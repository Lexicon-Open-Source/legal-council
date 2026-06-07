-- Add composite index for combined state + category filter queries
-- Optimizes: WHERE metadata->>'state' = X AND metadata->>'category' = Y ORDER BY created_at DESC
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sprm_offenders_state_category_created
ON crawler.sprm_offenders (
    (metadata->>'state'),
    (metadata->>'category'),
    created_at DESC
);
