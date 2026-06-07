-- Remove index for tahap_saat_ini filter
-- Single statement migration for DROP INDEX CONCURRENTLY compatibility
DROP INDEX CONCURRENTLY IF EXISTS crawler.idx_spse_tenders_tahap_saat_ini;
