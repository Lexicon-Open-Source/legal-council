"""
Tests for the DeliberationStateMachine.

Tests the phase transition logic, validation rules, and edge cases.
Uses mocked database queries to test in isolation.
"""

import json
from contextlib import asynccontextmanager
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.council.agents.state_machine import (
    CONVERGENCE_SCORE_AUTO,
    CONVERGENCE_SCORE_SUGGEST,
    CONVERGENCE_SUGGEST_ROUND,
    MAX_REGRESSIONS,
    VALID_TRANSITIONS,
    DeliberationStateMachine,
    _calc_convergence_score,
)
from src.council.models.generated import AgentId, DeliberationPhase


def _make_mock_engine():
    """Create a mock async engine with proper context manager support."""
    engine = MagicMock()
    conn = MagicMock()

    @asynccontextmanager
    async def mock_begin():
        yield conn

    @asynccontextmanager
    async def mock_connect():
        yield conn

    engine.begin = mock_begin
    engine.connect = mock_connect
    return engine


class TestCanTransition:
    """Test the synchronous transition validation logic."""

    def setup_method(self):
        self.sm = DeliberationStateMachine(db_engine=MagicMock())

    def test_opening_to_debate_allowed(self):
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.OPENING,
            DeliberationPhase.DEBATE,
            {},
        )
        assert allowed is True

    def test_debate_to_convergence_allowed(self):
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.DEBATE,
            DeliberationPhase.CONVERGENCE,
            {},
        )
        assert allowed is True

    def test_convergence_to_debate_allowed(self):
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.CONVERGENCE,
            DeliberationPhase.DEBATE,
            {"agreement_map": {"regression_count": 0}},
        )
        assert allowed is True

    def test_convergence_to_summary_allowed(self):
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.CONVERGENCE,
            DeliberationPhase.SUMMARY,
            {},
        )
        assert allowed is True

    def test_legacy_to_opening_allowed(self):
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.LEGACY,
            DeliberationPhase.OPENING,
            {},
        )
        assert allowed is True

    def test_opening_to_convergence_not_allowed(self):
        """Cannot skip debate phase."""
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.OPENING,
            DeliberationPhase.CONVERGENCE,
            {},
        )
        assert allowed is False
        assert "Cannot transition" in reason

    def test_debate_to_summary_not_allowed(self):
        """Cannot skip convergence phase."""
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.DEBATE,
            DeliberationPhase.SUMMARY,
            {},
        )
        assert allowed is False

    def test_summary_to_anything_not_allowed(self):
        """Summary is a terminal phase."""
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.SUMMARY,
            DeliberationPhase.DEBATE,
            {},
        )
        assert allowed is False

    def test_legacy_to_debate_not_allowed(self):
        """Legacy can only go to opening."""
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.LEGACY,
            DeliberationPhase.DEBATE,
            {},
        )
        assert allowed is False
        assert "Legacy sessions can only transition to opening" in reason


class TestMaxRegressions:
    """Test that convergence→debate regression is limited."""

    def setup_method(self):
        self.sm = DeliberationStateMachine(db_engine=MagicMock())

    def test_regression_allowed_under_limit(self):
        for count in range(MAX_REGRESSIONS):
            allowed, _ = self.sm.can_transition(
                DeliberationPhase.CONVERGENCE,
                DeliberationPhase.DEBATE,
                {"agreement_map": {"regression_count": count}},
            )
            assert allowed is True, f"Should allow regression at count={count}"

    def test_regression_blocked_at_limit(self):
        allowed, reason = self.sm.can_transition(
            DeliberationPhase.CONVERGENCE,
            DeliberationPhase.DEBATE,
            {"agreement_map": {"regression_count": MAX_REGRESSIONS}},
        )
        assert allowed is False
        assert "Max regressions" in reason

    def test_convergence_to_summary_still_allowed_at_max_regressions(self):
        """Even at max regressions, can still go to summary."""
        allowed, _ = self.sm.can_transition(
            DeliberationPhase.CONVERGENCE,
            DeliberationPhase.SUMMARY,
            {"agreement_map": {"regression_count": MAX_REGRESSIONS}},
        )
        assert allowed is True


