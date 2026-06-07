"""
Capability discovery endpoint for the Virtual Judicial Council.

Provides a programmatic discovery endpoint for external AI agents
to understand available actions, judge personalities, and valid
message intents.
"""

import logging

from fastapi import APIRouter
from pydantic import BaseModel, Field

from src.council.agents.identity import PUBLIC_TARGET_AGENT_VALUES
from src.council.models.generated import AgentId, MessageIntent, TargetAgent

logger = logging.getLogger(__name__)

router = APIRouter()


class AgentInfo(BaseModel):
    """Information about a judicial agent."""

    id: str = Field(description="Agent identifier")
    name: str = Field(description="Human-readable agent name")
    description: str = Field(description="Description of agent's judicial philosophy")


class CouncilCapabilities(BaseModel):
    """
    Available council capabilities for programmatic discovery.

    This schema enables external AI agents to understand what actions
    are available and how to interact with the judicial council.
    """

    agents: list[AgentInfo] = Field(description="Available judicial agents")
    valid_intents: list[str] = Field(description="Valid message intent classifications")
    valid_target_agents: list[str] = Field(
        description="Valid target agent values for messages"
    )
    workflow_guidance: dict[str, str] = Field(
        description="Guidance for common API workflows"
    )


# Agent metadata - centralized definitions for all judges
AGENT_METADATA: dict[AgentId, dict[str, str]] = {
    AgentId.STRICT: {
        "name": "Hakim Legalis",
        "description": (
            "Berfokus pada penerapan teks undang-undang secara ketat, "
            "konsistensi putusan, dan kepastian hukum."
        ),
    },
    AgentId.HUMANIST: {
        "name": "Hakim Humanis",
        "description": (
            "Menekankan proporsionalitas, rehabilitasi, keadaan pribadi "
            "terdakwa, dan dampak sosial pemidanaan."
        ),
    },
    AgentId.HISTORIAN: {
        "name": "Hakim Sejarawan",
        "description": (
            "Menganalisis yurisprudensi, perkembangan doktrin, dan pola "
            "putusan dalam perkara-perkara serupa."
        ),
    },
}

# Workflow guidance for API consumers
WORKFLOW_GUIDANCE: dict[str, str] = {
    "session_start": (
        "POST /council/sessions to create a session with case summary, "
        "then POST /council/deliberation/{session_id}/stream/initial to "
        "get initial opinions from all judges"
    ),
    "send_message": (
        "POST /council/deliberation/{session_id}/message for non-streaming response, "
        "or POST /council/deliberation/{session_id}/stream/message for SSE streaming"
    ),
    "continue_discussion": (
        "POST /council/deliberation/{session_id}/continue for non-streaming, "
        "or POST /council/deliberation/{session_id}/stream/continue for SSE streaming. "
        "Allows judges to continue deliberating among themselves."
    ),
    "generate_opinion": (
        "POST /council/deliberation/{session_id}/opinion to generate a structured "
        "legal opinion synthesizing the deliberation. Requires at least 3 messages."
    ),
    "conclude_session": (
        "POST /council/sessions/{session_id}/conclude to mark the session "
        "as concluded, preventing further messages."
    ),
    "download_pdf": (
        "GET /council/deliberation/{session_id}/download/pdf to download the "
        "deliberation as a PDF document."
    ),
}


@router.get("/capabilities", response_model=CouncilCapabilities)
async def get_capabilities() -> CouncilCapabilities:
    """
    Return available council capabilities for programmatic discovery.

    This endpoint enables external AI agents to discover:
    - Available judicial agents and their personalities
    - Valid message intent classifications
    - Valid target agent values
    - API workflow guidance

    Use this endpoint to understand how to interact with the
    Virtual Judicial Council API before making requests.
    """
    logger.debug("Returning council capabilities")

    agents = [
        AgentInfo(
            id=agent_id.value,
            name=metadata["name"],
            description=metadata["description"],
        )
        for agent_id, metadata in AGENT_METADATA.items()
    ]

    valid_intents = [intent.value for intent in MessageIntent]
    valid_target_agents = PUBLIC_TARGET_AGENT_VALUES + [
        target.value
        for target in TargetAgent
        if target.value not in PUBLIC_TARGET_AGENT_VALUES
    ]

    return CouncilCapabilities(
        agents=agents,
        valid_intents=valid_intents,
        valid_target_agents=valid_target_agents,
        workflow_guidance=WORKFLOW_GUIDANCE,
    )
