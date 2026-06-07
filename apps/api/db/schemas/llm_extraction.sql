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
-- Name: llm_extraction; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA llm_extraction;


--
-- Name: SCHEMA llm_extraction; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA llm_extraction IS 'L1.5 (Enrichment): LLM extraction results. Derived from L1, validation-gated via status column (pending → extracted → summarized → completed → failed).';


--
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: llm_extraction; Owner: -
--

CREATE FUNCTION llm_extraction.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bpk_regulations; Type: TABLE; Schema: llm_extraction; Owner: -
--

CREATE TABLE llm_extraction.bpk_regulations (
    extraction_id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_id integer NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    extraction_result jsonb,
    page_count integer,
    extraction_model character varying(100),
    extraction_tokens_in integer,
    extraction_tokens_out integer,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    confidence_score real,
    text_coverage real,
    extraction_version integer DEFAULT 1,
    detection_method character varying(20),
    pdf_quality character varying(20)
);


--
-- Name: COLUMN bpk_regulations.extraction_version; Type: COMMENT; Schema: llm_extraction; Owner: -
--

COMMENT ON COLUMN llm_extraction.bpk_regulations.extraction_version IS '1 = v1 (LLM-only), 2 = v2 (regex-first + LLM fallback)';


--
-- Name: COLUMN bpk_regulations.detection_method; Type: COMMENT; Schema: llm_extraction; Owner: -
--

COMMENT ON COLUMN llm_extraction.bpk_regulations.detection_method IS 'regex = deterministic section detection, llm_phase1 = LLM-based outline';


--
-- Name: COLUMN bpk_regulations.pdf_quality; Type: COMMENT; Schema: llm_extraction; Owner: -
--

COMMENT ON COLUMN llm_extraction.bpk_regulations.pdf_quality IS 'born_digital = regex extraction, scanned_clean = LLM with OCR, image_only = LLM only';


--
-- Name: extraction_review_items; Type: TABLE; Schema: llm_extraction; Owner: -
--

