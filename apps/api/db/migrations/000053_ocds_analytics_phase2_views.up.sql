-- OCDS Analytics Phase 2 Materialized Views
-- Provides OpenTender.net dashboard parity
-- Prerequisites: Migration 000052 (performance indexes) must be applied first

-- 1. Monthly Trends View
CREATE MATERIALIZED VIEW ocds.monthly_trends_mv AS
WITH tender_months AS (
    SELECT
        COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
        TO_CHAR(t.tender_period_start_date, 'YYYY-MM') as month,
        t.id as tender_id
    FROM ocds.tender t
    JOIN ocds.releases r ON r.id = t.release_id
    LEFT JOIN ocds.planning p ON p.release_id = r.id
    WHERE t.tender_period_start_date IS NOT NULL
)
SELECT
    tm.fiscal_year,
    tm.month,
    COUNT(DISTINCT tm.tender_id)::BIGINT as tender_count,
    COUNT(DISTINCT a.id)::BIGINT as award_count,
    COALESCE(SUM(a.value_amount), 0)::NUMERIC as total_value,
    NOW() as refreshed_at
FROM tender_months tm
LEFT JOIN ocds.tender t ON t.id = tm.tender_id
LEFT JOIN ocds.awards a ON a.release_id = t.release_id AND a.status = 'active'
GROUP BY tm.fiscal_year, tm.month
ORDER BY tm.fiscal_year DESC, tm.month DESC;

CREATE UNIQUE INDEX ON ocds.monthly_trends_mv (fiscal_year, month);

-- 2. Procurement Type Distribution
CREATE MATERIALIZED VIEW ocds.procurement_type_dist_mv AS
SELECT
    COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
    COALESCE(t.main_procurement_category, 'unknown') as procurement_type,
    COUNT(*)::BIGINT as tender_count,
    COALESCE(SUM(a.value_amount), 0)::NUMERIC as total_value,
    NOW() as refreshed_at
FROM ocds.tender t
JOIN ocds.releases r ON r.id = t.release_id
LEFT JOIN ocds.planning p ON p.release_id = r.id
LEFT JOIN ocds.awards a ON a.release_id = r.id AND a.status = 'active'
GROUP BY COALESCE(p.fiscal_year, 'Unknown'), COALESCE(t.main_procurement_category, 'unknown');

CREATE UNIQUE INDEX ON ocds.procurement_type_dist_mv (fiscal_year, procurement_type);

-- 3. Tender Status Distribution
CREATE MATERIALIZED VIEW ocds.tender_status_dist_mv AS
SELECT
    COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
    CASE
        WHEN t.status IN ('cancelled', 'withdrawn', 'unsuccessful') THEN 'cancelled'
        ELSE 'completed'
    END as status,
    COUNT(*)::BIGINT as tender_count,
    NOW() as refreshed_at
FROM ocds.tender t
JOIN ocds.releases r ON r.id = t.release_id
LEFT JOIN ocds.planning p ON p.release_id = r.id
GROUP BY COALESCE(p.fiscal_year, 'Unknown'),
    CASE WHEN t.status IN ('cancelled', 'withdrawn', 'unsuccessful') THEN 'cancelled' ELSE 'completed' END;

CREATE UNIQUE INDEX ON ocds.tender_status_dist_mv (fiscal_year, status);

