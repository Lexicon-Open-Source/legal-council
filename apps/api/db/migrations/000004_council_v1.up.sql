-- Schema: council_v1
-- AI Deliberation system for legal case analysis

CREATE SCHEMA IF NOT EXISTS council_v1;

-- Deliberation Sessions: AI deliberation sessions for case analysis
CREATE TABLE council_v1.deliberation_sessions (
    id VARCHAR NOT NULL,
    user_id VARCHAR,
    status VARCHAR NOT NULL DEFAULT 'active',
    case_input JSONB NOT NULL,
    similar_cases JSONB NOT NULL DEFAULT '[]'::jsonb,
    legal_opinion JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    concluded_at TIMESTAMPTZ,
    CONSTRAINT deliberation_sessions_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_deliberation_sessions_user_id ON council_v1.deliberation_sessions USING btree (user_id);
CREATE INDEX idx_deliberation_sessions_status ON council_v1.deliberation_sessions USING btree (status);
CREATE INDEX idx_deliberation_sessions_created_at ON council_v1.deliberation_sessions USING btree (created_at DESC);

-- Deliberation Messages: Individual messages in a deliberation session
CREATE TABLE council_v1.deliberation_messages (
    id VARCHAR NOT NULL,
    session_id VARCHAR NOT NULL,
    sender JSONB NOT NULL,
    content TEXT NOT NULL,
    intent VARCHAR,
    cited_cases JSONB NOT NULL DEFAULT '[]'::jsonb,
    cited_laws JSONB NOT NULL DEFAULT '[]'::jsonb,
    sequence_number INTEGER NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT deliberation_messages_pkey PRIMARY KEY (id),
    CONSTRAINT deliberation_messages_session_id_fkey FOREIGN KEY (session_id)
        REFERENCES council_v1.deliberation_sessions(id) ON DELETE CASCADE
);

CREATE INDEX idx_deliberation_messages_session_id ON council_v1.deliberation_messages USING btree (session_id);
CREATE INDEX idx_deliberation_messages_session_sequence ON council_v1.deliberation_messages USING btree (session_id, sequence_number);
