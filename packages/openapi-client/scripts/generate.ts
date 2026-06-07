import openapiTS, { astToString } from "openapi-typescript";
import fs from "node:fs/promises";
import path from "node:path";

// Read OpenAPI specs from local monorepo modules instead of remote repos.
// Paths are relative to this package (packages/openapi-client).
const SPECS = {
  backend: path.join(
    import.meta.dirname,
    "..",
    "..",
    "..",
    "apps",
    "api",
    "api",
    "openapi-bundled.yaml"
  ),
};

async function generateTypes(
  name: string,
  specPath: string,
  outputDir: string
): Promise<void> {
  console.log(`Generating types for ${name} from ${specPath}...`);

  const spec = await fs.readFile(specPath, "utf8");
  const ast = await openapiTS(spec, { exportType: true });
  const types = astToString(ast);

  const outputPath = path.join(outputDir, `${name}-types.ts`);
  await fs.writeFile(outputPath, types);
  console.log(`✓ Generated ${outputPath}`);
}

async function main(): Promise<void> {
  const srcDir = path.join(import.meta.dirname, "..", "src");

  await fs.mkdir(srcDir, { recursive: true });

  for (const [name, specPath] of Object.entries(SPECS)) {
    try {
      await generateTypes(name, specPath, srcDir);
    } catch (error) {
      console.error(`Error generating ${name} types:`, error);
      process.exit(1);
    }
  }

  console.log("\n✓ All types generated successfully!");
}

main();
