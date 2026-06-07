--
-- PostgreSQL database dump
--


-- Dumped from database version 17.10 (Debian 17.10-1.pgdg12+1)
-- Dumped by pg_dump version 17.10 (Debian 17.10-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: crawler; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA crawler;


--
-- Name: SCHEMA crawler; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA crawler IS 'L1 (Bronze): Raw scraped data from external sources. Upsert on natural keys, no cross-source normalization.';


--
-- Name: failure_class; Type: TYPE; Schema: crawler; Owner: -
--

CREATE TYPE crawler.failure_class AS ENUM (
    'site_down',
    'layout_changed',
    'rate_limited',
    'timeout',
    'browser_crashed',
    'data_quality',
    'unknown'
);


--
-- Name: job_status; Type: TYPE; Schema: crawler; Owner: -
--

CREATE TYPE crawler.job_status AS ENUM (
    'queued',
    'running',
    'completed',
    'failed',
    'cancelled'
);


--
-- Name: schedule_interval; Type: TYPE; Schema: crawler; Owner: -
--

CREATE TYPE crawler.schedule_interval AS ENUM (
    'daily',
    'weekly',
    'fortnightly',
    'monthly'
);


--
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: crawler; Owner: -
--

CREATE FUNCTION crawler.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: crawler; Owner: -
--

CREATE FUNCTION crawler.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: adb_sanctions; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.adb_sanctions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    adb_id text NOT NULL,
    name text NOT NULL,
    address text,
    sanction_type text NOT NULL,
    other_name text,
    nationality text,
    effective_date date,
    lapse_date date,
    is_active boolean DEFAULT true NOT NULL,
    grounds text,
    entity_type text,
    changes_made_on date,
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    last_seen_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT adb_sanctions_adb_id_format CHECK ((adb_id ~ '^[a-fA-F0-9]{24}$'::text)),
    CONSTRAINT adb_sanctions_entity_type_check CHECK ((entity_type = ANY (ARRAY['company'::text, 'person'::text])))
);


--
-- Name: TABLE adb_sanctions; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.adb_sanctions IS 'Asian Development Bank sanctions list - debarred entities (firms and individuals)';


--
-- Name: alembic_version; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: bpk_regulations; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.bpk_regulations (
    id integer NOT NULL,
    regulation_id character varying(50) NOT NULL,
    slug character varying(255) NOT NULL,
    judul text NOT NULL,
    judul_lengkap text,
    nomor character varying(50),
    tahun character varying(50),
    bentuk character varying(150),
    bentuk_singkat character varying(50),
    tipe_dokumen character varying(100),
    teu text,
    subjek text,
    status character varying(50),
    tanggal_penetapan date,
    tanggal_pengundangan date,
    tanggal_berlaku date,
    tempat_penetapan character varying(100),
    sumber text,
    lokasi character varying(100),
    bidang text,
    bahasa character varying(50),
    metadata jsonb DEFAULT '{}'::jsonb,
    pdf_files jsonb DEFAULT '[]'::jsonb,
    relations jsonb DEFAULT '{}'::jsonb,
    uji_materi jsonb DEFAULT '[]'::jsonb,
    source_url text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    keywords text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT ck_regulation_id_format CHECK (((regulation_id)::text ~ '^[a-zA-Z0-9_-]+$'::text))
);


--
-- Name: bpk_regulations_id_seq; Type: SEQUENCE; Schema: crawler; Owner: -
--

CREATE SEQUENCE crawler.bpk_regulations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bpk_regulations_id_seq; Type: SEQUENCE OWNED BY; Schema: crawler; Owner: -
--

ALTER SEQUENCE crawler.bpk_regulations_id_seq OWNED BY crawler.bpk_regulations.id;


--
-- Name: crawler_jobs; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.crawler_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    crawler_type character varying(50) NOT NULL,
    params jsonb NOT NULL,
    status crawler.job_status DEFAULT 'queued'::crawler.job_status NOT NULL,
    error text,
    pages_crawled integer DEFAULT 0 NOT NULL,
    items_extracted integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    recent_logs jsonb DEFAULT '[]'::jsonb NOT NULL,
    last_completed_page integer,
    schedule_id uuid,
    resumed_from_job_id uuid,
    failure_class crawler.failure_class,
    stop_requested boolean DEFAULT false NOT NULL,
    stop_reason text,
    stopped_at timestamp with time zone,
    CONSTRAINT crawler_jobs_last_completed_page_check CHECK (((last_completed_page IS NULL) OR (last_completed_page >= 0))),
    CONSTRAINT crawler_jobs_stop_reason_check CHECK (((stop_reason IS NULL) OR (stop_reason = ANY (ARRAY['user_stop'::text, 'force_stop'::text]))))
);


--
-- Name: COLUMN crawler_jobs.recent_logs; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.crawler_jobs.recent_logs IS 'Circular buffer of last 100 log entries for this job';


--
-- Name: COLUMN crawler_jobs.last_completed_page; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.crawler_jobs.last_completed_page IS 'Last successfully completed page (1-indexed). NULL means start fresh.';


