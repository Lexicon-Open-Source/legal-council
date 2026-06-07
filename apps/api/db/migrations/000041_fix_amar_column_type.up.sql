-- Fix amar column type from VARCHAR(100) to TEXT
-- The amar (verdict) field can contain thousands of characters

ALTER TABLE crawler.mahkamah_agung_putusans
    ALTER COLUMN amar TYPE TEXT;

-- Drop the index that was created on VARCHAR and recreate
-- (index on TEXT is less efficient but necessary for full content)
DROP INDEX IF EXISTS crawler.idx_ma_putusans_amar;
