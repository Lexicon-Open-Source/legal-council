-- Hotfix: Add initiation_type column if missing from ocds.releases
-- This handles cases where migration 39 was applied but the column wasn't created

DO $$
BEGIN
    -- Check if column exists, add if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'ocds'
        AND table_name = 'releases'
        AND column_name = 'initiation_type'
    ) THEN
        ALTER TABLE ocds.releases
        ADD COLUMN initiation_type VARCHAR(50) DEFAULT 'tender';
    END IF;
END $$;
