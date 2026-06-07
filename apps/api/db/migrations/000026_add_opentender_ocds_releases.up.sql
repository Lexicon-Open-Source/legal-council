-- OpenTender OCDS Releases table for storing OCDS data from OpenTender.net API
-- NOTE: This is separate from ocds.releases which stores SPSE→OCDS transformations

CREATE TABLE IF NOT EXISTS crawler.opentender_ocds_releases (
    -- Primary key (SHA256 hash of ocid#release_id)
    id VARCHAR(64) PRIMARY KEY,

    -- Natural key components
    ocid TEXT NOT NULL,
    release_id TEXT NOT NULL,

    -- Filter fields
    lpse_code VARCHAR(10) NOT NULL,
    fiscal_year VARCHAR(4) NOT NULL,

    -- Flattened query fields (extracted from JSONB)
    buyer_name TEXT,
    buyer_id TEXT,
    tender_title TEXT,
    tender_status TEXT,
    tender_value_amount NUMERIC(20, 2),
    tender_currency VARCHAR(3) DEFAULT 'IDR',
    date_published TIMESTAMPTZ,
    procurement_category TEXT,

    -- Full OCDS release data
    release_data JSONB NOT NULL,
    source_url TEXT NOT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT opentender_ocds_releases_id_check CHECK (id ~ '^[a-f0-9]{64}$'),
    CONSTRAINT opentender_ocds_releases_unique_release UNIQUE (ocid, release_id),
    CONSTRAINT opentender_ocds_releases_has_tender CHECK (release_data ? 'tender')
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_opentender_ocds_releases_lpse_year
    ON crawler.opentender_ocds_releases(lpse_code, fiscal_year);

CREATE INDEX IF NOT EXISTS idx_opentender_ocds_releases_buyer
    ON crawler.opentender_ocds_releases(buyer_name)
    WHERE buyer_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_opentender_ocds_releases_status
    ON crawler.opentender_ocds_releases(tender_status)
    WHERE tender_status IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_opentender_ocds_releases_created_at
    ON crawler.opentender_ocds_releases(created_at DESC);

-- GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_opentender_ocds_releases_data
    ON crawler.opentender_ocds_releases USING GIN (release_data jsonb_path_ops);

-- Trigger for updated_at
CREATE TRIGGER update_opentender_ocds_releases_updated_at
    BEFORE UPDATE ON crawler.opentender_ocds_releases
    FOR EACH ROW
    EXECUTE FUNCTION crawler.update_updated_at_column();

COMMENT ON TABLE crawler.opentender_ocds_releases IS 'OCDS releases from OpenTender.net API (distinct from ocds.releases for SPSE transformations)';
COMMENT ON COLUMN crawler.opentender_ocds_releases.id IS 'SHA256 hash of ocid#release_id';
COMMENT ON COLUMN crawler.opentender_ocds_releases.release_data IS 'Full OCDS release JSON per https://standard.open-contracting.org/';
