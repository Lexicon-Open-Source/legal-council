# Load .env file if it exists
-include .env
export


.PHONY: help install api-dev build test test-go test-integration test-all lint check \
	api-bundle api-docs api-generate openapi-client-generate sqlc-generate i18n-generate regenerate-all api-check sqlc-check i18n-check check-generated clean \
	migrate-up-dev migrate-down-dev migrate-status-dev migrate-skip-dev \
	migrate-up-staging migrate-down-staging migrate-status-staging migrate-skip-staging \
	migrate-up-prod migrate-down-prod migrate-status-prod migrate-skip-prod \
	migrate-up-test migrate-down-test migrate-reset-test \
	migrate-create schema-generate schema-check \
	llm-install llm-dev llm-lint llm-format llm-test llm-models-generate llm-models-check \
	dev-all install-all docker-build docker-up docker-down \
	bump bump-npm bump-uv bump-tools

# Default target
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Setup:"
	@echo "  install        Install Go dependencies and tools"
	@echo "  install-all    Install all dependencies (Go + Python LLM)"
	@echo ""
	@echo "Development:"
	@echo "  api-dev        Start Go API server with hot reload"
	@echo "  llm-dev        Start LLM service with hot reload (port 8001)"
	@echo "  dev-all        Instructions to run both services"
	@echo "  build          Build Go binary"
	@echo ""
	@echo "Quality:"
	@echo "  lint           Run golangci-lint"
	@echo "  llm-lint       Run ruff linter on LLM service"
	@echo "  llm-format     Format LLM service code"
	@echo "  check          Run lint + test"
	@echo ""
	@echo "Testing:"
	@echo "  test           Run all tests (Go + Python + integration if TEST_DATABASE_URL set)"
	@echo "  test-go        Run Go unit tests only (no database required)"
	@echo "  test-integration  Run Go integration tests (requires TEST_DATABASE_URL)"
	@echo "  llm-test       Run Python LLM tests only"
	@echo ""
	@echo "Database - Development:"
	@echo "  migrate-up-dev         Apply pending migrations (dev)"
	@echo "  migrate-down-dev       Rollback one migration (dev)"
	@echo "  migrate-status-dev     Show migration version (dev)"
	@echo "  migrate-skip-dev v=N   Force set version (dev)"
	@echo ""
	@echo "Database - Staging:"
	@echo "  migrate-up-staging        Apply pending migrations (staging, requires confirmation)"
	@echo "  migrate-down-staging      Rollback one migration (staging, requires confirmation)"
	@echo "  migrate-status-staging    Show migration version (staging)"
	@echo "  migrate-skip-staging v=N  Force set version (staging, requires confirmation)"
	@echo ""
	@echo "Database - Production:"
	@echo "  migrate-up-prod        Apply pending migrations (prod, requires confirmation)"
	@echo "  migrate-down-prod      Rollback one migration (prod, requires confirmation)"
	@echo "  migrate-status-prod    Show migration version (prod)"
	@echo "  migrate-skip-prod v=N  Force set version (prod, requires confirmation)"
	@echo ""
	@echo "Database - Testing:"
	@echo "  migrate-up-test        Apply pending migrations (test)"
	@echo "  migrate-down-test      Rollback one migration (test)"
	@echo "  migrate-reset-test     Drop all and re-run migrations (test)"
	@echo ""
	@echo "Database - Utilities:"
	@echo "  migrate-create name=x  Create new migration"
	@echo "  schema-generate        Generate schema dump files from migrations"
	@echo "  schema-check           Verify schema files match migrations (CI)"
	@echo ""
	@echo "Code Generation:"
	@echo "  api-bundle         Bundle split OpenAPI files into single spec"
	@echo "  api-docs           Generate API documentation (Redoc HTML)"
	@echo "  api-generate       Generate Go server from OpenAPI spec"
	@echo "  openapi-client-generate Generate TypeScript API client from OpenAPI spec"
	@echo "  sqlc-generate      Generate Go + Python code from SQL queries"
	@echo "  llm-models-generate Generate Python models from OpenAPI spec"
	@echo "  i18n-generate      Generate typed i18n key constants from TOML"
	@echo "  regenerate-all     Run all code generators"
	@echo "  check-generated    Verify all generated code is in sync (CI)"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build       Build Docker images"
	@echo "  docker-up          Start services with docker-compose"
	@echo "  docker-down        Stop services"
	@echo ""
	@echo "Dependencies:"
	@echo "  bump               Interactively bump npm + Python (uv) + Go tool versions"
	@echo "  bump-npm           Interactively bump npm packages (npm-check-updates)"
	@echo "  bump-uv            Interactively bump Python (uv) packages in llm/"
	@echo "  bump-tools         Interactively bump pinned Go tools in Makefile install: target"
	@echo ""
	@echo "Other:"
	@echo "  clean              Remove build artifacts and cache"

