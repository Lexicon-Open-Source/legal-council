-- ============================================================
-- OCDS v2: Fresh Start Migration
-- Alter tables + fix constraints + purge data + new tables + views
-- ============================================================

-- ---- 1. ALTER EXISTING TABLES (new columns per CSV mapping) ----

-- releases: add nation column
ALTER TABLE ocds.releases
    ADD COLUMN IF NOT EXISTS nation VARCHAR(3) DEFAULT 'IDN';
COMMENT ON COLUMN ocds.releases.nation IS 'ISO 3166-1 Alpha-3 nation code (extension field)';

-- tender: add duration columns + contract period + enquiry/award max extent
ALTER TABLE ocds.tender
    ADD COLUMN IF NOT EXISTS tender_period_duration_in_days INTEGER,
    ADD COLUMN IF NOT EXISTS enquiry_period_duration_in_days INTEGER,
    ADD COLUMN IF NOT EXISTS enquiry_period_max_extent_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS award_period_duration_in_days INTEGER,
    ADD COLUMN IF NOT EXISTS award_period_max_extent_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS contract_period_start_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS contract_period_end_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS contract_period_max_extent_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS contract_period_duration_in_days INTEGER;

-- awards: add max extent + duration
ALTER TABLE ocds.awards
    ADD COLUMN IF NOT EXISTS contract_period_max_extent_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS contract_period_duration_in_days INTEGER;

-- contracts: add max extent + duration
ALTER TABLE ocds.contracts
    ADD COLUMN IF NOT EXISTS period_max_extent_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS period_duration_in_days INTEGER;

-- parties: add additional identifiers + contact fields
ALTER TABLE ocds.parties
    ADD COLUMN IF NOT EXISTS additional_identifiers_scheme VARCHAR(100),
    ADD COLUMN IF NOT EXISTS additional_identifiers_id VARCHAR(255),
    ADD COLUMN IF NOT EXISTS additional_identifier_legal_name VARCHAR(500),
    ADD COLUMN IF NOT EXISTS additional_identifier_uri TEXT,
    ADD COLUMN IF NOT EXISTS fax_number VARCHAR(50),
    ADD COLUMN IF NOT EXISTS url TEXT,
    ADD COLUMN IF NOT EXISTS details JSONB;

-- planning: add budget_id, budget_currency, budget_uri, rename budget_source
ALTER TABLE ocds.planning
    ADD COLUMN IF NOT EXISTS budget_id VARCHAR(100),
    ADD COLUMN IF NOT EXISTS budget_currency VARCHAR(3) DEFAULT 'IDR',
    ADD COLUMN IF NOT EXISTS budget_uri TEXT;
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'ocds' AND table_name = 'planning'
               AND column_name = 'budget_source') THEN
        ALTER TABLE ocds.planning RENAME COLUMN budget_source TO budget_source_description;
    ELSE
        ALTER TABLE ocds.planning ADD COLUMN IF NOT EXISTS budget_source_description VARCHAR(100);
    END IF;
END $$;

