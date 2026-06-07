-- Add geo_geojson JSONB column to OCDS tables for Nominatim polygon/linestring geometry
-- Data populated during geocoding backfill from geolocation.geocode.raw_response->0->'geojson'

ALTER TABLE ocds.tender
    ADD COLUMN IF NOT EXISTS geo_geojson JSONB;

ALTER TABLE ocds.parties
    ADD COLUMN IF NOT EXISTS geo_geojson JSONB;

ALTER TABLE ocds.items
    ADD COLUMN IF NOT EXISTS geo_geojson JSONB;

ALTER TABLE geolocation.geocode_ocds
    ADD COLUMN IF NOT EXISTS geo_geojson JSONB;

COMMENT ON COLUMN ocds.tender.geo_geojson IS 'GeoJSON geometry (Polygon/LineString) from Nominatim polygon_geojson response.';
COMMENT ON COLUMN ocds.parties.geo_geojson IS 'GeoJSON geometry (Polygon/LineString) from Nominatim polygon_geojson response.';
COMMENT ON COLUMN ocds.items.geo_geojson IS 'GeoJSON geometry (Polygon/LineString) from Nominatim polygon_geojson response.';
COMMENT ON COLUMN geolocation.geocode_ocds.geo_geojson IS 'GeoJSON geometry (Polygon/LineString) from Nominatim polygon_geojson response. Redundant with geocode.raw_response->0->geojson for convenience.';
