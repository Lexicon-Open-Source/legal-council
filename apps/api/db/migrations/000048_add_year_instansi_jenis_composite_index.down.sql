-- Remove composite index for filter combination
-- Single statement migration for DROP INDEX CONCURRENTLY compatibility
DROP INDEX CONCURRENTLY IF EXISTS crawler.idx_spse_tenders_year_instansi_jenis;
