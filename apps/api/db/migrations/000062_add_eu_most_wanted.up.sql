-- Create eu_most_wanted_fugitives table for Europol/ENFAST fugitive data
CREATE TABLE IF NOT EXISTS crawler.eu_most_wanted_fugitives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Drupal node ID (unique identifier for upsert)
    node_id TEXT NOT NULL UNIQUE,

    -- Core identity fields (required for search)
    full_name TEXT NOT NULL,
    url_slug TEXT NOT NULL,

    -- Core filter fields
    status TEXT NOT NULL DEFAULT 'Wanted',
    wanted_by_country TEXT NOT NULL,
    crimes TEXT[] DEFAULT '{}',

    -- All other data stored as JSONB
    raw_data JSONB NOT NULL DEFAULT '{}',

    -- Primary photo storage
    image_path TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-update updated_at trigger (reuses existing function)
CREATE TRIGGER set_eu_most_wanted_fugitives_updated_at
    BEFORE UPDATE ON crawler.eu_most_wanted_fugitives
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

-- Indexes for common queries
CREATE INDEX idx_eu_most_wanted_status ON crawler.eu_most_wanted_fugitives (status);
CREATE INDEX idx_eu_most_wanted_country ON crawler.eu_most_wanted_fugitives (wanted_by_country);
CREATE INDEX idx_eu_most_wanted_name_trgm ON crawler.eu_most_wanted_fugitives USING gin (full_name gin_trgm_ops);

-- Seed health check row for this crawler type
INSERT INTO crawler.health_checks (crawler_type) VALUES ('eu_most_wanted');
