# @lexicon/openapi-client

Type-safe API clients generated from OpenAPI specifications.

## Installation

This package is included in the monorepo. Import directly:

```typescript
import { createBackendClient } from "@lexicon/openapi-client/backend";
import { createCrawlersClient } from "@lexicon/openapi-client/crawlers";
```

## Usage

### Backend API (Client or Server)

```typescript
import { createBackendClient } from "@lexicon/openapi-client/backend";

const backend = createBackendClient({
  baseUrl: process.env.NEXT_PUBLIC_BACKEND_API_URL!,
});

// Fully typed - autocomplete for paths, params, and responses
const { data, error } = await backend.GET("/v1/beneficial-ownership/search", {
  params: { query: { q: "search term", page: 1 } },
});

if (error) {
  console.error("API error:", error);
  return;
}

console.log("Results:", data);
```

### Crawlers API (Server-Side Only)

```typescript
import { createCrawlersClient } from "@lexicon/openapi-client/crawlers";

const crawlers = createCrawlersClient({
  baseUrl: process.env.CRAWLERS_API_URL!,
  token: process.env.CRAWLERS_API_TOKEN!,
});

const { data } = await crawlers.GET("/api/v1/crawl/spse/tenders", {
  params: { query: { page: 1, limit: 10 } },
});
```

> **Note**: The crawlers client uses `server-only` and will cause a build error if imported in client components.

When a server-side caller is already authenticated through a reverse proxy, set
`authMode: "none"` and attach the proxy's own request middleware instead of a
crawler token. The admin dashboard uses this mode with the backend
`/v1/admin/crawlers/*` proxy so the crawler shared secret stays only in
`lexicon-backend`.

## Regenerating Types

When the backend or crawlers OpenAPI specs change, regenerate types:

```bash
# Set GITHUB_TOKEN for private repos
export GITHUB_TOKEN=ghp_your_token

# Regenerate all types from main branch (default)
pnpm --filter @lexicon/openapi-client generate

# Regenerate types from a specific branch
pnpm --filter @lexicon/openapi-client generate -- --branch=feature-branch
```

## Environment Variables

| Variable                      | Purpose                        | Scope           |
| ----------------------------- | ------------------------------ | --------------- |
| `GITHUB_TOKEN`                | Fetch specs from private repos | Build-time      |
| `NEXT_PUBLIC_BACKEND_API_URL` | Backend API base URL           | Client + Server |
| `CRAWLERS_API_URL`            | Crawlers API base URL          | Server only     |
| `CRAWLERS_API_TOKEN`          | Crawlers API Bearer token      | Server only     |

`CRAWLERS_API_URL` and `CRAWLERS_API_TOKEN` are for direct crawler-service
callers. Admin-dashboard crawler pages should use `ADMIN_BFF_URL`; backend
deployments own `CRAWLER_BASE_URL` and `CRAWLER_API_KEY`.

## Relationship with @lexicon/api-client

- Use `@lexicon/openapi-client` for new API integrations (auto-generated types)
- Use `@lexicon/api-client` for SSE streaming and SWR integration
