-- Rollback OCDS Analytics Phase 2 Materialized Views

-- Drop Phase 2 views
DROP MATERIALIZED VIEW IF EXISTS ocds.provider_tenure_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.value_savings_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.text_quality_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.duration_metrics_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.klpd_ranking_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.tender_status_dist_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.procurement_type_dist_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.monthly_trends_mv;

-- Restore original refresh function (Phase 1 only)
CREATE OR REPLACE FUNCTION ocds.refresh_analytics_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.analytics_summary_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.bidder_distribution_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.contractor_ranking_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.blacklist_matches_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.verdict_matches_mv;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION ocds.refresh_analytics_views() IS
    'Refresh all analytics materialized views. Call via pg_cron every 6 hours.';
