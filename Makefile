# Makefile - Docker Development Environment

.PHONY: help docker-build docker-up docker-down docker-logs docker-clean \
        docker-shell docker-test docker-lint docker-format docker-build-ts \
        docker-bootstrap stage-1 stage-2 stage-3 stage-4 stage-5 \
        stage-6 stage-7 stage-8 stage-9

# Default target
help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║  LESS to Tailwind Parser - Docker Development              ║"
	@echo "║  Available Commands                                         ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "🐳 Docker Commands:"
	@echo "  make docker-build       Build Docker image"
	@echo "  make docker-up          Start all services (background)"
	@echo "  make docker-down        Stop all services"
	@echo "  make docker-shell       Enter dev container shell"
	@echo "  make docker-logs        View logs from all services"
	@echo "  make docker-clean       Remove containers and volumes"
	@echo ""
	@echo "🧪 Development Commands (inside container):"
	@echo "  make docker-test        Run tests"
	@echo "  make docker-lint        Check code quality"
	@echo "  make docker-format      Format code"
	@echo "  make docker-build-ts    Build TypeScript"
	@echo ""
	@echo "📚 Bootstrap Commands:"
	@echo "  make docker-bootstrap N=[N] NAME=[NAME]   Bootstrap a stage"
	@echo "  make stage-1            Bootstrap Stage 1 (DATABASE_FOUNDATION)"
	@echo "  make stage-2            Bootstrap Stage 2 (LESS_SCANNING)"
	@echo "  make stage-3            Bootstrap Stage 3 (IMPORT_HIERARCHY)"
	@echo "  make stage-4            Bootstrap Stage 4 (RULE_EXTRACTION)"
	@echo "  make stage-5            Bootstrap Stage 5 (VARIABLE_EXTRACTION)"
	@echo "  make stage-6            Bootstrap Stage 6 (TAILWIND_EXPORT)"
	@echo "  make stage-7            Bootstrap Stage 7 (INTEGRATION)"
	@echo "  make stage-8            Bootstrap Stage 8 (CHROME_EXTENSION)"
	@echo "  make stage-9            Bootstrap Stage 9 (DOM_TO_TAILWIND)"
	@echo ""
	@echo "Examples:"
	@echo "  make docker-up && make docker-shell"
	@echo "  make stage-1"
	@echo "  docker-compose exec dev npm test"
	@echo ""

# Docker image and container management
docker-build:
	@echo "🔨 Building Docker image..."
	docker-compose build --no-cache

docker-up:
	@echo "🚀 Starting Docker services..."
	docker-compose up -d
	@echo "✓ Services started"
	@echo "  PostgreSQL: localhost:5432"
	@echo "  Redis: localhost:6379"
	@echo "  API: localhost:3000 (when running)"
	@echo ""
	@echo "Enter container: make docker-shell"

docker-down:
	@echo "⏹ Stopping Docker services..."
	docker-compose down
	@echo "✓ Services stopped"

docker-logs:
	@echo "📋 Service logs (Ctrl+C to exit)..."
	docker-compose logs -f

docker-clean:
	@echo "🧹 Cleaning up containers and volumes..."
	docker-compose down -v
	@echo "✓ Cleaned"

docker-shell:
	@echo "📦 Entering development container..."
	docker-compose exec dev bash

# Development commands
docker-test:
	@echo "🧪 Running tests..."
	docker-compose exec dev npm test

docker-lint:
	@echo "🔍 Checking code quality..."
	docker-compose exec dev npm run lint

docker-format:
	@echo "✨ Formatting code..."
	docker-compose exec dev npm run format

docker-build-ts:
	@echo "🏗 Building TypeScript..."
	docker-compose exec dev npm run build

# Bootstrap commands
docker-bootstrap:
	@if [ -z "$(N)" ] || [ -z "$(NAME)" ]; then \
		echo "❌ Usage: make docker-bootstrap N=[NUMBER] NAME=[STAGE_NAME]"; \
		echo "   Example: make docker-bootstrap N=1 NAME=DATABASE_FOUNDATION"; \
		exit 1; \
	fi
	@echo "🎯 Bootstrapping Stage $(N): $(NAME)..."
	docker-compose exec dev ./bootstrap-stage.sh $(N) $(NAME)

stage-1:
	@make docker-bootstrap N=1 NAME=DATABASE_FOUNDATION

stage-2:
	@make docker-bootstrap N=2 NAME=LESS_SCANNING

stage-3:
	@make docker-bootstrap N=3 NAME=IMPORT_HIERARCHY

stage-4:
	@make docker-bootstrap N=4 NAME=RULE_EXTRACTION

stage-5:
	@make docker-bootstrap N=5 NAME=VARIABLE_EXTRACTION

stage-6:
	@make docker-bootstrap N=6 NAME=TAILWIND_EXPORT

stage-7:
	@make docker-bootstrap N=7 NAME=INTEGRATION

stage-8:
	@make docker-bootstrap N=8 NAME=CHROME_EXTENSION

stage-9:
	@make docker-bootstrap N=9 NAME=DOM_TO_TAILWIND
