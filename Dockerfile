# Dockerfile for LESS to Tailwind Parser Development Environment
# Multi-stage build with development tools, Claude Code, and MCPs

FROM node:22-alpine as base

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    bash \
    vim \
    nano \
    openssh-client \
    ca-certificates \
    python3 \
    make \
    g++ \
    postgresql-client \
    jq

# Set up development environment
WORKDIR /workspace

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Install MCP servers globally
# 1. Postgres MCP - for database operations
RUN npm install -g @modelcontextprotocol/server-postgres

# 2. Git MCP - for git operations
RUN npm install -g @modelcontextprotocol/server-git

# 3. Filesystem MCP - for file operations in /workspace
RUN npm install -g @modelcontextprotocol/server-filesystem

# 4. Sequential Thinking MCP - for structured reasoning
RUN npm install -g @modelcontextprotocol/server-sequentialthinking

# Install useful global npm packages for development
RUN npm install -g \
    typescript \
    ts-node \
    nodemon \
    eslint \
    prettier \
    jest \
    @types/node \
    dotenv-cli \
    npm-check-updates

# Create stage worktree directories
RUN mkdir -p /workspace/stages

# Create MCP config directory
RUN mkdir -p /root/.claude

# Copy package files
COPY package*.json ./

# Install project dependencies
RUN npm ci

# Build the project
RUN npm run build

# Copy MCP configuration
COPY claude-mcp-config.json /root/.claude/config.json

# Set environment variables
ENV NODE_ENV=development
ENV PATH=/workspace/node_modules/.bin:$PATH
ENV CLAUDE_MCP_SERVERS=/root/.claude/config.json

# Default shell
SHELL ["/bin/bash", "-c"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD npm run build 2>/dev/null && echo "healthy" || exit 1

# Entry point
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
