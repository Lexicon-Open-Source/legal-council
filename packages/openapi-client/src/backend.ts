import createClient, { type Client } from "openapi-fetch";
import type { paths } from "./backend-types";

export interface BackendClientConfig {
  baseUrl: string;
  locale?: string;
}

/**
 * Creates a typed Backend API client.
 *
 * @example
 * ```typescript
 * import { createBackendClient } from "@lexicon/openapi-client/backend";
 *
 * const backend = createBackendClient({
 *   baseUrl: process.env.NEXT_PUBLIC_BACKEND_API_URL!,
 *   locale: "en", // or "id" for Indonesian
 * });
 *
 * const { data, error } = await backend.GET("/v1/beneficial-ownership/search", {
 *   params: { query: { q: "search term" } },
 * });
 * ```
 */
export function createBackendClient(
  config: BackendClientConfig
): Client<paths> {
  if (!config.baseUrl || config.baseUrl.trim() === "") {
    throw new Error("baseUrl is required for Backend client");
  }

  try {
    new URL(config.baseUrl);
  } catch {
    throw new Error("baseUrl must be a valid URL");
  }

  return createClient<paths>({
    baseUrl: config.baseUrl,
    headers: {
      "Accept-Language": config.locale || "id",
    },
  });
}

export type { paths, components, operations } from "./backend-types";
