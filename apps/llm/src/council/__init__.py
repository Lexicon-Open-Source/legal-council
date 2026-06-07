"""
Virtual Judicial Council (AI Agent Council) for case deliberation.

This module provides an AI-powered judicial deliberation system with:
- Three distinct judge personas: Strict, Humanist, Historian
- Session-based deliberation management
- Semantic search for similar cases using embeddings
- Legal opinion generation from deliberation

Usage:
    from src.council import council_router
    app.include_router(council_router, prefix="/council")
"""

from src.council.agents import (
    AgentOrchestrator,
    HistorianAgent,
    HumanistAgent,
    StrictConstructionistAgent,
)
from src.council.models.generated import (
    AgentId,
    DeliberationMessage,
    DeliberationSession,
    ParsedCaseInput,
    SessionStatus,
)
from src.council.models.generated import (
    CouncilCaseType as CaseType,
)
from src.council.models.generated import (
    CouncilSimilarCase as SimilarCase,
)
from src.council.routers import council_router, set_db_engine

__all__ = [
    # Router and setup
    "council_router",
    "set_db_engine",
    # Agents
    "AgentOrchestrator",
    "StrictConstructionistAgent",
    "HumanistAgent",
    "HistorianAgent",
    # Schemas
    "AgentId",
    "CaseType",
    "SessionStatus",
    "ParsedCaseInput",
    "SimilarCase",
    "DeliberationSession",
    "DeliberationMessage",
]
