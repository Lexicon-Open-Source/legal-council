-- Update putusan_id constraint to allow any lowercase letter (not just hex)
-- This accommodates IDs like "zaf0dd82e3c627049d47313630343238" with z prefix

ALTER TABLE crawler.mahkamah_agung_putusans 
    DROP CONSTRAINT ck_putusan_id_format;

ALTER TABLE crawler.mahkamah_agung_putusans 
    ADD CONSTRAINT ck_putusan_id_format CHECK (putusan_id ~ '^[a-z0-9]{32,}$');
