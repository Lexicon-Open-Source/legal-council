-- NOTE: This migration is IRREVERSIBLE for data (TRUNCATE cannot be undone).
-- The down migration only reverses schema changes (new tables + new columns).
-- A full data restore from backup is required to recover truncated data.

-- Drop views added/modified
DROP VIEW IF EXISTS ocds.compiled_related_processes;

-- Restore compiled_contracts to original definition (without implementation_status)
CREATE OR REPLACE VIEW ocds.compiled_contracts AS
SELECT DISTINCT ON (r.ocid, c.contract_id)
    r.ocid,
    r.release_id as latest_release_id,
    r.date as release_date,
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
    c.created_at,
    c.updated_at
FROM ocds.releases r
JOIN ocds.contracts c ON c.release_id = r.id
ORDER BY r.ocid, c.contract_id, r.date DESC;

-- Restore latest_releases to original definition (without nation, event_id)
CREATE OR REPLACE VIEW ocds.latest_releases AS
SELECT DISTINCT ON (ocid)
    id,
    ocid,
    release_id,
    language,
    tag,
    initiation_type,
    buyer_id,
    source_system,
    source_id,
    source_url,
    source_updated_at,
    date,
    created_at,
    updated_at
FROM ocds.releases
ORDER BY ocid, date DESC;

-- Drop new tables
DROP TABLE IF EXISTS ocds.contract_implementation_documents CASCADE;
DROP TABLE IF EXISTS ocds.contract_implementation_milestones CASCADE;
DROP TABLE IF EXISTS ocds.contract_implementation_transactions CASCADE;
DROP TABLE IF EXISTS ocds.contract_implementation CASCADE;
DROP TABLE IF EXISTS ocds.related_processes CASCADE;
DROP TABLE IF EXISTS ocds.amendments CASCADE;

-- Drop new columns from existing tables
ALTER TABLE ocds.releases DROP COLUMN IF EXISTS nation;

ALTER TABLE ocds.tender
    DROP COLUMN IF EXISTS tender_period_duration_in_days,
    DROP COLUMN IF EXISTS enquiry_period_duration_in_days,
    DROP COLUMN IF EXISTS enquiry_period_max_extent_date,
    DROP COLUMN IF EXISTS award_period_duration_in_days,
    DROP COLUMN IF EXISTS award_period_max_extent_date,
    DROP COLUMN IF EXISTS contract_period_start_date,
    DROP COLUMN IF EXISTS contract_period_end_date,
    DROP COLUMN IF EXISTS contract_period_max_extent_date,
    DROP COLUMN IF EXISTS contract_period_duration_in_days;

ALTER TABLE ocds.awards
    DROP COLUMN IF EXISTS contract_period_max_extent_date,
    DROP COLUMN IF EXISTS contract_period_duration_in_days;

ALTER TABLE ocds.contracts
    DROP COLUMN IF EXISTS period_max_extent_date,
    DROP COLUMN IF EXISTS period_duration_in_days;

ALTER TABLE ocds.parties
    DROP COLUMN IF EXISTS additional_identifiers_scheme,
    DROP COLUMN IF EXISTS additional_identifiers_id,
    DROP COLUMN IF EXISTS additional_identifier_legal_name,
    DROP COLUMN IF EXISTS additional_identifier_uri,
    DROP COLUMN IF EXISTS fax_number,
    DROP COLUMN IF EXISTS url,
    DROP COLUMN IF EXISTS details;

-- Rename budget_source_description back to budget_source
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'ocds' AND table_name = 'planning'
               AND column_name = 'budget_source_description') THEN
        ALTER TABLE ocds.planning RENAME COLUMN budget_source_description TO budget_source;
    END IF;
END $$;
ALTER TABLE ocds.planning
    DROP COLUMN IF EXISTS budget_id,
    DROP COLUMN IF EXISTS budget_currency,
    DROP COLUMN IF EXISTS budget_uri;

-- Clean up rows that only have release_id as parent (before dropping column)
DELETE FROM ocds.items WHERE release_id IS NOT NULL AND tender_id IS NULL AND award_id IS NULL AND contract_id IS NULL;
DELETE FROM ocds.milestones WHERE release_id IS NOT NULL AND tender_id IS NULL AND contract_id IS NULL;

-- Drop release_id columns first (before restoring strict constraints)
ALTER TABLE ocds.items DROP COLUMN IF EXISTS release_id;
ALTER TABLE ocds.milestones DROP COLUMN IF EXISTS release_id;

-- Restore original CHECK constraints (after release_id columns are gone)
ALTER TABLE ocds.items DROP CONSTRAINT IF EXISTS items_parent_check;
ALTER TABLE ocds.items ADD CONSTRAINT items_parent_check CHECK (
    (tender_id IS NOT NULL)::int +
    (award_id IS NOT NULL)::int +
    (contract_id IS NOT NULL)::int = 1
);
ALTER TABLE ocds.milestones DROP CONSTRAINT IF EXISTS milestones_parent_check;
ALTER TABLE ocds.milestones ADD CONSTRAINT milestones_parent_check CHECK (
    (tender_id IS NOT NULL)::int +
    (contract_id IS NOT NULL)::int = 1
);

ALTER TABLE ocds.items
    DROP COLUMN IF EXISTS additional_classification_scheme,
    DROP COLUMN IF EXISTS additional_classification_id,
    DROP COLUMN IF EXISTS additional_classification_description,
    DROP COLUMN IF EXISTS additional_classification_uri,
    DROP COLUMN IF EXISTS unit_uri;
ALTER TABLE ocds.documents DROP COLUMN IF EXISTS updated_at;
