-- Add status and cancellation fields to spse_tenders table
-- These fields capture tender status information from SPSE detail pages

-- Cancellation reason (for failed/cancelled tenders)
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS alasan_pembatalan TEXT;

-- Package status badge text (e.g., "Paket Gagal", "Paket Dibatalkan")
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS status_paket VARCHAR(50);

-- OAP (Orang Asli Papua) affirmative action flag
-- True = reserved for Papua indigenous businesses
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS oap_khusus BOOLEAN;

-- Swakelola executor type (e.g., "K/L/PD Penanggung Jawab Anggaran")
-- Only applicable for swakelola tender type
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS tipe_pelaksana_swakelola VARCHAR(100);

-- Index for filtering by package status (commonly used for finding failed tenders)
CREATE INDEX IF NOT EXISTS idx_spse_tenders_status_paket
    ON crawler.spse_tenders (status_paket)
    WHERE status_paket IS NOT NULL;

-- Index for filtering by OAP affirmative action
CREATE INDEX IF NOT EXISTS idx_spse_tenders_oap_khusus
    ON crawler.spse_tenders (oap_khusus)
    WHERE oap_khusus IS NOT NULL;

COMMENT ON COLUMN crawler.spse_tenders.alasan_pembatalan IS 'Cancellation reason for failed/cancelled tenders';
COMMENT ON COLUMN crawler.spse_tenders.status_paket IS 'Package status badge: Paket Gagal, Paket Dibatalkan, etc.';
COMMENT ON COLUMN crawler.spse_tenders.oap_khusus IS 'Reserved for Orang Asli Papua (Papua affirmative action)';
COMMENT ON COLUMN crawler.spse_tenders.tipe_pelaksana_swakelola IS 'Swakelola executor type for self-managed procurement';
