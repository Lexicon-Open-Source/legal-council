-- Rollback: bo_crawler_v1 schema

DROP TABLE IF EXISTS bo_crawler_v1.llm_extractions;
DROP TABLE IF EXISTS bo_crawler_v1.extractions;
DROP TABLE IF EXISTS bo_crawler_v1.url_frontiers;
DROP SCHEMA IF EXISTS bo_crawler_v1;
