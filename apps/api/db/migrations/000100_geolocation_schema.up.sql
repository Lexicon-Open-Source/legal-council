-- Geolocation schema: dedicated geocoding storage with full Nominatim responses
-- Replaces ocds.geocoding_cache with richer 2-table design

-- 1. Create geolocation schema
CREATE SCHEMA IF NOT EXISTS geolocation;

-- 2. geocode table — full Nominatim API responses
CREATE TABLE IF NOT EXISTS geolocation.geocode (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_key       TEXT NOT NULL UNIQUE,
    request_params  JSONB NOT NULL,
    raw_response    JSONB,
    lat             DOUBLE PRECISION,
    lon             DOUBLE PRECISION,
    bbox_min_lat    DOUBLE PRECISION,
    bbox_max_lat    DOUBLE PRECISION,
    bbox_min_lon    DOUBLE PRECISION,
    bbox_max_lon    DOUBLE PRECISION,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE geolocation.geocode IS 'Nominatim API responses. raw_response=NULL means negative cache (queried, not found).';
COMMENT ON COLUMN geolocation.geocode.query_key IS 'SHA-256 hash of normalized structured request params for dedup.';
COMMENT ON COLUMN geolocation.geocode.raw_response IS 'Complete Nominatim jsonv2 response array. NULL = tried, no results. All metadata (osm_type, place_rank, importance, address breakdown) lives here.';
COMMENT ON COLUMN geolocation.geocode.lat IS 'Top result latitude (WGS84). NULL if not found.';
COMMENT ON COLUMN geolocation.geocode.lon IS 'Top result longitude (WGS84). NULL if not found.';

-- 3. geocode_ocds table — mapping to OCDS entities for backfill
CREATE TABLE IF NOT EXISTS geolocation.geocode_ocds (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id      UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,
    tender_id       UUID REFERENCES ocds.tender(id) ON DELETE CASCADE,
    party_id        UUID REFERENCES ocds.parties(id) ON DELETE CASCADE,
    item_id         UUID REFERENCES ocds.items(id) ON DELETE CASCADE,
    source_table    VARCHAR(20) NOT NULL CHECK (source_table IN ('tender', 'parties', 'items')),
    original_address TEXT,
    geocode_id      UUID REFERENCES geolocation.geocode(id) ON DELETE SET NULL,
    lat             DOUBLE PRECISION NOT NULL,
    lon             DOUBLE PRECISION NOT NULL,
    bbox_min_lat    DOUBLE PRECISION,
    bbox_max_lat    DOUBLE PRECISION,
    bbox_min_lon    DOUBLE PRECISION,
    bbox_max_lon    DOUBLE PRECISION,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Per-entity unique indexes (one geocode_ocds row per entity)
CREATE UNIQUE INDEX IF NOT EXISTS uq_geocode_ocds_tender ON geolocation.geocode_ocds (tender_id) WHERE tender_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_geocode_ocds_party ON geolocation.geocode_ocds (party_id) WHERE party_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_geocode_ocds_item ON geolocation.geocode_ocds (item_id) WHERE item_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_geocode_ocds_geocode ON geolocation.geocode_ocds (geocode_id);
CREATE INDEX IF NOT EXISTS idx_geocode_ocds_tender ON geolocation.geocode_ocds (tender_id) WHERE tender_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_geocode_ocds_party ON geolocation.geocode_ocds (party_id) WHERE party_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_geocode_ocds_item ON geolocation.geocode_ocds (item_id) WHERE item_id IS NOT NULL;

COMMENT ON TABLE geolocation.geocode_ocds IS 'Top geocode result per release per OCDS table. Direct FK to tender/parties/items for efficient backfill.';
COMMENT ON COLUMN geolocation.geocode_ocds.tender_id IS 'Set when source_table=tender. Direct FK for backfill.';
COMMENT ON COLUMN geolocation.geocode_ocds.party_id IS 'Set when source_table=parties. Direct FK for backfill.';
COMMENT ON COLUMN geolocation.geocode_ocds.item_id IS 'Set when source_table=items. Direct FK for future backfill.';

-- 4. Add geo columns to tender
ALTER TABLE ocds.tender
    ADD COLUMN IF NOT EXISTS geo_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_lon DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_min_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_max_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_min_lon DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_max_lon DOUBLE PRECISION;

CREATE INDEX IF NOT EXISTS idx_tender_geolocation ON ocds.tender (geo_lat, geo_lon);

-- 5. Add bounding box columns to parties (geo_lat/geo_lon already exist from 000099)
ALTER TABLE ocds.parties
    ADD COLUMN IF NOT EXISTS geo_bbox_min_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_max_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_min_lon DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_max_lon DOUBLE PRECISION;

-- 5b. Index on releases.buyer_id for efficient joins
CREATE INDEX IF NOT EXISTS idx_releases_buyer_id ON ocds.releases (buyer_id) WHERE buyer_id IS NOT NULL;

-- 6. Add geo columns to items (columns only — no ETL processing, data not available from SPSE/SiRUP)
ALTER TABLE ocds.items
    ADD COLUMN IF NOT EXISTS geo_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_lon DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_min_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_max_lat DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_min_lon DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geo_bbox_max_lon DOUBLE PRECISION;

CREATE INDEX IF NOT EXISTS idx_items_geolocation ON ocds.items (geo_lat, geo_lon);

-- 7. Drop old geocoding_cache
DROP TABLE IF EXISTS ocds.geocoding_cache;
