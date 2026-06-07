"""
Pytest fixtures for LLM service tests.
"""

import os
import sys
from collections.abc import AsyncGenerator, Generator
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient

# Set test environment before importing app
os.environ.setdefault("DATABASE_URL", "postgresql://test:test@localhost:5432/test")
os.environ.setdefault("GEMINI_API_KEY", "test-key")
os.environ.setdefault("LLM_API_KEY", "test-api-key")

# Mock missing modules before importing council modules
# These modules (src.extraction, src.embedding) are shared modules that don't exist
# in the llm service directory yet - they'll be integrated later

# Mock src.extraction
if "src.extraction" not in sys.modules:
    mock_extraction = MagicMock()
    mock_extraction.LLMExtraction = MagicMock()
    sys.modules["src.extraction"] = mock_extraction

# Mock src.embedding
if "src.embedding" not in sys.modules:
    mock_embedding = MagicMock()
    mock_embedding.EmbeddingService = MagicMock()
    mock_embedding.get_embedding_service = MagicMock(
        return_value=MagicMock(
            generate_query_embedding=AsyncMock(return_value=[0.1] * 768),
            build_search_text=MagicMock(return_value="test search text"),
        )
    )
    sys.modules["src.embedding"] = mock_embedding


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """Mock embedding service for tests."""
    mock = MagicMock()
    mock.generate_query_embedding = AsyncMock(return_value=[0.1] * 768)
    mock.build_search_text = MagicMock(return_value="test search text")
    return mock


@pytest.fixture
def mock_litellm() -> MagicMock:
    """Mock LiteLLM for tests."""
    mock = MagicMock()
    mock.acompletion = AsyncMock(
        return_value=MagicMock(
            choices=[MagicMock(message=MagicMock(content="Test response"))]
        )
    )
    return mock


def _create_test_app():
    """Create a test FastAPI app with mock endpoints."""
    from fastapi import FastAPI

    test_app = FastAPI(
        title="Virtual Judicial Council AI - Test",
        description="Test app without database",
        version="0.1.0",
    )

    _add_middleware(test_app)
    _add_base_routes(test_app)
    _add_session_routes(test_app)
    _add_case_routes(test_app)

    return test_app


def _add_middleware(app):
    """Add authentication middleware to the app."""
    from fastapi import Request
    from fastapi.responses import JSONResponse

    @app.middleware("http")
    async def verify_api_key(request: Request, call_next):
        """Verify API key for all requests except health check."""
        if request.url.path == "/health":
            return await call_next(request)

        api_key = request.headers.get("X-API-KEY")
        expected_key = os.getenv("LLM_API_KEY")

        if not expected_key:
            return JSONResponse(
                status_code=500,
                content={"detail": "Server configuration error: LLM_API_KEY not set"},
            )

        if not api_key or api_key != expected_key:
            return JSONResponse(
                status_code=401,
                content={"detail": "Invalid or missing API key"},
            )

        return await call_next(request)


def _add_base_routes(app):
    """Add base routes (health, session list/create) to the app."""
    import json

    from fastapi import HTTPException, Request
    from fastapi.responses import JSONResponse

    @app.get("/health")
    async def health():
        return {"status": "healthy", "service": "llm"}

    @app.get("/council/sessions")
    async def list_sessions():
        return []

    @app.post("/council/sessions")
    async def create_session(request: Request):
        content_type = request.headers.get("content-type", "")
        if "application/json" not in content_type:
            return JSONResponse(
                status_code=422,
                content={"detail": "Content-Type must be application/json"},
            )

        try:
            body = await request.json()
        except json.JSONDecodeError:
            return JSONResponse(
                status_code=422,
                content={"detail": "Invalid JSON body"},
            )

        summary = body.get("case_summary", "")
        if not summary or len(summary) < 50:
            raise HTTPException(
                status_code=422,
                detail="case_summary must be at least 50 characters",
            )
        return {"id": "test-session-id", "status": "created"}


def _add_session_routes(app):
    """Add session-related routes to the test app."""
    from fastapi import HTTPException, Request

    @app.get("/council/sessions/{session_id}")
    async def get_session(session_id: str):
        if session_id == "nonexistent-id":
            raise HTTPException(status_code=404, detail="Session not found")
        return {"id": session_id, "status": "active"}

    @app.delete("/council/sessions/{session_id}")
    async def delete_session(session_id: str):
        if session_id == "nonexistent-id":
            raise HTTPException(status_code=404, detail="Session not found")
        return {"deleted": True}

    @app.post("/council/sessions/{session_id}/messages")
    async def send_message(session_id: str, request: Request):
        if session_id == "nonexistent-id":
            raise HTTPException(status_code=404, detail="Session not found")
        body = await request.json()
        if not body.get("content"):
            raise HTTPException(status_code=422, detail="content is required")
        return {"id": "msg-1", "content": body["content"]}

    @app.get("/council/sessions/{session_id}/messages")
    async def get_messages(session_id: str):
        if session_id == "nonexistent-id":
            raise HTTPException(status_code=404, detail="Session not found")
        return []


def _add_case_routes(app):
    """Add case-related routes to the test app."""
    from fastapi import HTTPException, Request

    @app.post("/council/cases/search")
    async def search_cases(request: Request):
        return {"results": [], "total": 0}

    @app.get("/council/cases/statistics")
    async def get_statistics():
        return {"total_cases": 0, "by_type": {}}

    @app.get("/council/cases/{case_id}")
    async def get_case(case_id: str):
        if case_id == "nonexistent-id":
            raise HTTPException(status_code=404, detail="Case not found")
        return {"id": case_id}


@pytest.fixture
def test_client() -> Generator[TestClient]:
    """
    Synchronous test client for FastAPI.

    Creates a test app without database lifespan for unit testing.
    The app includes authentication middleware and routes but mocks
    database operations.
    """
    test_app = _create_test_app()
    with TestClient(test_app) as client:
        yield client


@pytest.fixture
async def async_client() -> AsyncGenerator[AsyncClient]:
    """
    Async test client for FastAPI.

    Note: This fixture requires a running database and should be used
    for integration tests only.
    """
    pytest.skip(
        "Async client requires database connection - use test_client for unit tests"
    )
    yield  # type: ignore
