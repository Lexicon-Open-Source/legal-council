"""Tests for position extraction."""

from unittest.mock import patch

import pytest

from src.council.agents.position_extractor import extract_positions
from src.council.models.generated import AgentId


class TestExtractPositions:
    """Test position extraction with mocked LLM."""

    @pytest.mark.asyncio
    async def test_empty_content_returns_empty(self):
        result = await extract_positions(AgentId.STRICT, "", round_number=1)
        assert result == []

    @pytest.mark.asyncio
    async def test_short_content_returns_empty(self):
        result = await extract_positions(AgentId.STRICT, "Too short", round_number=1)
        assert result == []

    @pytest.mark.asyncio
    async def test_llm_failure_returns_empty(self):
        """Graceful degradation on LLM failure."""
        with patch(
            "src.council.agents.position_extractor._llm_extract",
            side_effect=Exception("API error"),
        ):
            result = await extract_positions(
                AgentId.STRICT,
                "A" * 100,  # Long enough content
                round_number=1,
            )
            assert result == []

    @pytest.mark.asyncio
    async def test_successful_extraction(self):
        """Test successful extraction with mocked LLM."""
        from src.council.agents.position_extractor import (
            ExtractedPosition,
        )

        mock_positions = [
            ExtractedPosition(
                issue="penerapan pidana minimum",
                stance="agree",
                reasoning_summary="Hukuman minimum harus diterapkan",
                round_stated=1,
            )
        ]
        with patch(
            "src.council.agents.position_extractor._llm_extract",
            return_value=mock_positions,
        ):
            result = await extract_positions(
                AgentId.STRICT,
                "A" * 100,
                round_number=1,
            )
            assert len(result) == 1
            assert result[0].issue == "penerapan pidana minimum"
            assert result[0].stance == "agree"