CREATE TABLE llm_extraction.extraction_review_items (
    review_item_id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_id uuid NOT NULL,
    document_type text NOT NULL,
    source_table text NOT NULL,
    source_id text NOT NULL,
    unit_id text,
    legal_path text,
    page_start integer,
    page_end integer,
    severity text NOT NULL,
    category text NOT NULL,
    review_status text NOT NULL,
    finding jsonb NOT NULL,
    resolution jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: extraction_runs; Type: TABLE; Schema: llm_extraction; Owner: -
--

CREATE TABLE llm_extraction.extraction_runs (
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    document_type text NOT NULL,
    source_table text NOT NULL,
    source_id text NOT NULL,
    final_extraction_table text,
    final_extraction_id uuid,
    pdf_sha256 text NOT NULL,
    pdf_byte_size bigint,
    page_count integer,
    storage_path text,
    quality_class text NOT NULL,
    intake_status text NOT NULL,
    workflow_version text NOT NULL,
    schema_version text NOT NULL,
    run_status text NOT NULL,
    error_code text,
    error_message text,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: extraction_stage_artifacts; Type: TABLE; Schema: llm_extraction; Owner: -
--

CREATE TABLE llm_extraction.extraction_stage_artifacts (
    artifact_id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_id uuid NOT NULL,
    document_type text NOT NULL,
    source_table text NOT NULL,
    source_id text NOT NULL,
    pdf_sha256 text NOT NULL,
    stage_name text NOT NULL,
    stage_status text NOT NULL,
    stage_version text NOT NULL,
    schema_version text NOT NULL,
    prompt_version text DEFAULT ''::text NOT NULL,
    model_name text DEFAULT ''::text NOT NULL,
    attempt_number integer NOT NULL,
    artifact_hash text NOT NULL,
    artifact_summary jsonb NOT NULL,
    artifact_payload jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: mahkamah_agung_putusans; Type: TABLE; Schema: llm_extraction; Owner: -
--

CREATE TABLE llm_extraction.mahkamah_agung_putusans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    extraction_id character varying(64) NOT NULL,
    extraction_result jsonb,
    summary_id text,
    summary_en text,
    extraction_confidence double precision,
    content_embedding public.vector(768),
    summary_embedding_id public.vector(768),
    summary_embedding_en public.vector(768),
    embedding_generated boolean DEFAULT false NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mahkamah_agung_putusans_extraction_confidence_check CHECK (((extraction_confidence >= (0.0)::double precision) AND (extraction_confidence <= (1.0)::double precision))),
    CONSTRAINT mahkamah_agung_putusans_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'extracted'::character varying, 'summarized'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: parser_feedback; Type: TABLE; Schema: llm_extraction; Owner: -
--

CREATE TABLE llm_extraction.parser_feedback (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_id integer NOT NULL,
    feedback_type text NOT NULL,
    field_path text,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    parser_version text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE parser_feedback; Type: COMMENT; Schema: llm_extraction; Owner: -
--

COMMENT ON TABLE llm_extraction.parser_feedback IS 'Extraction feedback for self-improving parser loop — aggregated into GitHub Issues daily';


--
-- Name: COLUMN parser_feedback.feedback_type; Type: COMMENT; Schema: llm_extraction; Owner: -
--

COMMENT ON COLUMN llm_extraction.parser_feedback.feedback_type IS 'reconciliation_diff, validation_warning, escalation, coverage_low';


--
-- Name: COLUMN parser_feedback.field_path; Type: COMMENT; Schema: llm_extraction; Owner: -
--

COMMENT ON COLUMN llm_extraction.parser_feedback.field_path IS 'Dotted field path, e.g. batang_tubuh[3].rincian_isi[0].huruf';


--
-- Name: COLUMN parser_feedback.parser_version; Type: COMMENT; Schema: llm_extraction; Owner: -
--

COMMENT ON COLUMN llm_extraction.parser_feedback.parser_version IS 'Git SHA or extraction_version tag at time of feedback';


--
-- Name: bpk_regulations bpk_regulations_pkey; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.bpk_regulations
    ADD CONSTRAINT bpk_regulations_pkey PRIMARY KEY (extraction_id);


--
-- Name: extraction_review_items extraction_review_items_pkey; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.extraction_review_items
    ADD CONSTRAINT extraction_review_items_pkey PRIMARY KEY (review_item_id);


--
-- Name: extraction_runs extraction_runs_pkey; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.extraction_runs
    ADD CONSTRAINT extraction_runs_pkey PRIMARY KEY (run_id);


--
-- Name: extraction_stage_artifacts extraction_stage_artifacts_pkey; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.extraction_stage_artifacts
    ADD CONSTRAINT extraction_stage_artifacts_pkey PRIMARY KEY (artifact_id);


--
-- Name: mahkamah_agung_putusans mahkamah_agung_putusans_extraction_id_key; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.mahkamah_agung_putusans
    ADD CONSTRAINT mahkamah_agung_putusans_extraction_id_key UNIQUE (extraction_id);


--
-- Name: mahkamah_agung_putusans mahkamah_agung_putusans_pkey; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.mahkamah_agung_putusans
    ADD CONSTRAINT mahkamah_agung_putusans_pkey PRIMARY KEY (id);


--
-- Name: parser_feedback parser_feedback_pkey; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.parser_feedback
    ADD CONSTRAINT parser_feedback_pkey PRIMARY KEY (id);


--
-- Name: bpk_regulations uq_bpk_reg_source; Type: CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.bpk_regulations
    ADD CONSTRAINT uq_bpk_reg_source UNIQUE (source_id);


--
-- Name: extraction_review_items_category_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_review_items_category_idx ON llm_extraction.extraction_review_items USING btree (category);


--
-- Name: extraction_review_items_created_at_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_review_items_created_at_idx ON llm_extraction.extraction_review_items USING btree (created_at);


--
-- Name: extraction_review_items_review_status_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_review_items_review_status_idx ON llm_extraction.extraction_review_items USING btree (review_status);


--
-- Name: extraction_review_items_severity_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_review_items_severity_idx ON llm_extraction.extraction_review_items USING btree (severity);


--
-- Name: extraction_review_items_source_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_review_items_source_idx ON llm_extraction.extraction_review_items USING btree (document_type, source_id);


--
-- Name: extraction_runs_created_at_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_runs_created_at_idx ON llm_extraction.extraction_runs USING btree (created_at);


--
-- Name: extraction_runs_document_type_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_runs_document_type_idx ON llm_extraction.extraction_runs USING btree (document_type);


--
-- Name: extraction_runs_pdf_sha256_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_runs_pdf_sha256_idx ON llm_extraction.extraction_runs USING btree (pdf_sha256);


--
-- Name: extraction_runs_reusable_key; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE UNIQUE INDEX extraction_runs_reusable_key ON llm_extraction.extraction_runs USING btree (document_type, source_table, source_id, pdf_sha256, workflow_version, schema_version);


--
-- Name: extraction_runs_run_status_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_runs_run_status_idx ON llm_extraction.extraction_runs USING btree (run_status);


--
-- Name: extraction_runs_source_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_runs_source_idx ON llm_extraction.extraction_runs USING btree (document_type, source_table, source_id);


--
-- Name: extraction_stage_artifacts_created_at_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_stage_artifacts_created_at_idx ON llm_extraction.extraction_stage_artifacts USING btree (created_at);


--
-- Name: extraction_stage_artifacts_reusable_key; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE UNIQUE INDEX extraction_stage_artifacts_reusable_key ON llm_extraction.extraction_stage_artifacts USING btree (document_type, source_table, source_id, pdf_sha256, stage_name, stage_version, schema_version, prompt_version, model_name);


--
-- Name: extraction_stage_artifacts_run_id_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_stage_artifacts_run_id_idx ON llm_extraction.extraction_stage_artifacts USING btree (run_id);


--
-- Name: extraction_stage_artifacts_source_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_stage_artifacts_source_idx ON llm_extraction.extraction_stage_artifacts USING btree (document_type, source_id);


--
-- Name: extraction_stage_artifacts_stage_name_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_stage_artifacts_stage_name_idx ON llm_extraction.extraction_stage_artifacts USING btree (stage_name);


--
-- Name: extraction_stage_artifacts_stage_status_idx; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX extraction_stage_artifacts_stage_status_idx ON llm_extraction.extraction_stage_artifacts USING btree (stage_status);


--
-- Name: idx_bpk_reg_status; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_bpk_reg_status ON llm_extraction.bpk_regulations USING btree (status);


--
-- Name: idx_llm_ext_ma_content_hnsw; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_llm_ext_ma_content_hnsw ON llm_extraction.mahkamah_agung_putusans USING hnsw (content_embedding public.vector_cosine_ops) WHERE (content_embedding IS NOT NULL);


--
-- Name: idx_llm_ext_ma_created_at; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_llm_ext_ma_created_at ON llm_extraction.mahkamah_agung_putusans USING btree (created_at);


--
-- Name: idx_llm_ext_ma_result_gin; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_llm_ext_ma_result_gin ON llm_extraction.mahkamah_agung_putusans USING gin (extraction_result);


--
-- Name: idx_llm_ext_ma_status; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_llm_ext_ma_status ON llm_extraction.mahkamah_agung_putusans USING btree (status);


--
-- Name: idx_llm_ext_ma_summary_en_hnsw; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_llm_ext_ma_summary_en_hnsw ON llm_extraction.mahkamah_agung_putusans USING hnsw (summary_embedding_en public.vector_cosine_ops) WHERE (summary_embedding_en IS NOT NULL);


--
-- Name: idx_llm_ext_ma_summary_id_hnsw; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_llm_ext_ma_summary_id_hnsw ON llm_extraction.mahkamah_agung_putusans USING hnsw (summary_embedding_id public.vector_cosine_ops) WHERE (summary_embedding_id IS NOT NULL);


--
-- Name: idx_parser_feedback_created_at; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_parser_feedback_created_at ON llm_extraction.parser_feedback USING btree (created_at);


--
-- Name: idx_parser_feedback_type; Type: INDEX; Schema: llm_extraction; Owner: -
--

CREATE INDEX idx_parser_feedback_type ON llm_extraction.parser_feedback USING btree (feedback_type);


--
-- Name: mahkamah_agung_putusans set_llm_ext_ma_updated_at; Type: TRIGGER; Schema: llm_extraction; Owner: -
--

CREATE TRIGGER set_llm_ext_ma_updated_at BEFORE UPDATE ON llm_extraction.mahkamah_agung_putusans FOR EACH ROW EXECUTE FUNCTION llm_extraction.trigger_set_timestamp();


--
-- Name: bpk_regulations bpk_regulations_source_id_fkey; Type: FK CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.bpk_regulations
    ADD CONSTRAINT bpk_regulations_source_id_fkey FOREIGN KEY (source_id) REFERENCES crawler.bpk_regulations(id);


--
-- Name: extraction_review_items extraction_review_items_run_id_fkey; Type: FK CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.extraction_review_items
    ADD CONSTRAINT extraction_review_items_run_id_fkey FOREIGN KEY (run_id) REFERENCES llm_extraction.extraction_runs(run_id);


--
-- Name: extraction_stage_artifacts extraction_stage_artifacts_run_id_fkey; Type: FK CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.extraction_stage_artifacts
    ADD CONSTRAINT extraction_stage_artifacts_run_id_fkey FOREIGN KEY (run_id) REFERENCES llm_extraction.extraction_runs(run_id);


--
-- Name: mahkamah_agung_putusans fk_llm_ext_ma_crawler; Type: FK CONSTRAINT; Schema: llm_extraction; Owner: -
--

ALTER TABLE ONLY llm_extraction.mahkamah_agung_putusans
    ADD CONSTRAINT fk_llm_ext_ma_crawler FOREIGN KEY (extraction_id) REFERENCES crawler.mahkamah_agung_putusans(putusan_id);


--
-- PostgreSQL database dump complete
--