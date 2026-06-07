-- migrations/000079_drop_ocds_materialized_views.down.sql
--
-- WARNING: Full MV recreation requires the original CREATE MATERIALIZED VIEW statements
-- from migrations 000051, 000052, etc. This down migration is intentionally minimal.
-- To fully restore, roll back to a database backup or re-run the original MV migrations.

-- Recreate empty refresh function stubs so any external callers don't error
CREATE OR REPLACE FUNCTION ocds.refresh_analytics_views() RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    RAISE NOTICE 'MVs have been dropped. Re-run original MV migrations to restore.';
END;
$$;

CREATE OR REPLACE FUNCTION ocds.refresh_tender_search_view() RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    RAISE NOTICE 'tender_search_view has been dropped. Re-run original MV migrations to restore.';
END;
$$;
