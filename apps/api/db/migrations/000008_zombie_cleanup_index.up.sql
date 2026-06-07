-- Add partial index for efficient zombie job cleanup
-- This index optimizes the query: SELECT * FROM crawler.crawler_jobs WHERE status = 'running' AND started_at < $1
CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_crawler_jobs_running_started_at
ON crawler.crawler_jobs (started_at)
WHERE status = 'running';
