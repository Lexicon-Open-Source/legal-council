"""
Unit tests for database operations.
"""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.council.database import (
    _case_type_filter_patterns,
    _dict_to_sender,
    _sender_to_dict,
)
from src.council.models.generated import (
    AgentId,
    AgentSender,
    CouncilCaseType,
    SystemSender,
    UserSender,
)


class TestSenderConversion:
    """Tests for sender serialization/deserialization."""

    def test_user_sender_to_dict(self):
        sender = UserSender(type="user")
        result = _sender_to_dict(sender)
        assert result == {"type": "user"}

    def test_agent_sender_to_dict(self):
        sender = AgentSender(type="agent", agent_id=AgentId.STRICT)
        result = _sender_to_dict(sender)
        assert result == {"type": "agent", "agent_id": "strict"}

    def test_system_sender_to_dict(self):
        sender = SystemSender(type="system")
        result = _sender_to_dict(sender)
        assert result == {"type": "system"}

    def test_dict_to_user_sender(self):
        data = {"type": "user"}
        result = _dict_to_sender(data)
        assert isinstance(result, UserSender)

    def test_dict_to_agent_sender(self):
        data = {"type": "agent", "agent_id": "humanist"}
        result = _dict_to_sender(data)
        assert isinstance(result, AgentSender)
        assert result.agent_id == AgentId.HUMANIST

    def test_dict_to_system_sender(self):
        data = {"type": "system"}
        result = _dict_to_sender(data)
        assert isinstance(result, SystemSender)

    def test_dict_to_sender_unknown_type(self):
        data = {"type": "unknown"}
        result = _dict_to_sender(data)
        # Should default to SystemSender for unknown types
        assert isinstance(result, SystemSender)

    def test_roundtrip_user_sender(self):
        original = UserSender(type="user")
        serialized = _sender_to_dict(original)
        restored = _dict_to_sender(serialized)
        assert isinstance(restored, UserSender)

    def test_roundtrip_agent_sender(self):
        original = AgentSender(type="agent", agent_id=AgentId.HISTORIAN)
        serialized = _sender_to_dict(original)
        restored = _dict_to_sender(serialized)
        assert isinstance(restored, AgentSender)
        assert restored.agent_id == original.agent_id


class TestSessionStoreUnit:
    """Unit tests for SessionStore (mocked database)."""

    @pytest.fixture
    def mock_db_engine(self):
        """Mock async database engine."""
        return MagicMock()

    def test_session_store_initialization(self, mock_db_engine):
        """Test that SessionStore can be initialized."""
        from src.council.database import SessionStore

        store = SessionStore(mock_db_engine)
        assert store._db_engine == mock_db_engine


class TestCaseDatabaseUnit:
    """Unit tests for CaseDatabase (mocked database)."""

    @pytest.fixture
    def mock_db_engine(self):
        """Mock async database engine."""
        return MagicMock()

    @pytest.fixture
    def mock_embedding_service(self):
        """Mock embedding service."""
        mock = MagicMock()
        mock.generate_query_embedding = AsyncMock(return_value=[0.1] * 768)
        mock.build_search_text = MagicMock(return_value="test search text")
        return mock

    def test_case_database_initialization(self, mock_db_engine):
        """Test that CaseDatabase can be initialized."""
        with patch("src.council.database.get_council_embedding_service"):
            from src.council.database import CaseDatabase

            db = CaseDatabase(mock_db_engine)
            assert db.db_engine == mock_db_engine

    @pytest.mark.parametrize(
        ("case_type", "expected_patterns"),
        [
            (CouncilCaseType.CORRUPTION, ["%korupsi%", "%corruption%"]),
            ("corruption", ["%korupsi%", "%corruption%"]),
            ("korupsi", ["%korupsi%", "%corruption%"]),
            (CouncilCaseType.NARCOTICS, ["%narkotika%", "%narcotics%"]),
            ("narcotics", ["%narkotika%", "%narcotics%"]),
            ("narkotika", ["%narkotika%", "%narcotics%"]),
            ("general_criminal", ["%general_criminal%"]),
        ],
    )
    def test_case_type_filter_patterns_include_storage_terms(
        self, case_type, expected_patterns
    ):
        assert _case_type_filter_patterns(case_type) == expected_patterns

    @pytest.mark.asyncio
    async def test_semantic_search_expands_corruption_filter(self, monkeypatch):
        from src.council import database as database_module
        from src.council.database import CaseDatabase

        class FakeRow:
            def __init__(self, extraction_id, similarity):
                self.extraction_id = extraction_id
                self.similarity = similarity

        class FakeConnection:
            async def __aenter__(self):
                return object()

            async def __aexit__(self, exc_type, exc, tb):
                return False

        class FakeEngine:
            def connect(self):
                return FakeConnection()

        class FakeExtractionQuerier:
            calls = []

            def __init__(self, conn):
                self.conn = conn

            async def find_similar_cases_by_embedding_with_filter(
                self, *, dollar_1, limit, dollar_3
            ):
                # Capture the full pattern array from the single round trip;
                # SQL ordering (similarity DESC) is mocked here to assert that
                # the Python layer no longer re-sorts.
                self.calls.append(list(dollar_3))
                for row in [
                    FakeRow("id-corruption", 0.91),
                    FakeRow("id-korupsi", 0.72),
                ]:
                    yield row

        embedding_service = MagicMock()
        embedding_service.generate_query_embedding = AsyncMock(return_value=[0.1, 0.2])

        monkeypatch.setattr(database_module, "ExtractionQuerier", FakeExtractionQuerier)
        monkeypatch.setattr(
            database_module,
            "get_council_embedding_service",
            lambda: embedding_service,
        )

        db = CaseDatabase(FakeEngine())
        db.row_to_case_record = MagicMock(side_effect=lambda row: row.extraction_id)

        results = await db._semantic_search(
            "korupsi",
            limit=10,
            filters={"case_type": CouncilCaseType.CORRUPTION.value},
        )

        # One round trip, both bilingual patterns passed as an array.
        assert FakeExtractionQuerier.calls == [["%korupsi%", "%corruption%"]]
        assert results == ["id-corruption", "id-korupsi"]
