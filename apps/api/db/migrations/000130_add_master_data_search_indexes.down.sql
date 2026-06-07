DROP INDEX IF EXISTS crawler.idx_opentender_skpd_lpse_name_trgm;
DROP INDEX IF EXISTS crawler.idx_opentender_skpd_alt_name_trgm;
DROP INDEX IF EXISTS crawler.idx_opentender_skpd_name_trgm;
DROP INDEX IF EXISTS crawler.idx_opentender_skpd_code_text;

-- pg_trgm is shared by other search indexes; leave the extension installed.
