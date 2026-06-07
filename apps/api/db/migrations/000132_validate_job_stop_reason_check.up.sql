-- Validate the stop_reason CHECK constraint added NOT VALID in migration 000124.
-- Running this in its own migration (its own transaction) means the validation
-- scan only holds a SHARE UPDATE EXCLUSIVE lock, which does not block concurrent
-- reads or writes on crawler.crawler_jobs.
ALTER TABLE crawler.crawler_jobs
    VALIDATE CONSTRAINT crawler_jobs_stop_reason_check;
