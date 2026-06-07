-- Add updated_at trigger function and missing updated_at columns to screening tables.
-- Addresses PR review: sanctions_lists and entities had updated_at but no auto-update
-- trigger, and entity_names / entity_sanctions were missing updated_at entirely.

-- Trigger function (same pattern as llm_extraction / entity_graph schemas)
CREATE FUNCTION screening.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Add missing updated_at columns
ALTER TABLE screening.entity_names
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE screening.entity_sanctions
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Apply trigger to all tables with updated_at
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
