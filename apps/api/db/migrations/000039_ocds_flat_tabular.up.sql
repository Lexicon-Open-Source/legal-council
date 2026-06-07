-- Migration: Convert OCDS schema from JSONB to flat tabular format
-- OCDS v1.1.5 compliant schema

-- NOTE: Table Naming Convention
-- Most tables use plural names (parties, releases, awards, contracts, items, documents, milestones)
-- Exceptions: 'tender' (singular to match OCDS terminology), 'planning' (gerund per OCDS),
-- 'transformation_log' (singular as a log entity). This is intentional for OCDS compatibility.

-- Required extension for trigram text search indexes
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- PRE-FLIGHT SAFETY CHECK
-- This migration is DESTRUCTIVE and will drop existing OCDS data.
-- The check below prevents accidental execution on databases with existing data.
-- To bypass this check for intentional data reset, set: SET app.force_migration = 'true';

DO $$
DECLARE
    row_count INTEGER;
BEGIN
    -- Check if ocds.releases table exists and has data
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'ocds' AND table_name = 'releases') THEN
        SELECT COUNT(*) INTO row_count FROM ocds.releases;
        IF row_count > 0 AND COALESCE(current_setting('app.force_migration', true), 'false') != 'true' THEN
            RAISE EXCEPTION 'MIGRATION BLOCKED: ocds.releases contains % records. This migration will destroy all data. To proceed, first backup your data, then run: SET app.force_migration = ''true'';', row_count;
        END IF;
    END IF;
END $$;

-- Drop old releases table
DROP TABLE IF EXISTS ocds.releases CASCADE;

-- PARTIES: Organizations involved in procurement (buyers, suppliers, tenderers)
CREATE TABLE ocds.parties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id VARCHAR(255) NOT NULL,  -- OCDS party identifier (e.g., "ID-NPWP-1234567890")
    name VARCHAR(500) NOT NULL,
    identifier_scheme VARCHAR(100),  -- e.g., "ID-NPWP", "ID-NIB"
    identifier_id VARCHAR(255),      -- The actual ID (NPWP, NIB, etc.)
    identifier_legal_name VARCHAR(500),
    address_street_address TEXT,
    address_locality VARCHAR(255),
    address_region VARCHAR(255),
    address_postal_code VARCHAR(20),
    address_country_name VARCHAR(100) DEFAULT 'Indonesia',
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_telephone VARCHAR(50),
    roles TEXT[] NOT NULL,  -- Array: 'buyer', 'procuringEntity', 'supplier', 'tenderer'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT parties_party_id_key UNIQUE (party_id)
);

CREATE INDEX idx_parties_identifier ON ocds.parties (identifier_scheme, identifier_id);
CREATE INDEX idx_parties_roles ON ocds.parties USING gin (roles);
CREATE INDEX idx_parties_name ON ocds.parties USING gin (name gin_trgm_ops);

-- RELEASES: Main OCDS release record (one per procurement process)
CREATE TABLE ocds.releases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ocid VARCHAR(150) NOT NULL,  -- Open Contracting ID (e.g., "ocds-xxx-ID-LPSE-12345")
    release_id VARCHAR(200) NOT NULL,  -- Unique release identifier
    language VARCHAR(10) DEFAULT 'id',
    tag TEXT[] NOT NULL,  -- Array: 'planning', 'tender', 'award', 'contract', etc.
    initiation_type VARCHAR(50) DEFAULT 'tender',

    -- Buyer reference
    buyer_id UUID REFERENCES ocds.parties(id) ON DELETE SET NULL,

    -- Source tracking
    source_system VARCHAR(50) NOT NULL,  -- 'spse', 'sirup', etc.
    source_id VARCHAR(100) NOT NULL,     -- Original system ID (kode_tender)
    source_url TEXT,
    source_updated_at TIMESTAMPTZ,

    -- Timestamps
    date TIMESTAMPTZ NOT NULL,  -- Release date
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT releases_ocid_release_id_key UNIQUE (ocid, release_id)
);

CREATE INDEX idx_releases_ocid ON ocds.releases (ocid);
CREATE INDEX idx_releases_source ON ocds.releases (source_system, source_id);
CREATE INDEX idx_releases_date ON ocds.releases (date DESC);
CREATE INDEX idx_releases_tag ON ocds.releases USING gin (tag);

