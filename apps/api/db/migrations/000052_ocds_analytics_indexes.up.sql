-- OCDS Analytics Performance Indexes
-- Prerequisites for Phase 2 materialized views
-- These indexes significantly improve MV refresh performance

-- For KLPD ranking joins (10-20x faster refresh)
CREATE INDEX IF NOT EXISTS idx_tender_procuring_entity_release
    ON ocds.tender (procuring_entity_id, release_id)
    WHERE status IS NULL OR status NOT IN ('cancelled', 'withdrawn');

-- For award aggregations
CREATE INDEX IF NOT EXISTS idx_awards_release_value_active
    ON ocds.awards (release_id, value_amount DESC)
    WHERE status = 'active';

-- For planning fiscal year lookups
CREATE INDEX IF NOT EXISTS idx_planning_fiscal_release
    ON ocds.planning (fiscal_year, release_id);

-- For date-based aggregations
CREATE INDEX IF NOT EXISTS idx_tender_period_start_release
    ON ocds.tender (tender_period_start_date, release_id)
    WHERE tender_period_start_date IS NOT NULL;

-- For award supplier joins
CREATE INDEX IF NOT EXISTS idx_award_suppliers_party_award
    ON ocds.award_suppliers (party_id, award_id);

-- For budget/HPS aggregations
CREATE INDEX IF NOT EXISTS idx_planning_budget_release
    ON ocds.planning (budget_amount, release_id)
    WHERE budget_amount IS NOT NULL AND budget_amount > 0;
