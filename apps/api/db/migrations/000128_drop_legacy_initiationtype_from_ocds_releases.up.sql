-- Drop legacy initiationtype column from ocds.releases (redundant with initiation_type).
-- Verified in prod: 3,558,596 rows, 0 divergent values between the two columns (all 'tender').
-- No indexes, views, functions, or foreign keys depend on this column.
-- Fail fast under lock contention so we don't block traffic on this ~3.5M-row table.
SET lock_timeout = '2s';
ALTER TABLE ocds.releases
    DROP COLUMN IF EXISTS initiationtype;
