-- Add index for instansi filter on spse_tenders table
-- Single statement migration for CREATE INDEX CONCURRENTLY compatibility
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_spse_tenders_instansi
ON crawler.spse_tenders(instansi)
WHERE instansi IS NOT NULL;
