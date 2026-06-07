"""
Unit tests for council services.

Tests cover:
- Case parser service
- Parsing from text input
- Parsing from extraction results
- Type conversions and mappings
"""

import sys
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# Mock missing modules before importing council modules
# These modules (src.extraction, src.embedding) are shared modules that don't exist
# in the llm service directory yet - they'll be integrated later

if "src.extraction" not in sys.modules:
    mock_extraction = MagicMock()
    mock_extraction.LLMExtraction = MagicMock()
    sys.modules["src.extraction"] = mock_extraction

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

# Now we can import the council modules
from src.council.schemas import (  # noqa: E402
    CaseInput,
    CaseType,
    CorruptionDetails,
    DefendantProfile,
    InputType,
    NarcoticsDetails,
    NarcoticsIntent,
    ParsedCaseInput,
    StructuredCaseData,
)
from src.council.services.case_parser import CaseParserService  # noqa: E402

# =============================================================================
# Case Parser Service Tests
# =============================================================================


class TestCaseParserServiceInit:
    """Tests for case parser service initialization."""

    def test_service_initializes(self):
        """Service initializes without error."""
        with patch("src.council.services.case_parser.get_settings") as mock_settings:
            mock_settings.return_value = MagicMock(llm_model="test-model")
            service = CaseParserService()
            assert service.model == "test-model"


class TestCaseParserValidation:
    """Tests for input validation in case parser."""

    @pytest.fixture
    def parser(self):
        """Create parser service for tests."""
        with patch("src.council.services.case_parser.get_settings") as mock_settings:
            mock_settings.return_value = MagicMock(llm_model="test-model")
            return CaseParserService()

    @pytest.mark.asyncio
    async def test_parse_empty_input_raises(self, parser):
        """Empty input raises validation error."""
        with pytest.raises(ValueError, match="at least 50 characters"):
            await parser.parse_case(case_text="")

    @pytest.mark.asyncio
    async def test_parse_short_input_raises(self, parser):
        """Input below 50 characters raises validation error."""
        with pytest.raises(ValueError, match="at least 50 characters"):
            await parser.parse_case(case_text="Too short case text")

    @pytest.mark.asyncio
    async def test_parse_whitespace_only_raises(self, parser):
        """Whitespace-only input raises validation error."""
        with pytest.raises(ValueError, match="at least 50 characters"):
            await parser.parse_case(case_text="   \n\t   ")


