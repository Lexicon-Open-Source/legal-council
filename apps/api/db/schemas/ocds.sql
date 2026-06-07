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
-- Name: ocds; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ocds;


--
-- Name: SCHEMA ocds; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA ocds IS 'L2 (Silver): OCDS-normalized procurement data. Flat tabular design with immutable release pattern.';


--
-- Name: prevent_release_delete(); Type: FUNCTION; Schema: ocds; Owner: -
--

CREATE FUNCTION ocds.prevent_release_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Allow bypass for maintenance procedures
    IF COALESCE(current_setting('app.allow_release_delete', true), 'false') = 'true' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'OCDS releases are immutable and cannot be deleted. To purge data, set: SET app.allow_release_delete = ''true'';';
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: ocds; Owner: -
--

CREATE FUNCTION ocds.update_updated_at_column() RETURNS trigger
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
-- Name: amendments; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.amendments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    release_id uuid NOT NULL,
    tender_id uuid,
    award_id uuid,
    contract_id uuid,
    amendment_id character varying(150),
    date timestamp with time zone,
    rationale text,
    description text,
    amended_fields text[],
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: award_suppliers; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.award_suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    award_id uuid NOT NULL,
    party_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: awards; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.awards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    release_id uuid NOT NULL,
    award_id character varying(150) NOT NULL,
    title text,
    description text,
    status character varying(50),
    date timestamp with time zone,
    value_amount numeric(20,2),
    value_currency character varying(3) DEFAULT 'IDR'::character varying,
    negotiated_amount numeric(20,2),
    contract_period_start_date timestamp with time zone,
    contract_period_end_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    contract_period_max_extent_date timestamp with time zone,
    contract_period_duration_in_days integer,
    CONSTRAINT awards_status_check CHECK (((status IS NULL) OR ((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'cancelled'::character varying, 'unsuccessful'::character varying])::text[]))))
);


--
-- Name: bids; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.bids (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    release_id uuid NOT NULL,
    bid_id character varying(150),
    date timestamp with time zone,
    status character varying(50),
    value_amount numeric(20,2),
    value_currency character varying(3) DEFAULT 'IDR'::character varying,
    tenderer_id uuid,
    corrected_amount numeric(20,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE bids; Type: COMMENT; Schema: ocds; Owner: -
--

COMMENT ON TABLE ocds.bids IS 'OCDS Bid Extension (bids/details). Each row = one bid from one tenderer.';


--
-- Name: COLUMN bids.corrected_amount; Type: COMMENT; Schema: ocds; Owner: -
--

COMMENT ON COLUMN ocds.bids.corrected_amount IS 'Extension: harga_terkoreksi from Indonesian procurement (corrected bid price after evaluation).';


--
-- Name: releases; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.releases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ocid character varying(150) NOT NULL,
    release_id character varying(200) NOT NULL,
    language character varying(10) DEFAULT 'id'::character varying,
    tag text[] NOT NULL,
    initiation_type character varying(50) DEFAULT 'tender'::character varying,
    buyer_id uuid,
    source_system character varying(50) NOT NULL,
    source_id character varying(100) NOT NULL,
    source_url text,
    source_updated_at timestamp with time zone,
    date timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    event_id uuid,
    nation character varying(3) DEFAULT 'IDN'::character varying
);


--
-- Name: COLUMN releases.event_id; Type: COMMENT; Schema: ocds; Owner: -
--

COMMENT ON COLUMN ocds.releases.event_id IS 'Soft reference to entity_graph.events(id). One release = one procurement event. Populated by entity resolution ETL.';


--
-- Name: COLUMN releases.nation; Type: COMMENT; Schema: ocds; Owner: -
--

COMMENT ON COLUMN ocds.releases.nation IS 'ISO 3166-1 Alpha-3 nation code (extension field)';


--
-- Name: compiled_awards; Type: VIEW; Schema: ocds; Owner: -
--

CREATE VIEW ocds.compiled_awards AS
 SELECT DISTINCT ON (r.ocid, a.award_id) r.ocid,
    r.release_id AS latest_release_id,
    r.date AS release_date,
    a.id,
    a.award_id,
    a.title,
    a.status,
    a.date AS award_date,
    a.value_amount,
    a.value_currency,
    a.negotiated_amount,
    a.created_at,
    a.updated_at
   FROM (ocds.releases r
     JOIN ocds.awards a ON ((a.release_id = r.id)))
  ORDER BY r.ocid, a.award_id, r.date DESC;


--
-- Name: contract_implementation; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.contract_implementation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    contract_id uuid NOT NULL,
    status character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contracts; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.contracts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    release_id uuid NOT NULL,
    award_id uuid,
    contract_id character varying(150) NOT NULL,
    title text,
    description text,
    status character varying(50),
    period_start_date timestamp with time zone,
    period_end_date timestamp with time zone,
    value_amount numeric(20,2),
    value_currency character varying(3) DEFAULT 'IDR'::character varying,
    pdn_value_amount numeric(20,2),
    umk_value_amount numeric(20,2),
    date_signed timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    period_max_extent_date timestamp with time zone,
    period_duration_in_days integer,
    CONSTRAINT contracts_status_check CHECK (((status IS NULL) OR ((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'cancelled'::character varying, 'terminated'::character varying])::text[]))))
);