--
-- Name: COLUMN crawler_jobs.resumed_from_job_id; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.crawler_jobs.resumed_from_job_id IS 'References the original job this was resumed from. NULL for fresh jobs.';


--
-- Name: crawler_settings; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.crawler_settings (
    key text NOT NULL,
    value jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by text
);


--
-- Name: TABLE crawler_settings; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.crawler_settings IS 'Runtime-eligible global crawler settings overlaid on environment defaults.';


--
-- Name: crawler_type_overrides; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.crawler_type_overrides (
    crawler_type character varying(50) NOT NULL,
    overrides jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by text,
    CONSTRAINT crawler_type_overrides_overrides_object CHECK ((jsonb_typeof(overrides) = 'object'::text))
);


--
-- Name: TABLE crawler_type_overrides; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.crawler_type_overrides IS 'Per-crawler default request parameters and enabled flags for runtime job submission.';


--
-- Name: eu_most_wanted_fugitives; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.eu_most_wanted_fugitives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    node_id text NOT NULL,
    full_name text NOT NULL,
    url_slug text NOT NULL,
    status text DEFAULT 'Wanted'::text NOT NULL,
    wanted_by_country text NOT NULL,
    crimes text[] DEFAULT '{}'::text[],
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    image_path text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: health_checks; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.health_checks (
    crawler_type character varying(50) NOT NULL,
    passed boolean DEFAULT true NOT NULL,
    consecutive_failures integer DEFAULT 0 NOT NULL,
    last_checked_at timestamp with time zone,
    next_check_at timestamp with time zone,
    last_error text,
    failed_selectors jsonb,
    duration_ms integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE health_checks; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.health_checks IS 'Health check state per crawler type. One row per crawler, seeded at migration time.';


--
-- Name: interpol_red_notices; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.interpol_red_notices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id text NOT NULL,
    family_name text NOT NULL,
    forename text,
    nationality text[] DEFAULT '{}'::text[],
    wanted_by_country text NOT NULL,
    raw_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    image_path text
);


--
-- Name: TABLE interpol_red_notices; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.interpol_red_notices IS 'Interpol Red Notice data - international wanted persons alerts';


--
-- Name: COLUMN interpol_red_notices.entity_id; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.interpol_red_notices.entity_id IS 'Interpol notice ID (e.g., 2025-96936)';


--
-- Name: COLUMN interpol_red_notices.raw_data; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.interpol_red_notices.raw_data IS 'Complete API response including optional fields';


--
-- Name: COLUMN interpol_red_notices.image_path; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.interpol_red_notices.image_path IS 'Garage object storage path for notice photo (e.g., interpol/2025-96936.jpg)';


