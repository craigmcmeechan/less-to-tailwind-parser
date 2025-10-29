#!/bin/bash
# Docker entrypoint script for LESS to Tailwind Parser development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Welcome message
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  LESS to Tailwind Parser - Development Environment         ║"
echo "║  Docker Container Ready with MCPs Enabled                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Environment info
echo -e "${GREEN}✓ Environment Information${NC}"
echo "  Node.js: $(node --version)"
echo "  npm: $(npm --version)"
echo "  TypeScript: $(npx typescript --version 2>/dev/null || echo 'installed')"
echo "  Claude Code: $(claude code --version 2>/dev/null || echo 'available')"
echo "  Git: $(git --version)"

# Check MCPs
echo -e "\n${PURPLE}✓ Model Context Protocol (MCP) Servers${NC}"
echo "  Postgres MCP:"
echo "    Command: npx @modelcontextprotocol/server-postgres"
echo "    Database: postgresql://dev:devpassword@postgres:5432/less_to_tailwind"
echo "    Status: $(npm list -g @modelcontextprotocol/server-postgres 2>/dev/null | grep -q server-postgres && echo '✓ Installed' || echo '○ Not found')"
echo ""
echo "  Git MCP:"
echo "    Command: npx @modelcontextprotocol/server-git /workspace"
echo "    Access: /workspace repository"
echo "    Status: $(npm list -g @modelcontextprotocol/server-git 2>/dev/null | grep -q server-git && echo '✓ Installed' || echo '○ Not found')"
echo ""
echo "  Filesystem MCP:"
echo "    Command: npx @modelcontextprotocol/server-filesystem /workspace"
echo "    Access: /workspace directory"
echo "    Status: $(npm list -g @modelcontextprotocol/server-filesystem 2>/dev/null | grep -q server-filesystem && echo '✓ Installed' || echo '○ Not found')"
echo ""
echo "  Sequential Thinking MCP:"
echo "    Command: npx @modelcontextprotocol/server-sequentialthinking"
echo "    Purpose: Structured reasoning and planning"
echo "    Status: $(npm list -g @modelcontextprotocol/server-sequentialthinking 2>/dev/null | grep -q server-sequentialthinking && echo '✓ Installed' || echo '○ Not found')"

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
echo "  MCP Config: /root/.claude/config.json"

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

# MCP Usage
echo -e "\n${PURPLE}🔌 Using MCPs with Claude Code${NC}"
echo "  Claude Code will automatically use configured MCPs:"
echo ""
echo "  PostgreSQL MCP:"
echo "    Query the less_to_tailwind database"
echo "    Run migrations and schema updates"
echo "    Example: 'Show me the schema for scanned_files table'"
echo ""
echo "  Git MCP:"
echo "    Check git history, diffs, status"
echo "    Make commits and manage branches"
echo "    Example: 'Show recent commits related to Stage 1'"
echo ""
echo "  Filesystem MCP:"
echo "    Read/write files in /workspace"
echo "    Create directories, manage project structure"
echo "    Example: 'Read docs/stages/01_DATABASE_FOUNDATION.md'"
echo ""
echo "  Sequential Thinking MCP:"
echo "    Break down complex problems"
echo "    Plan implementation steps"
echo "    Example: 'Help me plan Stage 1 implementation'"

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
echo -e "${BLUE}Claude Code is ready with MCPs enabled!${NC}"
echo -e "${BLUE}MCPs will automatically provide:"
echo -e "  • Database access via Postgres MCP"
echo -e "  • Git operations via Git MCP"
echo -e "  • File access via Filesystem MCP"
echo -e "  • Structured thinking via Sequential Thinking MCP${NC}"
echo -e "${BLUE}Type 'exit' to leave the container.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

# Execute the command (usually /bin/bash)
exec "$@"
