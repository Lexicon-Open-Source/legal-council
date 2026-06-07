-- SC Malaysia AOB Sanctions
CREATE TABLE IF NOT EXISTS crawler.sc_aob_sanctions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year                    INTEGER NOT NULL,
    entry_number            TEXT,
    nature_of_misconduct    TEXT NOT NULL,
    auditor                 TEXT NOT NULL,
    description             TEXT,
    action_taken            TEXT,
    action_date             DATE,
    raw_data                JSONB NOT NULL DEFAULT '{}',
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_sc_aob_sanctions_updated_at
    BEFORE UPDATE ON crawler.sc_aob_sanctions
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

-- Natural key: year + entry number (matches source data structure)
CREATE UNIQUE INDEX idx_sc_aob_sanctions_natural_key
    ON crawler.sc_aob_sanctions (year, entry_number);

CREATE INDEX idx_sc_aob_sanctions_auditor
    ON crawler.sc_aob_sanctions (auditor);

CREATE INDEX idx_sc_aob_sanctions_year
    ON crawler.sc_aob_sanctions (year DESC);

COMMENT ON TABLE crawler.sc_aob_sanctions
    IS 'SC Malaysia Audit Oversight Board sanctions against auditors and audit firms';

-- SC Malaysia Investor Alert List
CREATE TABLE IF NOT EXISTS crawler.sc_investor_alerts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    entity_type     TEXT,
    addresses       JSONB DEFAULT '[]',
    websites        JSONB DEFAULT '[]',
    date_added      DATE,
    remarks         TEXT,
    raw_data        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_sc_investor_alerts_updated_at
    BEFORE UPDATE ON crawler.sc_investor_alerts
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

-- Case-insensitive unique on name (entity names should be unique identifiers)
CREATE UNIQUE INDEX idx_sc_investor_alerts_name_unique
    ON crawler.sc_investor_alerts (lower(name));

CREATE INDEX idx_sc_investor_alerts_entity_type
    ON crawler.sc_investor_alerts (entity_type)
    WHERE entity_type IS NOT NULL;

-- Trigram indexes for name search
CREATE INDEX idx_sc_aob_sanctions_auditor_trgm
    ON crawler.sc_aob_sanctions USING GIN (auditor gin_trgm_ops);

CREATE INDEX idx_sc_investor_alerts_name_trgm
    ON crawler.sc_investor_alerts USING GIN (name gin_trgm_ops);

COMMENT ON TABLE crawler.sc_investor_alerts
    IS 'SC Malaysia investor alert list - unauthorized entities, websites, and individuals';
