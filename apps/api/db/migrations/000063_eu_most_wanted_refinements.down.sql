-- Revert valid_crawler_type CHECK constraint (remove eu_most_wanted)
ALTER TABLE crawler.recurring_schedules DROP CONSTRAINT valid_crawler_type;
ALTER TABLE crawler.recurring_schedules ADD CONSTRAINT valid_crawler_type CHECK (
    crawler_type IN (
        'spse', 'bpk', 'lkpp_blacklist', 'mahkamah_agung', 'singapore',
        'sprm', 'opentender', 'opentender_ocds', 'sirup', 'mahkamah_agung_pdf',
        'interpol'
    )
);

-- Revert NOT NULL constraints on timestamps
ALTER TABLE crawler.eu_most_wanted_fugitives
    ALTER COLUMN created_at DROP NOT NULL,
    ALTER COLUMN updated_at DROP NOT NULL;

-- Drop updated_at index
DROP INDEX IF EXISTS crawler.idx_eu_most_wanted_updated_at;
