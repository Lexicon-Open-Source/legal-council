-- Add jadwal and PDF columns to spse_tenders table

-- Uraian Singkat Pekerjaan PDF URL (from pengumuman page)
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS uraian_pdf_url TEXT;

-- Cloud storage path for uploaded PDF
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS uraian_pdf_storage_path TEXT;

-- Schedule data with history (from /jadwal page)
-- Structure: [{no, tahap, mulai, sampai, perubahan_count, history: [{no, tanggal_edit, original_mulai, original_sampai, keterangan}]}]
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS jadwal JSONB DEFAULT '[]'::jsonb;

-- Index for querying tenders with PDFs
CREATE INDEX IF NOT EXISTS idx_spse_tenders_has_pdf
    ON crawler.spse_tenders (uraian_pdf_storage_path)
    WHERE uraian_pdf_storage_path IS NOT NULL;

COMMENT ON COLUMN crawler.spse_tenders.uraian_pdf_url IS 'Source URL of the Uraian Singkat Pekerjaan PDF';
COMMENT ON COLUMN crawler.spse_tenders.uraian_pdf_storage_path IS 'Cloud storage path (GCS/Garage) of uploaded PDF';
COMMENT ON COLUMN crawler.spse_tenders.jadwal IS 'Schedule stages with history as JSONB array';
