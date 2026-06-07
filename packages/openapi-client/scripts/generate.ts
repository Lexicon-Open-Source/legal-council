import openapiTS, { astToString } from "openapi-typescript";
import fs from "node:fs/promises";
import path from "node:path";
import { config } from "dotenv";

// Load .env.local from package root
config({ path: path.join(import.meta.dirname, "..", ".env.local") });

// Parse command-line arguments for optional branch
const args = process.argv.slice(2);
const branchArg = args.find((arg) => arg.startsWith("--branch="));
const branch = branchArg ? branchArg.split("=")[1] : "main";

if (branch !== "main") {
  console.log(`Using branch: ${branch}`);
}

// Use GitHub API for private repos, raw.githubusercontent for public
const SPECS = {
  backend: {
    api: `https://api.github.com/repos/LexiconIndonesia/backend/contents/api/openapi-bundled.yaml?ref=${branch}`,
    raw: `https://raw.githubusercontent.com/LexiconIndonesia/backend/${branch}/api/openapi-bundled.yaml`,
  },
  crawlers: {
    api: `https://api.github.com/repos/LexiconIndonesia/crawlers/contents/openapi.yaml?ref=${branch}`,
    raw: `https://raw.githubusercontent.com/LexiconIndonesia/crawlers/${branch}/openapi.yaml`,
  },
};

const token = process.env.GITHUB_TOKEN;
if (!token) {
  console.warn(
    "Warning: GITHUB_TOKEN not set. Will attempt to fetch public repos."
  );
  console.warn(
    "For private repos, set GITHUB_TOKEN in .env.local or export in your shell."
  );
}

async function fetchSpec(urls: { api: string; raw: string }): Promise<string> {
  // Use GitHub API with token for private repos, fallback to raw for public
  const url = token ? urls.api : urls.raw;

  const headers: Record<string, string> = {
    Accept: "application/vnd.github.v3.raw",
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const response = await fetch(url, { headers });

  if (response.status === 401) {
    throw new Error(
      "GITHUB_TOKEN is invalid or expired. Generate a new token with 'repo' scope."
    );
  }
  if (response.status === 404) {
    throw new Error(
      `OpenAPI spec not found at ${url}. Either the file was moved, or the token lacks access to this private repo.`
    );
  }
  if (!response.ok) {
    throw new Error(
      `Failed to fetch spec: ${response.status} ${response.statusText}`
    );
  }

  return response.text();
}

async function generateTypes(
  name: string,
  urls: { api: string; raw: string },
  outputDir: string
): Promise<void> {
  console.log(`Generating types for ${name}...`);

  const spec = await fetchSpec(urls);
  const ast = await openapiTS(spec, { exportType: true });
  const types = astToString(ast);

  const outputPath = path.join(outputDir, `${name}-types.ts`);
  await fs.writeFile(outputPath, types);
  console.log(`✓ Generated ${outputPath}`);
}

async function main(): Promise<void> {
  const srcDir = path.join(import.meta.dirname, "..", "src");

  await fs.mkdir(srcDir, { recursive: true });

  for (const [name, urls] of Object.entries(SPECS)) {
    try {
      await generateTypes(name, urls, srcDir);
    } catch (error) {
      console.error(`Error generating ${name} types:`, error);
      process.exit(1);
    }
  }

  console.log("\n✓ All types generated successfully!");
}

main();
