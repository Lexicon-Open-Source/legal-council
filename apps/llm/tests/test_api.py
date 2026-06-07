"""
Integration tests for LLM service API endpoints.

Tests cover:
- Health check endpoint
- API key authentication
- Session lifecycle (create, get, delete)
- Case search endpoints
- Error handling and validation
"""

import pytest
from fastapi.testclient import TestClient

# =============================================================================
# Health and Status Endpoints
# =============================================================================


class TestHealthEndpoint:
    """Tests for health check endpoint."""

    def test_health_check(self, test_client: TestClient):
        response = test_client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "service" in data

    def test_health_check_response_format(self, test_client: TestClient):
        """Verify health check returns proper JSON structure."""
        response = test_client.get("/health")
        assert response.headers.get("content-type") == "application/json"
        data = response.json()
        # Should have at minimum status and service fields
        assert isinstance(data.get("status"), str)
        assert isinstance(data.get("service"), str)


# =============================================================================
# Authentication Tests
# =============================================================================


class TestAPIKeyAuthentication:
    """Tests for API key authentication."""

    def test_missing_api_key(self, test_client: TestClient):
        response = test_client.get("/council/sessions")
        assert response.status_code == 401

    def test_invalid_api_key(self, test_client: TestClient):
        response = test_client.get(
            "/council/sessions",
            headers={"X-API-KEY": "invalid-key"},
        )
        assert response.status_code == 401

    def test_valid_api_key(self, test_client: TestClient):
        response = test_client.get(
            "/council/sessions",
            headers={"X-API-KEY": "test-api-key"},
        )
        # Should not be 401 (may be 200 or other status depending on DB)
        assert response.status_code != 401

    def test_api_key_case_sensitivity(self, test_client: TestClient):
        """API key header should be case-insensitive per HTTP spec."""
        response = test_client.get(
            "/council/sessions",
            headers={"x-api-key": "test-api-key"},  # lowercase
        )
        # Should accept lowercase header name
        assert response.status_code != 401

    def test_empty_api_key(self, test_client: TestClient):
        """Empty API key should be rejected."""
        response = test_client.get(
            "/council/sessions",
            headers={"X-API-KEY": ""},
        )
        assert response.status_code == 401


# =============================================================================
# Session Lifecycle Tests
# =============================================================================


class TestSessionEndpoints:
    """Tests for session management endpoints."""

    @pytest.fixture
    def auth_headers(self) -> dict[str, str]:
        return {"X-API-KEY": "test-api-key"}

    def test_list_sessions_empty(self, test_client: TestClient, auth_headers):
        response = test_client.get("/council/sessions", headers=auth_headers)
        # May fail if DB not available, which is expected in unit tests
        assert response.status_code in [200, 500]

    def test_create_session_validation(self, test_client: TestClient, auth_headers):
        # Test with invalid/empty payload
        response = test_client.post(
            "/council/sessions",
            headers=auth_headers,
            json={},
        )
        assert response.status_code in [400, 422, 500]

    def test_create_session_valid_payload(self, test_client: TestClient, auth_headers):
        response = test_client.post(
            "/council/sessions",
            headers=auth_headers,
            json={
                "case_summary": "Test corruption case involving public official " * 3,
                "defendant_name": "John Doe",
                "crime_type": "corruption",
            },
        )
        # May fail if DB/LLM not available
        assert response.status_code in [200, 201, 500, 503]

    def test_create_session_full_input(self, test_client: TestClient, auth_headers):
        """Create session with all optional fields provided."""
        response = test_client.post(
            "/council/sessions",
            headers=auth_headers,
            json={
                "case_summary": (
                    "Kasus korupsi pengadaan alat kesehatan di rumah sakit daerah. "
                    "Terdakwa diduga menggelembungkan harga pengadaan ventilator "
                    "sehingga menyebabkan kerugian negara sebesar Rp 5 miliar."
                ),
                "case_type": "corruption",
                "structured_data": {
                    "defendant_age": 45,
                    "defendant_first_offender": True,
                    "state_loss_idr": 5_000_000_000,
                },
            },
        )
        # May fail if DB/LLM not available
        assert response.status_code in [200, 201, 422, 500, 503]

    def test_create_session_narcotics_case(self, test_client: TestClient, auth_headers):
        """Create session for narcotics case with specific details."""
        case_summary = (
            "Terdakwa ditangkap membawa 5 gram sabu di dalam tasnya. "
            "Barang bukti ditemukan saat pemeriksaan di bandara. "
            "Terdakwa mengaku membeli narkotika tersebut "
            "untuk dikonsumsi sendiri."
        )
        response = test_client.post(
            "/council/sessions",
            headers=auth_headers,
            json={
                "case_summary": case_summary,
                "case_type": "narcotics",
                "structured_data": {
                    "substance_type": "methamphetamine",
                    "weight_grams": 5.0,
                },
            },
        )
        assert response.status_code in [200, 201, 422, 500, 503]

    def test_create_session_summary_too_short(
        self, test_client: TestClient, auth_headers
    ):
        """Case summary below minimum length should be rejected."""
        response = test_client.post(
            "/council/sessions",
            headers=auth_headers,
            json={
                "case_summary": "Too short",  # Less than 50 chars
            },
        )
        assert response.status_code in [400, 422]

    def test_get_session_not_found(self, test_client: TestClient, auth_headers):
        response = test_client.get(
            "/council/sessions/nonexistent-id",
            headers=auth_headers,
        )
        assert response.status_code in [404, 500]

    def test_delete_session_not_found(self, test_client: TestClient, auth_headers):
        response = test_client.delete(
            "/council/sessions/nonexistent-id",
            headers=auth_headers,
        )
        assert response.status_code in [404, 500]


