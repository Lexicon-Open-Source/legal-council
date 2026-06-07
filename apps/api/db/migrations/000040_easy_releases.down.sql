-- ============================================================================
-- Migration Rollback: Revert OCDS Easy Releases Pattern
-- ============================================================================

-- Drop views
DROP VIEW IF EXISTS ocds.ocid_summary;
DROP VIEW IF EXISTS ocds.release_history;
DROP VIEW IF EXISTS ocds.compiled_contracts;
DROP VIEW IF EXISTS ocds.compiled_awards;
DROP VIEW IF EXISTS ocds.compiled_tender;
DROP VIEW IF EXISTS ocds.latest_releases;

-- Drop new indexes
DROP INDEX IF EXISTS ocds.idx_releases_source_date;
DROP INDEX IF EXISTS ocds.idx_releases_ocid_date;
DROP INDEX IF EXISTS ocds.idx_transformation_log_source_releases;
DROP INDEX IF EXISTS ocds.idx_transformation_log_latest;

-- Revert transformation_log constraint
ALTER TABLE ocds.transformation_log
DROP CONSTRAINT IF EXISTS transformation_log_source_release_key;

-- Restore original constraint (1 entry per source)
ALTER TABLE ocds.transformation_log
ADD CONSTRAINT transformation_log_source_key
UNIQUE (source_system, source_id);
