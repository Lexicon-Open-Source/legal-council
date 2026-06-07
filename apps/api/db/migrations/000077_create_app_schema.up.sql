-- migrations/000077_create_app_schema.up.sql
--
-- Phase 1: Foundation
-- Document tier assignments on all existing schemas, then create the app schema.
-- Auth tables (users, password_reset_tokens, personal_access_tokens) are NOT created —
-- authentication is handled by Authentik (OIDC/OAuth2).
--
-- See: docs/plans/2026-03-01-refactor-l1-l2-l3-data-layer-architecture-plan.md

-- ============================================================
-- 1. COMMENT ON SCHEMA — tier documentation
-- ============================================================

-- L1 (Bronze): Raw ingestion layer
COMMENT ON SCHEMA crawler IS 'L1 (Bronze): Raw scraped data from external sources. Upsert on natural keys, no cross-source normalization.';

-- L1.5 (Enrichment): LLM-derived, validation-gated
COMMENT ON SCHEMA llm_extraction IS 'L1.5 (Enrichment): LLM extraction results. Derived from L1, validation-gated via status column (pending → extracted → summarized → completed → failed).';

-- L2 (Silver): Domain-specific normalized data
COMMENT ON SCHEMA ocds IS 'L2 (Silver): OCDS-normalized procurement data. Flat tabular design with immutable release pattern.';
COMMENT ON SCHEMA entity_graph IS 'L2 (Silver): Normalized entity graph. POLE model (actors, events), content-addressed dedup, soft merge for entity resolution.';

-- Deprecated schemas (marked for removal in separate plan)
COMMENT ON SCHEMA bo_v1 IS 'DEPRECATED: Migrating to app schema. Contains users, cases, auth tokens. Will be dropped after Go backend migration.';
COMMENT ON SCHEMA council_v1 IS 'DEPRECATED: Migrating to app schema. Contains deliberation sessions/messages. Will be dropped after Go backend migration.';
COMMENT ON SCHEMA bo_crawler_v1 IS 'DEPRECATED: Data migrated to llm_extraction. Will be dropped.';

-- ============================================================
-- 2. CREATE app schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS app;
COMMENT ON SCHEMA app IS 'App: User-generated state. Cases, deliberations. Auth handled by Authentik (OIDC). Replaces bo_v1 + council_v1.';

-- ============================================================
-- User Profiles (app-specific data not in Authentik)
-- ============================================================

CREATE TABLE app.user_profiles (
    authentik_sub TEXT NOT NULL,
    display_name TEXT,
    preferences JSONB DEFAULT '{}'::JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT user_profiles_pkey PRIMARY KEY (authentik_sub)
);

COMMENT ON TABLE app.user_profiles IS 'App-specific user data keyed by Authentik subject ID. Auth (name, email, password, 2FA) lives in Authentik. This stores preferences and display settings only.';

-- ============================================================
-- Cases (from bo_v1.cases)
-- ============================================================

CREATE TABLE app.cases (
    id VARCHAR(26) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    subject_type SMALLINT NOT NULL,
    person_in_charge VARCHAR(255),
    beneficial_ownership TEXT,
    case_date DATE,
    decision_number TEXT,
    source VARCHAR(255),
    link VARCHAR(255),
    nation VARCHAR(255),
    punishment_start DATE,
    punishment_end DATE,
    case_type SMALLINT,
    year VARCHAR(4),
    summary TEXT,
    summary_formatted TEXT,
    summary_en TEXT,
    summary_formatted_en TEXT,
    status SMALLINT DEFAULT 2,
    slug VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by TEXT,
    updated_by TEXT,
    deleted_by TEXT,
    deleted_at TIMESTAMPTZ,
    extra_data JSONB,
    subject_normalized TEXT,
    CONSTRAINT cases_pkey PRIMARY KEY (id)
);

COMMENT ON TABLE app.cases IS 'Cases migrated from bo_v1.cases. Primary user-facing content table. Auth columns (created_by, updated_by, deleted_by) are TEXT — old ULIDs preserved, new writes use Authentik subject IDs.';

