-- Remove content column and index
DROP INDEX IF EXISTS crawler.idx_sg_judgments_content_search;
ALTER TABLE crawler.singapore_judgments DROP COLUMN IF EXISTS content;
