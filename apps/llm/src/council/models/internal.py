"""
Internal models for the Council service.

These models are NOT exposed via the API and are used for:
- Case parsing and classification
- Agent communication
- Internal data structures

These should NOT be added to the OpenAPI spec as they are
implementation details of the LLM service.
"""

from datetime import datetime
from enum import StrEnum
from typing import Literal

from pydantic import BaseModel, Field

# =============================================================================
# Enums (Internal)
# =============================================================================


class CaseType(StrEnum):
    """Types of legal cases (internal classification)."""

    NARCOTICS = "narcotics"
    CORRUPTION = "corruption"
    GENERAL_CRIMINAL = "general_criminal"
    OTHER = "other"


class NarcoticsIntent(StrEnum):
    """Intent classification for narcotics cases."""

    PERSONAL_USE = "personal_use"
    DISTRIBUTION = "distribution"
    UNKNOWN = "unknown"


class InputType(StrEnum):
    """Type of case input."""

    TEXT_SUMMARY = "text_summary"
    EXTRACTION_ID = "extraction_id"


class MessageIntent(StrEnum):
    """Intent classification for user messages."""

    ASK_OPINION = "ask_opinion"
    REQUEST_COMPARISON = "request_comparison"
    CHALLENGE_VIEW = "challenge_view"
    SEEK_CONSENSUS = "seek_consensus"
    GENERAL_QUESTION = "general_question"


# =============================================================================
# Case Parsing Models (Internal)
# =============================================================================


class DefendantProfile(BaseModel):
    """Profile of the defendant in a case."""

    is_first_offender: bool = True
    age: int | None = None
    occupation: str | None = None


class NarcoticsDetails(BaseModel):
    """Details specific to narcotics cases."""

    substance: str
    weight_grams: float
    intent: NarcoticsIntent = NarcoticsIntent.UNKNOWN


class CorruptionDetails(BaseModel):
    """Details specific to corruption cases."""

    state_loss_idr: float
    position: str | None = None


class StructuredCaseData(BaseModel):
    """Optional structured data that can be provided with case input."""

    defendant_age: int | None = None
    defendant_first_offender: bool | None = None
    substance_type: str | None = None
    weight_grams: float | None = None
    state_loss_idr: float | None = None


class ParsedCaseInput(BaseModel):
    """Parsed and structured case information (internal)."""

    case_type: CaseType
    summary: str
    defendant_profile: DefendantProfile | None = None
    key_facts: list[str] = Field(default_factory=list)
    charges: list[str] = Field(default_factory=list)
    narcotics: NarcoticsDetails | None = None
    corruption: CorruptionDetails | None = None


class CaseInput(BaseModel):
    """Complete case input with raw and parsed data (internal)."""

    input_type: InputType
    raw_input: str
    parsed_case: ParsedCaseInput


# =============================================================================
# Message Sender Types (Internal - Discriminated Union)
# =============================================================================


class UserSender(BaseModel):
    """Sender type for user messages."""

    type: Literal["user"] = "user"


class AgentSender(BaseModel):
    """Sender type for agent messages."""

    type: Literal["agent"] = "agent"
    agent_id: str  # Uses AgentId from generated


class SystemSender(BaseModel):
    """Sender type for system messages."""

    type: Literal["system"] = "system"


# Union type for message senders
MessageSender = UserSender | AgentSender | SystemSender


# =============================================================================
# Streaming Types (Internal)
# =============================================================================


class StreamEventType(StrEnum):
    """Types of streaming events."""

    AGENT_START = "agent_start"
    CHUNK = "chunk"
    AGENT_COMPLETE = "agent_complete"
    AGENT_ERROR = "agent_error"
    USER_MESSAGE = "user_message"
    DELIBERATION_COMPLETE = "deliberation_complete"


class StreamEventData(BaseModel):
    """Data payload for streaming events (SSE)."""

    event_type: StreamEventType
    agent_id: str | None = None
    content: str = ""
    message_id: str | None = None
    full_content: str | None = None  # Only on agent_complete

    class Config:
        """Pydantic config."""

        use_enum_values = True


class StreamMessageRequest(BaseModel):
    """Request for streaming message processing."""

    content: str = Field(..., min_length=1, max_length=5000)
    target_agent: str | None = None  # AgentId or "all"


class StreamContinueRequest(BaseModel):
    """Request for streaming continued discussion."""

    num_rounds: int = Field(
        default=1,
        ge=1,
        le=3,
        description="Number of discussion rounds (each round = all judges respond)",
    )


# =============================================================================
# Internal Response Types
# =============================================================================


class InternalSimilarCase(BaseModel):
    """A similar case found via semantic search (internal format)."""

    case_id: str
    case_number: str
    similarity_score: float
    similarity_reason: str
    verdict_summary: str
    sentence_months: int


class InternalDeliberationMessage(BaseModel):
    """A message in a deliberation session (internal format with full sender)."""

    id: str
    session_id: str
    sender: MessageSender
    content: str
    intent: str | None = None
    cited_cases: list[str] = Field(default_factory=list)
    cited_laws: list[str] = Field(default_factory=list)
    timestamp: datetime | None = None
