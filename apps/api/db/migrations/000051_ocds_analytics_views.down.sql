-- Rollback OCDS Analytics Materialized Views

DROP FUNCTION IF EXISTS ocds.refresh_analytics_views();
DROP MATERIALIZED VIEW IF EXISTS ocds.verdict_matches_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.blacklist_matches_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.contractor_ranking_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.bidder_distribution_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.analytics_summary_mv;

-- Drop the indexes we created (safe to run even if they don't exist)
DROP INDEX IF EXISTS bo_v1.idx_cases_subject_normalized_btree;
DROP INDEX IF EXISTS crawler.idx_blacklist_name_normalized;
DROP INDEX IF EXISTS ocds.idx_parties_name_normalized;