# =============================================================================
# Setup
# =============================================================================

install:
	go mod download
	go install github.com/air-verse/air@v1.65.1
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1
	go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.6.0
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@v4.19.1
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.11.4

install-all: install llm-install

# =============================================================================
# Dependency Bumping (interactive)
# =============================================================================

# Bump everything: npm packages, Python (uv) packages, then pinned Go tools.
bump: bump-npm bump-uv bump-tools

# Interactive npm bump via npm-check-updates (no global install needed).
bump-npm:
	@echo "==> Bumping npm packages (interactive)..."
	@npx -y npm-check-updates@latest -i
	@npm install
	@npm audit || true

# Interactive Python (uv) bump for the LLM service.
bump-uv:
	@echo "==> Bumping Python (uv) packages in llm/ (interactive)..."
	@./scripts/bump-uv.sh llm

# Interactive Go tool bump: rewrites pinned versions in this Makefile.
bump-tools:
	@echo "==> Bumping Go tools pinned in $(firstword $(MAKEFILE_LIST)) (interactive)..."
	@./scripts/bump-tools.sh $(firstword $(MAKEFILE_LIST))

# =============================================================================
# Development
# =============================================================================

api-dev:
	air

build:
	go build -o bin/api ./cmd/api

dev-all:
	@echo "Start services in separate terminals:"
	@echo "  Terminal 1: make api-dev  (Go API on :8000)"
	@echo "  Terminal 2: make llm-dev  (LLM service on :8001)"

# =============================================================================
# Quality
# =============================================================================

lint:
	golangci-lint run ./...

check: lint test

# =============================================================================
# Testing
# =============================================================================

test: test-all

# Unit tests only (fast, no database required)
test-go:
	go test -v -race -coverprofile=coverage.out ./...

# Integration tests only (requires TEST_DATABASE_URL)
test-integration:
	@test -n "$(TEST_DATABASE_URL)" || (echo "Error: TEST_DATABASE_URL not set. Example:" && \
		echo "  export TEST_DATABASE_URL='postgres://user:pass@localhost:5432/test_db?sslmode=disable'" && \
		exit 1)
	@echo "Applying migrations to test database..."
	@$(MAKE) migrate-up-test
	@echo "Running integration tests..."
	go test -v -race -tags=integration -coverprofile=coverage-integration.out ./internal/api/...

# Run all tests (unit + integration if TEST_DATABASE_URL is set)
test-all: test-go llm-test
	@if [ -n "$(TEST_DATABASE_URL)" ]; then \
		echo "TEST_DATABASE_URL is set, running integration tests..."; \
		$(MAKE) test-integration; \
	else \
		echo "Skipping integration tests (TEST_DATABASE_URL not set)"; \
	fi

# =============================================================================
# Code Generation
# =============================================================================

# Bundle split OpenAPI files into a single spec for code generation
api-bundle:
	@echo "Bundling OpenAPI spec..."
	@npx @redocly/cli bundle api/openapi.yaml -o api/openapi-bundled.yaml --ext yaml
	@echo "✓ Bundled to api/openapi-bundled.yaml"

# Generate interactive API documentation (Redoc HTML)
api-docs: api-bundle
	@echo "Generating API documentation..."
	@npx @redocly/cli build-docs api/openapi-bundled.yaml -o api/redoc-static.html
	@echo "✓ Generated api/redoc-static.html"

api-generate: api-bundle
	oapi-codegen --config oapi-codegen.yaml api/openapi-bundled.yaml

# Generate the TypeScript API client (packages/openapi-client) from the bundled spec
openapi-client-generate: api-bundle
	@echo "Generating TypeScript API client..."
	pnpm --filter @lexicon/openapi-client generate
	@echo "✓ Generated packages/openapi-client/src/backend-types.ts"

