-- Rollback status and cancellation fields from spse_tenders table

DROP INDEX IF EXISTS crawler.idx_spse_tenders_oap_khusus;
DROP INDEX IF EXISTS crawler.idx_spse_tenders_status_paket;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS tipe_pelaksana_swakelola;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS oap_khusus;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS status_paket;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS alasan_pembatalan;
