-- Add COMMENT ON COLUMN for first_seen / last_seen across entity_graph tables.
-- These columns track ETL observation timestamps (when did the crawler first/last
-- see this entity in the source), NOT source-data dates. If last_seen stops
-- advancing, the entity may have been removed from the source list.

COMMENT ON COLUMN entity_graph.actors.first_seen IS
    'ETL observation: when this actor was first seen in the source during a crawl run';
COMMENT ON COLUMN entity_graph.actors.last_seen IS
    'ETL observation: when this actor was last seen in the source during a crawl run. Stale last_seen may indicate removal from source list.';

COMMENT ON COLUMN entity_graph.actor_names.first_seen IS
    'ETL observation: when this name variant was first seen in the source';
COMMENT ON COLUMN entity_graph.actor_names.last_seen IS
    'ETL observation: when this name variant was last seen in the source';

COMMENT ON COLUMN entity_graph.actor_identifiers.first_seen IS
    'ETL observation: when this identifier was first seen in the source';
COMMENT ON COLUMN entity_graph.actor_identifiers.last_seen IS
    'ETL observation: when this identifier was last seen in the source';

COMMENT ON COLUMN entity_graph.events.first_seen IS
    'ETL observation: when this event was first seen in the source during a crawl run';
COMMENT ON COLUMN entity_graph.events.last_seen IS
    'ETL observation: when this event was last seen in the source during a crawl run';

COMMENT ON COLUMN entity_graph.actor_links.first_seen IS
    'ETL observation: when this relationship was first seen in the source';
COMMENT ON COLUMN entity_graph.actor_links.last_seen IS
    'ETL observation: when this relationship was last seen in the source';
