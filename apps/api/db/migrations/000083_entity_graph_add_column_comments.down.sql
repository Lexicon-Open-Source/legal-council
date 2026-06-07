-- Remove COMMENT ON COLUMN for first_seen / last_seen
COMMENT ON COLUMN entity_graph.actors.first_seen IS NULL;
COMMENT ON COLUMN entity_graph.actors.last_seen IS NULL;
COMMENT ON COLUMN entity_graph.actor_names.first_seen IS NULL;
COMMENT ON COLUMN entity_graph.actor_names.last_seen IS NULL;
COMMENT ON COLUMN entity_graph.actor_identifiers.first_seen IS NULL;
COMMENT ON COLUMN entity_graph.actor_identifiers.last_seen IS NULL;
COMMENT ON COLUMN entity_graph.events.first_seen IS NULL;
COMMENT ON COLUMN entity_graph.events.last_seen IS NULL;
COMMENT ON COLUMN entity_graph.actor_links.first_seen IS NULL;
COMMENT ON COLUMN entity_graph.actor_links.last_seen IS NULL;
