import "server-only";

import createClient, { type Client, type Middleware } from "openapi-fetch";
import type { paths } from "./crawlers-types";

export interface CrawlersClientConfig {
  baseUrl: string;
  authMode?: "bearer" | "none";
  token?: string;
}

/**
 * Creates a typed Crawlers API client.
 *
 * This client is SERVER-SIDE ONLY. Importing it in a client component
 * will cause a build error due to the `server-only` package.
 *
 * @example
 * ```typescript
 * import { createCrawlersClient } from "@lexicon/openapi-client/crawlers";
 *
 * const crawlers = createCrawlersClient({
 *   baseUrl: process.env.CRAWLERS_API_URL!,
 *   token: process.env.CRAWLERS_API_TOKEN!,
 * });
 *
 * const { data } = await crawlers.GET("/api/v1/crawl/spse/tenders", {
 *   params: { query: { page: 1, limit: 10 } },
 * });
 * ```
 */
export function createCrawlersClient(
  config: CrawlersClientConfig
): Client<paths> {
  if (!config.baseUrl) {
    throw new Error("baseUrl is required for Crawlers client");
  }
  try {
    new URL(config.baseUrl);
  } catch {
    throw new Error("baseUrl must be a valid URL for Crawlers client");
  }
  const authMode = config.authMode ?? "bearer";

  const client = createClient<paths>({
    baseUrl: config.baseUrl,
  });

  if (authMode === "bearer") {
    const token = config.token;
    if (!token || token.trim() === "") {
      throw new Error("token is required for Crawlers client");
    }

    const authMiddleware: Middleware = {
      async onRequest({ request }) {
        request.headers.set("Authorization", `Bearer ${token}`);
        return request;
      },
    };
    client.use(authMiddleware);
  }

  return client;
}

export type { paths, components, operations } from "./crawlers-types";
