-- Add realisasi (contract execution/realization) fields to spse_tenders table
-- These fields capture contract execution data from pemenang berkontrak tab

-- Realisasi data as JSONB containing summary and detail entries
-- Structure: {
--   nilai_total_realisasi: "Rp. 202.020.000,00",
--   nilai_pdn: "Rp. 202.020.000,00",
--   nilai_umk: "Rp. 0,00",
--   tanggal_selesai: "15 November 2023",
--   entries: [{no, jenis_realisasi, nilai_realisasi, tanggal_realisasi}]
-- }
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS realisasi JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN crawler.spse_tenders.realisasi IS 'Contract execution/realization data with summary values and milestone entries';