-- NOTE: Indexes on app.cases are DEFERRED to migration 000078 (after bulk data load)
-- to avoid O(n * log n) per-row index updates during INSERT...SELECT.
-- See plan issue #7.

-- NOTE: fulltext_search_index TSVECTOR column, GIN index, and trigger intentionally
-- NOT migrated from bo_v1.cases. Full-text search will be handled by a hybrid RAG
-- layer (ParadeDB BM25 + pgvector) in a dedicated plan.

-- ============================================================
-- Draft Cases (from bo_v1.draft_cases)
-- ============================================================

CREATE TABLE app.draft_cases (
    id CHARACTER(26) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    subject_type SMALLINT NOT NULL,
    person_in_charge VARCHAR(255),
    beneficial_ownership VARCHAR(255),
    case_date DATE NOT NULL,
    decision_number TEXT NOT NULL,
    source VARCHAR(255) NOT NULL,
    link VARCHAR(255) NOT NULL,
    nation VARCHAR(255) NOT NULL,
    punishment_start DATE,
    punishment_end DATE,
    type SMALLINT NOT NULL,
    year VARCHAR(4) NOT NULL,
    summary TEXT,
    summary_formatted TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    summary_en TEXT,
    summary_formatted_en TEXT,
    extra_data JSONB,
    CONSTRAINT draft_cases_pkey PRIMARY KEY (id),
    CONSTRAINT draft_cases_unique UNIQUE (link)
);

CREATE INDEX idx_app_draft_cases_subject ON app.draft_cases USING btree (subject);
CREATE INDEX idx_app_draft_cases_subject_type ON app.draft_cases USING btree (subject_type);
CREATE INDEX idx_app_draft_cases_year ON app.draft_cases USING btree (year);

COMMENT ON TABLE app.draft_cases IS 'Draft cases pending review/approval. Migrated from bo_v1.draft_cases.';

-- ============================================================
-- Deliberation Sessions (from council_v1.deliberation_sessions)
-- ============================================================

CREATE TABLE app.deliberation_sessions (
    id VARCHAR(64) NOT NULL,
    user_id TEXT,
    status VARCHAR DEFAULT 'active' NOT NULL,
    case_input JSONB NOT NULL,
    similar_cases JSONB NOT NULL DEFAULT '[]'::JSONB,
    legal_opinion JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    concluded_at TIMESTAMPTZ,
    CONSTRAINT deliberation_sessions_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_app_deliberation_sessions_user_id ON app.deliberation_sessions USING btree (user_id);
CREATE INDEX idx_app_deliberation_sessions_status ON app.deliberation_sessions USING btree (status);
CREATE INDEX idx_app_deliberation_sessions_created_at ON app.deliberation_sessions USING btree (created_at DESC);

COMMENT ON TABLE app.deliberation_sessions IS 'AI-assisted deliberation sessions. Migrated from council_v1.deliberation_sessions. user_id is TEXT (Authentik subject or legacy ULID).';

-- ============================================================
-- Deliberation Messages (from council_v1.deliberation_messages)
-- ============================================================

CREATE TABLE app.deliberation_messages (
    id VARCHAR(64) NOT NULL,
    session_id VARCHAR NOT NULL,
    sender JSONB NOT NULL,
    content TEXT NOT NULL,
    intent VARCHAR,
    cited_cases JSONB NOT NULL DEFAULT '[]'::JSONB,
    cited_laws JSONB NOT NULL DEFAULT '[]'::JSONB,
    sequence_number INTEGER NOT NULL,
    "timestamp" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT deliberation_messages_pkey PRIMARY KEY (id),
    CONSTRAINT deliberation_messages_session_id_fkey
        FOREIGN KEY (session_id) REFERENCES app.deliberation_sessions(id) ON DELETE CASCADE
);

CREATE INDEX idx_app_deliberation_messages_session_sequence ON app.deliberation_messages USING btree (session_id, sequence_number);

COMMENT ON TABLE app.deliberation_messages IS 'Messages within deliberation sessions. Migrated from council_v1.deliberation_messages.';
