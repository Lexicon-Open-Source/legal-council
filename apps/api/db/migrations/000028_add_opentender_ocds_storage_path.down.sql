-- Rollback: remove storage_path column and index from opentender_ocds_releases

DROP INDEX IF EXISTS crawler.idx_opentender_ocds_releases_has_storage;

ALTER TABLE crawler.opentender_ocds_releases
    DROP COLUMN IF EXISTS storage_path;
