-- Actor classification/risk tags with optional temporal validity.

CREATE TABLE entity_graph.actor_tags (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    actor_id    UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    tag         TEXT NOT NULL,
    tag_source  TEXT,
    valid_from  TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    dataset     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Include valid_from in unique constraint to allow time-partitioned tags
-- for the same actor+tag+dataset (e.g. blacklisted 2020-2022, re-blacklisted 2024).
CREATE UNIQUE INDEX idx_eg_actor_tags_unique
    ON entity_graph.actor_tags(actor_id, tag, dataset, COALESCE(valid_from, '1970-01-01'::timestamptz));

CREATE INDEX idx_eg_actor_tags_tag ON entity_graph.actor_tags(tag);
CREATE INDEX idx_eg_actor_tags_active ON entity_graph.actor_tags(tag) WHERE valid_until IS NULL;

COMMENT ON TABLE entity_graph.actor_tags
    IS 'Derived risk/classification tags per actor, with optional temporal validity';
