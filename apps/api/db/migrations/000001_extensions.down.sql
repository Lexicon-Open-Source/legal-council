-- Drop extensions in reverse order
-- WARNING: Dropping extensions will cascade to dependent objects

-- ============================================
-- Feature Extensions
-- ============================================
DROP EXTENSION IF EXISTS pg_search CASCADE;
DROP EXTENSION IF EXISTS age CASCADE;
DROP EXTENSION IF EXISTS vector CASCADE;
DROP EXTENSION IF EXISTS btree_gin CASCADE;
DROP EXTENSION IF EXISTS pg_trgm CASCADE;

-- ============================================
-- Production Extensions
-- ============================================
DROP EXTENSION IF EXISTS pg_uuidv7 CASCADE;
DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
DROP EXTENSION IF EXISTS pg_stat_statements CASCADE;
