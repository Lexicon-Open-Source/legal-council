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
-- Name: cms; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cms;


--
-- Name: SCHEMA cms; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA cms IS 'Content management system tables for admin-managed website content.';


--
-- Name: array_to_text_immutable(text[]); Type: FUNCTION; Schema: cms; Owner: -
--

CREATE FUNCTION cms.array_to_text_immutable(arr text[]) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT array_to_string(arr, ' ')
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: files; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.files (
    id text NOT NULL,
    filename text NOT NULL,
    original_filename text NOT NULL,
    mime_type text NOT NULL,
    file_size bigint DEFAULT 0 NOT NULL,
    s3_key text NOT NULL,
    category text DEFAULT 'other'::text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'published'::text NOT NULL,
    published_at timestamp with time zone DEFAULT now(),
    created_by text DEFAULT ''::text NOT NULL,
    updated_by text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    title text DEFAULT ''::text NOT NULL,
    alt_text text DEFAULT ''::text NOT NULL,
    public_url text DEFAULT ''::text NOT NULL,
    upload_status text DEFAULT 'confirmed'::text NOT NULL,
    CONSTRAINT files_category_check CHECK ((category = ANY (ARRAY['document'::text, 'image'::text, 'training_material'::text, 'other'::text]))),
    CONSTRAINT files_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text]))),
    CONSTRAINT files_upload_status_check CHECK ((upload_status = ANY (ARRAY['pending'::text, 'confirmed'::text])))
);


--
-- Name: TABLE files; Type: COMMENT; Schema: cms; Owner: -
--

COMMENT ON TABLE cms.files IS 'Uploaded files for the file manager (documents, images, training materials)';


--
-- Name: pages; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.pages (
    id text NOT NULL,
    title text NOT NULL,
    title_en text DEFAULT ''::text NOT NULL,
    slug text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_en jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_plain text DEFAULT ''::text NOT NULL,
    content_plain_en text DEFAULT ''::text NOT NULL,
    page_type text DEFAULT 'custom'::text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    published_at timestamp with time zone,
    created_by text DEFAULT ''::text NOT NULL,
    updated_by text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT pages_page_type_check CHECK ((page_type = ANY (ARRAY['profile'::text, 'vision_mission'::text, 'about'::text, 'contact'::text, 'custom'::text]))),
    CONSTRAINT pages_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text])))
);


--
-- Name: TABLE pages; Type: COMMENT; Schema: cms; Owner: -
--

COMMENT ON TABLE cms.pages IS 'Static pages for the website (company profile, vision/mission, etc.)';


--
-- Name: posts; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.posts (
    id text NOT NULL,
    title text NOT NULL,
    title_en text DEFAULT ''::text NOT NULL,
    slug text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_en jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_plain text DEFAULT ''::text NOT NULL,
    content_plain_en text DEFAULT ''::text NOT NULL,
    excerpt text DEFAULT ''::text NOT NULL,
    cover_image_url text DEFAULT ''::text NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    published_at timestamp with time zone,
    created_by text DEFAULT ''::text NOT NULL,
    updated_by text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    tags_text text GENERATED ALWAYS AS (cms.array_to_text_immutable(tags)) STORED,
    CONSTRAINT posts_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text])))
);


--
-- Name: TABLE posts; Type: COMMENT; Schema: cms; Owner: -
--

COMMENT ON TABLE cms.posts IS 'Blog posts and news articles';


--
-- Name: projects; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.projects (
    id text NOT NULL,
    title text NOT NULL,
    title_en text DEFAULT ''::text NOT NULL,
    slug text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_en jsonb DEFAULT '{}'::jsonb NOT NULL,
    content_plain text DEFAULT ''::text NOT NULL,
    content_plain_en text DEFAULT ''::text NOT NULL,
    summary text DEFAULT ''::text NOT NULL,
    cover_image_url text DEFAULT ''::text NOT NULL,
    client_name text DEFAULT ''::text NOT NULL,
    project_date date,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_featured boolean DEFAULT false NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    published_at timestamp with time zone,
    created_by text DEFAULT ''::text NOT NULL,
    updated_by text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT projects_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text])))
);


