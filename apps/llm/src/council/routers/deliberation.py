"""
Deliberation endpoints for the Virtual Judicial Council.

Provides endpoints for:
- Sending messages to the council
- Getting agent responses
- Generating legal opinions
- Streaming deliberation responses (SSE)
"""

import asyncio
import json
import logging
from collections.abc import AsyncIterator
from datetime import UTC, datetime
from http import HTTPStatus
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response, StreamingResponse
from sqlalchemy.ext.asyncio import AsyncEngine

from src.council.agents.classifier import classify_intent
from src.council.agents.identity import normalize_target_agent
from src.council.agents.orchestrator import StreamEvent, get_agent_orchestrator
from src.council.agents.position_extractor import extract_positions
from src.council.agents.router import route_message
from src.council.agents.state_machine import get_state_machine
from src.council.database import CaseDatabase, SessionStore, get_session_store
from src.council.dependencies import get_db_engine
from src.council.models.generated import (
    AgentId,
    AgentSender,
    ContinueDiscussionRequest,
    ContinueDiscussionResponse,
    DeliberationMessage,
    DeliberationPhase,
    GenerateOpinionRequest,
    GenerateOpinionResponse,
    GetMessagesResponse,
    SendMessageRequest,
    SendMessageResponse,
    SessionStatus,
    StreamContinueRequest,
    StreamEventData,
    StreamEventType,
    StreamMessageRequest,
    UserSender,
)
from src.council.services.opinion_generator import get_opinion_generator_service
from src.council.services.pdf_generator import get_pdf_generator_service
from src.council.services.summary_generator import generate_structured_summary

logger = logging.getLogger(__name__)

router = APIRouter()


def _agent_value(agent: object | None) -> str | None:
    if agent is None:
        return None
    if hasattr(agent, "value"):
        return str(agent.value)
    return str(agent)


def _resolve_target_agent(
    requested_target: object | None,
    routed_responders: list[AgentId],
) -> str | None:
    """Prefer explicit request targets over classifier routing defaults."""
    explicit_target = normalize_target_agent(requested_target)
    if explicit_target:
        return explicit_target
    if routed_responders:
        return normalize_target_agent(routed_responders[0])
    return None


async def _extract_and_track_positions(
    session_id: str,
    agent_id: str,
    content: str,
) -> None:
    """Extract positions from agent response and update agreement map."""
    try:
        state_machine = get_state_machine()
        metadata = await state_machine.get_phase_metadata(session_id)
        agreement_map = metadata.get("agreement_map", {})
        existing_issues = list(agreement_map.get("issues", {}).keys())
        round_count = agreement_map.get("round_count", 0)

        positions = await extract_positions(
            agent_id=agent_id,
            response_content=content,
            existing_issues=existing_issues if existing_issues else None,
            round_number=round_count,
        )
        if positions:
            await state_machine.update_agreement_map(
                session_id,
                agent_id,
                [
                    {
                        "issue": p.issue,
                        "stance": p.stance,
                        "reasoning_summary": p.reasoning_summary,
                        "round_stated": p.round_stated,
                    }
                    for p in positions
                ],
            )
            logger.debug(
                f"Extracted {len(positions)} positions from {agent_id} "
                f"in session {session_id}"
            )
    except Exception:
        logger.exception(f"Position extraction failed for {agent_id} in {session_id}")


