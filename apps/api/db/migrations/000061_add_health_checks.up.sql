-- Create health_checks table for proactive crawler source monitoring
CREATE TABLE crawler.health_checks (
    crawler_type VARCHAR(50) PRIMARY KEY,
    passed BOOLEAN NOT NULL DEFAULT true,
    consecutive_failures INTEGER NOT NULL DEFAULT 0,
    last_checked_at TIMESTAMPTZ,
    next_check_at TIMESTAMPTZ,
    last_error TEXT,
    failed_selectors JSONB,
    duration_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auto-update updated_at trigger (reuses existing function)
CREATE TRIGGER set_health_checks_updated_at
    BEFORE UPDATE ON crawler.health_checks
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

-- Seed all known crawler types
INSERT INTO crawler.health_checks (crawler_type) VALUES
    ('spse'), ('bpk'), ('mahkamah_agung'), ('lkpp_blacklist'),
    ('opentender'), ('interpol'), ('sirup'), ('singapore'), ('sprm');

COMMENT ON TABLE crawler.health_checks IS
    'Health check state per crawler type. One row per crawler, seeded at migration time.';

-- Add paused_reason to recurring_schedules to distinguish manual vs automatic pauses
ALTER TABLE crawler.recurring_schedules
ADD COLUMN paused_reason VARCHAR(50);

COMMENT ON COLUMN crawler.recurring_schedules.paused_reason IS
    'Why the schedule was paused: NULL = manual, ''health_check'' = paused by health check system';

-- Index for status API: efficient per-type completed job stats
CREATE INDEX idx_crawler_jobs_completed_per_type
    ON crawler.crawler_jobs (crawler_type, completed_at DESC)
    WHERE status = 'completed';
