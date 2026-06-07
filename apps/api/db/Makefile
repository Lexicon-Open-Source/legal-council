-include .env
export DEV_DATABASE_URL
export STAGING_DATABASE_URL
export PROD_DATABASE_URL
export TEST_DATABASE_URL

.PHONY: help \
       migrate-up-dev migrate-down-dev migrate-status-dev migrate-skip-dev \
       migrate-up-staging migrate-down-staging migrate-status-staging migrate-skip-staging \
       migrate-up-prod migrate-down-prod migrate-status-prod migrate-skip-prod \
       migrate-up-test migrate-down-test migrate-reset-test \
       migrate-create schema-generate schema-check

help:
	@echo "Development:"
	@echo "  make migrate-up-dev              Apply pending migrations (dev)"
	@echo "  make migrate-down-dev            Rollback one migration (dev)"
	@echo "  make migrate-status-dev          Show current migration version (dev)"
	@echo "  make migrate-skip-dev v=...      Force set migration version (dev)"
	@echo ""
	@echo "Testing:"
	@echo "  make migrate-up-test             Apply pending migrations (test)"
	@echo "  make migrate-down-test           Rollback one migration (test)"
	@echo "  make migrate-reset-test          Drop all and re-run migrations (test)"
	@echo ""
	@echo "Staging:"
	@echo "  make migrate-up-staging          Apply pending migrations (staging)"
	@echo "  make migrate-down-staging        Rollback one migration (staging)"
	@echo "  make migrate-status-staging      Show current migration version (staging)"
	@echo "  make migrate-skip-staging v=...  Force set migration version (staging)"
	@echo ""
	@echo "Production:"
	@echo "  make migrate-up-prod             Apply pending migrations (prod)"
	@echo "  make migrate-down-prod           Rollback one migration (prod)"
	@echo "  make migrate-status-prod         Show current migration version (prod)"
	@echo "  make migrate-skip-prod v=...     Force set migration version (prod)"
	@echo ""
	@echo "Utilities:"
	@echo "  make migrate-create name=...     Create new migration"
	@echo "  make schema-generate             Generate schema dump files"
	@echo "  make schema-check                Verify schema files are up to date (CI)"

# Development commands
migrate-up-dev:
	@test -n "$(DEV_DATABASE_URL)" || (echo "Error: DEV_DATABASE_URL not set" && exit 1)
	migrate -path migrations -database "$(DEV_DATABASE_URL)" up

migrate-down-dev:
	@test -n "$(DEV_DATABASE_URL)" || (echo "Error: DEV_DATABASE_URL not set" && exit 1)
	migrate -path migrations -database "$(DEV_DATABASE_URL)" down 1

migrate-status-dev:
	@test -n "$(DEV_DATABASE_URL)" || (echo "Error: DEV_DATABASE_URL not set" && exit 1)
	migrate -path migrations -database "$(DEV_DATABASE_URL)" version

migrate-skip-dev:
	@test -n "$(DEV_DATABASE_URL)" || (echo "Error: DEV_DATABASE_URL not set" && exit 1)
	@test -n "$(v)" || (echo "Usage: make migrate-skip-dev v=<version>" && exit 1)
	migrate -path migrations -database "$(DEV_DATABASE_URL)" force $(v)

# Staging commands
migrate-up-staging:
	@test -n "$(STAGING_DATABASE_URL)" || (echo "Error: STAGING_DATABASE_URL not set" && exit 1)
	@echo "⚠️  Running migration on STAGING database..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	migrate -path migrations -database "$(STAGING_DATABASE_URL)" up

migrate-down-staging:
	@test -n "$(STAGING_DATABASE_URL)" || (echo "Error: STAGING_DATABASE_URL not set" && exit 1)
	@echo "⚠️  Rolling back migration on STAGING database..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	migrate -path migrations -database "$(STAGING_DATABASE_URL)" down 1

migrate-status-staging:
	@test -n "$(STAGING_DATABASE_URL)" || (echo "Error: STAGING_DATABASE_URL not set" && exit 1)
	migrate -path migrations -database "$(STAGING_DATABASE_URL)" version

migrate-skip-staging:
	@test -n "$(STAGING_DATABASE_URL)" || (echo "Error: STAGING_DATABASE_URL not set" && exit 1)
	@test -n "$(v)" || (echo "Usage: make migrate-skip-staging v=<version>" && exit 1)
	@echo "⚠️  Force setting migration version on STAGING database to $(v)..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	migrate -path migrations -database "$(STAGING_DATABASE_URL)" force $(v)

