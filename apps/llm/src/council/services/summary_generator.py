"""
Structured summary generator for deliberation conclusions.

Produces the final recommendation document (R5) from:
- Full message transcript
- Agreement map
- Case context
- Similar cases

Uses the primary LLM model (not gemini-flash) for quality.
"""

import json
import logging
from datetime import UTC, datetime

from litellm import acompletion

from settings import get_settings

logger = logging.getLogger(__name__)

SUMMARY_SCHEMA = {
    "type": "object",
    "properties": {
        "unanimous_points": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "point": {"type": "string"},
                    "supporting_evidence": {"type": "string"},
                },
                "required": ["point"],
            },
            "description": "Points all 3 judges agree on",
        },
        "majority_position": {
            "type": "object",
            "properties": {
                "position": {"type": "string"},
                "reasoning": {"type": "string"},
                "supporting_agents": {
                    "type": "array",
                    "items": {"type": "string"},
                },
            },
            "required": ["position", "reasoning"],
        },
        "dissenting_points": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "agent": {"type": "string"},
                    "point": {"type": "string"},
                    "reasoning": {"type": "string"},
                },
                "required": ["agent", "point", "reasoning"],
            },
        },
        "cited_evidence": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "reference": {"type": "string"},
                    "source_type": {
                        "type": "string",
                        "enum": ["rag_database", "legal_doctrine"],
                    },
                    "relevance": {"type": "string"},
                },
                "required": ["reference", "source_type"],
            },
        },
        "recommended_sentencing": {
            "type": "object",
            "properties": {
                "minimum_months": {"type": "integer"},
                "maximum_months": {"type": "integer"},
                "recommended_months": {"type": "integer"},
                "reasoning": {"type": "string"},
            },
            "required": ["minimum_months", "maximum_months"],
        },
        "key_legal_arguments": {
            "type": "array",
            "items": {"type": "string"},
        },
    },
    "required": [
        "unanimous_points",
        "majority_position",
        "dissenting_points",
        "cited_evidence",
        "key_legal_arguments",
    ],
}

SUMMARY_PROMPT = """\
Anda adalah penyusun ringkasan musyawarah majelis hakim.

Berdasarkan transkrip musyawarah dan peta kesepakatan berikut, \
buat ringkasan terstruktur dari hasil musyawarah.

PETA KESEPAKATAN:
{agreement_map}

KONTEKS PERKARA:
{case_context}

PERKARA SERUPA DARI BASIS DATA:
{similar_cases}

TRANSKRIP MUSYAWARAH (ringkasan):
{transcript}

INSTRUKSI:
1. Identifikasi poin-poin yang disepakati semua hakim (unanimous_points)
2. Tentukan posisi mayoritas dengan penalaran (majority_position)
3. Catat pendapat berbeda yang tetap dipertahankan (dissenting_points)
4. Daftar bukti yang dikutip, tandai sumbernya:
   - "rag_database" untuk perkara dari basis data
   - "legal_doctrine" untuk undang-undang dan doktrin hukum
5. Rekomendasikan rentang pidana berdasarkan musyawarah
6. Daftar argumen hukum utama

Semua teks harus dalam Bahasa Indonesia.
"""


async def generate_structured_summary(
    messages: list[dict],
    agreement_map: dict,
    case_summary: str = "",
    similar_cases_text: str = "",
) -> dict:
    """
    Generate a structured summary from deliberation data.

    Args:
        messages: List of message dicts with sender and content
        agreement_map: The agreement map from phase_metadata
        case_summary: Brief case description
        similar_cases_text: Formatted similar cases text

    Returns:
        Dict matching the StructuredSummary schema, or empty dict on failure
    """
    settings = get_settings()

    # Build transcript summary (last 20 messages to fit context)
    transcript_parts = []
    for msg in messages[-20:]:
        sender = msg.get("sender", "Unknown")
        content = msg.get("content", "")
        if len(content) > 300:
            content = content[:300] + "..."
        transcript_parts.append(f"[{sender}]: {content}")
    transcript = "\n\n".join(transcript_parts)

    agreement_text = json.dumps(agreement_map, indent=2, ensure_ascii=False)

    prompt = SUMMARY_PROMPT.format(
        agreement_map=agreement_text,
        case_context=case_summary or "Tidak tersedia",
        similar_cases=similar_cases_text or "Tidak tersedia",
        transcript=transcript or "Tidak tersedia",
    )

    try:
        response = await acompletion(
            model=settings.llm_model,  # Primary model for quality
            messages=[{"role": "user", "content": prompt}],
            response_format={
                "type": "json_schema",
                "json_schema": {
                    "name": "structured_summary",
                    "schema": SUMMARY_SCHEMA,
                },
            },
        )

        content = response.choices[0].message.content
        summary = json.loads(content)
        summary["generated_at"] = datetime.now(UTC).isoformat()
        return summary

    except Exception as e:
        logger.error(f"Summary generation failed: {e}")
        return {}
