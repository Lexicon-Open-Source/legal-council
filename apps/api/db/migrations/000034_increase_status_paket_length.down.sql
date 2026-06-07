-- Revert status_paket column size from VARCHAR(255) to VARCHAR(50)
-- Note: This may fail if existing data exceeds 50 characters

ALTER TABLE crawler.spse_tenders
    ALTER COLUMN status_paket TYPE VARCHAR(50);

COMMENT ON COLUMN crawler.spse_tenders.status_paket IS 'Package status badge: Paket Gagal, Paket Dibatalkan, etc.';
