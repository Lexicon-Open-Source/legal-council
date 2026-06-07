-- Revert: Remove entity_graph soft-reference columns from OCDS tables

DROP INDEX IF EXISTS ocds.idx_releases_event_id;
ALTER TABLE ocds.releases DROP COLUMN IF EXISTS event_id;

DROP INDEX IF EXISTS ocds.idx_parties_actor_id;
ALTER TABLE ocds.parties DROP COLUMN IF EXISTS actor_id;
