"""Tests for the structured summary generator."""

import json
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.council.services.summary_generator import generate_structured_summary


class TestGenerateStructuredSummary:
    """Test summary generation with mocked LLM."""

    @pytest.mark.asyncio
    async def test_successful_summary(self):
        mock_summary = {
            "unanimous_points": [{"point": "Terdakwa terbukti bersalah"}],
            "majority_position": {
                "position": "Pidana penjara 5 tahun",
                "reasoning": "Sesuai dengan preseden",
                "supporting_agents": ["strict", "historian"],
            },
            "dissenting_points": [
                {
                    "agent": "humanist",
                    "point": "Pidana terlalu berat",
                    "reasoning": "Pelanggar pertama kali",
                }
            ],
            "cited_evidence": [
                {
                    "reference": "123/Pid.Sus/2024/PN JKT",
                    "source_type": "rag_database",
                    "relevance": "Kasus serupa",
                }
            ],
            "recommended_sentencing": {
                "minimum_months": 36,
                "maximum_months": 72,
                "recommended_months": 60,
                "reasoning": "Berdasarkan musyawarah",
            },
            "key_legal_arguments": ["Pasal 114 UU Narkotika berlaku"],
        }

        mock_response = MagicMock()
        mock_response.choices = [
            MagicMock(message=MagicMock(content=json.dumps(mock_summary)))
        ]

        with patch(
            "src.council.services.summary_generator.acompletion",
            new_callable=AsyncMock,
            return_value=mock_response,
        ):
            result = await generate_structured_summary(
                messages=[{"sender": "strict", "content": "Analysis..."}],
                agreement_map={"issues": {}, "convergence_score": 0.8},
                case_summary="Drug case",
            )

            assert len(result["unanimous_points"]) == 1
            assert result["majority_position"]["position"] == "Pidana penjara 5 tahun"
            assert len(result["dissenting_points"]) == 1
            assert result["cited_evidence"][0]["source_type"] == "rag_database"
            assert "generated_at" in result

    @pytest.mark.asyncio
    async def test_llm_failure_returns_empty(self):
        with patch(
            "src.council.services.summary_generator.acompletion",
            new_callable=AsyncMock,
            side_effect=Exception("API error"),
        ):
            result = await generate_structured_summary(
                messages=[],
                agreement_map={},
            )
            assert result == {}
