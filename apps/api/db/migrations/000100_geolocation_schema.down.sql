-- Reverse migration 000100: restore geocoding_cache, drop geolocation schema

-- Drop indexes on ocds tables before dropping columns
DROP INDEX IF EXISTS idx_tender_geolocation;
DROP INDEX IF EXISTS idx_items_geolocation;
DROP INDEX IF EXISTS idx_releases_buyer_id;

-- Drop geo columns from tender
ALTER TABLE ocds.tender
    DROP COLUMN IF EXISTS geo_lat,
    DROP COLUMN IF EXISTS geo_lon,
    DROP COLUMN IF EXISTS geo_bbox_min_lat,
    DROP COLUMN IF EXISTS geo_bbox_max_lat,
    DROP COLUMN IF EXISTS geo_bbox_min_lon,
    DROP COLUMN IF EXISTS geo_bbox_max_lon;

-- Drop bounding box columns from parties (keep geo_lat/geo_lon from 000099)
ALTER TABLE ocds.parties
    DROP COLUMN IF EXISTS geo_bbox_min_lat,
    DROP COLUMN IF EXISTS geo_bbox_max_lat,
    DROP COLUMN IF EXISTS geo_bbox_min_lon,
    DROP COLUMN IF EXISTS geo_bbox_max_lon;

-- Drop geo columns from items
ALTER TABLE ocds.items
    DROP COLUMN IF EXISTS geo_lat,
    DROP COLUMN IF EXISTS geo_lon,
    DROP COLUMN IF EXISTS geo_bbox_min_lat,
    DROP COLUMN IF EXISTS geo_bbox_max_lat,
    DROP COLUMN IF EXISTS geo_bbox_min_lon,
    DROP COLUMN IF EXISTS geo_bbox_max_lon;

-- Drop unique indexes on geocode_ocds before dropping tables
DROP INDEX IF EXISTS geolocation.uq_geocode_ocds_tender;
DROP INDEX IF EXISTS geolocation.uq_geocode_ocds_party;
DROP INDEX IF EXISTS geolocation.uq_geocode_ocds_item;

-- Drop geolocation tables and schema
DROP TABLE IF EXISTS geolocation.geocode_ocds;
DROP TABLE IF EXISTS geolocation.geocode;
DROP SCHEMA IF EXISTS geolocation;

-- Recreate geocoding_cache (from 000099)
CREATE TABLE IF NOT EXISTS ocds.geocoding_cache (
    query_text  TEXT PRIMARY KEY,
    lat         DOUBLE PRECISION,
    lon         DOUBLE PRECISION,
    display_name TEXT,
    source      VARCHAR(50) NOT NULL DEFAULT 'nominatim',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
