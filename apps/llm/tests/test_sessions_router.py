"""
Tests for council session router helpers.
"""

import json
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
    CreateSessionRequest,
    DeliberationMessage,
    DeliberationPhase,
    DeliberationSession,
    InputType,
    ParsedCaseInput,
    SessionStatus,
)
from src.council.routers import sessions as sessions_router


def test_accepts_event_stream_requires_positive_text_event_stream():
    assert sessions_router._accepts_event_stream("text/event-stream")
    assert sessions_router._accepts_event_stream(
        "application/json, text/event-stream;q=1"
    )
    assert not sessions_router._accepts_event_stream("")
    assert not sessions_router._accepts_event_stream("application/json")
    assert not sessions_router._accepts_event_stream(
        "application/json, text/event-stream;q=0"
    )


@pytest.mark.asyncio
async def test_create_session_stream_emits_setup_and_first_judge_events(monkeypatch):
    fixtures = _install_stream_fixtures(monkeypatch)
    payload = CreateSessionRequest(case_summary="A corruption case summary " * 4)

    events = [
        _decode_sse(line)
        async for line in sessions_router._create_session_stream(
            payload,
            db_engine=MagicMock(),
        )
    ]

    assert [event["event_type"] for event in events] == [
        "status",
        "status",
        "status",
        "session_created",
        "agent_start",
        "chunk",
        "agent_complete",
        "session_complete",
    ]
    assert events[3]["session_id"] == "sess-stream"
    assert events[3]["parsed_case"]["case_type"] == "corruption"
    assert events[5]["content"] == "Initial streamed opinion"
    assert events[7]["initial_message"]["content"] == "Initial streamed opinion"
    assert len(fixtures.store.messages) == 1
    assert fixtures.store.messages[0].sender.agent_id == AgentId.STRICT


@pytest.mark.asyncio
async def test_create_session_stream_completes_when_initial_opinion_fails(monkeypatch):
    """
    Mirrors the non-streaming path's graceful degradation: when the initial
    opinion fails after the session has been persisted, the SSE flow should
    still emit session_complete with initial_message=None so clients can
    recover via /stream/initial.
    """
    fixtures = _install_stream_fixtures(monkeypatch, orchestrator_fails=True)
    payload = CreateSessionRequest(case_summary="A corruption case summary " * 4)

    events = [
        _decode_sse(line)
        async for line in sessions_router._create_session_stream(
            payload,
            db_engine=MagicMock(),
        )
    ]

    assert [event["event_type"] for event in events] == [
        "status",
        "status",
        "status",
        "session_created",
        "agent_start",
        "agent_complete",
        "session_complete",
    ]
    assert events[-1]["session_id"] == "sess-stream"
    assert events[-1]["initial_message"] is None
    # The session is persisted even though the initial opinion failed.
    assert fixtures.store.messages == []


@pytest.mark.asyncio
async def test_create_session_stream_emits_terminal_error_for_parse_failure(
    monkeypatch,
):
    class FailingParser:
        async def parse_case(self, *, case_text, structured_data):
            raise ValueError("cannot parse")

    monkeypatch.setattr(
        sessions_router,
        "get_case_parser_service",
        lambda: FailingParser(),
    )

    payload = CreateSessionRequest(case_summary="A corruption case summary " * 4)

    events = [
        _decode_sse(line)
        async for line in sessions_router._create_session_stream(
            payload,
            db_engine=MagicMock(),
        )
    ]

    assert [event["event_type"] for event in events] == ["status", "error"]
    assert events[-1]["status_code"] == 400
    assert "cannot parse" in events[-1]["content"]


def _decode_sse(line: str) -> dict:
    assert line.startswith("data: ")
    assert line.endswith("\n\n")
    return json.loads(line.removeprefix("data: ").strip())


class _FixtureBundle:
    def __init__(self, store):
        self.store = store


def _install_stream_fixtures(  # noqa: C901
    monkeypatch,
    *,
    orchestrator_fails: bool = False,
) -> _FixtureBundle:
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
    session = DeliberationSession(
        id="sess-stream",
        status=SessionStatus.ACTIVE,
        current_phase=DeliberationPhase.OPENING,
        case_input=case_input,
        similar_cases=[similar_case],
        messages=[],
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )

    class FakeParser:
        async def parse_case(self, *, case_text, structured_data):
            return case_input

    class FakeCaseDatabase:
        def __init__(self, db_engine):
            self.db_engine = db_engine

        async def find_similar_cases(self, *, case_input, limit):
            return [similar_case]

    class FakeStore:
        def __init__(self):
            self.messages = []

        async def create_session(self, *, case_input):
            return session

        async def set_similar_cases(self, session_id, similar_cases):
            session.similar_cases = similar_cases

        async def add_message(self, session_id, message):
            self.messages.append(message)

    class FakeStateMachine:
        async def transition(self, session_id, phase, reason):
            return True, "ok"

    class FakeAgent:
        def create_message_from_stream(
            self,
            *,
            session_id: str,
            message_id: str,
            full_content: str,
        ) -> DeliberationMessage:
            return DeliberationMessage(
                id=message_id,
                session_id=session_id,
                sender=AgentSender(type="agent", agent_id=AgentId.STRICT),
                content=full_content,
                cited_cases=[],
                cited_laws=[],
            )

    class FakeOrchestrator:
        async def generate_random_initial_opinion_stream(
            self,
            *,
            session_id,
            case_input,
            similar_cases,
        ):
            yield StreamEvent(event_type="agent_start", agent_id=AgentId.STRICT)
            if orchestrator_fails:
                yield StreamEvent(
                    event_type="agent_error",
                    agent_id=AgentId.STRICT,
                    content="LLM unavailable",
                )
                return
            yield StreamEvent(
                event_type="chunk",
                agent_id=AgentId.STRICT,
                content="Initial streamed opinion",
                message_id="msg-stream",
            )
            yield StreamEvent(
                event_type="agent_complete",
                agent_id=AgentId.STRICT,
                message_id="msg-stream",
                full_content="Initial streamed opinion",
            )

        def get_agent(self, agent_id):
            return FakeAgent()

    store = FakeStore()
    monkeypatch.setattr(
        sessions_router,
        "get_case_parser_service",
        lambda: FakeParser(),
    )
    monkeypatch.setattr(sessions_router, "CaseDatabase", FakeCaseDatabase)
    monkeypatch.setattr(sessions_router, "get_session_store", lambda: store)
    monkeypatch.setattr(
        sessions_router,
        "get_state_machine",
        lambda: FakeStateMachine(),
    )
    monkeypatch.setattr(
        sessions_router,
        "get_agent_orchestrator",
        lambda: FakeOrchestrator(),
    )
    return _FixtureBundle(store)
