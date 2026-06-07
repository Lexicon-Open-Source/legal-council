# @lexicon/openapi-client

Type-safe API clients generated from OpenAPI specifications.

## Installation

This package is included in the monorepo. Import directly:

```typescript
import { createBackendClient } from "@lexicon/openapi-client/backend";
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

## Regenerating Types

Types are generated from the local backend OpenAPI spec at
`apps/api/api/openapi-bundled.yaml`. When that spec changes, regenerate:

```bash
pnpm --filter @lexicon/openapi-client generate
```

## Environment Variables

| Variable                      | Purpose              | Scope           |
| ----------------------------- | -------------------- | --------------- |
| `NEXT_PUBLIC_BACKEND_API_URL` | Backend API base URL | Client + Server |

## Relationship with @lexicon/api-client

- Use `@lexicon/openapi-client` for new API integrations (auto-generated types)
- Use `@lexicon/api-client` for SSE streaming and SWR integration
