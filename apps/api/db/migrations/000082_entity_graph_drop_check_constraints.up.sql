-- Drop restrictive CHECK constraints that prevent new enum values
-- from being inserted by ETL extractors.
--
-- regulation_links.link_type: allows 'established_by' (BPK extractor) and future values
-- events.event_type: allows 'warning' (SC investor alerts) and future values
--
-- Application-level validation is enforced by Pydantic Literal types in the ETL.
-- Follows precedent of migration 000076 (dropped actor_events.role + actor_links.link_type CHECKs).

ALTER TABLE entity_graph.regulation_links
    DROP CONSTRAINT IF EXISTS chk_regulation_link_type;

ALTER TABLE entity_graph.events
    DROP CONSTRAINT IF EXISTS chk_event_type;
