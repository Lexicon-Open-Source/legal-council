-- Remove index for jenis_pengadaan filter
-- Single statement migration for DROP INDEX CONCURRENTLY compatibility
DROP INDEX CONCURRENTLY IF EXISTS crawler.idx_spse_tenders_jenis_pengadaan;
