ALTER TABLE crawler.crawler_jobs
DROP COLUMN IF EXISTS failure_class;

DROP TYPE IF EXISTS crawler.failure_class;
