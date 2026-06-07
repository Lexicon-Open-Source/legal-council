#!/usr/bin/env python3
"""
Split the monolithic OpenAPI spec into domain-based files.

This script parses the openapi.yaml file and splits it into:
- paths/*.yaml - One file per API domain with paths
- schemas/*.yaml - One file per domain's schemas
- Main openapi.yaml that uses $ref to reference all files

After splitting, use Redocly to bundle:
  npx @redocly/cli bundle api/openapi.yaml -o api/openapi-bundled.yaml

Usage: python scripts/split_openapi.py
"""

import re
import yaml
from pathlib import Path
from collections import defaultdict
from typing import Any

# Domain mapping based on path prefixes (longer prefixes first for matching)
DOMAIN_MAP = [
    ('/v2/procurement/analytics', 'procurement-v2'),
    ('/v2/procurement/tenders', 'procurement-v2'),
    ('/v2/procurement/filters', 'procurement-v2'),
    ('/v1.5/procurement', 'procurement-v1-5'),
    ('/v1/beneficial-ownership', 'beneficial-ownership'),
    ('/v1/analytics', 'analytics'),
    ('/v1/procurement', 'procurement-v1'),
    ('/v1/council', 'council'),
    ('/v1/bulk', 'bulk'),
    ('/health', 'health'),
    ('/ready', 'health'),
]

# Schemas that are shared across multiple domains
COMMON_SCHEMAS = {
    'Error',
    'PaginationMeta',
    'ChartItem',
    'FilterOption',
    'YearRange',
}

