ALTER TABLE crawler.crawler_jobs
    DROP CONSTRAINT IF EXISTS crawler_jobs_stop_reason_check;

ALTER TABLE crawler.crawler_jobs
    DROP COLUMN IF EXISTS stopped_at,
    DROP COLUMN IF EXISTS stop_reason,
    DROP COLUMN IF EXISTS stop_requested;
