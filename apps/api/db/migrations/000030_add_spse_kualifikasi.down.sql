-- Rollback kualifikasi fields from spse_tenders table

DROP INDEX IF EXISTS crawler.idx_spse_tenders_kualifikasi_usaha;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS syarat_kualifikasi;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS kualifikasi_usaha;