--
-- Name: compiled_contracts; Type: VIEW; Schema: ocds; Owner: -
--

CREATE VIEW ocds.compiled_contracts AS
 SELECT DISTINCT ON (r.ocid, c.contract_id) r.ocid,
    r.release_id AS latest_release_id,
    r.date AS release_date,
    c.id,
    c.contract_id,
    c.award_id,
    c.title,
    c.status,
    c.value_amount,
    c.value_currency,
    c.pdn_value_amount,
    c.umk_value_amount,
    c.date_signed,
    c.period_max_extent_date,
    c.period_duration_in_days,
    ci.status AS implementation_status,
    c.created_at,
    c.updated_at
   FROM ((ocds.releases r
     JOIN ocds.contracts c ON ((c.release_id = r.id)))
     LEFT JOIN ocds.contract_implementation ci ON ((ci.contract_id = c.id)))
  ORDER BY r.ocid, c.contract_id, r.date DESC;


--
-- Name: latest_releases; Type: VIEW; Schema: ocds; Owner: -
--

CREATE VIEW ocds.latest_releases AS
 SELECT DISTINCT ON (ocid) id,
    ocid,
    release_id,
    language,
    tag,
    initiation_type,
    buyer_id,
    source_system,
    source_id,
    source_url,
    source_updated_at,
    date,
    nation,
    event_id,
    created_at,
    updated_at
   FROM ocds.releases
  ORDER BY ocid, date DESC;


--
-- Name: related_processes; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.related_processes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    release_id uuid NOT NULL,
    related_process_id character varying(255),
    relationship text[],
    title text,
    scheme character varying(100),
    identifier character varying(255),
    uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: compiled_related_processes; Type: VIEW; Schema: ocds; Owner: -
--

CREATE VIEW ocds.compiled_related_processes AS
 SELECT DISTINCT ON (lr.ocid, rp.identifier) lr.ocid,
    lr.id AS release_id,
    rp.id AS related_process_pk,
    rp.related_process_id,
    rp.relationship,
    rp.title,
    rp.scheme,
    rp.identifier,
    rp.uri,
    rp.created_at,
    rp.updated_at
   FROM (ocds.latest_releases lr
     JOIN ocds.related_processes rp ON ((rp.release_id = lr.id)))
  ORDER BY lr.ocid, rp.identifier, rp.created_at DESC;


--
-- Name: tender; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.tender (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    release_id uuid NOT NULL,
    tender_id character varying(100) NOT NULL,
    title text NOT NULL,
    description text,
    status character varying(50),
    procurement_method character varying(50),
    procurement_method_details character varying(255),
    procurement_method_rationale text,
    main_procurement_category character varying(50),
    additional_procurement_categories text[],
    value_amount numeric(20,2),
    value_currency character varying(3) DEFAULT 'IDR'::character varying,
    min_value_amount numeric(20,2),
    max_value_amount numeric(20,2),
    procuring_entity_id uuid,
    tender_period_start_date timestamp with time zone,
    tender_period_end_date timestamp with time zone,
    tender_period_max_extent_date timestamp with time zone,
    enquiry_period_start_date timestamp with time zone,
    enquiry_period_end_date timestamp with time zone,
    award_period_start_date timestamp with time zone,
    award_period_end_date timestamp with time zone,
    has_enquiries boolean,
    eligibility_criteria text,
    award_criteria character varying(100),
    award_criteria_details text,
    submission_method text[],
    submission_method_details text,
    number_of_tenderers integer,
    legal_basis text,
    location_description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tender_period_duration_in_days integer,
    enquiry_period_duration_in_days integer,
    enquiry_period_max_extent_date timestamp with time zone,
    award_period_duration_in_days integer,
    award_period_max_extent_date timestamp with time zone,
    contract_period_start_date timestamp with time zone,
    contract_period_end_date timestamp with time zone,
    contract_period_max_extent_date timestamp with time zone,
    contract_period_duration_in_days integer,
    rup_codes text[],
    geo_lat double precision,
    geo_lon double precision,
    geo_bbox_min_lat double precision,
    geo_bbox_max_lat double precision,
    geo_bbox_min_lon double precision,
    geo_bbox_max_lon double precision,
    geo_geojson jsonb,
    CONSTRAINT tender_status_check CHECK (((status IS NULL) OR ((status)::text = ANY ((ARRAY['planning'::character varying, 'planned'::character varying, 'active'::character varying, 'cancelled'::character varying, 'unsuccessful'::character varying, 'complete'::character varying, 'withdrawn'::character varying])::text[]))))
);


