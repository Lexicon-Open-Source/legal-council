-- Add recent_logs JSONB column to store last 100 log entries for real-time streaming
ALTER TABLE crawler.crawler_jobs
ADD COLUMN recent_logs JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN crawler.crawler_jobs.recent_logs IS
    'Circular buffer of last 100 log entries for this job';
