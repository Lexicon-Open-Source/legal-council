-- Revert composite index for cursor-based pagination

DROP INDEX CONCURRENTLY IF EXISTS ocds.idx_releases_updated_at_id;
