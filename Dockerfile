FROM node:20-alpine

# Set working directory
WORKDIR /workspace

# Install system dependencies for MCPs and development
RUN apk add --no-cache \
    git \
    postgresql-client \
    python3 \
    py3-pip \
    bash \
    curl \
    jq \
    build-essential \
    python3-dev

# Install Node.js global tools
RUN npm install -g \
    @anthropic-ai/sdk \
    typescript \
    ts-node \
    pm2

# Create MCP server directory
RUN mkdir -p /mcp/servers

# Install MCP Servers
# 1. PostgreSQL MCP Server
RUN npm install -g @modelcontextprotocol/server-postgres@latest

# 2. Git MCP Server
RUN npm install -g @modelcontextprotocol/server-git@latest

# 3. Filesystem MCP Server
RUN npm install -g @modelcontextprotocol/server-filesystem@latest

# 4. Sequential Thinking support (via Claude extensions)
RUN npm install -g @anthropic-ai/thinking-toolkit@latest || true

# Copy MCP configuration
COPY .mcp-config.json /root/.mcp-config.json
COPY mcp-servers.json /mcp/servers.json

# Create initialization script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Copy application files
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the project
RUN npm run build

# Expose ports for MCP servers
EXPOSE 3000 5432 9000-9010

# Set environment variables
ENV NODE_ENV=production
ENV MCP_CONFIG_PATH=/root/.mcp-config.json
ENV WORKSPACE=/workspace
ENV DATABASE_URL=postgresql://localhost/less_to_tailwind
ENV PATH="/mcp/bin:${PATH}"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD npm run health || exit 1

# Run entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["npm", "start"]
