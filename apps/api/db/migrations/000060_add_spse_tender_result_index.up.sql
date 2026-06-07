-- Add composite index for tender result distribution query
-- Covers WHERE status_paket IN (...) AND tahun_anggaran LIKE ANY(...)
-- NOTE: Cannot use CONCURRENTLY here because golang-migrate runs migrations
-- inside a transaction block. For production, consider running manually
-- with CONCURRENTLY to avoid table locks.

CREATE INDEX IF NOT EXISTS idx_spse_tender_status_tahun
ON crawler.spse_tenders (status_paket, tahun_anggaran)
WHERE status_paket IN ('Paket Dibatalkan', 'Paket Gagal', 'Paket Selesai');
