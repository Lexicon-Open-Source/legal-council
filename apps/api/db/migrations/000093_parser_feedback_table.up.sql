-- Parser feedback table for self-improving parser loop
CREATE TABLE IF NOT EXISTS llm_extraction.parser_feedback (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id       INTEGER NOT NULL,
    feedback_type   TEXT NOT NULL,
    field_path      TEXT,
    details         JSONB NOT NULL DEFAULT '{}',
    parser_version  TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE llm_extraction.parser_feedback IS
    'Extraction feedback for self-improving parser loop — aggregated into GitHub Issues daily';

COMMENT ON COLUMN llm_extraction.parser_feedback.feedback_type IS
    'reconciliation_diff, validation_warning, escalation, coverage_low';

COMMENT ON COLUMN llm_extraction.parser_feedback.field_path IS
    'Dotted field path, e.g. batang_tubuh[3].rincian_isi[0].huruf';

COMMENT ON COLUMN llm_extraction.parser_feedback.parser_version IS
    'Git SHA or extraction_version tag at time of feedback';

CREATE INDEX IF NOT EXISTS idx_parser_feedback_created_at
    ON llm_extraction.parser_feedback (created_at);

CREATE INDEX IF NOT EXISTS idx_parser_feedback_type
    ON llm_extraction.parser_feedback (feedback_type);
