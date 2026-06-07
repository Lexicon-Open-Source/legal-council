"""
Session management endpoints for the Virtual Judicial Council.

Provides endpoints for:
- Creating new deliberation sessions
- Retrieving session details
- Listing sessions
- Deleting sessions
"""

import json
import logging
from collections.abc import AsyncIterator
from dataclasses import dataclass
from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncEngine

from src.council.agents.orchestrator import get_agent_orchestrator
from src.council.agents.state_machine import get_state_machine
from src.council.database import CaseDatabase, SessionStore, get_session_store
from src.council.dependencies import get_db_engine
from src.council.models.generated import (
    CaseInput,
    CouncilSimilarCase,
    CreateSessionRequest,
    CreateSessionResponse,
    CreateSessionStreamEventData,
    CreateSessionStreamEventType,
    DeliberationMessage,
    DeliberationPhase,
    DeliberationSession,
    GetSessionResponse,
    ListSessionsResponse,
    SessionStatus,
)
from src.council.services.case_parser import get_case_parser_service

logger = logging.getLogger(__name__)

router = APIRouter()


@dataclass
class _SessionCreationContext:
    case_input: CaseInput
    similar_cases: list[CouncilSimilarCase]
    session: DeliberationSession
    store: SessionStore


def _accepts_event_stream(accept_header: str | None) -> bool:
    for part in (accept_header or "").split(","):
        media_type, *raw_params = part.strip().split(";")
        if media_type.strip().lower() != "text/event-stream":
            continue
        params = {}
        for raw_param in raw_params:
            key, _, value = raw_param.strip().partition("=")
            if key:
                params[key.lower()] = value.strip()
        q = params.get("q")
        if q is None:
            return True
        try:
            if float(q) > 0:
                return True
        except ValueError:
            continue
    return False


def _create_session_event_to_sse(event: CreateSessionStreamEventData) -> str:
    """Convert a create-session event to SSE format."""
    return f"data: {json.dumps(event.model_dump(mode='json'))}\n\n"


def _status_event(status: str, content: str) -> CreateSessionStreamEventData:
    return CreateSessionStreamEventData(
        event_type=CreateSessionStreamEventType.STATUS,
        status=status,
        content=content,
    )


def _error_event(
    content: str,
    status_code: int,
    session_id: str | None = None,
) -> CreateSessionStreamEventData:
    return CreateSessionStreamEventData(
        event_type=CreateSessionStreamEventType.ERROR,
        session_id=session_id,
        content=content,
        status_code=status_code,
    )


async def _parse_case_input(payload: CreateSessionRequest) -> CaseInput:
    parser = get_case_parser_service()
    try:
        return await parser.parse_case(
            case_text=payload.case_summary,
            structured_data=payload.structured_data,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail=f"Failed to parse case: {str(e)}",
        ) from e


async def _find_similar_cases(
    case_input: CaseInput,
    db_engine: AsyncEngine,
) -> list[CouncilSimilarCase]:
    case_db = CaseDatabase(db_engine)
    return await case_db.find_similar_cases(
        case_input=case_input,
        limit=5,
    )


async def _create_initialized_session(
    case_input: CaseInput,
    similar_cases: list[CouncilSimilarCase],
) -> tuple[DeliberationSession, SessionStore]:
    store = get_session_store()
    session = await store.create_session(case_input=case_input)
    await store.set_similar_cases(session.id, similar_cases)

    state_machine = get_state_machine()
    success, msg = await state_machine.transition(
        session.id, DeliberationPhase.OPENING, reason="session_created"
    )
    if not success:
        logger.warning(f"Failed to set initial phase for session {session.id}: {msg}")

    return session, store


async def _create_session_context(
    payload: CreateSessionRequest,
    db_engine: AsyncEngine,
) -> _SessionCreationContext:
    case_input = await _parse_case_input(payload)
    similar_cases = await _find_similar_cases(case_input, db_engine)
    session, store = await _create_initialized_session(case_input, similar_cases)
    return _SessionCreationContext(
        case_input=case_input,
        similar_cases=similar_cases,
        session=session,
        store=store,
    )