# Production commands
migrate-up-prod:
	@test -n "$(PROD_DATABASE_URL)" || (echo "Error: PROD_DATABASE_URL not set" && exit 1)
	@echo "⚠️  Running migration on PRODUCTION database..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	migrate -path migrations -database "$(PROD_DATABASE_URL)" up

migrate-down-prod:
	@test -n "$(PROD_DATABASE_URL)" || (echo "Error: PROD_DATABASE_URL not set" && exit 1)
	@echo "⚠️  Rolling back migration on PRODUCTION database..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	migrate -path migrations -database "$(PROD_DATABASE_URL)" down 1

migrate-status-prod:
	@test -n "$(PROD_DATABASE_URL)" || (echo "Error: PROD_DATABASE_URL not set" && exit 1)
	migrate -path migrations -database "$(PROD_DATABASE_URL)" version

migrate-skip-prod:
	@test -n "$(PROD_DATABASE_URL)" || (echo "Error: PROD_DATABASE_URL not set" && exit 1)
	@test -n "$(v)" || (echo "Usage: make migrate-skip-prod v=<version>" && exit 1)
	@echo "⚠️  Force setting migration version on PRODUCTION database to $(v)..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	migrate -path migrations -database "$(PROD_DATABASE_URL)" force $(v)

# Test commands
migrate-up-test:
	@test -n "$(TEST_DATABASE_URL)" || (echo "Error: TEST_DATABASE_URL not set" && exit 1)
	migrate -path migrations -database "$(TEST_DATABASE_URL)" up

migrate-down-test:
	@test -n "$(TEST_DATABASE_URL)" || (echo "Error: TEST_DATABASE_URL not set" && exit 1)
	migrate -path migrations -database "$(TEST_DATABASE_URL)" down 1

migrate-reset-test:
	@test -n "$(TEST_DATABASE_URL)" || (echo "Error: TEST_DATABASE_URL not set" && exit 1)
	@echo "Dropping all schemas and re-running migrations on test database..."
	@# Drop golang-migrate tracking table
	migrate -path migrations -database "$(TEST_DATABASE_URL)" drop -f || true
	@# Drop all custom schemas that migrations create (migrate drop only drops public tables)
	@psql "$(TEST_DATABASE_URL)" -c "DROP SCHEMA IF EXISTS app CASCADE; DROP SCHEMA IF EXISTS screening CASCADE; DROP SCHEMA IF EXISTS llm_extraction CASCADE; DROP SCHEMA IF EXISTS entity_graph CASCADE; DROP SCHEMA IF EXISTS crawler CASCADE; DROP SCHEMA IF EXISTS bo_crawler_v1 CASCADE; DROP SCHEMA IF EXISTS bo_v1 CASCADE; DROP SCHEMA IF EXISTS council_v1 CASCADE; DROP SCHEMA IF EXISTS ocds CASCADE; DROP SCHEMA IF EXISTS cms CASCADE; DROP SCHEMA IF EXISTS geolocation CASCADE;" 2>/dev/null || true
	migrate -path migrations -database "$(TEST_DATABASE_URL)" up

# Utilities
migrate-create:
	@test -n "$(name)" || (echo "Usage: make migrate-create name=my_migration" && exit 1)
	migrate create -ext sql -dir migrations -seq $(name)

# Schema generation (dumps current schema from migrations)
schema-generate:
	@echo "Generating schema files from migrations..."
	./scripts/generate-schema.sh
	@echo "✓ Schema files generated in schemas/"

schema-check:
	@echo "Checking if schema files are in sync with migrations..."
	@cp -r schemas .tmp-schemas-backup
	@./scripts/generate-schema.sh > /dev/null 2>&1 || \
		(echo "ERROR: Schema generation failed" && mv .tmp-schemas-backup schemas && exit 1)
	@if ! diff -rq schemas .tmp-schemas-backup > /dev/null 2>&1; then \
		echo "ERROR: Schema files are out of sync with migrations!"; \
		echo "Run 'make schema-generate' and commit the changes."; \
		mv .tmp-schemas-backup schemas; \
		exit 1; \
	fi
	@rm -rf .tmp-schemas-backup
	@echo "✓ Schema files are in sync."