-- 4. KLPD Ranking with HHI
CREATE MATERIALIZED VIEW ocds.klpd_ranking_mv AS
WITH provider_shares AS (
    -- Calculate each provider's share within a KLPD
    SELECT
        pe.id as klpd_id,
        pe.name as klpd_name,
        sup.id as provider_id,
        SUM(a.value_amount) as provider_value,
        SUM(SUM(a.value_amount)) OVER (PARTITION BY pe.id) as klpd_total_value
    FROM ocds.tender t
    JOIN ocds.parties pe ON pe.id = t.procuring_entity_id
    JOIN ocds.awards a ON a.release_id = t.release_id AND a.status = 'active'
    JOIN ocds.award_suppliers aws ON aws.award_id = a.id
    JOIN ocds.parties sup ON sup.id = aws.party_id
    GROUP BY pe.id, pe.name, sup.id
),
hhi_calculation AS (
    -- HHI = sum of squared market shares (as percentages)
    SELECT
        klpd_id,
        klpd_name,
        SUM(POWER((provider_value / NULLIF(klpd_total_value, 0)) * 100, 2))::NUMERIC(10,5) as hhi
    FROM provider_shares
    GROUP BY klpd_id, klpd_name
),
klpd_stats AS (
    SELECT
        pe.id as klpd_id,
        pe.name as klpd_name,
        COUNT(DISTINCT t.id)::BIGINT as contract_count,
        COUNT(DISTINCT aws.party_id)::INTEGER as provider_count,
        COUNT(DISTINCT r.buyer_id)::INTEGER as satker_count,
        COALESCE(SUM(a.value_amount), 0)::NUMERIC as total_value
    FROM ocds.tender t
    JOIN ocds.releases r ON r.id = t.release_id
    JOIN ocds.parties pe ON pe.id = t.procuring_entity_id
    LEFT JOIN ocds.awards a ON a.release_id = r.id AND a.status = 'active'
    LEFT JOIN ocds.award_suppliers aws ON aws.award_id = a.id
    GROUP BY pe.id, pe.name
)
SELECT
    ks.klpd_id,
    ks.klpd_name,
    -- Score: weighted combination (lower HHI = higher score)
    LEAST(100, GREATEST(0,
        (100 - COALESCE(hc.hhi / 100, 0))::INTEGER
    ))::INTEGER as score,
    ks.satker_count,
    ks.provider_count,
    COALESCE(hc.hhi, 0)::NUMERIC(10,5) as hhi,
    ks.contract_count,
    ks.total_value,
    NOW() as refreshed_at
FROM klpd_stats ks
LEFT JOIN hhi_calculation hc ON hc.klpd_id = ks.klpd_id
ORDER BY score DESC;

CREATE UNIQUE INDEX ON ocds.klpd_ranking_mv (klpd_id);
CREATE INDEX ON ocds.klpd_ranking_mv (score DESC);
CREATE INDEX ON ocds.klpd_ranking_mv (total_value DESC NULLS LAST);
CREATE INDEX ON ocds.klpd_ranking_mv (contract_count DESC);
CREATE INDEX ON ocds.klpd_ranking_mv (hhi DESC);

-- 5. Duration Metrics (Announcement to Award)
CREATE MATERIALIZED VIEW ocds.duration_metrics_mv AS
WITH duration_calc AS (
    SELECT
        COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
        EXTRACT(DAY FROM (a.date - t.tender_period_start_date))::INTEGER as days_to_award
    FROM ocds.tender t
    JOIN ocds.releases r ON r.id = t.release_id
    LEFT JOIN ocds.planning p ON p.release_id = r.id
    JOIN ocds.awards a ON a.release_id = r.id AND a.status = 'active'
    WHERE t.tender_period_start_date IS NOT NULL
      AND a.date IS NOT NULL
      AND a.date > t.tender_period_start_date
)
SELECT
    fiscal_year,
    CASE
        WHEN days_to_award <= 30 THEN '0-30 days'
        WHEN days_to_award <= 60 THEN '31-60 days'
        WHEN days_to_award <= 90 THEN '61-90 days'
        WHEN days_to_award <= 120 THEN '91-120 days'
        ELSE '>120 days'
    END as bucket,
    COUNT(*)::BIGINT as tender_count,
    AVG(days_to_award)::NUMERIC(10,2) as avg_days,
    NOW() as refreshed_at
FROM duration_calc
GROUP BY fiscal_year,
    CASE
        WHEN days_to_award <= 30 THEN '0-30 days'
        WHEN days_to_award <= 60 THEN '31-60 days'
        WHEN days_to_award <= 90 THEN '61-90 days'
        WHEN days_to_award <= 120 THEN '91-120 days'
        ELSE '>120 days'
    END;

CREATE UNIQUE INDEX ON ocds.duration_metrics_mv (fiscal_year, bucket);

