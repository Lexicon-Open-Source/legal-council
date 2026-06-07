-- Revert performance indexes for opentender_ocds_releases

-- Drop trigram index and restore B-tree index
DROP INDEX IF EXISTS crawler.idx_opentender_ocds_releases_buyer_trgm;
CREATE INDEX IF NOT EXISTS idx_opentender_ocds_releases_buyer
    ON crawler.opentender_ocds_releases(buyer_name)
    WHERE buyer_name IS NOT NULL;

-- Drop standalone OCID index
DROP INDEX IF EXISTS crawler.idx_opentender_ocds_releases_ocid;

-- Note: pg_trgm extension is left installed as other tables may use it
