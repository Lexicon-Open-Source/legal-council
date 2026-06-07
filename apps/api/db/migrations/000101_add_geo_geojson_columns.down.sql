ALTER TABLE ocds.tender DROP COLUMN IF EXISTS geo_geojson;
ALTER TABLE ocds.parties DROP COLUMN IF EXISTS geo_geojson;
ALTER TABLE ocds.items DROP COLUMN IF EXISTS geo_geojson;
ALTER TABLE geolocation.geocode_ocds DROP COLUMN IF EXISTS geo_geojson;
