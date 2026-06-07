DROP TRIGGER IF EXISTS update_sc_aob_sanctions_updated_at ON crawler.sc_aob_sanctions;
DROP TRIGGER IF EXISTS update_sc_investor_alerts_updated_at ON crawler.sc_investor_alerts;

DROP INDEX IF EXISTS crawler.idx_sc_aob_sanctions_natural_key;
DROP INDEX IF EXISTS crawler.idx_sc_aob_sanctions_auditor;
DROP INDEX IF EXISTS crawler.idx_sc_aob_sanctions_year;
DROP INDEX IF EXISTS crawler.idx_sc_aob_sanctions_auditor_trgm;
DROP INDEX IF EXISTS crawler.idx_sc_investor_alerts_name_unique;
DROP INDEX IF EXISTS crawler.idx_sc_investor_alerts_entity_type;
DROP INDEX IF EXISTS crawler.idx_sc_investor_alerts_name_trgm;

DROP TABLE IF EXISTS crawler.sc_aob_sanctions;
DROP TABLE IF EXISTS crawler.sc_investor_alerts;
