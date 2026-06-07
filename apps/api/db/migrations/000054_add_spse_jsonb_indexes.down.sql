-- Drop SPSE tender JSONB indexes
-- NOTE: Cannot use CONCURRENTLY here because golang-migrate runs migrations
-- inside a transaction block.
DROP INDEX IF EXISTS crawler.idx_spse_tender_jadwal_length;
DROP INDEX IF EXISTS crawler.idx_spse_tender_pemenang_length;
DROP INDEX IF EXISTS crawler.idx_spse_tender_jadwal_gin;
DROP INDEX IF EXISTS crawler.idx_spse_tender_pemenang_gin;