--
-- Name: COLUMN tender.rup_codes; Type: COMMENT; Schema: ocds; Owner: -
--

COMMENT ON COLUMN ocds.tender.rup_codes IS 'Extension: array of RUP (Rencana Umum Pengadaan) codes from SiRUP, used for cross-referencing related planning processes.';


--
-- Name: COLUMN tender.geo_geojson; Type: COMMENT; Schema: ocds; Owner: -
--

COMMENT ON COLUMN ocds.tender.geo_geojson IS 'GeoJSON geometry (Polygon/LineString) from Nominatim polygon_geojson response.';


--
-- Name: compiled_tender; Type: VIEW; Schema: ocds; Owner: -
--

CREATE VIEW ocds.compiled_tender AS
 SELECT DISTINCT ON (r.ocid) r.ocid,
    r.release_id AS latest_release_id,
    r.date AS release_date,
    r.tag,
    r.source_system,
    t.id,
    t.tender_id,
    t.title,
    t.description,
    t.status,
    t.procurement_method,
    t.procurement_method_details,
    t.main_procurement_category,
    t.value_amount,
    t.value_currency,
    t.max_value_amount,
    t.number_of_tenderers,
    t.location_description,
    t.tender_period_start_date,
    t.created_at,
    t.updated_at
   FROM (ocds.releases r
     JOIN ocds.tender t ON ((t.release_id = r.id)))
  ORDER BY r.ocid, r.date DESC;


--
-- Name: contract_implementation_documents; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.contract_implementation_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    implementation_id uuid NOT NULL,
    document_id character varying(100),
    document_type character varying(100),
    title text,
    description text,
    url text,
    storage_path text,
    date_published timestamp with time zone,
    date_modified timestamp with time zone,
    format character varying(100),
    language character varying(10) DEFAULT 'id'::character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contract_implementation_milestones; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.contract_implementation_milestones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    implementation_id uuid NOT NULL,
    milestone_id character varying(100),
    title text,
    milestone_type character varying(100),
    description text,
    code character varying(50),
    due_date timestamp with time zone,
    date_met timestamp with time zone,
    date_modified timestamp with time zone,
    status character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contract_implementation_transactions; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.contract_implementation_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    implementation_id uuid NOT NULL,
    transaction_id character varying(150),
    source text,
    date timestamp with time zone,
    value_amount numeric(20,2),
    value_currency character varying(3) DEFAULT 'IDR'::character varying,
    payer_id uuid,
    payee_id uuid,
    uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: documents; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    release_id uuid,
    tender_id uuid,
    award_id uuid,
    contract_id uuid,
    document_id character varying(100) NOT NULL,
    document_type character varying(100),
    title text,
    description text,
    url text,
    storage_path text,
    date_published timestamp with time zone,
    date_modified timestamp with time zone,
    format character varying(100),
    language character varying(10) DEFAULT 'id'::character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT documents_parent_check CHECK (((((((release_id IS NOT NULL))::integer + ((tender_id IS NOT NULL))::integer) + ((award_id IS NOT NULL))::integer) + ((contract_id IS NOT NULL))::integer) = 1))
);


--
-- Name: items; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tender_id uuid,
    award_id uuid,
    contract_id uuid,
    item_id character varying(100) NOT NULL,
    description text,
    classification_scheme character varying(50),
    classification_id character varying(50),
    classification_description text,
    classification_uri text,
    quantity numeric(20,4),
    unit_scheme character varying(50),
    unit_id character varying(50),
    unit_name character varying(100),
    unit_value_amount numeric(20,2),
    unit_value_currency character varying(3) DEFAULT 'IDR'::character varying,
    delivery_location_description text,
    delivery_address text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    release_id uuid,
    additional_classification_scheme character varying(100),
    additional_classification_id character varying(100),
    additional_classification_description text,
    additional_classification_uri text,
    unit_uri text,
    geo_lat double precision,
    geo_lon double precision,
    geo_bbox_min_lat double precision,
    geo_bbox_max_lat double precision,
    geo_bbox_min_lon double precision,
    geo_bbox_max_lon double precision,
    geo_geojson jsonb,
    CONSTRAINT items_parent_check CHECK (((((((release_id IS NOT NULL))::integer + ((tender_id IS NOT NULL))::integer) + ((award_id IS NOT NULL))::integer) + ((contract_id IS NOT NULL))::integer) = 1))
);


