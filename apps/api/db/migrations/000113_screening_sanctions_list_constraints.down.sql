DROP INDEX IF EXISTS screening.idx_screening_sanctions_lists_country_code;

ALTER TABLE screening.sanctions_lists
    DROP CONSTRAINT IF EXISTS uq_sanctions_lists_name_publisher,
    DROP COLUMN IF EXISTS country_code;
