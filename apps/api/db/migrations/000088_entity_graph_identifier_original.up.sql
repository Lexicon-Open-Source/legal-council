-- Preserve original identifier values before normalization.

ALTER TABLE entity_graph.actor_identifiers
    ADD COLUMN IF NOT EXISTS identifier_original TEXT;

COMMENT ON COLUMN entity_graph.actor_identifiers.identifier_original
    IS 'Raw value before normalization (e.g. NPWP with original formatting)';