-- items: add release_id FK + additional classification fields + unit_uri
ALTER TABLE ocds.items
    ADD COLUMN IF NOT EXISTS release_id UUID REFERENCES ocds.releases(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS additional_classification_scheme VARCHAR(100),
    ADD COLUMN IF NOT EXISTS additional_classification_id VARCHAR(100),
    ADD COLUMN IF NOT EXISTS additional_classification_description TEXT,
    ADD COLUMN IF NOT EXISTS additional_classification_uri TEXT,
    ADD COLUMN IF NOT EXISTS unit_uri TEXT;

-- milestones: add release_id FK
ALTER TABLE ocds.milestones
    ADD COLUMN IF NOT EXISTS release_id UUID REFERENCES ocds.releases(id) ON DELETE CASCADE;

-- documents: add updated_at
ALTER TABLE ocds.documents
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- ---- 2. UPDATE CHECK CONSTRAINTS ----

-- items: drop old constraint and replace with exactly-one-parent check
-- ensures an item is linked to precisely one of release_id, tender_id, award_id, or contract_id
ALTER TABLE ocds.items DROP CONSTRAINT IF EXISTS items_parent_check;
ALTER TABLE ocds.items ADD CONSTRAINT items_parent_check CHECK (
    (release_id IS NOT NULL)::int +
    (tender_id IS NOT NULL)::int +
    (award_id IS NOT NULL)::int +
    (contract_id IS NOT NULL)::int = 1
);

-- milestones: drop old constraint and replace with exactly-one-parent check
-- ensures a milestone is linked to precisely one of release_id, tender_id, or contract_id
ALTER TABLE ocds.milestones DROP CONSTRAINT IF EXISTS milestones_parent_check;
ALTER TABLE ocds.milestones ADD CONSTRAINT milestones_parent_check CHECK (
    (release_id IS NOT NULL)::int +
    (tender_id IS NOT NULL)::int +
    (contract_id IS NOT NULL)::int = 1
);

-- ---- 3. TRUNCATE ALL OCDS DATA (fresh start) ----

SET app.allow_release_delete = 'true';
TRUNCATE TABLE ocds.releases CASCADE;
TRUNCATE TABLE ocds.parties CASCADE;
TRUNCATE TABLE ocds.transformation_log CASCADE;
RESET app.allow_release_delete;

-- ---- 4. NEW TABLES ----

-- amendments (OCDS standard completeness -- populated by third-party API consumers, not by ETL)
CREATE TABLE ocds.amendments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id      UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,
    tender_id       UUID REFERENCES ocds.tender(id) ON DELETE CASCADE,
    award_id        UUID REFERENCES ocds.awards(id) ON DELETE CASCADE,
    contract_id     UUID REFERENCES ocds.contracts(id) ON DELETE CASCADE,
    amendment_id    VARCHAR(150),
    date            TIMESTAMPTZ,
    rationale       TEXT,
    description     TEXT,
    amended_fields  TEXT[],
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_amendments_release ON ocds.amendments(release_id);

-- related_processes (partially populated by our ETL via kode_rup matching)
CREATE TABLE ocds.related_processes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id          UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,
    related_process_id  VARCHAR(255),
    relationship        TEXT[],
    title               TEXT,
    scheme              VARCHAR(100),
    identifier          VARCHAR(255),
    uri                 TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_related_processes_release ON ocds.related_processes(release_id);
CREATE INDEX idx_related_processes_identifier ON ocds.related_processes(identifier);

-- contract_implementation (OCDS standard completeness -- populated by third-party API consumers, not by ETL)
CREATE TABLE ocds.contract_implementation (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id     UUID NOT NULL REFERENCES ocds.contracts(id) ON DELETE CASCADE,
    status          VARCHAR(50),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_contract_impl_contract UNIQUE (contract_id)
);

-- contract_implementation_transactions (OCDS standard completeness -- populated by third-party API consumers, not by ETL)
CREATE TABLE ocds.contract_implementation_transactions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    implementation_id UUID NOT NULL REFERENCES ocds.contract_implementation(id) ON DELETE CASCADE,
    transaction_id    VARCHAR(150),
    source            TEXT,
    date              TIMESTAMPTZ,
    value_amount      NUMERIC(20,2),
    value_currency    VARCHAR(3) DEFAULT 'IDR',
    payer_id          UUID REFERENCES ocds.parties(id),
    payee_id          UUID REFERENCES ocds.parties(id),
    uri               TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_contract_impl_txn_impl ON ocds.contract_implementation_transactions(implementation_id);

-- contract_implementation_milestones (OCDS standard completeness -- populated by third-party API consumers, not by ETL)
CREATE TABLE ocds.contract_implementation_milestones (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    implementation_id UUID NOT NULL REFERENCES ocds.contract_implementation(id) ON DELETE CASCADE,
    milestone_id      VARCHAR(100),
    title             TEXT,
    milestone_type    VARCHAR(100),
    description       TEXT,
    code              VARCHAR(50),
    due_date          TIMESTAMPTZ,
    date_met          TIMESTAMPTZ,
    date_modified     TIMESTAMPTZ,
    status            VARCHAR(50),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_contract_impl_ms_impl ON ocds.contract_implementation_milestones(implementation_id);

-- contract_implementation_documents (OCDS standard completeness -- populated by third-party API consumers, not by ETL)
CREATE TABLE ocds.contract_implementation_documents (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    implementation_id UUID NOT NULL REFERENCES ocds.contract_implementation(id) ON DELETE CASCADE,
    document_id       VARCHAR(100),
    document_type     VARCHAR(100),
    title             TEXT,
    description       TEXT,
    url               TEXT,
    storage_path      TEXT,
    date_published    TIMESTAMPTZ,
    date_modified     TIMESTAMPTZ,
    format            VARCHAR(100),
    language          VARCHAR(10) DEFAULT 'id',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_contract_impl_doc_impl ON ocds.contract_implementation_documents(implementation_id);

-- ---- 5. UPDATE VIEWS ----

-- Drop views that need column changes (CREATE OR REPLACE cannot reorder columns)
DROP VIEW IF EXISTS ocds.compiled_related_processes;
DROP VIEW IF EXISTS ocds.compiled_contracts;
DROP VIEW IF EXISTS ocds.latest_releases;

-- Recreate latest_releases (explicit columns, includes nation + event_id)
CREATE OR REPLACE VIEW ocds.latest_releases AS
SELECT DISTINCT ON (ocid)
    id, ocid, release_id, language, tag, initiation_type,
    buyer_id, source_system, source_id, source_url, source_updated_at,
    date, nation, event_id, created_at, updated_at
FROM ocds.releases
ORDER BY ocid, date DESC;

-- Update compiled_contracts to include implementation status
CREATE OR REPLACE VIEW ocds.compiled_contracts AS
SELECT DISTINCT ON (r.ocid, c.contract_id)
    r.ocid,
    r.release_id AS latest_release_id,
    r.date AS release_date,
    c.id,
    c.contract_id,
    c.award_id,
    c.title,
    c.status,
    c.value_amount,
    c.value_currency,
    c.pdn_value_amount,
    c.umk_value_amount,
    c.date_signed,
    c.period_max_extent_date,
    c.period_duration_in_days,
    ci.status AS implementation_status,
    c.created_at,
    c.updated_at
FROM ocds.releases r
JOIN ocds.contracts c ON c.release_id = r.id
LEFT JOIN ocds.contract_implementation ci ON ci.contract_id = c.id
ORDER BY r.ocid, c.contract_id, r.date DESC;

-- Add compiled_related_processes view
CREATE OR REPLACE VIEW ocds.compiled_related_processes AS
SELECT DISTINCT ON (lr.ocid, rp.identifier)
    lr.ocid,
    lr.id AS release_id,
    rp.id AS related_process_pk,
    rp.related_process_id,
    rp.relationship,
    rp.title,
    rp.scheme,
    rp.identifier,
    rp.uri,
    rp.created_at,
    rp.updated_at
FROM ocds.latest_releases lr
JOIN ocds.related_processes rp ON rp.release_id = lr.id
ORDER BY lr.ocid, rp.identifier, rp.created_at DESC;
