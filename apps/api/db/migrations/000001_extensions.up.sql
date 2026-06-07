-- ============================================
-- Production Extensions
-- ============================================

-- Enable pg_stat_statements (Query performance monitoring)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Enable pgcrypto (Cryptographic functions, UUID generation)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enable uuid-ossp (UUID generation functions)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_uuidv7 (UUIDv7 generation - time-ordered UUIDs)
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;

-- ============================================
-- Feature Extensions
-- ============================================

-- Enable pg_trgm (Trigram matching for fuzzy text search)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enable btree_gin (GIN index support for B-tree indexable types)
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Enable pgvector (Vector similarity search)
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable Apache AGE (Graph database extension)
CREATE EXTENSION IF NOT EXISTS age;

-- Load AGE into search path
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- Enable pg_search (Full-text search by ParadeDB)
CREATE EXTENSION IF NOT EXISTS pg_search;

-- ============================================
-- Verify All Extensions
-- ============================================
SELECT extname, extversion FROM pg_extension
WHERE extname IN (
    'pg_stat_statements',
    'pgcrypto',
    'uuid-ossp',
    'pg_uuidv7',
    'pg_trgm',
    'btree_gin',
    'vector',
    'age',
    'pg_search'
)
ORDER BY extname;
