"""Tests for Indonesian PDF rendering."""

from datetime import UTC, datetime

from src.council.models.generated import (
    AgentId,
    CaseInput,
    CouncilCaseType,
    CouncilDefendantProfile,
    InputType,
    LegalArguments,
    LegalOpinionDraft,
    NarcoticsDetails,
    NarcoticsIntent,
    ParsedCaseInput,
    SentenceRange,
    SentenceRecommendation,
    VerdictDecision,
    VerdictRecommendation,
)
from src.council.services.pdf_generator import (
    AGENT_NAMES,
    PDFGeneratorService,
    _localize_case_type,
    _localize_substance,
    _localize_verdict_summary,
)


def _plain_text(elements: list[object]) -> str:
    return "\n".join(
        element.getPlainText()
        for element in elements
        if hasattr(element, "getPlainText")
    )


def test_pdf_case_section_renders_indonesian_input_and_localizes_schema_enums():
    """The case parser now returns Indonesian, so free-text fields pass through
    untouched. Schema-level enum values (case_type, substance code) still map
    to Indonesian labels."""
    case_input = CaseInput(
        input_type=InputType.TEXT_SUMMARY,
        raw_input="Terdakwa membawa sabu 5 gram.",
        parsed_case=ParsedCaseInput(
            case_type=CouncilCaseType.NARCOTICS,
            summary=(
                "Terdakwa ditemukan membawa 5 gram sabu yang diakui untuk "
                "penggunaan pribadi saat razia kelab malam."
            ),
            defendant_profile=CouncilDefendantProfile(
                is_first_offender=True,
                age=28,
                occupation="pegawai swasta",
            ),
            key_facts=[
                "Terdakwa ditemukan membawa 5 gram sabu",
                "Terdakwa adalah pelanggar pertama",
            ],
            charges=[],
            narcotics=NarcoticsDetails(
                substance="methamphetamine",
                weight_grams=5.0,
                intent=NarcoticsIntent.PERSONAL_USE,
            ),
        ),
    )

    text = _plain_text(PDFGeneratorService()._build_case_section(case_input))

    # Schema enum localized to Indonesian.
    assert "narkotika" in text
    # Substance code translated via NARCOTICS_SUBSTANCE_LABELS.
    assert "sabu" in text
    # Indonesian free text passes through verbatim.
    assert "pegawai swasta" in text
    assert "Terdakwa ditemukan membawa" in text
    # Raw schema enum value never leaks into the PDF.
    assert "narcotics" not in text


def test_pdf_localizes_static_labels():
    assert AGENT_NAMES[AgentId.STRICT] == "Hakim Legalis"
    assert _localize_case_type(CouncilCaseType.CORRUPTION) == "korupsi"
    assert _localize_case_type(CouncilCaseType.NARCOTICS) == "narkotika"
    assert _localize_substance("methamphetamine") == "sabu"
    assert _localize_verdict_summary("Verdict: guilty") == "Putusan: bersalah"
    assert _localize_verdict_summary("Verdict: not_guilty") == (
        "Putusan: tidak bersalah"
    )


def test_pdf_opinion_section_localizes_verdict_and_confidence():
    opinion = LegalOpinionDraft(
        session_id="session-1",
        generated_at=datetime.now(UTC),
        case_summary="Ringkasan perkara",
        verdict_recommendation=VerdictRecommendation(
            decision=VerdictDecision.GUILTY,
            confidence="high",
            reasoning="Terdapat konsensus penuh di antara majelis hakim.",
        ),
        sentence_recommendation=SentenceRecommendation(
            imprisonment_months=SentenceRange(
                minimum=18,
                maximum=0,
                recommended=18,
            ),
            fine_idr=SentenceRange(
                minimum=0,
                maximum=0,
                recommended=0,
            ),
            additional_penalties=[
                "Mewajibkan Terdakwa mengikuti program rehabilitasi."
            ],
        ),
        legal_arguments=LegalArguments(
            for_conviction=[],
            for_leniency=[],
            for_severity=[],
        ),
    )

    text = _plain_text(PDFGeneratorService()._build_opinion_section(opinion))

    assert "Keputusan: bersalah" in text
    assert "Tingkat Keyakinan: tinggi" in text
    assert "guilty" not in text
    assert "high" not in text
