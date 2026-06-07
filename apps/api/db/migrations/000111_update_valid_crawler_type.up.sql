-- Update valid_crawler_type CHECK constraint: replace 'spse' with 'spse_http',
-- add 'adb_sanctions' and 'sc_malaysia'.
ALTER TABLE crawler.recurring_schedules DROP CONSTRAINT valid_crawler_type;
ALTER TABLE crawler.recurring_schedules ADD CONSTRAINT valid_crawler_type CHECK (
    crawler_type IN (
        'spse_http', 'bpk', 'lkpp_blacklist', 'mahkamah_agung', 'singapore',
        'sprm', 'opentender', 'opentender_ocds', 'sirup', 'mahkamah_agung_pdf',
        'interpol', 'eu_most_wanted', 'uk_companies_house', 'sg_mas',
        'sc_malaysia', 'adb_sanctions'
    )
);
