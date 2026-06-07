COMMENT ON COLUMN screening.entities.nationality_code IS NULL;

COMMENT ON COLUMN screening.entities.nationality IS NULL;

ALTER TABLE screening.entities
    DROP CONSTRAINT IF EXISTS screening_entities_nationality_code_iso2_check;

ALTER TABLE screening.entities
    DROP COLUMN IF EXISTS nationality_code,
    DROP COLUMN IF EXISTS nationality;
