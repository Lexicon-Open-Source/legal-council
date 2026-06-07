-- Add demographic columns to entity_graph.actors.
-- All ADD COLUMN DEFAULT NULL are metadata-only on PG 17 (no table rewrite).

ALTER TABLE entity_graph.actors
    ADD COLUMN IF NOT EXISTS birth_date  TEXT,
    ADD COLUMN IF NOT EXISTS birth_place TEXT,
    ADD COLUMN IF NOT EXISTS gender      TEXT,
    ADD COLUMN IF NOT EXISTS nationality TEXT[],
    ADD COLUMN IF NOT EXISTS occupation  TEXT;

COMMENT ON COLUMN entity_graph.actors.birth_date IS 'Partial ISO 8601: YYYY, YYYY-MM, or YYYY-MM-DD';
COMMENT ON COLUMN entity_graph.actors.birth_place IS 'Place of birth (free text)';
COMMENT ON COLUMN entity_graph.actors.gender IS 'Gender (free text, e.g. male, female)';
COMMENT ON COLUMN entity_graph.actors.nationality IS 'Array of ISO country codes or nationality strings';
COMMENT ON COLUMN entity_graph.actors.occupation IS 'Occupation or profession (free text)';

-- GIN index for array containment queries on nationality
CREATE INDEX idx_eg_actors_nationality
    ON entity_graph.actors USING gin(nationality)
    WHERE NOT is_merged;

-- Partial B-tree index for birth_date lookups
CREATE INDEX idx_eg_actors_birth_date
    ON entity_graph.actors(birth_date)
    WHERE birth_date IS NOT NULL AND NOT is_merged;
