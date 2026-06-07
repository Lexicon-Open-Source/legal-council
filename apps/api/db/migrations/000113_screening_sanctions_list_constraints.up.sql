-- Add country_code to sanctions_lists for jurisdiction filtering by the Egress API.
-- Add UNIQUE constraint on (name, publisher) so seed upsert ON CONFLICT works.
ALTER TABLE screening.sanctions_lists
    ADD COLUMN country_code TEXT,
    ADD CONSTRAINT uq_sanctions_lists_name_publisher UNIQUE (name, publisher);

CREATE INDEX idx_screening_sanctions_lists_country_code
    ON screening.sanctions_lists (country_code);