@router.post("/{session_id}/message", response_model=SendMessageResponse)
async def send_message(
    session_id: str,
    request: SendMessageRequest,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> SendMessageResponse:
    """
    Send a message to the judicial council.

    The message is processed by the orchestrator, which determines
    which agent(s) should respond based on:
    - Target agent (if specified)
    - Message intent (inferred from content)
    - Conversation balance

    Returns the user's message and all agent responses.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if session.status != SessionStatus.ACTIVE:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Session is not active",
        )

    logger.info(
        f"Processing message for session {session_id}: target={request.target_agent}"
    )

    # Get similar cases for context
    case_db = CaseDatabase(db_engine)
    if not session.similar_cases:
        similar_cases = await case_db.find_similar_cases(
            case_input=session.case_input,
            limit=5,
        )
        await store.set_similar_cases(session_id, similar_cases)
    else:
        similar_cases = session.similar_cases

    # Classify intent and route using phase-aware logic
    state_machine = get_state_machine()
    current_phase = await state_machine.get_phase(session_id)
    phase = current_phase or DeliberationPhase.LEGACY

    classified = await classify_intent(request.content, phase)
    routing = route_message(classified, phase)

    logger.info(
        f"Classified intent={classified.intent}, "
        f"phase={phase}, responders={[r.value for r in routing.responders]}"
    )

    # Handle phase transitions from routing decisions
    if routing.trigger_phase_transition:
        success, msg = await state_machine.transition(
            session_id,
            routing.trigger_phase_transition,
            reason=f"routing:{classified.intent}",
        )
        if success:
            logger.info(
                f"Phase transition to {routing.trigger_phase_transition}: {msg}"
            )

    # Process message through orchestrator with routed responders
    orchestrator = get_agent_orchestrator()
    try:
        user_msg, agent_responses = await orchestrator.process_user_message(
            session_id=session_id,
            user_message=request.content,
            case_input=session.case_input.parsed_case,
            similar_cases=similar_cases,
            history=session.messages,
            target_agent=_resolve_target_agent(
                request.target_agent,
                routing.responders,
            ),
        )
    except Exception as e:
        logger.exception(f"Failed to process message: {e}")
        raise HTTPException(
            status_code=HTTPStatus.INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred. Please try again.",
        )

    # Add user message and agent responses atomically in a single transaction
    await store.add_message_with_responses(session_id, user_msg, agent_responses)

    # Update round count after successful response
    await state_machine.update_round_count(session_id)

    # Fire-and-forget: extract positions from each agent response
    for resp in agent_responses:
        if hasattr(resp.sender, "agent_id"):
            asyncio.create_task(
                _extract_and_track_positions(
                    session_id, resp.sender.agent_id, resp.content
                )
            )

    return SendMessageResponse(
        user_message=user_msg,
        agent_responses=agent_responses,
    )


@router.post("/{session_id}/continue", response_model=ContinueDiscussionResponse)
async def continue_discussion(
    session_id: str,
    request: ContinueDiscussionRequest,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> ContinueDiscussionResponse:
    """
    Continue the judicial discussion without user input.

    This allows the judges to continue deliberating amongst themselves,
    responding to each other's points, building consensus, or exploring
    disagreements. Use this to let the discussion flow naturally.

    Each "round" means all three judges get a chance to respond to the
    current state of the discussion.

    Returns new messages generated in this continuation.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if session.status != SessionStatus.ACTIVE:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Session is not active",
        )

    if len(session.messages) < 3:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Need at least 3 messages before continuing discussion",
        )

    logger.info(
        f"Continuing discussion for session {session_id}, {request.num_rounds} round(s)"
    )

    # Get similar cases for context
    case_db = CaseDatabase(db_engine)
    if not session.similar_cases:
        similar_cases = await case_db.find_similar_cases(
            case_input=session.case_input,
            limit=5,
        )
        await store.set_similar_cases(session_id, similar_cases)
    else:
        similar_cases = session.similar_cases

    # Continue the discussion
    orchestrator = get_agent_orchestrator()
    try:
        new_messages = await orchestrator.continue_discussion(
            session_id=session_id,
            case_input=session.case_input.parsed_case,
            similar_cases=similar_cases,
            history=session.messages,
            num_rounds=request.num_rounds,
        )
    except Exception as e:
        logger.exception(f"Failed to continue discussion: {e}")
        raise HTTPException(
            status_code=HTTPStatus.INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred. Please try again.",
        )

    # Add new messages to session
    await store.add_messages(session_id, new_messages)

    # Get updated message count
    updated_session = await store.get_session(session_id)
    total_messages = len(updated_session.messages) if updated_session else 0

    return ContinueDiscussionResponse(
        new_messages=new_messages,
        total_messages=total_messages,
    )


