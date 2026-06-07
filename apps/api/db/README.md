# Lexicon Database Migrations

Centralized PostgreSQL migrations for the Lexicon platform using [golang-migrate](https://github.com/golang-migrate/migrate).

## Prerequisites

- PostgreSQL 15+ with extensions (see below)
- golang-migrate CLI

```bash
# macOS
brew install golang-migrate

# Linux
curl -L https://github.com/golang-migrate/migrate/releases/download/v4.17.0/migrate.linux-amd64.tar.gz | tar xvz
sudo mv migrate /usr/local/bin/

# Go install
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

## Setup

```bash
cp .env.example .env
# Edit .env with your database URL
```

## Commands

```bash
make migrate-up              # Apply all pending migrations
make migrate-down            # Rollback one migration
make migrate-create name=... # Create new migration pair
```

## Required PostgreSQL Extensions

The following extensions must be available in your PostgreSQL installation:

### Production Extensions

| Extension | Purpose | Requires `shared_preload_libraries` |
|-----------|---------|-------------------------------------|
| `pg_stat_statements` | Query performance monitoring | Yes |
| `pgcrypto` | Cryptographic functions | No |
| `uuid-ossp` | UUID generation functions | No |
| `pg_uuidv7` | Time-ordered UUIDs | No |
| `pg_cron` | Job scheduler | Yes |

### Feature Extensions

| Extension | Purpose | Source |
|-----------|---------|--------|
| `pg_trgm` | Trigram fuzzy text search | PostgreSQL contrib |
| `btree_gin` | GIN index for B-tree types | PostgreSQL contrib |
| `vector` | Vector similarity search | [pgvector](https://github.com/pgvector/pgvector) |
| `age` | Graph database (Cypher) | [Apache AGE](https://age.apache.org/) |
| `pg_search` | BM25 full-text search | [ParadeDB](https://www.paradedb.com/) |

### postgresql.conf Configuration

```ini
shared_preload_libraries = 'pg_stat_statements,pg_cron,age'
```

## Migration Structure

```
migrations/
├── 000001_extensions.up.sql      # PostgreSQL extensions
├── 000001_extensions.down.sql
├── 000002_*.up.sql               # Schema migrations
├── 000002_*.down.sql
└── ...
```

## Creating Migrations

```bash
make migrate-create name=create_users_table
```

This creates:
- `migrations/NNNNNN_create_users_table.up.sql`
- `migrations/NNNNNN_create_users_table.down.sql`

## Best Practices

1. **Idempotency** - Use `IF NOT EXISTS` / `IF EXISTS`
2. **Reversibility** - Always write both up and down migrations
3. **Testing** - Run `up → down → up` before committing
4. **Atomic** - One logical change per migration
5. **No data in schema migrations** - Separate data migrations

## Dirty State Recovery

If a migration fails mid-execution:

```bash
# Check current version
migrate -path migrations -database "$DATABASE_URL" version

# Force to specific version (use with caution)
migrate -path migrations -database "$DATABASE_URL" force VERSION
```

## Integration with Services

Services using sqlc can reference these migrations:

```yaml
# sqlc.yaml
version: "2"
sql:
  - engine: "postgresql"
    schema: "../migrations/migrations/"  # Point to this repo
    queries: "internal/db/queries/"
    # ... rest of config
```

## License

Proprietary - Lexicon Indonesia
