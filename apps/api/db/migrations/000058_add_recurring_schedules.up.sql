-- Create schedule interval enum
CREATE TYPE crawler.schedule_interval AS ENUM (
    'daily', 'weekly', 'fortnightly', 'monthly'
);

-- Create recurring schedules table
CREATE TABLE crawler.recurring_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crawler_type VARCHAR(50) NOT NULL,
    crawler_params JSONB NOT NULL,
    interval crawler.schedule_interval NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused')),

    -- Scheduling metadata
    next_scheduled_at TIMESTAMPTZ,
    last_executed_at TIMESTAMPTZ,
    last_execution_job_id UUID REFERENCES crawler.crawler_jobs(id),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT valid_crawler_type CHECK (
        crawler_type IN ('spse', 'bpk', 'lkpp_blacklist', 'mahkamah_agung',
                         'singapore', 'sprm', 'opentender', 'opentender_ocds',
                         'sirup', 'mahkamah_agung_pdf', 'interpol')
    )
);

-- Index for efficient schedule polling
CREATE INDEX idx_recurring_schedules_due ON crawler.recurring_schedules (next_scheduled_at)
    WHERE status = 'active';

-- Add schedule_id to crawler_jobs for tracking
ALTER TABLE crawler.crawler_jobs
ADD COLUMN schedule_id UUID REFERENCES crawler.recurring_schedules(id);

-- Index for execution history queries
CREATE INDEX idx_crawler_jobs_schedule_id ON crawler.crawler_jobs (schedule_id)
    WHERE schedule_id IS NOT NULL;

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION crawler.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON crawler.recurring_schedules
    FOR EACH ROW EXECUTE FUNCTION crawler.trigger_set_timestamp();

-- Comment on table
COMMENT ON TABLE crawler.recurring_schedules IS
    'Recurring crawl schedule definitions. Jobs are created automatically based on interval.';
