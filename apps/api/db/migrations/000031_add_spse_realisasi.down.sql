-- Rollback realisasi field from spse_tenders table

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS realisasi;
