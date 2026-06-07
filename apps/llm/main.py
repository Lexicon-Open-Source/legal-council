"""
Virtual Judicial Council AI Service

FastAPI application that provides AI-powered judicial deliberation with:
- Three-agent council (Strict, Humanist, Historian judges)
- Session-based deliberation management
- Streaming responses via SSE
- Legal opinion generation
- Semantic case search
"""

import os
from contextlib import asynccontextmanager
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from dotenv import load_dotenv

# Load .env into os.environ before anything reads env vars (litellm reads
# GEMINI_API_KEY directly from the process environment).
load_dotenv()

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import create_async_engine

from src.council import council_router, set_db_engine


def prepare_asyncpg_url(url: str) -> str:
    """
    Prepare a PostgreSQL URL for asyncpg.

    - Converts postgres:// or postgresql:// to postgresql+asyncpg://
    - Removes sslmode parameter (asyncpg uses 'ssl' instead)
    """
    # Convert to asyncpg dialect
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

    # Parse and remove unsupported parameters
    parsed = urlparse(url)
    if parsed.query:
        params = parse_qs(parsed.query)
        # Remove sslmode - asyncpg doesn't support it as query param
        params.pop("sslmode", None)
        # Rebuild query string (parse_qs returns lists, flatten them)
        new_query = urlencode({k: v[0] for k, v in params.items()})
        parsed = parsed._replace(query=new_query)

    return urlunparse(parsed)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager - handles startup and shutdown."""
    # Startup: Initialize database connection
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        raise RuntimeError("DATABASE_URL environment variable is required")

    # Prepare URL for asyncpg (handles dialect and removes unsupported params)
    db_url = prepare_asyncpg_url(db_url)

    # Note: SQLAlchemy's asyncpg dialect handles JSON/JSONB serialization.
    # JSONB values must be passed as JSON strings, not dicts, when using
    # raw SQL queries (SQLC). The database.py module handles this serialization.
    engine = create_async_engine(
        db_url,
        echo=False,
        pool_pre_ping=True,  # Verify connections are alive before use
        pool_size=5,
        max_overflow=10,
    )

    set_db_engine(engine)

    yield

    # Shutdown: Close database connection
    await engine.dispose()


# Disable docs in production (security best practice)
_is_production = os.getenv("ENVIRONMENT", "development") == "production"

app = FastAPI(
    title="Virtual Judicial Council AI",
    description="Multi-agent deliberation system for legal case analysis",
    version="0.1.0",
    lifespan=lifespan,
    # Disable Swagger UI, ReDoc, and OpenAPI spec in production
    docs_url=None if _is_production else "/docs",
    redoc_url=None if _is_production else "/redoc",
    openapi_url=None if _is_production else "/openapi.json",
)


# API Key authentication middleware
@app.middleware("http")
async def verify_api_key(request: Request, call_next):
    """Verify API key for all requests except health check."""
    # Skip authentication for health check
    if request.url.path == "/health":
        return await call_next(request)

    # Get API key from header
    api_key = request.headers.get("X-API-KEY")
    expected_key = os.getenv("LLM_API_KEY")

    # Validate API key
    if not expected_key:
        return JSONResponse(
            status_code=500,
            content={"detail": "Server configuration error: LLM_API_KEY not set"},
        )

    if not api_key or api_key != expected_key:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")

    return await call_next(request)


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok", "service": "llm"}


# Mount council router with all deliberation endpoints
app.include_router(council_router, prefix="/council")
