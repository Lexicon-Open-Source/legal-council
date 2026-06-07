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
-- Name: app; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA app;


--
-- Name: SCHEMA app; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA app IS 'App: User-generated state. Cases, deliberations. Auth handled by Authentik (OIDC). Replaces bo_v1 + council_v1.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: api_clients; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.api_clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT api_clients_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'disabled'::text])))
);


--
-- Name: api_keys; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.api_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    key_prefix text NOT NULL,
    key_hash text NOT NULL,
    key_scope text[] DEFAULT '{}'::text[] NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT api_keys_status_check CHECK ((status = ANY (ARRAY['active'::text, 'revoked'::text, 'expired'::text])))
);


--
-- Name: api_quotas; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.api_quotas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    scope text NOT NULL,
    quota_limit bigint NOT NULL,
    window_start timestamp with time zone NOT NULL,
    window_end timestamp with time zone NOT NULL,
    used bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: api_usage_logs; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.api_usage_logs (
    id bigint NOT NULL,
    client_id uuid NOT NULL,
    key_id uuid NOT NULL,
    endpoint text NOT NULL,
    method text NOT NULL,
    status_code integer NOT NULL,
    latency_ms integer NOT NULL,
    billable boolean DEFAULT true NOT NULL,
    request_id text,
    logged_at timestamp with time zone DEFAULT now() NOT NULL
)
PARTITION BY RANGE (logged_at);


--
-- Name: api_usage_logs_id_seq; Type: SEQUENCE; Schema: app; Owner: -
--

CREATE SEQUENCE app.api_usage_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_usage_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: -
--

ALTER SEQUENCE app.api_usage_logs_id_seq OWNED BY app.api_usage_logs.id;


