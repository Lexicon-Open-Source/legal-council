-- Create ParadeDB BM25 index on OCDS tender search materialized view
-- Indexes id (key), title, description, buyer_name, procuring_entity_name for full-text search
CREATE INDEX ocds_tender_search_idx ON ocds.tender_search_view
USING bm25 (id, title, description, buyer_name, procuring_entity_name)
WITH (key_field='id');

-- Create function to refresh materialized view
-- Call after ETL loads new OCDS data
CREATE OR REPLACE FUNCTION ocds.refresh_tender_search_view()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY ocds.tender_search_view;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION ocds.refresh_tender_search_view() IS
'Refreshes the tender search materialized view. Call after ETL loads new OCDS data.';
