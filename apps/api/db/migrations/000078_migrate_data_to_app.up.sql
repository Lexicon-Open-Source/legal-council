-- migrations/000078_migrate_data_to_app.up.sql
--
-- Phase 2: Data Migration
-- Copy case and deliberation data from bo_v1/council_v1 into app schema.
-- Auth tables (users, password_reset_tokens, personal_access_tokens) are NOT migrated.
-- Existing created_by/updated_by/deleted_by values (old ULIDs) are preserved as
-- historical audit trail. New writes will use Authentik subject IDs.
--
-- Indexes on app.cases were deferred from 000077 — created AFTER bulk load here.

-- ============================================================
-- 1. Copy data
-- ============================================================

-- Cases (excludes fulltext_search_index TSVECTOR — not migrated)
INSERT INTO app.cases (
    id, subject, subject_type, person_in_charge, beneficial_ownership,
    case_date, decision_number, source, link, nation,
    punishment_start, punishment_end, case_type, year,
    summary, summary_formatted, summary_en, summary_formatted_en,
    status, slug, created_at, updated_at,
    created_by, updated_by, deleted_by, deleted_at,
    extra_data, subject_normalized
)
SELECT
    id, subject, subject_type, person_in_charge, beneficial_ownership,
    case_date, decision_number, source, link, nation,
    punishment_start, punishment_end, case_type, year,
    summary, summary_formatted, summary_en, summary_formatted_en,
    status, slug, created_at, updated_at,
    created_by, updated_by, deleted_by, deleted_at,
    extra_data, subject_normalized
FROM bo_v1.cases;

-- Draft Cases
INSERT INTO app.draft_cases (
    id, subject, subject_type, person_in_charge, beneficial_ownership,
    case_date, decision_number, source, link, nation,
    punishment_start, punishment_end, type, year,
    summary, summary_formatted, created_at, updated_at,
    summary_en, summary_formatted_en, extra_data
)
SELECT
    id, subject, subject_type, person_in_charge, beneficial_ownership,
    case_date, decision_number, source, link, nation,
    punishment_start, punishment_end, type, year,
    summary, summary_formatted, created_at, updated_at,
    summary_en, summary_formatted_en, extra_data
FROM bo_v1.draft_cases;

-- Deliberation Sessions (TRIM user_id: CHAR(26) → TEXT to strip trailing spaces)
INSERT INTO app.deliberation_sessions (
    id, user_id, status, case_input, similar_cases,
    legal_opinion, created_at, updated_at, concluded_at
)
SELECT
    id, NULLIF(TRIM(user_id), ''), status, case_input, similar_cases,
    legal_opinion, created_at, updated_at, concluded_at
FROM council_v1.deliberation_sessions;

-- Deliberation Messages
INSERT INTO app.deliberation_messages (
    id, session_id, sender, content, intent,
    cited_cases, cited_laws, sequence_number, "timestamp"
)
SELECT
    id, session_id, sender, content, intent,
    cited_cases, cited_laws, sequence_number, "timestamp"
FROM council_v1.deliberation_messages;

-- ============================================================
-- 2. Create deferred indexes on app.cases (after bulk load)
-- ============================================================

CREATE INDEX idx_app_cases_nation_lower ON app.cases USING btree (LOWER(nation::TEXT));
CREATE INDEX idx_app_cases_subject_normalized ON app.cases USING gin (subject_normalized gin_trgm_ops) WHERE (status = 1);
CREATE INDEX idx_app_cases_subject_normalized_btree ON app.cases USING btree (LOWER(REGEXP_REPLACE(subject::TEXT, '[^a-zA-Z0-9]', '', 'g')));
CREATE INDEX idx_app_cases_search_filter ON app.cases USING btree (subject_type, year, case_type, nation, status);

-- ============================================================
-- 3. Update entity_graph provenance strings
-- ============================================================

-- Disable updated_at triggers to preserve original timestamps during provenance-only update
ALTER TABLE entity_graph.actors DISABLE TRIGGER set_actors_updated_at;
ALTER TABLE entity_graph.events DISABLE TRIGGER set_events_updated_at;

-- Core tables (known to reference bo_v1.cases)
UPDATE entity_graph.actors SET source_table = 'app.cases' WHERE source_table = 'bo_v1.cases';
UPDATE entity_graph.events SET source_table = 'app.cases' WHERE source_table = 'bo_v1.cases';

-- Junction and related tables (defensive — no-op if no rows match)
UPDATE entity_graph.actor_regulations SET source_table = 'app.cases' WHERE source_table = 'bo_v1.cases';
UPDATE entity_graph.event_regulations SET source_table = 'app.cases' WHERE source_table = 'bo_v1.cases';
UPDATE entity_graph.regulations SET source_table = 'app.cases' WHERE source_table = 'bo_v1.cases';

-- Re-enable triggers
ALTER TABLE entity_graph.actors ENABLE TRIGGER set_actors_updated_at;
ALTER TABLE entity_graph.events ENABLE TRIGGER set_events_updated_at;
