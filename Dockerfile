# Dockerfile for LESS to Tailwind Parser Development Environment
# Multi-stage build with development tools and global dependencies

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
    g++

# Set up development environment
WORKDIR /workspace

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

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

# Copy package files
COPY package*.json ./

# Install project dependencies
RUN npm ci

# Build the project
RUN npm run build

# Set environment variables
ENV NODE_ENV=development
ENV PATH=/workspace/node_modules/.bin:$PATH

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
