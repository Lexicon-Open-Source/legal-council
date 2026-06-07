-- Add last_completed_page column for checkpoint resume functionality.
-- This allows jobs to resume from the last successfully completed page
-- instead of starting over from page 1 on retry.

ALTER TABLE crawler.crawler_jobs
ADD COLUMN last_completed_page INTEGER DEFAULT NULL
CHECK (last_completed_page IS NULL OR last_completed_page >= 0);

COMMENT ON COLUMN crawler.crawler_jobs.last_completed_page IS
    'Last successfully completed page (1-indexed). NULL means start fresh.';