--
-- Name: TABLE projects; Type: COMMENT; Schema: cms; Owner: -
--

COMMENT ON TABLE cms.projects IS 'Project and product portfolio entries';


--
-- Name: reviews; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.reviews (
    id text NOT NULL,
    client_name text NOT NULL,
    client_title text DEFAULT ''::text NOT NULL,
    client_company text DEFAULT ''::text NOT NULL,
    client_avatar_url text DEFAULT ''::text NOT NULL,
    testimonial text DEFAULT ''::text NOT NULL,
    rating integer DEFAULT 5 NOT NULL,
    is_featured boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    published_at timestamp with time zone,
    created_by text DEFAULT ''::text NOT NULL,
    updated_by text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5))),
    CONSTRAINT reviews_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text])))
);


--
-- Name: TABLE reviews; Type: COMMENT; Schema: cms; Owner: -
--

COMMENT ON TABLE cms.reviews IS 'Client testimonials and reviews';


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: idx_cms_files_category; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_files_category ON cms.files USING btree (category) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_files_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_files_status ON cms.files USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_files_upload_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_files_upload_status ON cms.files USING btree (upload_status) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_pages_fts; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_fts ON cms.pages USING gin (to_tsvector('simple'::regconfig, content_plain));


--
-- Name: idx_cms_pages_fts_en; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_fts_en ON cms.pages USING gin (to_tsvector('simple'::regconfig, content_plain_en));


--
-- Name: idx_cms_pages_slug; Type: INDEX; Schema: cms; Owner: -
--

CREATE UNIQUE INDEX idx_cms_pages_slug ON cms.pages USING btree (slug) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_pages_sort_order; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_sort_order ON cms.pages USING btree (sort_order);


--
-- Name: idx_cms_pages_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_status ON cms.pages USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_posts_bm25; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_bm25 ON cms.posts USING bm25 (id, title, title_en, content_plain, content_plain_en, excerpt, tags_text) WITH (key_field=id);


--
-- Name: idx_cms_posts_fts; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_fts ON cms.posts USING gin (to_tsvector('simple'::regconfig, content_plain));


--
-- Name: idx_cms_posts_fts_en; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_fts_en ON cms.posts USING gin (to_tsvector('simple'::regconfig, content_plain_en));


--
-- Name: idx_cms_posts_published_at; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_published_at ON cms.posts USING btree (published_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_posts_slug; Type: INDEX; Schema: cms; Owner: -
--

CREATE UNIQUE INDEX idx_cms_posts_slug ON cms.posts USING btree (slug) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_posts_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_status ON cms.posts USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_posts_tags; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_tags ON cms.posts USING gin (tags);


--
-- Name: idx_cms_projects_featured; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_projects_featured ON cms.projects USING btree (is_featured) WHERE ((deleted_at IS NULL) AND (status = 'published'::text));


--
-- Name: idx_cms_projects_fts; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_projects_fts ON cms.projects USING gin (to_tsvector('simple'::regconfig, content_plain));


--
-- Name: idx_cms_projects_fts_en; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_projects_fts_en ON cms.projects USING gin (to_tsvector('simple'::regconfig, content_plain_en));


--
-- Name: idx_cms_projects_slug; Type: INDEX; Schema: cms; Owner: -
--

CREATE UNIQUE INDEX idx_cms_projects_slug ON cms.projects USING btree (slug) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_projects_sort_order; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_projects_sort_order ON cms.projects USING btree (sort_order);


--
-- Name: idx_cms_projects_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_projects_status ON cms.projects USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_cms_projects_tags; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_projects_tags ON cms.projects USING gin (tags);


--
-- Name: idx_cms_reviews_featured; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_reviews_featured ON cms.reviews USING btree (is_featured) WHERE ((deleted_at IS NULL) AND (status = 'published'::text));


--
-- Name: idx_cms_reviews_sort_order; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_reviews_sort_order ON cms.reviews USING btree (sort_order);


--
-- Name: idx_cms_reviews_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_reviews_status ON cms.reviews USING btree (status) WHERE (deleted_at IS NULL);


--
-- PostgreSQL database dump complete
--