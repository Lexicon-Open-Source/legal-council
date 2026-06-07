-- SPRM Malaysia Corruption Offenders
-- Source: https://www.sprm.gov.my/index.php?id=21&page_id=96
-- Stores convicted corruption offenders from Malaysia's Anti-Corruption Commission

CREATE TABLE IF NOT EXISTS crawler.sprm_offenders (
    id VARCHAR(64) PRIMARY KEY,
    source_url VARCHAR(255) NOT NULL,
    metadata JSONB NOT NULL,
    site_content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT sprm_offenders_id_check CHECK (id ~ '^[a-f0-9]{64}$'),
    CONSTRAINT sprm_offenders_metadata_accused CHECK (metadata ? 'accused')
);

COMMENT ON TABLE crawler.sprm_offenders IS 'SPRM Malaysia corruption offenders from https://www.sprm.gov.my';
COMMENT ON COLUMN crawler.sprm_offenders.id IS 'SHA256 hash of URL#data-key';
COMMENT ON COLUMN crawler.sprm_offenders.metadata IS 'Offender data: accused, id_number, gender, nationality, state, category, employer, position, court, judge, officer, defense_attorney, past_convictions, sentencing_date, appeal, charges[]';

-- Indexes for common query filters
CREATE INDEX IF NOT EXISTS idx_sprm_offenders_state ON crawler.sprm_offenders ((metadata->>'state')) WHERE metadata->>'state' IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sprm_offenders_category ON crawler.sprm_offenders ((metadata->>'category')) WHERE metadata->>'category' IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sprm_offenders_created_at ON crawler.sprm_offenders (created_at DESC);
