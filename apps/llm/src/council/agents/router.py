"""
Phase-aware message routing for deliberation.

Determines which agents respond and in what order based on
classified intent and current deliberation phase.
"""

from dataclasses import dataclass, field

from src.council.agents.classifier import ClassifiedIntent
from src.council.models.generated import AgentId, DeliberationPhase, MessageIntent

# Thesis-antithesis pairs for challenge response
ANTITHESIS_MAP: dict[AgentId, AgentId] = {
    AgentId.STRICT: AgentId.HUMANIST,
    AgentId.HUMANIST: AgentId.STRICT,
    AgentId.HISTORIAN: AgentId.STRICT,
}

CONFIDENCE_THRESHOLD = 0.7
ALL_AGENTS = [AgentId.STRICT, AgentId.HUMANIST, AgentId.HISTORIAN]


@dataclass
class RoutingDecision:
    """Result of routing: which agents respond and in what order."""

    responders: list[AgentId] = field(default_factory=list)
    trigger_phase_transition: str | None = None
    emit_convergence_suggestion: bool = False


def route_message(
    classified: ClassifiedIntent,
    phase: str,
    all_agents: list[AgentId] | None = None,
) -> RoutingDecision:
    """Determine which agents respond based on intent and phase."""
    agents = all_agents or list(ALL_AGENTS)
    handler = _INTENT_HANDLERS.get(classified.intent, _handle_default)
    return handler(classified, phase, agents)


# =============================================================================
# Intent Handlers
# =============================================================================


def _handle_address_agent(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    """R11: Direct agent addressing."""
    if not ci.target_agent:
        return RoutingDecision(responders=list(agents))
    responders = [ci.target_agent]
    second = _select_challenge_responder(ci)
    if second and second != ci.target_agent:
        responders.append(second)
    return RoutingDecision(responders=responders)


def _handle_challenge(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    """R12: Challenge a position."""
    if not ci.target_agent:
        return RoutingDecision(responders=list(agents))
    responders = [ci.target_agent]
    second = _select_challenge_responder(ci)
    if second and second != ci.target_agent:
        responders.append(second)
    return RoutingDecision(responders=responders)


def _handle_evidence(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    """R13: New evidence — all agents re-evaluate."""
    transition = None
    if phase == DeliberationPhase.CONVERGENCE:
        transition = DeliberationPhase.DEBATE
    return RoutingDecision(
        responders=list(agents),
        trigger_phase_transition=transition,
    )


def _handle_consensus(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    """Request consensus or summary — trigger phase transition."""
    if phase == DeliberationPhase.DEBATE:
        return RoutingDecision(
            responders=list(agents),
            trigger_phase_transition=DeliberationPhase.CONVERGENCE,
        )
    if phase == DeliberationPhase.CONVERGENCE:
        return RoutingDecision(
            responders=[],
            trigger_phase_transition=DeliberationPhase.SUMMARY,
        )
    return RoutingDecision(responders=list(agents))


def _handle_override(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    return RoutingDecision(responders=[])


def _handle_comparison(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    """Comparison requests — Historian leads."""
    order = [AgentId.HISTORIAN]
    for a in agents:
        if a not in order:
            order.append(a)
    return RoutingDecision(responders=order[:2])


def _handle_opinion(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    if ci.target_agent:
        return RoutingDecision(responders=[ci.target_agent])
    return RoutingDecision(responders=list(agents))


def _handle_default(
    ci: ClassifiedIntent, phase: str, agents: list[AgentId]
) -> RoutingDecision:
    return RoutingDecision(responders=list(agents)[:1])


_INTENT_HANDLERS = {
    MessageIntent.ADDRESS_AGENT: _handle_address_agent,
    MessageIntent.CHALLENGE_VIEW: _handle_challenge,
    MessageIntent.INTRODUCE_EVIDENCE: _handle_evidence,
    MessageIntent.SEEK_CONSENSUS: _handle_consensus,
    MessageIntent.REQUEST_SUMMARY: _handle_consensus,
    MessageIntent.OVERRIDE_SUGGESTION: _handle_override,
    MessageIntent.REQUEST_COMPARISON: _handle_comparison,
    MessageIntent.ASK_OPINION: _handle_opinion,
}


def _select_challenge_responder(
    classified: ClassifiedIntent,
) -> AgentId | None:
    """
    Hybrid: use classifier suggestion if confidence >= 0.7,
    otherwise thesis-antithesis heuristic.
    """
    if classified.confidence >= CONFIDENCE_THRESHOLD and classified.relevant_responder:
        return classified.relevant_responder
    target = classified.target_agent
    if target:
        return ANTITHESIS_MAP.get(target)
    return None
