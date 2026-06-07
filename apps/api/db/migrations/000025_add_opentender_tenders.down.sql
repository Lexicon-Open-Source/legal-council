-- Drop OpenTender tenders table and indexes
DROP INDEX IF EXISTS crawler.idx_opentender_created_at;
DROP INDEX IF EXISTS crawler.idx_opentender_category;
DROP INDEX IF EXISTS crawler.idx_opentender_fiscal_year;
DROP INDEX IF EXISTS crawler.idx_opentender_lpse_code;
DROP TABLE IF EXISTS crawler.opentender_tenders;
