# MCPs (Model Context Protocol) in Docker Environment

Complete reference for using MCPs with Claude Code in the development container.

---

## 🔌 Available MCPs

All MCPs are pre-installed and configured globally in the container.

### 1. Postgres MCP

**Purpose:** Direct database access and operations

**Access Point:** `postgresql://dev:devpassword@postgres:5432/less_to_tailwind`

**Available Operations:**
- Query tables and schemas
- Run migrations
- Execute SQL commands
- Inspect table structure
- Test database connections

**Example Usage:**
```
Claude: "Show me the schema for the scanned_files table"
Postgres MCP → Queries database → Returns schema information
```

**Configuration:**
```json
{
  "postgres": {
    "command": "npx @modelcontextprotocol/server-postgres",
    "env": {
      "DATABASE_URL": "postgresql://dev:devpassword@postgres:5432/less_to_tailwind"
    }
  }
}
```

---

### 2. Git MCP

**Purpose:** Git repository operations within /workspace

**Access Point:** `/workspace` (project root)

**Available Operations:**
- View commit history
- Check git status
- Create branches
- Stage and commit changes
- View diffs and logs
- Track file changes

**Example Usage:**
```
Claude: "Show me the recent commits related to Stage 1"
Git MCP → Queries git log → Returns commit history
```

```
Claude: "Commit all changes with message STAGE-1-1: Database setup"
Git MCP → Stages files → Creates commit → Returns result
```

**Configuration:**
```json
{
  "git": {
    "command": "npx @modelcontextprotocol/server-git",
    "args": ["/workspace"]
  }
}
```

---

### 3. Filesystem MCP

**Purpose:** Read/write files and manage directories in /workspace

**Access Point:** `/workspace` (root of project)

**Available Operations:**
- Read files
- Write files
- Create directories
- List directory contents
- Delete files (with confirmation)
- Manage file permissions
- Search for files

**Example Usage:**
```
Claude: "Read docs/stages/01_DATABASE_FOUNDATION.md"
Filesystem MCP → Reads file → Returns content
```

```
Claude: "Create a new file STAGE_1_TODO.md with this content..."
Filesystem MCP → Creates file → Returns result
```

**Configuration:**
```json
{
  "filesystem": {
    "command": "npx @modelcontextprotocol/server-filesystem",
    "args": ["/workspace"],
    "env": {
      "ALLOWED_PATHS": "/workspace"
    }
  }
}
```

---

### 4. Sequential Thinking MCP

**Purpose:** Structured reasoning and problem decomposition

**Access Point:** Claude's reasoning layer

**Available Operations:**
- Break down complex problems
- Create step-by-step plans
- Track reasoning chains
- Organize thoughts
- Plan implementation

**Example Usage:**
```
Claude: "Help me plan the implementation for Stage 1: Database Foundation"
Sequential Thinking MCP → Organizes thinking → Returns structured plan
```

```
Claude: "What are the sequential steps needed to implement LESS scanning?"
Sequential Thinking MCP → Breaks into steps → Returns decomposed tasks
```

**Configuration:**
```json
{
  "sequentialthinking": {
    "command": "npx @modelcontextprotocol/server-sequentialthinking"
  }
}
```

---

## 🎯 How MCPs Work with Claude Code

### Automatic Integration

When you invoke Claude Code inside the container:

```bash
claude code --instructions="..." less-to-tailwind-parser
```

Claude Code automatically has access to all configured MCPs. It can:

1. **Read files via Filesystem MCP**
   - Load stage documentation
   - Review existing code
   - Check project structure

2. **Query database via Postgres MCP**
   - Check schema
   - Verify table creation
   - Run test queries

3. **Manage git via Git MCP**
   - View git history
   - Stage changes
   - Create commits
   - Check status

4. **Plan implementation via Sequential Thinking MCP**
   - Break down stages into steps
   - Organize implementation plan
   - Track reasoning

### Example: Claude Code Uses MCPs

```
User: "Invoke Claude Code for Stage 1"
       ↓
Claude Code Starts
       ↓
Claude: "Let me understand what we're building..."
        → Uses Filesystem MCP to read docs/stages/01_DATABASE_FOUNDATION.md
        → Uses Sequential Thinking MCP to plan steps
       ↓
Claude: "I'll create a database connection..."
        → Uses Filesystem MCP to create database.ts
        → Uses Git MCP to check status
       ↓
Claude: "Let me verify the schema..."
        → Uses Postgres MCP to query the database
        → Checks if tables were created
       ↓
Claude: "Tests pass! Let me commit..."
        → Uses Git MCP to stage and commit changes
        → Commit message: "STAGE-1-1: Database foundation setup"
```

---

## 🔄 Typical MCP Usage Patterns

### Pattern 1: Reading Documentation

```bash
# Inside container
docker-compose exec dev bash

# Claude reads documentation
claude code --instructions="Read docs/stages/[N]_[NAME].md and explain what needs to be done"
```

Claude uses **Filesystem MCP** to read documentation files.

### Pattern 2: Database Operations

```bash
# Claude queries the database
claude code --instructions="Check if the scanned_files table exists and show me its schema"
```

