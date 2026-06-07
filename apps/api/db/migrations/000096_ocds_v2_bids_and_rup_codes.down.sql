-- Reverse migration 000096

-- Remove extension comments
COMMENT ON COLUMN ocds.planning.fiscal_year IS NULL;
COMMENT ON COLUMN ocds.planning.rup_id IS NULL;
COMMENT ON COLUMN ocds.planning.rup_codes IS NULL;

-- Drop rup_codes from tender
DROP INDEX IF EXISTS ocds.idx_tender_rup_codes;
ALTER TABLE ocds.tender DROP COLUMN IF EXISTS rup_codes;

-- Restore bid columns on tender_tenderers
ALTER TABLE ocds.tender_tenderers
    ADD COLUMN IF NOT EXISTS bid_amount NUMERIC(20,2),
    ADD COLUMN IF NOT EXISTS bid_currency VARCHAR(3),
    ADD COLUMN IF NOT EXISTS corrected_amount NUMERIC(20,2),
    ADD COLUMN IF NOT EXISTS bid_status VARCHAR(50);

-- Drop bids table
DROP TABLE IF EXISTS ocds.bids CASCADE;