-- TENDER: Tender/procurement process details
CREATE TABLE ocds.tender (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,

    -- Tender identification
    tender_id VARCHAR(100) NOT NULL,  -- Original tender ID
    title TEXT NOT NULL,
    description TEXT,

    -- Status and method
    status VARCHAR(50),  -- 'planning', 'planned', 'active', 'cancelled', 'unsuccessful', 'complete', 'withdrawn'
    procurement_method VARCHAR(50),  -- 'open', 'selective', 'limited', 'direct'
    procurement_method_details VARCHAR(255),  -- e.g., 'Tender Terbuka', 'Pengadaan Langsung'
    procurement_method_rationale TEXT,
    main_procurement_category VARCHAR(50),  -- 'goods', 'works', 'services'
    additional_procurement_categories TEXT[],

    -- Value
    value_amount NUMERIC(20, 2),
    value_currency VARCHAR(3) DEFAULT 'IDR',
    min_value_amount NUMERIC(20, 2),
    max_value_amount NUMERIC(20, 2),

    -- Procurement entity
    procuring_entity_id UUID REFERENCES ocds.parties(id) ON DELETE SET NULL,

    -- Tender period
    tender_period_start_date TIMESTAMPTZ,
    tender_period_end_date TIMESTAMPTZ,
    tender_period_max_extent_date TIMESTAMPTZ,

    -- Enquiry period
    enquiry_period_start_date TIMESTAMPTZ,
    enquiry_period_end_date TIMESTAMPTZ,

    -- Award period
    award_period_start_date TIMESTAMPTZ,
    award_period_end_date TIMESTAMPTZ,

    -- Eligibility and submission
    has_enquiries BOOLEAN,
    eligibility_criteria TEXT,
    award_criteria VARCHAR(100),  -- 'priceOnly', 'costOnly', 'qualityOnly', 'ratedCriteria', 'lowestCost', 'bestProposal'
    award_criteria_details TEXT,
    submission_method TEXT[],  -- 'electronicSubmission', 'electronicAuction', 'written', 'inPerson'
    submission_method_details TEXT,

    -- Additional info
    number_of_tenderers INTEGER,
    legal_basis TEXT,

    -- Location
    location_description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT tender_status_check CHECK (
        status IS NULL OR status IN ('planning', 'planned', 'active', 'cancelled', 'unsuccessful', 'complete', 'withdrawn')
    ),
    CONSTRAINT tender_release_id_key UNIQUE (release_id)
);

CREATE INDEX idx_tender_value ON ocds.tender (value_amount);
CREATE INDEX idx_tender_title ON ocds.tender USING gin (title gin_trgm_ops);
-- Composite index for common filtered queries (replaces individual low-cardinality indexes)
CREATE INDEX idx_tender_method_category ON ocds.tender (procurement_method, main_procurement_category) WHERE status = 'active';

-- TENDER_TENDERERS: Organizations that submitted tenders (bids)
CREATE TABLE ocds.tender_tenderers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tender_id UUID NOT NULL REFERENCES ocds.tender(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES ocds.parties(id),

    -- Bid information
    bid_amount NUMERIC(20, 2),
    bid_currency VARCHAR(3) DEFAULT 'IDR',
    corrected_amount NUMERIC(20, 2),  -- harga_terkoreksi

    -- Status
    bid_status VARCHAR(50),  -- 'pending', 'valid', 'disqualified', 'withdrawn'

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT tender_tenderers_unique UNIQUE (tender_id, party_id)
);

CREATE INDEX idx_tender_tenderers_tender ON ocds.tender_tenderers (tender_id);
CREATE INDEX idx_tender_tenderers_party ON ocds.tender_tenderers (party_id);

-- AWARDS: Award decisions
CREATE TABLE ocds.awards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,

    award_id VARCHAR(150) NOT NULL,  -- Unique award identifier
    title TEXT,
    description TEXT,
    status VARCHAR(50),  -- 'pending', 'active', 'cancelled', 'unsuccessful'

    -- Award date
    date TIMESTAMPTZ,

    -- Value
    value_amount NUMERIC(20, 2),
    value_currency VARCHAR(3) DEFAULT 'IDR',

    -- Negotiated value (hasil_negosiasi)
    negotiated_amount NUMERIC(20, 2),

    -- Contract period (if known at award stage)
    contract_period_start_date TIMESTAMPTZ,
    contract_period_end_date TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT awards_status_check CHECK (
        status IS NULL OR status IN ('pending', 'active', 'cancelled', 'unsuccessful')
    ),
    CONSTRAINT awards_release_award_key UNIQUE (release_id, award_id)
);

CREATE INDEX idx_awards_release ON ocds.awards (release_id);
CREATE INDEX idx_awards_date ON ocds.awards (date DESC);
CREATE INDEX idx_awards_value ON ocds.awards (value_amount);

