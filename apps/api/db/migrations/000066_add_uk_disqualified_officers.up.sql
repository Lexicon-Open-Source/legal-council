-- UK Companies House Disqualified Officers Register
-- Stores both natural persons and corporate entities in a single table
-- with nullable type-specific columns discriminated by officer_type.

CREATE TABLE IF NOT EXISTS crawler.uk_disqualified_officers (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Natural key from Companies House (extracted from URL path)
    officer_id TEXT NOT NULL UNIQUE,

    -- Discriminator: 'natural' or 'corporate'
    officer_type TEXT NOT NULL CHECK (officer_type IN ('natural', 'corporate')),

    -- Natural person fields (NULL for corporate)
    forename TEXT,
    surname TEXT,
    other_forenames TEXT,
    title TEXT,
    honours TEXT,
    date_of_birth DATE,
    nationality TEXT,

    -- Corporate entity fields (NULL for natural)
    company_name TEXT,
    company_number TEXT,
    country_of_registration TEXT,

    -- Shared fields
    person_number TEXT,

    -- Disqualification data (JSONB arrays from API response)
    disqualifications JSONB NOT NULL DEFAULT '[]',
    permissions_to_act JSONB NOT NULL DEFAULT '[]',

    -- Full API response for reference
    raw_data JSONB NOT NULL DEFAULT '{}',

    -- Computed: latest disqualification end date (for active/expired filtering)
    latest_disqualified_until DATE,

    -- Soft-delete for officers whose disqualifications have all expired
    expired_at TIMESTAMPTZ,

    -- ETag from API response for change detection on re-crawl
    etag TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-update trigger (reuses existing function from 000001)
CREATE TRIGGER update_uk_disqualified_officers_updated_at
    BEFORE UPDATE ON crawler.uk_disqualified_officers
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

-- Filter indexes
CREATE INDEX idx_uk_disq_officer_type ON crawler.uk_disqualified_officers (officer_type);
CREATE INDEX idx_uk_disq_latest_until ON crawler.uk_disqualified_officers (latest_disqualified_until)
    WHERE latest_disqualified_until IS NOT NULL;
CREATE INDEX idx_uk_disq_expired_at ON crawler.uk_disqualified_officers (expired_at)
    WHERE expired_at IS NOT NULL;
CREATE INDEX idx_uk_disq_nationality ON crawler.uk_disqualified_officers (nationality)
    WHERE nationality IS NOT NULL;

-- Trigram indexes for ILIKE name searches (pg_trgm enabled in 000001)
CREATE INDEX idx_uk_disq_surname_trgm ON crawler.uk_disqualified_officers USING GIN (surname gin_trgm_ops)
    WHERE surname IS NOT NULL;
CREATE INDEX idx_uk_disq_forename_trgm ON crawler.uk_disqualified_officers USING GIN (forename gin_trgm_ops)
    WHERE forename IS NOT NULL;
CREATE INDEX idx_uk_disq_company_name_trgm ON crawler.uk_disqualified_officers USING GIN (company_name gin_trgm_ops)
    WHERE company_name IS NOT NULL;

COMMENT ON TABLE crawler.uk_disqualified_officers IS 'UK Companies House Register of Disqualifications — natural persons and corporate entities';
COMMENT ON COLUMN crawler.uk_disqualified_officers.officer_id IS 'Companies House internal officer ID (from URL path, e.g. Q8J9tnY4wzC8BP9ilhung2VFw8I)';
COMMENT ON COLUMN crawler.uk_disqualified_officers.officer_type IS 'natural (person) or corporate (company/entity)';
COMMENT ON COLUMN crawler.uk_disqualified_officers.latest_disqualified_until IS 'Latest disqualification end date across all disqualifications (computed on upsert)';
COMMENT ON COLUMN crawler.uk_disqualified_officers.expired_at IS 'Soft-delete timestamp — set when all disqualifications have ended';
COMMENT ON COLUMN crawler.uk_disqualified_officers.etag IS 'ETag from Companies House API response for change detection';
