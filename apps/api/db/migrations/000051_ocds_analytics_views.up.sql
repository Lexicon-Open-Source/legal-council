-- OCDS Analytics Materialized Views
-- Provides pre-computed analytics for the OCDS Procurement Analytics Dashboard

-- Enable pg_trgm for future fuzzy matching (Phase 2)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create indexes for efficient matching
CREATE INDEX IF NOT EXISTS idx_parties_name_normalized
    ON ocds.parties (LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]', '', 'g')));
CREATE INDEX IF NOT EXISTS idx_blacklist_name_normalized
    ON crawler.lkpp_blacklist_entries (LOWER(REGEXP_REPLACE(provider_name, '[^a-zA-Z0-9]', '', 'g')));
CREATE INDEX IF NOT EXISTS idx_cases_subject_normalized_btree
    ON bo_v1.cases (LOWER(REGEXP_REPLACE(subject, '[^a-zA-Z0-9]', '', 'g')));

-- 1. Combined Summary View (replaces 3 separate views)
CREATE MATERIALIZED VIEW ocds.analytics_summary_mv AS
WITH tender_stats AS (
    SELECT
        COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
        t.main_procurement_category as category,
        CASE
            WHEN pe.name ILIKE '%kementerian%' THEN 'central'
            WHEN pe.name ILIKE '%polri%' THEN 'central'
            WHEN pe.name ILIKE '%pemerintah kabupaten%' THEN 'regional'
            WHEN pe.name ILIKE '%pemerintah kota%' THEN 'regional'
            WHEN pe.name ILIKE '%provinsi%' THEN 'regional'
            ELSE 'other'
        END as government_level,
        t.id as tender_id,
        t.release_id,
        COALESCE(t.number_of_tenderers, (
            SELECT COUNT(*) FROM ocds.tender_tenderers tt WHERE tt.tender_id = t.id
        ))::INTEGER as bid_count
    FROM ocds.tender t
    JOIN ocds.releases r ON r.id = t.release_id
    LEFT JOIN ocds.planning p ON p.release_id = r.id
    LEFT JOIN ocds.parties pe ON pe.id = t.procuring_entity_id
    WHERE t.status IS NULL OR t.status NOT IN ('cancelled', 'withdrawn')
)
SELECT
    ts.fiscal_year,
    COALESCE(ts.category, 'unknown') as category,
    ts.government_level,
    COUNT(DISTINCT ts.tender_id)::BIGINT as total_tenders,
    COUNT(DISTINCT a.id)::BIGINT as total_awards,
    COALESCE(SUM(a.value_amount), 0)::NUMERIC as total_value,
    AVG(ts.bid_count)::NUMERIC(10,2) as avg_bids_per_tender,
    (COUNT(CASE WHEN ts.bid_count <= 1 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0))::NUMERIC(5,2) as single_bidder_rate,
    NOW() as refreshed_at
FROM tender_stats ts
LEFT JOIN ocds.awards a ON a.release_id = ts.release_id AND a.status = 'active'
GROUP BY ts.fiscal_year, COALESCE(ts.category, 'unknown'), ts.government_level;

CREATE UNIQUE INDEX ON ocds.analytics_summary_mv (fiscal_year, category, government_level);

-- 2. Bidder Distribution (histogram buckets)
CREATE MATERIALIZED VIEW ocds.bidder_distribution_mv AS
WITH tender_bid_counts AS (
    SELECT
        COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
        COALESCE(t.number_of_tenderers, (SELECT COUNT(*) FROM ocds.tender_tenderers tt WHERE tt.tender_id = t.id))::INTEGER as bid_count
    FROM ocds.tender t
    JOIN ocds.releases r ON r.id = t.release_id
    LEFT JOIN ocds.planning p ON p.release_id = r.id
    WHERE t.status IS NULL OR t.status NOT IN ('cancelled', 'withdrawn')
)
SELECT
    fiscal_year,
    CASE
        WHEN bid_count = 1 THEN '1'
        WHEN bid_count = 2 THEN '2'
        WHEN bid_count = 3 THEN '3'
        WHEN bid_count = 4 THEN '4'
        ELSE '5+'
    END as bucket,
    COUNT(*)::BIGINT as tender_count,
    NOW() as refreshed_at
FROM tender_bid_counts
WHERE bid_count > 0
GROUP BY fiscal_year,
    CASE
        WHEN bid_count = 1 THEN '1'
        WHEN bid_count = 2 THEN '2'
        WHEN bid_count = 3 THEN '3'
        WHEN bid_count = 4 THEN '4'
        ELSE '5+'
    END;

CREATE UNIQUE INDEX ON ocds.bidder_distribution_mv (fiscal_year, bucket);

