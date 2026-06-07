-- Add reverse auction and evaluation weight fields to spse_tenders
-- These fields are extracted from the tender detail page (pengumuman tab)

ALTER TABLE crawler.spse_tenders
    ADD COLUMN reverse_auction BOOLEAN,
    ADD COLUMN bobot_teknis DECIMAL(5,2),
    ADD COLUMN bobot_biaya DECIMAL(5,2);

-- Add constraint to ensure weights are valid percentages (0-100)
ALTER TABLE crawler.spse_tenders
    ADD CONSTRAINT ck_spse_tenders_bobot_teknis_range
        CHECK (bobot_teknis IS NULL OR (bobot_teknis >= 0 AND bobot_teknis <= 100)),
    ADD CONSTRAINT ck_spse_tenders_bobot_biaya_range
        CHECK (bobot_biaya IS NULL OR (bobot_biaya >= 0 AND bobot_biaya <= 100));

-- Add comments for documentation
COMMENT ON COLUMN crawler.spse_tenders.reverse_auction IS 'Whether the tender uses e-reverse auction (online descending price bidding)';
COMMENT ON COLUMN crawler.spse_tenders.bobot_teknis IS 'Technical evaluation weight percentage (e.g., 80.0 means 80%)';
COMMENT ON COLUMN crawler.spse_tenders.bobot_biaya IS 'Cost evaluation weight percentage (e.g., 20.0 means 20%)';
