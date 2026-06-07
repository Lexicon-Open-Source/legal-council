-- Runtime crawler configuration control plane.
-- Depends on crawler.update_updated_at_column() from 000005_crawler.up.sql.
CREATE TABLE IF NOT EXISTS crawler.crawler_settings (
    key         TEXT PRIMARY KEY,
    value       JSONB NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by  TEXT
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_crawler_settings_updated_at'
          AND tgrelid = 'crawler.crawler_settings'::regclass
    ) THEN
        CREATE TRIGGER update_crawler_settings_updated_at
            BEFORE UPDATE ON crawler.crawler_settings
            FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS crawler.crawler_type_overrides (
    crawler_type  VARCHAR(50) PRIMARY KEY,
    overrides     JSONB NOT NULL DEFAULT '{}'::jsonb,
    enabled       BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by    TEXT,
    CONSTRAINT crawler_type_overrides_overrides_object CHECK (jsonb_typeof(overrides) = 'object')
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_crawler_type_overrides_updated_at'
          AND tgrelid = 'crawler.crawler_type_overrides'::regclass
    ) THEN
        CREATE TRIGGER update_crawler_type_overrides_updated_at
            BEFORE UPDATE ON crawler.crawler_type_overrides
            FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();
    END IF;
END $$;

COMMENT ON TABLE crawler.crawler_settings
    IS 'Runtime-eligible global crawler settings overlaid on environment defaults.';

COMMENT ON TABLE crawler.crawler_type_overrides
    IS 'Per-crawler default request parameters and enabled flags for runtime job submission.';
