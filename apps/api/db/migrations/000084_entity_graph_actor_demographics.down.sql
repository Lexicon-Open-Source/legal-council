DROP INDEX IF EXISTS entity_graph.idx_eg_actors_birth_date;
DROP INDEX IF EXISTS entity_graph.idx_eg_actors_nationality;

ALTER TABLE entity_graph.actors
    DROP COLUMN IF EXISTS occupation,
    DROP COLUMN IF EXISTS nationality,
    DROP COLUMN IF EXISTS gender,
    DROP COLUMN IF EXISTS birth_place,
    DROP COLUMN IF EXISTS birth_date;
