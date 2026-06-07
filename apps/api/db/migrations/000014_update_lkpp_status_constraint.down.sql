-- Revert to original status constraint
ALTER TABLE crawler.lkpp_blacklist_entries
    DROP CONSTRAINT IF EXISTS valid_status;

ALTER TABLE crawler.lkpp_blacklist_entries
    ADD CONSTRAINT valid_status CHECK (
        status IN ('PUBLISHED', 'CANCELLED', 'EXPIRED', 'PENDING')
    );
