"""Shared agent identity helpers.

The API exposes Indonesian public target names while the deliberation engine
keeps the original internal AgentId enum for persistence and SSE payloads.
"""

from src.council.models.generated import AgentId

PUBLIC_TARGET_AGENT_VALUES = ["legalis", "humanis", "sejarawan", "all"]
LEGACY_TARGET_AGENT_VALUES = ["strict", "humanist", "historian"]
ACCEPTED_TARGET_AGENT_VALUES = PUBLIC_TARGET_AGENT_VALUES + LEGACY_TARGET_AGENT_VALUES

_TARGET_AGENT_ALIASES = {
    "strict": AgentId.STRICT,
    "legalis": AgentId.STRICT,
    "konstruksionis": AgentId.STRICT,
    "hakim legalis": AgentId.STRICT,
    "hakim strict": AgentId.STRICT,
    "humanist": AgentId.HUMANIST,
    "humanis": AgentId.HUMANIST,
    "hakim humanis": AgentId.HUMANIST,
    "historian": AgentId.HISTORIAN,
    "sejarawan": AgentId.HISTORIAN,
    "historis": AgentId.HISTORIAN,
    "hakim sejarawan": AgentId.HISTORIAN,
    "hakim historis": AgentId.HISTORIAN,
}

AGENT_DISPLAY_NAMES = {
    AgentId.STRICT: "Hakim Legalis",
    AgentId.HUMANIST: "Hakim Humanis",
    AgentId.HISTORIAN: "Hakim Sejarawan",
}


def _value(value: object | None) -> str | None:
    if value is None:
        return None
    if hasattr(value, "value"):
        return str(value.value)
    return str(value)


def parse_agent_id(value: object | None) -> AgentId | None:
    """Parse internal IDs and Indonesian public aliases into AgentId."""
    raw = _value(value)
    if not raw:
        return None

    normalized = raw.strip().lower()
    if normalized == "null":
        return None

    return _TARGET_AGENT_ALIASES.get(normalized)


def normalize_target_agent(value: object | None) -> str | None:
    """Normalize a public target value into orchestrator target strings."""
    raw = _value(value)
    if not raw:
        return None

    normalized = raw.strip().lower()
    if normalized == "all":
        return "all"

    agent_id = parse_agent_id(normalized)
    if agent_id:
        return agent_id.value

    return None


def agent_display_name(agent_id: AgentId) -> str:
    """Return the Indonesian display name for an internal agent ID."""
    return AGENT_DISPLAY_NAMES.get(agent_id, f"Hakim {agent_id.value.title()}")


def public_target_for_agent(agent_id: AgentId) -> str:
    """Return the public target alias for an internal agent ID."""
    public_targets = {
        AgentId.STRICT: "legalis",
        AgentId.HUMANIST: "humanis",
        AgentId.HISTORIAN: "sejarawan",
    }
    return public_targets[agent_id]
