-- Remove tender query optimization indexes
DROP INDEX IF EXISTS crawler.idx_spse_tenders_pagu;
DROP INDEX IF EXISTS crawler.idx_spse_tenders_has_pdf;