--
-- Name: lkpp_blacklist_entries; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.lkpp_blacklist_entries (
    id text NOT NULL,
    sk_number text NOT NULL,
    provider_name text NOT NULL,
    provider_npwp text,
    provider_address text,
    status text NOT NULL,
    start_date timestamp with time zone,
    expired_date timestamp with time zone,
    publish_date timestamp with time zone,
    tender jsonb,
    violation jsonb,
    correspondence jsonb,
    document jsonb,
    raw_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE lkpp_blacklist_entries; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.lkpp_blacklist_entries IS 'LKPP Daftar Hitam (blacklisted vendors) from https://daftar-hitam.inaproc.id/';


--
-- Name: COLUMN lkpp_blacklist_entries.sk_number; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.lkpp_blacklist_entries.sk_number IS 'Surat Keputusan (decree) number';


--
-- Name: COLUMN lkpp_blacklist_entries.provider_npwp; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.lkpp_blacklist_entries.provider_npwp IS 'NPWP (masked in source data)';


--
-- Name: COLUMN lkpp_blacklist_entries.tender; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.lkpp_blacklist_entries.tender IS 'Related tender info (id, name, pagu, hps, category, budgetYear)';


--
-- Name: COLUMN lkpp_blacklist_entries.violation; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.lkpp_blacklist_entries.violation IS 'Violation details (id, name, description, month, year)';


--
-- Name: COLUMN lkpp_blacklist_entries.correspondence; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON COLUMN crawler.lkpp_blacklist_entries.correspondence IS 'Reporting agencies (lpse, kldi, satker)';


--
-- Name: lpse_sites; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.lpse_sites (
    code text NOT NULL,
    name text NOT NULL,
    base_url text NOT NULL,
    province text,
    email text,
    lpse_type text,
    status text,
    is_online boolean,
    standardisasi text,
    pegawai text,
    kegiatan text,
    spse_version text,
    source_updated_at text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE lpse_sites; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.lpse_sites IS 'LPSE site directory from eproc.lkpp.go.id; refreshed by scripts/scrape_lpse_sites.py.';


--
-- Name: mahkamah_agung_putusans; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.mahkamah_agung_putusans (
    id integer NOT NULL,
    putusan_id character varying(64) NOT NULL,
    nomor character varying(100) NOT NULL,
    tingkat_proses character varying(50),
    klasifikasi text[] DEFAULT '{}'::text[],
    kata_kunci text[] DEFAULT '{}'::text[],
    tahun character varying(10),
    lembaga_peradilan text,
    jenis_lembaga_peradilan character varying(20),
    tanggal_register date,
    tanggal_musyawarah date,
    tanggal_dibacakan date,
    hakim_ketua text,
    hakim_anggota text[] DEFAULT '{}'::text[],
    panitera text,
    amar text,
    amar_lainnya text,
    catatan_amar text,
    status character varying(100),
    kaidah text,
    abstrak text,
    pdf_url text,
    pdf_storage_path text,
    related_cases jsonb DEFAULT '{}'::jsonb,
    source_url text NOT NULL,
    raw_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT ck_ma_putusans_date_ordering CHECK ((((tanggal_register IS NULL) OR (tanggal_musyawarah IS NULL) OR (tanggal_register <= tanggal_musyawarah)) AND ((tanggal_musyawarah IS NULL) OR (tanggal_dibacakan IS NULL) OR (tanggal_musyawarah <= tanggal_dibacakan)))),
    CONSTRAINT ck_ma_putusans_pdf_consistency CHECK (((pdf_storage_path IS NULL) OR ((pdf_storage_path IS NOT NULL) AND (pdf_url IS NOT NULL)))),
    CONSTRAINT ck_putusan_id_format CHECK (((putusan_id)::text ~ '^[a-z0-9]{32,}$'::text))
);


--
-- Name: mahkamah_agung_putusans_id_seq; Type: SEQUENCE; Schema: crawler; Owner: -
--

CREATE SEQUENCE crawler.mahkamah_agung_putusans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mahkamah_agung_putusans_id_seq; Type: SEQUENCE OWNED BY; Schema: crawler; Owner: -
--

ALTER SEQUENCE crawler.mahkamah_agung_putusans_id_seq OWNED BY crawler.mahkamah_agung_putusans.id;


--
-- Name: mcp_action_previews; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.mcp_action_previews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    token_hash text NOT NULL,
    client_id text NOT NULL,
    operator_ref text,
    original_text text NOT NULL,
    action_kind text NOT NULL,
    actions jsonb NOT NULL,
    summary jsonb DEFAULT '{}'::jsonb NOT NULL,
    parser_provider text,
    parser_model text,
    confidence numeric,
    validation_result jsonb DEFAULT '{}'::jsonb NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    consumed_by text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mcp_action_previews_action_kind_check CHECK ((action_kind = ANY (ARRAY['crawl'::text, 'schedule'::text]))),
    CONSTRAINT mcp_action_previews_actions_array_check CHECK ((jsonb_typeof(actions) = 'array'::text)),
    CONSTRAINT mcp_action_previews_confidence_range_check CHECK (((confidence IS NULL) OR ((confidence >= (0)::numeric) AND (confidence <= (1)::numeric)))),
    CONSTRAINT mcp_action_previews_consumed_by_requires_consumed_at_check CHECK (((consumed_by IS NULL) OR (consumed_at IS NOT NULL))),
    CONSTRAINT mcp_action_previews_summary_object_check CHECK ((jsonb_typeof(summary) = 'object'::text)),
    CONSTRAINT mcp_action_previews_validation_result_object_check CHECK ((jsonb_typeof(validation_result) = 'object'::text))
);


--
-- Name: mcp_audit_events; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.mcp_audit_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    preview_id uuid,
    event_type text NOT NULL,
    client_id text NOT NULL,
    operator_ref text,
    original_text text,
    parser_provider text,
    parser_model text,
    llm_output jsonb DEFAULT '{}'::jsonb NOT NULL,
    deterministic_result jsonb DEFAULT '{}'::jsonb NOT NULL,
    submitted_results jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mcp_audit_events_deterministic_result_object_check CHECK ((jsonb_typeof(deterministic_result) = 'object'::text)),
    CONSTRAINT mcp_audit_events_event_type_check CHECK ((event_type = ANY (ARRAY['parse'::text, 'preview'::text, 'auto_submit'::text, 'confirm'::text, 'reject'::text, 'ambiguous'::text, 'failed'::text]))),
    CONSTRAINT mcp_audit_events_llm_output_object_check CHECK ((jsonb_typeof(llm_output) = 'object'::text)),
    CONSTRAINT mcp_audit_events_submitted_results_array_check CHECK ((jsonb_typeof(submitted_results) = 'array'::text))
);