sqlc-generate:
	sqlc generate
	# Fix Python import paths (SQLC generates absolute imports, we need relative)
	@if [ -f llm/src/council/db/sqlc/council/council.py ]; then \
		sed -i.bak 's/from council_queries import models/from . import models/' llm/src/council/db/sqlc/council/council.py && \
		rm -f llm/src/council/db/sqlc/council/council.py.bak; \
	fi
	@if [ -f llm/src/council/db/sqlc/extraction/llm_extractions.py ]; then \
		sed -i.bak 's/from extraction_queries import models/from . import models/' llm/src/council/db/sqlc/extraction/llm_extractions.py && \
		rm -f llm/src/council/db/sqlc/extraction/llm_extractions.py.bak; \
	fi
	# Run ruff to fix import sorting on generated files
	@if [ -d llm/src/council/db/sqlc ]; then \
		(cd llm && uv run ruff check --fix src/council/db/sqlc/) || true && \
		(cd llm && uv run ruff format src/council/db/sqlc/); \
	fi

i18n-generate:
	@echo "Generating i18n key constants..."
	@go run ./cmd/gen-i18n-keys
	@echo "✓ Generated internal/i18n/keys_gen.go"

regenerate-all: api-generate openapi-client-generate sqlc-generate llm-models-generate i18n-generate

# CI validation - ensures generated code is in sync with specs
api-check: api-bundle
	@echo "Checking if api.gen.go is in sync with openapi.yaml..."
	@oapi-codegen --config oapi-codegen.yaml api/openapi-bundled.yaml
	@git diff --exit-code internal/api/api.gen.go || \
		(echo "ERROR: api.gen.go is out of sync with openapi.yaml. Run 'make api-generate' and commit." && exit 1)
	@echo "✓ api.gen.go is in sync"

sqlc-check:
	@echo "Checking if SQLC generated code is in sync..."
	@sqlc generate
	# Fix Python import paths
	@if [ -f llm/src/council/db/sqlc/council/council.py ]; then \
		sed -i.bak 's/from council_queries import models/from . import models/' llm/src/council/db/sqlc/council/council.py && \
		rm -f llm/src/council/db/sqlc/council/council.py.bak; \
	fi
	@if [ -f llm/src/council/db/sqlc/extraction/llm_extractions.py ]; then \
		sed -i.bak 's/from extraction_queries import models/from . import models/' llm/src/council/db/sqlc/extraction/llm_extractions.py && \
		rm -f llm/src/council/db/sqlc/extraction/llm_extractions.py.bak; \
	fi
	# Run ruff to ensure consistent formatting
	@if [ -d llm/src/council/db/sqlc ]; then \
		(cd llm && uv run ruff check --fix src/council/db/sqlc/) || true && \
		(cd llm && uv run ruff format src/council/db/sqlc/); \
	fi
	@git diff --exit-code internal/db/sqlc/ || \
		(echo "ERROR: SQLC Go code is out of sync. Run 'make sqlc-generate' and commit." && exit 1)
	@git diff --exit-code llm/src/council/db/sqlc/ || \
		(echo "ERROR: SQLC Python code is out of sync. Run 'make sqlc-generate' and commit." && exit 1)
	@echo "✓ SQLC code is in sync (Go + Python)"

i18n-check:
	@echo "Checking if i18n keys are in sync with TOML files..."
	@go run ./cmd/gen-i18n-keys
	@gofmt -w internal/i18n/keys_gen.go
	@git diff --exit-code internal/i18n/keys_gen.go || \
		(echo "ERROR: keys_gen.go is out of sync with TOML files. Run 'make i18n-generate' and commit." && exit 1)
	@echo "✓ i18n keys are in sync"

# Run all generation checks (use in CI)
check-generated: api-check sqlc-check llm-models-check schema-check i18n-check
	@echo "✓ All generated code is in sync"

# =============================================================================
# Database Migrations
# =============================================================================
# Uses environment variables from .env:
#   DATABASE_URL      - Development database
#   PROD_DATABASE_URL - Production database
#   TEST_DATABASE_URL - Test database

# Development (uses DATABASE_URL from .env)
migrate-up-dev:
	$(MAKE) -C db migrate-up-dev DEV_DATABASE_URL="$(DEV_DATABASE_URL)"

migrate-down-dev:
	$(MAKE) -C db migrate-down-dev DEV_DATABASE_URL="$(DEV_DATABASE_URL)"