--
-- Name: COLUMN items.geo_geojson; Type: COMMENT; Schema: ocds; Owner: -
--

COMMENT ON COLUMN ocds.items.geo_geojson IS 'GeoJSON geometry (Polygon/LineString) from Nominatim polygon_geojson response.';


--
-- Name: milestones; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.milestones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tender_id uuid,
    contract_id uuid,
    milestone_id character varying(100) NOT NULL,
    title text,
    milestone_type character varying(100),
    description text,
    code character varying(50),
    due_date timestamp with time zone,
    date_met timestamp with time zone,
    date_modified timestamp with time zone,
    status character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    release_id uuid,
    CONSTRAINT milestones_parent_check CHECK ((((((release_id IS NOT NULL))::integer + ((tender_id IS NOT NULL))::integer) + ((contract_id IS NOT NULL))::integer) = 1))
);


--
-- Name: ocid_summary; Type: VIEW; Schema: ocds; Owner: -
--

CREATE VIEW ocds.ocid_summary AS
 WITH release_tags AS (
         SELECT expanded.ocid,
            array_agg(DISTINCT expanded.tag_item ORDER BY expanded.tag_item) AS all_tags
           FROM ( SELECT releases.ocid,
                    unnest(releases.tag) AS tag_item
                   FROM ocds.releases) expanded
          GROUP BY expanded.ocid
        )
 SELECT r.ocid,
    count(DISTINCT r.id) AS release_count,
    min(r.date) AS first_release_date,
    max(r.date) AS last_release_date,
    rt.all_tags
   FROM (ocds.releases r
     LEFT JOIN release_tags rt ON (((rt.ocid)::text = (r.ocid)::text)))
  GROUP BY r.ocid, rt.all_tags;


--
-- Name: parties; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.parties (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    party_id character varying(255) NOT NULL,
    name text NOT NULL,
    identifier_scheme character varying

... [OUTPUT TRUNCATED - 4478 chars omitted out of 54478 total] ...

 ((t.release_id = r.id)))
     LEFT JOIN award_summary a ON ((a.release_id = r.id)))
     LEFT JOIN contract_summary c ON ((c.release_id = r.id)))
  ORDER BY r.ocid, r.date;


--
-- Name: tender_tenderers; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.tender_tenderers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tender_id uuid NOT NULL,
    party_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transformation_log; Type: TABLE; Schema: ocds; Owner: -
--

CREATE TABLE ocds.transformation_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_system character varying(50) NOT NULL,
    source_id character varying(100) NOT NULL,
    release_id uuid,
    status character varying(50) NOT NULL,
    error_message text,
    source_updated_at timestamp with time zone,
    transformed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT transformation_log_status_check CHECK (((status)::text = ANY ((ARRAY['success'::character varying, 'error'::character varying, 'skipped'::character varying])::text[])))
);


--
-- Name: amendments amendments_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.amendments
    ADD CONSTRAINT amendments_pkey PRIMARY KEY (id);


--
-- Name: award_suppliers award_suppliers_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.award_suppliers
    ADD CONSTRAINT award_suppliers_pkey PRIMARY KEY (id);


--
-- Name: award_suppliers award_suppliers_unique; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.award_suppliers
    ADD CONSTRAINT award_suppliers_unique UNIQUE (award_id, party_id);


--
-- Name: awards awards_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.awards
    ADD CONSTRAINT awards_pkey PRIMARY KEY (id);


--
-- Name: awards awards_release_award_key; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.awards
    ADD CONSTRAINT awards_release_award_key UNIQUE (release_id, award_id);


--
-- Name: bids bids_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.bids
    ADD CONSTRAINT bids_pkey PRIMARY KEY (id);


--
-- Name: contract_implementation_documents contract_implementation_documents_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_documents
    ADD CONSTRAINT contract_implementation_documents_pkey PRIMARY KEY (id);


--
-- Name: contract_implementation_milestones contract_implementation_milestones_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_milestones
    ADD CONSTRAINT contract_implementation_milestones_pkey PRIMARY KEY (id);


--
-- Name: contract_implementation contract_implementation_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation
    ADD CONSTRAINT contract_implementation_pkey PRIMARY KEY (id);