-- 6. Text Quality Metrics
CREATE MATERIALIZED VIEW ocds.text_quality_mv AS
WITH title_lengths AS (
    SELECT
        COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
        'title' as field_type,
        CASE
            WHEN LENGTH(t.title) <= 20 THEN '0-20'
            WHEN LENGTH(t.title) <= 40 THEN '21-40'
            WHEN LENGTH(t.title) <= 60 THEN '41-60'
            WHEN LENGTH(t.title) <= 80 THEN '61-80'
            ELSE '>80'
        END as bucket
    FROM ocds.tender t
    JOIN ocds.releases r ON r.id = t.release_id
    LEFT JOIN ocds.planning p ON p.release_id = r.id
    WHERE t.title IS NOT NULL
),
description_lengths AS (
    SELECT
        COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
        'description' as field_type,
        CASE
            WHEN LENGTH(COALESCE(t.description, '')) <= 60 THEN '0-60'
            WHEN LENGTH(t.description) <= 120 THEN '61-120'
            WHEN LENGTH(t.description) <= 180 THEN '121-180'
            WHEN LENGTH(t.description) <= 240 THEN '181-240'
            ELSE '>240'
        END as bucket
    FROM ocds.tender t
    JOIN ocds.releases r ON r.id = t.release_id
    LEFT JOIN ocds.planning p ON p.release_id = r.id
)
SELECT fiscal_year, field_type, bucket, COUNT(*)::BIGINT as tender_count, NOW() as refreshed_at
FROM (SELECT * FROM title_lengths UNION ALL SELECT * FROM description_lengths) combined
GROUP BY fiscal_year, field_type, bucket;

CREATE UNIQUE INDEX ON ocds.text_quality_mv (fiscal_year, field_type, bucket);

-- 7. Value Savings Distribution (HPS vs Contract)
CREATE MATERIALIZED VIEW ocds.value_savings_mv AS
WITH savings_calc AS (
    SELECT
        COALESCE(p.fiscal_year, 'Unknown') as fiscal_year,
        p.budget_amount as hps_value,
        COALESCE(a.value_amount, c.value_amount) as contract_value,
        CASE
            WHEN p.budget_amount > 0 AND COALESCE(a.value_amount, c.value_amount) IS NOT NULL
            THEN ((p.budget_amount - COALESCE(a.value_amount, c.value_amount)) / p.budget_amount * 100)
            ELSE NULL
        END as savings_pct
    FROM ocds.planning p
    JOIN ocds.releases r ON r.id = p.release_id
    LEFT JOIN ocds.awards a ON a.release_id = r.id AND a.status = 'active'
    LEFT JOIN ocds.contracts c ON c.release_id = r.id
    WHERE p.budget_amount IS NOT NULL AND p.budget_amount > 0
)
SELECT
    fiscal_year,
    CASE
        WHEN savings_pct IS NULL THEN 'no_data'
        WHEN savings_pct < 0 THEN 'over_budget'
        WHEN savings_pct <= 10 THEN '0-10%'
        WHEN savings_pct <= 20 THEN '11-20%'
        WHEN savings_pct <= 30 THEN '21-30%'
        ELSE '>30%'
    END as bucket,
    COUNT(*)::BIGINT as tender_count,
    ROUND(AVG(savings_pct)::NUMERIC, 2) as avg_savings_pct,
    SUM(hps_value)::NUMERIC as total_hps_value,
    SUM(contract_value)::NUMERIC as total_contract_value,
    NOW() as refreshed_at
FROM savings_calc
WHERE savings_pct IS NOT NULL
GROUP BY fiscal_year,
    CASE
        WHEN savings_pct IS NULL THEN 'no_data'
        WHEN savings_pct < 0 THEN 'over_budget'
        WHEN savings_pct <= 10 THEN '0-10%'
        WHEN savings_pct <= 20 THEN '11-20%'
        WHEN savings_pct <= 30 THEN '21-30%'
        ELSE '>30%'
    END;

CREATE UNIQUE INDEX ON ocds.value_savings_mv (fiscal_year, bucket);

