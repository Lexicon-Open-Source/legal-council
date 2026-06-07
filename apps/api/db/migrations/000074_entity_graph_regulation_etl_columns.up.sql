-- ============================================================
-- ETL-specific additions to regulation tables (000073)
-- Adds computed columns, optimizes indexes, extends status CHECK
-- ============================================================

-- =====
-- 1. Add ETL computed columns to regulations
-- =====
ALTER TABLE entity_graph.regulations
    ADD COLUMN form_normalized VARCHAR(100),
    ADD COLUMN canonical_title_normalized TEXT;

COMMENT ON COLUMN entity_graph.regulations.form_normalized IS 'Canonical lowercase form (uu, pp, perpres) for content hash and lookup. Computed by ETL, not DB-generated.';
COMMENT ON COLUMN entity_graph.regulations.canonical_title_normalized IS 'NFKD-normalized, lowercased title for codex law dedup (KUHP, KUHPerdata). Used when number/year are NULL. Computed by ETL.';

-- =====
-- 2. Add indexes for ETL computed columns
-- =====
CREATE INDEX idx_eg_regulations_form_norm_number_year
    ON entity_graph.regulations(jurisdiction, form_normalized, number, year);

CREATE INDEX idx_eg_regulations_title_normalized
    ON entity_graph.regulations(canonical_title_normalized)
    WHERE canonical_title_normalized IS NOT NULL;

-- =====
-- 3. Drop redundant indexes (covered by leftmost prefix of existing composite indexes)
-- =====

-- idx_eg_regulations_jurisdiction: covered by idx_eg_regulations_form_number_year (jurisdiction, form, number, year)
DROP INDEX IF EXISTS entity_graph.idx_eg_regulations_jurisdiction;

-- idx_eg_regulations_properties: premature GIN — no queries use @> at launch, ~28k rows don't benefit
DROP INDEX IF EXISTS entity_graph.idx_eg_regulations_properties;

-- idx_eg_regulation_articles_pasal: low selectivity, pasal queries always filter by regulation_id first
DROP INDEX IF EXISTS entity_graph.idx_eg_regulation_articles_pasal;

-- idx_eg_regulation_links_source: covered by idx_eg_regulation_links_unique (source_regulation_id, target_regulation_id, link_type)
DROP INDEX IF EXISTS entity_graph.idx_eg_regulation_links_source;

-- idx_eg_actor_regulations_actor: covered by idx_eg_actor_regulations_unique (actor_id, regulation_id, role)
DROP INDEX IF EXISTS entity_graph.idx_eg_actor_regulations_actor;

-- =====
-- 4. Extend status CHECK for multi-jurisdiction (allow NULL + SG/MY values)
-- =====
ALTER TABLE entity_graph.regulations
    DROP CONSTRAINT chk_regulation_status;

ALTER TABLE entity_graph.regulations
    ADD CONSTRAINT chk_regulation_status CHECK (
        status IS NULL OR status IN (
            'berlaku', 'tidak_berlaku', 'dicabut', 'diubah',  -- ID
            'current', 'repealed', 'revised'                   -- SG/MY
        )
    );

-- =====
-- 5. Extend extraction_log for regulation audit
-- =====
ALTER TABLE entity_graph.extraction_log
    ADD COLUMN regulations_created INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN entity_graph.extraction_log.regulations_created IS 'Number of regulation entities created during extraction run. Matches actors_created pattern.';
