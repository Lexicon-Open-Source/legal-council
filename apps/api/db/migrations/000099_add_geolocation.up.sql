-- Kolom geolokasi pada parties untuk dashboard visualisasi
ALTER TABLE ocds.parties
    ADD COLUMN IF NOT EXISTS geo_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_lon DOUBLE PRECISION;

COMMENT ON COLUMN ocds.parties.geo_lat IS 'Latitude dari geocoding (WGS84).';
COMMENT ON COLUMN ocds.parties.geo_lon IS 'Longitude dari geocoding (WGS84).';

-- Composite index untuk query dashboard visualisasi berdasarkan lokasi
CREATE INDEX IF NOT EXISTS idx_parties_geolocation ON ocds.parties (geo_lat, geo_lon);

-- Cache table untuk hasil geocoding (Nominatim / OSM)
-- Mencegah query berulang ke Nominatim untuk alamat yang sama
CREATE TABLE IF NOT EXISTS ocds.geocoding_cache (
    query_text  TEXT PRIMARY KEY,
    lat         DOUBLE PRECISION,
    lon         DOUBLE PRECISION,
    display_name TEXT,
    source      VARCHAR(50) NOT NULL DEFAULT 'nominatim',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ocds.geocoding_cache IS 'Cache hasil geocoding dari Nominatim/OSM. NULL lat/lon = negative cache (sudah di-query, tidak ditemukan).';