--
-- Name: opentender_instansi; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.opentender_instansi (
    code text NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE opentender_instansi; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.opentender_instansi IS 'OpenTender instansi master data from pro.opentender.net; refreshed by scripts/fetch_opentender_master.py.';


--
-- Name: opentender_lpse; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.opentender_lpse (
    code text NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE opentender_lpse; Type: COMMENT; Schema: crawler; Owner: -
--

COMMENT ON TABLE crawler.opentender_lpse IS 'OpenTender LPSE master data from pro.opentender.net; refreshed by scripts/fetch_opentender_master.py.';


--
-- Name: opentender_ocds_releases; Type: TABLE; Schema: crawler; Owner: -
--

CREATE TABLE crawler.opentender_ocds_releases (
    id character varying(64) NOT NULL,
    ocid text NOT NULL,
    release_id text NOT NULL,
    lpse_code character varying(10) NOT NULL,
    fiscal_year character varying(4) NOT NULL,
    buyer_name text,
    buyer_id text,
    tender_title text,
    tender_status text,
    tender_value_amount numeric(20,2),
    tender_currency character varying(3) DEFAULT 'IDR'::character varying,
    date_published timestamp with time zone,
    procurement_category text,
    release_data jsonb NOT NULL,
    source_url text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    storage_path text,
    CONSTRAINT opentender_ocds_releases_has_tender CHECK ((release_data ? 'tender'::text)),
    CONSTRAINT opentender_ocds_releases_id_check CHE

... [OUTPUT TRUNCATED - 36712 chars omitted out of 86712 total] ...

DEX idx_interpol_notices_updated_at ON crawler.interpol_red_notices USING btree (updated_at DESC);


--
-- Name: idx_interpol_notices_wanted_by; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_interpol_notices_wanted_by ON crawler.interpol_red_notices USING btree (wanted_by_country);


--
-- Name: idx_interpol_notices_wanted_nationality; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_interpol_notices_wanted_nationality ON crawler.interpol_red_notices USING btree (wanted_by_country, nationality);


--
-- Name: idx_lkpp_blacklist_active; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_lkpp_blacklist_active ON crawler.lkpp_blacklist_entries USING btree (status, expired_date DESC) WHERE (status = 'PUBLISHED'::text);


--
-- Name: idx_lkpp_blacklist_provider_name; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_lkpp_blacklist_provider_name ON crawler.lkpp_blacklist_entries USING btree (provider_name);


--
-- Name: idx_lkpp_blacklist_publish_date; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_lkpp_blacklist_publish_date ON crawler.lkpp_blacklist_entries USING btree (publish_date DESC);


--
-- Name: idx_lkpp_blacklist_status; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_lkpp_blacklist_status ON crawler.lkpp_blacklist_entries USING btree (status);


--
-- Name: idx_lpse_sites_province; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_lpse_sites_province ON crawler.lpse_sites USING btree (province);


--
-- Name: idx_lpse_sites_status; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_lpse_sites_status ON crawler.lpse_sites USING btree (status);


--
-- Name: idx_ma_putusans_hakim_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_hakim_trgm ON crawler.mahkamah_agung_putusans USING gin (hakim_ketua public.gin_trgm_ops);


--
-- Name: idx_ma_putusans_kata_kunci_gin; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_kata_kunci_gin ON crawler.mahkamah_agung_putusans USING gin (kata_kunci);


--
-- Name: idx_ma_putusans_klasifikasi_gin; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_klasifikasi_gin ON crawler.mahkamah_agung_putusans USING gin (klasifikasi);


--
-- Name: idx_ma_putusans_lembaga_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_lembaga_trgm ON crawler.mahkamah_agung_putusans USING gin (lembaga_peradilan public.gin_trgm_ops);


--
-- Name: idx_ma_putusans_nomor; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_nomor ON crawler.mahkamah_agung_putusans USING btree (nomor);


--
-- Name: idx_ma_putusans_nomor_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_nomor_trgm ON crawler.mahkamah_agung_putusans USING gin (nomor public.gin_trgm_ops);


--
-- Name: idx_ma_putusans_tahun; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_tahun ON crawler.mahkamah_agung_putusans USING btree (tahun);


--
-- Name: idx_ma_putusans_tanggal_dibacakan; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_tanggal_dibacakan ON crawler.mahkamah_agung_putusans USING btree (tanggal_dibacakan);


--
-- Name: idx_ma_putusans_tingkat_proses; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_tingkat_proses ON crawler.mahkamah_agung_putusans USING btree (tingkat_proses);


--
-- Name: idx_ma_putusans_tingkat_tahun; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ma_putusans_tingkat_tahun ON crawler.mahkamah_agung_putusans USING btree (tingkat_proses, tahun);


--
-- Name: idx_mcp_action_previews_client_created; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_mcp_action_previews_client_created ON crawler.mcp_action_previews USING btree (client_id, created_at DESC);


--
-- Name: idx_mcp_action_previews_expires_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_mcp_action_previews_expires_at ON crawler.mcp_action_previews USING btree (expires_at) WHERE (consumed_at IS NULL);


--
-- Name: idx_mcp_audit_events_client_created; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_mcp_audit_events_client_created ON crawler.mcp_audit_events USING btree (client_id, created_at DESC);


--
-- Name: idx_mcp_audit_events_event_created; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_mcp_audit_events_event_created ON crawler.mcp_audit_events USING btree (event_type, created_at DESC);


--
-- Name: idx_mcp_audit_events_preview_created; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_mcp_audit_events_preview_created ON crawler.mcp_audit_events USING btree (preview_id, created_at DESC);


--
-- Name: idx_opentender_category; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_category ON crawler.opentender_tenders USING btree (((metadata ->> 'category_label'::text))) WHERE ((metadata ->> 'category_label'::text) IS NOT NULL);


--
-- Name: idx_opentender_created_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_created_at ON crawler.opentender_tenders USING btree (created_at DESC);


--
-- Name: idx_opentender_fiscal_year; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_fiscal_year ON crawler.opentender_tenders USING btree (((metadata ->> 'fiscal_year'::text))) WHERE ((metadata ->> 'fiscal_year'::text) IS NOT NULL);


--
-- Name: idx_opentender_instansi_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_instansi_type ON crawler.opentender_instansi USING btree (type);


--
-- Name: idx_opentender_lpse_code; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_lpse_code ON crawler.opentender_tenders USING btree (lpse_code);


--
-- Name: idx_opentender_ocds_releases_buyer_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_ocds_releases_buyer_trgm ON crawler.opentender_ocds_releases USING gin (buyer_name public.gin_trgm_ops) WHERE (buyer_name IS NOT NULL);


--
-- Name: idx_opentender_ocds_releases_created_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_ocds_releases_created_at ON crawler.opentender_ocds_releases USING btree (created_at DESC);


--
-- Name: idx_opentender_ocds_releases_data; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_ocds_releases_data ON crawler.opentender_ocds_releases USING gin (release_data jsonb_path_ops);


--
-- Name: idx_opentender_ocds_releases_has_storage; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_ocds_releases_has_storage ON crawler.opentender_ocds_releases USING btree (((storage_path IS NOT NULL))) WHERE (storage_path IS NOT NULL);


--
-- Name: idx_opentender_ocds_releases_lpse_year; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_ocds_releases_lpse_year ON crawler.opentender_ocds_releases USING btree (lpse_code, fiscal_year);


--
-- Name: idx_opentender_ocds_releases_ocid; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_ocds_releases_ocid ON crawler.opentender_ocds_releases USING btree (ocid);


--
-- Name: idx_opentender_ocds_releases_status; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_ocds_releases_status ON crawler.opentender_ocds_releases USING btree (tender_status) WHERE (tender_status IS NOT NULL);


--
-- Name: idx_opentender_skpd_alt_name_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_skpd_alt_name_trgm ON crawler.opentender_skpd USING gin (alt_name public.gin_trgm_ops) WHERE (alt_name IS NOT NULL);


--
-- Name: idx_opentender_skpd_code_text; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_skpd_code_text ON crawler.opentender_skpd USING btree (((code)::text));


--
-- Name: idx_opentender_skpd_lpse_code; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_skpd_lpse_code ON crawler.opentender_skpd USING btree (lpse_code, code) WHERE (lpse_code IS NOT NULL);


--
-- Name: idx_opentender_skpd_lpse_name_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_skpd_lpse_name_trgm ON crawler.opentender_skpd USING gin (lpse_name public.gin_trgm_ops) WHERE (lpse_name IS NOT NULL);


--
-- Name: idx_opentender_skpd_name_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_opentender_skpd_name_trgm ON crawler.opentender_skpd USING gin (name public.gin_trgm_ops);


--
-- Name: idx_ppatk_dttot_densus_code; Type: INDEX; Schema: crawler; Owner: -
--

CREATE UNIQUE INDEX idx_ppatk_dttot_densus_code ON crawler.ppatk_dttot USING btree (densus_code);


--
-- Name: idx_ppatk_dttot_entity_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_ppatk_dttot_entity_type ON crawler.ppatk_dttot USING btree (entity_type);


--
-- Name: idx_recurring_schedules_due; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_recurring_schedules_due ON crawler.recurring_schedules USING btree (next_scheduled_at) WHERE ((status)::text = 'active'::text);


--
-- Name: idx_sc_aob_sanctions_auditor; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sc_aob_sanctions_auditor ON crawler.sc_aob_sanctions USING btree (auditor);


--
-- Name: idx_sc_aob_sanctions_auditor_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sc_aob_sanctions_auditor_trgm ON crawler.sc_aob_sanctions USING gin (auditor public.gin_trgm_ops);


--
-- Name: idx_sc_aob_sanctions_natural_key; Type: INDEX; Schema: crawler; Owner: -
--

CREATE UNIQUE INDEX idx_sc_aob_sanctions_natural_key ON crawler.sc_aob_sanctions USING btree (year, entry_number);


--
-- Name: idx_sc_aob_sanctions_year; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sc_aob_sanctions_year ON crawler.sc_aob_sanctions USING btree (year DESC);


--
-- Name: idx_sc_investor_alerts_entity_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sc_investor_alerts_entity_type ON crawler.sc_investor_alerts USING btree (entity_type) WHERE (entity_type IS NOT NULL);


--
-- Name: idx_sc_investor_alerts_name_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sc_investor_alerts_name_trgm ON crawler.sc_investor_alerts USING gin (name public.gin_trgm_ops);


--
-- Name: idx_sc_investor_alerts_name_unique; Type: INDEX; Schema: crawler; Owner: -
--

CREATE UNIQUE INDEX idx_sc_investor_alerts_name_unique ON crawler.sc_investor_alerts USING btree (lower(name));


--
-- Name: idx_sg_judgments_case_title_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_judgments_case_title_trgm ON crawler.singapore_judgments USING gin (case_title public.gin_trgm_ops);


--
-- Name: idx_sg_judgments_citation_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_judgments_citation_trgm ON crawler.singapore_judgments USING gin (citation public.gin_trgm_ops);


--
-- Name: idx_sg_judgments_court_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_judgments_court_type ON crawler.singapore_judgments USING btree (court_type);


--
-- Name: idx_sg_judgments_court_type_date; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_judgments_court_type_date ON crawler.singapore_judgments USING btree (court_type, decision_date DESC NULLS LAST);


--
-- Name: idx_sg_judgments_decision_date; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_judgments_decision_date ON crawler.singapore_judgments USING btree (decision_date DESC);


--
-- Name: idx_sg_mas_action_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_mas_action_type ON crawler.sg_mas_enforcement_actions USING btree (action_type) WHERE (action_type IS NOT NULL);


--
-- Name: idx_sg_mas_issue_date; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_mas_issue_date ON crawler.sg_mas_enforcement_actions USING btree (issue_date DESC) WHERE (issue_date IS NOT NULL);


--
-- Name: idx_sg_mas_title_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sg_mas_title_trgm ON crawler.sg_mas_enforcement_actions USING gin (title public.gin_trgm_ops);


--
-- Name: idx_sirup_paket_klpd; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sirup_paket_klpd ON crawler.sirup_paket USING btree (nama_klpd);


--
-- Name: idx_sirup_paket_tahun; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sirup_paket_tahun ON crawler.sirup_paket USING btree (tahun_anggaran);


--
-- Name: idx_sirup_paket_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sirup_paket_type ON crawler.sirup_paket USING btree (package_type);


--
-- Name: idx_sprm_offenders_category; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sprm_offenders_category ON crawler.sprm_offenders USING btree (((metadata ->> 'category'::text))) WHERE ((metadata ->> 'category'::text) IS NOT NULL);


--
-- Name: idx_sprm_offenders_created_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sprm_offenders_created_at ON crawler.sprm_offenders USING btree (created_at DESC);


--
-- Name: idx_sprm_offenders_state; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sprm_offenders_state ON crawler.sprm_offenders USING btree (((metadata ->> 'state'::text))) WHERE ((metadata ->> 'state'::text) IS NOT NULL);


--
-- Name: idx_sprm_offenders_state_category_created; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_sprm_offenders_state_category_created ON crawler.sprm_offenders USING btree (((metadata ->> 'state'::text)), ((metadata ->> 'category'::text)), created_at DESC);


--
-- Name: idx_spse_tender_jadwal_gin; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tender_jadwal_gin ON crawler.spse_tenders USING gin (jadwal jsonb_path_ops) WHERE ((jadwal IS NOT NULL) AND (jadwal <> '[]'::jsonb));


--
-- Name: idx_spse_tender_jadwal_length; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tender_jadwal_length ON crawler.spse_tenders USING btree (jsonb_array_length(COALESCE(jadwal, '[]'::jsonb))) WHERE ((jadwal IS NOT NULL) AND (jadwal <> '[]'::jsonb));


--
-- Name: idx_spse_tender_pemenang_gin; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tender_pemenang_gin ON crawler.spse_tenders USING gin (pemenang_berkontrak jsonb_path_ops) WHERE ((pemenang_berkontrak IS NOT NULL) AND (pemenang_berkontrak <> '[]'::jsonb));


--
-- Name: idx_spse_tender_pemenang_length; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tender_pemenang_length ON crawler.spse_tenders USING btree (jsonb_array_length(COALESCE(pemenang_berkontrak, '[]'::jsonb))) WHERE ((pemenang_berkontrak IS NOT NULL) AND (pemenang_berkontrak <> '[]'::jsonb));


--
-- Name: idx_spse_tender_status_tahun; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tender_status_tahun ON crawler.spse_tenders USING btree (status_paket, tahun_anggaran) WHERE ((status_paket)::text = ANY ((ARRAY['Paket Dibatalkan'::character varying, 'Paket Gagal'::character varying, 'Paket Selesai'::character varying])::text[]));


--
-- Name: idx_spse_tenders_created; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_created ON crawler.spse_tenders USING btree (created_at);


--
-- Name: idx_spse_tenders_has_pdf; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_has_pdf ON crawler.spse_tenders USING btree (uraian_pdf_storage_path) WHERE (uraian_pdf_storage_path IS NOT NULL);


--
-- Name: idx_spse_tenders_instansi; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_instansi ON crawler.spse_tenders USING btree (instansi) WHERE (instansi IS NOT NULL);


--
-- Name: idx_spse_tenders_jenis_pengadaan; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_jenis_pengadaan ON crawler.spse_tenders USING btree (jenis_pengadaan) WHERE (jenis_pengadaan IS NOT NULL);


--
-- Name: idx_spse_tenders_kode_tender; Type: INDEX; Schema: crawler; Owner: -
--

CREATE UNIQUE INDEX idx_spse_tenders_kode_tender ON crawler.spse_tenders USING btree (kode_tender);


--
-- Name: idx_spse_tenders_kualifikasi_usaha; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_kualifikasi_usaha ON crawler.spse_tenders USING btree (kualifikasi_usaha) WHERE (kualifikasi_usaha IS NOT NULL);


--
-- Name: idx_spse_tenders_list; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_list ON crawler.spse_tenders USING btree (tanggal_pembuatan DESC, tahun_anggaran);


--
-- Name: idx_spse_tenders_lpse; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_lpse ON crawler.spse_tenders USING btree (lpse_code);


--
-- Name: idx_spse_tenders_lpse_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_lpse_type ON crawler.spse_tenders USING btree (lpse_code, tender_type);


--
-- Name: idx_spse_tenders_oap_khusus; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_oap_khusus ON crawler.spse_tenders USING btree (oap_khusus) WHERE (oap_khusus IS NOT NULL);


--
-- Name: idx_spse_tenders_pagu; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_pagu ON crawler.spse_tenders USING btree (nilai_pagu) WHERE (nilai_pagu IS NOT NULL);


--
-- Name: idx_spse_tenders_status_paket; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_status_paket ON crawler.spse_tenders USING btree (status_paket) WHERE (status_paket IS NOT NULL);


--
-- Name: idx_spse_tenders_tahap_saat_ini; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_tahap_saat_ini ON crawler.spse_tenders USING btree (tahap_saat_ini) WHERE (tahap_saat_ini IS NOT NULL);


--
-- Name: idx_spse_tenders_tahun; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_tahun ON crawler.spse_tenders USING btree (tahun_anggaran);


--
-- Name: idx_spse_tenders_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_type ON crawler.spse_tenders USING btree (tender_type);


--
-- Name: idx_spse_tenders_year_instansi_jenis; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_spse_tenders_year_instansi_jenis ON crawler.spse_tenders USING btree (tahun_anggaran, instansi, jenis_pengadaan);


--
-- Name: idx_uk_disq_company_name_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_uk_disq_company_name_trgm ON crawler.uk_disqualified_officers USING gin (company_name public.gin_trgm_ops) WHERE (company_name IS NOT NULL);


--
-- Name: idx_uk_disq_expired_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_uk_disq_expired_at ON crawler.uk_disqualified_officers USING btree (expired_at) WHERE (expired_at IS NOT NULL);


--
-- Name: idx_uk_disq_forename_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_uk_disq_forename_trgm ON crawler.uk_disqualified_officers USING gin (forename public.gin_trgm_ops) WHERE (forename IS NOT NULL);


--
-- Name: idx_uk_disq_latest_until; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_uk_disq_latest_until ON crawler.uk_disqualified_officers USING btree (latest_disqualified_until) WHERE (latest_disqualified_until IS NOT NULL);


--
-- Name: idx_uk_disq_nationality; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_uk_disq_nationality ON crawler.uk_disqualified_officers USING btree (nationality) WHERE (nationality IS NOT NULL);


--
-- Name: idx_uk_disq_officer_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_uk_disq_officer_type ON crawler.uk_disqualified_officers USING btree (officer_type);


--
-- Name: idx_uk_disq_surname_trgm; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_uk_disq_surname_trgm ON crawler.uk_disqualified_officers USING gin (surname public.gin_trgm_ops) WHERE (surname IS NOT NULL);


--
-- Name: idx_world_bank_debarred_country_name; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_world_bank_debarred_country_name ON crawler.world_bank_debarred USING btree (country_name) WHERE (country_name IS NOT NULL);


--
-- Name: idx_world_bank_debarred_entity_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_world_bank_debarred_entity_type ON crawler.world_bank_debarred USING btree (entity_type) WHERE (entity_type IS NOT NULL);


--
-- Name: idx_world_bank_debarred_name; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX idx_world_bank_debarred_name ON crawler.world_bank_debarred USING btree (name);


--
-- Name: idx_world_bank_debarred_supp_id; Type: INDEX; Schema: crawler; Owner: -
--

CREATE UNIQUE INDEX idx_world_bank_debarred_supp_id ON crawler.world_bank_debarred USING btree (supp_id);


--
-- Name: ix_crawler_jobs_crawler_type; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX ix_crawler_jobs_crawler_type ON crawler.crawler_jobs USING btree (crawler_type);


--
-- Name: ix_crawler_jobs_crawler_type_created_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX ix_crawler_jobs_crawler_type_created_at ON crawler.crawler_jobs USING btree (crawler_type, created_at DESC);


--
-- Name: ix_crawler_jobs_created_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX ix_crawler_jobs_created_at ON crawler.crawler_jobs USING btree (created_at);


--
-- Name: ix_crawler_jobs_running_started_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX ix_crawler_jobs_running_started_at ON crawler.crawler_jobs USING btree (started_at) WHERE (status = 'running'::crawler.job_status);


--
-- Name: ix_crawler_jobs_status; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX ix_crawler_jobs_status ON crawler.crawler_jobs USING btree (status);


--
-- Name: ix_crawler_jobs_status_created_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX ix_crawler_jobs_status_created_at ON crawler.crawler_jobs USING btree (status, created_at);


--
-- Name: ix_crawler_jobs_updated_at; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX ix_crawler_jobs_updated_at ON crawler.crawler_jobs USING btree (updated_at);


--
-- Name: procurement_search_idx; Type: INDEX; Schema: crawler; Owner: -
--

CREATE INDEX procurement_search_idx ON crawler.spse_tenders USING bm25 (id, nama_tender, instansi, satuan_kerja) WITH (key_field=id);


--
-- Name: eu_most_wanted_fugitives set_eu_most_wanted_fugitives_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER set_eu_most_wanted_fugitives_updated_at BEFORE UPDATE ON crawler.eu_most_wanted_fugitives FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: health_checks set_health_checks_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER set_health_checks_updated_at BEFORE UPDATE ON crawler.health_checks FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: recurring_schedules set_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON crawler.recurring_schedules FOR EACH ROW EXECUTE FUNCTION crawler.trigger_set_timestamp();


--
-- Name: sirup_paket set_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON crawler.sirup_paket FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: adb_sanctions update_adb_sanctions_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_adb_sanctions_updated_at BEFORE UPDATE ON crawler.adb_sanctions FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: bpk_regulations update_bpk_regulations_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_bpk_regulations_updated_at BEFORE UPDATE ON crawler.bpk_regulations FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: crawler_jobs update_crawler_jobs_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_crawler_jobs_updated_at BEFORE UPDATE ON crawler.crawler_jobs FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: crawler_settings update_crawler_settings_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_crawler_settings_updated_at BEFORE UPDATE ON crawler.crawler_settings FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: crawler_type_overrides update_crawler_type_overrides_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_crawler_type_overrides_updated_at BEFORE UPDATE ON crawler.crawler_type_overrides FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: interpol_red_notices update_interpol_notices_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_interpol_notices_updated_at BEFORE UPDATE ON crawler.interpol_red_notices FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: lpse_sites update_lpse_sites_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_lpse_sites_updated_at BEFORE UPDATE ON crawler.lpse_sites FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: mahkamah_agung_putusans update_ma_putusans_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_ma_putusans_updated_at BEFORE UPDATE ON crawler.mahkamah_agung_putusans FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: opentender_instansi update_opentender_instansi_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_opentender_instansi_updated_at BEFORE UPDATE ON crawler.opentender_instansi FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: opentender_lpse update_opentender_lpse_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_opentender_lpse_updated_at BEFORE UPDATE ON crawler.opentender_lpse FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: opentender_ocds_releases update_opentender_ocds_releases_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_opentender_ocds_releases_updated_at BEFORE UPDATE ON crawler.opentender_ocds_releases FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: opentender_skpd update_opentender_skpd_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_opentender_skpd_updated_at BEFORE UPDATE ON crawler.opentender_skpd FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: opentender_source_fund update_opentender_source_fund_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_opentender_source_fund_updated_at BEFORE UPDATE ON crawler.opentender_source_fund FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: ppatk_dttot update_ppatk_dttot_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_ppatk_dttot_updated_at BEFORE UPDATE ON crawler.ppatk_dttot FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: sc_aob_sanctions update_sc_aob_sanctions_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_sc_aob_sanctions_updated_at BEFORE UPDATE ON crawler.sc_aob_sanctions FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: sc_investor_alerts update_sc_investor_alerts_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_sc_investor_alerts_updated_at BEFORE UPDATE ON crawler.sc_investor_alerts FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: singapore_judgments update_sg_judgments_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_sg_judgments_updated_at BEFORE UPDATE ON crawler.singapore_judgments FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: sg_mas_enforcement_actions update_sg_mas_enforcement_actions_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_sg_mas_enforcement_actions_updated_at BEFORE UPDATE ON crawler.sg_mas_enforcement_actions FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: spse_tenders update_spse_tenders_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_spse_tenders_updated_at BEFORE UPDATE ON crawler.spse_tenders FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: uk_disqualified_officers update_uk_disqualified_officers_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_uk_disqualified_officers_updated_at BEFORE UPDATE ON crawler.uk_disqualified_officers FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: world_bank_debarred update_world_bank_debarred_updated_at; Type: TRIGGER; Schema: crawler; Owner: -
--

CREATE TRIGGER update_world_bank_debarred_updated_at BEFORE UPDATE ON crawler.world_bank_debarred FOR EACH ROW EXECUTE FUNCTION crawler.update_updated_at_column();


--
-- Name: crawler_jobs crawler_jobs_resumed_from_job_id_fkey; Type: FK CONSTRAINT; Schema: crawler; Owner: -
--

ALTER TABLE ONLY crawler.crawler_jobs
    ADD CONSTRAINT crawler_jobs_resumed_from_job_id_fkey FOREIGN KEY (resumed_from_job_id) REFERENCES crawler.crawler_jobs(id);


--
-- Name: crawler_jobs crawler_jobs_schedule_id_fkey; Type: FK CONSTRAINT; Schema: crawler; Owner: -
--

ALTER TABLE ONLY crawler.crawler_jobs
    ADD CONSTRAINT crawler_jobs_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES crawler.recurring_schedules(id) ON DELETE SET NULL;


--
-- Name: recurring_schedules recurring_schedules_last_execution_job_id_fkey; Type: FK CONSTRAINT; Schema: crawler; Owner: -
--

ALTER TABLE ONLY crawler.recurring_schedules
    ADD CONSTRAINT recurring_schedules_last_execution_job_id_fkey FOREIGN KEY (last_execution_job_id) REFERENCES crawler.crawler_jobs(id);


--
-- PostgreSQL database dump complete
--