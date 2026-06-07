ALTER TABLE crawler.crawler_jobs
ADD COLUMN resumed_from_job_id uuid REFERENCES crawler.crawler_jobs(id);

-- Partial unique index: only one non-terminal resume job per parent.
-- This prevents the TOCTOU race condition where two concurrent resume
-- requests both pass the SELECT check and both INSERT.
CREATE UNIQUE INDEX idx_crawler_jobs_active_resume
ON crawler.crawler_jobs(resumed_from_job_id)
WHERE resumed_from_job_id IS NOT NULL
  AND status NOT IN ('completed', 'failed', 'cancelled');

-- For querying all resume jobs (including finished ones) by parent
CREATE INDEX idx_crawler_jobs_resumed_from
ON crawler.crawler_jobs(resumed_from_job_id)
WHERE resumed_from_job_id IS NOT NULL;

COMMENT ON COLUMN crawler.crawler_jobs.resumed_from_job_id IS
  'References the original job this was resumed from. NULL for fresh jobs.';
