-- migrations/000078_migrate_data_to_app.down.sql
--
-- WARNING: This down migration TRUNCATES all app.* tables.
-- Any data written to app.* tables AFTER migration 000078 ran
-- will be PERMANENTLY LOST. Only run this if bo_v1/council_v1
-- still contain the authoritative data.

-- Disable updated_at triggers to preserve original timestamps during provenance-only update
ALTER TABLE entity_graph.actors DISABLE TRIGGER set_actors_updated_at;
ALTER TABLE entity_graph.events DISABLE TRIGGER set_events_updated_at;

-- Reverse provenance updates
UPDATE entity_graph.regulations SET source_table = 'bo_v1.cases' WHERE source_table = 'app.cases';
UPDATE entity_graph.event_regulations SET source_table = 'bo_v1.cases' WHERE source_table = 'app.cases';
UPDATE entity_graph.actor_regulations SET source_table = 'bo_v1.cases' WHERE source_table = 'app.cases';
UPDATE entity_graph.events SET source_table = 'bo_v1.cases' WHERE source_table = 'app.cases';
UPDATE entity_graph.actors SET source_table = 'bo_v1.cases' WHERE source_table = 'app.cases';

-- Re-enable triggers
ALTER TABLE entity_graph.actors ENABLE TRIGGER set_actors_updated_at;
ALTER TABLE entity_graph.events ENABLE TRIGGER set_events_updated_at;

-- Drop deferred indexes
DROP INDEX IF EXISTS app.idx_app_cases_search_filter;
DROP INDEX IF EXISTS app.idx_app_cases_subject_normalized_btree;
DROP INDEX IF EXISTS app.idx_app_cases_subject_normalized;
DROP INDEX IF EXISTS app.idx_app_cases_nation_lower;

-- Truncate app tables (data still exists in bo_v1/council_v1)
TRUNCATE app.deliberation_messages CASCADE;
TRUNCATE app.deliberation_sessions CASCADE;
TRUNCATE app.draft_cases CASCADE;
TRUNCATE app.cases CASCADE;
