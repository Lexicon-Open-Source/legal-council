DELETE FROM crawler.health_checks WHERE crawler_type = 'world_bank_debarred';

ALTER TABLE crawler.recurring_schedules DROP CONSTRAINT valid_crawler_type;
ALTER TABLE crawler.recurring_schedules ADD CONSTRAINT valid_crawler_type CHECK (
    crawler_type IN (
        'spse_http', 'bpk', 'lkpp_blacklist', 'mahkamah_agung', 'singapore',
        'sprm', 'opentender', 'opentender_ocds', 'sirup', 'mahkamah_agung_pdf',
        'interpol', 'eu_most_wanted', 'uk_companies_house', 'sg_mas',
        'sc_malaysia', 'adb_sanctions', 'ppatk_dttot'
    )
);

DROP TRIGGER IF EXISTS update_world_bank_debarred_updated_at
    ON crawler.world_bank_debarred;

DROP INDEX IF EXISTS crawler.idx_world_bank_debarred_supp_id;
DROP INDEX IF EXISTS crawler.idx_world_bank_debarred_name;
DROP INDEX IF EXISTS crawler.idx_world_bank_debarred_country_name;
DROP INDEX IF EXISTS crawler.idx_world_bank_debarred_entity_type;

DROP TABLE IF EXISTS crawler.world_bank_debarred;
