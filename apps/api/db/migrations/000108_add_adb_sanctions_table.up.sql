-- ADB (Asian Development Bank) Sanctions List
CREATE TABLE IF NOT EXISTS crawler.adb_sanctions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    adb_id              TEXT NOT NULL CONSTRAINT adb_sanctions_adb_id_format CHECK (adb_id ~ '^[a-fA-F0-9]{24}$'),
    name                TEXT NOT NULL,
    address             TEXT,
    sanction_type       TEXT NOT NULL,
    other_name          TEXT,
    nationality         TEXT,
    effective_date      DATE,
    lapse_date          DATE,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    grounds             TEXT,
    entity_type         TEXT CONSTRAINT adb_sanctions_entity_type_check CHECK (entity_type IN ('company', 'person')),
    changes_made_on     DATE,
    raw_data            JSONB NOT NULL DEFAULT '{}',
    last_seen_at        TIMESTAMPTZ DEFAULT NOW(),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_adb_sanctions_updated_at
    BEFORE UPDATE ON crawler.adb_sanctions
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

-- Natural key: ADB record ID (24-char hex, MongoDB ObjectID format)
CREATE UNIQUE INDEX idx_adb_sanctions_adb_id
    ON crawler.adb_sanctions (adb_id);

CREATE INDEX idx_adb_sanctions_nationality
    ON crawler.adb_sanctions (nationality)
    WHERE nationality IS NOT NULL;

CREATE INDEX idx_adb_sanctions_name
    ON crawler.adb_sanctions (name);

COMMENT ON TABLE crawler.adb_sanctions
    IS 'Asian Development Bank sanctions list - debarred entities (firms and individuals)';
