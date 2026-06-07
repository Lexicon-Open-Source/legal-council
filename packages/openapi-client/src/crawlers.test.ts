import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createCrawlersClient } from "./crawlers";

vi.mock("server-only", () => ({}));

function requestFromFetchCall(call: unknown[]): Request {
  const [requestInput, requestInit] = call;
  return requestInput instanceof Request
    ? requestInput
    : new Request(String(requestInput), requestInit as RequestInit);
}

function firstFetchRequest(fetchMock: ReturnType<typeof vi.fn>): Request {
  const call = fetchMock.mock.calls[0];
  if (!call) {
    throw new Error("Expected fetch to be called");
  }
  return requestFromFetchCall(call);
}

describe("createCrawlersClient", () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    fetchMock.mockReset();
    fetchMock.mockResolvedValue(
      new Response(JSON.stringify({ crawlers: [] }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      })
    );
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("adds bearer authorization when a token is supplied", async () => {
    const client = createCrawlersClient({
      baseUrl: "https://crawlers.example.com",
      token: "secret-token",
    });

    await client.GET("/api/v1/crawlers/status");

    const request = firstFetchRequest(fetchMock);
    expect(request.headers.get("Authorization")).toBe("Bearer secret-token");
  });

  it("does not add authorization when a token is omitted", async () => {
    const client = createCrawlersClient({
      authMode: "none",
      baseUrl: "https://admin.example.com/v1/admin/crawlers",
    });

    await client.GET("/api/v1/crawlers/status");

    const request = firstFetchRequest(fetchMock);
    expect(request.headers.get("Authorization")).toBeNull();
  });

  it("requires tokens for bearer auth by default", () => {
    expect(() =>
      createCrawlersClient({
        baseUrl: "https://crawlers.example.com",
      })
    ).toThrow("token is required for Crawlers client");
  });

  it("rejects explicitly blank tokens", () => {
    expect(() =>
      createCrawlersClient({
        baseUrl: "https://crawlers.example.com",
        token: "  ",
      })
    ).toThrow("token is required for Crawlers client");
  });

  it("requires a valid base URL", () => {
    expect(() => createCrawlersClient({ baseUrl: "" })).toThrow(
      "baseUrl is required for Crawlers client"
    );
    expect(() => createCrawlersClient({ baseUrl: "not a url" })).toThrow(
      "baseUrl must be a valid URL for Crawlers client"
    );
  });
});
