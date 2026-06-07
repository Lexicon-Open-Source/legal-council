-- Revert to original constraint without ON DELETE clause
ALTER TABLE crawler.crawler_jobs
DROP CONSTRAINT IF EXISTS crawler_jobs_schedule_id_fkey;

ALTER TABLE crawler.crawler_jobs
ADD CONSTRAINT crawler_jobs_schedule_id_fkey
FOREIGN KEY (schedule_id) REFERENCES crawler.recurring_schedules(id);
