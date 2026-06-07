-- migrations/000080_drop_bo_crawler_v1.down.sql
--
-- Recreate empty bo_crawler_v1 schema structure.
-- Data cannot be recovered — this is a one-way migration.

CREATE SCHEMA IF NOT EXISTS bo_crawler_v1;
COMMENT ON SCHEMA bo_crawler_v1 IS 'DEPRECATED: Recreated as empty schema for rollback. Original data not preserved.';
