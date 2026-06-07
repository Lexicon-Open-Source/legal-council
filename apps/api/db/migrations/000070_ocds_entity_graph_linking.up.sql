-- Link OCDS parties to entity_graph actors (soft reference, no FK)
ALTER TABLE ocds.parties
    ADD COLUMN actor_id UUID;

CREATE INDEX idx_parties_actor_id
    ON ocds.parties(actor_id)
    WHERE actor_id IS NOT NULL;

COMMENT ON COLUMN ocds.parties.actor_id IS
    'Soft reference to entity_graph.actors(id). Populated by entity resolution ETL. No FK constraint — schemas are independently managed.';

-- Link OCDS releases to entity_graph events (soft reference, no FK)
ALTER TABLE ocds.releases
    ADD COLUMN event_id UUID;

CREATE INDEX idx_releases_event_id
    ON ocds.releases(event_id)
    WHERE event_id IS NOT NULL;

COMMENT ON COLUMN ocds.releases.event_id IS
    'Soft reference to entity_graph.events(id). One release = one procurement event. Populated by entity resolution ETL.';
