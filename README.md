# legal-council

Standalone Turborepo for the **Legal Council** product (production: <https://counsel.lexicon.id>) — extracted from the Lexicon monorepo and Go backend.

A multi-agent AI "council of judges" (Hakim Legalis / Humanis / Sejarawan) that
deliberates Indonesian criminal cases, searches jurisprudence, and drafts a
legal opinion.

## Architecture

```
apps/web (Next.js)  ──►  apps/api (Go, council-only proxy)  ──►  apps/llm (Python FastAPI, the AI)
                                   │                                      │
                                   └─► Redis (rate limit / bot detect)    └─► Postgres + pgvector (sessions + jurisprudence)
                                                                          └─► Google Gemini (LLM + embeddings)
```

- **apps/web** — Next.js 16 frontend (case input → live deliberation → opinion, case search, session history). Uses `@lexicon/design-system` + `@lexicon/openapi-client`.
- **apps/api** — Go (Chi) service stripped to **only** `/v1/council/*` + `/health`. Pure reverse proxy to the LLM service; adds Turnstile, rate limiting, bot detection. Generated `api.gen.go` from the council-only OpenAPI spec.
- **apps/llm** — Python FastAPI service: the actual deliberation engine (agents, orchestrator, opinion/PDF generation, pgvector case search).
- **packages/** — `design-system`, `openapi-client` (vendored types — no GitHub token needed), `tailwind-config`, `eslint-config`, `typescript-config`.

## Prerequisites

- Node 20+ and `pnpm@11`
- Docker (for the backend stack)
- A **Google Gemini API key** (`GEMINI_API_KEY`) — required for AI + embeddings
- A **Postgres database** — the local compose Postgres boots empty; for full
  production parity (real case search) point `DATABASE_URL` at your populated
  Lexicon DB (schemas `council_v1` + `llm_extraction` with embeddings).

## Quick start

```bash
pnpm install

# 1. Backend stack (Postgres + Redis + Go API + Python LLM)
cp .env.example .env        # fill GEMINI_API_KEY (and DATABASE_URL for parity)
pnpm backend:up             # docker compose up -d postgres redis api llm
#   API  → http://localhost:8000/health
#   LLM  → http://localhost:8001/health

# 2. Frontend
cp apps/web/.env.example apps/web/.env   # NEXT_PUBLIC_API_BASE_URL=http://localhost:8000
pnpm --filter web dev        # http://localhost:3000
```

Stop the backend: `pnpm backend:down`. Logs: `pnpm backend:logs`.

## Turbo tasks

```bash
pnpm dev          # all dev servers (web + native api/llm shims)
pnpm build        # build everything
pnpm lint
pnpm check-types
pnpm test
```

## Data & parity notes

- The local Postgres is seeded by `infra/postgres/init/01-council-bootstrap.sql`
  with **empty** `council_v1` + `llm_extraction.mahkamah_agung_putusans` tables
  (cross-feature FKs and exotic extensions removed so it boots standalone).
  Deliberation works immediately; **case search returns nothing until the
  jurisprudence dataset is loaded** (or `DATABASE_URL` points at the real DB).
- The Go API authenticates to the LLM service with a shared `LLM_API_KEY`
  (sent as `X-API-KEY`) — keep it identical on both services.

## Regenerating the API client / server

- Frontend types: `pnpm --filter @lexicon/openapi-client generate` (needs a
  GitHub token for the private spec; vendored types ship by default).
- Go server stub: `cd apps/api && pnpm api-bundle && pnpm api-generate`.
