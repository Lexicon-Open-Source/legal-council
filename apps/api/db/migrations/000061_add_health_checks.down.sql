-- Drop the completed jobs index
DROP INDEX IF EXISTS crawler.idx_crawler_jobs_completed_per_type;

-- Remove paused_reason column from recurring_schedules
ALTER TABLE crawler.recurring_schedules
DROP COLUMN IF EXISTS paused_reason;

-- Drop health_checks table (cascade drops trigger)
DROP TABLE IF EXISTS crawler.health_checks;
