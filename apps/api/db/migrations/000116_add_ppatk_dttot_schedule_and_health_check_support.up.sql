-- Add ppatk_dttot to recurring schedules and seed health checks.
ALTER TABLE crawler.recurring_schedules DROP CONSTRAINT valid_crawler_type;
ALTER TABLE crawler.recurring_schedules ADD CONSTRAINT valid_crawler_type CHECK (
    crawler_type IN (
        'spse_http', 'bpk', 'lkpp_blacklist', 'mahkamah_agung', 'singapore',
        'sprm', 'opentender', 'opentender_ocds', 'sirup', 'mahkamah_agung_pdf',
        'interpol', 'eu_most_wanted', 'uk_companies_house', 'sg_mas',
        'sc_malaysia', 'adb_sanctions', 'ppatk_dttot'
    )
);

INSERT INTO crawler.health_checks (crawler_type)
VALUES ('ppatk_dttot')
ON CONFLICT (crawler_type) DO NOTHING;
