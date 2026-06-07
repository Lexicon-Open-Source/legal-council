-- ============================================================
-- Add fuzzystrmatch extension, extraction_log table, and
-- missing unique index for entity_graph ETL pipeline.
-- ============================================================

-- Required by actor_names INSERT which uses soundex() SQL function
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- Unique constraint required by ON CONFLICT (actor_id, name_normalized) DO NOTHING
CREATE UNIQUE INDEX idx_eg_actor_names_actor_normalized
    ON entity_graph.actor_names(actor_id, name_normalized);

-- Extraction audit log: one row per (dataset, source_id) pair
CREATE TABLE entity_graph.extraction_log (
    dataset         TEXT NOT NULL,
    source_id       TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL,
    actors_created  INT NOT NULL DEFAULT 0,
    error_message   TEXT,
    source_updated_at TIMESTAMPTZ,
    extracted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (dataset, source_id),
    CONSTRAINT chk_extraction_log_status CHECK (status IN ('success', 'error', 'skipped'))
);

COMMENT ON TABLE entity_graph.extraction_log IS
    'Per-row extraction audit trail. UPSERT keyed on (dataset, source_id) so re-processing overwrites old entries.';

CREATE INDEX idx_eg_extraction_log_status ON entity_graph.extraction_log(dataset, status);
