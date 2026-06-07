"""
Deliberation State Machine.

Manages phase transitions for deliberation sessions.
Phase state is stored per-session in PostgreSQL, not in the singleton orchestrator.
"""

import json
import logging
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncEngine

from src.council.db.sqlc.council import AsyncQuerier as CouncilQuerier
from src.council.models.generated import AgentId, DeliberationPhase

logger = logging.getLogger(__name__)

# Valid phase transitions: {from_phase: [allowed_to_phases]}
VALID_TRANSITIONS: dict[str, list[str]] = {
    DeliberationPhase.OPENING: [DeliberationPhase.DEBATE],
    DeliberationPhase.DEBATE: [DeliberationPhase.CONVERGENCE],
    DeliberationPhase.CONVERGENCE: [
        DeliberationPhase.DEBATE,
        DeliberationPhase.SUMMARY,
    ],
    DeliberationPhase.SUMMARY: [],
    # Legacy sessions can transition to opening (upgrade path)
    DeliberationPhase.LEGACY: [DeliberationPhase.OPENING],
}

MAX_REGRESSIONS = 3
CONVERGENCE_SUGGEST_ROUND = 5
CONVERGENCE_SCORE_AUTO = 0.8  # Auto-transition threshold
CONVERGENCE_SCORE_SUGGEST = 0.6  # Suggestion threshold


class DeliberationStateMachine:
    """
    Manages deliberation phase transitions with server-side enforcement.

    All state is stored in PostgreSQL via SQLC queries.
    Phase transitions use optimistic locking (WHERE current_phase = expected).
    """

    def __init__(self, db_engine: AsyncEngine):
        self._db_engine = db_engine

    async def get_phase(self, session_id: str) -> DeliberationPhase | None:
        """Get the current phase for a session. Returns None if session not found."""
        async with self._db_engine.connect() as conn:
            querier = CouncilQuerier(conn)
            row = await querier.get_session_phase_state(id=session_id)
            if row is None:
                return None
            return DeliberationPhase(row.current_phase)

    async def get_phase_metadata(self, session_id: str) -> dict:
        """Get the full phase metadata for a session."""
        async with self._db_engine.connect() as conn:
            querier = CouncilQuerier(conn)
            row = await querier.get_session_phase_state(id=session_id)
            if row is None:
                return {}
            meta = row.phase_metadata
            if isinstance(meta, str):
                return json.loads(meta)
            return meta if isinstance(meta, dict) else {}

    def can_transition(
        self, from_phase: str, to_phase: str, metadata: dict
    ) -> tuple[bool, str]:
        """
        Check if a phase transition is valid.

        Returns:
            (allowed, reason) — reason explains why if not allowed.
        """
        if from_phase == DeliberationPhase.LEGACY:
            if to_phase == DeliberationPhase.OPENING:
                return True, ""
            return (
                False,
                f"Legacy sessions can only transition to opening, not {to_phase}",
            )

        allowed = VALID_TRANSITIONS.get(from_phase, [])
        if to_phase not in allowed:
            return False, f"Cannot transition from {from_phase} to {to_phase}"

        # Check regression limit: convergence → debate
        if (
            from_phase == DeliberationPhase.CONVERGENCE
            and to_phase == DeliberationPhase.DEBATE
        ):
            regression_count = metadata.get("agreement_map", {}).get(
                "regression_count", 0
            )
            if regression_count >= MAX_REGRESSIONS:
                return (
                    False,
                    f"Max regressions ({MAX_REGRESSIONS}) reached."
                    " Must proceed to summary.",
                )

        return True, ""

    async def transition(
        self, session_id: str, to_phase: str, reason: str
    ) -> tuple[bool, str]:
        """
        Attempt a phase transition with optimistic locking.

        Returns:
            (success, message) — message explains failure if not successful.
        """
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            row = await querier.get_session_phase_state(id=session_id)
            if row is None:
                return False, f"Session {session_id} not found"

            from_phase = row.current_phase
            meta = row.phase_metadata
            if isinstance(meta, str):
                meta = json.loads(meta)
            if not isinstance(meta, dict):
                meta = {}

            allowed, deny_reason = self.can_transition(from_phase, to_phase, meta)
            if not allowed:
                return False, deny_reason

            # Update regression count if regressing from convergence
            if (
                from_phase == DeliberationPhase.CONVERGENCE
                and to_phase == DeliberationPhase.DEBATE
            ):
                agreement_map = meta.get("agreement_map", {})
                agreement_map["regression_count"] = (
                    agreement_map.get("regression_count", 0) + 1
                )
                meta["agreement_map"] = agreement_map

            # Record phase history
            history = meta.get("phase_history", [])
            history.append(
                {
                    "phase": to_phase,
                    "entered_at": datetime.now(UTC).isoformat(),
                    "round": meta.get("agreement_map", {}).get("round_count", 0),
                    "reason": reason,
                }
            )
            meta["phase_history"] = history

            # Optimistic locking: only update if current_phase matches expected
            await querier.update_session_phase(
                session_id=session_id,
                new_phase=to_phase,
                new_metadata=json.dumps(meta),
                expected_phase=from_phase,
            )

            logger.info(f"Session {session_id}: {from_phase} → {to_phase} ({reason})")
            return True, f"Transitioned to {to_phase}"

    async def update_round_count(self, session_id: str) -> int:
        """Increment and return the round count for a session."""
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            row = await querier.get_session_phase_state(id=session_id)
            if row is None:
                return 0

            meta = row.phase_metadata
            if isinstance(meta, str):
                meta = json.loads(meta)
            if not isinstance(meta, dict):
                meta = {}

            agreement_map = meta.get("agreement_map", {})
            new_count = agreement_map.get("round_count", 0) + 1
            agreement_map["round_count"] = new_count
            meta["agreement_map"] = agreement_map

            await querier.update_session_phase_metadata(
                id=session_id, phase_metadata=json.dumps(meta)
            )
            return new_count

    async def should_suggest_convergence(self, session_id: str) -> bool:
        """Check if the system should suggest convergence based on round count."""
        async with self._db_engine.connect() as conn:
            querier = CouncilQuerier(conn)
            row = await querier.get_session_phase_state(id=session_id)
            if row is None:
                return False

            meta = row.phase_metadata
            if isinstance(meta, str):
                meta = json.loads(meta)
            if not isinstance(meta, dict):
                return False

            phase = row.current_phase
            if phase != DeliberationPhase.DEBATE:
                return False

            round_count = meta.get("agreement_map", {}).get("round_count", 0)
            return round_count >= CONVERGENCE_SUGGEST_ROUND

    async def update_agreement_map(
        self,
        session_id: str,
        agent_id: AgentId,
        positions: list[dict],
    ) -> dict:
        """
        Update the agreement map with new positions from an agent.

        Each position is a dict with: issue, stance, reasoning_summary, round_stated.
        Recalculates convergence_score after update.

        Returns the updated agreement_map dict.
        """
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            row = await querier.get_session_phase_state(id=session_id)
            if row is None:
                return {}

            meta = _parse_metadata(row.phase_metadata)
            agreement_map = meta.get("agreement_map", {})
            issues = agreement_map.get("issues", {})

            for pos in positions:
                issue_key = pos["issue"]
                if issue_key not in issues:
                    issues[issue_key] = {}
                issues[issue_key][agent_id.value] = {
                    "stance": pos["stance"],
                    "reasoning_summary": pos["reasoning_summary"],
                    "round_stated": pos["round_stated"],
                }

            agreement_map["issues"] = issues
            agreement_map["convergence_score"] = _calc_convergence_score(issues)
            meta["agreement_map"] = agreement_map

            await querier.update_session_phase_metadata(
                id=session_id, phase_metadata=json.dumps(meta)
            )
            return agreement_map

    async def check_convergence_readiness(self, session_id: str) -> dict:
        """
        Check if deliberation is ready for convergence.

        Returns dict with:
          should_suggest: bool — soft suggestion (score >= 0.6 or round >= 5)
          should_auto_transition: bool — auto-transition (score >= 0.8)
          convergence_score: float
          round_count: int
        """
        async with self._db_engine.connect() as conn:
            querier = CouncilQuerier(conn)
            row = await querier.get_session_phase_state(id=session_id)
            if row is None:
                return {
                    "should_suggest": False,
                    "should_auto_transition": False,
                    "convergence_score": 0.0,
                    "round_count": 0,
                }

            meta = _parse_metadata(row.phase_metadata)
            agreement_map = meta.get("agreement_map", {})
            score = agreement_map.get("convergence_score", 0.0)
            round_count = agreement_map.get("round_count", 0)

            phase = row.current_phase
            if phase != DeliberationPhase.DEBATE:
                return {
                    "should_suggest": False,
                    "should_auto_transition": False,
                    "convergence_score": score,
                    "round_count": round_count,
                }

            should_suggest = (
                score >= CONVERGENCE_SCORE_SUGGEST
                or round_count >= CONVERGENCE_SUGGEST_ROUND
            )
            should_auto = score >= CONVERGENCE_SCORE_AUTO

            return {
                "should_suggest": should_suggest,
                "should_auto_transition": should_auto,
                "convergence_score": score,
                "round_count": round_count,
            }

    async def _update_structured_summary(self, session_id: str, summary: dict) -> None:
        """Store a structured summary in the session."""
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            await querier.update_session_structured_summary(
                id=session_id,
                structured_summary=json.dumps(summary),
            )


