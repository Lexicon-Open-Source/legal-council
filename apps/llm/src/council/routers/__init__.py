"""
FastAPI routers for the Virtual Judicial Council API.

Provides endpoints for:
- Session management (create, get, list, delete)
- Deliberation (send messages, get responses)
- Opinion generation
- Case search and retrieval
- Capability discovery
"""

import logging

from fastapi import APIRouter
from sqlalchemy.ext.asyncio import AsyncEngine

from src.council.agents.state_machine import set_state_machine_engine
from src.council.database import init_session_store
from src.council.dependencies import set_db_engine as _set_dependencies_db
from src.council.routers.capabilities import router as capabilities_router
from src.council.routers.cases import router as cases_router
from src.council.routers.deliberation import router as deliberation_router
from src.council.routers.sessions import router as sessions_router

logger = logging.getLogger(__name__)

# Create the main council router
council_router = APIRouter()

# Include sub-routers
council_router.include_router(
    sessions_router,
    prefix="/sessions",
    tags=["Council Sessions"],
)
council_router.include_router(
    deliberation_router,
    prefix="/deliberation",
    tags=["Council Deliberation"],
)
council_router.include_router(
    cases_router,
    prefix="/cases",
    tags=["Council Cases"],
)
council_router.include_router(
    capabilities_router,
    tags=["Council Discovery"],
)


def set_db_engine(engine: AsyncEngine) -> None:
    """
    Set the database engine for all council routes.

    This must be called during app startup before any routes are used.
    Also initializes the database-backed session store.
    """
    _set_dependencies_db(engine)
    # Initialize the database-backed session store
    init_session_store(engine)
    # Initialize the deliberation state machine (phase transitions, agreement tracking)
    set_state_machine_engine(engine)
    logger.info("Council database engine, session store, and state machine configured")


__all__ = ["council_router", "set_db_engine"]