Claude uses **Postgres MCP** to query database structure.

### Pattern 3: Git Workflow

```bash
# Claude commits code
claude code --instructions="After completing Stage 1, commit with message STAGE-1-COMPLETE"
```

Claude uses **Git MCP** to stage, commit, and push changes.

### Pattern 4: Planning

```bash
# Claude plans implementation
claude code --instructions="Break Stage 2 implementation into sequential, testable steps"
```

Claude uses **Sequential Thinking MCP** to organize implementation plan.

### Pattern 5: File Management

```bash
# Claude manages project files
claude code --instructions="Create STAGE_1_TODO.md with the implementation steps"
```

Claude uses **Filesystem MCP** to create and manage files.

---

## 📊 MCP Configuration Reference

### Complete Configuration File

Location: `/root/.claude/config.json`

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://dev:devpassword@postgres:5432/less_to_tailwind"
      },
      "disabled": false
    },
    "git": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-git", "/workspace"],
      "disabled": false
    },
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/workspace"],
      "env": {
        "ALLOWED_PATHS": "/workspace"
      },
      "disabled": false
    },
    "sequentialthinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequentialthinking"],
      "disabled": false
    }
  }
}
```

### Enabling/Disabling MCPs

Edit `/root/.claude/config.json`:

```json
{
  "postgres": {
    "disabled": false    // true to disable
  }
}
```

---

## 🚀 Quick MCP Commands

### Check MCP Status

```bash
# Inside container
npm list -g @modelcontextprotocol/server-*

# Shows installed MCPs:
# @modelcontextprotocol/server-postgres
# @modelcontextprotocol/server-git
# @modelcontextprotocol/server-filesystem
# @modelcontextprotocol/server-sequentialthinking
```

### Test Postgres MCP

```bash
# Inside container
psql -U dev -h postgres -d less_to_tailwind -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public';"
```

### Test Filesystem MCP

```bash
# Inside container
ls -la /workspace
cat docs/stages/01_DATABASE_FOUNDATION.md
```

### Test Git MCP

```bash
# Inside container
git status
git log --oneline | head -5
```

---

## 💡 Tips & Best Practices

### Use MCPs Effectively

1. **Ask Claude to read docs first**
   ```
   "Read the stage documentation and explain what needs to be implemented"
   ```
   → Filesystem MCP reads docs
   → Claude understands requirements

2. **Have Claude check database state**
   ```
   "Query the database to see what tables exist"
   ```
   → Postgres MCP queries schema
   → Claude sees current state

3. **Use git history for context**
   ```
   "Show me recent commits to understand the pattern"
   ```
   → Git MCP shows history
   → Claude follows established patterns

4. **Plan with sequential thinking**
   ```
   "Break this stage into sequential, testable steps"
   ```
   → Sequential Thinking MCP organizes
   → Claude returns structured plan

### Performance Notes

- **Postgres MCP:** Queries are instant (connected to docker postgres)
- **Git MCP:** Operations are fast (local repository)
- **Filesystem MCP:** File I/O is instant (mounted volume)
- **Sequential Thinking MCP:** Planning is fast (reasoning layer)

### Security

- **Postgres MCP:** Read/write access limited to `less_to_tailwind` database
- **Git MCP:** Access limited to `/workspace` repository
- **Filesystem MCP:** Access limited to `/workspace` directory
- **Sequential Thinking MCP:** No external access (reasoning only)

---

## 🔧 Troubleshooting

### MCP Not Working

```bash
# Check if MCP is installed
npm list -g @modelcontextprotocol/server-postgres

# If missing, install manually
npm install -g @modelcontextprotocol/server-postgres

# Verify config file
cat /root/.claude/config.json

# Check if enabled (disabled: false)
```

### Postgres MCP Connection Failed

```bash
# Verify postgres service is running
docker-compose ps postgres

# Test connection manually
psql -U dev -h postgres -d less_to_tailwind

# Check DATABASE_URL in config
cat /root/.claude/config.json | grep DATABASE_URL
```

### Filesystem MCP Permission Denied

```bash
# Verify /workspace is accessible
ls -la /workspace

# Check ALLOWED_PATHS in config
cat /root/.claude/config.json | grep ALLOWED_PATHS

# Ensure proper permissions
chmod 755 /workspace
```

### Git MCP Not Finding Repository

```bash
# Verify git repository exists
ls -la /workspace/.git

# Check git status
git status

# Verify git config
git config --list
```

---

## 📚 Related Documentation

- [docs/DOCKER_SETUP.md](./DOCKER_SETUP.md) - Main Docker guide
- [docs/GETTING_STARTED_WITH_CLAUDE_CODE.md](./GETTING_STARTED_WITH_CLAUDE_CODE.md) - Claude Code guide
- [docs/CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md) - Workflow details

---

## ✨ Summary

MCPs provide Claude Code with:

✅ **Database access** - Query and manage PostgreSQL  
✅ **File management** - Read/write files in /workspace  
✅ **Git operations** - Manage version control  
✅ **Structured thinking** - Plan and organize implementation  

All MCPs are automatically configured and ready to use!

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025  
**Status:** ✅ Ready for use
