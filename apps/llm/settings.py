"""
Application settings for LLM service.

Uses pydantic-settings for environment variable management.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Database
    database_url: str = "postgresql://test:test@localhost:5432/test"

    # API Keys
    gemini_api_key: str = ""
    council_api_key: str = ""

    # LLM Models
    llm_model: str = "gemini/gemini-2.5-flash"
    llm_fallback_model: str | None = None
    llm_orchestrator_model: str = "gemini/gemini-2.5-flash"

    # Embedding settings (LiteLLM format: provider/model)
    embedding_model: str = "gemini/gemini-embedding-001"
    embedding_dimensions: int = 768
    embedding_task_type: str = "RETRIEVAL_DOCUMENT"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
