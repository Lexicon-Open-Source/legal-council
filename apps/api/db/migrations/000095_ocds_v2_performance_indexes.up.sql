-- ============================================================
-- OCDS v2: Performance indexes for ETL queries
-- ============================================================

-- GIN index for array containment queries on planning.rup_codes
-- Used by SiRUP pipeline's _link_related_tenders cross-linking
CREATE INDEX IF NOT EXISTS idx_planning_rup_codes
ON ocds.planning USING GIN (rup_codes);

-- Partial index for transformation_log dedup checks
-- Used by check_already_processed() and get_pending_* DAG queries
CREATE INDEX IF NOT EXISTS idx_transformation_log_dedup
ON ocds.transformation_log (source_system, source_id, source_updated_at)
WHERE status = 'success';
