-- OpenTender master data tables (source: pro.opentender.net)
CREATE TABLE IF NOT EXISTS crawler.opentender_lpse (
    code        TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_opentender_lpse_updated_at'
          AND tgrelid = 'crawler.opentender_lpse'::regclass
    ) THEN
        CREATE TRIGGER update_opentender_lpse_updated_at
            BEFORE UPDATE ON crawler.opentender_lpse
            FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();
    END IF;
END $$;

COMMENT ON TABLE crawler.opentender_lpse
    IS 'OpenTender LPSE master data from pro.opentender.net; refreshed by scripts/fetch_opentender_master.py.';

CREATE TABLE IF NOT EXISTS crawler.opentender_instansi (
    code        TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    type        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_opentender_instansi_updated_at'
          AND tgrelid = 'crawler.opentender_instansi'::regclass
    ) THEN
        CREATE TRIGGER update_opentender_instansi_updated_at
            BEFORE UPDATE ON crawler.opentender_instansi
            FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_opentender_instansi_type
    ON crawler.opentender_instansi (type);

COMMENT ON TABLE crawler.opentender_instansi
    IS 'OpenTender instansi master data from pro.opentender.net; refreshed by scripts/fetch_opentender_master.py.';

CREATE TABLE IF NOT EXISTS crawler.opentender_skpd (
    code        BIGINT PRIMARY KEY,
    name        TEXT NOT NULL,
    alt_name    TEXT,
    lpse_code   TEXT,
    lpse_name   TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_opentender_skpd_updated_at'
          AND tgrelid = 'crawler.opentender_skpd'::regclass
    ) THEN
        CREATE TRIGGER update_opentender_skpd_updated_at
            BEFORE UPDATE ON crawler.opentender_skpd
            FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_opentender_skpd_lpse_code
    ON crawler.opentender_skpd (lpse_code, code)
    WHERE lpse_code IS NOT NULL;

COMMENT ON TABLE crawler.opentender_skpd
    IS 'OpenTender SKPD master data from pro.opentender.net; refreshed by scripts/fetch_opentender_master.py.';

CREATE TABLE IF NOT EXISTS crawler.opentender_source_fund (
    key         INT PRIMARY KEY,
    label       TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_opentender_source_fund_updated_at'
          AND tgrelid = 'crawler.opentender_source_fund'::regclass
    ) THEN
        CREATE TRIGGER update_opentender_source_fund_updated_at
            BEFORE UPDATE ON crawler.opentender_source_fund
            FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();
    END IF;
END $$;

COMMENT ON TABLE crawler.opentender_source_fund
    IS 'OpenTender source fund master data from pro.opentender.net; refreshed by scripts/fetch_opentender_master.py.';
