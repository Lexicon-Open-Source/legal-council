-- Add deliberation phase columns to council_v1.deliberation_sessions
-- Supports phased deliberation workflow (legacy, analysis, opinion, summary).

ALTER TABLE council_v1.deliberation_sessions
    ADD COLUMN current_phase VARCHAR NOT NULL DEFAULT 'legacy',
    ADD COLUMN phase_metadata JSONB NOT NULL DEFAULT '{}',
    ADD COLUMN structured_summary JSONB;

CREATE INDEX idx_deliberation_sessions_current_phase
    ON council_v1.deliberation_sessions (current_phase);
