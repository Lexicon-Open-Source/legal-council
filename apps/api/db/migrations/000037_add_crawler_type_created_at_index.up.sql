-- Add composite index for recent jobs per crawler query
-- Supports the window function: PARTITION BY crawler_type ORDER BY created_at DESC
CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_crawler_jobs_crawler_type_created_at
ON crawler.crawler_jobs (crawler_type, created_at DESC);
