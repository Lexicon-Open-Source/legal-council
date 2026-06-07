-- Add functional indexes for SPSE tender JSONB fields
-- These improve query performance for analytics dashboard
--
-- NOTE: Standard B-tree indexes on JSONB paths (e.g., jadwal->>'mulai') do NOT
-- help with lateral joins via jsonb_array_elements() since the database must
-- iterate through all array elements regardless.
--
-- What DOES help:
-- 1. Expression indexes on jsonb_array_length() for existence checks
-- 2. GIN indexes for containment queries (@>, ?)
--
-- NOTE: Cannot use CONCURRENTLY here because golang-migrate runs migrations
-- inside a transaction block. For production, consider running these indexes
-- manually with CONCURRENTLY to avoid table locks.

-- Index on jadwal array length (used in efficiency filter: jsonb_array_length(jadwal) > 0)
CREATE INDEX IF NOT EXISTS idx_spse_tender_jadwal_length
ON crawler.spse_tenders (jsonb_array_length(COALESCE(jadwal, '[]'::jsonb)))
WHERE jadwal IS NOT NULL AND jadwal != '[]'::jsonb;

-- Index on pemenang_berkontrak array length (used in value-for-money filter)
CREATE INDEX IF NOT EXISTS idx_spse_tender_pemenang_length
ON crawler.spse_tenders (jsonb_array_length(COALESCE(pemenang_berkontrak, '[]'::jsonb)))
WHERE pemenang_berkontrak IS NOT NULL AND pemenang_berkontrak != '[]'::jsonb;

-- GIN index on jadwal for potential containment queries and general JSONB access
CREATE INDEX IF NOT EXISTS idx_spse_tender_jadwal_gin
ON crawler.spse_tenders USING GIN (jadwal jsonb_path_ops)
WHERE jadwal IS NOT NULL AND jadwal != '[]'::jsonb;

-- GIN index on pemenang_berkontrak for containment queries and general JSONB access
CREATE INDEX IF NOT EXISTS idx_spse_tender_pemenang_gin
ON crawler.spse_tenders USING GIN (pemenang_berkontrak jsonb_path_ops)
WHERE pemenang_berkontrak IS NOT NULL AND pemenang_berkontrak != '[]'::jsonb;
