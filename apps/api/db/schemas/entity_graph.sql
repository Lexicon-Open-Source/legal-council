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
-- Name: entity_graph; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA entity_graph;


--
-- Name: SCHEMA entity_graph; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA entity_graph IS 'L2 (Silver): Normalized entity graph. POLE model (actors, events), content-addressed dedup, soft merge for entity resolution.';


--
-- Name: content_hash(text, text[]); Type: FUNCTION; Schema: entity_graph; Owner: -
--

CREATE FUNCTION entity_graph.content_hash(p_dataset text, p_keys text[]) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT encode(
        sha256(convert_to(
            p_dataset || ':' || array_to_string(
                ARRAY(SELECT coalesce(x, '__NULL__') FROM unnest(p_keys) AS x ORDER BY 1),
                ':'
            ),
            'UTF8'
        )),
        'hex'
    );
$$;


--
-- Name: FUNCTION content_hash(p_dataset text, p_keys text[]); Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON FUNCTION entity_graph.content_hash(p_dataset text, p_keys text[]) IS 'Deterministic dedup key: same entity from same source always produces the same hash. Keys are sorted internally. Used with INSERT ON CONFLICT.';


--
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: entity_graph; Owner: -
--

CREATE FUNCTION entity_graph.trigger_set_timestamp() RETURNS trigger
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
-- Name: actor_addresses; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_addresses (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_id uuid NOT NULL,
    address text NOT NULL,
    address_normalized text,
    address_type text,
    jurisdiction text,
    dataset text NOT NULL,
    source_table text,
    source_id text,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE actor_addresses; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_addresses IS 'Physical addresses associated with actors, with optional classification';


--
-- Name: COLUMN actor_addresses.address; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_addresses.address IS 'Raw address text (dedup key)';


--
-- Name: COLUMN actor_addresses.address_normalized; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_addresses.address_normalized IS 'Lowercased, whitespace-collapsed address for display/search';


--
-- Name: COLUMN actor_addresses.address_type; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_addresses.address_type IS 'Address type: registered, operational, residential';


--
-- Name: COLUMN actor_addresses.jurisdiction; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_addresses.jurisdiction IS 'ISO 3166-1 alpha-2 country code';


--
-- Name: actor_datasets; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_datasets (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_id uuid NOT NULL,
    dataset text NOT NULL,
    source_table text NOT NULL,
    source_id text NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE actor_datasets; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_datasets IS 'Multi-source attribution: tracks which datasets contributed to each actor';


--
-- Name: COLUMN actor_datasets.actor_id; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_datasets.actor_id IS 'FK to actors — ON DELETE RESTRICT to prevent silent provenance loss';


--
-- Name: actor_events; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_events (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_id uuid NOT NULL,
    event_id uuid NOT NULL,
    role character varying(100) NOT NULL,
    dataset text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE actor_events; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_events IS 'Links actors to events. Role describes participation: defendant, judge, clerk, defense_counsel, supplier, subject, etc.';


--
-- Name: COLUMN actor_events.role; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_events.role IS 'defendant, co_defendant, victim, witness, judge, presiding_judge, prosecutor, clerk, defense_counsel, supplier, tenderer, winner, buyer, subject, authority';


--
-- Name: actor_identifiers; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_identifiers (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_id uuid NOT NULL,
    scheme character varying(50) NOT NULL,
    identifier text NOT NULL,
    dataset text NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    identifier_original text
);


--
-- Name: TABLE actor_identifiers; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_identifiers IS 'External registry IDs. Multiple actors may share (scheme, identifier) pre-merge. Use lookup index for entity resolution candidate discovery.';


--
-- Name: COLUMN actor_identifiers.scheme; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_identifiers.scheme IS 'ID scheme: npwp, lkpp_id, lei, nib, siup, passport, etc.';


--
-- Name: COLUMN actor_identifiers.first_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_identifiers.first_seen IS 'ETL observation: when this identifier was first seen in the source';


--
-- Name: COLUMN actor_identifiers.last_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_identifiers.last_seen IS 'ETL observation: when this identifier was last seen in the source';


--
-- Name: COLUMN actor_identifiers.identifier_original; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_identifiers.identifier_original IS 'Raw value before normalization (e.g. NPWP with original formatting)';


--
-- Name: actor_links; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_links (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    link_type character varying(50) NOT NULL,
    source_actor_id uuid NOT NULL,
    target_actor_id uuid NOT NULL,
    properties jsonb DEFAULT '{}'::jsonb NOT NULL,
    start_date date,
    end_date date,
    is_current boolean DEFAULT true NOT NULL,
    dataset text NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_no_self_link CHECK ((source_actor_id <> target_actor_id))
);


--
-- Name: TABLE actor_links; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_links IS 'Actor-to-actor relationships. Enables ownership chains, directorship mapping, family links.';


--
-- Name: COLUMN actor_links.link_type; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_links.link_type IS 'ownership, directorship, employment, family, associate';


--
-- Name: COLUMN actor_links.properties; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_links.properties IS '{"share_pct": 70.5, "role": "komisaris"} — link-type-specific attributes';


--
-- Name: COLUMN actor_links.is_current; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_links.is_current IS 'false if relationship has ended (end_date set)';


--
-- Name: COLUMN actor_links.first_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_links.first_seen IS 'ETL observation: when this relationship was first seen in the source';


--
-- Name: COLUMN actor_links.last_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_links.last_seen IS 'ETL observation: when this relationship was last seen in the source';


--
-- Name: actor_names; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_names (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_id uuid NOT NULL,
    name text NOT NULL,
    name_normalized text NOT NULL,
    name_prefix3 character varying(3),
    name_soundex character varying(10),
    lang character varying(10),
    is_primary boolean DEFAULT false NOT NULL,
    dataset text NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE actor_names; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_names IS 'All known name variants per actor. Used for fuzzy search and entity resolution blocking.';


--
-- Name: COLUMN actor_names.name_prefix3; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_names.name_prefix3 IS 'First 3 chars of normalized name — blocking key for entity resolution';


--
-- Name: COLUMN actor_names.name_soundex; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_names.name_soundex IS 'Soundex of normalized name — blocking key for entity resolution';


--
-- Name: COLUMN actor_names.first_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_names.first_seen IS 'ETL observation: when this name variant was first seen in the source';


--
-- Name: COLUMN actor_names.last_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_names.last_seen IS 'ETL observation: when this name variant was last seen in the source';


--
-- Name: actor_regulations; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_regulations (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_id uuid NOT NULL,
    regulation_id uuid NOT NULL,
    role character varying(50) NOT NULL,
    dataset text NOT NULL,
    source_table text NOT NULL,
    source_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_actor_regulation_role CHECK (((role)::text = ANY ((ARRAY['issuer'::character varying, 'enforcer'::character varying])::text[])))
);


--
-- Name: TABLE actor_regulations; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_regulations IS 'Links actors to regulations. Role describes the relationship: issuer (enacted by), enforcer (enforced by).';


--
-- Name: COLUMN actor_regulations.role; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actor_regulations.role IS 'issuer (public body that enacted the regulation), enforcer (body responsible for enforcement)';


--
-- Name: actor_tags; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actor_tags (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_id uuid NOT NULL,
    tag text NOT NULL,
    tag_source text,
    valid_from timestamp with time zone,
    valid_until timestamp with time zone,
    dataset text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE actor_tags; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actor_tags IS 'Derived risk/classification tags per actor, with optional temporal validity';


--
-- Name: actors; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.actors (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    actor_type character varying(50) NOT NULL,
    canonical_name text NOT NULL,
    name_normalized text NOT NULL,
    properties jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_hash text NOT NULL,
    dataset text NOT NULL,
    source_table text,
    source_id text,
    is_merged boolean DEFAULT false NOT NULL,
    merged_into uuid,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    birth_date text,
    birth_place text,
    gender text,
    nationality text[],
    occupation text,
    CONSTRAINT chk_actor_merge_consistency CHECK ((((is_merged = true) AND (merged_into IS NOT NULL)) OR ((is_merged = false) AND (merged_into IS NULL)))),
    CONSTRAINT chk_actor_type CHECK (((actor_type)::text = ANY ((ARRAY['person'::character varying, 'company'::character varying, 'organization'::character varying, 'public_body'::character varying])::text[])))
);


--
-- Name: TABLE actors; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.actors IS 'Canonical actor registry. One row per real-world person, company, org.';


--
-- Name: COLUMN actors.actor_type; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.actor_type IS 'person, company, organization, public_body. Professional roles (judge, prosecutor) are tracked via actor_events.role and properties JSONB.';


--
-- Name: COLUMN actors.content_hash; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.content_hash IS 'SHA256(dataset:sorted_key_props) — dedup key, UNIQUE constraint';


--
-- Name: COLUMN actors.dataset; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.dataset IS 'Source dataset (interpol, lkpp, spse, mahkamah, etc.)';


--
-- Name: COLUMN actors.source_table; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.source_table IS 'Fully qualified source table (crawler.interpol_red_notices, etc.)';


--
-- Name: COLUMN actors.source_id; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.source_id IS 'ID in the source table (text, not FK — self-contained schema)';


--
-- Name: COLUMN actors.is_merged; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.is_merged IS 'true if absorbed into another actor via entity resolution';


--
-- Name: COLUMN actors.merged_into; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.merged_into IS 'FK to the winner actor. RESTRICT prevents deleting a winner while losers reference it. Use merge_decisions to reverse instead.';


--
-- Name: COLUMN actors.first_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.first_seen IS 'ETL observation: when this actor was first seen in the source during a crawl run';


--
-- Name: COLUMN actors.last_seen; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.last_seen IS 'ETL observation: when this actor was last seen in the source during a crawl run. Stale last_seen may indicate removal from source list.';


--
-- Name: COLUMN actors.birth_date; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.birth_date IS 'Partial ISO 8601: YYYY, YYYY-MM, or YYYY-MM-DD';


--
-- Name: COLUMN actors.birth_place; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.birth_place IS 'Place of birth (free text)';


--
-- Name: COLUMN actors.gender; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.gender IS 'Gender (free text, e.g. male, female)';


--
-- Name: COLUMN actors.nationality; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.nationality IS 'Array of ISO country codes or nationality strings';


--
-- Name: COLUMN actors.occupation; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.actors.occupation IS 'Occupation or profession (free text)';


--
-- Name: event_amounts; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.event_amounts (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    event_id uuid NOT NULL,
    amount_raw text NOT NULL,
    amount numeric,
    currency text DEFAULT 'IDR'::text NOT NULL,
    amount_type text NOT NULL,
    dataset text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE event_amounts; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.event_amounts IS 'Financial amounts associated with events (budget_ceiling, contract_value, penalty, fine, loss, damages)';


--
-- Name: COLUMN event_amounts.amount_raw; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.event_amounts.amount_raw IS 'Original amount string for audit trail';


--
-- Name: COLUMN event_amounts.amount; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.event_amounts.amount IS 'Parsed numeric value (NULL if unparseable)';


--
-- Name: COLUMN event_amounts.amount_type; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.event_amounts.amount_type IS 'Category: budget_ceiling, contract_value, penalty, fine, loss, damages';


--
-- Name: event_content; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.event_content (
    event_id uuid NOT NULL,
    summary text,
    summary_en text,
    body_markdown text,
    properties jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE event_content; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.event_content IS 'Summaries and heavy text content for events. 1:1 with events (optional). Separated to keep core events table lean for graph traversal.';


--
-- Name: COLUMN event_content.event_id; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.event_content.event_id IS 'FK to events.id — also serves as PK enforcing at-most-one content row per event.';


--
-- Name: COLUMN event_content.summary; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.event_content.summary IS 'Indonesian-language summary. Generated by LLM extraction pipeline. May be NULL if not yet extracted.';


--
-- Name: COLUMN event_content.summary_en; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.event_content.summary_en IS 'English-language summary. Generated by LLM extraction pipeline. May be NULL if not yet extracted.';


--
-- Name: COLUMN event_content.body_markdown; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.event_content.body_markdown IS 'Curated formatted content as markdown — not raw PDF text. For verdicts: structured summary with sections. For sanctions: violation description.';


--
-- Name: COLUMN event_content.properties; Type: COMMENT; Schema: entity_graph; Owner

... [OUTPUT TRUNCATED - 13621 chars omitted out of 63621 total] ...

; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulation_links.link_type IS 'revokes, amends, amended_by, revoked_by, legal_basis (from mengingat section)';


--
-- Name: regulations; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.regulations (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    jurisdiction character varying(10) NOT NULL,
    canonical_title text NOT NULL,
    form character varying(100),
    number character varying(50),
    year character varying(10),
    subject text,
    status character varying(50),
    effective_date date,
    properties jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_hash text NOT NULL,
    dataset text NOT NULL,
    source_table text NOT NULL,
    source_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    form_normalized character varying(100),
    canonical_title_normalized text,
    CONSTRAINT chk_jurisdiction CHECK (((jurisdiction)::text = ANY ((ARRAY['ID'::character varying, 'SG'::character varying, 'MY'::character varying])::text[]))),
    CONSTRAINT chk_regulation_status CHECK (((status IS NULL) OR ((status)::text = ANY ((ARRAY['berlaku'::character varying, 'tidak_berlaku'::character varying, 'dicabut'::character varying, 'diubah'::character varying, 'current'::character varying, 'repealed'::character varying, 'revised'::character varying])::text[]))))
);


--
-- Name: TABLE regulations; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.regulations IS 'Canonical regulation registry. One row per distinct regulation (law, decree, circular, etc.).';


--
-- Name: COLUMN regulations.jurisdiction; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.jurisdiction IS 'ISO 3166-1 alpha-2: ID (Indonesia), SG (Singapore), MY (Malaysia)';


--
-- Name: COLUMN regulations.canonical_title; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.canonical_title IS 'Full official title of the regulation';


--
-- Name: COLUMN regulations.form; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.form IS 'Regulation form: undang-undang, peraturan_pemerintah, peraturan_presiden, etc. No CHECK — vocabulary varies by jurisdiction.';


--
-- Name: COLUMN regulations.status; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.status IS 'berlaku, tidak_berlaku, dicabut, diubah. Nullable — SG/MY may use different vocabulary.';


--
-- Name: COLUMN regulations.content_hash; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.content_hash IS 'SHA256(dataset:sorted_key_props) — dedup key, UNIQUE index';


--
-- Name: COLUMN regulations.dataset; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.dataset IS 'Source dataset (jdih_bpk, peraturan_go_id, etc.)';


--
-- Name: COLUMN regulations.source_table; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.source_table IS 'Fully qualified source table (crawler.bpk_regulations, etc.)';


--
-- Name: COLUMN regulations.source_id; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.source_id IS 'ID in the source table (text, not FK — self-contained schema)';


--
-- Name: COLUMN regulations.form_normalized; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.form_normalized IS 'Canonical lowercase form (uu, pp, perpres) for content hash and lookup. Computed by ETL, not DB-generated.';


--
-- Name: COLUMN regulations.canonical_title_normalized; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.regulations.canonical_title_normalized IS 'NFKD-normalized, lowercased title for codex law dedup (KUHP, KUHPerdata). Used when number/year are NULL. Computed by ETL.';


--
-- Name: watermarks; Type: TABLE; Schema: entity_graph; Owner: -
--

CREATE TABLE entity_graph.watermarks (
    source_dataset text NOT NULL,
    last_processed_at timestamp with time zone,
    version integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'idle'::character varying NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_processed_id text DEFAULT '00000000-0000-0000-0000-000000000000'::text,
    CONSTRAINT chk_watermark_status CHECK (((status)::text = ANY ((ARRAY['idle'::character varying, 'running'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: TABLE watermarks; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON TABLE entity_graph.watermarks IS 'ETL progress tracking per source. Optimistic locking via version column.';


--
-- Name: COLUMN watermarks.version; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.watermarks.version IS 'Optimistic lock: UPDATE SET version = version + 1 WHERE version = $expected';


--
-- Name: COLUMN watermarks.status; Type: COMMENT; Schema: entity_graph; Owner: -
--

COMMENT ON COLUMN entity_graph.watermarks.status IS 'idle, running, failed';


--
-- Name: merge_decisions id; Type: DEFAULT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.merge_decisions ALTER COLUMN id SET DEFAULT nextval('entity_graph.merge_decisions_id_seq'::regclass);


--
-- Name: actor_addresses actor_addresses_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_addresses
    ADD CONSTRAINT actor_addresses_pkey PRIMARY KEY (id);


--
-- Name: actor_datasets actor_datasets_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_datasets
    ADD CONSTRAINT actor_datasets_pkey PRIMARY KEY (id);


--
-- Name: actor_events actor_events_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_events
    ADD CONSTRAINT actor_events_pkey PRIMARY KEY (id);


--
-- Name: actor_identifiers actor_identifiers_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_identifiers
    ADD CONSTRAINT actor_identifiers_pkey PRIMARY KEY (id);


--
-- Name: actor_links actor_links_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_links
    ADD CONSTRAINT actor_links_pkey PRIMARY KEY (id);


--
-- Name: actor_names actor_names_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_names
    ADD CONSTRAINT actor_names_pkey PRIMARY KEY (id);


--
-- Name: actor_regulations actor_regulations_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_regulations
    ADD CONSTRAINT actor_regulations_pkey PRIMARY KEY (id);


--
-- Name: actor_tags actor_tags_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_tags
    ADD CONSTRAINT actor_tags_pkey PRIMARY KEY (id);


--
-- Name: actors actors_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actors
    ADD CONSTRAINT actors_pkey PRIMARY KEY (id);


--
-- Name: event_amounts event_amounts_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.event_amounts
    ADD CONSTRAINT event_amounts_pkey PRIMARY KEY (id);


--
-- Name: event_content event_content_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.event_content
    ADD CONSTRAINT event_content_pkey PRIMARY KEY (event_id);


--
-- Name: event_regulations event_regulations_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.event_regulations
    ADD CONSTRAINT event_regulations_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: extraction_log extraction_log_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.extraction_log
    ADD CONSTRAINT extraction_log_pkey PRIMARY KEY (dataset, source_id);


--
-- Name: merge_decisions merge_decisions_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.merge_decisions
    ADD CONSTRAINT merge_decisions_pkey PRIMARY KEY (id);


--
-- Name: regulation_articles regulation_articles_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_articles
    ADD CONSTRAINT regulation_articles_pkey PRIMARY KEY (id);


--
-- Name: regulation_content regulation_content_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_content
    ADD CONSTRAINT regulation_content_pkey PRIMARY KEY (regulation_id);


--
-- Name: regulation_identifiers regulation_identifiers_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_identifiers
    ADD CONSTRAINT regulation_identifiers_pkey PRIMARY KEY (id);


--
-- Name: regulation_links regulation_links_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_links
    ADD CONSTRAINT regulation_links_pkey PRIMARY KEY (id);


--
-- Name: regulations regulations_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulations
    ADD CONSTRAINT regulations_pkey PRIMARY KEY (id);


--
-- Name: watermarks watermarks_pkey; Type: CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.watermarks
    ADD CONSTRAINT watermarks_pkey PRIMARY KEY (source_dataset);


--
-- Name: idx_eg_actor_addresses_actor; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_addresses_actor ON entity_graph.actor_addresses USING btree (actor_id);


--
-- Name: idx_eg_actor_addresses_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_addresses_unique ON entity_graph.actor_addresses USING btree (actor_id, address, dataset);


--
-- Name: idx_eg_actor_datasets_actor; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_datasets_actor ON entity_graph.actor_datasets USING btree (actor_id);


--
-- Name: idx_eg_actor_datasets_dataset; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_datasets_dataset ON entity_graph.actor_datasets USING btree (dataset);


--
-- Name: idx_eg_actor_datasets_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_datasets_unique ON entity_graph.actor_datasets USING btree (actor_id, dataset, source_id);


--
-- Name: idx_eg_actor_events_event_role; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_events_event_role ON entity_graph.actor_events USING btree (event_id, role);


--
-- Name: idx_eg_actor_events_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_events_unique ON entity_graph.actor_events USING btree (actor_id, event_id, role);


--
-- Name: idx_eg_actor_identifiers_actor_scheme; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_identifiers_actor_scheme ON entity_graph.actor_identifiers USING btree (actor_id, scheme, identifier);


--
-- Name: idx_eg_actor_identifiers_lookup; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_identifiers_lookup ON entity_graph.actor_identifiers USING btree (scheme, identifier);


--
-- Name: idx_eg_actor_links_source_type; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_links_source_type ON entity_graph.actor_links USING btree (source_actor_id, link_type);


--
-- Name: idx_eg_actor_links_target_type; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_links_target_type ON entity_graph.actor_links USING btree (target_actor_id, link_type);


--
-- Name: idx_eg_actor_links_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_links_unique ON entity_graph.actor_links USING btree (source_actor_id, target_actor_id, link_type, dataset, COALESCE(start_date, '1970-01-01'::date));


--
-- Name: idx_eg_actor_names_actor; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_names_actor ON entity_graph.actor_names USING btree (actor_id);


--
-- Name: idx_eg_actor_names_actor_normalized; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_names_actor_normalized ON entity_graph.actor_names USING btree (actor_id, name_normalized);


--
-- Name: idx_eg_actor_names_prefix3; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_names_prefix3 ON entity_graph.actor_names USING btree (name_prefix3);


--
-- Name: idx_eg_actor_names_primary; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_names_primary ON entity_graph.actor_names USING btree (actor_id) WHERE (is_primary = true);


--
-- Name: idx_eg_actor_names_soundex; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_names_soundex ON entity_graph.actor_names USING btree (name_soundex);


--
-- Name: idx_eg_actor_names_trgm; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_names_trgm ON entity_graph.actor_names USING gin (name_normalized public.gin_trgm_ops);


--
-- Name: idx_eg_actor_regulations_regulation; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_regulations_regulation ON entity_graph.actor_regulations USING btree (regulation_id);


--
-- Name: idx_eg_actor_regulations_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_regulations_unique ON entity_graph.actor_regulations USING btree (actor_id, regulation_id, role);


--
-- Name: idx_eg_actor_tags_active; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_tags_active ON entity_graph.actor_tags USING btree (tag) WHERE (valid_until IS NULL);


--
-- Name: idx_eg_actor_tags_tag; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actor_tags_tag ON entity_graph.actor_tags USING btree (tag);


--
-- Name: idx_eg_actor_tags_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actor_tags_unique ON entity_graph.actor_tags USING btree (actor_id, tag, dataset, COALESCE(valid_from, '1970-01-01 00:00:00+00'::timestamp with time zone));


--
-- Name: idx_eg_actors_birth_date; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actors_birth_date ON entity_graph.actors USING btree (birth_date) WHERE ((birth_date IS NOT NULL) AND (NOT is_merged));


--
-- Name: idx_eg_actors_content_hash; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_actors_content_hash ON entity_graph.actors USING btree (content_hash);


--
-- Name: idx_eg_actors_dataset; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actors_dataset ON entity_graph.actors USING btree (dataset) WHERE (NOT is_merged);


--
-- Name: idx_eg_actors_merged_into; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actors_merged_into ON entity_graph.actors USING btree (merged_into) WHERE is_merged;


--
-- Name: idx_eg_actors_name_trgm; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actors_name_trgm ON entity_graph.actors USING gin (name_normalized public.gin_trgm_ops) WHERE (NOT is_merged);


--
-- Name: idx_eg_actors_nationality; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actors_nationality ON entity_graph.actors USING gin (nationality) WHERE (NOT is_merged);


--
-- Name: idx_eg_actors_properties; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actors_properties ON entity_graph.actors USING gin (properties jsonb_path_ops) WHERE (NOT is_merged);


--
-- Name: idx_eg_actors_type; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_actors_type ON entity_graph.actors USING btree (actor_type) WHERE (NOT is_merged);


--
-- Name: idx_eg_event_amounts_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_event_amounts_unique ON entity_graph.event_amounts USING btree (event_id, amount_type, dataset);


--
-- Name: idx_eg_event_regulations_event; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_event_regulations_event ON entity_graph.event_regulations USING btree (event_id);


--
-- Name: idx_eg_event_regulations_regulation; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_event_regulations_regulation ON entity_graph.event_regulations USING btree (regulation_id);


--
-- Name: idx_eg_event_regulations_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_event_regulations_unique ON entity_graph.event_regulations USING btree (event_id, regulation_id, role, COALESCE(article, ''::text));


--
-- Name: idx_eg_events_content_hash; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_events_content_hash ON entity_graph.events USING btree (content_hash);


--
-- Name: idx_eg_events_dataset; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_events_dataset ON entity_graph.events USING btree (dataset);


--
-- Name: idx_eg_events_properties; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_events_properties ON entity_graph.events USING gin (properties jsonb_path_ops);


--
-- Name: idx_eg_events_type_date; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_events_type_date ON entity_graph.events USING btree (event_type, event_date);


--
-- Name: idx_eg_extraction_log_status; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_extraction_log_status ON entity_graph.extraction_log USING btree (dataset, status);


--
-- Name: idx_eg_merge_decisions_entities; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_merge_decisions_entities ON entity_graph.merge_decisions USING btree (entity_a, entity_b);


--
-- Name: idx_eg_merge_decisions_symmetric; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_merge_decisions_symmetric ON entity_graph.merge_decisions USING btree (LEAST(entity_a, entity_b), GREATEST(entity_a, entity_b)) WHERE (is_active = true);


--
-- Name: idx_eg_regulation_articles_bm25; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulation_articles_bm25 ON entity_graph.regulation_articles USING bm25 (id, content, title, pasal) WITH (key_field=id);


--
-- Name: idx_eg_regulation_articles_regulation; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulation_articles_regulation ON entity_graph.regulation_articles USING btree (regulation_id, ordinal);


--
-- Name: idx_eg_regulation_articles_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_regulation_articles_unique ON entity_graph.regulation_articles USING btree (regulation_id, path);


--
-- Name: idx_eg_regulation_identifiers_lookup; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulation_identifiers_lookup ON entity_graph.regulation_identifiers USING btree (scheme, identifier);


--
-- Name: idx_eg_regulation_identifiers_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_regulation_identifiers_unique ON entity_graph.regulation_identifiers USING btree (regulation_id, scheme, identifier);


--
-- Name: idx_eg_regulation_links_target; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulation_links_target ON entity_graph.regulation_links USING btree (target_regulation_id);


--
-- Name: idx_eg_regulation_links_unique; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_regulation_links_unique ON entity_graph.regulation_links USING btree (source_regulation_id, target_regulation_id, link_type);


--
-- Name: idx_eg_regulations_content_hash; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE UNIQUE INDEX idx_eg_regulations_content_hash ON entity_graph.regulations USING btree (content_hash);


--
-- Name: idx_eg_regulations_dataset; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulations_dataset ON entity_graph.regulations USING btree (dataset);


--
-- Name: idx_eg_regulations_form_norm_number_year; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulations_form_norm_number_year ON entity_graph.regulations USING btree (jurisdiction, form_normalized, number, year);


--
-- Name: idx_eg_regulations_form_number_year; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulations_form_number_year ON entity_graph.regulations USING btree (jurisdiction, form, number, year);


--
-- Name: idx_eg_regulations_source; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulations_source ON entity_graph.regulations USING btree (source_table, source_id);


--
-- Name: idx_eg_regulations_title_normalized; Type: INDEX; Schema: entity_graph; Owner: -
--

CREATE INDEX idx_eg_regulations_title_normalized ON entity_graph.regulations USING btree (canonical_title_normalized) WHERE (canonical_title_normalized IS NOT NULL);


--
-- Name: actors set_actors_updated_at; Type: TRIGGER; Schema: entity_graph; Owner: -
--

CREATE TRIGGER set_actors_updated_at BEFORE UPDATE ON entity_graph.actors FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();


--
-- Name: event_content set_event_content_updated_at; Type: TRIGGER; Schema: entity_graph; Owner: -
--

CREATE TRIGGER set_event_content_updated_at BEFORE UPDATE ON entity_graph.event_content FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();


--
-- Name: events set_events_updated_at; Type: TRIGGER; Schema: entity_graph; Owner: -
--

CREATE TRIGGER set_events_updated_at BEFORE UPDATE ON entity_graph.events FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();


--
-- Name: regulation_content set_regulation_content_updated_at; Type: TRIGGER; Schema: entity_graph; Owner: -
--

CREATE TRIGGER set_regulation_content_updated_at BEFORE UPDATE ON entity_graph.regulation_content FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();


--
-- Name: regulations set_regulations_updated_at; Type: TRIGGER; Schema: entity_graph; Owner: -
--

CREATE TRIGGER set_regulations_updated_at BEFORE UPDATE ON entity_graph.regulations FOR EACH ROW EXECUTE FUNCTION entity_graph.trigger_set_timestamp();


--
-- Name: actor_addresses actor_addresses_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_addresses
    ADD CONSTRAINT actor_addresses_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actor_datasets actor_datasets_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_datasets
    ADD CONSTRAINT actor_datasets_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES entity_graph.actors(id) ON DELETE RESTRICT;


--
-- Name: actor_events actor_events_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_events
    ADD CONSTRAINT actor_events_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actor_events actor_events_event_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_events
    ADD CONSTRAINT actor_events_event_id_fkey FOREIGN KEY (event_id) REFERENCES entity_graph.events(id) ON DELETE CASCADE;


--
-- Name: actor_identifiers actor_identifiers_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_identifiers
    ADD CONSTRAINT actor_identifiers_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actor_links actor_links_source_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_links
    ADD CONSTRAINT actor_links_source_actor_id_fkey FOREIGN KEY (source_actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actor_links actor_links_target_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_links
    ADD CONSTRAINT actor_links_target_actor_id_fkey FOREIGN KEY (target_actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actor_names actor_names_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_names
    ADD CONSTRAINT actor_names_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actor_regulations actor_regulations_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_regulations
    ADD CONSTRAINT actor_regulations_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actor_regulations actor_regulations_regulation_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_regulations
    ADD CONSTRAINT actor_regulations_regulation_id_fkey FOREIGN KEY (regulation_id) REFERENCES entity_graph.regulations(id) ON DELETE CASCADE;


--
-- Name: actor_tags actor_tags_actor_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actor_tags
    ADD CONSTRAINT actor_tags_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES entity_graph.actors(id) ON DELETE CASCADE;


--
-- Name: actors actors_merged_into_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.actors
    ADD CONSTRAINT actors_merged_into_fkey FOREIGN KEY (merged_into) REFERENCES entity_graph.actors(id) ON DELETE RESTRICT;


--
-- Name: event_amounts event_amounts_event_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.event_amounts
    ADD CONSTRAINT event_amounts_event_id_fkey FOREIGN KEY (event_id) REFERENCES entity_graph.events(id) ON DELETE CASCADE;


--
-- Name: event_content event_content_event_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.event_content
    ADD CONSTRAINT event_content_event_id_fkey FOREIGN KEY (event_id) REFERENCES entity_graph.events(id) ON DELETE CASCADE;


--
-- Name: event_regulations event_regulations_event_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.event_regulations
    ADD CONSTRAINT event_regulations_event_id_fkey FOREIGN KEY (event_id) REFERENCES entity_graph.events(id) ON DELETE CASCADE;


--
-- Name: event_regulations event_regulations_regulation_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.event_regulations
    ADD CONSTRAINT event_regulations_regulation_id_fkey FOREIGN KEY (regulation_id) REFERENCES entity_graph.regulations(id) ON DELETE CASCADE;


--
-- Name: merge_decisions merge_decisions_canonical_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.merge_decisions
    ADD CONSTRAINT merge_decisions_canonical_id_fkey FOREIGN KEY (canonical_id) REFERENCES entity_graph.actors(id) ON DELETE RESTRICT;


--
-- Name: merge_decisions merge_decisions_entity_a_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.merge_decisions
    ADD CONSTRAINT merge_decisions_entity_a_fkey FOREIGN KEY (entity_a) REFERENCES entity_graph.actors(id) ON DELETE RESTRICT;


--
-- Name: merge_decisions merge_decisions_entity_b_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.merge_decisions
    ADD CONSTRAINT merge_decisions_entity_b_fkey FOREIGN KEY (entity_b) REFERENCES entity_graph.actors(id) ON DELETE RESTRICT;


--
-- Name: regulation_articles regulation_articles_regulation_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_articles
    ADD CONSTRAINT regulation_articles_regulation_id_fkey FOREIGN KEY (regulation_id) REFERENCES entity_graph.regulations(id) ON DELETE CASCADE;


--
-- Name: regulation_content regulation_content_regulation_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_content
    ADD CONSTRAINT regulation_content_regulation_id_fkey FOREIGN KEY (regulation_id) REFERENCES entity_graph.regulations(id) ON DELETE CASCADE;


--
-- Name: regulation_identifiers regulation_identifiers_regulation_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_identifiers
    ADD CONSTRAINT regulation_identifiers_regulation_id_fkey FOREIGN KEY (regulation_id) REFERENCES entity_graph.regulations(id) ON DELETE CASCADE;


--
-- Name: regulation_links regulation_links_source_regulation_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_links
    ADD CONSTRAINT regulation_links_source_regulation_id_fkey FOREIGN KEY (source_regulation_id) REFERENCES entity_graph.regulations(id) ON DELETE CASCADE;


--
-- Name: regulation_links regulation_links_target_regulation_id_fkey; Type: FK CONSTRAINT; Schema: entity_graph; Owner: -
--

ALTER TABLE ONLY entity_graph.regulation_links
    ADD CONSTRAINT regulation_links_target_regulation_id_fkey FOREIGN KEY (target_regulation_id) REFERENCES entity_graph.regulations(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--