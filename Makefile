.PHONY: help setup list enter-stage-1 enter-stage-2 enter-stage-3 enter-stage-4 enter-stage-5 enter-stage-6 enter-stage-7 enter-stage-8 enter-stage-9 enter-dev install-all commit-all push-all status-all

help:
	@echo "LESS to Tailwind Parser - Git Workspaces Makefile"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup              Create all stage workspaces"
	@echo "  make list               List all workspaces"
	@echo ""
	@echo "Enter Workspace Commands:"
	@echo "  make enter-stage-1      Enter Stage 1 workspace"
	@echo "  make enter-stage-2      Enter Stage 2 workspace"
	@echo "  ... (up to stage-9)"
	@echo "  make enter-dev          Enter development workspace"
	@echo ""
	@echo "Installation:"
	@echo "  make install-all        Install npm dependencies in all workspaces"
	@echo "  make install-stage-1    Install dependencies in Stage 1 only"
	@echo ""
	@echo "Status & Info:"
	@echo "  make list               List all workspaces and branches"
	@echo "  make status-all         Git status in all workspaces"
	@echo ""
	@echo "Bulk Operations:"
	@echo "  make commit-all MSG=\"your message\"  Commit in all workspaces"
	@echo "  make push-all           Push all workspaces"
	@echo ""
	@echo "Development:"
	@echo "  make clean              Remove all node_modules"
	@echo "  make logs               View git logs for all branches"
	@echo ""

setup:
	@echo "🚀 Setting up workspaces..."
	bash setup-workspaces.sh
	@echo "✅ Setup complete!"

list:
	@echo "📦 Git Workspaces:"
	@git worktree list

enter-stage-1:
	@cd .worktrees/stage-1 && bash

enter-stage-2:
	@cd .worktrees/stage-2 && bash

enter-stage-3:
	@cd .worktrees/stage-3 && bash

enter-stage-4:
	@cd .worktrees/stage-4 && bash

enter-stage-5:
	@cd .worktrees/stage-5 && bash

enter-stage-6:
	@cd .worktrees/stage-6 && bash

enter-stage-7:
	@cd .worktrees/stage-7 && bash

enter-stage-8:
	@cd .worktrees/stage-8 && bash

enter-stage-9:
	@cd .worktrees/stage-9 && bash

enter-dev:
	@cd .worktrees/dev && bash

install-all:
	@echo "📦 Installing dependencies in all workspaces..."
	@for dir in .worktrees/*/; do \
		echo "Installing in $$dir..."; \
		cd "$$dir" && npm install && cd ../.. ; \
	done
	@echo "✅ All dependencies installed!"

install-stage-1:
	@cd .worktrees/stage-1 && npm install

install-stage-2:
	@cd .worktrees/stage-2 && npm install

install-stage-3:
	@cd .worktrees/stage-3 && npm install

install-stage-4:
	@cd .worktrees/stage-4 && npm install

install-stage-5:
	@cd .worktrees/stage-5 && npm install

install-stage-6:
	@cd .worktrees/stage-6 && npm install

install-stage-7:
	@cd .worktrees/stage-7 && npm install

install-stage-8:
	@cd .worktrees/stage-8 && npm install

install-stage-9:
	@cd .worktrees/stage-9 && npm install

status-all:
	@echo "📋 Git Status in All Workspaces:"
	@for dir in .worktrees/*/; do \
		echo ""; \
		echo "=== $$dir ==="; \
		cd "$$dir" && git status --short && cd ../.. ; \
	done

commit-all:
	@if [ -z "$(MSG)" ]; then \
		echo "❌ Error: MSG is required"; \
		echo "Usage: make commit-all MSG=\"your commit message\""; \
		exit 1; \
	fi
	@echo "📝 Committing in all workspaces..."
	@for dir in .worktrees/*/; do \
		echo "Committing in $$dir..."; \
		cd "$$dir" && git add -A && git commit -m "$(MSG)" || true && cd ../.. ; \
	done
	@echo "✅ Commits complete!"

push-all:
	@echo "📤 Pushing all workspaces..."
	@for dir in .worktrees/*/; do \
		branch=$$(cd "$$dir" && git rev-parse --abbrev-ref HEAD); \
		echo "Pushing $$dir (branch: $$branch)..."; \
		cd "$$dir" && git push origin "$$branch" && cd ../.. ; \
	done
	@echo "✅ All pushes complete!"

clean:
	@echo "🧹 Removing node_modules from all workspaces..."
	@for dir in .worktrees/*/; do \
		echo "Cleaning $$dir..."; \
		rm -rf "$$dir/node_modules" ; \
	done
	@echo "✅ Cleanup complete!"

logs:
	@echo "📋 Git Logs (all branches):"
	@git log --oneline --graph --all --decorate -20

fetch-all:
	@echo "🔄 Fetching latest from all remotes..."
	@for dir in .worktrees/*/; do \
		echo "Fetching $$dir..."; \
		cd "$$dir" && git fetch origin && cd ../.. ; \
	done
	@echo "✅ Fetch complete!"

info:
	@echo "LESS to Tailwind Parser Project Info"
	@echo ""
	@echo "📍 Repository: https://github.com/craigmcmeechan/less-to-tailwind-parser"
	@echo "📚 Documentation:"
	@echo "   - Quick Start: QUICK_START.md"
	@echo "   - Full Guide: GIT_WORKSPACES_GUIDE.md"
	@echo "   - Architecture: docs/ARCHITECTURE.md"
	@echo "   - Roadmap: docs/PROJECT_ROADMAP.md"
	@echo ""
	@echo "🏗️  Stages:"
	@echo "   1. Database Foundation"
	@echo "   2. LESS File Scanning"
	@echo "   3. Import Hierarchy"
	@echo "   4. CSS Rule Extraction (CRITICAL)"
	@echo "   5. Variable Extraction"
	@echo "   6. Tailwind Export"
	@echo "   7. Integration & Testing"
	@echo "   8. Chrome Extension"
	@echo "   9. DOM Matching & Tailwind"
	@echo ""
	@echo "Run 'make help' for commands"

.DEFAULT_GOAL := help
