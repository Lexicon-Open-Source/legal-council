DROP TRIGGER IF EXISTS set_entity_sanctions_updated_at ON screening.entity_sanctions;
DROP TRIGGER IF EXISTS set_entity_names_updated_at ON screening.entity_names;
DROP TRIGGER IF EXISTS set_entities_updated_at ON screening.entities;
DROP TRIGGER IF EXISTS set_sanctions_lists_updated_at ON screening.sanctions_lists;

ALTER TABLE screening.entity_sanctions DROP COLUMN IF EXISTS updated_at;
ALTER TABLE screening.entity_names DROP COLUMN IF EXISTS updated_at;

DROP FUNCTION IF EXISTS screening.trigger_set_timestamp();
