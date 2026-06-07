-- Enable pg_trgm extension for trigram-based text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Add GIN indexes for efficient ILIKE/similarity searches
-- Note: Not using CONCURRENTLY because golang-migrate runs in transactions.
-- For small tables this is acceptable; for large tables, run indexes manually.
CREATE INDEX IF NOT EXISTS idx_sg_judgments_citation_trgm
ON crawler.singapore_judgments
USING gin(citation gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_sg_judgments_case_title_trgm
ON crawler.singapore_judgments
USING gin(case_title gin_trgm_ops);

-- Composite index for common filter + sort pattern
CREATE INDEX IF NOT EXISTS idx_sg_judgments_court_type_date
ON crawler.singapore_judgments (court_type, decision_date DESC NULLS LAST);
