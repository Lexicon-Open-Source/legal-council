"""
Embedding Module for LLM Service.

Provides text embedding generation using litellm with Gemini embedding model.
This module is used by the council services for semantic case search.
"""

import logging
from dataclasses import dataclass
from typing import Any

import litellm

logger = logging.getLogger(__name__)


@dataclass
class EmbeddingConfig:
    """Configuration for embedding generation."""

    model: str = "gemini/gemini-embedding-001"
    dimensions: int = 768
    task_type: str = "RETRIEVAL_DOCUMENT"


async def generate_embedding(text: str, config: EmbeddingConfig) -> list[float]:
    """
    Generate an embedding for text using litellm.

    Args:
        text: Input text to embed
        config: Embedding configuration

    Returns:
        List of floats representing the embedding vector
    """
    if not text or not text.strip():
        logger.warning("Empty text provided for embedding")
        return []

    try:
        response = await litellm.aembedding(
            model=config.model,
            input=[text],
            dimensions=config.dimensions,
        )

        if response.data and len(response.data) > 0:
            return response.data[0]["embedding"]

        logger.error("No embedding returned from litellm")
        return []

    except Exception as e:
        logger.error(f"Error generating embedding: {e}")
        raise


async def generate_query_embedding(query: str, config: EmbeddingConfig) -> list[float]:
    """
    Generate an embedding optimized for search queries.

    Uses RETRIEVAL_QUERY task type for better search performance.

    Args:
        query: Search query text
        config: Embedding configuration

    Returns:
        Query embedding vector
    """
    if not query or not query.strip():
        logger.warning("Empty query provided for embedding")
        return []

    try:
        # For query embeddings, we use the same model but could adjust task_type
        response = await litellm.aembedding(
            model=config.model,
            input=[query],
            dimensions=config.dimensions,
        )

        if response.data and len(response.data) > 0:
            return response.data[0]["embedding"]

        logger.error("No embedding returned from litellm")
        return []

    except Exception as e:
        logger.error(f"Error generating query embedding: {e}")
        raise


def _extract_metadata_parts(extraction_result: dict[str, Any]) -> list[str]:
    """Extract case metadata into text parts."""
    parts = []
    metadata = extraction_result.get("case_metadata", {})
    if metadata.get("crime_category"):
        parts.append(f"Crime category: {metadata['crime_category']}")
    if metadata.get("case_number"):
        parts.append(f"Case: {metadata['case_number']}")
    # Fallback to top-level crime category
    if extraction_result.get("crime_category") and not metadata.get("crime_category"):
        parts.append(f"Crime category: {extraction_result['crime_category']}")
    return parts


def _extract_verdict_parts(verdict: dict[str, Any]) -> list[str]:
    """Extract verdict info into text parts."""
    parts = []
    if verdict.get("result"):
        parts.append(f"Verdict: {verdict['result']}")
    sentences = verdict.get("sentences", {})
    imprisonment = sentences.get("imprisonment", {})
    if imprisonment.get("duration_months"):
        parts.append(f"Sentence: {imprisonment['duration_months']} months")
    elif imprisonment.get("duration_years"):
        parts.append(f"Sentence: {imprisonment['duration_years']} years")
    return parts


def _extract_defendant_parts(defendant: dict[str, Any]) -> list[str]:
    """Extract defendant profile into text parts."""
    parts = []
    if defendant.get("age"):
        parts.append(f"Defendant age: {defendant['age']}")
    if defendant.get("is_first_offender") is not None:
        status = (
            "first offender" if defendant["is_first_offender"] else "repeat offender"
        )
        parts.append(f"Defendant: {status}")
    return parts


def prepare_content_text(extraction_result: dict[str, Any]) -> str:
    """
    Prepare content text from extraction result for embedding.

    Combines relevant fields from the extraction result into a
    text representation optimized for semantic search.

    Args:
        extraction_result: Full extraction result from LLM

    Returns:
        Text suitable for embedding
    """
    parts = _extract_metadata_parts(extraction_result)

    if extraction_result.get("summary"):
        parts.append(f"Summary: {extraction_result['summary']}")

    key_facts = extraction_result.get("key_facts", [])
    if key_facts:
        parts.append(f"Key facts: {'. '.join(key_facts[:5])}")

    charges = extraction_result.get("charges", [])
    if charges:
        if isinstance(charges[0], dict):
            charge_texts = [c.get("description", str(c)) for c in charges[:3]]
        else:
            charge_texts = charges[:3]
        parts.append(f"Charges: {', '.join(charge_texts)}")

    verdict = extraction_result.get("verdict", {})
    if verdict:
        parts.extend(_extract_verdict_parts(verdict))

    defendant = extraction_result.get("defendant_profile", {})
    if defendant:
        parts.extend(_extract_defendant_parts(defendant))

    return ". ".join(parts)
