# OpenAPI Specification Structure

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