class TestTransitionAsync:
    """Test the async transition method with mocked DB."""

    @pytest.fixture
    def mock_engine(self):
        return _make_mock_engine()

    @pytest.mark.asyncio
    async def test_transition_session_not_found(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=None
            )
            success, msg = await sm.transition("missing-id", "debate", "test")
            assert success is False
            assert "not found" in msg

    @pytest.mark.asyncio
    async def test_transition_valid(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.OPENING
        mock_row.phase_metadata = json.dumps({})

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            querier_instance = MockQuerier.return_value
            querier_instance.get_session_phase_state = AsyncMock(return_value=mock_row)
            querier_instance.update_session_phase = AsyncMock()

            success, msg = await sm.transition(
                "session-1", DeliberationPhase.DEBATE, "all agents spoke"
            )
            assert success is True
            querier_instance.update_session_phase.assert_called_once()

    @pytest.mark.asyncio
    async def test_transition_invalid_rejected(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.OPENING
        mock_row.phase_metadata = json.dumps({})

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            querier_instance = MockQuerier.return_value
            querier_instance.get_session_phase_state = AsyncMock(return_value=mock_row)

            success, msg = await sm.transition(
                "session-1", DeliberationPhase.CONVERGENCE, "skip debate"
            )
            assert success is False
            assert "Cannot transition" in msg

    @pytest.mark.asyncio
    async def test_regression_increments_count(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.CONVERGENCE
        mock_row.phase_metadata = json.dumps(
            {"agreement_map": {"regression_count": 1, "round_count": 3}}
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            querier_instance = MockQuerier.return_value
            querier_instance.get_session_phase_state = AsyncMock(return_value=mock_row)
            querier_instance.update_session_phase = AsyncMock()

            success, _ = await sm.transition(
                "session-1", DeliberationPhase.DEBATE, "new evidence"
            )
            assert success is True

            # Verify the metadata passed to update includes incremented regression_count
            call_args = querier_instance.update_session_phase.call_args
            new_meta = json.loads(call_args.kwargs["new_metadata"])
            assert new_meta["agreement_map"]["regression_count"] == 2


class TestShouldSuggestConvergence:
    """Test convergence suggestion logic."""

    @pytest.fixture
    def mock_engine(self):
        return _make_mock_engine()

    @pytest.mark.asyncio
    async def test_suggest_when_round_threshold_reached(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.DEBATE
        mock_row.phase_metadata = json.dumps(
            {"agreement_map": {"round_count": CONVERGENCE_SUGGEST_ROUND}}
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=mock_row
            )
            assert await sm.should_suggest_convergence("session-1") is True

    @pytest.mark.asyncio
    async def test_no_suggest_below_threshold(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.DEBATE
        mock_row.phase_metadata = json.dumps(
            {"agreement_map": {"round_count": CONVERGENCE_SUGGEST_ROUND - 1}}
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=mock_row
            )
            assert await sm.should_suggest_convergence("session-1") is False

    @pytest.mark.asyncio
    async def test_no_suggest_in_wrong_phase(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.CONVERGENCE
        mock_row.phase_metadata = json.dumps({"agreement_map": {"round_count": 10}})

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=mock_row
            )
            assert await sm.should_suggest_convergence("session-1") is False

    @pytest.mark.asyncio
    async def test_no_suggest_session_not_found(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=None
            )
            assert await sm.should_suggest_convergence("missing") is False


class TestValidTransitionsCompleteness:
    """Verify the transition map is complete and consistent."""

    def test_all_phases_have_entries(self):
        for phase in DeliberationPhase:
            assert phase in VALID_TRANSITIONS, f"Missing transition entry for {phase}"

    def test_no_self_transitions(self):
        for phase, targets in VALID_TRANSITIONS.items():
            assert phase not in targets, f"Self-transition found for {phase}"

    def test_summary_is_terminal(self):
        assert VALID_TRANSITIONS[DeliberationPhase.SUMMARY] == []


class TestConvergenceScore:
    """Test the convergence score calculation."""

    def test_empty_issues(self):
        assert _calc_convergence_score({}) == 0.0

    def test_full_agreement(self):
        issues = {
            "issue1": {
                "strict": {"stance": "agree"},
                "humanist": {"stance": "agree"},
                "historian": {"stance": "agree"},
            }
        }
        assert _calc_convergence_score(issues) == 1.0

    def test_majority_agreement(self):
        issues = {
            "issue1": {
                "strict": {"stance": "agree"},
                "humanist": {"stance": "agree"},
                "historian": {"stance": "disagree"},
            }
        }
        assert _calc_convergence_score(issues) == 1.0  # 2/3 agree

    def test_no_agreement(self):
        issues = {
            "issue1": {
                "strict": {"stance": "agree"},
                "humanist": {"stance": "disagree"},
                "historian": {"stance": "partial"},
            }
        }
        assert _calc_convergence_score(issues) == 0.0

    def test_mixed_issues(self):
        issues = {
            "issue1": {
                "strict": {"stance": "agree"},
                "humanist": {"stance": "agree"},
            },
            "issue2": {
                "strict": {"stance": "agree"},
                "humanist": {"stance": "disagree"},
                "historian": {"stance": "partial"},
            },
        }
        # issue1 has agreement, issue2 doesn't = 0.5
        assert _calc_convergence_score(issues) == 0.5

    def test_no_position_excluded(self):
        issues = {
            "issue1": {
                "strict": {"stance": "agree"},
                "humanist": {"stance": "no_position"},
            },
        }
        # Only 1 real stance, need >= 2 to count
        assert _calc_convergence_score(issues) == 0.0


class TestUpdateAgreementMap:
    """Test agreement map updates."""

    @pytest.fixture
    def mock_engine(self):
        return _make_mock_engine()

    @pytest.mark.asyncio
    async def test_update_adds_positions(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.DEBATE
        mock_row.phase_metadata = json.dumps(
            {"agreement_map": {"issues": {}, "round_count": 1}}
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            querier = MockQuerier.return_value
            querier.get_session_phase_state = AsyncMock(return_value=mock_row)
            querier.update_session_phase_metadata = AsyncMock()

            result = await sm.update_agreement_map(
                "session-1",
                AgentId.STRICT,
                [
                    {
                        "issue": "pidana minimum",
                        "stance": "agree",
                        "reasoning_summary": "Harus diterapkan",
                        "round_stated": 1,
                    }
                ],
            )

            assert "pidana minimum" in result["issues"]
            assert "strict" in result["issues"]["pidana minimum"]
            assert result["convergence_score"] == 0.0  # Only 1 agent

    @pytest.mark.asyncio
    async def test_update_recalculates_score(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        existing_issues = {
            "pidana minimum": {
                "strict": {
                    "stance": "agree",
                    "reasoning_summary": "Yes",
                    "round_stated": 1,
                }
            }
        }
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.DEBATE
        mock_row.phase_metadata = json.dumps(
            {"agreement_map": {"issues": existing_issues, "round_count": 2}}
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            querier = MockQuerier.return_value
            querier.get_session_phase_state = AsyncMock(return_value=mock_row)
            querier.update_session_phase_metadata = AsyncMock()

            result = await sm.update_agreement_map(
                "session-1",
                AgentId.HUMANIST,
                [
                    {
                        "issue": "pidana minimum",
                        "stance": "agree",
                        "reasoning_summary": "Setuju",
                        "round_stated": 2,
                    }
                ],
            )

            # 2/3 agents agree = majority
            assert result["convergence_score"] == 1.0


class TestCheckConvergenceReadiness:
    """Test convergence readiness checks."""

    @pytest.fixture
    def mock_engine(self):
        return _make_mock_engine()

    @pytest.mark.asyncio
    async def test_high_score_auto_transitions(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.DEBATE
        mock_row.phase_metadata = json.dumps(
            {
                "agreement_map": {
                    "convergence_score": CONVERGENCE_SCORE_AUTO,
                    "round_count": 3,
                }
            }
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=mock_row
            )
            result = await sm.check_convergence_readiness("s1")
            assert result["should_auto_transition"] is True
            assert result["should_suggest"] is True

    @pytest.mark.asyncio
    async def test_moderate_score_suggests_only(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.DEBATE
        mock_row.phase_metadata = json.dumps(
            {
                "agreement_map": {
                    "convergence_score": CONVERGENCE_SCORE_SUGGEST,
                    "round_count": 3,
                }
            }
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=mock_row
            )
            result = await sm.check_convergence_readiness("s1")
            assert result["should_suggest"] is True
            assert result["should_auto_transition"] is False

    @pytest.mark.asyncio
    async def test_wrong_phase_no_suggestion(self, mock_engine):
        sm = DeliberationStateMachine(mock_engine)
        mock_row = MagicMock()
        mock_row.current_phase = DeliberationPhase.CONVERGENCE
        mock_row.phase_metadata = json.dumps(
            {"agreement_map": {"convergence_score": 1.0, "round_count": 10}}
        )

        with patch("src.council.agents.state_machine.CouncilQuerier") as MockQuerier:
            MockQuerier.return_value.get_session_phase_state = AsyncMock(
                return_value=mock_row
            )
            result = await sm.check_convergence_readiness("s1")
            assert result["should_suggest"] is False
