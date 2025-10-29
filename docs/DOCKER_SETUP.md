# Docker Development Environment Setup

Complete Docker setup for LESS to Tailwind Parser development with Claude Code, all necessary tools, and service infrastructure.

---

## 🐳 Quick Start

### Prerequisites

- Docker Desktop installed and running
- Docker Compose v1.29+ 
- Git configured locally (optional but recommended)

### Start the Development Environment

```bash
# Build and start all services
docker-compose up -d

# Enter the development container
docker-compose exec dev bash

# Inside the container - you're now in /workspace
```

That's it! You have a fully configured development environment.

---

## 📋 What's Included

### Services

| Service | Purpose | Port | Image |
|---------|---------|------|-------|
| **dev** | Main development container | - | Custom (Node.js 22) |
| **postgres** | PostgreSQL database | 5432 | postgres:16-alpine |
| **redis** | Cache/session store | 6379 | redis:7-alpine |

### Global npm Packages

Pre-installed globally for convenience:

```
├── @anthropic-ai/claude-code  (Claude Code CLI)
├── typescript                  (TypeScript compiler)
├── ts-node                      (TypeScript executor)
├── nodemon                      (Auto-reload on changes)
├── eslint                       (Code linting)
├── prettier                     (Code formatting)
├── jest                         (Test runner)
├── @types/node                  (Node.js types)
├── dotenv-cli                   (Env var management)
└── npm-check-updates            (Check for updates)
```

### System Tools

```
├── git                          (Version control)
├── curl                         (HTTP client)
├── bash                         (Shell)
├── vim & nano                   (Editors)
├── python3                      (Build dependencies)
├── make & g++                   (Build tools)
└── openssh-client               (SSH)
```

### Volume Mounts

| Local | Container | Purpose |
|-------|-----------|---------|
| `.` | `/workspace` | Full project code |
| `./stages/{1-9}` | `/workspace/stages/{1-9}` | Stage worktrees |
| `node_modules` | `/workspace/node_modules` | Cached dependencies |
| `npm-cache` | `/root/.npm` | Cached npm packages |
| `~/.gitconfig` | `/root/.gitconfig` | Git configuration |
| `~/.ssh` | `/root/.ssh` | SSH keys |

---

## 🚀 Usage

### Basic Commands

```bash
# Start services in the background
docker-compose up -d

# View logs from all services
docker-compose logs -f

# Enter the development container
docker-compose exec dev bash

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# Rebuild the image
docker-compose build --no-cache

# View service status
docker-compose ps
```

### Development Workflow

```bash
# 1. Start services
docker-compose up -d

# 2. Enter the container
docker-compose exec dev bash

# 3. Inside the container, you have everything ready:

# Bootstrap a stage
./bootstrap-stage.sh 1 DATABASE_FOUNDATION

# Invoke Claude Code
claude code --instructions="..." less-to-tailwind-parser

# Run tests
npm test

# Build project
npm run build

# Format code
npm run format

# Check linting
npm run lint

# View git log
git log --oneline | grep STAGE-

# Exit when done
exit
```

### Running Commands Without Entering Container

```bash
# Run npm commands
docker-compose exec dev npm test

# Run other commands
docker-compose exec dev npm run build
docker-compose exec dev npm run lint
docker-compose exec dev npm run format

# Bootstrap a stage
docker-compose exec dev ./bootstrap-stage.sh 1 DATABASE_FOUNDATION

# View files
docker-compose exec dev cat docs/stages/01_DATABASE_FOUNDATION.md

# Run git commands
docker-compose exec dev git log --oneline | head -10
```

---

## 🔧 Configuration

### Environment Variables

The container uses default development settings. For production-like configuration:

```bash
# Copy example .env file (if it exists)
cp .env.example .env

# Edit with your settings
nano .env

# Restart services to apply
docker-compose restart dev
```

### Database Connection

From inside the container:

```bash
# PostgreSQL connection string
postgresql://dev:devpassword@postgres:5432/less_to_tailwind

# Or use psql to connect
psql -U dev -h postgres -d less_to_tailwind
```

### Redis Connection

```bash
# Redis connection string
redis://redis:6379

# Or use redis-cli
redis-cli -h redis
```

### Customize Resource Limits

Edit `docker-compose.yml`:

```yaml
dev:
  deploy:
    resources:
      limits:
        cpus: '4'           # Increase CPU limit
        memory: 8G          # Increase memory limit
      reservations:
        cpus: '2'           # Minimum CPU
        memory: 4G          # Minimum memory
```

---

## 💡 Tips & Tricks

### Speed Up Builds

Node modules are in a named volume (persistent):

```bash
# First run builds the image - takes a few minutes
docker-compose build

# Subsequent runs use cache - starts instantly
docker-compose up -d
```

### Preserve Bash History

Your bash history is saved in a volume between sessions:

```bash
# Previous commands persist even after stopping container
docker-compose down
docker-compose up -d
docker-compose exec dev bash
# history shows previous commands!
```

### Use Git Inside Container

Your git config and SSH keys are mounted:

```bash
docker-compose exec dev bash
git config --global user.name              # Works!
git push origin stage-1-complete           # Works with SSH!
```

### View Container Logs

```bash
# All services
docker-compose logs -f

# Just the dev container
docker-compose logs -f dev

# Just PostgreSQL
docker-compose logs -f postgres

# Just the last 100 lines
docker-compose logs --tail=100
```

### Access Services from Host

All services are accessible from your local machine:

