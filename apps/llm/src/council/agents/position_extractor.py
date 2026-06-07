"""
Position marker extraction for agreement tracking.

Extracts structured positions from agent responses using the
orchestrator model (gemini-flash). Runs AFTER responses are
streamed and persisted — no latency impact on user experience.
"""

import json
import logging

from litellm import acompletion

from settings import get_settings
from src.council.models.generated import AgentId, PositionStance

logger = logging.getLogger(__name__)


EXTRACTION_SCHEMA = {
    "type": "object",
    "properties": {
        "positions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "issue": {
                        "type": "string",
                        "description": "The legal issue discussed",
                    },
                    "stance": {
                        "type": "string",
                        "enum": [s.value for s in PositionStance],
                    },
                    "reasoning_summary": {
                        "type": "string",
                        "description": "1-2 sentence summary",
                    },
                },
                "required": ["issue", "stance", "reasoning_summary"],
            },
        },
    },
    "required": ["positions"],
}

EXTRACTION_PROMPT = """\
Analyze this Indonesian judicial agent's response and extract their \
positions on each legal issue discussed.

For each issue the agent addresses, identify:
1. The issue (in Indonesian, concise — e.g., "penerapan pidana minimum")
2. Their stance: agree, disagree, partial, or no_position
3. A brief reasoning summary (1-2 sentences in Indonesian)

If the agent agrees or disagrees with another judge, note that in \
the reasoning_summary.

Existing issues to check against (update stance if mentioned):
{existing_issues}

Agent response:
{response}
"""


class ExtractedPosition:
    """A single extracted position from an agent response."""

    __slots__ = ("issue", "stance", "reasoning_summary", "round_stated")

    def __init__(
        self,
        issue: str,
        stance: str,
        reasoning_summary: str,
        round_stated: int,
    ):
        self.issue = issue
        self.stance = stance
        self.reasoning_summary = reasoning_summary
        self.round_stated = round_stated


async def extract_positions(
    agent_id: AgentId,
    response_content: str,
    existing_issues: list[str] | None = None,
    round_number: int = 0,
) -> list[ExtractedPosition]:
    """
    Extract structured positions from an agent response.

    Uses the orchestrator model (fast/cheap) with structured JSON output.
    Returns empty list on failure (graceful degradation).

    Args:
        agent_id: Which agent produced this response
        response_content: The full agent response text
        existing_issues: Previously identified issues to track
        round_number: Current deliberation round

    Returns:
        List of ExtractedPosition objects
    """
    if not response_content or len(response_content) < 50:
        return []

    try:
        return await _llm_extract(
            response_content,
            existing_issues or [],
            round_number,
        )
    except Exception as e:
        logger.warning(f"Position extraction failed for {agent_id.value}: {e}")
        return []


async def _llm_extract(
    response_content: str,
    existing_issues: list[str],
    round_number: int,
) -> list[ExtractedPosition]:
    """Extract positions using LLM structured output."""
    settings = get_settings()

    issues_text = (
        "\n".join(f"- {i}" for i in existing_issues)
        if existing_issues
        else "Tidak ada isu yang teridentifikasi sebelumnya."
    )

    prompt = EXTRACTION_PROMPT.format(
        existing_issues=issues_text,
        response=response_content,
    )

    response = await acompletion(
        model=settings.llm_orchestrator_model,
        messages=[
            {"role": "user", "content": prompt},
        ],
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "position_extraction",
                "schema": EXTRACTION_SCHEMA,
            },
        },
    )

    content = response.choices[0].message.content
    data = json.loads(content)

    positions = []
    for p in data.get("positions", []):
        positions.append(
            ExtractedPosition(
                issue=p["issue"],
                stance=p["stance"],
                reasoning_summary=p["reasoning_summary"],
                round_stated=round_number,
            )
        )

    return positions
