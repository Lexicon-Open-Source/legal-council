-- migrations/000079_drop_ocds_materialized_views.up.sql
--
-- Phase 2: MV Cleanup
-- Drop all 14 OCDS materialized views and the refresh function.
-- These L3 views will be redesigned from scratch during Go API development
-- to match actual endpoint needs.

-- Phase 1 MVs (from migration 000051)
DROP MATERIALIZED VIEW IF EXISTS ocds.analytics_summary_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.bidder_distribution_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.contractor_ranking_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.blacklist_matches_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.verdict_matches_mv;

-- Phase 2 MVs (from migration 000052)
DROP MATERIALIZED VIEW IF EXISTS ocds.monthly_trends_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.procurement_type_dist_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.tender_status_dist_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.klpd_ranking_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.duration_metrics_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.text_quality_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.value_savings_mv;
DROP MATERIALIZED VIEW IF EXISTS ocds.provider_tenure_mv;

-- tender_search_view (MV but doesn't follow _mv naming convention)
DROP MATERIALIZED VIEW IF EXISTS ocds.tender_search_view;

-- Drop the refresh functions (no MVs left to refresh)
DROP FUNCTION IF EXISTS ocds.refresh_analytics_views();
DROP FUNCTION IF EXISTS ocds.refresh_tender_search_view();
