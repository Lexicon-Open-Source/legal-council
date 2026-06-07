-- Rebuild screening as a richer read model for dynamic profile and sanctions-history UI.
-- This schema is a projection from entity_graph and is safe to recreate before a full ETL rebuild.

CREATE SCHEMA IF NOT EXISTS screening;

CREATE OR REPLACE FUNCTION screening.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TABLE IF EXISTS screening.entity_names;
DROP TABLE IF EXISTS screening.entity_sanctions;
DROP TABLE IF EXISTS screening.entities;
DROP TABLE IF EXISTS screening.sanctions_lists;

CREATE TABLE screening.sanctions_lists (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    source_dataset TEXT NOT NULL,
    name           TEXT NOT NULL,
    publisher      TEXT NOT NULL,
    url            TEXT,
    description    TEXT,
    country_code   TEXT,
    metadata       JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_sanctions_lists_name_publisher UNIQUE (name, publisher),
    CONSTRAINT uq_screening_sanctions_lists_source_dataset UNIQUE (source_dataset),
    CONSTRAINT sanctions_lists_metadata_object_check CHECK (jsonb_typeof(metadata) = 'object')
);
COMMENT ON TABLE screening.sanctions_lists IS 'Reference table of screening source lists used by the screening read model.';
CREATE INDEX idx_screening_sanctions_lists_country_code
    ON screening.sanctions_lists (country_code);

CREATE TABLE screening.entities (
    id                UUID PRIMARY KEY,
    entity_type       TEXT NOT NULL CHECK (entity_type IN ('person', 'organization')),
    source_actor_type TEXT NOT NULL,
    display_name      TEXT NOT NULL,
    topics            TEXT[] NOT NULL DEFAULT '{}',
    remarks           TEXT,
    profile_data      JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT entities_profile_data_object_check CHECK (jsonb_typeof(profile_data) = 'object')
);
COMMENT ON TABLE screening.entities IS 'Denormalized screening entities with display-ready profile data.';
COMMENT ON COLUMN screening.entities.entity_type IS
    'Simplified screening type. company and public_body are projected as organization; see source_actor_type for the raw upstream actor type.';
COMMENT ON COLUMN screening.entities.source_actor_type IS
    'Raw actor_type from entity_graph.actors preserved for provenance and future UI branching.';
CREATE INDEX idx_screening_entities_type ON screening.entities (entity_type);

CREATE TABLE screening.entity_names (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    entity_id       UUID NOT NULL REFERENCES screening.entities(id) ON DELETE CASCADE,
    name_value      TEXT NOT NULL,
    name_normalized TEXT NOT NULL,
    name_type       TEXT NOT NULL DEFAULT 'primary',
    is_matchable    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT screening_entity_names_name_type_check CHECK (name_type IN ('primary', 'alias'))
);
COMMENT ON TABLE screening.entity_names IS 'Search-oriented entity name variants for BM25 search.';
CREATE INDEX idx_screening_entity_names_entity_id ON screening.entity_names (entity_id);
CREATE INDEX idx_screening_entity_names_bm25 ON screening.entity_names
USING bm25 (id, name_normalized)
WITH (key_field='id');

CREATE TABLE screening.entity_sanctions (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    entity_id         UUID NOT NULL REFERENCES screening.entities(id) ON DELETE CASCADE,
    sanctions_list_id UUID NOT NULL REFERENCES screening.sanctions_lists(id) ON DELETE CASCADE,
    source_event_id   UUID NOT NULL,
    list_entry_id     TEXT,
    listed_at         DATE,
    delisted_at       DATE,
    entry_data        JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT entity_sanctions_entity_id_sanctions_list_id_key UNIQUE (entity_id, sanctions_list_id),
    CONSTRAINT entity_sanctions_entry_data_object_check CHECK (jsonb_typeof(entry_data) = 'object'),
    CONSTRAINT entity_sanctions_date_order_check CHECK (
        listed_at IS NULL OR delisted_at IS NULL OR listed_at <= delisted_at
    )
);
COMMENT ON TABLE screening.entity_sanctions IS 'One row per entity/list card with canonical provenance and entry payload.';
CREATE INDEX idx_screening_entity_sanctions_entity_id ON screening.entity_sanctions (entity_id);
CREATE INDEX idx_screening_entity_sanctions_list_id ON screening.entity_sanctions (sanctions_list_id);
CREATE INDEX idx_screening_entity_sanctions_source_event_id ON screening.entity_sanctions (source_event_id);

CREATE TRIGGER set_sanctions_lists_updated_at
    BEFORE UPDATE ON screening.sanctions_lists
    FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();

CREATE TRIGGER set_entities_updated_at
    BEFORE UPDATE ON screening.entities
    FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();

CREATE TRIGGER set_entity_names_updated_at
    BEFORE UPDATE ON screening.entity_names
    FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();

CREATE TRIGGER set_entity_sanctions_updated_at
    BEFORE UPDATE ON screening.entity_sanctions
    FOR EACH ROW EXECUTE FUNCTION screening.trigger_set_timestamp();
