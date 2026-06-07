-- Mahkamah Agung Putusans: Indonesian Supreme Court decisions
-- Source: https://putusan3.mahkamahagung.go.id

CREATE TABLE crawler.mahkamah_agung_putusans (
    id SERIAL PRIMARY KEY,
    putusan_id VARCHAR(64) UNIQUE NOT NULL,
    nomor VARCHAR(100) NOT NULL,

    -- Classification
    tingkat_proses VARCHAR(50),
    klasifikasi TEXT[] DEFAULT '{}',
    kata_kunci TEXT[] DEFAULT '{}',
    tahun VARCHAR(10),

    -- Court Information
    lembaga_peradilan TEXT,
    jenis_lembaga_peradilan VARCHAR(20),

    -- Dates
    tanggal_register DATE,
    tanggal_musyawarah DATE,
    tanggal_dibacakan DATE,

    -- Judges & Clerk
    hakim_ketua TEXT,
    hakim_anggota TEXT[] DEFAULT '{}',
    panitera TEXT,

    -- Verdict
    amar VARCHAR(100),
    amar_lainnya TEXT,
    catatan_amar TEXT,
    status VARCHAR(100),
    kaidah TEXT,
    abstrak TEXT,

    -- PDF attachment
    pdf_url TEXT,
    pdf_storage_path TEXT,

    -- Related cases (JSONB links, no auto-crawl)
    related_cases JSONB DEFAULT '{}',

    -- Metadata
    source_url TEXT NOT NULL,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Validation: putusan_id must be hex format (32+ chars)
    CONSTRAINT ck_putusan_id_format CHECK (putusan_id ~ '^[a-f0-9]{32,}$')
);

-- Essential indexes for common queries
CREATE INDEX idx_ma_putusans_nomor ON crawler.mahkamah_agung_putusans (nomor);
CREATE INDEX idx_ma_putusans_tahun ON crawler.mahkamah_agung_putusans (tahun);
CREATE INDEX idx_ma_putusans_tingkat_proses ON crawler.mahkamah_agung_putusans (tingkat_proses);
CREATE INDEX idx_ma_putusans_amar ON crawler.mahkamah_agung_putusans (amar);
CREATE INDEX idx_ma_putusans_tanggal_dibacakan ON crawler.mahkamah_agung_putusans (tanggal_dibacakan);

-- Update trigger
CREATE TRIGGER update_ma_putusans_updated_at
    BEFORE UPDATE ON crawler.mahkamah_agung_putusans
    FOR EACH ROW
    EXECUTE FUNCTION crawler.update_updated_at_column();
