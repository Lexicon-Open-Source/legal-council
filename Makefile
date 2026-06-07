# legal-council — root Makefile
# Monorepo: pnpm + turbo (apps: api[Go], llm[Python], web[Next]).
# Backend services run via docker compose. DB migrations live in db/Makefile.

PNPM ?= pnpm
COMPOSE ?= docker compose

.DEFAULT_GOAL := help

.PHONY: help install dev build start test lint lint-fix format format-check check-types \
	backend-up backend-down backend-logs backend-restart compose-build \
	db-migrate-up db-migrate-down db-migrate-status db-migrate-create db-migrate-reset-test \
	generate clean

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
help:
	@echo "Setup:"
	@echo "  make install              Install workspace deps (pnpm)"
	@echo ""
	@echo "Develop:"
	@echo "  make dev                  Run all apps in dev (turbo)"
	@echo "  make build                Build all apps"
	@echo "  make start                Start built apps"
	@echo "  make generate             Run codegen tasks (turbo generate)"
	@echo ""
	@echo "Quality:"
	@echo "  make test                 Run all tests"
	@echo "  make lint                 Lint all apps"
	@echo "  make lint-fix             Lint + autofix"
	@echo "  make format               Prettier write"
	@echo "  make format-check         Prettier check"
	@echo "  make check-types          Type-check all apps"
	@echo ""
	@echo "Backend (docker compose: postgres redis api llm):"
	@echo "  make backend-up           Start backend services (detached)"
	@echo "  make backend-down         Stop backend services"
	@echo "  make backend-restart      Restart backend services"
	@echo "  make backend-logs         Tail api + llm logs"
	@echo "  make compose-build        Rebuild api + llm images"
	@echo ""
	@echo "Database (delegates to db/Makefile):"
	@echo "  make db-migrate-up        Apply pending migrations (dev)"
	@echo "  make db-migrate-down      Rollback one migration (dev)"
	@echo "  make db-migrate-status    Show current migration version (dev)"
	@echo "  make db-migrate-create name=...   Create a new migration"
	@echo "  make db-migrate-reset-test        Drop + re-run migrations (test)"
	@echo ""
	@echo "  make clean                Remove build output + node_modules"

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
install:
	$(PNPM) install

# ---------------------------------------------------------------------------
# Develop
# ---------------------------------------------------------------------------
dev:
	$(PNPM) dev

build:
	$(PNPM) build

start:
	$(PNPM) start

generate:
	$(PNPM) turbo run generate

# ---------------------------------------------------------------------------
# Quality
# ---------------------------------------------------------------------------
test:
	$(PNPM) test

lint:
	$(PNPM) lint

lint-fix:
	$(PNPM) lint:fix

format:
	$(PNPM) format

format-check:
	$(PNPM) format:check

check-types:
	$(PNPM) check-types

# ---------------------------------------------------------------------------
# Backend (docker compose)
# ---------------------------------------------------------------------------
backend-up:
	$(COMPOSE) up -d postgres redis api llm

backend-down:
	$(COMPOSE) down

backend-restart: backend-down backend-up

backend-logs:
	$(COMPOSE) logs -f api llm

compose-build:
	$(COMPOSE) build api llm

# ---------------------------------------------------------------------------
# Database (delegate to db/Makefile)
# ---------------------------------------------------------------------------
db-migrate-up:
	$(MAKE) -C db migrate-up-dev

db-migrate-down:
	$(MAKE) -C db migrate-down-dev

db-migrate-status:
	$(MAKE) -C db migrate-status-dev

db-migrate-create:
	$(MAKE) -C db migrate-create name=$(name)

db-migrate-reset-test:
	$(MAKE) -C db migrate-reset-test

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------
clean:
	rm -rf node_modules apps/*/node_modules packages/*/node_modules
	rm -rf apps/web/.next apps/api/bin .turbo apps/*/.turbo
