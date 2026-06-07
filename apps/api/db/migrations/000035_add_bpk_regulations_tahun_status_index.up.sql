-- Add composite index for BPK regulations tahun/status queries
-- Optimizes queries that filter by tahun and status columns with created_at ordering
-- Uses CONCURRENTLY to avoid locking the table during index creation

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_bpk_regulations_tahun_status_created
    ON crawler.bpk_regulations(tahun, status, created_at DESC);
