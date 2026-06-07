-- migrations/000080_drop_bo_crawler_v1.up.sql
--
-- Phase 2: Drop obsolete schema
-- bo_crawler_v1 data was migrated to llm_extraction schema via
-- scripts/migrate_llm_extractions_to_mahkamah_agung.sql
-- Raw crawl data (url_frontiers, extractions) is intentionally not preserved.
--
DROP SCHEMA IF EXISTS bo_crawler_v1 CASCADE;
