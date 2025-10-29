#!/bin/bash
# Docker entrypoint script for LESS to Tailwind Parser development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Welcome message
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  LESS to Tailwind Parser - Development Environment         ║"
echo "║  Docker Container Ready                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Environment info
echo -e "${GREEN}✓ Environment Information${NC}"
echo "  Node.js: $(node --version)"
echo "  npm: $(npm --version)"
echo "  TypeScript: $(npx typescript --version 2>/dev/null || echo 'installed')"
echo "  Claude Code: $(claude code --version 2>/dev/null || echo 'available')"
echo "  Git: $(git --version)"

# Check database connection
echo -e "\n${GREEN}✓ Service Status${NC}"

# Check PostgreSQL
if nc -z postgres 5432 2>/dev/null; then
  echo -e "  PostgreSQL: ${GREEN}✓ Connected${NC} (postgres:5432)"
else
  echo -e "  PostgreSQL: ${YELLOW}○ Waiting${NC} (postgres:5432)"
fi

# Check Redis
if nc -z redis 6379 2>/dev/null; then
  echo -e "  Redis: ${GREEN}✓ Connected${NC} (redis:6379)"
else
  echo -e "  Redis: ${YELLOW}○ Available${NC} (redis:6379)"
fi

# Project info
echo -e "\n${GREEN}✓ Project Information${NC}"
echo "  Workspace: /workspace"
echo "  Stages: /workspace/stages/{1-9}"
echo "  Node modules: Cached volume"
echo "  NPM cache: Cached volume"

# Useful commands
echo -e "\n${BLUE}📚 Quick Reference Commands${NC}"
echo "  Bootstrap stage:     ./bootstrap-stage.sh [N] [NAME]"
echo "  Run tests:           npm test"
echo "  Build project:       npm run build"
echo "  Format code:         npm run format"
echo "  Check linting:       npm run lint"
echo "  Start dev server:    npm run dev"
echo "  View stage docs:     cat docs/stages/[N]_[NAME].md"
echo "  Invoke Claude Code:  claude code --instructions='...' less-to-tailwind-parser"

# Git setup reminder
echo -e "\n${BLUE}🔧 Setup Tips${NC}"
if [ -z "$(git config --global user.name)" ]; then
  echo -e "  ${YELLOW}⚠ Git user not configured${NC}"
  echo "    git config --global user.name 'Your Name'"
  echo "    git config --global user.email 'your@email.com'"
else
  echo -e "  ${GREEN}✓ Git configured${NC}: $(git config --global user.name)"
fi

# Database setup check
echo -e "\n${BLUE}💾 Database Setup${NC}"
if [ -f .env ]; then
  echo -e "  ${GREEN}✓ .env file found${NC}"
else
  echo -e "  ${YELLOW}○ .env file not found${NC}"
  echo "    Copy and configure: cp .env.example .env"
fi

# Stage directories
echo -e "\n${BLUE}📂 Stage Directories${NC}"
for i in {1..9}; do
  if [ -d "stages/$i" ]; then
    echo -e "  ${GREEN}✓${NC} Stage $i"
  fi
done

# Final message
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Ready for development! Type 'exit' to leave the container.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

# Execute the command (usually /bin/bash)
exec "$@"
