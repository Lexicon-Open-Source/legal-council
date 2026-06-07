-- Reverse the validation performed by the up migration. PostgreSQL cannot
-- directly "un-validate" a constraint, so drop and re-create it as NOT VALID,
-- returning the table to its post-000124 state.
ALTER TABLE crawler.crawler_jobs
    DROP CONSTRAINT IF EXISTS crawler_jobs_stop_reason_check;

ALTER TABLE crawler.crawler_jobs
    ADD CONSTRAINT crawler_jobs_stop_reason_check
    CHECK (
        stop_reason IS NULL
        OR stop_reason IN ('user_stop', 'force_stop')
    ) NOT VALID;
