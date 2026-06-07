-- Multi-source attribution: tracks which datasets contributed to each actor.

CREATE TABLE entity_graph.actor_datasets (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    actor_id     UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE RESTRICT,
    dataset      TEXT NOT NULL,
    source_table TEXT NOT NULL,
    source_id    TEXT NOT NULL,
    first_seen   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE entity_graph.actor_datasets IS 'Multi-source attribution: tracks which datasets contributed to each actor';
COMMENT ON COLUMN entity_graph.actor_datasets.actor_id IS 'FK to actors — ON DELETE RESTRICT to prevent silent provenance loss';

CREATE UNIQUE INDEX idx_eg_actor_datasets_unique
    ON entity_graph.actor_datasets(actor_id, dataset, source_id);
CREATE INDEX idx_eg_actor_datasets_actor
    ON entity_graph.actor_datasets(actor_id);
CREATE INDEX idx_eg_actor_datasets_dataset
    ON entity_graph.actor_datasets(dataset);
