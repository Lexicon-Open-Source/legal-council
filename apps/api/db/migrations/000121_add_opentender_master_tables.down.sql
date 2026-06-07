DROP TRIGGER IF EXISTS update_opentender_source_fund_updated_at ON crawler.opentender_source_fund;
DROP TRIGGER IF EXISTS update_opentender_skpd_updated_at ON crawler.opentender_skpd;
DROP TRIGGER IF EXISTS update_opentender_instansi_updated_at ON crawler.opentender_instansi;
DROP TRIGGER IF EXISTS update_opentender_lpse_updated_at ON crawler.opentender_lpse;

DROP INDEX IF EXISTS crawler.idx_opentender_skpd_lpse_code;
DROP INDEX IF EXISTS crawler.idx_opentender_instansi_type;

DROP TABLE IF EXISTS crawler.opentender_source_fund CASCADE;
DROP TABLE IF EXISTS crawler.opentender_skpd CASCADE;
DROP TABLE IF EXISTS crawler.opentender_instansi CASCADE;
DROP TABLE IF EXISTS crawler.opentender_lpse CASCADE;
