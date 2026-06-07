ALTER TABLE screening.entities
    ADD COLUMN IF NOT EXISTS nationality TEXT,
    ADD COLUMN IF NOT EXISTS nationality_code TEXT;

ALTER TABLE screening.entities
    ADD CONSTRAINT screening_entities_nationality_code_iso2_check
    CHECK (nationality_code IS NULL OR nationality_code ~ '^[A-Z]{2}$');

COMMENT ON COLUMN screening.entities.nationality
    IS 'Normalized ISO 3166 English short country name for the entity nationality.';

COMMENT ON COLUMN screening.entities.nationality_code
    IS 'ISO 3166-1 alpha-2 country code for the entity nationality.';
