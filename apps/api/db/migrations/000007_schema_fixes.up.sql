-- ============================================
-- Schema Fixes Migration
-- Addresses code review findings
-- ============================================

-- ============================================
-- 1. Fix Column Typo (TODO 008)
-- ============================================
ALTER TABLE bo_v1.draft_cases
RENAME COLUMN benificiary_ownership TO beneficial_ownership;

-- ============================================
-- 2. Fix ID Type Inconsistencies (TODO 007)
-- ============================================

-- Fix unbounded VARCHAR for IDs in council_v1
ALTER TABLE council_v1.deliberation_sessions
ALTER COLUMN id TYPE VARCHAR(64);

ALTER TABLE council_v1.deliberation_sessions
ALTER COLUMN user_id TYPE CHAR(26);

ALTER TABLE council_v1.deliberation_messages
ALTER COLUMN id TYPE VARCHAR(64);

-- Fix llm_extractions.extraction_id missing length constraint
ALTER TABLE bo_crawler_v1.llm_extractions
ALTER COLUMN extraction_id TYPE VARCHAR(64);

-- ============================================
-- 3. Fix Timestamp Type Inconsistencies (TODO 006)
-- ============================================

-- bo_crawler_v1.url_frontiers: TIMESTAMP -> TIMESTAMPTZ
ALTER TABLE bo_crawler_v1.url_frontiers
ALTER COLUMN created_at TYPE TIMESTAMPTZ,
ALTER COLUMN updated_at TYPE TIMESTAMPTZ;

-- bo_crawler_v1.extractions: TIMESTAMP -> TIMESTAMPTZ
ALTER TABLE bo_crawler_v1.extractions
ALTER COLUMN created_at TYPE TIMESTAMPTZ,
ALTER COLUMN updated_at TYPE TIMESTAMPTZ;

-- bo_v1.users: TIMESTAMP -> TIMESTAMPTZ
ALTER TABLE bo_v1.users
ALTER COLUMN created_at TYPE TIMESTAMPTZ,
ALTER COLUMN updated_at TYPE TIMESTAMPTZ,
ALTER COLUMN email_verified_at TYPE TIMESTAMPTZ,
ALTER COLUMN two_factor_confirmed_at TYPE TIMESTAMPTZ;

-- bo_v1.password_reset_tokens: TIMESTAMP -> TIMESTAMPTZ
ALTER TABLE bo_v1.password_reset_tokens
ALTER COLUMN created_at TYPE TIMESTAMPTZ;

-- bo_v1.personal_access_tokens: TIMESTAMP -> TIMESTAMPTZ
ALTER TABLE bo_v1.personal_access_tokens
ALTER COLUMN last_used_at TYPE TIMESTAMPTZ,
ALTER COLUMN expires_at TYPE TIMESTAMPTZ,
ALTER COLUMN created_at TYPE TIMESTAMPTZ,
ALTER COLUMN updated_at TYPE TIMESTAMPTZ;

-- ============================================
-- 4. Add Foreign Key Constraints (TODO 002)
-- ============================================

-- bo_crawler_v1: extractions -> url_frontiers
ALTER TABLE bo_crawler_v1.extractions
ADD CONSTRAINT fk_extractions_url_frontier
FOREIGN KEY (url_frontier_id)
REFERENCES bo_crawler_v1.url_frontiers(id) ON DELETE CASCADE;

-- bo_crawler_v1: llm_extractions -> extractions
ALTER TABLE bo_crawler_v1.llm_extractions
ADD CONSTRAINT fk_llm_extractions_extraction
FOREIGN KEY (extraction_id)
REFERENCES bo_crawler_v1.extractions(id) ON DELETE CASCADE;

-- bo_v1: personal_access_tokens -> users
ALTER TABLE bo_v1.personal_access_tokens
ADD CONSTRAINT fk_personal_access_tokens_user
FOREIGN KEY (tokenable_id)
REFERENCES bo_v1.users(id) ON DELETE CASCADE;

-- bo_v1: cases audit columns -> users (SET NULL on delete)
ALTER TABLE bo_v1.cases
ADD CONSTRAINT fk_cases_created_by
FOREIGN KEY (created_by)
REFERENCES bo_v1.users(id) ON DELETE SET NULL;

ALTER TABLE bo_v1.cases
ADD CONSTRAINT fk_cases_updated_by
FOREIGN KEY (updated_by)
REFERENCES bo_v1.users(id) ON DELETE SET NULL;

ALTER TABLE bo_v1.cases
ADD CONSTRAINT fk_cases_deleted_by
FOREIGN KEY (deleted_by)
REFERENCES bo_v1.users(id) ON DELETE SET NULL;

-- council_v1: deliberation_sessions -> users
ALTER TABLE council_v1.deliberation_sessions
ADD CONSTRAINT fk_deliberation_sessions_user
FOREIGN KEY (user_id)
REFERENCES bo_v1.users(id) ON DELETE SET NULL;

-- ocds: releases -> spse_tenders
ALTER TABLE ocds.releases
ADD CONSTRAINT fk_releases_source_tender
FOREIGN KEY (source_tender_id)
REFERENCES crawler.spse_tenders(id) ON DELETE RESTRICT;

-- ============================================
-- 5. Add Missing FK Indexes (TODO 003)
-- ============================================

-- Index on extractions.url_frontier_id
CREATE INDEX idx_extractions_url_frontier_id
ON bo_crawler_v1.extractions USING btree (url_frontier_id);

-- Index on releases.source_tender_id
CREATE INDEX idx_releases_source_tender_id
ON ocds.releases USING btree (source_tender_id);

-- Queue processing index for llm_extractions
CREATE INDEX idx_llm_extractions_processing_queue
ON bo_crawler_v1.llm_extractions USING btree (created_at)
WHERE (embedding_generated = false AND status = 'pending');

-- ============================================
-- 6. Remove Redundant Indexes (TODO 009)
-- ============================================

-- url_frontiers.url is already covered by UNIQUE constraint
DROP INDEX IF EXISTS bo_crawler_v1.idx_url;

-- draft_cases.link is already covered by UNIQUE constraint
DROP INDEX IF EXISTS bo_v1.draft_cases_link_idx;

-- spse_tenders.kode_tender is already covered by UNIQUE index
DROP INDEX IF EXISTS crawler.idx_spse_tenders_kode;
