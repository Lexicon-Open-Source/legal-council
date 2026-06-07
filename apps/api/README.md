# Lexicon Backend

A minimal, production-ready Go backend for Lexicon using Chi router, SQLC, OpenAPI, PostgreSQL, and Redis. Includes a Python LLM service for AI-powered judicial deliberation via multi-agent architecture.

## Philosophy

**Start simple, add complexity when pain emerges.**

- No repository pattern (SQLC is the repository)
- No services layer initially (handlers call SQLC directly)
- Flat configuration structure
- No premature abstractions

## Features

| Domain | Description |
|--------|-------------|
| **Beneficial Ownership** | Company search, case detail, charts, LKPP blacklist data, chatbot |
| **Analytics** | Case trends, verdict counts, financial analysis, defendant profiles |
| **Council** | AI-powered judicial deliberation with multi-agent judges, streaming, PDF export |
| **Procurement** | OCDS v2 procurement data, analytics, distribution, trends |
| **Graph** | Procurement relationship visualization for D3.js |
| **Screening** | AML sanctions screening with BM25 search |
| **AML** | Anti-money laundering screening and egress |
| **Bulk** | Batch OCDS releases and AML actor data |

## Quick Start

### Prerequisites

- Go 1.25+
- Python 3.14+ (for LLM service)
- Node.js (for OpenAPI bundling via `@redocly/cli`)
- Make
- [uv](https://docs.astral.sh/uv/) (Python package manager)
- Access to shared infrastructure (PostgreSQL, Redis)

### Setup

```bash
# 1. Install dependencies and tools
make install          # Go dependencies + CLI tools
make llm-install      # Python dependencies (optional, for LLM service)

# 2. Create environment file
cp .env.example .env
# Edit .env with your database and Redis credentials

# 3. Apply database migrations
make migrate-up-dev

# 4. Generate code from OpenAPI and SQLC
make regenerate-all

# 5. Start development server with hot reload
make api-dev          # Go API on port 8000
make llm-dev          # LLM service on port 8001 (optional)
```

The API will be available at `http://localhost:8000`

### Health Check

```bash
curl http://localhost:8000/health
curl http://localhost:8000/ready
```

## Project Structure

```
backend/
├── cmd/
│   ├── api/main.go              # Server startup + graceful shutdown
│   └── gen-i18n-keys/           # i18n constant generator
├── api/                         # OpenAPI specification (modular)
│   ├── openapi.yaml             # Main spec (references subfiles)
│   ├── paths/                   # Split endpoint definitions
│   │   ├── analytics.yaml
│   │   ├── beneficial-ownership.yaml
│   │   ├── council.yaml
│   │   ├── procurement-v1.yaml
│   │   ├── graph.yaml
│   │   ├── screening.yaml
│   │   ├── aml.yaml
│   │   ├── bulk.yaml
│   │   └── health.yaml
│   └── schemas/                 # Reusable schema definitions
├── internal/
│   ├── api/
│   │   ├── api.gen.go           # Generated from OpenAPI
│   │   ├── handlers_*.go        # HTTP handlers (call SQLC directly)
│   │   ├── middleware_*.go      # Security, bot detection, telemetry
│   │   ├── routes.go            # Middleware stack + route setup
│   │   └── server.go            # Server struct with DB + Redis clients
│   ├── config/config.go         # Flat config struct
│   ├── db/
│   │   ├── queries/             # SQLC query files (.sql)
│   │   └── sqlc/                # Generated Go code
│   ├── i18n/                    # Internationalization (Indonesian + English)
│   ├── telemetry/               # OpenTelemetry integration
│   ├── storage/                 # S3-compatible storage (pre-signed URLs)
│   ├── httpclient/              # Secure HTTP client (SSRF protection)
│   └── testutil/                # Test utilities
├── llm/                         # Python LLM service
│   ├── src/council/
│   │   ├── agents/              # Strict, Humanist, Historian judges + Router
│   │   ├── routers/             # FastAPI route modules
│   │   ├── services/            # Business logic
│   │   ├── models/              # Pydantic models + generated.py from OpenAPI
│   │   └── db/sqlc/             # Generated Python SQLC code
│   ├── main.py                  # FastAPI app entry point
│   └── pyproject.toml           # Python dependencies
├── db/
│   ├── migrations/              # SQL migration files (up/down pairs)
│   └── schemas/                 # Generated schema dumps (CI validation)
├── docs/
│   ├── adr/                     # Architecture Decision Records
│   ├── sop/                     # Standard Operating Procedures
│   ├── reference/               # Component documentation
│   └── reports/                 # Test execution reports
└── .github/workflows/           # CI/CD pipelines
```

## Development Commands

### Go API

| Command | Description |
|---------|-------------|
| `make install` | Install Go dependencies and tools |
| `make api-dev` | Start server with hot reload |
| `make build` | Build production binary |
| `make test` | Run all tests (Go + Python) |
| `make test-go` | Run Go unit tests only |
| `make test-integration` | Run integration tests (requires `TEST_DATABASE_URL`) |
| `make lint` | Run golangci-lint |
| `make check` | Run lint + test |

### Code Generation

| Command | Description |
|---------|-------------|
| `make regenerate-all` | Regenerate all code (API + SQLC + Python models + i18n) |
| `make api-bundle` | Bundle split OpenAPI files into single spec |
| `make api-generate` | Generate Go server from OpenAPI |
| `make api-docs` | Generate interactive API docs (Redoc HTML) |
| `make sqlc-generate` | Generate Go + Python code from SQL queries |
| `make i18n-generate` | Generate typed i18n key constants from TOML |
| `make llm-models-generate` | Generate Python models from OpenAPI spec |
| `make check-generated` | Verify all generated code is in sync (CI) |

### Database Migrations

| Command | Description |
|---------|-------------|
| `make migrate-up-dev` | Apply pending migrations (dev) |
| `make migrate-down-dev` | Rollback one migration (dev) |
| `make migrate-status-dev` | Show current migration version (dev) |
| `make migrate-skip-dev v=N` | Force set migration version (dev) |
| `make migrate-create name=x` | Create new migration pair |
| `make schema-generate` | Generate schema dump files |
| `make schema-check` | Verify schema files match migrations (CI) |

Staging and production targets (`migrate-up-staging`, `migrate-up-prod`, etc.) require confirmation prompts.

### LLM Service (Python)

| Command | Description |
|---------|-------------|
| `make llm-install` | Install Python dependencies |
| `make llm-dev` | Start LLM service (port 8001) |
| `make llm-test` | Run pytest |
| `make llm-lint` | Run ruff linter |
| `make llm-format` | Format code with ruff |

### Docker

| Command | Description |
|---------|-------------|
| `make docker-build` | Build Docker images |
| `make docker-up` | Start services with docker-compose |
| `make docker-down` | Stop services |

## Development Workflow

### API-First Development

Always start with the OpenAPI spec. See [SOP-002](docs/sop/002-api-first-development.md).

```bash
# 1. Edit api/openapi.yaml (or files in api/paths/ and api/schemas/)
# 2. Regenerate code
make api-generate
# 3. Implement handler in internal/api/handlers_*.go
```

### Database Changes

See [SOP-003](docs/sop/003-database-changes.md).

```bash
# 1. Create migration
make migrate-create name=add_users_table

# 2. Write SQL in db/migrations/
# 3. Generate schema
make schema-generate

# 4. Add queries in internal/db/queries/
# 5. Generate Go + Python code
make sqlc-generate

# 6. Apply migration
make migrate-up-dev
```

### Internationalization

All user-facing API responses support Indonesian (default) and English. See [SOP-001](docs/sop/001-i18n.md).

```bash
# 1. Add keys to internal/i18n/locales/en.toml and id.toml
# 2. Generate typed constants
make i18n-generate
# 3. Use in handlers: i18n.T(ctx, i18n.MsgErrorKey)
```

Language detection is handled automatically via `Accept-Language` header middleware.

## Architecture

### LLM Service

The Python LLM service implements a multi-agent judicial deliberation system:

- **Strict Judge** — focuses on legal precedent and rule-of-law
- **Humanist Judge** — emphasizes justice, equity, and human impact
- **Historian Judge** — provides historical legal context
- **Router** — orchestrates the deliberation flow across judges

Uses LiteLLM for provider-agnostic LLM calls (Gemini primary, configurable fallback) and pgvector for semantic case search.

### When to Add Complexity

| Add This | When You See This |
|----------|-------------------|
| Services layer | Handler exceeds 100 lines |
| Repository pattern | SQLC becomes insufficient (unlikely) |
| Circuit breaker | LLM failure rate > 5% |
| Retry logic | Transient errors in production |
| NATS | Need async job processing |

See [ADR index](docs/adr/README.md) for all architectural decisions.

## Security

| Protection | Implementation |
|------------|----------------|
| SSRF | Secure HTTP client with host whitelist (`internal/httpclient/`) |
| SQL Injection | SQLC type-safe queries (never build SQL manually) |
| Rate Limiting | 100 req/min per IP, fail-closed (Redis) |
| Bot Detection | Multi-signal detection (headers, behavior, rate) with 429 blocking |
| Turnstile | Cloudflare Turnstile verification with graceful degradation |
| Body Size | 1MB max via middleware |
| Security Headers | X-Frame-Options, HSTS, nosniff, Referrer-Policy |
| CORS | HTTPS-only in production, environment-aware origins |

See [SOP-005](docs/sop/005-security.md) and [ADR-0008](docs/adr/0008-security-middleware-stack.md).

## Observability

OpenTelemetry integration for both Go API and Python LLM service, with SigNoz as the backend:

- **Traces** — distributed request tracing across Go and Python services
- **Metrics** — request latency, error rates, database query performance
- **Logs** — structured logging with trace correlation

See [ADR-0009](docs/adr/0009-logging-and-opentelemetry-observability.md) and [SOP-004](docs/sop/004-logging-and-telemetry.md).

## Deployment

### Build Docker Image

```bash
docker build -t lexicon-backend:latest .
```

### Key Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `REDIS_URL` | Yes | Redis connection string |
| `LLM_SERVICE_URL` | Yes | LLM service endpoint |
| `LLM_API_KEY` | Yes | LLM service API key |
| `GEMINI_API_KEY` | Yes | Gemini API key for AI processing |
| `LLM_MODEL` | No | Primary LLM model (default: `gemini/gemini-2.5-flash`) |
| `LLM_FALLBACK_MODEL` | No | Fallback LLM model |
| `ENVIRONMENT` | No | `development`, `staging`, or `production` |
| `OTEL_ENABLED` | No | Enable OpenTelemetry (`true`/`false`) |
| `TURNSTILE_ENABLED` | No | Enable Cloudflare Turnstile verification |
| `S3_ENDPOINT` | No | S3-compatible storage for PDF pre-signed URLs |

See `.env.example` for all options and [SOP-012](docs/sop/012-environment-variable-checklist.md).

## CI/CD

GitHub Actions workflows run on every push and PR:

- Linting (golangci-lint, ruff)
- Unit tests (Go + Python)
- Integration tests with PostgreSQL and Redis
- Generated code sync check (`make check-generated`)
- Schema validation (`make schema-check`)
- Docker image build and push to GHCR (main branch only)

## Documentation

- [CLAUDE.md](CLAUDE.md) — Development guidelines for AI assistants
- [ADRs](docs/adr/README.md) — Architecture Decision Records (16 decisions)
- [SOPs](docs/sop/README.md) — Standard Operating Procedures (12 workflows)
- [Reference](docs/reference/README.md) — Component guides (LLM personalities, SigNoz alerts, egress API)

## License

MIT