@router.get("/{session_id}/messages", response_model=GetMessagesResponse)
async def get_messages(
    session_id: str,
    limit: int = 50,
    offset: int = 0,
) -> GetMessagesResponse:
    """
    Get messages from a deliberation session.

    Returns messages in chronological order with pagination.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    # Paginate messages
    messages = session.messages[offset : offset + limit]

    return GetMessagesResponse(messages=messages)


@router.post("/{session_id}/opinion", response_model=GenerateOpinionResponse)
async def generate_opinion(
    session_id: str,
    request: GenerateOpinionRequest = GenerateOpinionRequest(),
) -> GenerateOpinionResponse:
    """
    Generate a legal opinion from the deliberation.

    Synthesizes the discussion between all three judges into a
    structured legal opinion document including:
    - Verdict recommendation with confidence level
    - Sentence recommendation with ranges
    - Categorized legal arguments
    - Cited precedents and applicable laws
    - Dissenting views (optional)

    Requires at least 3 messages in the session to generate.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if len(session.messages) < 3:
        # Count agent messages to provide helpful guidance
        agent_message_count = sum(
            1 for msg in session.messages if hasattr(msg.sender, "agent_id")
        )

        if agent_message_count < 3:
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail=(
                    f"Need initial opinions from all 3 judges before "
                    f"generating opinion (currently {agent_message_count}/3). "
                    f"Call POST /{session_id}/stream/initial first to "
                    f"complete initial deliberation."
                ),
            )
        else:
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail="Need at least 3 messages to generate opinion",
            )

    logger.info(f"Generating opinion for session {session_id}")

    generator = get_opinion_generator_service()
    try:
        opinion = await generator.generate_opinion(
            session_id=session_id,
            case_input=session.case_input.parsed_case,
            similar_cases=session.similar_cases,
            messages=session.messages,
            include_dissent=request.include_dissent,
        )
    except Exception as e:
        logger.exception(f"Failed to generate opinion: {e}")
        raise HTTPException(
            status_code=HTTPStatus.INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred. Please try again.",
        )

    # Store opinion in session
    session.legal_opinion = opinion.model_dump(mode="json")
    await store.update_session(session)

    # Generate structured summary from agreement map (if available)
    state_machine = get_state_machine()
    try:
        metadata = await state_machine.get_phase_metadata(session_id)
        agreement_map = metadata.get("agreement_map", {})
        if agreement_map.get("issues"):
            case_summary = ""
            if session.case_input and session.case_input.parsed_case:
                case_summary = session.case_input.parsed_case.summary or ""
            summary = await generate_structured_summary(
                messages=[msg.model_dump(mode="json") for msg in session.messages],
                agreement_map=agreement_map,
                case_summary=case_summary,
            )
            if summary:
                await state_machine._update_structured_summary(session_id, summary)
                logger.info(f"Generated structured summary for session {session_id}")
        # Transition to SUMMARY phase
        await state_machine.transition(
            session_id, DeliberationPhase.SUMMARY, reason="opinion_generated"
        )
    except Exception:
        logger.exception(f"Failed to generate structured summary for {session_id}")

    return GenerateOpinionResponse(opinion=opinion)


