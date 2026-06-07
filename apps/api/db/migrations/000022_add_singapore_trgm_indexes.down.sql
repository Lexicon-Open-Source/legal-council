DROP INDEX IF EXISTS crawler.idx_sg_judgments_citation_trgm;
DROP INDEX IF EXISTS crawler.idx_sg_judgments_case_title_trgm;
DROP INDEX IF EXISTS crawler.idx_sg_judgments_court_type_date;
-- Note: Don't drop pg_trgm extension as other tables may use it
