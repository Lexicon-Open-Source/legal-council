"""Shared dependencies for council routers."""

import logging
from http import HTTPStatus
from typing import Annotated

from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncEngine

logger = logging.getLogger(__name__)

_db_engine: AsyncEngine | None = None


def set_db_engine(engine: AsyncEngine) -> None:
    """Set the database engine for dependency injection."""
    global _db_engine
    _db_engine = engine
    logger.info("Council database engine set")


async def get_db_engine() -> AsyncEngine:
    """Get database engine dependency."""
    if _db_engine is None:
        raise HTTPException(
            status_code=HTTPStatus.SERVICE_UNAVAILABLE,
            detail="Database not initialized",
        )
    return _db_engine


# Type alias for FastAPI dependency injection
DbEngine = Annotated[AsyncEngine, Depends(get_db_engine)]
