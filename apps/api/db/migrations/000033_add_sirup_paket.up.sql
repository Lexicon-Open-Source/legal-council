-- Verify trigger function exists first
-- SELECT proname FROM pg_proc WHERE proname = 'update_updated_at_column';

CREATE TABLE crawler.sirup_paket (
    id SERIAL PRIMARY KEY,
    kode_rup TEXT NOT NULL UNIQUE,
    nama_paket TEXT NOT NULL,
    nama_klpd TEXT NOT NULL,
    satuan_kerja TEXT NOT NULL,
    tahun_anggaran INTEGER NOT NULL,
    package_type TEXT NOT NULL CHECK (package_type IN ('penyedia', 'swakelola')),

    -- Detail fields (from HTML page)
    volume_pekerjaan TEXT,
    uraian_pekerjaan TEXT,
    spesifikasi_pekerjaan TEXT,
    produk_dalam_negeri BOOLEAN DEFAULT false,
    usaha_kecil_koperasi BOOLEAN DEFAULT false,
    pra_dipa_dpa BOOLEAN DEFAULT false,
    total_pagu NUMERIC(20, 2),
    metode_pemilihan TEXT,
    tipe_swakelola TEXT,  -- Tipe 1-4 for swakelola only
    tanggal_umumkan TIMESTAMPTZ,

    -- Nested data as JSONB (keeps it simple)
    lokasi_pekerjaan JSONB DEFAULT '[]'::jsonb,
    sumber_dana JSONB DEFAULT '[]'::jsonb,
    jenis_pengadaan JSONB DEFAULT '[]'::jsonb,
    jadwal JSONB DEFAULT '{}'::jsonb,  -- pemanfaatan, pelaksanaan, pemilihan

    -- Metadata
    source_url TEXT NOT NULL,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sirup_paket_tahun ON crawler.sirup_paket(tahun_anggaran);
CREATE INDEX idx_sirup_paket_type ON crawler.sirup_paket(package_type);
CREATE INDEX idx_sirup_paket_klpd ON crawler.sirup_paket(nama_klpd);

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON crawler.sirup_paket
    FOR EACH ROW
    EXECUTE FUNCTION crawler.update_updated_at_column();

COMMENT ON TABLE crawler.sirup_paket IS 'SIRUP RUP packages from sirup.inaproc.id';
