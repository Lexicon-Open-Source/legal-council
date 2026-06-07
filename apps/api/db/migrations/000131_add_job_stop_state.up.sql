-- Persist user-requested job stops so workers can honor stop intent
-- even if Redis flags are lost or the job is reloaded from PostgreSQL.
ALTER TABLE crawler.crawler_jobs
    ADD COLUMN stop_requested boolean NOT NULL DEFAULT false,
    ADD COLUMN stop_reason text,
    ADD COLUMN stopped_at timestamp with time zone;

-- Add the CHECK constraint as NOT VALID so this statement takes only a brief
-- ACCESS EXCLUSIVE lock and does not scan existing rows. New and updated rows
-- are enforced immediately; the pre-existing rows (all NULL for this brand-new
-- column) are validated separately in migration 000125 under a lighter
-- SHARE UPDATE EXCLUSIVE lock. This is the standard Postgres zero-downtime
-- pattern for adding a CHECK constraint to a large table.
ALTER TABLE crawler.crawler_jobs
    ADD CONSTRAINT crawler_jobs_stop_reason_check
    CHECK (
        stop_reason IS NULL
        OR stop_reason IN ('user_stop', 'force_stop')
    ) NOT VALID;
