-- Rollback: bo_v1 schema

DROP TRIGGER IF EXISTS cases_fulltext_search_index_update ON bo_v1.cases;
DROP TABLE IF EXISTS bo_v1.cases;
DROP TABLE IF EXISTS bo_v1.draft_cases;
DROP TABLE IF EXISTS bo_v1.personal_access_tokens;
DROP TABLE IF EXISTS bo_v1.password_reset_tokens;
DROP TABLE IF EXISTS bo_v1.users;
DROP SCHEMA IF EXISTS bo_v1;
