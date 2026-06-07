#!/usr/bin/env bash
set -euo pipefail

# Generate schema files by running migrations against a temporary database
# and dumping the resulting schema using pg_dump
#
# Prerequisites:
# - PostgreSQL 17 client tools (psql-17, pg_dump-17)
# - golang-migrate CLI
# - Running PostgreSQL server (lexicon-postgresql-server)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$PROJECT_DIR/migrations"
SCHEMA_DIR="$PROJECT_DIR/schemas"

# PostgreSQL tools
PSQL="${PSQL:-/opt/homebrew/bin/psql-17}"
PG_DUMP="${PG_DUMP:-/opt/homebrew/bin/pg_dump-17}"

# Database config
DB_HOST="${PGHOST:-localhost}"
DB_PORT="${PGPORT:-5432}"
DB_USER="${PGUSER:-postgres}"
DB_PASS="${PGPASSWORD:-postgres}"
DB_NAME="lexicon_schema_gen_$$"

export PGPASSWORD="$DB_PASS"

echo "==> Creating temporary database: $DB_NAME"
"$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"

cleanup() {
    echo "==> Cleaning up temporary database"
    "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Installing extensions"
"$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS age;
LOAD 'age';
CREATE EXTENSION IF NOT EXISTS pg_search;
"

MIGRATE_URL="postgres://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=disable"

echo "==> Running migrations"
migrate -database "$MIGRATE_URL" -path "$MIGRATIONS_DIR" force 1

# Run all migrations. If 000080 pre-flight check fails (empty llm_extraction table
# in clean-room DB), seed a dummy row and retry.
if ! migrate -database "$MIGRATE_URL" -path "$MIGRATIONS_DIR" up 2>/dev/null; then
    echo "==> Seeding data for pre-flight checks (clean-room database)"
    migrate -database "$MIGRATE_URL" -path "$MIGRATIONS_DIR" force 79
    "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        ALTER TABLE llm_extraction.mahkamah_agung_putusans DROP CONSTRAINT IF EXISTS fk_llm_ext_ma_crawler;
        INSERT INTO llm_extraction.mahkamah_agung_putusans (extraction_id, status) VALUES ('schema-gen-seed', 'pending');
    "
    migrate -database "$MIGRATE_URL" -path "$MIGRATIONS_DIR" up
fi

echo "==> Creating schema directory"
mkdir -p "$SCHEMA_DIR"
rm -f "$SCHEMA_DIR"/*.sql

# Dump each schema
SCHEMAS=("app" "bo_v1" "cms" "council_v1" "crawler" "entity_graph" "llm_extraction" "ocds" "screening")

for schema in "${SCHEMAS[@]}"; do
    echo "==> Dumping schema: $schema"
    "$PG_DUMP" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        --schema-only --no-owner --no-privileges \
        -n "$schema" "$DB_NAME" \
        | sed '/^\\restrict/d; /^\\unrestrict/d' \
        | cat -s \
        | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' \
        > "$SCHEMA_DIR/$schema.sql"
done

# Dump extensions
echo "==> Dumping extensions"
"$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "
SELECT 'CREATE EXTENSION IF NOT EXISTS ' || quote_ident(extname) || ';'
FROM pg_extension WHERE extname NOT IN ('plpgsql') ORDER BY extname;
" > "$SCHEMA_DIR/extensions.sql"

echo ""
echo "==> Schema files generated in: $SCHEMA_DIR"
ls -la "$SCHEMA_DIR"
