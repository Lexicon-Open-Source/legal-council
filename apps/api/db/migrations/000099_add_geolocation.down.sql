DROP INDEX IF EXISTS ocds.idx_parties_geolocation;

DROP TABLE IF EXISTS ocds.geocoding_cache;

ALTER TABLE ocds.parties
    DROP COLUMN IF EXISTS geo_lat,
    DROP COLUMN IF EXISTS geo_lon;
