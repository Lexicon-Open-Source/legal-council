-- Create materialized view for optimized OCDS tender search
-- Uses pure OCDS schema - no crawler dependencies
-- Uses DISTINCT ON pattern to get latest release per OCID
-- Idempotent: drop first if exists to ensure definition matches
DROP MATERIALIZED VIEW IF EXISTS ocds.tender_search_view;

CREATE MATERIALIZED VIEW ocds.tender_search_view AS
SELECT DISTINCT ON (r.ocid)
    t.id,
    r.ocid,
    r.release_id,
    t.tender_id,
    t.title,
    t.description,
    t.status,
    t.procurement_method,
    t.procurement_method_details,
    t.procurement_method_rationale,
    t.main_procurement_category,
    t.additional_procurement_categories,
    t.number_of_tenderers,
    t.has_enquiries,
    t.eligibility_criteria,
    t.submission_method,
    t.submission_method_details,
    t.tender_period_start_date,
    t.tender_period_end_date,
    t.enquiry_period_start_date,
    t.enquiry_period_end_date,
    t.award_criteria,
    t.award_criteria_details,
    t.value_amount,
    t.value_currency,
    t.min_value_amount,
    t.location_description,
    -- Buyer/Institution info from parties
    buyer.name AS buyer_name,
    buyer.identifier_id AS buyer_identifier,
    -- Procuring entity info
    pe.name AS procuring_entity_name,
    pe.identifier_id AS procuring_entity_identifier,
    -- Budget/Planning info
    p.fiscal_year,
    p.budget_amount,
    p.budget_source,
    -- Source tracking
    r.source_system,
    r.source_id,
    r.source_url,
    -- Metadata
    r.date AS release_date,
    t.created_at,
    t.updated_at
FROM ocds.releases r
JOIN ocds.tender t ON t.release_id = r.id
LEFT JOIN ocds.parties buyer ON buyer.id = r.buyer_id
LEFT JOIN ocds.parties pe ON pe.id = t.procuring_entity_id
LEFT JOIN ocds.planning p ON p.release_id = r.id
WHERE t.status IS NULL OR t.status != 'cancelled'
ORDER BY r.ocid, r.date DESC;

-- Create unique index (required for CONCURRENTLY refresh)
CREATE UNIQUE INDEX idx_tender_search_view_id
ON ocds.tender_search_view(id);

-- Create B-tree indexes for exact match filters
CREATE INDEX idx_tsv_fiscal_year
ON ocds.tender_search_view(fiscal_year);

CREATE INDEX idx_tsv_main_procurement_category
ON ocds.tender_search_view(main_procurement_category);

CREATE INDEX idx_tsv_status
ON ocds.tender_search_view(status);

CREATE INDEX idx_tsv_source_id
ON ocds.tender_search_view(source_id);

CREATE INDEX idx_tsv_ocid
ON ocds.tender_search_view(ocid);

-- Create GIN trigram index for buyer_name (fuzzy matching for institution search)
CREATE INDEX idx_tsv_buyer_name
ON ocds.tender_search_view USING gin(buyer_name gin_trgm_ops);

-- Create composite index for common filter combinations
CREATE INDEX idx_tsv_year_category_status
ON ocds.tender_search_view(fiscal_year, main_procurement_category, status);

-- Create index for value sorting
CREATE INDEX idx_tsv_value_amount
ON ocds.tender_search_view(value_amount DESC NULLS LAST);

-- Create index for date sorting
CREATE INDEX idx_tsv_created_at
ON ocds.tender_search_view(created_at DESC);

CREATE INDEX idx_tsv_release_date
ON ocds.tender_search_view(release_date DESC);
