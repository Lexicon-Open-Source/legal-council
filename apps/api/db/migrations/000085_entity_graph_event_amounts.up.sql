-- Financial metrics: amounts associated with events (budget, contract value, penalties).

CREATE TABLE entity_graph.event_amounts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    event_id    UUID NOT NULL REFERENCES entity_graph.events(id) ON DELETE CASCADE,
    amount_raw  TEXT NOT NULL,
    amount      NUMERIC,
    currency    TEXT NOT NULL DEFAULT 'IDR',
    amount_type TEXT NOT NULL,
    dataset     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE entity_graph.event_amounts IS 'Financial amounts associated with events (budget_ceiling, contract_value, penalty, fine, loss, damages)';
COMMENT ON COLUMN entity_graph.event_amounts.amount_raw IS 'Original amount string for audit trail';
COMMENT ON COLUMN entity_graph.event_amounts.amount IS 'Parsed numeric value (NULL if unparseable)';
COMMENT ON COLUMN entity_graph.event_amounts.amount_type IS 'Category: budget_ceiling, contract_value, penalty, fine, loss, damages';

-- No separate idx_eg_event_amounts_event — the unique index prefix covers event_id lookups
CREATE UNIQUE INDEX idx_eg_event_amounts_unique
    ON entity_graph.event_amounts(event_id, amount_type, dataset);
