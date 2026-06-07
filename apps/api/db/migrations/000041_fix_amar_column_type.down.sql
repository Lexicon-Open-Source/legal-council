-- Revert amar column type back to VARCHAR(100)
-- WARNING: This will fail if any data exceeds 100 characters

ALTER TABLE crawler.mahkamah_agung_putusans
    ALTER COLUMN amar TYPE VARCHAR(100);

CREATE INDEX idx_ma_putusans_amar ON crawler.mahkamah_agung_putusans (amar);