class OpenAPISplitter:
    def __init__(self, api_dir: Path):
        self.api_dir = api_dir
        self.paths_dir = api_dir / 'paths'
        self.schemas_dir = api_dir / 'schemas'
        self.spec = None
        self.domain_paths = defaultdict(dict)
        self.domain_schemas = defaultdict(set)
        self.schema_to_domain = {}
        self.all_schemas = {}

    def load(self):
        """Load the OpenAPI spec."""
        openapi_file = self.api_dir / 'openapi.yaml'
        print(f"Reading {openapi_file}...")
        with open(openapi_file) as f:
            self.spec = yaml.safe_load(f)
        self.all_schemas = self.spec.get('components', {}).get('schemas', {})

    def get_domain(self, path: str) -> str:
        """Determine which domain a path belongs to."""
        for prefix, domain in DOMAIN_MAP:
            if path.startswith(prefix):
                return domain
        return 'misc'

    def extract_refs(self, obj: Any, refs: set = None) -> set:
        """Extract all schema $ref values from an object."""
        if refs is None:
            refs = set()

        if isinstance(obj, dict):
            if '$ref' in obj:
                ref = obj['$ref']
                if '/components/schemas/' in ref:
                    schema_name = ref.split('/components/schemas/')[-1]
                    refs.add(schema_name)
            for v in obj.values():
                self.extract_refs(v, refs)
        elif isinstance(obj, list):
            for item in obj:
                self.extract_refs(item, refs)

        return refs

    def find_dependent_schemas(self, schema_name: str, found: set = None) -> set:
        """Find all schemas that a schema depends on (transitive)."""
        if found is None:
            found = set()

        if schema_name in found or schema_name not in self.all_schemas:
            return found

        found.add(schema_name)
        refs = self.extract_refs(self.all_schemas[schema_name])

        for ref in refs:
            self.find_dependent_schemas(ref, found)

        return found

    def analyze(self):
        """Analyze the spec to determine domain assignments."""
        paths = self.spec.get('paths', {})

        # Group paths by domain
        for path, operations in paths.items():
            domain = self.get_domain(path)
            self.domain_paths[domain][path] = operations

        # Find which schemas are used by which domain
        for domain, paths_dict in self.domain_paths.items():
            for path, operations in paths_dict.items():
                refs = self.extract_refs(operations)
                for ref in refs:
                    deps = self.find_dependent_schemas(ref)
                    self.domain_schemas[domain].update(deps)

        # Identify shared schemas (used by multiple domains)
        schema_usage = defaultdict(set)
        for domain, schema_set in self.domain_schemas.items():
            for schema in schema_set:
                schema_usage[schema].add(domain)

        shared_schemas = {s for s, domains in schema_usage.items() if len(domains) > 1}
        shared_schemas.update(COMMON_SCHEMAS)

        # Assign each schema to either common or a specific domain
        for schema_name in self.all_schemas:
            if schema_name in shared_schemas:
                self.schema_to_domain[schema_name] = 'common'
            else:
                # Find which domain uses this schema
                for domain, schema_set in self.domain_schemas.items():
                    if schema_name in schema_set:
                        self.schema_to_domain[schema_name] = domain
                        break
                else:
                    # Schema not used by any domain, put in common
                    self.schema_to_domain[schema_name] = 'common'

        print(f"\nFound {len(self.domain_paths)} domains:")
        for domain, paths_dict in sorted(self.domain_paths.items()):
            schema_count = len([s for s, d in self.schema_to_domain.items() if d == domain])
            print(f"  - {domain}: {len(paths_dict)} paths, {schema_count} schemas")

        common_count = len([s for s, d in self.schema_to_domain.items() if d == 'common'])
        print(f"  - common: {common_count} schemas")

    def update_refs_for_schema_file(self, obj: Any, current_domain: str) -> Any:
        """Update $ref paths within schema files."""
        if isinstance(obj, dict):
            if '$ref' in obj:
                ref = obj['$ref']
                if ref.startswith('#/components/schemas/'):
                    schema_name = ref.split('/components/schemas/')[-1]
                    target_domain = self.schema_to_domain.get(schema_name, 'common')

                    if target_domain == current_domain:
                        # Same file, use local reference
                        return {'$ref': f'#/{schema_name}'}
                    else:
                        # Different file, use relative reference
                        return {'$ref': f'./{target_domain}.yaml#/{schema_name}'}
                return obj

            # Handle discriminator mapping (special case where refs are string values)
            if 'discriminator' in obj and 'mapping' in obj.get('discriminator', {}):
                new_obj = {}
                for k, v in obj.items():
                    if k == 'discriminator':
                        new_discriminator = dict(v)
                        if 'mapping' in new_discriminator:
                            new_mapping = {}
                            for key, ref in new_discriminator['mapping'].items():
                                if isinstance(ref, str) and ref.startswith('#/components/schemas/'):
                                    schema_name = ref.split('/components/schemas/')[-1]
                                    target_domain = self.schema_to_domain.get(schema_name, 'common')
                                    if target_domain == current_domain:
                                        new_mapping[key] = f'#/{schema_name}'
                                    else:
                                        new_mapping[key] = f'./{target_domain}.yaml#/{schema_name}'
                                else:
                                    new_mapping[key] = ref
                            new_discriminator['mapping'] = new_mapping
                        new_obj[k] = new_discriminator
                    else:
                        new_obj[k] = self.update_refs_for_schema_file(v, current_domain)
                return new_obj

            return {k: self.update_refs_for_schema_file(v, current_domain) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self.update_refs_for_schema_file(item, current_domain) for item in obj]
        return obj

    def update_refs_for_path_file(self, obj: Any, current_domain: str) -> Any:
        """Update $ref paths within path files (always reference schemas directory)."""
        if isinstance(obj, dict):
            if '$ref' in obj:
                ref = obj['$ref']
                if ref.startswith('#/components/schemas/'):
                    schema_name = ref.split('/components/schemas/')[-1]
                    target_domain = self.schema_to_domain.get(schema_name, 'common')
                    # Always use external reference to schemas directory
                    return {'$ref': f'../schemas/{target_domain}.yaml#/{schema_name}'}
                return obj
            return {k: self.update_refs_for_path_file(v, current_domain) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self.update_refs_for_path_file(item, current_domain) for item in obj]
        return obj

    def write_files(self):
        """Write all split files."""
        self.paths_dir.mkdir(exist_ok=True)
        self.schemas_dir.mkdir(exist_ok=True)

        # Group schemas by domain
        domain_schema_content = defaultdict(dict)
        for schema_name, domain in self.schema_to_domain.items():
            if schema_name in self.all_schemas:
                domain_schema_content[domain][schema_name] = self.all_schemas[schema_name]

        # Write schema files
        for domain, schemas in sorted(domain_schema_content.items()):
            if not schemas:
                continue

            # Update refs within schemas to point to correct files
            updated_schemas = {}
            for name, schema in schemas.items():
                updated_schemas[name] = self.update_refs_for_schema_file(schema, domain)

            schemas_file = self.schemas_dir / f'{domain}.yaml'
            print(f"Writing {schemas_file.name} ({len(updated_schemas)} schemas)...")
            with open(schemas_file, 'w') as f:
                f.write(f"# {domain.replace('-', ' ').title()} schemas\n")
                f.write(f"# Part of the Lexicon Backend API specification\n\n")
                yaml.dump(updated_schemas, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

        # Write path files
        for domain, paths_dict in sorted(self.domain_paths.items()):
            # Update refs in paths to point to schema files
            updated_paths = {}
            for path, operations in paths_dict.items():
                updated_paths[path] = self.update_refs_for_path_file(operations, domain)

            paths_file = self.paths_dir / f'{domain}.yaml'
            print(f"Writing {paths_file.name} ({len(updated_paths)} paths)...")
            with open(paths_file, 'w') as f:
                f.write(f"# {domain.replace('-', ' ').title()} API paths\n")
                f.write(f"# Part of the Lexicon Backend API specification\n\n")
                yaml.dump(updated_paths, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

    def write_main_spec(self):
        """Write the main openapi.yaml with $ref to external files."""
        main_spec = {
            'openapi': self.spec['openapi'],
            'info': self.spec['info'],
            'servers': self.spec['servers'],
            'paths': {},
            'components': {
                'schemas': {}
            }
        }

        # Add security schemes if present
        if 'securitySchemes' in self.spec.get('components', {}):
            main_spec['components']['securitySchemes'] = self.spec['components']['securitySchemes']

        # Add path references
        for domain in sorted(self.domain_paths.keys()):
            for path in self.domain_paths[domain]:
                # Escape / in path for JSON pointer
                escaped_path = path.replace('~', '~0').replace('/', '~1')
                main_spec['paths'][path] = {'$ref': f'paths/{domain}.yaml#/{escaped_path}'}

        # Add schema references
        for schema_name in sorted(self.all_schemas.keys()):
            domain = self.schema_to_domain.get(schema_name, 'common')
            main_spec['components']['schemas'][schema_name] = {
                '$ref': f'schemas/{domain}.yaml#/{schema_name}'
            }

        # Write new main spec
        main_file = self.api_dir / 'openapi.yaml'
        print(f"\nWriting {main_file.name}...")
        with open(main_file, 'w') as f:
            f.write("# Lexicon Backend API - Main specification file\n")
            f.write("# This file references external path and schema files.\n")
            f.write("# Use 'make api-bundle' to create the bundled spec for code generation.\n\n")
            yaml.dump(main_spec, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

    def write_readme(self):
        """Write README explaining the structure."""
        readme_content = """# OpenAPI Specification Structure

This directory contains the split OpenAPI specification for the Lexicon Backend API.

## Directory Structure

```
api/
├── openapi.yaml          # Main spec with $ref to external files
├── openapi-bundled.yaml  # Bundled single-file spec (for oapi-codegen)
├── paths/                # Path definitions by domain
│   ├── health.yaml
│   ├── beneficial-ownership.yaml
│   ├── analytics.yaml
│   ├── procurement-v1.yaml
│   ├── procurement-v2.yaml
│   ├── council.yaml
│   ├── bulk.yaml
│   └── procurement-v1-5.yaml
└── schemas/              # Schema definitions by domain
    ├── common.yaml       # Shared schemas (Error, PaginationMeta, etc.)
    ├── beneficial-ownership.yaml
    ├── analytics.yaml
    ├── procurement-v1.yaml
    ├── procurement-v2.yaml
    ├── council.yaml
    └── procurement-v1-5.yaml
```

## Development Workflow

### Editing the API

1. Edit the appropriate `paths/*.yaml` or `schemas/*.yaml` file
2. Run `make api-bundle` to create the bundled spec
3. Run `make api-generate` to regenerate Go code

### Commands

```bash
make api-bundle     # Bundle split files into openapi-bundled.yaml
make api-generate   # Generate Go code from bundled spec
make regenerate-all # Bundle + generate all code
```

## Domain Organization

| Domain | Description |
|--------|-------------|
| `health` | Health check and readiness probes |
| `beneficial-ownership` | Beneficial ownership search and analysis |
| `analytics` | Verdict analytics and statistics |
| `procurement-v1` | Legacy procurement API |
| `procurement-v2` | OCDS-compliant procurement API |
| `council` | Virtual Judicial Council AI deliberation |
| `bulk` | Bulk data egress for ETL |
| `procurement-v1-5` | SPSE procurement analytics |

## Adding New Endpoints

1. Identify which domain the endpoint belongs to
2. Add the path to `paths/{domain}.yaml`
3. Add any new schemas to `schemas/{domain}.yaml`
4. Run `make api-bundle && make api-generate`

## Cross-Domain Schema References

Schemas can reference other schemas using:
- `$ref: '#/SchemaName'` - Same file
- `$ref: '../schemas/common.yaml#/Error'` - External file
"""

        with open(self.api_dir / 'README.md', 'w') as f:
            f.write(readme_content)
        print("Written README.md")


def main():
    api_dir = Path(__file__).parent.parent / 'api'

    splitter = OpenAPISplitter(api_dir)
    splitter.load()
    splitter.analyze()
    splitter.write_files()
    splitter.write_main_spec()
    splitter.write_readme()

    print("\n" + "="*60)
    print("Split complete!")
    print("="*60)
    print("\nNext steps:")
    print("1. Install Redocly CLI: npm install -g @redocly/cli")
    print("2. Bundle the spec: npx @redocly/cli bundle api/openapi.yaml -o api/openapi-bundled.yaml")
    print("3. Update Makefile to use openapi-bundled.yaml for code generation")


if __name__ == '__main__':
    main()
