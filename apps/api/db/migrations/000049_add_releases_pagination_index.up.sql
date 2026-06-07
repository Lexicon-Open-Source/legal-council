-- Add composite index for cursor-based pagination in OCDS releases export
-- Supports efficient ORDER BY (updated_at ASC, id ASC) queries
-- Used by ExportOCDSReleases query in internal/db/queries/egress.sql

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_releases_updated_at_id
ON ocds.releases (updated_at ASC, id ASC);
