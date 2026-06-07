-- Schema: crawler
-- Web crawlers for regulations and government procurement data

CREATE SCHEMA IF NOT EXISTS crawler;

-- Enum type for crawler job status
CREATE TYPE crawler.job_status AS ENUM ('queued', 'running', 'completed', 'failed', 'cancelled');

-- Function for auto-updating updated_at timestamp
CREATE OR REPLACE FUNCTION crawler.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;

-- Alembic Version: Migration tracking for Python Alembic
CREATE TABLE crawler.alembic_version (
    version_num VARCHAR(32) NOT NULL,
    CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num)
);

-- Crawler Jobs: Job queue for crawler tasks
CREATE TABLE crawler.crawler_jobs (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    crawler_type VARCHAR(50) NOT NULL,
    params JSONB NOT NULL,
    status crawler.job_status NOT NULL DEFAULT 'queued',
    error TEXT,
    pages_crawled INTEGER NOT NULL DEFAULT 0,
    items_extracted INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT crawler_jobs_pkey PRIMARY KEY (id)
);

CREATE INDEX ix_crawler_jobs_crawler_type ON crawler.crawler_jobs USING btree (crawler_type);
CREATE INDEX ix_crawler_jobs_status ON crawler.crawler_jobs USING btree (status);
CREATE INDEX ix_crawler_jobs_created_at ON crawler.crawler_jobs USING btree (created_at);
CREATE INDEX ix_crawler_jobs_updated_at ON crawler.crawler_jobs USING btree (updated_at);
CREATE INDEX ix_crawler_jobs_status_created_at ON crawler.crawler_jobs USING btree (status, created_at);

CREATE TRIGGER update_crawler_jobs_updated_at
    BEFORE UPDATE ON crawler.crawler_jobs
    FOR EACH ROW
    EXECUTE FUNCTION crawler.update_updated_at_column();

-- BPK Regulations: Indonesian audit board regulations
CREATE TABLE crawler.bpk_regulations (
    id SERIAL NOT NULL,
    regulation_id VARCHAR(50) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    judul TEXT NOT NULL,
    judul_lengkap TEXT,
    nomor VARCHAR(50),
    tahun VARCHAR(50),
    bentuk VARCHAR(150),
    bentuk_singkat VARCHAR(50),
    tipe_dokumen VARCHAR(100),
    teu TEXT,
    subjek TEXT,
    status VARCHAR(50),
    tanggal_penetapan DATE,
    tanggal_pengundangan DATE,
    tanggal_berlaku DATE,
    tempat_penetapan VARCHAR(100),
    sumber TEXT,
    lokasi VARCHAR(100),
    bidang TEXT,
    bahasa VARCHAR(50),
    metadata JSONB DEFAULT '{}'::jsonb,
    pdf_files JSONB DEFAULT '[]'::jsonb,
    relations JSONB DEFAULT '{}'::jsonb,
    uji_materi JSONB DEFAULT '[]'::jsonb,
    source_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    keywords TEXT[] NOT NULL DEFAULT '{}'::text[],
    CONSTRAINT bpk_regulations_pkey PRIMARY KEY (id),
    CONSTRAINT uq_bpk_regulation_id UNIQUE (regulation_id),
    CONSTRAINT ck_regulation_id_format CHECK (regulation_id ~ '^[a-zA-Z0-9_-]+$')
);

CREATE INDEX idx_bpk_regulations_tahun ON crawler.bpk_regulations USING btree (tahun);
CREATE INDEX idx_bpk_regulations_bentuk_singkat ON crawler.bpk_regulations USING btree (bentuk_singkat) WHERE (bentuk_singkat IS NOT NULL);
CREATE INDEX idx_bpk_regulations_status ON crawler.bpk_regulations USING btree (status) WHERE (status IS NOT NULL);
CREATE INDEX idx_bpk_regulations_created_at ON crawler.bpk_regulations USING btree (created_at DESC);
CREATE INDEX idx_bpk_regulations_tahun_bentuk ON crawler.bpk_regulations USING btree (tahun, bentuk_singkat) WHERE ((tahun IS NOT NULL) AND (bentuk_singkat IS NOT NULL));
CREATE INDEX idx_bpk_regulations_keywords ON crawler.bpk_regulations USING gin (keywords);
CREATE INDEX idx_bpk_regulations_judul_fts ON crawler.bpk_regulations USING gin (to_tsvector('indonesian', judul));

CREATE TRIGGER update_bpk_regulations_updated_at
    BEFORE UPDATE ON crawler.bpk_regulations
    FOR EACH ROW
    EXECUTE FUNCTION crawler.update_updated_at_column();

-- SPSE Tenders: Government procurement tender data
CREATE TABLE crawler.spse_tenders (
    id SERIAL NOT NULL,
    kode_tender VARCHAR(50) NOT NULL,
    nama_tender TEXT NOT NULL,
    tender_type VARCHAR(20) NOT NULL DEFAULT 'lelang',
    instansi TEXT,
    satuan_kerja TEXT,
    jenis_pengadaan TEXT,
    metode_pengadaan TEXT,
    tahun_anggaran TEXT,
    nilai_pagu NUMERIC(20, 2),
    nilai_hps NUMERIC(20, 2),
    jenis_kontrak TEXT,
    lokasi_pekerjaan JSONB DEFAULT '[]'::jsonb,
    tanggal_pembuatan DATE,
    tahap_saat_ini TEXT,
    peserta_count INTEGER,
    rup_codes JSONB DEFAULT '[]'::jsonb,
    peserta JSONB DEFAULT '[]'::jsonb,
    hasil_evaluasi JSONB DEFAULT '[]'::jsonb,
    pemenang JSONB DEFAULT '[]'::jsonb,
    pemenang_berkontrak JSONB DEFAULT '[]'::jsonb,
    source_url TEXT NOT NULL,
    lpse_code VARCHAR(50) NOT NULL,
    raw_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT spse_tenders_pkey PRIMARY KEY (id),
    CONSTRAINT spse_tenders_kode_tender_lpse_code_tender_type_key UNIQUE (kode_tender, lpse_code, tender_type)
);

CREATE UNIQUE INDEX idx_spse_tenders_kode_tender ON crawler.spse_tenders USING btree (kode_tender);
CREATE INDEX idx_spse_tenders_kode ON crawler.spse_tenders USING btree (kode_tender);
CREATE INDEX idx_spse_tenders_lpse ON crawler.spse_tenders USING btree (lpse_code);
CREATE INDEX idx_spse_tenders_type ON crawler.spse_tenders USING btree (tender_type);
CREATE INDEX idx_spse_tenders_lpse_type ON crawler.spse_tenders USING btree (lpse_code, tender_type);
CREATE INDEX idx_spse_tenders_tahun ON crawler.spse_tenders USING btree (tahun_anggaran);
CREATE INDEX idx_spse_tenders_created ON crawler.spse_tenders USING btree (created_at);
CREATE INDEX idx_spse_tenders_list ON crawler.spse_tenders USING btree (tanggal_pembuatan DESC, tahun_anggaran);

-- BM25 full-text search index (ParadeDB pg_search)
CREATE INDEX procurement_search_idx ON crawler.spse_tenders
    USING bm25 (id, nama_tender, instansi, satuan_kerja)
    WITH (key_field=id);

CREATE TRIGGER update_spse_tenders_updated_at
    BEFORE UPDATE ON crawler.spse_tenders
    FOR EACH ROW
    EXECUTE FUNCTION crawler.update_updated_at_column();
