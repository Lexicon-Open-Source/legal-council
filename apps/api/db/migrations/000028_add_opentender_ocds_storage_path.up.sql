-- Add storage_path column to opentender_ocds_releases for Garage object storage
-- Stores the object key (path) in S3-compatible storage where the original OCDS JSON file is stored

ALTER TABLE crawler.opentender_ocds_releases
    ADD COLUMN IF NOT EXISTS storage_path TEXT;

COMMENT ON COLUMN crawler.opentender_ocds_releases.storage_path IS 'Object storage path (e.g., opentender/ocds/2025/100/releases.json)';

-- Index for querying records that have/don't have uploaded files
CREATE INDEX IF NOT EXISTS idx_opentender_ocds_releases_has_storage
    ON crawler.opentender_ocds_releases ((storage_path IS NOT NULL))
    WHERE storage_path IS NOT NULL;
