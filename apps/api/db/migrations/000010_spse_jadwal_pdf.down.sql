-- Rollback jadwal and PDF columns from spse_tenders table

DROP INDEX IF EXISTS crawler.idx_spse_tenders_has_pdf;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS jadwal;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS uraian_pdf_storage_path;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS uraian_pdf_url;
