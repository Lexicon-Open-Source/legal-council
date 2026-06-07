CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS llm_extraction;

CREATE TABLE IF NOT EXISTS llm_extraction.extraction_runs (
    run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_type TEXT NOT NULL,
    source_table TEXT NOT NULL,
    source_id TEXT NOT NULL,
    final_extraction_table TEXT,
    final_extraction_id UUID,
    pdf_sha256 TEXT NOT NULL,
    pdf_byte_size BIGINT,
    page_count INTEGER,
    storage_path TEXT,
    quality_class TEXT NOT NULL,
    intake_status TEXT NOT NULL,
    workflow_version TEXT NOT NULL,
    schema_version TEXT NOT NULL,
    run_status TEXT NOT NULL,
    error_code TEXT,
    error_message TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS extraction_runs_source_idx
    ON llm_extraction.extraction_runs (document_type, source_table, source_id);
CREATE UNIQUE INDEX IF NOT EXISTS extraction_runs_reusable_key
    ON llm_extraction.extraction_runs (
        document_type,
        source_table,
        source_id,
        pdf_sha256,
        workflow_version,
        schema_version
    );
CREATE INDEX IF NOT EXISTS extraction_runs_pdf_sha256_idx
    ON llm_extraction.extraction_runs (pdf_sha256);
CREATE INDEX IF NOT EXISTS extraction_runs_run_status_idx
    ON llm_extraction.extraction_runs (run_status);
CREATE INDEX IF NOT EXISTS extraction_runs_document_type_idx
    ON llm_extraction.extraction_runs (document_type);
CREATE INDEX IF NOT EXISTS extraction_runs_created_at_idx
    ON llm_extraction.extraction_runs (created_at);

CREATE TABLE IF NOT EXISTS llm_extraction.extraction_stage_artifacts (
    artifact_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID NOT NULL REFERENCES llm_extraction.extraction_runs(run_id),
    document_type TEXT NOT NULL,
    source_table TEXT NOT NULL,
    source_id TEXT NOT NULL,
    pdf_sha256 TEXT NOT NULL,
    stage_name TEXT NOT NULL,
    stage_status TEXT NOT NULL,
    stage_version TEXT NOT NULL,
    schema_version TEXT NOT NULL,
    prompt_version TEXT NOT NULL DEFAULT '',
    model_name TEXT NOT NULL DEFAULT '',
    attempt_number INTEGER NOT NULL,
    artifact_hash TEXT NOT NULL,
    artifact_summary JSONB NOT NULL,
    artifact_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS extraction_stage_artifacts_reusable_key
    ON llm_extraction.extraction_stage_artifacts (
        document_type,
        source_table,
        source_id,
        pdf_sha256,
        stage_name,
        stage_version,
        schema_version,
        prompt_version,
        model_name
    );
CREATE INDEX IF NOT EXISTS extraction_stage_artifacts_run_id_idx
    ON llm_extraction.extraction_stage_artifacts (run_id);
CREATE INDEX IF NOT EXISTS extraction_stage_artifacts_source_idx
    ON llm_extraction.extraction_stage_artifacts (document_type, source_id);
CREATE INDEX IF NOT EXISTS extraction_stage_artifacts_stage_name_idx
    ON llm_extraction.extraction_stage_artifacts (stage_name);
CREATE INDEX IF NOT EXISTS extraction_stage_artifacts_stage_status_idx
    ON llm_extraction.extraction_stage_artifacts (stage_status);
CREATE INDEX IF NOT EXISTS extraction_stage_artifacts_created_at_idx
    ON llm_extraction.extraction_stage_artifacts (created_at);

CREATE TABLE IF NOT EXISTS llm_extraction.extraction_review_items (
    review_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID NOT NULL REFERENCES llm_extraction.extraction_runs(run_id),
    document_type TEXT NOT NULL,
    source_table TEXT NOT NULL,
    source_id TEXT NOT NULL,
    unit_id TEXT,
    legal_path TEXT,
    page_start INTEGER,
    page_end INTEGER,
    severity TEXT NOT NULL,
    category TEXT NOT NULL,
    review_status TEXT NOT NULL,
    finding JSONB NOT NULL,
    resolution JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS extraction_review_items_source_idx
    ON llm_extraction.extraction_review_items (document_type, source_id);
CREATE INDEX IF NOT EXISTS extraction_review_items_review_status_idx
    ON llm_extraction.extraction_review_items (review_status);
CREATE INDEX IF NOT EXISTS extraction_review_items_severity_idx
    ON llm_extraction.extraction_review_items (severity);
CREATE INDEX IF NOT EXISTS extraction_review_items_category_idx
    ON llm_extraction.extraction_review_items (category);
CREATE INDEX IF NOT EXISTS extraction_review_items_created_at_idx
    ON llm_extraction.extraction_review_items (created_at);