-- AWARD_SUPPLIERS: Suppliers per award (winners)
CREATE TABLE ocds.award_suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    award_id UUID NOT NULL REFERENCES ocds.awards(id) ON DELETE CASCADE,
    party_id UUID NOT NULL REFERENCES ocds.parties(id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT award_suppliers_unique UNIQUE (award_id, party_id)
);

CREATE INDEX idx_award_suppliers_award ON ocds.award_suppliers (award_id);
CREATE INDEX idx_award_suppliers_party ON ocds.award_suppliers (party_id);

-- CONTRACTS: Contract details
CREATE TABLE ocds.contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,
    award_id UUID REFERENCES ocds.awards(id),

    contract_id VARCHAR(150) NOT NULL,  -- Unique contract identifier
    title TEXT,
    description TEXT,
    status VARCHAR(50),  -- 'pending', 'active', 'cancelled', 'terminated'

    -- Contract period
    period_start_date TIMESTAMPTZ,
    period_end_date TIMESTAMPTZ,

    -- Value
    value_amount NUMERIC(20, 2),
    value_currency VARCHAR(3) DEFAULT 'IDR',

    -- PDN/UMK values (Indonesian specific)
    pdn_value_amount NUMERIC(20, 2),  -- Produk Dalam Negeri value
    umk_value_amount NUMERIC(20, 2),  -- Usaha Mikro Kecil value

    -- Date signed
    date_signed TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT contracts_status_check CHECK (
        status IS NULL OR status IN ('pending', 'active', 'cancelled', 'terminated')
    ),
    CONSTRAINT contracts_release_contract_key UNIQUE (release_id, contract_id)
);

CREATE INDEX idx_contracts_release ON ocds.contracts (release_id);
CREATE INDEX idx_contracts_award ON ocds.contracts (award_id);
CREATE INDEX idx_contracts_value ON ocds.contracts (value_amount);

-- PLANNING: Planning stage information (from RUP/SIRUP)
CREATE TABLE ocds.planning (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,

    -- Budget information
    budget_description TEXT,
    budget_amount NUMERIC(20, 2),
    budget_currency VARCHAR(3) DEFAULT 'IDR',
    budget_project TEXT,
    budget_project_id VARCHAR(100),
    budget_source VARCHAR(100),  -- e.g., 'APBD', 'APBN'
    fiscal_year VARCHAR(50),

    -- RUP specific
    rup_id VARCHAR(100),
    rup_codes TEXT[],

    rationale TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT planning_release_id_key UNIQUE (release_id)
);

CREATE INDEX idx_planning_release ON ocds.planning (release_id);
CREATE INDEX idx_planning_fiscal_year ON ocds.planning (fiscal_year);
CREATE INDEX idx_planning_rup ON ocds.planning (rup_id);

-- ITEMS: Items being procured (can be in tender, award, or contract)
CREATE TABLE ocds.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Reference to parent (one of these will be set)
    tender_id UUID REFERENCES ocds.tender(id) ON DELETE CASCADE,
    award_id UUID REFERENCES ocds.awards(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES ocds.contracts(id) ON DELETE CASCADE,

    item_id VARCHAR(100) NOT NULL,
    description TEXT,

    -- Classification (CPV, UNSPSC, or Indonesian classification)
    classification_scheme VARCHAR(50),
    classification_id VARCHAR(50),
    classification_description TEXT,
    classification_uri TEXT,

    -- Quantity
    quantity NUMERIC(20, 4),
    unit_scheme VARCHAR(50),
    unit_id VARCHAR(50),
    unit_name VARCHAR(100),
    unit_value_amount NUMERIC(20, 2),
    unit_value_currency VARCHAR(3) DEFAULT 'IDR',

    -- Delivery location
    delivery_location_description TEXT,
    delivery_address TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT items_parent_check CHECK (
        (tender_id IS NOT NULL)::int +
        (award_id IS NOT NULL)::int +
        (contract_id IS NOT NULL)::int = 1
    )
);

CREATE INDEX idx_items_tender ON ocds.items (tender_id) WHERE tender_id IS NOT NULL;
CREATE INDEX idx_items_award ON ocds.items (award_id) WHERE award_id IS NOT NULL;
CREATE INDEX idx_items_contract ON ocds.items (contract_id) WHERE contract_id IS NOT NULL;
CREATE INDEX idx_items_classification ON ocds.items (classification_scheme, classification_id);