class TestBuildParsedCase:
    """Tests for _build_parsed_case helper method."""

    @pytest.fixture
    def parser(self):
        """Create parser service for tests."""
        with patch("src.council.services.case_parser.get_settings") as mock_settings:
            mock_settings.return_value = MagicMock(llm_model="test-model")
            return CaseParserService()

    def test_build_minimal_case(self, parser):
        """Build case from minimal LLM response."""
        result = {
            "case_type": "corruption",
            "summary": "Test corruption case",
            "key_facts": [],
            "charges": [],
        }
        parsed = parser._build_parsed_case(result, "original text")

        assert parsed.case_type == CaseType.CORRUPTION
        assert parsed.summary == "Test corruption case"
        assert parsed.key_facts == []
        assert parsed.charges == []

    def test_build_narcotics_case(self, parser):
        """Build narcotics case with substance details."""
        result = {
            "case_type": "narcotics",
            "summary": "Drug possession case",
            "key_facts": ["Found with drugs", "At airport"],
            "charges": ["Pasal 127 UU Narkotika"],
            "narcotics": {
                "substance": "methamphetamine",
                "weight_grams": 5.0,
                "intent": "personal_use",
            },
        }
        parsed = parser._build_parsed_case(result, "original text")

        assert parsed.case_type == CaseType.NARCOTICS
        assert parsed.narcotics is not None
        assert parsed.narcotics.substance == "methamphetamine"
        assert parsed.narcotics.weight_grams == 5.0
        assert parsed.narcotics.intent == NarcoticsIntent.PERSONAL_USE

    def test_build_corruption_case(self, parser):
        """Build corruption case with state loss details."""
        result = {
            "case_type": "corruption",
            "summary": "Procurement fraud case",
            "key_facts": ["Inflated prices"],
            "charges": ["Pasal 2 UU Tipikor"],
            "corruption": {
                "state_loss_idr": 5_000_000_000,
                "position": "Director",
            },
        }
        parsed = parser._build_parsed_case(result, "original text")

        assert parsed.case_type == CaseType.CORRUPTION
        assert parsed.corruption is not None
        assert parsed.corruption.state_loss_idr == 5_000_000_000
        assert parsed.corruption.position == "Director"

    def test_build_case_with_defendant_profile(self, parser):
        """Build case with defendant profile."""
        result = {
            "case_type": "general_criminal",
            "summary": "Theft case",
            "key_facts": [],
            "charges": [],
            "defendant_profile": {
                "is_first_offender": False,
                "age": 35,
                "occupation": "unemployed",
            },
        }
        parsed = parser._build_parsed_case(result, "original text")

        assert parsed.defendant_profile is not None
        assert parsed.defendant_profile.is_first_offender is False
        assert parsed.defendant_profile.age == 35
        assert parsed.defendant_profile.occupation == "unemployed"

    def test_build_case_unknown_type(self, parser):
        """Unknown case type defaults to OTHER."""
        result = {
            "case_type": "invalid_type",
            "summary": "Some case",
            "key_facts": [],
            "charges": [],
        }
        parsed = parser._build_parsed_case(result, "original text")

        assert parsed.case_type == CaseType.OTHER

    def test_build_case_missing_summary_uses_original(self, parser):
        """Missing summary uses truncated original text."""
        result = {
            "case_type": "corruption",
            "key_facts": [],
            "charges": [],
        }
        original = "A" * 600  # Long original text
        parsed = parser._build_parsed_case(result, original)

        assert parsed.summary == original[:500]

    def test_build_narcotics_unknown_intent(self, parser):
        """Unknown narcotics intent defaults to UNKNOWN."""
        result = {
            "case_type": "narcotics",
            "summary": "Drug case",
            "key_facts": [],
            "charges": [],
            "narcotics": {
                "substance": "unknown",
                "weight_grams": 1.0,
                "intent": "invalid_intent",
            },
        }
        parsed = parser._build_parsed_case(result, "original text")

        assert parsed.narcotics.intent == NarcoticsIntent.UNKNOWN


class TestParseFromExtraction:
    """Tests for parsing from extraction results."""

    @pytest.fixture
    def parser(self):
        """Create parser service for tests."""
        with patch("src.council.services.case_parser.get_settings") as mock_settings:
            mock_settings.return_value = MagicMock(llm_model="test-model")
            return CaseParserService()

    @pytest.mark.asyncio
    async def test_parse_corruption_extraction(self, parser):
        """Parse corruption case from extraction result."""
        extraction_result = {
            "case_metadata": {"crime_category": "korupsi"},
            "defendant": {"age": 50, "occupation": "PNS"},
            "state_loss": {"proven_amount": 1_000_000_000},
            "indictment": {"chronology": "Defendant embezzled funds"},
            "legal_facts": {"violations": ["Mark-up pricing"]},
        }

        result = await parser.parse_from_extraction(
            extraction_result=extraction_result,
            summary_id="Ringkasan kasus korupsi",
        )

        assert result.input_type == InputType.EXTRACTION_ID
        assert result.parsed_case.case_type == CaseType.CORRUPTION
        assert result.parsed_case.corruption is not None
        assert result.parsed_case.corruption.state_loss_idr == 1_000_000_000

    @pytest.mark.asyncio
    async def test_parse_narcotics_extraction(self, parser):
        """Parse narcotics case from extraction result."""
        extraction_result = {
            "case_metadata": {"crime_category": "narkotika"},
            "defendant": {"age": 25},
            "indictment": {"chronology": "Defendant caught with drugs"},
        }

        result = await parser.parse_from_extraction(
            extraction_result=extraction_result,
        )

        assert result.parsed_case.case_type == CaseType.NARCOTICS
        assert result.parsed_case.narcotics is not None

    @pytest.mark.asyncio
    async def test_parse_general_criminal_extraction(self, parser):
        """Parse general criminal case from extraction result."""
        extraction_result = {
            "case_metadata": {"crime_category": "pencurian"},
            "defendant": {"age": 30},
        }

        result = await parser.parse_from_extraction(
            extraction_result=extraction_result,
        )

        assert result.parsed_case.case_type == CaseType.GENERAL_CRIMINAL

    @pytest.mark.asyncio
    async def test_parse_unknown_category_extraction(self, parser):
        """Unknown category defaults to OTHER."""
        extraction_result = {
            "case_metadata": {},
            "defendant": {},
        }

        result = await parser.parse_from_extraction(
            extraction_result=extraction_result,
        )

        assert result.parsed_case.case_type == CaseType.OTHER

    @pytest.mark.asyncio
    async def test_parse_extraction_uses_english_summary(self, parser):
        """English summary is preferred when available."""
        extraction_result = {
            "case_metadata": {"crime_category": "korupsi"},
        }

        result = await parser.parse_from_extraction(
            extraction_result=extraction_result,
            summary_en="English summary of the case",
            summary_id="Ringkasan dalam Bahasa Indonesia",
        )

        assert result.parsed_case.summary == "English summary of the case"

    @pytest.mark.asyncio
    async def test_parse_extraction_extracts_charges(self, parser):
        """Charges are extracted from indictment."""
        extraction_result = {
            "case_metadata": {"crime_category": "korupsi"},
            "indictment": {
                "cited_articles": [
                    {"full_citation": "Pasal 2 UU 31/1999"},
                    {"article": "Pasal 3"},
                ],
            },
        }

        result = await parser.parse_from_extraction(
            extraction_result=extraction_result,
        )

        assert len(result.parsed_case.charges) >= 1
        assert any("Pasal 2" in c for c in result.parsed_case.charges)


