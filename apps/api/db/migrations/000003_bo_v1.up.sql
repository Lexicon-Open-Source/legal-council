-- Schema: bo_v1
-- Beneficial Ownership application - users, cases, authentication

CREATE SCHEMA IF NOT EXISTS bo_v1;

-- Users: Application users
CREATE TABLE bo_v1.users (
    id CHAR(26) NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email_verified_at TIMESTAMP,
    remember_token VARCHAR(100),
    profile_photo_path VARCHAR(2048),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    two_factor_secret TEXT,
    two_factor_recovery_codes TEXT,
    two_factor_confirmed_at TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT users_email_key UNIQUE (email)
);

-- Password Reset Tokens
CREATE TABLE bo_v1.password_reset_tokens (
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP,
    CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email)
);

-- Personal Access Tokens (API authentication)
CREATE TABLE bo_v1.personal_access_tokens (
    id INTEGER NOT NULL,
    tokenable_type VARCHAR(255) NOT NULL,
    tokenable_id CHAR(26) NOT NULL,
    name VARCHAR(255) NOT NULL,
    token VARCHAR(64) NOT NULL,
    abilities TEXT,
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id),
    CONSTRAINT personal_access_tokens_token_key UNIQUE (token)
);

CREATE INDEX idx_tokenable_id ON bo_v1.personal_access_tokens USING btree (tokenable_id);

-- Draft Cases: Cases pending review/approval
CREATE TABLE bo_v1.draft_cases (
    id CHAR(26) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    subject_type SMALLINT NOT NULL,
    person_in_charge VARCHAR(255),
    benificiary_ownership VARCHAR(255),
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    summary_en TEXT,
    summary_formatted_en TEXT,
    extra_data JSONB,
    CONSTRAINT draft_cases_pkey PRIMARY KEY (id),
    CONSTRAINT draft_cases_unique UNIQUE (link)
);

CREATE INDEX draft_cases_link_idx ON bo_v1.draft_cases USING btree (link);
CREATE INDEX idx_subject ON bo_v1.draft_cases USING btree (subject);
CREATE INDEX idx_subject_type ON bo_v1.draft_cases USING btree (subject_type);
CREATE INDEX idx_year ON bo_v1.draft_cases USING btree (year);

-- Cases: Published beneficial ownership cases
CREATE TABLE bo_v1.cases (
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
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(26),
    updated_by VARCHAR(26),
    deleted_by VARCHAR(26),
    deleted_at TIMESTAMPTZ,
    fulltext_search_index TSVECTOR,
    extra_data JSONB,
    subject_normalized TEXT,
    CONSTRAINT cases_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_search_filter ON bo_v1.cases USING btree (subject_type, year, case_type, nation, status);
CREATE INDEX idx_search_fulltext ON bo_v1.cases USING gin (fulltext_search_index);
CREATE INDEX idx_cases_subject_normalized ON bo_v1.cases USING gin (subject_normalized gin_trgm_ops) WHERE (status = 1);

-- Trigger for fulltext search index auto-update
CREATE TRIGGER cases_fulltext_search_index_update
    BEFORE INSERT OR UPDATE ON bo_v1.cases
    FOR EACH ROW
    EXECUTE FUNCTION tsvector_update_trigger('fulltext_search_index', 'pg_catalog.english', 'subject', 'summary');
