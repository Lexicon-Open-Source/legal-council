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
-- Name: screening; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA screening;


--
-- Name: SCHEMA screening; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA screening IS 'Read-optimized screening data for BM25 full-text search. Populated by ETL pipeline from entity_graph.';


--
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: screening; Owner: -
--

CREATE FUNCTION screening.trigger_set_timestamp() RETURNS trigger
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
-- Name: entities; Type: TABLE; Schema: screening; Owner: -
--

CREATE TABLE screening.entities (
    id uuid NOT NULL,
    entity_type text NOT NULL,
    source_actor_type text NOT NULL,
    display_name text NOT NULL,
    topics text[] DEFAULT '{}'::text[] NOT NULL,
    remarks text,
    profile_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    nationality text,
    nationality_code text,
    CONSTRAINT entities_entity_type_check CHECK ((entity_type = ANY (ARRAY['person'::text, 'organization'::text]))),
    CONSTRAINT entities_profile_data_object_check CHECK ((jsonb_typeof(profile_data) = 'object'::text)),
    CONSTRAINT screening_entities_nationality_code_iso2_check CHECK (((nationality_code IS NULL) OR (nationality_code ~ '^[A-Z]{2}$'::text)))
);


--
-- Name: TABLE entities; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON TABLE screening.entities IS 'Denormalized screening entities with display-ready profile data.';


--
-- Name: COLUMN entities.entity_type; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON COLUMN screening.entities.entity_type IS 'Simplified screening type. company and public_body are projected as organization; see source_actor_type for the raw upstream actor type.';


--
-- Name: COLUMN entities.source_actor_type; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON COLUMN screening.entities.source_actor_type IS 'Raw actor_type from entity_graph.actors preserved for provenance and future UI branching.';


--
-- Name: COLUMN entities.nationality; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON COLUMN screening.entities.nationality IS 'Normalized ISO 3166 English short country name for the entity nationality.';


--
-- Name: COLUMN entities.nationality_code; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON COLUMN screening.entities.nationality_code IS 'ISO 3166-1 alpha-2 country code for the entity nationality.';


--
-- Name: entity_names; Type: TABLE; Schema: screening; Owner: -
--

CREATE TABLE screening.entity_names (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    entity_id uuid NOT NULL,
    name_value text NOT NULL,
    name_normalized text NOT NULL,
    name_type text DEFAULT 'primary'::text NOT NULL,
    is_matchable boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT screening_entity_names_name_type_check CHECK ((name_type = ANY (ARRAY['primary'::text, 'alias'::text])))
);


--
-- Name: TABLE entity_names; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON TABLE screening.entity_names IS 'Search-oriented entity name variants for BM25 search.';


--
-- Name: entity_sanctions; Type: TABLE; Schema: screening; Owner: -
--

CREATE TABLE screening.entity_sanctions (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    entity_id uuid NOT NULL,
    sanctions_list_id uuid NOT NULL,
    source_event_id uuid NOT NULL,
    list_entry_id text,
    listed_at date,
    delisted_at date,
    entry_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT entity_sanctions_date_order_check CHECK (((listed_at IS NULL) OR (delisted_at IS NULL) OR (listed_at <= delisted_at))),
    CONSTRAINT entity_sanctions_entry_data_object_check CHECK ((jsonb_typeof(entry_data) = 'object'::text))
);


--
-- Name: TABLE entity_sanctions; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON TABLE screening.entity_sanctions IS 'One row per entity/list card with canonical provenance and entry payload.';


--
-- Name: sanctions_lists; Type: TABLE; Schema: screening; Owner: -
--

CREATE TABLE screening.sanctions_lists (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    source_dataset text NOT NULL,
    name text NOT NULL,
    publisher text NOT NULL,
    url text,
    description text,
    country_code text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sanctions_lists_metadata_object_check CHECK ((jsonb_typeof(metadata) = 'object'::text))
);


--
-- Name: TABLE sanctions_lists; Type: COMMENT; Schema: screening; Owner: -
--

COMMENT ON TABLE screening.sanctions_lists IS 'Reference table of screening source lists used by the screening read model.';


--
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: entity_names entity_names_pkey; Type: CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.entity_names
    ADD CONSTRAINT entity_names_pkey PRIMARY KEY (id);


--
-- Name: entity_sanctions entity_sanctions_entity_id_sanctions_list_id_key; Type: CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.entity_sanctions
    ADD CONSTRAINT entity_sanctions_entity_id_sanctions_list_id_key UNIQUE (entity_id, sanctions_list_id);


