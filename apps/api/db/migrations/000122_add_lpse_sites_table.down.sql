DROP TRIGGER IF EXISTS update_lpse_sites_updated_at ON crawler.lpse_sites;

DROP INDEX IF EXISTS crawler.idx_lpse_sites_status;
DROP INDEX IF EXISTS crawler.idx_lpse_sites_province;

DROP TABLE IF EXISTS crawler.lpse_sites CASCADE;
