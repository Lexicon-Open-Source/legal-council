-- Reverse 000074: remove ETL columns, restore original indexes and CHECK constraint

-- Remove extraction_log extension
ALTER TABLE entity_graph.extraction_log
    DROP COLUMN IF EXISTS regulations_created;

-- Restore original status CHECK (ID-only values, no NULL allowance)
ALTER TABLE entity_graph.regulations
    DROP CONSTRAINT IF EXISTS chk_regulation_status;

ALTER TABLE entity_graph.regulations
    ADD CONSTRAINT chk_regulation_status CHECK (status IN ('berlaku', 'tidak_berlaku', 'dicabut', 'diubah'));

-- Recreate dropped indexes
CREATE INDEX IF NOT EXISTS idx_eg_actor_regulations_actor ON entity_graph.actor_regulations(actor_id);
CREATE INDEX IF NOT EXISTS idx_eg_regulation_links_source ON entity_graph.regulation_links(source_regulation_id);
CREATE INDEX IF NOT EXISTS idx_eg_regulation_articles_pasal ON entity_graph.regulation_articles(pasal);
CREATE INDEX IF NOT EXISTS idx_eg_regulations_properties ON entity_graph.regulations USING gin(properties jsonb_path_ops);
CREATE INDEX IF NOT EXISTS idx_eg_regulations_jurisdiction ON entity_graph.regulations(jurisdiction);

-- Drop ETL indexes
DROP INDEX IF EXISTS entity_graph.idx_eg_regulations_title_normalized;
DROP INDEX IF EXISTS entity_graph.idx_eg_regulations_form_norm_number_year;

-- Remove ETL computed columns
ALTER TABLE entity_graph.regulations
    DROP COLUMN IF EXISTS canonical_title_normalized,
    DROP COLUMN IF EXISTS form_normalized;