@router.get("/{session_id}/opinion")
async def get_opinion(session_id: str) -> dict:
    """
    Get the generated legal opinion for a session.

    Returns the previously generated opinion, or an error if none exists.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if not session.legal_opinion:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail="No opinion generated for this session yet",
        )

    return {"opinion": session.legal_opinion}


# =============================================================================
# Streaming Endpoints (SSE)
# =============================================================================


def _stream_event_to_sse(event: StreamEvent) -> str:
    """Convert a StreamEvent to SSE format."""
    data = StreamEventData(
        event_type=StreamEventType(event.event_type),
        agent_id=event.agent_id,
        content=event.content,
        message_id=event.message_id,
        full_content=event.full_content,
    )
    return f"data: {json.dumps(data.model_dump(mode='json'))}\n\n"


async def _stream_generator(
    events: AsyncIterator[StreamEvent],
) -> AsyncIterator[str]:
    """Generator that converts StreamEvents to SSE format."""
    async for event in events:
        yield _stream_event_to_sse(event)


async def _stream_with_persistence(
    events: AsyncIterator[StreamEvent],
    session_id: str,
    store: SessionStore,
) -> AsyncIterator[str]:
    """
    Generator that persists messages to DB as they complete, then yields SSE.

    Intercepts:
    - user_message events: saves user message to database
    - agent_complete events: saves agent message to database

    All events are yielded to the client unchanged.
    """
    async for event in events:
        # Persist user message when recorded
        if event.event_type == "user_message":
            user_msg = DeliberationMessage(
                id=event.message_id or str(uuid4()),
                session_id=session_id,
                sender=UserSender(type="user"),
                content=event.content,
                timestamp=datetime.now(UTC),
            )
            try:
                await store.add_message(session_id, user_msg)
                logger.debug(f"Persisted user message: {user_msg.id}")
            except Exception as e:
                logger.error(f"Failed to persist user message: {e}")

        # Persist agent message when complete
        elif event.event_type == "agent_complete" and event.agent_id:
            full_content = event.full_content or event.content
            agent_msg = DeliberationMessage(
                id=event.message_id or str(uuid4()),
                session_id=session_id,
                sender=AgentSender(type="agent", agent_id=event.agent_id),
                content=full_content,
                timestamp=datetime.now(UTC),
            )
            try:
                await store.add_message(session_id, agent_msg)
                logger.debug(
                    f"Persisted agent message from {event.agent_id}: {agent_msg.id}"
                )
            except Exception as e:
                logger.error(f"Failed to persist agent message: {e}")

            # Fire-and-forget: extract positions and update agreement map
            asyncio.create_task(
                _extract_and_track_positions(session_id, event.agent_id, full_content)
            )

        # Always yield the event to the client
        yield _stream_event_to_sse(event)


@router.post("/{session_id}/stream/initial")
async def stream_initial_opinions(
    session_id: str,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> StreamingResponse:
    """
    Stream remaining initial opinions from judges (SSE).

    Session creation generates 1 random judge's opinion. This endpoint
    streams opinions from the remaining judges to complete the initial
    deliberation round.

    SSE Event Types:
    - agent_start: A judge is about to speak
    - chunk: A piece of text from the current judge
    - agent_complete: A judge finished speaking (includes full content)
    - deliberation_complete: All judges have spoken

    Returns Server-Sent Events stream.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if session.status != SessionStatus.ACTIVE:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Session is not active",
        )

    # Need at least the initial message from session creation
    if len(session.messages) == 0:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="No initial message found. Session may not be properly created.",
        )

    # Check if all 3 judges have already spoken in the initial round
    agent_messages = [
        msg for msg in session.messages if hasattr(msg.sender, "agent_id")
    ]
    if len(agent_messages) >= 3:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Initial opinions already complete. Use /stream/continue instead.",
        )

    logger.info(
        f"Streaming remaining initial opinions for session {session_id} "
        f"({len(agent_messages)} judges have spoken)"
    )

    # Get similar cases for context
    case_db = CaseDatabase(db_engine)
    if not session.similar_cases:
        similar_cases = await case_db.find_similar_cases(
            case_input=session.case_input,
            limit=5,
        )
        await store.set_similar_cases(session_id, similar_cases)
    else:
        similar_cases = session.similar_cases

    # Determine which judges haven't spoken yet

    judges_spoken = {
        msg.sender.agent_id
        for msg in session.messages
        if hasattr(msg.sender, "agent_id")
    }
    judges_remaining = [
        agent_id for agent_id in AgentId if agent_id not in judges_spoken
    ]

    logger.info(f"Judges remaining to speak: {[j.value for j in judges_remaining]}")

    # Stream opinions from remaining judges only
    orchestrator = get_agent_orchestrator()
    event_stream = orchestrator.continue_discussion_stream(
        session_id=session_id,
        case_input=session.case_input.parsed_case,
        similar_cases=similar_cases,
        history=session.messages,
        num_rounds=1,
        agents_filter=judges_remaining,
    )

    # After all initial opinions, transition OPENING → DEBATE
    async def _stream_and_transition():
        async for sse_line in _stream_with_persistence(event_stream, session_id, store):
            yield sse_line
        # All judges have spoken — transition to DEBATE phase
        state_machine = get_state_machine()
        success, msg = await state_machine.transition(
            session_id, DeliberationPhase.DEBATE, reason="initial_opinions_complete"
        )
        if success:
            logger.info(
                f"Session {session_id} transitioned to DEBATE after initial opinions"
            )

    return StreamingResponse(
        _stream_and_transition(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/{session_id}/stream/message")
async def stream_message_response(
    session_id: str,
    request: StreamMessageRequest,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> StreamingResponse:
    """
    Send a message and stream agent responses (SSE).

    The message is processed by the orchestrator, which determines
    which agent(s) should respond. Responses are streamed in real-time.

    SSE Event Types:
    - user_message: The user's message was recorded
    - agent_start: A judge is about to respond
    - chunk: A piece of text from the current judge
    - agent_complete: A judge finished responding (includes full content)
    - deliberation_complete: All responding judges have finished

    Returns Server-Sent Events stream.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if session.status != SessionStatus.ACTIVE:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Session is not active",
        )

    logger.info(
        f"Streaming message response for session {session_id}: "
        f"target={request.target_agent}"
    )

    # Get similar cases for context
    case_db = CaseDatabase(db_engine)
    if not session.similar_cases:
        similar_cases = await case_db.find_similar_cases(
            case_input=session.case_input,
            limit=5,
        )
        await store.set_similar_cases(session_id, similar_cases)
    else:
        similar_cases = session.similar_cases

    # Classify intent and route using phase-aware logic
    state_machine = get_state_machine()
    current_phase = await state_machine.get_phase(session_id)
    phase = current_phase or DeliberationPhase.LEGACY

    classified = await classify_intent(request.content, phase)
    routing = route_message(classified, phase)

    logger.info(
        f"Stream: classified intent={classified.intent}, "
        f"phase={phase}, responders={[r.value for r in routing.responders]}"
    )

    # Handle phase transitions from routing decisions
    if routing.trigger_phase_transition:
        success, msg = await state_machine.transition(
            session_id,
            routing.trigger_phase_transition,
            reason=f"routing:{classified.intent}",
        )
        if success:
            logger.info(
                f"Phase transition to {routing.trigger_phase_transition}: {msg}"
            )

    # Create the stream with routed target agent
    orchestrator = get_agent_orchestrator()
    event_stream = orchestrator.process_user_message_stream(
        session_id=session_id,
        user_message=request.content,
        case_input=session.case_input.parsed_case,
        similar_cases=similar_cases,
        history=session.messages,
        target_agent=_resolve_target_agent(
            request.target_agent,
            routing.responders,
        ),
    )

    return StreamingResponse(
        _stream_with_persistence(event_stream, session_id, store),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/{session_id}/stream/continue")
async def stream_continue_discussion(
    session_id: str,
    request: StreamContinueRequest,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> StreamingResponse:
    """
    Continue the judicial discussion with streaming (SSE).

    This allows the judges to continue deliberating amongst themselves,
    with responses streamed in real-time.

    SSE Event Types:
    - agent_start: A judge is about to speak
    - chunk: A piece of text from the current judge
    - agent_complete: A judge finished speaking (includes full content)
    - agent_error: An error occurred with a specific judge
    - deliberation_complete: All rounds have finished

    Returns Server-Sent Events stream.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if session.status != SessionStatus.ACTIVE:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Session is not active",
        )

    if len(session.messages) < 3:
        # Count agent messages to provide helpful guidance
        agent_message_count = sum(
            1 for msg in session.messages if hasattr(msg.sender, "agent_id")
        )

        if agent_message_count < 3:
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail=(
                    f"Need initial opinions from all 3 judges before "
                    f"continuing discussion (currently {agent_message_count}/3). "
                    f"Call POST /{session_id}/stream/initial first to "
                    f"complete initial deliberation."
                ),
            )
        else:
            raise HTTPException(
                status_code=HTTPStatus.BAD_REQUEST,
                detail="Need at least 3 messages before continuing discussion",
            )

    logger.info(
        f"Streaming continued discussion for session {session_id}, "
        f"{request.num_rounds} round(s)"
    )

    # Get similar cases for context
    case_db = CaseDatabase(db_engine)
    if not session.similar_cases:
        similar_cases = await case_db.find_similar_cases(
            case_input=session.case_input,
            limit=5,
        )
        await store.set_similar_cases(session_id, similar_cases)
    else:
        similar_cases = session.similar_cases

    # Create the stream
    orchestrator = get_agent_orchestrator()
    event_stream = orchestrator.continue_discussion_stream(
        session_id=session_id,
        case_input=session.case_input.parsed_case,
        similar_cases=similar_cases,
        history=session.messages,
        num_rounds=request.num_rounds,
    )

    return StreamingResponse(
        _stream_with_persistence(event_stream, session_id, store),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


# =============================================================================
# PDF Download Endpoint
# =============================================================================


@router.get("/{session_id}/download/pdf")
async def download_deliberation_pdf(session_id: str) -> Response:
    """
    Download the deliberation session as a PDF document.

    Generates a professional PDF containing:
    - Case information and summary
    - Similar cases for reference
    - Full deliberation transcript
    - Legal opinion (if generated)

    Returns the PDF as a downloadable file.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if len(session.messages) == 0:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="No messages in session. Cannot generate PDF.",
        )

    logger.info(f"Generating PDF for session {session_id}")

    # Parse legal opinion if available
    legal_opinion = None
    if session.legal_opinion:
        from src.council.models.generated import LegalOpinionDraft

        try:
            legal_opinion = LegalOpinionDraft.model_validate(session.legal_opinion)
        except Exception as e:
            logger.warning(f"Failed to parse legal opinion: {e}")

    # Generate PDF
    pdf_generator = get_pdf_generator_service()
    try:
        pdf_bytes = pdf_generator.generate_deliberation_pdf(
            session_id=session_id,
            case_input=session.case_input,
            similar_cases=session.similar_cases or [],
            messages=session.messages,
            legal_opinion=legal_opinion,
        )
    except Exception as e:
        logger.exception(f"Failed to generate PDF: {e}")
        raise HTTPException(
            status_code=HTTPStatus.INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred. Please try again.",
        )

    # Generate filename
    filename = f"deliberation_{session_id[:8]}.pdf"

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Content-Length": str(len(pdf_bytes)),
        },
    )
