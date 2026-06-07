-- Create llm_extraction.bpk_regulations table for BPK regulation PDF extraction results.
-- This stores LLM-extracted structured content from BPK regulation PDFs (L1.5 enrichment layer).

CREATE SCHEMA IF NOT EXISTS llm_extraction;

CREATE TABLE llm_extraction.bpk_regulations (
    extraction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id INTEGER NOT NULL REFERENCES crawler.bpk_regulations(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    extraction_result JSONB,
    page_count INTEGER,
    extraction_model VARCHAR(100),
    extraction_tokens_in INTEGER,
    extraction_tokens_out INTEGER,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_bpk_reg_source UNIQUE (source_id)
);

CREATE INDEX idx_bpk_reg_status ON llm_extraction.bpk_regulations(status);
