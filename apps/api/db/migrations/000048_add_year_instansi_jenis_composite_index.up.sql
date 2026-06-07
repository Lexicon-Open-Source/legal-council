-- Add composite index for common filter combination on spse_tenders table
-- Supports queries filtering by year + instansi + jenis_pengadaan together
-- Single statement migration for CREATE INDEX CONCURRENTLY compatibility
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_spse_tenders_year_instansi_jenis
ON crawler.spse_tenders(tahun_anggaran, instansi, jenis_pengadaan);