-- DOCUMENTS: Attached documents
CREATE TABLE ocds.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Reference to parent (one of these will be set)
    release_id UUID REFERENCES ocds.releases(id) ON DELETE CASCADE,
    tender_id UUID REFERENCES ocds.tender(id) ON DELETE CASCADE,
    award_id UUID REFERENCES ocds.awards(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES ocds.contracts(id) ON DELETE CASCADE,

    document_id VARCHAR(100) NOT NULL,
    document_type VARCHAR(100),  -- 'tenderNotice', 'awardNotice', 'contractNotice', etc.
    title TEXT,
    description TEXT,
    url TEXT,
    storage_path TEXT,  -- Internal storage path
    date_published TIMESTAMPTZ,
    date_modified TIMESTAMPTZ,
    format VARCHAR(100),  -- MIME type
    language VARCHAR(10) DEFAULT 'id',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT documents_parent_check CHECK (
        (release_id IS NOT NULL)::int +
        (tender_id IS NOT NULL)::int +
        (award_id IS NOT NULL)::int +
        (contract_id IS NOT NULL)::int = 1
    )
);

CREATE INDEX idx_documents_release ON ocds.documents (release_id) WHERE release_id IS NOT NULL;
CREATE INDEX idx_documents_tender ON ocds.documents (tender_id) WHERE tender_id IS NOT NULL;
CREATE INDEX idx_documents_award ON ocds.documents (award_id) WHERE award_id IS NOT NULL;
CREATE INDEX idx_documents_contract ON ocds.documents (contract_id) WHERE contract_id IS NOT NULL;
CREATE INDEX idx_documents_type ON ocds.documents (document_type);

-- MILESTONES: Key dates and milestones
CREATE TABLE ocds.milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Reference to parent
    tender_id UUID REFERENCES ocds.tender(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES ocds.contracts(id) ON DELETE CASCADE,

    milestone_id VARCHAR(100) NOT NULL,
    title TEXT,
    milestone_type VARCHAR(100),  -- 'preProcurement', 'engagement', 'approval', 'delivery', 'reporting', 'financing'
    description TEXT,
    code VARCHAR(50),

    -- Dates
    due_date TIMESTAMPTZ,
    date_met TIMESTAMPTZ,
    date_modified TIMESTAMPTZ,

    status VARCHAR(50),  -- 'scheduled', 'met', 'notMet', 'partiallyMet'

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT milestones_parent_check CHECK (
        (tender_id IS NOT NULL)::int +
        (contract_id IS NOT NULL)::int = 1
    )
);

CREATE INDEX idx_milestones_tender ON ocds.milestones (tender_id) WHERE tender_id IS NOT NULL;
CREATE INDEX idx_milestones_contract ON ocds.milestones (contract_id) WHERE contract_id IS NOT NULL;

-- TRANSFORMATION TRACKING: Track which source records have been transformed
CREATE TABLE ocds.transformation_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_system VARCHAR(50) NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    release_id UUID REFERENCES ocds.releases(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL,  -- 'success', 'error', 'skipped'
    error_message TEXT,
    source_updated_at TIMESTAMPTZ,
    transformed_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT transformation_log_status_check CHECK (
        status IN ('success', 'error', 'skipped')
    ),
    CONSTRAINT transformation_log_source_key UNIQUE (source_system, source_id)
);

CREATE INDEX idx_transformation_log_status ON ocds.transformation_log (status);
CREATE INDEX idx_transformation_log_source ON ocds.transformation_log (source_system, source_id);


-- ============================================================================
-- IMMUTABILITY: Prevent deletion of releases (Easy Releases pattern)
-- ============================================================================
-- OCDS releases are immutable. Updates create new releases, not modify existing.
-- To purge data, use a separate maintenance procedure that bypasses this trigger.

CREATE OR REPLACE FUNCTION ocds.prevent_release_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow bypass for maintenance procedures
    IF COALESCE(current_setting('app.allow_release_delete', true), 'false') = 'true' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'OCDS releases are immutable and cannot be deleted. To purge data, set: SET app.allow_release_delete = ''true'';';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_release_immutability
BEFORE DELETE ON ocds.releases
FOR EACH ROW EXECUTE FUNCTION ocds.prevent_release_delete();

-- ============================================================================
-- AUDIT: Automatic updated_at timestamp triggers
-- ============================================================================

CREATE OR REPLACE FUNCTION ocds.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_parties_updated_at
BEFORE UPDATE ON ocds.parties
FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();

CREATE TRIGGER update_releases_updated_at
BEFORE UPDATE ON ocds.releases
FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();

CREATE TRIGGER update_tender_updated_at
BEFORE UPDATE ON ocds.tender
FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();

CREATE TRIGGER update_awards_updated_at
BEFORE UPDATE ON ocds.awards
FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();

CREATE TRIGGER update_contracts_updated_at
BEFORE UPDATE ON ocds.contracts
FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();

CREATE TRIGGER update_planning_updated_at
BEFORE UPDATE ON ocds.planning
FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();
