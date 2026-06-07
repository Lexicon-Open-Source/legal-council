-- Add kualifikasi (qualification) fields to spse_tenders table
-- These fields capture vendor qualification requirements from the pengumuman tab

-- Business qualification class (e.g., "Non Kecil", "Kecil", "Koperasi")
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS kualifikasi_usaha VARCHAR(50);

-- Detailed qualification requirements as JSONB
-- Structure: {
--   administrasi: [{type: "requirement"|"izin_usaha", text?: string, data?: [{jenis_izin, bidang_usaha}]}],
--   teknis: [string],
--   kbki: [{divisi, kelompok, deskripsi, tahun}]
-- }
ALTER TABLE crawler.spse_tenders
    ADD COLUMN IF NOT EXISTS syarat_kualifikasi JSONB DEFAULT '{}'::jsonb;

-- Index for filtering by business qualification class
CREATE INDEX IF NOT EXISTS idx_spse_tenders_kualifikasi_usaha
    ON crawler.spse_tenders (kualifikasi_usaha)
    WHERE kualifikasi_usaha IS NOT NULL;

COMMENT ON COLUMN crawler.spse_tenders.kualifikasi_usaha IS 'Business qualification class: Non Kecil, Kecil, or Koperasi';
COMMENT ON COLUMN crawler.spse_tenders.syarat_kualifikasi IS 'Detailed qualification requirements: administrasi, teknis, and KBKI classification';
