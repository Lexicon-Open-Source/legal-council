-- Remove last_completed_page column

ALTER TABLE crawler.crawler_jobs
DROP COLUMN IF EXISTS last_completed_page;
