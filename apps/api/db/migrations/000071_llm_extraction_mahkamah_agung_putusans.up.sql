-- ============================================================
-- llm_extraction schema
-- LLM-powered extraction results, separated by source table.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS llm_extraction;

-- ============================================================
-- mahkamah_agung_putusans: extraction results from court PDFs
-- Source: crawler.mahkamah_agung_putusans (putusan_id as FK)
-- ============================================================

CREATE TABLE llm_extraction.mahkamah_agung_putusans (
    id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    extraction_id         VARCHAR(64) NOT NULL UNIQUE,
    extraction_result     JSONB,
    summary_id            TEXT,
    summary_en            TEXT,
    extraction_confidence FLOAT8 CHECK (extraction_confidence >= 0.0 AND extraction_confidence <= 1.0),
    content_embedding     vector(768),
    summary_embedding_id  vector(768),
    summary_embedding_en  vector(768),
    embedding_generated   BOOLEAN NOT NULL DEFAULT FALSE,
    status                VARCHAR(50) NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending', 'extracted', 'summarized', 'completed', 'failed')),
    error_message         TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_llm_ext_ma_status ON llm_extraction.mahkamah_agung_putusans(status);
CREATE INDEX idx_llm_ext_ma_created_at ON llm_extraction.mahkamah_agung_putusans(created_at);
CREATE INDEX idx_llm_ext_ma_result_gin ON llm_extraction.mahkamah_agung_putusans USING GIN (extraction_result);

-- HNSW indexes for vector similarity search (cosine distance)
CREATE INDEX idx_llm_ext_ma_content_hnsw
    ON llm_extraction.mahkamah_agung_putusans USING hnsw (content_embedding vector_cosine_ops)
    WHERE content_embedding IS NOT NULL;

CREATE INDEX idx_llm_ext_ma_summary_id_hnsw
    ON llm_extraction.mahkamah_agung_putusans USING hnsw (summary_embedding_id vector_cosine_ops)
    WHERE summary_embedding_id IS NOT NULL;

CREATE INDEX idx_llm_ext_ma_summary_en_hnsw
    ON llm_extraction.mahkamah_agung_putusans USING hnsw (summary_embedding_en vector_cosine_ops)
    WHERE summary_embedding_en IS NOT NULL;

-- FK to crawler source table
ALTER TABLE llm_extraction.mahkamah_agung_putusans
    ADD CONSTRAINT fk_llm_ext_ma_crawler
    FOREIGN KEY (extraction_id) REFERENCES crawler.mahkamah_agung_putusans(putusan_id);

-- Auto-update updated_at on row modification
CREATE FUNCTION llm_extraction.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER set_llm_ext_ma_updated_at
    BEFORE UPDATE ON llm_extraction.mahkamah_agung_putusans
    FOR EACH ROW EXECUTE FUNCTION llm_extraction.trigger_set_timestamp();
