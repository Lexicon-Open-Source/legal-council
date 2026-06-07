-- OpenTender tenders table for storing Indonesian government procurement data
-- fetched from https://pro.opentender.net/api/tender/

CREATE TABLE IF NOT EXISTS crawler.opentender_tenders (
    id VARCHAR(64) PRIMARY KEY,
    tender_id INTEGER NOT NULL,
    lpse_code VARCHAR(10) NOT NULL,
    source_url TEXT NOT NULL,
    metadata JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ID is SHA256 hash of lpse_code#tender_id
    CONSTRAINT opentender_tenders_id_check CHECK (id ~ '^[a-f0-9]{64}$'),
    -- Metadata must contain package_name
    CONSTRAINT opentender_tenders_metadata_package CHECK (metadata ? 'package_name'),
    -- tender_id is only unique per LPSE, not globally
    CONSTRAINT opentender_tenders_unique_tender UNIQUE (lpse_code, tender_id)
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_opentender_lpse_code
    ON crawler.opentender_tenders (lpse_code);

-- Partial indexes for JSONB fields (following SPRM pattern for better performance)
CREATE INDEX IF NOT EXISTS idx_opentender_fiscal_year
    ON crawler.opentender_tenders ((metadata->>'fiscal_year'))
    WHERE metadata->>'fiscal_year' IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_opentender_category
    ON crawler.opentender_tenders ((metadata->>'category_label'))
    WHERE metadata->>'category_label' IS NOT NULL;

-- For ordering by created_at DESC (most common query)
CREATE INDEX IF NOT EXISTS idx_opentender_created_at
    ON crawler.opentender_tenders (created_at DESC);
