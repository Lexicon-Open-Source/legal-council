-- Drop tsvector index on content column
-- PostgreSQL tsvector has 1MB limit which breaks on large judgments (5MB+)
-- Full-text search can be handled by external search engine if needed
DROP INDEX IF EXISTS crawler.idx_sg_judgments_content_search;
