-- Remove LKPP blacklist status constraint
-- The original constraint was too restrictive - the API returns various statuses
-- like PUBLISHED, CANCELLED, CANCELED, CANCELED_TEMPORARY, CANCELED_PERMANENT, etc.
-- Rather than enumerate all possible values, we remove the constraint entirely
-- and let the application handle status validation if needed.

ALTER TABLE crawler.lkpp_blacklist_entries
    DROP CONSTRAINT IF EXISTS valid_status;
