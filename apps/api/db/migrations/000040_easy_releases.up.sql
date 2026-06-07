-- ============================================================================
-- Migration: Implement OCDS Easy Releases Pattern
-- ============================================================================
-- This migration modifies the schema to support OCDS Easy Releases pattern
-- where each update to source data creates a NEW release instead of updating
-- existing ones. This makes releases immutable as per OCDS standard.
--
-- Changes:
-- 1. Modify transformation_log constraint to allow multiple releases per source
-- 2. Add indexes for efficient "latest release" queries
-- 3. Create views for compiled releases (latest values)
-- ============================================================================
-- STEP 1: Modify transformation_log constraint
-- ============================================================================

-- Drop old constraint that only allows 1 log entry per source record
ALTER TABLE ocds.transformation_log
DROP CONSTRAINT IF EXISTS transformation_log_source_key;

-- Add new constraint that allows multiple releases per source
-- Each (source_system, source_id, release_id) combination must be unique
ALTER TABLE ocds.transformation_log
ADD CONSTRAINT transformation_log_source_release_key
UNIQUE (source_system, source_id, release_id);

-- Add index for finding latest transformation log per source
CREATE INDEX IF NOT EXISTS idx_transformation_log_latest
ON ocds.transformation_log (source_system, source_id, transformed_at DESC);

-- Add index for finding all releases of a source record
CREATE INDEX IF NOT EXISTS idx_transformation_log_source_releases
ON ocds.transformation_log (source_system, source_id, release_id);

-- ============================================================================
-- STEP 2: Create views for compiled releases (latest values)
-- ============================================================================

-- View: Latest release per OCID (equivalent to compiled release)
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

-- View: Compiled tender (latest tender per OCID)
CREATE OR REPLACE VIEW ocds.compiled_tender AS
SELECT DISTINCT ON (r.ocid)
    r.ocid,
    r.release_id as latest_release_id,
    r.date as release_date,
    r.tag,
    r.source_system,
    t.id,
    t.tender_id,
    t.title,
    t.description,
    t.status,
    t.procurement_method,
    t.procurement_method_details,
    t.main_procurement_category,
    t.value_amount,
    t.value_currency,
    t.max_value_amount,
    t.number_of_tenderers,
    t.location_description,
    t.tender_period_start_date,
    t.created_at,
    t.updated_at
FROM ocds.releases r
JOIN ocds.tender t ON t.release_id = r.id
ORDER BY r.ocid, r.date DESC;

-- View: Compiled awards (latest award per OCID and award_id)
CREATE OR REPLACE VIEW ocds.compiled_awards AS
SELECT DISTINCT ON (r.ocid, a.award_id)
    r.ocid,
    r.release_id as latest_release_id,
    r.date as release_date,
    a.id,
    a.award_id,
    a.title,
    a.status,
    a.date as award_date,
    a.value_amount,
    a.value_currency,
    a.negotiated_amount,
    a.created_at,
    a.updated_at
FROM ocds.releases r
JOIN ocds.awards a ON a.release_id = r.id
ORDER BY r.ocid, a.award_id, r.date DESC;

-- View: Compiled contracts (latest contract per OCID and contract_id)
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

-- View: Release history for analysis (aggregated to avoid Cartesian product)
CREATE OR REPLACE VIEW ocds.release_history AS
WITH award_summary AS (
    SELECT
        release_id,
        COUNT(*) as award_count,
        SUM(value_amount) as total_award_value,
        SUM(negotiated_amount) as total_negotiated_amount
    FROM ocds.awards
    GROUP BY release_id
),
contract_summary AS (
    SELECT
        release_id,
        COUNT(*) as contract_count,
        SUM(value_amount) as total_contract_value,
        SUM(pdn_value_amount) as total_pdn_value,
        SUM(umk_value_amount) as total_umk_value
    FROM ocds.contracts
    GROUP BY release_id
)
SELECT
    r.ocid,
    r.release_id,
    r.date,
    r.tag,
    r.source_system,
    r.source_id,
    t.status as tender_status,
    t.value_amount as tender_value,
    a.award_count,
    a.total_award_value,
    a.total_negotiated_amount,
    c.contract_count,
    c.total_contract_value,
    c.total_pdn_value,
    c.total_umk_value
FROM ocds.releases r
LEFT JOIN ocds.tender t ON t.release_id = r.id
LEFT JOIN award_summary a ON a.release_id = r.id
LEFT JOIN contract_summary c ON c.release_id = r.id
ORDER BY r.ocid, r.date ASC;

-- View: Summary statistics per OCID (optimized - O(n) instead of O(n^2))
CREATE OR REPLACE VIEW ocds.ocid_summary AS
WITH release_tags AS (
    SELECT ocid, array_agg(DISTINCT tag_item ORDER BY tag_item) as all_tags
    FROM (
        SELECT ocid, unnest(tag) as tag_item
        FROM ocds.releases
    ) expanded
    GROUP BY ocid
)
SELECT
    r.ocid,
    COUNT(DISTINCT r.id) as release_count,
    MIN(r.date) as first_release_date,
    MAX(r.date) as last_release_date,
    rt.all_tags
FROM ocds.releases r
LEFT JOIN release_tags rt ON rt.ocid = r.ocid
GROUP BY r.ocid, rt.all_tags;

-- ============================================================================
-- STEP 3: Add additional indexes for performance
-- ============================================================================

-- Index for efficient OCID + date queries (used by views)
CREATE INDEX IF NOT EXISTS idx_releases_ocid_date
ON ocds.releases (ocid, date DESC);

-- Index for source tracking with date
CREATE INDEX IF NOT EXISTS idx_releases_source_date
ON ocds.releases (source_system, source_id, date DESC);
