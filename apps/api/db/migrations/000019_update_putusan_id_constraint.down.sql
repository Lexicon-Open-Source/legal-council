-- Revert putusan_id constraint to only allow hex characters
ALTER TABLE crawler.mahkamah_agung_putusans 
    DROP CONSTRAINT ck_putusan_id_format;

ALTER TABLE crawler.mahkamah_agung_putusans 
    ADD CONSTRAINT ck_putusan_id_format CHECK (putusan_id ~ '^[a-f0-9]{32,}$');
