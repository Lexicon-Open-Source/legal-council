DROP INDEX IF EXISTS council_v1.idx_deliberation_sessions_current_phase;

ALTER TABLE council_v1.deliberation_sessions
    DROP COLUMN IF EXISTS structured_summary,
    DROP COLUMN IF EXISTS phase_metadata,
    DROP COLUMN IF EXISTS current_phase;
