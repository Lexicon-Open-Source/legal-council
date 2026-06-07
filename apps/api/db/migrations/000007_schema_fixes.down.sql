-- ============================================
-- Rollback: Schema Fixes Migration
-- ============================================

-- ============================================
-- 6. Restore Redundant Indexes
-- ============================================
CREATE INDEX IF NOT EXISTS idx_url ON bo_crawler_v1.url_frontiers USING btree (url);
CREATE INDEX IF NOT EXISTS draft_cases_link_idx ON bo_v1.draft_cases USING btree (link);
CREATE INDEX IF NOT EXISTS idx_spse_tenders_kode ON crawler.spse_tenders USING btree (kode_tender);

-- ============================================
-- 5. Drop FK Indexes
-- ============================================
DROP INDEX IF EXISTS bo_crawler_v1.idx_extractions_url_frontier_id;
DROP INDEX IF EXISTS ocds.idx_releases_source_tender_id;
DROP INDEX IF EXISTS bo_crawler_v1.idx_llm_extractions_processing_queue;

-- ============================================
-- 4. Drop Foreign Key Constraints
-- ============================================
ALTER TABLE ocds.releases
DROP CONSTRAINT IF EXISTS fk_releases_source_tender;

ALTER TABLE council_v1.deliberation_sessions
DROP CONSTRAINT IF EXISTS fk_deliberation_sessions_user;

ALTER TABLE bo_v1.cases
DROP CONSTRAINT IF EXISTS fk_cases_deleted_by;

ALTER TABLE bo_v1.cases
DROP CONSTRAINT IF EXISTS fk_cases_updated_by;

ALTER TABLE bo_v1.cases
DROP CONSTRAINT IF EXISTS fk_cases_created_by;

ALTER TABLE bo_v1.personal_access_tokens
DROP CONSTRAINT IF EXISTS fk_personal_access_tokens_user;

ALTER TABLE bo_crawler_v1.llm_extractions
DROP CONSTRAINT IF EXISTS fk_llm_extractions_extraction;

ALTER TABLE bo_crawler_v1.extractions
DROP CONSTRAINT IF EXISTS fk_extractions_url_frontier;

-- ============================================
-- 3. Revert Timestamp Types (TIMESTAMPTZ -> TIMESTAMP)
-- ============================================

-- bo_v1.personal_access_tokens
ALTER TABLE bo_v1.personal_access_tokens
ALTER COLUMN updated_at TYPE TIMESTAMP,
ALTER COLUMN created_at TYPE TIMESTAMP,
ALTER COLUMN expires_at TYPE TIMESTAMP,
ALTER COLUMN last_used_at TYPE TIMESTAMP;

-- bo_v1.password_reset_tokens
ALTER TABLE bo_v1.password_reset_tokens
ALTER COLUMN created_at TYPE TIMESTAMP;

-- bo_v1.users
ALTER TABLE bo_v1.users
ALTER COLUMN two_factor_confirmed_at TYPE TIMESTAMP,
ALTER COLUMN email_verified_at TYPE TIMESTAMP,
ALTER COLUMN updated_at TYPE TIMESTAMP,
ALTER COLUMN created_at TYPE TIMESTAMP;

-- bo_crawler_v1.extractions
ALTER TABLE bo_crawler_v1.extractions
ALTER COLUMN updated_at TYPE TIMESTAMP,
ALTER COLUMN created_at TYPE TIMESTAMP;

-- bo_crawler_v1.url_frontiers
ALTER TABLE bo_crawler_v1.url_frontiers
ALTER COLUMN updated_at TYPE TIMESTAMP,
ALTER COLUMN created_at TYPE TIMESTAMP;

-- ============================================
-- 2. Revert ID Type Changes
-- ============================================
ALTER TABLE bo_crawler_v1.llm_extractions
ALTER COLUMN extraction_id TYPE VARCHAR;

ALTER TABLE council_v1.deliberation_messages
ALTER COLUMN id TYPE VARCHAR;

ALTER TABLE council_v1.deliberation_sessions
ALTER COLUMN user_id TYPE VARCHAR;

ALTER TABLE council_v1.deliberation_sessions
ALTER COLUMN id TYPE VARCHAR;

-- ============================================
-- 1. Revert Column Name
-- ============================================
ALTER TABLE bo_v1.draft_cases
RENAME COLUMN beneficial_ownership TO benificiary_ownership;
