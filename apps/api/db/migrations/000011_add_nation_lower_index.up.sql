-- Add function-based index for case-insensitive nation filtering
-- This improves performance of queries using LOWER(nation) in WHERE clauses
CREATE INDEX idx_bo_v1_cases_nation_lower ON bo_v1.cases (LOWER(nation));
