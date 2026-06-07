-- World Bank Listing of Ineligible Firms and Individuals
CREATE TABLE IF NOT EXISTS crawler.world_bank_debarred (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supp_id             TEXT NOT NULL,
    name                TEXT NOT NULL,
    country_name        TEXT,
    address             TEXT,
    city                TEXT,
    supplier_type_code  TEXT,
    entity_type         TEXT
                        CONSTRAINT world_bank_debarred_entity_type_check
                        CHECK (entity_type IN ('company', 'person')),
    additional_info     TEXT,
    debar_type          TEXT,
    debar_from_date     DATE,
    debar_to_date       DATE,
    is_indefinite       BOOLEAN NOT NULL DEFAULT FALSE,
    raw_data            JSONB NOT NULL DEFAULT '{}',
    last_seen_at        TIMESTAMPTZ DEFAULT NOW(),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT world_bank_debarred_indefinite_date_check
        CHECK (NOT is_indefinite OR debar_to_date IS NULL)
);

CREATE TRIGGER update_world_bank_debarred_updated_at
    BEFORE UPDATE ON crawler.world_bank_debarred
    FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();

CREATE UNIQUE INDEX idx_world_bank_debarred_supp_id
    ON crawler.world_bank_debarred (supp_id);

CREATE INDEX idx_world_bank_debarred_name
    ON crawler.world_bank_debarred (name);

CREATE INDEX idx_world_bank_debarred_country_name
    ON crawler.world_bank_debarred (country_name)
    WHERE country_name IS NOT NULL;

CREATE INDEX idx_world_bank_debarred_entity_type
    ON crawler.world_bank_debarred (entity_type)
    WHERE entity_type IS NOT NULL;

COMMENT ON TABLE crawler.world_bank_debarred
    IS 'World Bank listing of ineligible firms and individuals';

INSERT INTO crawler.health_checks (crawler_type)
VALUES ('world_bank_debarred')
ON CONFLICT (crawler_type) DO NOTHING;

ALTER TABLE crawler.recurring_schedules DROP CONSTRAINT valid_crawler_type;
ALTER TABLE crawler.recurring_schedules ADD CONSTRAINT valid_crawler_type CHECK (
    crawler_type IN (
        'spse_http', 'bpk', 'lkpp_blacklist', 'mahkamah_agung', 'singapore',
        'sprm', 'opentender', 'opentender_ocds', 'sirup', 'mahkamah_agung_pdf',
        'interpol', 'eu_most_wanted', 'uk_companies_house', 'sg_mas',
        'sc_malaysia', 'adb_sanctions', 'ppatk_dttot', 'world_bank_debarred'
    )
);
