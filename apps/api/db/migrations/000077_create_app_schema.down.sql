-- migrations/000077_create_app_schema.down.sql

DROP SCHEMA IF EXISTS app CASCADE;

-- Remove tier documentation comments
COMMENT ON SCHEMA crawler IS NULL;
COMMENT ON SCHEMA llm_extraction IS NULL;
COMMENT ON SCHEMA ocds IS NULL;
COMMENT ON SCHEMA entity_graph IS NULL;
COMMENT ON SCHEMA bo_v1 IS NULL;
COMMENT ON SCHEMA council_v1 IS NULL;
COMMENT ON SCHEMA bo_crawler_v1 IS NULL;
