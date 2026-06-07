-- LPSE site directory (source: eproc.lkpp.go.id)
CREATE TABLE IF NOT EXISTS crawler.lpse_sites (
    code               TEXT PRIMARY KEY,
    name               TEXT NOT NULL,
    base_url           TEXT NOT NULL,
    province           TEXT,
    email              TEXT,
    lpse_type          TEXT,
    status             TEXT,
    is_online          BOOLEAN,
    standardisasi      TEXT,
    pegawai            TEXT,
    kegiatan           TEXT,
    spse_version       TEXT,
    source_updated_at  TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_lpse_sites_updated_at'
          AND tgrelid = 'crawler.lpse_sites'::regclass
    ) THEN
        CREATE TRIGGER update_lpse_sites_updated_at
            BEFORE UPDATE ON crawler.lpse_sites
            FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_lpse_sites_province
    ON crawler.lpse_sites (province);

CREATE INDEX IF NOT EXISTS idx_lpse_sites_status
    ON crawler.lpse_sites (status);

COMMENT ON TABLE crawler.lpse_sites
    IS 'LPSE site directory from eproc.lkpp.go.id; refreshed by scripts/scrape_lpse_sites.py.';
