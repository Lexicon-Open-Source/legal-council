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
-- Name: council_v1; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA council_v1;


--
-- Name: SCHEMA council_v1; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA council_v1 IS 'DEPRECATED: Migrating to app schema. Contains deliberation sessions/messages. Will be dropped after Go backend migration.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: deliberation_messages; Type: TABLE; Schema: council_v1; Owner: -
--

CREATE TABLE council_v1.deliberation_messages (
    id character varying(64) NOT NULL,
    session_id character varying NOT NULL,
    sender jsonb NOT NULL,
    content text NOT NULL,
    intent character varying,
    cited_cases jsonb DEFAULT '[]'::jsonb NOT NULL,
    cited_laws jsonb DEFAULT '[]'::jsonb NOT NULL,
    sequence_number integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: deliberation_sessions; Type: TABLE; Schema: council_v1; Owner: -
--

CREATE TABLE council_v1.deliberation_sessions (
    id character varying(64) NOT NULL,
    user_id character(26),
    status character varying DEFAULT 'active'::character varying NOT NULL,
    case_input jsonb NOT NULL,
    similar_cases jsonb DEFAULT '[]'::jsonb NOT NULL,
    legal_opinion jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    concluded_at timestamp with time zone,
    current_phase character varying DEFAULT 'legacy'::character varying NOT NULL,
    phase_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    structured_summary jsonb
);


--
-- Name: deliberation_messages deliberation_messages_pkey; Type: CONSTRAINT; Schema: council_v1; Owner: -
--

ALTER TABLE ONLY council_v1.deliberation_messages
    ADD CONSTRAINT deliberation_messages_pkey PRIMARY KEY (id);


--
-- Name: deliberation_sessions deliberation_sessions_pkey; Type: CONSTRAINT; Schema: council_v1; Owner: -
--

ALTER TABLE ONLY council_v1.deliberation_sessions
    ADD CONSTRAINT deliberation_sessions_pkey PRIMARY KEY (id);


--
-- Name: idx_deliberation_messages_session_id; Type: INDEX; Schema: council_v1; Owner: -
--

CREATE INDEX idx_deliberation_messages_session_id ON council_v1.deliberation_messages USING btree (session_id);


--
-- Name: idx_deliberation_messages_session_sequence; Type: INDEX; Schema: council_v1; Owner: -
--

CREATE INDEX idx_deliberation_messages_session_sequence ON council_v1.deliberation_messages USING btree (session_id, sequence_number);


--
-- Name: idx_deliberation_sessions_created_at; Type: INDEX; Schema: council_v1; Owner: -
--

CREATE INDEX idx_deliberation_sessions_created_at ON council_v1.deliberation_sessions USING btree (created_at DESC);


--
-- Name: idx_deliberation_sessions_current_phase; Type: INDEX; Schema: council_v1; Owner: -
--

CREATE INDEX idx_deliberation_sessions_current_phase ON council_v1.deliberation_sessions USING btree (current_phase);


--
-- Name: idx_deliberation_sessions_status; Type: INDEX; Schema: council_v1; Owner: -
--

CREATE INDEX idx_deliberation_sessions_status ON council_v1.deliberation_sessions USING btree (status);


--
-- Name: idx_deliberation_sessions_user_id; Type: INDEX; Schema: council_v1; Owner: -
--

CREATE INDEX idx_deliberation_sessions_user_id ON council_v1.deliberation_sessions USING btree (user_id);


--
-- Name: deliberation_messages deliberation_messages_session_id_fkey; Type: FK CONSTRAINT; Schema: council_v1; Owner: -
--

ALTER TABLE ONLY council_v1.deliberation_messages
    ADD CONSTRAINT deliberation_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES council_v1.deliberation_sessions(id) ON DELETE CASCADE;


--
-- Name: deliberation_sessions fk_deliberation_sessions_user; Type: FK CONSTRAINT; Schema: council_v1; Owner: -
--

ALTER TABLE ONLY council_v1.deliberation_sessions
    ADD CONSTRAINT fk_deliberation_sessions_user FOREIGN KEY (user_id) REFERENCES bo_v1.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--