--
-- Name: entity_sanctions entity_sanctions_pkey; Type: CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.entity_sanctions
    ADD CONSTRAINT entity_sanctions_pkey PRIMARY KEY (id);


--
-- Name: sanctions_lists sanctions_lists_pkey; Type: CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.sanctions_lists
    ADD CONSTRAINT sanctions_lists_pkey PRIMARY KEY (id);


--
-- Name: sanctions_lists uq_sanctions_lists_name_publisher; Type: CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.sanctions_lists
    ADD CONSTRAINT uq_sanctions_lists_name_publisher UNIQUE (name, publisher);


--
-- Name: sanctions_lists uq_screening_sanctions_lists_source_dataset; Type: CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.sanctions_lists
    ADD CONSTRAINT uq_screening_sanctions_lists_source_dataset UNIQUE (source_dataset);


--
-- Name: idx_screening_entities_type; Type: INDEX; Schema: screening; Owner: -
--

CREATE INDEX idx_screening_entities_type ON screening.entities USING btree (entity_type);


--
-- Name: idx_screening_entity_names_bm25; Type: INDEX; Schema: screening; Owner: -
--

CREATE INDEX idx_screening_entity_names_bm25 ON screening.entity_names USING bm25 (id, name_normalized) WITH (key_field=id);


--
-- Name: idx_screening_entity_names_entity_id; Type: INDEX; Schema: screening; Owner: -
--

CREATE INDEX idx_screening_entity_names_entity_id ON screening.entity_names USING btree (entity_id);


--
-- Name: idx_screening_entity_sanctions_entity_id; Type: INDEX; Schema: screening; Owner: -
--

CREATE INDEX idx_screening_entity_sanctions_entity_id ON screening.entity_sanctions USING btree (entity_id);


--
-- Name: idx_screening_entity_sanctions_list_id; Type: INDEX; Schema: screening; Owner: -
--

CREATE INDEX idx_screening_entity_sanctions_list_id ON screening.entity_sanctions USING btree (sanctions_list_id);


--
-- Name: idx_screening_entity_sanctions_source_event_id; Type: INDEX; Schema: screening; Owner: -
--

CREATE INDEX idx_screening_entity_sanctions_source_event_id ON screening.entity_sanctions USING btree (source_event_id);


--
-- Name: idx_screening_sanctions_lists_country_code; Type: INDEX; Schema: screening; Owner: -
--

CREATE INDEX idx_screening_sanctions_lists_country_code ON screening.sanctions_lists USING btree (country_code);


--
-- Name: entities set_entities_updated_at; Type: TRIGGER; Schema: screening; Owner: -
--

CREATE TRIGGER set_entities_updated_at BEFORE UPDATE ON screening.entities FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();


--
-- Name: entity_names set_entity_names_updated_at; Type: TRIGGER; Schema: screening; Owner: -
--

CREATE TRIGGER set_entity_names_updated_at BEFORE UPDATE ON screening.entity_names FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();


--
-- Name: entity_sanctions set_entity_sanctions_updated_at; Type: TRIGGER; Schema: screening; Owner: -
--

CREATE TRIGGER set_entity_sanctions_updated_at BEFORE UPDATE ON screening.entity_sanctions FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();


--
-- Name: sanctions_lists set_sanctions_lists_updated_at; Type: TRIGGER; Schema: screening; Owner: -
--

CREATE TRIGGER set_sanctions_lists_updated_at BEFORE UPDATE ON screening.sanctions_lists FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();


--
-- Name: entity_names entity_names_entity_id_fkey; Type: FK CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.entity_names
    ADD CONSTRAINT entity_names_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES screening.entities(id) ON DELETE CASCADE;


--
-- Name: entity_sanctions entity_sanctions_entity_id_fkey; Type: FK CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.entity_sanctions
    ADD CONSTRAINT entity_sanctions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES screening.entities(id) ON DELETE CASCADE;


--
-- Name: entity_sanctions entity_sanctions_sanctions_list_id_fkey; Type: FK CONSTRAINT; Schema: screening; Owner: -
--

ALTER TABLE ONLY screening.entity_sanctions
    ADD CONSTRAINT entity_sanctions_sanctions_list_id_fkey FOREIGN KEY (sanctions_list_id) REFERENCES screening.sanctions_lists(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--