--
-- Name: api_usage_logs_202606; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.api_usage_logs_202606 (
    id bigint DEFAULT nextval('app.api_usage_logs_id_seq'::regclass) NOT NULL,
    client_id uuid NOT NULL,
    key_id uuid NOT NULL,
    endpoint text NOT NULL,
    method text NOT NULL,
    status_code integer NOT NULL,
    latency_ms integer NOT NULL,
    billable boolean DEFAULT true NOT NULL,
    request_id text,
    logged_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cases; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.cases (
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
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by text,
    updated_by text,
    deleted_by text,
    deleted_at timestamp with time zone,
    extra_data jsonb,
    subject_normalized text
);


--
-- Name: TABLE cases; Type: COMMENT; Schema: app; Owner: -
--

COMMENT ON TABLE app.cases IS 'Cases migrated from bo_v1.cases. Primary user-facing content table. Auth columns (created_by, updated_by, deleted_by) are TEXT — old ULIDs preserved, new writes use Authentik subject IDs.';


--
-- Name: deliberation_messages; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.deliberation_messages (
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
-- Name: TABLE deliberation_messages; Type: COMMENT; Schema: app; Owner: -
--

COMMENT ON TABLE app.deliberation_messages IS 'Messages within deliberation sessions. Migrated from council_v1.deliberation_messages.';


--
-- Name: deliberation_sessions; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.deliberation_sessions (
    id character varying(64) NOT NULL,
    user_id text,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    case_input jsonb NOT NULL,
    similar_cases jsonb DEFAULT '[]'::jsonb NOT NULL,
    legal_opinion jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    concluded_at timestamp with time zone
);


--
-- Name: TABLE deliberation_sessions; Type: COMMENT; Schema: app; Owner: -
--

COMMENT ON TABLE app.deliberation_sessions IS 'AI-assisted deliberation sessions. Migrated from council_v1.deliberation_sessions. user_id is TEXT (Authentik subject or legacy ULID).';


--
-- Name: draft_cases; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.draft_cases (
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
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    summary_en text,
    summary_formatted_en text,
    extra_data jsonb
);


--
-- Name: TABLE draft_cases; Type: COMMENT; Schema: app; Owner: -
--

COMMENT ON TABLE app.draft_cases IS 'Draft cases pending review/approval. Migrated from bo_v1.draft_cases.';


--
-- Name: user_profiles; Type: TABLE; Schema: app; Owner: -
--

CREATE TABLE app.user_profiles (
    authentik_sub text NOT NULL,
    display_name text,
    preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE user_profiles; Type: COMMENT; Schema: app; Owner: -
--

COMMENT ON TABLE app.user_profiles IS 'App-specific user data keyed by Authentik subject ID. Auth (name, email, password, 2FA) lives in Authentik. This stores preferences and display settings only.';


--
-- Name: api_usage_logs_202606; Type: TABLE ATTACH; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_usage_logs ATTACH PARTITION app.api_usage_logs_202606 FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');


--
-- Name: api_usage_logs id; Type: DEFAULT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_usage_logs ALTER COLUMN id SET DEFAULT nextval('app.api_usage_logs_id_seq'::regclass);


--
-- Name: api_clients api_clients_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_clients
    ADD CONSTRAINT api_clients_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: api_quotas api_quotas_client_scope_window_unique; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_quotas
    ADD CONSTRAINT api_quotas_client_scope_window_unique UNIQUE (client_id, scope, window_start);


--
-- Name: api_quotas api_quotas_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_quotas
    ADD CONSTRAINT api_quotas_pkey PRIMARY KEY (id);


--
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- Name: deliberation_messages deliberation_messages_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.deliberation_messages
    ADD CONSTRAINT deliberation_messages_pkey PRIMARY KEY (id);


--
-- Name: deliberation_sessions deliberation_sessions_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.deliberation_sessions
    ADD CONSTRAINT deliberation_sessions_pkey PRIMARY KEY (id);


--
-- Name: draft_cases draft_cases_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.draft_cases
    ADD CONSTRAINT draft_cases_pkey PRIMARY KEY (id);


--
-- Name: draft_cases draft_cases_unique; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.draft_cases
    ADD CONSTRAINT draft_cases_unique UNIQUE (link);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (authentik_sub);


--
-- Name: idx_api_usage_logs_client_logged; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_api_usage_logs_client_logged ON ONLY app.api_usage_logs USING btree (client_id, logged_at DESC);


--
-- Name: api_usage_logs_202606_client_id_logged_at_idx; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX api_usage_logs_202606_client_id_logged_at_idx ON app.api_usage_logs_202606 USING btree (client_id, logged_at DESC);


--
-- Name: idx_api_usage_logs_logged_at; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_api_usage_logs_logged_at ON ONLY app.api_usage_logs USING btree (logged_at DESC);


--
-- Name: api_usage_logs_202606_logged_at_idx; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX api_usage_logs_202606_logged_at_idx ON app.api_usage_logs_202606 USING btree (logged_at DESC);


--
-- Name: idx_api_keys_client; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_api_keys_client ON app.api_keys USING btree (client_id);


--
-- Name: idx_api_keys_prefix; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_api_keys_prefix ON app.api_keys USING btree (key_prefix);


--
-- Name: idx_api_quotas_client_scope; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_api_quotas_client_scope ON app.api_quotas USING btree (client_id, scope);


--
-- Name: idx_app_cases_nation_lower; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_cases_nation_lower ON app.cases USING btree (lower((nation)::text));


--
-- Name: idx_app_cases_search_filter; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_cases_search_filter ON app.cases USING btree (subject_type, year, case_type, nation, status);


--
-- Name: idx_app_cases_subject_normalized; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_cases_subject_normalized ON app.cases USING gin (subject_normalized public.gin_trgm_ops) WHERE (status = 1);


--
-- Name: idx_app_cases_subject_normalized_btree; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_cases_subject_normalized_btree ON app.cases USING btree (lower(regexp_replace((subject)::text, '[^a-zA-Z0-9]'::text, ''::text, 'g'::text)));


--
-- Name: idx_app_deliberation_messages_session_sequence; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_deliberation_messages_session_sequence ON app.deliberation_messages USING btree (session_id, sequence_number);


--
-- Name: idx_app_deliberation_sessions_created_at; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_deliberation_sessions_created_at ON app.deliberation_sessions USING btree (created_at DESC);


--
-- Name: idx_app_deliberation_sessions_status; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_deliberation_sessions_status ON app.deliberation_sessions USING btree (status);


--
-- Name: idx_app_deliberation_sessions_user_id; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_deliberation_sessions_user_id ON app.deliberation_sessions USING btree (user_id);


--
-- Name: idx_app_draft_cases_subject; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_draft_cases_subject ON app.draft_cases USING btree (subject);


--
-- Name: idx_app_draft_cases_subject_type; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_draft_cases_subject_type ON app.draft_cases USING btree (subject_type);


--
-- Name: idx_app_draft_cases_year; Type: INDEX; Schema: app; Owner: -
--

CREATE INDEX idx_app_draft_cases_year ON app.draft_cases USING btree (year);


--
-- Name: api_usage_logs_202606_client_id_logged_at_idx; Type: INDEX ATTACH; Schema: app; Owner: -
--

ALTER INDEX app.idx_api_usage_logs_client_logged ATTACH PARTITION app.api_usage_logs_202606_client_id_logged_at_idx;


--
-- Name: api_usage_logs_202606_logged_at_idx; Type: INDEX ATTACH; Schema: app; Owner: -
--

ALTER INDEX app.idx_api_usage_logs_logged_at ATTACH PARTITION app.api_usage_logs_202606_logged_at_idx;


--
-- Name: api_keys api_keys_client_id_fkey; Type: FK CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_keys
    ADD CONSTRAINT api_keys_client_id_fkey FOREIGN KEY (client_id) REFERENCES app.api_clients(id) ON DELETE CASCADE;


--
-- Name: api_quotas api_quotas_client_id_fkey; Type: FK CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.api_quotas
    ADD CONSTRAINT api_quotas_client_id_fkey FOREIGN KEY (client_id) REFERENCES app.api_clients(id) ON DELETE CASCADE;


--
-- Name: api_usage_logs api_usage_logs_client_id_fkey; Type: FK CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE app.api_usage_logs
    ADD CONSTRAINT api_usage_logs_client_id_fkey FOREIGN KEY (client_id) REFERENCES app.api_clients(id);


--
-- Name: api_usage_logs api_usage_logs_key_id_fkey; Type: FK CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE app.api_usage_logs
    ADD CONSTRAINT api_usage_logs_key_id_fkey FOREIGN KEY (key_id) REFERENCES app.api_keys(id);


--
-- Name: deliberation_messages deliberation_messages_session_id_fkey; Type: FK CONSTRAINT; Schema: app; Owner: -
--

ALTER TABLE ONLY app.deliberation_messages
    ADD CONSTRAINT deliberation_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES app.deliberation_sessions(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--