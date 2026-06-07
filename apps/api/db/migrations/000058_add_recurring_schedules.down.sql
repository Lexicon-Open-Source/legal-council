DROP TRIGGER IF EXISTS set_updated_at ON crawler.recurring_schedules;
DROP FUNCTION IF EXISTS crawler.trigger_set_timestamp();
DROP INDEX IF EXISTS crawler.idx_crawler_jobs_schedule_id;
ALTER TABLE crawler.crawler_jobs DROP COLUMN IF EXISTS schedule_id;
DROP INDEX IF EXISTS crawler.idx_recurring_schedules_due;
DROP TABLE IF EXISTS crawler.recurring_schedules;
DROP TYPE IF EXISTS crawler.schedule_interval;
