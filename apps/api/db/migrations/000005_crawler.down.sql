-- Rollback: crawler schema

DROP TRIGGER IF EXISTS update_spse_tenders_updated_at ON crawler.spse_tenders;
DROP TRIGGER IF EXISTS update_bpk_regulations_updated_at ON crawler.bpk_regulations;
DROP TRIGGER IF EXISTS update_crawler_jobs_updated_at ON crawler.crawler_jobs;

DROP TABLE IF EXISTS crawler.spse_tenders;
DROP TABLE IF EXISTS crawler.bpk_regulations;
DROP TABLE IF EXISTS crawler.crawler_jobs;
DROP TABLE IF EXISTS crawler.alembic_version;

DROP FUNCTION IF EXISTS crawler.update_updated_at_column();
DROP TYPE IF EXISTS crawler.job_status;

DROP SCHEMA IF EXISTS crawler;
