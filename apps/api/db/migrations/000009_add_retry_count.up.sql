-- Add retry_count column to crawler_jobs for automatic retry tracking.
-- Jobs will automatically retry up to max_retries times with exponential backoff.
ALTER TABLE crawler.crawler_jobs
ADD COLUMN IF NOT EXISTS retry_count INTEGER NOT NULL DEFAULT 0;
