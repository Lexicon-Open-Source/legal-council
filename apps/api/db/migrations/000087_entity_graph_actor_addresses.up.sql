-- Actor addresses: physical addresses associated with actors.

CREATE TABLE entity_graph.actor_addresses (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    actor_id           UUID NOT NULL REFERENCES entity_graph.actors(id) ON DELETE CASCADE,
    address            TEXT NOT NULL,
    address_normalized TEXT,
    address_type       TEXT,
    jurisdiction       TEXT,
    dataset            TEXT NOT NULL,
    source_table       TEXT,
    source_id          TEXT,
    first_seen         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE entity_graph.actor_addresses IS 'Physical addresses associated with actors, with optional classification';
COMMENT ON COLUMN entity_graph.actor_addresses.address IS 'Raw address text (dedup key)';
COMMENT ON COLUMN entity_graph.actor_addresses.address_normalized IS 'Lowercased, whitespace-collapsed address for display/search';
COMMENT ON COLUMN entity_graph.actor_addresses.address_type IS 'Address type: registered, operational, residential';
COMMENT ON COLUMN entity_graph.actor_addresses.jurisdiction IS 'ISO 3166-1 alpha-2 country code';

-- Dedup key uses RAW address to avoid false dedup when normalization is lossy
CREATE UNIQUE INDEX idx_eg_actor_addresses_unique
    ON entity_graph.actor_addresses(actor_id, address, dataset);
CREATE INDEX idx_eg_actor_addresses_actor
    ON entity_graph.actor_addresses(actor_id);

-- NOTE: GIN trgm index DEFERRED — add when fuzzy address search is needed (adds write overhead)
-- CREATE INDEX idx_eg_actor_addresses_trgm
--     ON entity_graph.actor_addresses USING gin(address_normalized gin_trgm_ops);