# =============================================================================
# Schema Tests
# =============================================================================


class TestParsedCaseInputSchema:
    """Tests for ParsedCaseInput schema validation."""

    def test_minimal_valid_case(self):
        """Minimal case input is valid."""
        case = ParsedCaseInput(
            case_type=CaseType.CORRUPTION,
            summary="Test case summary",
        )
        assert case.case_type == CaseType.CORRUPTION
        assert case.summary == "Test case summary"
        assert case.key_facts == []
        assert case.charges == []

    def test_full_case_with_narcotics(self):
        """Full case with narcotics details."""
        case = ParsedCaseInput(
            case_type=CaseType.NARCOTICS,
            summary="Narcotics possession case",
            defendant_profile=DefendantProfile(
                is_first_offender=True,
                age=25,
            ),
            key_facts=["Arrested at checkpoint", "Found with substances"],
            charges=["Pasal 127 UU Narkotika"],
            narcotics=NarcoticsDetails(
                substance="methamphetamine",
                weight_grams=2.5,
                intent=NarcoticsIntent.PERSONAL_USE,
            ),
        )
        assert case.narcotics is not None
        assert case.narcotics.substance == "methamphetamine"

    def test_full_case_with_corruption(self):
        """Full case with corruption details."""
        case = ParsedCaseInput(
            case_type=CaseType.CORRUPTION,
            summary="Procurement fraud",
            corruption=CorruptionDetails(
                state_loss_idr=10_000_000_000,
                position="Director of Procurement",
            ),
        )
        assert case.corruption is not None
        assert case.corruption.state_loss_idr == 10_000_000_000


class TestCaseInputSchema:
    """Tests for CaseInput schema validation."""

    def test_text_summary_input(self):
        """Text summary input type."""
        case_input = CaseInput(
            input_type=InputType.TEXT_SUMMARY,
            raw_input="Case description text",
            parsed_case=ParsedCaseInput(
                case_type=CaseType.CORRUPTION,
                summary="Parsed summary",
            ),
        )
        assert case_input.input_type == InputType.TEXT_SUMMARY

    def test_extraction_id_input(self):
        """Extraction ID input type."""
        case_input = CaseInput(
            input_type=InputType.EXTRACTION_ID,
            raw_input="extraction-123",
            parsed_case=ParsedCaseInput(
                case_type=CaseType.CORRUPTION,
                summary="Parsed summary",
            ),
        )
        assert case_input.input_type == InputType.EXTRACTION_ID


class TestStructuredCaseDataSchema:
    """Tests for StructuredCaseData schema."""

    def test_all_fields_optional(self):
        """All fields are optional."""
        data = StructuredCaseData()
        assert data.defendant_age is None
        assert data.defendant_first_offender is None
        assert data.substance_type is None
        assert data.weight_grams is None
        assert data.state_loss_idr is None

    def test_partial_fields(self):
        """Partial fields work."""
        data = StructuredCaseData(
            defendant_age=45,
            state_loss_idr=5_000_000_000,
        )
        assert data.defendant_age == 45
        assert data.state_loss_idr == 5_000_000_000
        assert data.substance_type is None
