-- Enable trigram extension for ILIKE name searches
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Interpol Red Notice data - simplified schema
-- Stores core searchable fields + JSONB for all optional data
CREATE TABLE IF NOT EXISTS crawler.interpol_red_notices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Interpol identifier (required, unique)
    -- Note: UNIQUE constraint creates implicit B-tree index
    entity_id TEXT NOT NULL UNIQUE,

    -- Core identity fields (required for search)
    family_name TEXT NOT NULL,
    forename TEXT,

    -- Core filter fields
    nationality TEXT[] DEFAULT '{}',
    wanted_by_country TEXT NOT NULL,

    -- All other data stored as JSONB
    -- Access via: raw_data->>'charges', raw_data->>'date_of_birth', etc.
    raw_data JSONB NOT NULL DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Primary filter indexes (NO index on entity_id - UNIQUE creates it)
CREATE INDEX idx_interpol_notices_nationality ON crawler.interpol_red_notices USING GIN (nationality);
CREATE INDEX idx_interpol_notices_wanted_by ON crawler.interpol_red_notices (wanted_by_country);
CREATE INDEX idx_interpol_notices_updated_at ON crawler.interpol_red_notices (updated_at DESC);

-- Trigram indexes for ILIKE name searches (requires pg_trgm)
CREATE INDEX idx_interpol_notices_family_name_trgm ON crawler.interpol_red_notices USING GIN (family_name gin_trgm_ops);
CREATE INDEX idx_interpol_notices_forename_trgm ON crawler.interpol_red_notices USING GIN (forename gin_trgm_ops) WHERE forename IS NOT NULL;

-- Composite index for common filter combination
CREATE INDEX idx_interpol_notices_wanted_nationality ON crawler.interpol_red_notices (wanted_by_country, nationality);

-- Auto-update trigger
CREATE TRIGGER update_interpol_notices_updated_at
    BEFORE UPDATE ON crawler.interpol_red_notices
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

COMMENT ON TABLE crawler.interpol_red_notices IS 'Interpol Red Notice data - international wanted persons alerts';
COMMENT ON COLUMN crawler.interpol_red_notices.entity_id IS 'Interpol notice ID (e.g., 2025-96936)';
COMMENT ON COLUMN crawler.interpol_red_notices.raw_data IS 'Complete API response including optional fields';
