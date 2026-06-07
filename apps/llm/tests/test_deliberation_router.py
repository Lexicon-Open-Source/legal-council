"""Tests for deliberation endpoint helpers."""

from datetime import UTC, datetime
from unittest.mock import MagicMock

import pytest

from src.council.agents.orchestrator import StreamEvent
from src.council.models.generated import (
    AgentId,
    AgentSender,
    CaseInput,
    CouncilCaseType,
    CouncilSimilarCase,
    DeliberationMessage,
    DeliberationPhase,
    DeliberationSession,
    InputType,
    ParsedCaseInput,
    SendMessageRequest,
    SessionStatus,
    StreamMessageRequest,
    TargetAgent,
)
from src.council.routers import deliberation as deliberation_router
from src.council.routers.deliberation import _resolve_target_agent, _stream_event_to_sse


def test_stream_event_to_sse_keeps_wire_shape():
    event = StreamEvent(event_type="agent_start", agent_id=AgentId.HUMANIST)
    expected = (
        'data: {"event_type": "agent_start", "agent_id": "humanist", '
        '"content": "", "message_id": null, "full_content": null}\n\n'
    )

    assert _stream_event_to_sse(event) == expected


def test_explicit_target_agent_takes_precedence_over_routing_default():
    target = _resolve_target_agent(
        TargetAgent.HISTORIAN,
        [AgentId.STRICT],
    )

    assert target == "historian"


def test_frontend_target_aliases_are_normalized():
    assert _resolve_target_agent(TargetAgent.LEGALIS, [AgentId.HUMANIST]) == "strict"
    assert _resolve_target_agent(TargetAgent.HUMANIS, [AgentId.STRICT]) == "humanist"
    assert _resolve_target_agent(TargetAgent.SEJARAWAN, [AgentId.STRICT]) == (
        "historian"
    )


def test_message_models_accept_frontend_target_aliases():
    send_request = SendMessageRequest(content="Pendapat?", target_agent="humanis")
    stream_request = StreamMessageRequest(
        content="Ada yurisprudensi?",
        target_agent="sejarawan",
    )

    assert send_request.target_agent == TargetAgent.HUMANIS
    assert stream_request.target_agent == TargetAgent.SEJARAWAN


def test_routed_responder_used_when_request_has_no_explicit_target():
    target = _resolve_target_agent(
        None,
        [AgentId.STRICT],
    )

    assert target == "strict"


def test_explicit_all_target_takes_precedence_over_routing_default():
    target = _resolve_target_agent(
        TargetAgent.ALL,
        [AgentId.STRICT],
    )

    assert target == "all"


@pytest.mark.asyncio
async def test_stream_initial_excludes_judges_who_already_spoke(monkeypatch):
    captured = {}
    session = _session_with_initial_message(AgentId.STRICT)

    class FakeStore:
        async def get_session(self, session_id):
            return session

        async def add_message(self, session_id, message):
            session.messages.append(message)

    class FakeOrchestrator:
        def continue_discussion_stream(
            self,
            *,
            session_id,
            case_input,
            similar_cases,
            history,
            num_rounds,
            agents_filter,
        ):
            captured["agents_filter"] = agents_filter

            async def event_stream():
                yield StreamEvent(event_type="deliberation_complete")

            return event_stream()

    class FakeStateMachine:
        async def transition(self, session_id, phase, reason):
            return True, "ok"

    monkeypatch.setattr(
        deliberation_router,
        "get_session_store",
        lambda: FakeStore(),
    )
    monkeypatch.setattr(
        deliberation_router,
        "get_agent_orchestrator",
        lambda: FakeOrchestrator(),
    )
    monkeypatch.setattr(
        deliberation_router,
        "get_state_machine",
        lambda: FakeStateMachine(),
    )

    response = await deliberation_router.stream_initial_opinions(
        "sess-initial",
        db_engine=MagicMock(),
    )
    body = "".join([line async for line in response.body_iterator])

    assert [agent.value for agent in captured["agents_filter"]] == [
        "humanist",
        "historian",
    ]
    assert '"event_type": "deliberation_complete"' in body


def _session_with_initial_message(agent_id: AgentId) -> DeliberationSession:
    parsed_case = ParsedCaseInput(
        case_type=CouncilCaseType.CORRUPTION,
        summary="Corruption case",
    )
    case_input = CaseInput(
        input_type=InputType.TEXT_SUMMARY,
        raw_input="A corruption case summary",
        parsed_case=parsed_case,
    )
    similar_case = CouncilSimilarCase(
        case_id="case-1",
        case_number="1/Pid.Sus/2024",
        similarity_score=0.9,
        similarity_reason="Similar corruption case",
        verdict_summary="Guilty",
        sentence_months=60,
    )
    return DeliberationSession(
        id="sess-initial",
        status=SessionStatus.ACTIVE,
        current_phase=DeliberationPhase.OPENING,
        case_input=case_input,
        similar_cases=[similar_case],
        messages=[
            DeliberationMessage(
                id="msg-initial",
                session_id="sess-initial",
                sender=AgentSender(type="agent", agent_id=agent_id),
                content="Initial opinion",
                cited_cases=[],
                cited_laws=[],
            )
        ],
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )
