# fake-authentik

Stand-in OIDC provider for local end-to-end testing of the admin BFF auth
flow. Serves discovery, JWKS, `/authorize`, `/token`, and `/logout` with
real RS256-signed JWTs so the backend's `go-oidc` verifier accepts them
exactly as it would for a real Authentik deployment.

Unit tests (`httptest.Server` fakes in `internal/api/*_test.go`) cover
correctness of the handlers. Use this binary only when you need to drive
the real `cmd/api` process through the full authorization-code round-trip
(e.g. writing a Test Execution Report, reproducing a reported auth bug,
or validating a session-store change end-to-end).

## When to use it

| Situation | Tool |
|---|---|
| Writing `*_test.go` coverage for a handler or middleware | stub `Verifier` in-process (see `handlers_admin_auth_test.go`) |
| Debugging a suspected Authentik drift against the backend | point at **staging** Authentik directly |
| Validating the login → callback → protected → refresh → logout chain locally | **fake-authentik** |
| Producing a `docs/reports/TEST_EXECUTION_REPORT_*` for admin features | **fake-authentik** |

## Running it

Separate Go module (does not share `go.mod` with the main backend so it
can't accidentally drift the production dependency graph):

```bash
# From the repo root
go run ./scripts/fake-authentik \
  -addr :9999 \
  -issuer http://localhost:9999 \
  -client-id lexicon-admin
```

Sanity check:

```bash
curl -s http://localhost:9999/.well-known/openid-configuration | jq .
```

## Backend env vars required to drive it

```bash
export AUTHN_ADMIN_ISSUER=http://localhost:9999
export AUTHN_ADMIN_CLIENT_ID=lexicon-admin
export AUTHN_ADMIN_CLIENT_SECRET=test-client-secret
export AUTHN_ADMIN_REDIRECT_URL=http://localhost:8000/v1/admin/auth/callback
export ADMIN_DASHBOARD_URL=http://localhost:3000/admin
export ADMIN_SESSION_ENCRYPTION_KEY=$(openssl rand -base64 32)
```

Then start the backend normally (`make api-dev` or `go run ./cmd/api`).

## Behaviour quirks worth knowing

- **Access tokens carry `aud: lexicon-api`** (not the client_id). This
  deliberately exercises the dedicated `adminAccessVerifier` that runs
  with `SkipClientIDCheck: true` — the ID-token verifier would reject it.
- **Access tokens expire after 30 seconds.** Sleep past that window and
  hit any `/v1/admin/*` route to drive silent-refresh through
  `AdminSessionStore.Resolve`.
- **Every user is `super_admin`.** The `groups` claim is hard-coded so
  you automatically hold every permission in the RBAC catalog; adjust
  `main.go` if you need to test role gating.
- **No consent UI.** `/authorize` approves every request and 302s back to
  the redirect_uri unconditionally — this is a harness, not a simulator.
- **In-memory code-to-nonce map.** Restarting the process invalidates all
  pending authorization codes, which is fine for single-threaded local
  testing.

## Linked docs

- Feature testing workflow: [`docs/sop/010-feature-testing-workflow.md`](../../docs/sop/010-feature-testing-workflow.md)
- Admin BFF auth design: [`docs/adr/0019-admin-bff-auth.md`](../../docs/adr/0019-admin-bff-auth.md)
- Reference run: [`docs/reports/TEST_EXECUTION_REPORT_ADMIN_BFF_AUTH.md`](../../docs/reports/TEST_EXECUTION_REPORT_ADMIN_BFF_AUTH.md)