-- 3. Top Contractors Ranking
CREATE MATERIALIZED VIEW ocds.contractor_ranking_mv AS
SELECT
    p.id as party_id,
    p.name as party_name,
    COUNT(DISTINCT a.id)::BIGINT as total_contracts,
    COALESCE(SUM(a.value_amount), 0)::NUMERIC as total_value,
    COUNT(DISTINCT t.procuring_entity_id)::INTEGER as procuring_entities_count,
    NOW() as refreshed_at
FROM ocds.award_suppliers aws
JOIN ocds.awards a ON a.id = aws.award_id
JOIN ocds.parties p ON p.id = aws.party_id
JOIN ocds.tender t ON t.release_id = a.release_id
WHERE a.status = 'active'
GROUP BY p.id, p.name
ORDER BY total_value DESC NULLS LAST;

CREATE UNIQUE INDEX ON ocds.contractor_ranking_mv (party_id);
CREATE INDEX ON ocds.contractor_ranking_mv (total_value DESC NULLS LAST);

-- 4. Blacklist Matches (EXACT match only - no CROSS JOIN)
CREATE MATERIALIZED VIEW ocds.blacklist_matches_mv AS
WITH normalized_parties AS (
    SELECT
        id as party_id,
        name as party_name,
        LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]', '', 'g')) as normalized_name
    FROM ocds.parties
    WHERE 'supplier' = ANY(roles) OR 'tenderer' = ANY(roles)
),
normalized_blacklist AS (
    SELECT
        id as entry_id,
        provider_name,
        status,
        LOWER(REGEXP_REPLACE(provider_name, '[^a-zA-Z0-9]', '', 'g')) as normalized_name
    FROM crawler.lkpp_blacklist_entries
)
SELECT
    p.party_id as ocds_party_id,
    b.entry_id as lkpp_entry_id,
    'exact'::VARCHAR as match_type,
    p.party_name as ocds_party_name,
    b.provider_name as lkpp_provider_name,
    b.status as blacklist_status,
    NOW() as refreshed_at
FROM normalized_parties p
JOIN normalized_blacklist b ON p.normalized_name = b.normalized_name
WHERE p.normalized_name != ''; -- Exclude empty names

CREATE UNIQUE INDEX ON ocds.blacklist_matches_mv (ocds_party_id, lkpp_entry_id);
CREATE INDEX ON ocds.blacklist_matches_mv (ocds_party_name);

-- 5. Verdict Matches (EXACT match only - no CROSS JOIN)
CREATE MATERIALIZED VIEW ocds.verdict_matches_mv AS
WITH normalized_parties AS (
    SELECT
        id as party_id,
        name as party_name,
        LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]', '', 'g')) as normalized_name
    FROM ocds.parties
    WHERE 'supplier' = ANY(roles) OR 'tenderer' = ANY(roles)
),
normalized_cases AS (
    SELECT
        id as case_id,
        subject,
        case_type,
        LOWER(REGEXP_REPLACE(subject, '[^a-zA-Z0-9]', '', 'g')) as normalized_name
    FROM bo_v1.cases
    WHERE status = 1
)
SELECT
    p.party_id as ocds_party_id,
    c.case_id,
    'exact'::VARCHAR as match_type,
    p.party_name as ocds_party_name,
    c.subject as case_subject,
    c.case_type,
    NOW() as refreshed_at
FROM normalized_parties p
JOIN normalized_cases c ON p.normalized_name = c.normalized_name
WHERE p.normalized_name != ''; -- Exclude empty names

CREATE UNIQUE INDEX ON ocds.verdict_matches_mv (ocds_party_id, case_id);
CREATE INDEX ON ocds.verdict_matches_mv (ocds_party_name);

-- Refresh function
CREATE OR REPLACE FUNCTION ocds.refresh_analytics_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.analytics_summary_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.bidder_distribution_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.contractor_ranking_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.blacklist_matches_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.verdict_matches_mv;
END;
$$ LANGUAGE plpgsql;

-- Initial population (required before CONCURRENTLY can be used)
REFRESH MATERIALIZED VIEW ocds.analytics_summary_mv;
REFRESH MATERIALIZED VIEW ocds.bidder_distribution_mv;
REFRESH MATERIALIZED VIEW ocds.contractor_ranking_mv;
REFRESH MATERIALIZED VIEW ocds.blacklist_matches_mv;
REFRESH MATERIALIZED VIEW ocds.verdict_matches_mv;

COMMENT ON FUNCTION ocds.refresh_analytics_views() IS
    'Refresh all analytics materialized views. Call via pg_cron every 6 hours.';
