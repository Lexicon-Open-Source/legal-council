-- Add indexes for improved tender query performance
-- These indexes optimize filters for nilai_pagu range queries and has_pdf filtering

-- Partial index for nilai_pagu range queries (only index non-null values)
-- This optimizes queries like: WHERE nilai_pagu >= X
CREATE INDEX IF NOT EXISTS idx_spse_tenders_pagu ON crawler.spse_tenders (nilai_pagu)
    WHERE nilai_pagu IS NOT NULL;

-- Partial index for has_pdf filter (only index tenders with PDFs)
-- This optimizes queries like: WHERE uraian_pdf_storage_path IS NOT NULL
CREATE INDEX IF NOT EXISTS idx_spse_tenders_has_pdf ON crawler.spse_tenders (id)
    WHERE uraian_pdf_storage_path IS NOT NULL;