async def _create_session_stream(
    payload: CreateSessionRequest,
    db_engine: AsyncEngine,
) -> AsyncIterator[str]:
    session_id: str | None = None
    try:
        yield _create_session_event_to_sse(
            _status_event("parsing_case", "Parsing case")
        )
        case_input = await _parse_case_input(payload)

        yield _create_session_event_to_sse(
            _status_event("finding_similar_cases", "Finding similar cases")
        )
        similar_cases = await _find_similar_cases(case_input, db_engine)

        yield _create_session_event_to_sse(
            _status_event("creating_session", "Creating session")
        )
        session, store = await _create_initialized_session(case_input, similar_cases)
        session_id = session.id

        yield _create_session_event_to_sse(
            CreateSessionStreamEventData(
                event_type=CreateSessionStreamEventType.SESSION_CREATED,
                session_id=session.id,
                parsed_case=case_input.parsed_case,
                similar_cases=similar_cases,
            )
        )

        orchestrator = get_agent_orchestrator()
        initial_message: DeliberationMessage | None = None
        async for event in orchestrator.generate_random_initial_opinion_stream(
            session_id=session.id,
            case_input=case_input.parsed_case,
            similar_cases=similar_cases,
        ):
            # Initial-opinion failures are best-effort: the session is already
            # persisted, so we surface the agent-level failure but still emit
            # session_complete with initial_message=None — matching the
            # non-streaming path's graceful degradation. Clients can recover
            # via /stream/initial.
            if event.event_type == "agent_error":
                logger.warning(
                    "Initial opinion stream failed for session %s: %s",
                    session.id,
                    event.content,
                )
                yield _create_session_event_to_sse(
                    CreateSessionStreamEventData(
                        event_type=CreateSessionStreamEventType.AGENT_COMPLETE,
                        session_id=session.id,
                        agent_id=event.agent_id,
                        content=event.content,
                    )
                )
                break

            if event.event_type == "agent_complete" and event.agent_id is not None:
                agent = orchestrator.get_agent(event.agent_id)
                initial_message = agent.create_message_from_stream(
                    session_id=session.id,
                    message_id=event.message_id or "",
                    full_content=event.full_content or event.content or "",
                )
                await store.add_message(session.id, initial_message)

            yield _create_session_event_to_sse(
                CreateSessionStreamEventData(
                    event_type=CreateSessionStreamEventType(event.event_type),
                    session_id=session.id,
                    agent_id=event.agent_id,
                    content=event.content,
                    message_id=event.message_id,
                    full_content=event.full_content,
                )
            )

        yield _create_session_event_to_sse(
            CreateSessionStreamEventData(
                event_type=CreateSessionStreamEventType.SESSION_COMPLETE,
                session_id=session.id,
                initial_message=initial_message,
            )
        )

    except HTTPException as e:
        yield _create_session_event_to_sse(
            _error_event(str(e.detail), e.status_code, session_id)
        )
    except Exception:
        logger.exception("Failed to stream session creation")
        yield _create_session_event_to_sse(
            _error_event(
                "An unexpected error occurred. Please try again.",
                HTTPStatus.INTERNAL_SERVER_ERROR,
                session_id,
            )
        )


@router.post("", response_model=CreateSessionResponse)
async def create_session(
    request: Request,
    payload: CreateSessionRequest,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> CreateSessionResponse | StreamingResponse:
    """
    Create a new deliberation session.

    This endpoint:
    1. Parses the case summary into structured data
    2. Finds similar cases via semantic search
    3. Creates and stores the session
    4. Generates one initial opinion from a random judge

    The response includes the session ID, parsed case, similar cases,
    and the first agent message to display.
    """
    logger.info(f"Creating new session with case type: {payload.case_type}")

    if _accepts_event_stream(request.headers.get("accept")):
        return StreamingResponse(
            _create_session_stream(payload, db_engine),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )

    context = await _create_session_context(payload, db_engine)

    # Generate initial opinion from a randomly selected judge
    # This makes session creation faster (~5s instead of ~15s)
    # Users can use /stream/initial or /stream/continue for full deliberation
    orchestrator = get_agent_orchestrator()
    try:
        initial_message = await orchestrator.generate_random_initial_opinion(
            session_id=context.session.id,
            case_input=context.case_input.parsed_case,
            similar_cases=context.similar_cases,
        )
    except Exception:
        logger.exception("Failed to generate initial opinion")
        # Still create session, just without initial message
        initial_message = None

    # Add message to session (now async)
    if initial_message:
        await context.store.add_message(context.session.id, initial_message)

    return CreateSessionResponse(
        session_id=context.session.id,
        parsed_case=context.case_input.parsed_case,
        similar_cases=context.similar_cases,
        initial_message=initial_message,
    )


@router.get("/{session_id}", response_model=GetSessionResponse)
async def get_session(session_id: str) -> GetSessionResponse:
    """
    Get a deliberation session by ID.

    Returns the full session including case input, similar cases,
    and all messages exchanged so far.
    """
    store = get_session_store()
    session = await store.get_session(session_id)

    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    return GetSessionResponse(session=session)


@router.get("", response_model=ListSessionsResponse)
async def list_sessions(
    status: SessionStatus | None = None,
    limit: int = 20,
    offset: int = 0,
) -> ListSessionsResponse:
    """
    List deliberation sessions.

    Supports filtering by status and pagination.
    """
    store = get_session_store()
    sessions = await store.list_sessions(
        status=status,
        limit=limit,
        offset=offset,
    )

    # Get total count using dedicated method
    total = await store.count_sessions(status=status)

    return ListSessionsResponse(
        sessions=sessions,
        pagination={
            "limit": limit,
            "offset": offset,
            "total": total,
        },
    )


@router.delete("/{session_id}")
async def delete_session(session_id: str) -> dict:
    """
    Delete a deliberation session.

    This permanently removes the session and all its messages.
    """
    store = get_session_store()

    if not await store.get_session(session_id):
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    await store.delete_session(session_id)
    return {"message": f"Session {session_id} deleted"}


@router.post("/{session_id}/conclude")
async def conclude_session(session_id: str) -> GetSessionResponse:
    """
    Conclude a deliberation session.

    Marks the session as concluded, preventing further messages.
    The session can still be read and used to generate opinions.
    """
    store = get_session_store()

    session = await store.get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Session not found: {session_id}",
        )

    if session.status == SessionStatus.CONCLUDED:
        raise HTTPException(
            status_code=HTTPStatus.BAD_REQUEST,
            detail="Session is already concluded",
        )

    concluded = await store.conclude_session(session_id)
    return GetSessionResponse(session=concluded)
