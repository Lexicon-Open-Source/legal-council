"""
Unit tests for LLM service schemas.
"""

from datetime import UTC, datetime

from src.council.models.generated import (
    AgentId,
    AgentSender,
    CaseInput,
    CorruptionDetails,
    DeliberationMessage,
    DeliberationSession,
    InputType,
    ParsedCaseInput,
    SendMessageRequest,
    SessionStatus,
    SystemSender,
    UserSender,
)
from src.council.models.generated import (
    CouncilCaseType as CaseType,
)
from src.council.models.generated import (
    CouncilDefendantProfile as DefendantProfile,
)
from src.council.models.generated import (
    CouncilSimilarCase as SimilarCase,
)


class TestMessageSenders:
    """Tests for message sender types."""

    def test_user_sender(self):
        sender = UserSender(type="user")
        assert sender.type == "user"

    def test_agent_sender(self):
        sender = AgentSender(type="agent", agent_id=AgentId.STRICT)
        assert sender.type == "agent"
        assert sender.agent_id == AgentId.STRICT

    def test_system_sender(self):
        sender = SystemSender(type="system")
        assert sender.type == "system"

    def test_agent_id_values(self):
        assert AgentId.STRICT.value == "strict"
        assert AgentId.HUMANIST.value == "humanist"
        assert AgentId.HISTORIAN.value == "historian"


class TestParsedCaseInput:
    """Tests for ParsedCaseInput schema."""

    def test_minimal_case_input(self):
        case = ParsedCaseInput(
            case_type=CaseType.CORRUPTION,
            summary="Test case summary",
        )
        assert case.summary == "Test case summary"
        assert case.case_type == CaseType.CORRUPTION
        assert case.defendant_profile is None
        assert case.key_facts == []
        assert case.charges == []

    def test_full_case_input(self):
        case = ParsedCaseInput(
            case_type=CaseType.CORRUPTION,
            summary="Corruption case involving public official",
            defendant_profile=DefendantProfile(
                is_first_offender=True,
                age=45,
                occupation="Public official",
            ),
            key_facts=["Embezzlement of funds", "Falsified documents"],
            charges=["Article 2 UU 31/1999"],
            corruption=CorruptionDetails(
                state_loss_idr=5_000_000_000,
                position="Director",
            ),
        )
        assert case.defendant_profile.age == 45
        assert case.case_type == CaseType.CORRUPTION
        assert len(case.key_facts) == 2
        assert case.corruption.state_loss_idr == 5_000_000_000


class TestCaseInput:
    """Tests for CaseInput schema."""

    def test_case_input_creation(self):
        parsed = ParsedCaseInput(
            case_type=CaseType.CORRUPTION,
            summary="Test summary",
        )
        case_input = CaseInput(
            input_type=InputType.TEXT_SUMMARY,
            raw_input="Raw text input",
            parsed_case=parsed,
        )
        assert case_input.input_type == InputType.TEXT_SUMMARY
        assert case_input.raw_input == "Raw text input"
        assert case_input.parsed_case.summary == "Test summary"


class TestSimilarCase:
    """Tests for SimilarCase schema."""

    def test_similar_case(self):
        case = SimilarCase(
            case_id="case-123",
            case_number="PN/2024/001",
            similarity_score=0.85,
            similarity_reason="Similar corruption case",
            verdict_summary="Guilty, 3 years",
            sentence_months=36,
        )
        assert case.similarity_score == 0.85
        assert case.sentence_months == 36


class TestDeliberationMessage:
    """Tests for DeliberationMessage schema."""

    def test_user_message(self):
        msg = DeliberationMessage(
            id="msg-1",
            session_id="sess-1",
            sender=UserSender(type="user"),
            content="What do you think about this case?",
        )
        assert msg.sender.type == "user"
        assert msg.content == "What do you think about this case?"
        assert msg.cited_cases == []
        assert msg.cited_laws == []

    def test_agent_message_with_citations(self):
        msg = DeliberationMessage(
            id="msg-2",
            session_id="sess-1",
            sender=AgentSender(type="agent", agent_id=AgentId.STRICT),
            content="Based on precedent...",
            intent="legal_analysis",
            cited_cases=["case-1", "case-2"],
            cited_laws=["Article 2 UU 31/1999"],
        )
        assert msg.sender.agent_id == AgentId.STRICT
        assert len(msg.cited_cases) == 2
        assert len(msg.cited_laws) == 1


class TestSendMessageRequest:
    """Tests for SendMessageRequest schema."""

    def test_intent_extra_field_is_ignored(self):
        request = SendMessageRequest(
            content="What should the council consider?",
            target_agent="humanist",
            intent="ask_opinion",
        )

        assert request.content == "What should the council consider?"
        assert request.target_agent == "humanist"
        assert not hasattr(request, "intent")


class TestDeliberationSession:
    """Tests for DeliberationSession schema."""

    def test_session_creation(self):
        parsed = ParsedCaseInput(
            case_type=CaseType.CORRUPTION,
            summary="Test case",
        )
        case_input = CaseInput(
            input_type=InputType.TEXT_SUMMARY,
            raw_input="Test",
            parsed_case=parsed,
        )
        session = DeliberationSession(
            id="sess-1",
            status=SessionStatus.ACTIVE,
            case_input=case_input,
            similar_cases=[],
            messages=[],
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        assert session.status == SessionStatus.ACTIVE
        assert session.user_id is None
        assert session.legal_opinion is None

    def test_session_status_values(self):
        assert SessionStatus.ACTIVE.value == "active"
        assert SessionStatus.CONCLUDED.value == "concluded"


class TestCaseType:
    """Tests for CaseType enum."""

    def test_case_types(self):
        assert CaseType.CORRUPTION.value == "corruption"
        assert CaseType.NARCOTICS.value == "narcotics"
        assert CaseType.GENERAL_CRIMINAL.value == "general_criminal"
        assert CaseType.OTHER.value == "other"
