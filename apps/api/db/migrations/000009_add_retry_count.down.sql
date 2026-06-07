-- Remove retry_count column from crawler_jobs.
ALTER TABLE crawler.crawler_jobs
DROP COLUMN IF EXISTS retry_count;
