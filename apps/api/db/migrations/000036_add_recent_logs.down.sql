-- Remove recent_logs column
ALTER TABLE crawler.crawler_jobs
DROP COLUMN recent_logs;
