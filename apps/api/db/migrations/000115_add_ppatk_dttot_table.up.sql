-- PPATK DTTOT (Daftar Terduga Teroris dan Organisasi Teroris)
CREATE TABLE IF NOT EXISTS crawler.ppatk_dttot (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    densus_code         TEXT NOT NULL,
    name                TEXT NOT NULL,
    description         TEXT,
    entity_type         TEXT NOT NULL
        CONSTRAINT ppatk_dttot_entity_type_check CHECK (entity_type IN ('Orang', 'Korporasi')),
    birth_place         TEXT,
    birth_date          TEXT,
    nationality         TEXT,
    address             TEXT,
    raw_data            JSONB NOT NULL DEFAULT '{}',
    last_seen_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_ppatk_dttot_updated_at
    BEFORE UPDATE ON crawler.ppatk_dttot
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

CREATE UNIQUE INDEX idx_ppatk_dttot_densus_code
    ON crawler.ppatk_dttot (densus_code);

CREATE INDEX idx_ppatk_dttot_entity_type
    ON crawler.ppatk_dttot (entity_type);

COMMENT ON TABLE crawler.ppatk_dttot
    IS 'PPATK DTTOT (Daftar Terduga Teroris dan Organisasi Teroris) entity list';