--
-- Name: contract_implementation_transactions contract_implementation_transactions_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_transactions
    ADD CONSTRAINT contract_implementation_transactions_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_release_contract_key; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contracts
    ADD CONSTRAINT contracts_release_contract_key UNIQUE (release_id, contract_id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: milestones milestones_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.milestones
    ADD CONSTRAINT milestones_pkey PRIMARY KEY (id);


--
-- Name: parties parties_party_id_key; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.parties
    ADD CONSTRAINT parties_party_id_key UNIQUE (party_id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (id);


--
-- Name: planning planning_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (id);


--
-- Name: planning planning_release_id_key; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.planning
    ADD CONSTRAINT planning_release_id_key UNIQUE (release_id);


--
-- Name: related_processes related_processes_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.related_processes
    ADD CONSTRAINT related_processes_pkey PRIMARY KEY (id);


--
-- Name: releases releases_ocid_release_id_key; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.releases
    ADD CONSTRAINT releases_ocid_release_id_key UNIQUE (ocid, release_id);


--
-- Name: releases releases_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);


--
-- Name: tender tender_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender
    ADD CONSTRAINT tender_pkey PRIMARY KEY (id);


--
-- Name: tender tender_release_id_key; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender
    ADD CONSTRAINT tender_release_id_key UNIQUE (release_id);


--
-- Name: tender_tenderers tender_tenderers_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender_tenderers
    ADD CONSTRAINT tender_tenderers_pkey PRIMARY KEY (id);


--
-- Name: tender_tenderers tender_tenderers_unique; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender_tenderers
    ADD CONSTRAINT tender_tenderers_unique UNIQUE (tender_id, party_id);


--
-- Name: transformation_log transformation_log_pkey; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.transformation_log
    ADD CONSTRAINT transformation_log_pkey PRIMARY KEY (id);


--
-- Name: transformation_log transformation_log_source_release_key; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.transformation_log
    ADD CONSTRAINT transformation_log_source_release_key UNIQUE (source_system, source_id, release_id);


--
-- Name: contract_implementation uq_contract_impl_contract; Type: CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation
    ADD CONSTRAINT uq_contract_impl_contract UNIQUE (contract_id);


--
-- Name: idx_amendments_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_amendments_release ON ocds.amendments USING btree (release_id);


--
-- Name: idx_award_suppliers_award; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_award_suppliers_award ON ocds.award_suppliers USING btree (award_id);


--
-- Name: idx_award_suppliers_party; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_award_suppliers_party ON ocds.award_suppliers USING btree (party_id);


--
-- Name: idx_award_suppliers_party_award; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_award_suppliers_party_award ON ocds.award_suppliers USING btree (party_id, award_id);


--
-- Name: idx_awards_date; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_awards_date ON ocds.awards USING btree (date DESC);


--
-- Name: idx_awards_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_awards_release ON ocds.awards USING btree (release_id);


--
-- Name: idx_awards_release_value_active; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_awards_release_value_active ON ocds.awards USING btree (release_id, value_amount DESC) WHERE ((status)::text = 'active'::text);


--
-- Name: idx_awards_value; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_awards_value ON ocds.awards USING btree (value_amount);


--
-- Name: idx_bids_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_bids_release ON ocds.bids USING btree (release_id);


--
-- Name: idx_bids_tenderer; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_bids_tenderer ON ocds.bids USING btree (tenderer_id);


--
-- Name: idx_contract_impl_doc_impl; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_contract_impl_doc_impl ON ocds.contract_implementation_documents USING btree (implementation_id);


--
-- Name: idx_contract_impl_ms_impl; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_contract_impl_ms_impl ON ocds.contract_implementation_milestones USING btree (implementation_id);


--
-- Name: idx_contract_impl_txn_impl; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_contract_impl_txn_impl ON ocds.contract_implementation_transactions USING btree (implementation_id);


--
-- Name: idx_contracts_award; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_contracts_award ON ocds.contracts USING btree (award_id);


--
-- Name: idx_contracts_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_contracts_release ON ocds.contracts USING btree (release_id);


--
-- Name: idx_contracts_value; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_contracts_value ON ocds.contracts USING btree (value_amount);


--
-- Name: idx_documents_award; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_documents_award ON ocds.documents USING btree (award_id) WHERE (award_id IS NOT NULL);


--
-- Name: idx_documents_contract; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_documents_contract ON ocds.documents USING btree (contract_id) WHERE (contract_id IS NOT NULL);


--
-- Name: idx_documents_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_documents_release ON ocds.documents USING btree (release_id) WHERE (release_id IS NOT NULL);


--
-- Name: idx_documents_tender; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_documents_tender ON ocds.documents USING btree (tender_id) WHERE (tender_id IS NOT NULL);


--
-- Name: idx_documents_type; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_documents_type ON ocds.documents USING btree (document_type);


--
-- Name: idx_items_award; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_items_award ON ocds.items USING btree (award_id) WHERE (award_id IS NOT NULL);


--
-- Name: idx_items_classification; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_items_classification ON ocds.items USING btree (classification_scheme, classification_id);


--
-- Name: idx_items_contract; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_items_contract ON ocds.items USING btree (contract_id) WHERE (contract_id IS NOT NULL);


--
-- Name: idx_items_geolocation; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_items_geolocation ON ocds.items USING btree (geo_lat, geo_lon);


--
-- Name: idx_items_tender; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_items_tender ON ocds.items USING btree (tender_id) WHERE (tender_id IS NOT NULL);


--
-- Name: idx_milestones_contract; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_milestones_contract ON ocds.milestones USING btree (contract_id) WHERE (contract_id IS NOT NULL);


--
-- Name: idx_milestones_tender; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_milestones_tender ON ocds.milestones USING btree (tender_id) WHERE (tender_id IS NOT NULL);


--
-- Name: idx_parties_actor_id; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_parties_actor_id ON ocds.parties USING btree (actor_id) WHERE (actor_id IS NOT NULL);


--
-- Name: idx_parties_geolocation; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_parties_geolocation ON ocds.parties USING btree (geo_lat, geo_lon);


--
-- Name: idx_parties_identifier; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_parties_identifier ON ocds.parties USING btree (identifier_scheme, identifier_id);


--
-- Name: idx_parties_name; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_parties_name ON ocds.parties USING gin (name public.gin_trgm_ops);


--
-- Name: idx_parties_name_normalized; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_parties_name_normalized ON ocds.parties USING btree (lower(regexp_replace(name, '[^a-zA-Z0-9]'::text, ''::text, 'g'::text)));


--
-- Name: idx_parties_roles; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_parties_roles ON ocds.parties USING gin (roles);


--
-- Name: idx_planning_budget_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_planning_budget_release ON ocds.planning USING btree (budget_amount, release_id) WHERE ((budget_amount IS NOT NULL) AND (budget_amount > (0)::numeric));


--
-- Name: idx_planning_fiscal_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_planning_fiscal_release ON ocds.planning USING btree (fiscal_year, release_id);


--
-- Name: idx_planning_fiscal_year; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_planning_fiscal_year ON ocds.planning USING btree (fiscal_year);


--
-- Name: idx_planning_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_planning_release ON ocds.planning USING btree (release_id);


--
-- Name: idx_planning_rup; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_planning_rup ON ocds.planning USING btree (rup_id);


--
-- Name: idx_planning_rup_codes; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_planning_rup_codes ON ocds.planning USING gin (rup_codes);


--
-- Name: idx_related_processes_identifier; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_related_processes_identifier ON ocds.related_processes USING btree (identifier);


--
-- Name: idx_related_processes_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_related_processes_release ON ocds.related_processes USING btree (release_id);


--
-- Name: idx_related_processes_release_identifier; Type: INDEX; Schema: ocds; Owner: -
--

CREATE UNIQUE INDEX idx_related_processes_release_identifier ON ocds.related_processes USING btree (release_id, identifier);


--
-- Name: idx_releases_buyer_id; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_buyer_id ON ocds.releases USING btree (buyer_id) WHERE (buyer_id IS NOT NULL);


--
-- Name: idx_releases_date; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_date ON ocds.releases USING btree (date DESC);


--
-- Name: idx_releases_event_id; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_event_id ON ocds.releases USING btree (event_id) WHERE (event_id IS NOT NULL);


--
-- Name: idx_releases_ocid; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_ocid ON ocds.releases USING btree (ocid);


--
-- Name: idx_releases_ocid_date; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_ocid_date ON ocds.releases USING btree (ocid, date DESC);


--
-- Name: idx_releases_source; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_source ON ocds.releases USING btree (source_system, source_id);


--
-- Name: idx_releases_source_date; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_source_date ON ocds.releases USING btree (source_system, source_id, date DESC);


--
-- Name: idx_releases_tag; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_tag ON ocds.releases USING gin (tag);


--
-- Name: idx_releases_updated_at_id; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_releases_updated_at_id ON ocds.releases USING btree (updated_at, id);


--
-- Name: idx_tender_geolocation; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_geolocation ON ocds.tender USING btree (geo_lat, geo_lon);


--
-- Name: idx_tender_method_category; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_method_category ON ocds.tender USING btree (procurement_method, main_procurement_category) WHERE ((status)::text = 'active'::text);


--
-- Name: idx_tender_period_start_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_period_start_release ON ocds.tender USING btree (tender_period_start_date, release_id) WHERE (tender_period_start_date IS NOT NULL);


--
-- Name: idx_tender_procuring_entity_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_procuring_entity_release ON ocds.tender USING btree (procuring_entity_id, release_id) WHERE ((status IS NULL) OR ((status)::text <> ALL ((ARRAY['cancelled'::character varying, 'withdrawn'::character varying])::text[])));


--
-- Name: idx_tender_release; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_release ON ocds.tender USING btree (release_id);


--
-- Name: idx_tender_rup_codes; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_rup_codes ON ocds.tender USING gin (rup_codes);


--
-- Name: idx_tender_tenderers_party; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_tenderers_party ON ocds.tender_tenderers USING btree (party_id);


--
-- Name: idx_tender_tenderers_tender; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_tenderers_tender ON ocds.tender_tenderers USING btree (tender_id);


--
-- Name: idx_tender_title; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_title ON ocds.tender USING gin (title public.gin_trgm_ops);


--
-- Name: idx_tender_value; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_tender_value ON ocds.tender USING btree (value_amount);


--
-- Name: idx_transformation_log_dedup; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_transformation_log_dedup ON ocds.transformation_log USING btree (source_system, source_id, source_updated_at) WHERE ((status)::text = 'success'::text);


--
-- Name: idx_transformation_log_latest; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_transformation_log_latest ON ocds.transformation_log USING btree (source_system, source_id, transformed_at DESC);


--
-- Name: idx_transformation_log_source; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_transformation_log_source ON ocds.transformation_log USING btree (source_system, source_id);


--
-- Name: idx_transformation_log_source_releases; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_transformation_log_source_releases ON ocds.transformation_log USING btree (source_system, source_id, release_id);


--
-- Name: idx_transformation_log_status; Type: INDEX; Schema: ocds; Owner: -
--

CREATE INDEX idx_transformation_log_status ON ocds.transformation_log USING btree (status);


--
-- Name: releases enforce_release_immutability; Type: TRIGGER; Schema: ocds; Owner: -
--

CREATE TRIGGER enforce_release_immutability BEFORE DELETE ON ocds.releases FOR EACH ROW EXECUTE FUNCTION ocds.prevent_release_delete();


--
-- Name: awards update_awards_updated_at; Type: TRIGGER; Schema: ocds; Owner: -
--

CREATE TRIGGER update_awards_updated_at BEFORE UPDATE ON ocds.awards FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();


--
-- Name: contracts update_contracts_updated_at; Type: TRIGGER; Schema: ocds; Owner: -
--

CREATE TRIGGER update_contracts_updated_at BEFORE UPDATE ON ocds.contracts FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();


--
-- Name: parties update_parties_updated_at; Type: TRIGGER; Schema: ocds; Owner: -
--

CREATE TRIGGER update_parties_updated_at BEFORE UPDATE ON ocds.parties FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();


--
-- Name: planning update_planning_updated_at; Type: TRIGGER; Schema: ocds; Owner: -
--

CREATE TRIGGER update_planning_updated_at BEFORE UPDATE ON ocds.planning FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();


--
-- Name: releases update_releases_updated_at; Type: TRIGGER; Schema: ocds; Owner: -
--

CREATE TRIGGER update_releases_updated_at BEFORE UPDATE ON ocds.releases FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();


--
-- Name: tender update_tender_updated_at; Type: TRIGGER; Schema: ocds; Owner: -
--

CREATE TRIGGER update_tender_updated_at BEFORE UPDATE ON ocds.tender FOR EACH ROW EXECUTE FUNCTION ocds.update_updated_at_column();


--
-- Name: amendments amendments_award_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.amendments
    ADD CONSTRAINT amendments_award_id_fkey FOREIGN KEY (award_id) REFERENCES ocds.awards(id) ON DELETE CASCADE;


--
-- Name: amendments amendments_contract_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.amendments
    ADD CONSTRAINT amendments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES ocds.contracts(id) ON DELETE CASCADE;


--
-- Name: amendments amendments_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.amendments
    ADD CONSTRAINT amendments_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: amendments amendments_tender_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.amendments
    ADD CONSTRAINT amendments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES ocds.tender(id) ON DELETE CASCADE;


--
-- Name: award_suppliers award_suppliers_award_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.award_suppliers
    ADD CONSTRAINT award_suppliers_award_id_fkey FOREIGN KEY (award_id) REFERENCES ocds.awards(id) ON DELETE CASCADE;


--
-- Name: award_suppliers award_suppliers_party_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.award_suppliers
    ADD CONSTRAINT award_suppliers_party_id_fkey FOREIGN KEY (party_id) REFERENCES ocds.parties(id);


--
-- Name: awards awards_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.awards
    ADD CONSTRAINT awards_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: bids bids_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.bids
    ADD CONSTRAINT bids_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: bids bids_tenderer_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.bids
    ADD CONSTRAINT bids_tenderer_id_fkey FOREIGN KEY (tenderer_id) REFERENCES ocds.parties(id);


--
-- Name: contract_implementation contract_implementation_contract_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation
    ADD CONSTRAINT contract_implementation_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES ocds.contracts(id) ON DELETE CASCADE;


--
-- Name: contract_implementation_documents contract_implementation_documents_implementation_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_documents
    ADD CONSTRAINT contract_implementation_documents_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES ocds.contract_implementation(id) ON DELETE CASCADE;


--
-- Name: contract_implementation_milestones contract_implementation_milestones_implementation_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_milestones
    ADD CONSTRAINT contract_implementation_milestones_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES ocds.contract_implementation(id) ON DELETE CASCADE;


--
-- Name: contract_implementation_transactions contract_implementation_transactions_implementation_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_transactions
    ADD CONSTRAINT contract_implementation_transactions_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES ocds.contract_implementation(id) ON DELETE CASCADE;


--
-- Name: contract_implementation_transactions contract_implementation_transactions_payee_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_transactions
    ADD CONSTRAINT contract_implementation_transactions_payee_id_fkey FOREIGN KEY (payee_id) REFERENCES ocds.parties(id);


--
-- Name: contract_implementation_transactions contract_implementation_transactions_payer_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contract_implementation_transactions
    ADD CONSTRAINT contract_implementation_transactions_payer_id_fkey FOREIGN KEY (payer_id) REFERENCES ocds.parties(id);


--
-- Name: contracts contracts_award_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contracts
    ADD CONSTRAINT contracts_award_id_fkey FOREIGN KEY (award_id) REFERENCES ocds.awards(id);


--
-- Name: contracts contracts_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.contracts
    ADD CONSTRAINT contracts_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: documents documents_award_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.documents
    ADD CONSTRAINT documents_award_id_fkey FOREIGN KEY (award_id) REFERENCES ocds.awards(id) ON DELETE CASCADE;


--
-- Name: documents documents_contract_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.documents
    ADD CONSTRAINT documents_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES ocds.contracts(id) ON DELETE CASCADE;


--
-- Name: documents documents_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.documents
    ADD CONSTRAINT documents_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: documents documents_tender_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.documents
    ADD CONSTRAINT documents_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES ocds.tender(id) ON DELETE CASCADE;


--
-- Name: items items_award_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.items
    ADD CONSTRAINT items_award_id_fkey FOREIGN KEY (award_id) REFERENCES ocds.awards(id) ON DELETE CASCADE;


--
-- Name: items items_contract_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.items
    ADD CONSTRAINT items_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES ocds.contracts(id) ON DELETE CASCADE;


--
-- Name: items items_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.items
    ADD CONSTRAINT items_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: items items_tender_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.items
    ADD CONSTRAINT items_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES ocds.tender(id) ON DELETE CASCADE;


--
-- Name: milestones milestones_contract_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.milestones
    ADD CONSTRAINT milestones_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES ocds.contracts(id) ON DELETE CASCADE;


--
-- Name: milestones milestones_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.milestones
    ADD CONSTRAINT milestones_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: milestones milestones_tender_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.milestones
    ADD CONSTRAINT milestones_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES ocds.tender(id) ON DELETE CASCADE;


--
-- Name: planning planning_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.planning
    ADD CONSTRAINT planning_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: related_processes related_processes_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.related_processes
    ADD CONSTRAINT related_processes_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: releases releases_buyer_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.releases
    ADD CONSTRAINT releases_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES ocds.parties(id) ON DELETE SET NULL;


--
-- Name: tender tender_procuring_entity_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender
    ADD CONSTRAINT tender_procuring_entity_id_fkey FOREIGN KEY (procuring_entity_id) REFERENCES ocds.parties(id) ON DELETE SET NULL;


--
-- Name: tender tender_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender
    ADD CONSTRAINT tender_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE CASCADE;


--
-- Name: tender_tenderers tender_tenderers_party_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender_tenderers
    ADD CONSTRAINT tender_tenderers_party_id_fkey FOREIGN KEY (party_id) REFERENCES ocds.parties(id);


--
-- Name: tender_tenderers tender_tenderers_tender_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.tender_tenderers
    ADD CONSTRAINT tender_tenderers_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES ocds.tender(id) ON DELETE CASCADE;


--
-- Name: transformation_log transformation_log_release_id_fkey; Type: FK CONSTRAINT; Schema: ocds; Owner: -
--

ALTER TABLE ONLY ocds.transformation_log
    ADD CONSTRAINT transformation_log_release_id_fkey FOREIGN KEY (release_id) REFERENCES ocds.releases(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--