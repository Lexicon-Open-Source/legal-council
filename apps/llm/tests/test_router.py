"""Tests for the phase-aware message router."""

from src.council.agents.classifier import ClassifiedIntent
from src.council.agents.router import (
    CONFIDENCE_THRESHOLD,
    route_message,
)
from src.council.models.generated import AgentId, DeliberationPhase, MessageIntent


class TestRouteMessage:
    """Test routing decisions based on intent and phase."""

    def test_address_agent_routes_to_target(self):
        ci = ClassifiedIntent(
            intent=MessageIntent.ADDRESS_AGENT,
            target_agent=AgentId.HISTORIAN,
        )
        decision = route_message(ci, DeliberationPhase.DEBATE)
        assert AgentId.HISTORIAN in decision.responders
        assert decision.trigger_phase_transition is None

    def test_challenge_routes_target_plus_antithesis(self):
        ci = ClassifiedIntent(
            intent=MessageIntent.CHALLENGE_VIEW,
            target_agent=AgentId.STRICT,
            confidence=0.5,  # Below threshold, uses heuristic
        )
        decision = route_message(ci, DeliberationPhase.DEBATE)
        assert decision.responders[0] == AgentId.STRICT
        # Antithesis of Strict is Humanist
        assert AgentId.HUMANIST in decision.responders

    def test_challenge_high_confidence_uses_classifier(self):
        ci = ClassifiedIntent(
            intent=MessageIntent.CHALLENGE_VIEW,
            target_agent=AgentId.STRICT,
            relevant_responder=AgentId.HISTORIAN,
            confidence=CONFIDENCE_THRESHOLD + 0.1,
        )
        decision = route_message(ci, DeliberationPhase.DEBATE)
        assert decision.responders[0] == AgentId.STRICT
        assert AgentId.HISTORIAN in decision.responders

    def test_introduce_evidence_all_agents(self):
        ci = ClassifiedIntent(
            intent=MessageIntent.INTRODUCE_EVIDENCE,
            is_new_evidence=True,
        )
        decision = route_message(ci, DeliberationPhase.DEBATE)
        assert len(decision.responders) == 3

    def test_introduce_evidence_in_convergence_triggers_regression(self):
        ci = ClassifiedIntent(
            intent=MessageIntent.INTRODUCE_EVIDENCE,
            is_new_evidence=True,
        )
        decision = route_message(ci, DeliberationPhase.CONVERGENCE)
        assert decision.trigger_phase_transition == DeliberationPhase.DEBATE

    def test_seek_consensus_in_debate_triggers_convergence(self):
        ci = ClassifiedIntent(
            intent=MessageIntent.SEEK_CONSENSUS,
            is_convergence_request=True,
        )
        decision = route_message(ci, DeliberationPhase.DEBATE)
        assert decision.trigger_phase_transition == DeliberationPhase.CONVERGENCE

    def test_request_summary_in_convergence_triggers_summary(self):
        ci = ClassifiedIntent(
            intent=MessageIntent.REQUEST_SUMMARY,
        )
        decision = route_message(ci, DeliberationPhase.CONVERGENCE)
        assert decision.trigger_phase_transition == DeliberationPhase.SUMMARY

    def test_override_suggestion_no_responders(self):
        ci = ClassifiedIntent(intent=MessageIntent.OVERRIDE_SUGGESTION)
        decision = route_message(ci, DeliberationPhase.DEBATE)
        assert decision.responders == []

    def test_comparison_historian_leads(self):
        ci = ClassifiedIntent(intent=MessageIntent.REQUEST_COMPARISON)
        decision = route_message(ci, DeliberationPhase.DEBATE)
        assert decision.responders[0] == AgentId.HISTORIAN
