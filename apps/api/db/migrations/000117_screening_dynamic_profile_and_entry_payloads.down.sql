-- Revert screening to the pre-000117 search-oriented schema.

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
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    name         TEXT NOT NULL,
    publisher    TEXT NOT NULL,
    url          TEXT,
    description  TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    country_code TEXT,
    CONSTRAINT uq_sanctions_lists_name_publisher UNIQUE (name, publisher)
);
COMMENT ON TABLE screening.sanctions_lists IS 'Reference table of sanctions list sources (OFAC, UN, EU, etc.)';
CREATE INDEX idx_screening_sanctions_lists_country_code
    ON screening.sanctions_lists (country_code);

CREATE TABLE screening.entities (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    entity_type TEXT NOT NULL CHECK (entity_type IN ('person', 'organization')),
    topics      TEXT[] NOT NULL DEFAULT '{}',
    remarks     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE screening.entities IS 'Denormalized entities for screening search. One row per unique entity.';
CREATE INDEX idx_screening_entities_type ON screening.entities (entity_type);

CREATE TABLE screening.entity_names (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    entity_id       UUID NOT NULL REFERENCES screening.entities(id) ON DELETE CASCADE,
    name_value      TEXT NOT NULL,
    name_normalized TEXT NOT NULL,
    name_type       TEXT NOT NULL DEFAULT 'primary',
    is_matchable    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE screening.entity_names IS 'Entity name variants for BM25 search. is_matchable controls which names appear in search results.';
CREATE INDEX idx_screening_entity_names_entity_id ON screening.entity_names (entity_id);
CREATE INDEX idx_screening_entity_names_bm25 ON screening.entity_names
USING bm25 (id, name_normalized)
WITH (key_field='id');

CREATE TABLE screening.entity_sanctions (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    entity_id         UUID NOT NULL REFERENCES screening.entities(id) ON DELETE CASCADE,
    sanctions_list_id UUID NOT NULL REFERENCES screening.sanctions_lists(id) ON DELETE CASCADE,
    list_entry_id     TEXT,
    listed_at         DATE,
    delisted_at       DATE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT entity_sanctions_entity_id_sanctions_list_id_key UNIQUE (entity_id, sanctions_list_id)
);
COMMENT ON TABLE screening.entity_sanctions IS 'Junction table linking entities to their sanctions list appearances.';
CREATE INDEX idx_screening_entity_sanctions_entity_id ON screening.entity_sanctions (entity_id);
CREATE INDEX idx_screening_entity_sanctions_list_id ON screening.entity_sanctions (sanctions_list_id);

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
