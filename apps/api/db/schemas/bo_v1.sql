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
-- Name: bo_v1; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bo_v1;


--
-- Name: SCHEMA bo_v1; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA bo_v1 IS 'DEPRECATED: Migrating to app schema. Contains users, cases, auth tokens. Will be dropped after Go backend migration.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cases; Type: TABLE; Schema: bo_v1; Owner: -
--

CREATE TABLE bo_v1.cases (
    id character varying(26) NOT NULL,
    subject character varying(255) NOT NULL,
    subject_type smallint NOT NULL,
    person_in_charge character varying(255),
    beneficial_ownership text,
    case_date date,
    decision_number text,
    source character varying(255),
    link character varying(255),
    nation character varying(255),
    punishment_start date,
    punishment_end date,
    case_type smallint,
    year character varying(4),
    summary text,
    summary_formatted text,
    summary_en text,
    summary_formatted_en text,
    status smallint DEFAULT 2,
    slug character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(26),
    updated_by character varying(26),
    deleted_by character varying(26),
    deleted_at timestamp with time zone,
    fulltext_search_index tsvector,
    extra_data jsonb,
    subject_normalized text
);


--
-- Name: draft_cases; Type: TABLE; Schema: bo_v1; Owner: -
--

CREATE TABLE bo_v1.draft_cases (
    id character(26) NOT NULL,
    subject character varying(255) NOT NULL,
    subject_type smallint NOT NULL,
    person_in_charge character varying(255),
    beneficial_ownership character varying(255),
    case_date date NOT NULL,
    decision_number text NOT NULL,
    source character varying(255) NOT NULL,
    link character varying(255) NOT NULL,
    nation character varying(255) NOT NULL,
    punishment_start date,
    punishment_end date,
    type smallint NOT NULL,
    year character varying(4) NOT NULL,
    summary text,
    summary_formatted text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    summary_en text,
    summary_formatted_en text,
    extra_data jsonb
);


--
-- Name: password_reset_tokens; Type: TABLE; Schema: bo_v1; Owner: -
--

CREATE TABLE bo_v1.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp with time zone
);


--
-- Name: personal_access_tokens; Type: TABLE; Schema: bo_v1; Owner: -
--

CREATE TABLE bo_v1.personal_access_tokens (
    id integer NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id character(26) NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone
);


--
-- Name: users; Type: TABLE; Schema: bo_v1; Owner: -
--

CREATE TABLE bo_v1.users (
    id character(26) NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    email_verified_at timestamp with time zone,
    remember_token character varying(100),
    profile_photo_path character varying(2048),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone,
    two_factor_secret text,
    two_factor_recovery_codes text,
    two_factor_confirmed_at timestamp with time zone
);


--
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- Name: draft_cases draft_cases_pkey; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.draft_cases
    ADD CONSTRAINT draft_cases_pkey PRIMARY KEY (id);


--
-- Name: draft_cases draft_cases_unique; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.draft_cases
    ADD CONSTRAINT draft_cases_unique UNIQUE (link);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_key; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_key UNIQUE (token);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_bo_v1_cases_nation_lower; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_bo_v1_cases_nation_lower ON bo_v1.cases USING btree (lower((nation)::text));


--
-- Name: idx_cases_subject_normalized; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_cases_subject_normalized ON bo_v1.cases USING gin (subject_normalized public.gin_trgm_ops) WHERE (status = 1);


--
-- Name: idx_cases_subject_normalized_btree; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_cases_subject_normalized_btree ON bo_v1.cases USING btree (lower(regexp_replace((subject)::text, '[^a-zA-Z0-9]'::text, ''::text, 'g'::text)));


--
-- Name: idx_search_filter; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_search_filter ON bo_v1.cases USING btree (subject_type, year, case_type, nation, status);


--
-- Name: idx_search_fulltext; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_search_fulltext ON bo_v1.cases USING gin (fulltext_search_index);


--
-- Name: idx_subject; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_subject ON bo_v1.draft_cases USING btree (subject);


--
-- Name: idx_subject_type; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_subject_type ON bo_v1.draft_cases USING btree (subject_type);


--
-- Name: idx_tokenable_id; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_tokenable_id ON bo_v1.personal_access_tokens USING btree (tokenable_id);


--
-- Name: idx_year; Type: INDEX; Schema: bo_v1; Owner: -
--

CREATE INDEX idx_year ON bo_v1.draft_cases USING btree (year);


--
-- Name: cases cases_fulltext_search_index_update; Type: TRIGGER; Schema: bo_v1; Owner: -
--

CREATE TRIGGER cases_fulltext_search_index_update BEFORE INSERT OR UPDATE ON bo_v1.cases FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('fulltext_search_index', 'pg_catalog.english', 'subject', 'summary');


--
-- Name: cases fk_cases_created_by; Type: FK CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.cases
    ADD CONSTRAINT fk_cases_created_by FOREIGN KEY (created_by) REFERENCES bo_v1.users(id) ON DELETE SET NULL;


--
-- Name: cases fk_cases_deleted_by; Type: FK CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.cases
    ADD CONSTRAINT fk_cases_deleted_by FOREIGN KEY (deleted_by) REFERENCES bo_v1.users(id) ON DELETE SET NULL;


--
-- Name: cases fk_cases_updated_by; Type: FK CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.cases
    ADD CONSTRAINT fk_cases_updated_by FOREIGN KEY (updated_by) REFERENCES bo_v1.users(id) ON DELETE SET NULL;


--
-- Name: personal_access_tokens fk_personal_access_tokens_user; Type: FK CONSTRAINT; Schema: bo_v1; Owner: -
--

ALTER TABLE ONLY bo_v1.personal_access_tokens
    ADD CONSTRAINT fk_personal_access_tokens_user FOREIGN KEY (tokenable_id) REFERENCES bo_v1.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--