-- 8. Provider Tenure Distribution (New vs Existing)
CREATE MATERIALIZED VIEW ocds.provider_tenure_mv AS
WITH provider_first_appearance AS (
    SELECT
        sup.id as provider_id,
        MIN(EXTRACT(YEAR FROM t.tender_period_start_date))::INTEGER as first_year
    FROM ocds.parties sup
    JOIN ocds.award_suppliers aws ON aws.party_id = sup.id
    JOIN ocds.awards a ON a.id = aws.award_id
    JOIN ocds.tender t ON t.release_id = a.release_id
    WHERE 'supplier' = ANY(sup.roles)
      AND t.tender_period_start_date IS NOT NULL
    GROUP BY sup.id
),
provider_yearly_stats AS (
    SELECT
        COALESCE(pl.fiscal_year, 'Unknown') as fiscal_year,
        pfa.provider_id,
        CASE
            WHEN pfa.first_year = EXTRACT(YEAR FROM t.tender_period_start_date)::INTEGER
            THEN 'new' ELSE 'existing'
        END as tenure,
        SUM(a.value_amount) as provider_value
    FROM provider_first_appearance pfa
    JOIN ocds.award_suppliers aws ON aws.party_id = pfa.provider_id
    JOIN ocds.awards a ON a.id = aws.award_id AND a.status = 'active'
    JOIN ocds.tender t ON t.release_id = a.release_id
    LEFT JOIN ocds.planning pl ON pl.release_id = a.release_id
    WHERE t.tender_period_start_date IS NOT NULL
    GROUP BY COALESCE(pl.fiscal_year, 'Unknown'), pfa.provider_id,
        CASE WHEN pfa.first_year = EXTRACT(YEAR FROM t.tender_period_start_date)::INTEGER
             THEN 'new' ELSE 'existing' END
)
SELECT
    fiscal_year,
    tenure,
    COUNT(DISTINCT provider_id)::BIGINT as provider_count,
    COALESCE(SUM(provider_value), 0)::NUMERIC as total_value,
    NOW() as refreshed_at
FROM provider_yearly_stats
GROUP BY fiscal_year, tenure;

CREATE UNIQUE INDEX ON ocds.provider_tenure_mv (fiscal_year, tenure);

-- Update refresh function to include Phase 2 views
CREATE OR REPLACE FUNCTION ocds.refresh_analytics_views()
RETURNS void AS $$
BEGIN
    -- Phase 1 views (existing)
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.analytics_summary_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.bidder_distribution_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.contractor_ranking_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.blacklist_matches_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.verdict_matches_mv;

    -- Phase 2 views (new)
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.monthly_trends_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.procurement_type_dist_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.tender_status_dist_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.klpd_ranking_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.duration_metrics_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.text_quality_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.value_savings_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.provider_tenure_mv;
END;
$$ LANGUAGE plpgsql;

-- Initial population (required before CONCURRENTLY can be used)
REFRESH MATERIALIZED VIEW ocds.monthly_trends_mv;
REFRESH MATERIALIZED VIEW ocds.procurement_type_dist_mv;
REFRESH MATERIALIZED VIEW ocds.tender_status_dist_mv;
REFRESH MATERIALIZED VIEW ocds.klpd_ranking_mv;
REFRESH MATERIALIZED VIEW ocds.duration_metrics_mv;
REFRESH MATERIALIZED VIEW ocds.text_quality_mv;
REFRESH MATERIALIZED VIEW ocds.value_savings_mv;
REFRESH MATERIALIZED VIEW ocds.provider_tenure_mv;

COMMENT ON MATERIALIZED VIEW ocds.monthly_trends_mv IS 'Monthly procurement trends for temporal analysis';
COMMENT ON MATERIALIZED VIEW ocds.procurement_type_dist_mv IS 'Tender distribution by procurement category (goods/works/services)';
COMMENT ON MATERIALIZED VIEW ocds.tender_status_dist_mv IS 'Completed vs cancelled tender proportion';
COMMENT ON MATERIALIZED VIEW ocds.klpd_ranking_mv IS 'KLPD ranking with HHI market concentration scores';
COMMENT ON MATERIALIZED VIEW ocds.duration_metrics_mv IS 'Announcement-to-award duration buckets';
COMMENT ON MATERIALIZED VIEW ocds.text_quality_mv IS 'Title and description length quality metrics';
COMMENT ON MATERIALIZED VIEW ocds.value_savings_mv IS 'HPS vs contract value savings distribution';
COMMENT ON MATERIALIZED VIEW ocds.provider_tenure_mv IS 'New vs existing provider distribution per fiscal year';