```bash
# PostgreSQL from host (if psql installed)
psql -U dev -h localhost -p 5432 -d less_to_tailwind

# Redis from host (if redis-cli installed)
redis-cli -h localhost -p 6379

# API server (once running)
curl http://localhost:3000
```

### Rebuild After Major Changes

```bash
# Clean rebuild (removes everything)
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

---

## 🔍 Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs dev

# Verify services
docker-compose ps

# Try rebuilding
docker-compose build --no-cache
docker-compose up -d
```

### Permission denied errors

```bash
# Ensure user ownership in container
docker-compose exec dev chown -R node:node /workspace
```

### Port already in use

```bash
# Change port in docker-compose.yml
# Change from 5432:5432 to 5433:5432
# Then: psql -h localhost -p 5433
```

### Node modules not updating

```bash
# Clear npm cache and reinstall
docker-compose exec dev npm cache clean --force
docker-compose exec dev npm install
```

### Database connection refused

```bash
# Ensure postgres service is running
docker-compose ps

# Check logs
docker-compose logs postgres

# Wait for postgres to be ready (takes ~5-10 seconds)
docker-compose exec postgres pg_isready
```

---

## 🎯 Workflow Examples

### Example 1: Develop Stage 1

```bash
# 1. Start environment
docker-compose up -d

# 2. Enter container
docker-compose exec dev bash

# 3. Bootstrap stage
./bootstrap-stage.sh 1 DATABASE_FOUNDATION

# 4. Read the TODO
cat STAGE_1_TODO.md

# 5. Look up invocation (in another terminal or tab)
grep -A 30 "Stage 1:" docs/CLAUDE_CODE_INVOCATION.md

# 6. Invoke Claude Code (copy from docs)
claude code --instructions="..." less-to-tailwind-parser

# 7. Monitor tests (in another terminal)
docker-compose exec dev npm test

# 8. When done, verify
docker-compose exec dev npm run build
docker-compose exec dev npm test
docker-compose exec dev npm run lint

# 9. Exit
exit
```

### Example 2: Quick Test Run

```bash
# Without entering container
docker-compose exec dev npm test

# Watch for changes
docker-compose exec dev npm run dev
```

### Example 3: Debug Database Issues

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U dev -d less_to_tailwind

# Or from dev container
docker-compose exec dev bash
psql -U dev -h postgres -d less_to_tailwind
```

---

## 📊 Resource Usage

Current configuration:

```
CPU:
  - Limit: 2 cores per service
  - Reservation: 1 core per service
  - Total: ~3 cores under load

Memory:
  - Limit: 4GB per service
  - Reservation: 2GB per service
  - Total: ~6GB under load
  
Disk:
  - node_modules: ~1-2GB (shared across services)
  - postgres-data: ~100MB (empty database)
  - redis-data: ~10MB
```

Adjust in `docker-compose.yml` if needed.

---

## 🔄 Updating Dependencies

```bash
# Inside container
npm update

# Check for outdated packages
npm outdated

# Check for updates with npm-check-updates
ncu
ncu -u
npm install
```

---

## 🛑 Stopping & Cleanup

```bash
# Stop services (keeps data)
docker-compose stop

# Restart services
docker-compose start

# Stop and remove containers (keeps data)
docker-compose down

# Stop and remove containers + volumes (DELETES DATA)
docker-compose down -v

# Remove unused images/volumes
docker system prune
```

---

## 📝 Files Reference

| File | Purpose |
|------|---------|
| `Dockerfile` | Container definition with all tools |
| `docker-compose.yml` | Service orchestration |
| `.dockerignore` | Files to exclude from build |
| `docker-entrypoint.sh` | Startup script with diagnostics |

---

## 🆘 Getting Help

### Check Service Health

```bash
# All services
docker-compose ps

# Service logs
docker-compose logs dev
docker-compose logs postgres
docker-compose logs redis

# Health status
docker-compose exec dev npm run build
```

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Container won't start | `docker-compose logs dev` → check errors |
| Port in use | Edit `docker-compose.yml`, change port mapping |
| Permission denied | `sudo chown -R $USER:$USER .` |
| npm packages not found | `docker-compose exec dev npm install` |
| Database won't connect | Wait 10s for postgres to start, check logs |

---

## 🚀 Next Steps

1. **Start the environment:**
   ```bash
   docker-compose up -d
   ```

2. **Enter the container:**
   ```bash
   docker-compose exec dev bash
   ```

3. **Bootstrap Stage 1:**
   ```bash
   ./bootstrap-stage.sh 1 DATABASE_FOUNDATION
   ```

4. **Review the workflow:**
   ```bash
   cat docs/GETTING_STARTED_WITH_CLAUDE_CODE.md
   ```

5. **Invoke Claude Code:**
   ```bash
   # Copy from docs/CLAUDE_CODE_INVOCATION.md - Stage 1 section
   ```

---

## 📚 Related Documentation

- [GETTING_STARTED_WITH_CLAUDE_CODE.md](./docs/GETTING_STARTED_WITH_CLAUDE_CODE.md) - Claude Code quick start
- [CLAUDE_CODE_INVOCATION.md](./docs/CLAUDE_CODE_INVOCATION.md) - Stage-specific invocations
- [CLAUDE_CODE_WORKFLOW.md](./docs/CLAUDE_CODE_WORKFLOW.md) - Detailed workflow
- [PROJECT_ROADMAP.md](./docs/PROJECT_ROADMAP.md) - Project timeline

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025  
**Container Base:** Node.js 22-Alpine
