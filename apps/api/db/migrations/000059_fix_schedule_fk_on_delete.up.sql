-- Drop the existing constraint and recreate with ON DELETE SET NULL
-- This prevents cryptic errors when deleting schedules with job history
ALTER TABLE crawler.crawler_jobs
DROP CONSTRAINT IF EXISTS crawler_jobs_schedule_id_fkey;

ALTER TABLE crawler.crawler_jobs
ADD CONSTRAINT crawler_jobs_schedule_id_fkey
FOREIGN KEY (schedule_id) REFERENCES crawler.recurring_schedules(id) ON DELETE SET NULL;
