-- Increase status_paket column size from VARCHAR(50) to VARCHAR(255)
-- Status badge values can exceed 50 characters, e.g.:
-- "Tindak lanjut Prakualifikasi ulang jumlah peserta yang lulus 1" (63 chars)

ALTER TABLE crawler.spse_tenders
    ALTER COLUMN status_paket TYPE VARCHAR(255);

COMMENT ON COLUMN crawler.spse_tenders.status_paket IS 'Package status badge: Paket Gagal, Paket Dibatalkan, Tindak lanjut, etc.';
