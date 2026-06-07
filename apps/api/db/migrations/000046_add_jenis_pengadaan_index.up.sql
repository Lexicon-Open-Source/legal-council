-- Add index for jenis_pengadaan filter on spse_tenders table
-- Single statement migration for CREATE INDEX CONCURRENTLY compatibility
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_spse_tenders_jenis_pengadaan
ON crawler.spse_tenders(jenis_pengadaan)
WHERE jenis_pengadaan IS NOT NULL;
