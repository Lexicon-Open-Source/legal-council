-- Add trigram indexes for public SKPD master-data search.
-- pg_trgm is enabled in 000001, but keep this migration self-contained.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_opentender_skpd_code_text
ON crawler.opentender_skpd ((code::TEXT));

CREATE INDEX IF NOT EXISTS idx_opentender_skpd_name_trgm
ON crawler.opentender_skpd
USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_opentender_skpd_alt_name_trgm
ON crawler.opentender_skpd
USING gin (alt_name gin_trgm_ops)
WHERE alt_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_opentender_skpd_lpse_name_trgm
ON crawler.opentender_skpd
USING gin (lpse_name gin_trgm_ops)
WHERE lpse_name IS NOT NULL;