def _parse_metadata(raw: object) -> dict:
    """Parse phase_metadata from DB (may be str or dict)."""
    if isinstance(raw, str):
        return json.loads(raw)
    if isinstance(raw, dict):
        return raw
    return {}


def _calc_convergence_score(issues: dict) -> float:
    """
    Calculate convergence score: proportion of issues with majority agreement.

    An issue has majority agreement if >=2 agents share the same stance
    (agree, disagree, or partial — not no_position).
    """
    if not issues:
        return 0.0

    agreed_count = 0
    for _issue_key, agent_positions in issues.items():
        stances = [
            p.get("stance", "no_position")
            for p in agent_positions.values()
            if p.get("stance") != "no_position"
        ]
        if len(stances) < 2:
            continue
        # Check if any stance appears >= 2 times
        from collections import Counter

        counts = Counter(stances)
        if counts.most_common(1)[0][1] >= 2:
            agreed_count += 1

    return agreed_count / len(issues)


# Singleton
_state_machine: DeliberationStateMachine | None = None


def get_state_machine() -> DeliberationStateMachine:
    """Get the singleton state machine instance."""
    if _state_machine is None:
        raise RuntimeError(
            "State machine not initialized. Call set_state_machine_engine() first."
        )
    return _state_machine


def set_state_machine_engine(engine: AsyncEngine) -> None:
    """Initialize the state machine with a database engine."""
    global _state_machine
    _state_machine = DeliberationStateMachine(engine)
    logger.info("Deliberation state machine initialized")
