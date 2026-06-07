-- Rollback: OpenTender OCDS releases table
DROP TRIGGER IF EXISTS update_opentender_ocds_releases_updated_at ON crawler.opentender_ocds_releases;
DROP TABLE IF EXISTS crawler.opentender_ocds_releases;
