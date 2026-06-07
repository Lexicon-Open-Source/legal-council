-- Add updated_at DESC index for ORDER BY performance
CREATE INDEX idx_eu_most_wanted_updated_at ON crawler.eu_most_wanted_fugitives (updated_at DESC);

-- Add NOT NULL constraints to timestamps (they have DEFAULT NOW() but were missing NOT NULL)
ALTER TABLE crawler.eu_most_wanted_fugitives
    ALTER COLUMN created_at SET NOT NULL,
    ALTER COLUMN updated_at SET NOT NULL;

-- Add eu_most_wanted to valid_crawler_type CHECK constraint on recurring_schedules
ALTER TABLE crawler.recurring_schedules DROP CONSTRAINT valid_crawler_type;
ALTER TABLE crawler.recurring_schedules ADD CONSTRAINT valid_crawler_type CHECK (
    crawler_type IN (
        'spse', 'bpk', 'lkpp_blacklist', 'mahkamah_agung', 'singapore',
        'sprm', 'opentender', 'opentender_ocds', 'sirup', 'mahkamah_agung_pdf',
        'interpol', 'eu_most_wanted'
    )
);
