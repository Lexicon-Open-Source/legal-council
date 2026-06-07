-- LKPP Blacklist (Daftar Hitam) table
-- Stores sanctioned vendor data from https://daftar-hitam.inaproc.id/

CREATE TABLE crawler.lkpp_blacklist_entries (
    -- Primary identification
    id TEXT PRIMARY KEY,
    sk_number TEXT NOT NULL,

    -- Provider (flattened for common queries)
    provider_name TEXT NOT NULL,
    provider_npwp TEXT,
    provider_address TEXT,

    -- Status and dates (flattened for filtering)
    status TEXT NOT NULL,
    start_date TIMESTAMPTZ,
    expired_date TIMESTAMPTZ,
    publish_date TIMESTAMPTZ,

    -- Nested structures as JSONB (matches GraphQL response)
    tender JSONB,
    violation JSONB,
    correspondence JSONB,
    document JSONB,

    -- Raw GraphQL response for debugging/future use
    raw_data JSONB,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Status validation
    CONSTRAINT valid_status CHECK (status IN ('PUBLISHED', 'CANCELLED', 'EXPIRED', 'PENDING'))
);

-- Indexes for common query patterns
CREATE INDEX idx_lkpp_blacklist_provider_name ON crawler.lkpp_blacklist_entries (provider_name);
CREATE INDEX idx_lkpp_blacklist_status ON crawler.lkpp_blacklist_entries (status);
CREATE INDEX idx_lkpp_blacklist_publish_date ON crawler.lkpp_blacklist_entries (publish_date DESC);

-- Partial index for "active blacklist" queries (most common use case)
CREATE INDEX idx_lkpp_blacklist_active ON crawler.lkpp_blacklist_entries (status, expired_date DESC)
    WHERE status = 'PUBLISHED';

COMMENT ON TABLE crawler.lkpp_blacklist_entries IS 'LKPP Daftar Hitam (blacklisted vendors) from https://daftar-hitam.inaproc.id/';
COMMENT ON COLUMN crawler.lkpp_blacklist_entries.sk_number IS 'Surat Keputusan (decree) number';
COMMENT ON COLUMN crawler.lkpp_blacklist_entries.provider_npwp IS 'NPWP (masked in source data)';
COMMENT ON COLUMN crawler.lkpp_blacklist_entries.tender IS 'Related tender info (id, name, pagu, hps, category, budgetYear)';
COMMENT ON COLUMN crawler.lkpp_blacklist_entries.violation IS 'Violation details (id, name, description, month, year)';
COMMENT ON COLUMN crawler.lkpp_blacklist_entries.correspondence IS 'Reporting agencies (lpse, kldi, satker)';
