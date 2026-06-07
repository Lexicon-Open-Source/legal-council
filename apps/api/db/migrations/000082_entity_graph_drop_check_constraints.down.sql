-- WARNING: This down migration DELETES rows with values introduced after the
-- original CHECK constraints. Run pre-rollback verification queries before executing:
--
--   SELECT link_type, COUNT(*) FROM entity_graph.regulation_links
--       WHERE link_type NOT IN ('revokes', 'amends', 'amended_by', 'revoked_by', 'legal_basis')
--       GROUP BY link_type;
--
--   SELECT event_type, COUNT(*) FROM entity_graph.events
--       WHERE event_type NOT IN ('verdict', 'sanction', 'blacklist_entry', 'tender')
--       GROUP BY event_type;

BEGIN;

-- Phase 1: Delete regulation_links with non-original link_type values
DELETE FROM entity_graph.regulation_links
    WHERE link_type NOT IN ('revokes', 'amends', 'amended_by', 'revoked_by', 'legal_basis');

-- Phase 2: Delete events with non-original event_type values
-- CASCADE cleans up: event_content, actor_events
DELETE FROM entity_graph.events
    WHERE event_type NOT IN ('verdict', 'sanction', 'blacklist_entry', 'tender');

-- Phase 3: Restore constraints
ALTER TABLE entity_graph.regulation_links
    ADD CONSTRAINT chk_regulation_link_type
    CHECK (link_type IN ('revokes', 'amends', 'amended_by', 'revoked_by', 'legal_basis'));

ALTER TABLE entity_graph.events
    ADD CONSTRAINT chk_event_type
    CHECK (event_type IN ('verdict', 'sanction', 'blacklist_entry', 'tender'));

COMMIT;
