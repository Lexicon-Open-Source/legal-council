-- Rollback: Remove initiation_type column
-- Note: This is a no-op if the column was already there from migration 39

-- We don't drop the column on rollback since it might have been
-- created by the original migration 39. This migration is idempotent.
SELECT 1;