migrate-status-dev:
	$(MAKE) -C db migrate-status-dev DEV_DATABASE_URL="$(DEV_DATABASE_URL)"

migrate-skip-dev:
	@test -n "$(v)" || (echo "Usage: make migrate-skip-dev v=<version>" && exit 1)
	$(MAKE) -C db migrate-skip-dev v=$(v) DEV_DATABASE_URL="$(DEV_DATABASE_URL)"

# Production (requires confirmation)
migrate-up-prod:
	$(MAKE) -C db migrate-up-prod PROD_DATABASE_URL="$(PROD_DATABASE_URL)"

migrate-down-prod:
	$(MAKE) -C db migrate-down-prod PROD_DATABASE_URL="$(PROD_DATABASE_URL)"

migrate-status-prod:
	$(MAKE) -C db migrate-status-prod PROD_DATABASE_URL="$(PROD_DATABASE_URL)"

migrate-skip-prod:
	@test -n "$(v)" || (echo "Usage: make migrate-skip-prod v=<version>" && exit 1)
	$(MAKE) -C db migrate-skip-prod v=$(v) PROD_DATABASE_URL="$(PROD_DATABASE_URL)"

# Staging (requires confirmation)
migrate-up-staging:
	$(MAKE) -C db migrate-up-staging STAGING_DATABASE_URL="$(STAGING_DATABASE_URL)"

migrate-down-staging:
	$(MAKE) -C db migrate-down-staging STAGING_DATABASE_URL="$(STAGING_DATABASE_URL)"

migrate-status-staging:
	$(MAKE) -C db migrate-status-staging STAGING_DATABASE_URL="$(STAGING_DATABASE_URL)"

migrate-skip-staging:
	@test -n "$(v)" || (echo "Usage: make migrate-skip-staging v=<version>" && exit 1)
	$(MAKE) -C db migrate-skip-staging v=$(v) STAGING_DATABASE_URL="$(STAGING_DATABASE_URL)"

# Testing
migrate-up-test:
	$(MAKE) -C db migrate-up-test TEST_DATABASE_URL="$(TEST_DATABASE_URL)"

migrate-down-test:
	$(MAKE) -C db migrate-down-test TEST_DATABASE_URL="$(TEST_DATABASE_URL)"

migrate-reset-test:
	$(MAKE) -C db migrate-reset-test TEST_DATABASE_URL="$(TEST_DATABASE_URL)"

# Utilities
migrate-create:
	@test -n "$(name)" || (echo "Usage: make migrate-create name=my_migration" && exit 1)
	$(MAKE) -C db migrate-create name=$(name)

# Schema dump generation (delegates to db/ submodule)
schema-generate:
	$(MAKE) -C db schema-generate

# CI validation - ensures schema files match migrations
schema-check:
	$(MAKE) -C db schema-check

# =============================================================================
# LLM Service (Python)
# =============================================================================

llm-install:
	cd llm && uv sync

llm-dev:
	cd llm && uv run uvicorn main:app --reload --host 0.0.0.0 --port 8001

llm-lint:
	cd llm && uv run ruff check . && uv run ruff format --check .

llm-format:
	cd llm && uv run ruff format .

llm-test:
	cd llm && uv run pytest -v

# Generate Python models from shared OpenAPI spec
# Config is in llm/pyproject.toml under [tool.datamodel-codegen]
llm-models-generate:
	@echo "Generating Python models from OpenAPI spec..."
	@mkdir -p llm/src/council/models
	cd llm && uv run datamodel-codegen
	# Run ruff to ensure consistent formatting
	cd llm && uv run ruff format src/council/models/generated.py
	@echo "✓ Python models generated"

# CI validation - ensures Python models are in sync with OpenAPI spec
llm-models-check:
	@echo "Checking if Python models are in sync with openapi.yaml..."
	@mkdir -p llm/src/council/models
	cd llm && uv run datamodel-codegen
	cd llm && uv run ruff format src/council/models/generated.py
	@git diff --exit-code llm/src/council/models/generated.py || \
		(echo "ERROR: Python models are out of sync with openapi.yaml. Run 'make llm-models-generate' and commit." && exit 1)
	@echo "✓ Python models are in sync"

# =============================================================================
# Docker
# =============================================================================

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

# =============================================================================
# Cleanup
# =============================================================================

clean:
	rm -rf bin/ tmp/ coverage.out
