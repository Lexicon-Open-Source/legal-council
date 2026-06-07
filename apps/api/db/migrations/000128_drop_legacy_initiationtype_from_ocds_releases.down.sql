-- Restore legacy initiationtype column with its original definition.
-- The DEFAULT will populate existing rows with 'tender' (the sole observed value prior to drop).
-- Fail fast under lock contention so we don't block traffic on this ~3.5M-row table.
SET lock_timeout = '2s';
ALTER TABLE ocds.releases
    ADD COLUMN IF NOT EXISTS initiationtype VARCHAR DEFAULT 'tender';
