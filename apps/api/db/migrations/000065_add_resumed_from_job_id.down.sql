DROP INDEX IF EXISTS crawler.idx_crawler_jobs_active_resume;
DROP INDEX IF EXISTS crawler.idx_crawler_jobs_resumed_from;
ALTER TABLE crawler.crawler_jobs DROP COLUMN IF EXISTS resumed_from_job_id;
