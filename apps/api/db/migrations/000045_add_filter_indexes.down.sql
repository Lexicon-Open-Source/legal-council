-- Remove index for instansi filter
-- Single statement migration for DROP INDEX CONCURRENTLY compatibility
DROP INDEX CONCURRENTLY IF EXISTS crawler.idx_spse_tenders_instansi;
