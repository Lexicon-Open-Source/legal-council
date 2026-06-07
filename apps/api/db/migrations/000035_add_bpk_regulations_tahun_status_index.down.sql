-- Revert composite index for BPK regulations tahun/status queries

DROP INDEX CONCURRENTLY IF EXISTS crawler.idx_bpk_regulations_tahun_status_created;