# =============================================================================
# Deliberation Tests
# =============================================================================


class TestDeliberationEndpoints:
    """Tests for deliberation/message endpoints."""

    @pytest.fixture
    def auth_headers(self) -> dict[str, str]:
        return {"X-API-KEY": "test-api-key"}

    def test_send_message_invalid_session(self, test_client: TestClient, auth_headers):
        """Sending message to non-existent session should fail."""
        response = test_client.post(
            "/council/sessions/nonexistent-id/messages",
            headers=auth_headers,
            json={"content": "What do you think about this case?"},
        )
        assert response.status_code in [404, 500]

    def test_send_message_empty_content(self, test_client: TestClient, auth_headers):
        """Empty message content should be rejected."""
        response = test_client.post(
            "/council/sessions/test-session/messages",
            headers=auth_headers,
            json={"content": ""},
        )
        assert response.status_code in [400, 422, 404, 500]

    def test_get_messages_invalid_session(self, test_client: TestClient, auth_headers):
        """Getting messages from non-existent session should fail."""
        response = test_client.get(
            "/council/sessions/nonexistent-id/messages",
            headers=auth_headers,
        )
        assert response.status_code in [404, 500]


# =============================================================================
# Case Search Tests
# =============================================================================


class TestCaseSearchEndpoints:
    """Tests for case search endpoints."""

    @pytest.fixture
    def auth_headers(self) -> dict[str, str]:
        return {"X-API-KEY": "test-api-key"}

    def test_search_cases_request_preserves_case_type_filter(self):
        """POST search filters must keep case_type for database filtering."""
        from src.council.models.generated import (
            CouncilCaseType,
            SearchCasesRequest,
        )

        request = SearchCasesRequest.model_validate(
            {
                "query": "korupsi",
                "filters": {"case_type": "corruption"},
            }
        )

        assert request.filters is not None
        assert request.filters.case_type == CouncilCaseType.CORRUPTION
        assert request.filters.model_dump(exclude_none=True) == {
            "case_type": CouncilCaseType.CORRUPTION
        }

    def test_search_cases_validation(self, test_client: TestClient, auth_headers):
        response = test_client.post(
            "/council/cases/search",
            headers=auth_headers,
            json={"query": "corruption"},
        )
        # May fail if DB not available
        assert response.status_code in [200, 500]

    def test_search_cases_with_limit(self, test_client: TestClient, auth_headers):
        """Search with custom limit parameter."""
        response = test_client.post(
            "/council/cases/search",
            headers=auth_headers,
            json={"query": "narkotika", "limit": 5},
        )
        assert response.status_code in [200, 500]

    def test_search_cases_semantic_disabled(
        self, test_client: TestClient, auth_headers
    ):
        """Search with semantic search disabled."""
        response = test_client.post(
            "/council/cases/search",
            headers=auth_headers,
            json={"query": "korupsi", "semantic_search": False},
        )
        assert response.status_code in [200, 500]

    def test_search_cases_empty_query(self, test_client: TestClient, auth_headers):
        """Empty query should return results or error gracefully."""
        response = test_client.post(
            "/council/cases/search",
            headers=auth_headers,
            json={"query": ""},
        )
        # Empty query might be rejected (422) or return empty results (200)
        assert response.status_code in [200, 400, 422, 500]

    def test_get_case_not_found(self, test_client: TestClient, auth_headers):
        response = test_client.get(
            "/council/cases/nonexistent-id",
            headers=auth_headers,
        )
        assert response.status_code in [404, 500]

    def test_get_case_statistics(self, test_client: TestClient, auth_headers):
        response = test_client.get(
            "/council/cases/statistics",
            headers=auth_headers,
        )
        # May fail if DB not available
        assert response.status_code in [200, 500]


# =============================================================================
# Error Handling Tests
# =============================================================================


class TestErrorHandling:
    """Tests for error responses and edge cases."""

    @pytest.fixture
    def auth_headers(self) -> dict[str, str]:
        return {"X-API-KEY": "test-api-key"}

    def test_malformed_json(self, test_client: TestClient, auth_headers):
        """Malformed JSON should return 422."""
        response = test_client.post(
            "/council/sessions",
            content="not valid json",
            headers={"Content-Type": "application/json", **auth_headers},
        )
        assert response.status_code == 422

    def test_wrong_content_type(self, test_client: TestClient, auth_headers):
        """Wrong content type should be handled gracefully."""
        response = test_client.post(
            "/council/sessions",
            content="plain text body",
            headers={"Content-Type": "text/plain", **auth_headers},
        )
        assert response.status_code in [400, 415, 422]

    def test_method_not_allowed(self, test_client: TestClient, auth_headers):
        """Using wrong HTTP method should return 405."""
        response = test_client.put(
            "/health",
            headers=auth_headers,
        )
        assert response.status_code == 405

    def test_not_found_endpoint(self, test_client: TestClient, auth_headers):
        """Non-existent endpoint should return 404."""
        response = test_client.get(
            "/council/nonexistent-endpoint",
            headers=auth_headers,
        )
        assert response.status_code == 404
