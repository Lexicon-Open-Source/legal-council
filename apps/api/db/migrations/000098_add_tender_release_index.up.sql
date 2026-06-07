-- Add missing index on ocds.tender(release_id) for batch egress queries.
-- The FK constraint exists but PostgreSQL does not auto-create FK indexes.
-- Without this index, GetEgressTendersByReleaseIDs does a sequential scan.
CREATE INDEX CONCURRENTLY idx_tender_release ON ocds.tender(release_id);
