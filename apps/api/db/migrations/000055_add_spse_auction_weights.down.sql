-- Revert: Remove reverse auction and evaluation weight fields from spse_tenders

ALTER TABLE crawler.spse_tenders
    DROP CONSTRAINT IF EXISTS ck_spse_tenders_bobot_teknis_range,
    DROP CONSTRAINT IF EXISTS ck_spse_tenders_bobot_biaya_range;

ALTER TABLE crawler.spse_tenders
    DROP COLUMN IF EXISTS reverse_auction,
    DROP COLUMN IF EXISTS bobot_teknis,
    DROP COLUMN IF EXISTS bobot_biaya;
