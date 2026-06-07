-- Add index for tahap_saat_ini filter on spse_tenders table
-- Single statement migration for CREATE INDEX CONCURRENTLY compatibility
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_spse_tenders_tahap_saat_ini
ON crawler.spse_tenders(tahap_saat_ini)
WHERE tahap_saat_ini IS NOT NULL;
