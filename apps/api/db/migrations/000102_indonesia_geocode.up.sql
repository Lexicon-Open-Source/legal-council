-- Local Indonesian administrative boundary polygons from BPS/government sources.
-- Used as fallback/enrichment when Nominatim polygon is incomplete or missing.

CREATE TABLE IF NOT EXISTS geolocation.indonesia_geocode (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_level     VARCHAR(20) NOT NULL CHECK (admin_level IN ('provinsi', 'kabupaten', 'kecamatan', 'kelurahan')),
    name            TEXT NOT NULL,
    name_normalized TEXT NOT NULL,
    province_name   TEXT,
    kabupaten_name  TEXT,
    kecamatan_name  TEXT,
    kelurahan_name  TEXT,
    kode_bps        TEXT,
    luas            DOUBLE PRECISION,
    bbox_min_lat    DOUBLE PRECISION,
    bbox_max_lat    DOUBLE PRECISION,
    bbox_min_lon    DOUBLE PRECISION,
    bbox_max_lon    DOUBLE PRECISION,
    geojson         JSONB NOT NULL,
    coordinate_count INTEGER NOT NULL DEFAULT 0,
    source_url      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE geolocation.indonesia_geocode IS 'Indonesian admin boundaries (provinsi, kabupaten, kecamatan, kelurahan) from BPS/government GeoJSON sources. Used to enrich/replace Nominatim polygons when local data is more complete.';
COMMENT ON COLUMN geolocation.indonesia_geocode.name_normalized IS 'Lowercase, prefix-stripped name for matching. E.g. "bandung" not "Kabupaten Bandung".';
COMMENT ON COLUMN geolocation.indonesia_geocode.coordinate_count IS 'Pre-computed total coordinate points in geojson for polygon completeness comparison.';

-- Lookup indexes
CREATE INDEX IF NOT EXISTS idx_indonesia_geocode_level_name
    ON geolocation.indonesia_geocode (admin_level, name_normalized);

CREATE INDEX IF NOT EXISTS idx_indonesia_geocode_province
    ON geolocation.indonesia_geocode (province_name)
    WHERE province_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_indonesia_geocode_kabupaten
    ON geolocation.indonesia_geocode (kabupaten_name)
    WHERE kabupaten_name IS NOT NULL;

-- Trigram index for fuzzy matching (pg_trgm already enabled)
CREATE INDEX IF NOT EXISTS idx_indonesia_geocode_name_trgm
    ON geolocation.indonesia_geocode USING gin (name_normalized gin_trgm_ops);
