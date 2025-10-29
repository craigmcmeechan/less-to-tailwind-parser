# Git Workspaces Guide

## Overview

This project uses Git worktrees to manage parallel development of different stages. Each stage has its own working directory, allowing you to work on multiple stages simultaneously without constantly switching branches.

**Benefits:**
- ✅ Work on Stage 4 while Stage 3 is being reviewed
- ✅ Keep dependencies consistent (separate `node_modules` per stage)
- ✅ Easy context switching without branch checkout time
- ✅ Parallel testing and development
- ✅ Cleaner git history (one branch per logical unit)

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/craigmcmeechan/less-to-tailwind-parser.git
cd less-to-tailwind-parser
```

### 2. Run the Setup Script

```bash
bash setup-workspaces.sh
```

This will:
- Create branches for each stage
- Create worktrees at `.worktrees/stage-1`, `.worktrees/stage-2`, etc.
- Create `.stage-info.md` in each worktree with quick reference

### 3. Verify Setup

```bash
git worktree list
```

Output should show:
```
/path/to/project                (detached HEAD 67d2571)
/path/to/project/.worktrees/dev (branch develop)
/path/to/project/.worktrees/stage-1 (branch feature/01-database-foundation)
/path/to/project/.worktrees/stage-2 (branch feature/02-less-scanning)
... (one for each stage)
```

---

## Directory Structure

```
less-to-tailwind-parser/
├── .git/
├── .worktrees/                    # All stage workspaces
│   ├── dev/                       # Development workspace
│   ├── stage-1/                   # Stage 1 workspace
│   ├── stage-2/                   # Stage 2 workspace
│   ├── stage-3/                   # Stage 3 workspace
│   ├── stage-4/                   # Stage 4 workspace
│   ├── stage-5/                   # Stage 5 workspace
│   ├── stage-6/                   # Stage 6 workspace
│   ├── stage-7/                   # Stage 7 workspace
│   ├── stage-8/                   # Stage 8 workspace
│   └── stage-9/                   # Stage 9 workspace
├── docs/
├── package.json
├── setup-workspaces.sh
└── ... (other files)
```

Each worktree is a complete, independent working directory on its own branch.

---

## Workflow: Working on a Stage

### 1. Enter a Stage Workspace

```bash
cd .worktrees/stage-1
```

### 2. Install Dependencies (First Time Only)

```bash
npm install
```

Each worktree has its own `node_modules`.

### 3. Check Stage Documentation

```bash
# From within stage-1 worktree
cat ../../docs/stages/01_DATABASE_FOUNDATION.md
```

Or from project root:
```bash
cat docs/stages/01_DATABASE_FOUNDATION.md
```

### 4. Create Implementation Files

```bash
# Example: creating Stage 1 database service
touch src/services/databaseService.ts
```

### 5. Write Code & Tests

```bash
# Run tests for this stage
npm test -- stage-1

# Run linting
npm run lint
```

### 6. Commit Your Work

```bash
# While in the stage-1 worktree
git add .
git commit -m "feat: implement database connection pooling

- Add pg connection pool
- Configure for PostgreSQL 14+
- Add health check endpoint
- Closes #1"
```

### 7. Return to Main Directory

```bash
cd ../..
```

---

## Common Commands

### View All Worktrees

```bash
git worktree list
```

### Create a New Worktree (If Needed)

```bash
git worktree add .worktrees/new-feature feature/my-feature
```

### Remove a Worktree When Done

```bash
# First, clean up the stage work
git worktree remove .worktrees/stage-1

# Then delete the branch if no longer needed
git branch -d feature/01-database-foundation
```

### Switch to a Worktree from Anywhere

```bash
cd .worktrees/stage-3
# or
cd .worktrees/stage-7
```

### View Recent Commits in a Worktree

```bash
# While in a worktree
cd .worktrees/stage-4
git log --oneline -10
```

---

## Development Scenarios

### Scenario 1: You're on Stage 3, Stage 2 Found a Bug

**Without Worktrees:**
1. Stash Stage 3 work
2. Checkout Stage 2 branch
3. Fix bug
4. Commit and push
5. Checkout Stage 3 branch
6. Pop stash
7. Resolve conflicts
8. Continue

**With Worktrees:**
1. In another terminal: `cd .worktrees/stage-2`
2. Fix bug
3. Commit
4. Back to Stage 3 terminal, continue working

### Scenario 2: Parallel Development

**Team Setup:**
- Dev A: `cd .worktrees/stage-1` (Database)
- Dev B: `cd .worktrees/stage-4` (Rule Extraction)
- Dev C: `cd .worktrees/stage-7` (Testing)

All working simultaneously, no conflicts.

### Scenario 3: Testing Across Stages

```bash
# Terminal 1: Stage 4 implementation
cd .worktrees/stage-4
npm run dev

# Terminal 2: Stage 4 tests
cd .worktrees/stage-4
npm test -- --watch

# Terminal 3: Check main branch
cd .
git status

# Terminal 4: Review other stages
cd .worktrees/stage-3
git log --oneline
```

---

## Branch Naming Convention

Each stage follows this pattern:

```
feature/XX-description

Where:
  XX = Stage number (01, 02, ... 09)
  description = kebab-case description
```

Examples:
```
feature/01-database-foundation
feature/02-less-scanning
feature/03-import-hierarchy
feature/04-rule-extraction
feature/05-variable-extraction
feature/06-tailwind-export
feature/07-integration
feature/08-chrome-extension
feature/09-dom-matching

develop (integration branch for all stages)
main (production/release branch)
```

---

## Commit Message Convention

```
type: subject

body

footer

Where type is one of: feat, fix, docs, style, refactor, perf, test, chore
```

Examples:

```
feat: implement SHA256 checksum calculation for LESS files

- Use crypto module for SHA256
- Add unit tests
- Integrate with ScanService

Closes #42
```

```
fix: handle circular imports in dependency graph

- Add cycle detection using DFS
- Return cycles in API response
- Add test for circular import scenario

Fixes #38
```

---

## Git Workflow: From Stage to Main

### 1. Complete Stage Work

```bash
cd .worktrees/stage-1
npm test
npm run lint
git log # verify commits
```

### 2. Push Stage Branch

```bash
git push origin feature/01-database-foundation
```

### 3. Create Pull Request

On GitHub:
1. Go to Pull Requests
2. Create PR from `feature/01-database-foundation` → `develop`
3. Reference documentation (docs/stages/01_DATABASE_FOUNDATION.md)
4. Link acceptance criteria

### 4. Code Review & Merge

- Reviewers approve
- CI/CD pipeline passes
- Merge to `develop`

### 5. Update Main Branch

```bash
cd .
git checkout main
git pull origin main
git merge develop
git push origin main
```

---

## Shared Code Between Stages

Some code is used by multiple stages. Keep it in `src/shared/`:

```
src/
├── shared/
│   ├── database.ts         # Shared across all stages
│   ├── logger.ts           # Shared across all stages
│   ├── types.ts            # Shared type definitions
│   └── utils.ts
├── part1/
│   ├── services/
│   │   ├── scanService.ts  # Stage 2 specific
│   │   ├── importResolverService.ts  # Stage 3 specific
│   │   └── ...
│   └── ...
└── part2/
    ├── services/
    │   ├── captureService.ts  # Stage 8 specific
    │   ├── matchingService.ts  # Stage 9 specific
    │   └── ...
    └── ...
```

When you update `src/shared/database.ts` in Stage 1, it automatically affects all other stages (same file, different branches share through main).

---

## Troubleshooting

### Problem: Worktree doesn't exist

```bash
bash setup-workspaces.sh
```

### Problem: Changes lost in worktree

```bash
cd .worktrees/stage-X
git log # check if commits exist
git reflog # see all commits
```

### Problem: Worktree is stale

```bash
cd .worktrees/stage-X
git fetch origin
git merge origin/feature/XX-description
```

### Problem: Want to abandon a worktree

```bash
# Don't lose uncommitted work!
cd .worktrees/stage-X
git add .
git commit -m "WIP: checkpoint before abandonment"
git push

# Then remove
cd ../..
git worktree remove .worktrees/stage-X
```

### Problem: Merge conflicts between stages

Since each stage is independent, conflicts are rare. If they occur:

1. **In shared code (`src/shared/`):**
   ```bash
   cd .worktrees/stage-X
   git fetch origin
   git rebase origin/develop  # Get latest shared code
   # Resolve conflicts
   ```

2. **In stage-specific code:**
   Each stage owns its code, so merge only happens to `main`/`develop`, not between worktrees.

---

## Best Practices

✅ **DO:**
- Commit frequently (every logical change)
- Push regularly (daily minimum)
- Use descriptive commit messages
- Run tests before committing
- Keep workspaces up to date: `git fetch origin`

❌ **DON'T:**
- Commit node_modules (use .gitignore)
- Merge branches locally; use GitHub PR
- Work on multiple stages in same worktree
- Leave long-running stashes
- Push to main directly (always use PR)

---

## Quick Reference

```bash
# Setup
bash setup-workspaces.sh

# List all worktrees
git worktree list

# Enter a stage
cd .worktrees/stage-1

# Work and commit
git add .
git commit -m "your message"
git push origin feature/01-database-foundation

# Return to main
cd ../..

# Remove worktree when done
git worktree remove .worktrees/stage-1
git branch -d feature/01-database-foundation
```

---

## Questions?

See individual stage documentation:
- `docs/stages/01_DATABASE_FOUNDATION.md`
- `docs/stages/02_LESS_SCANNING.md`
- ... etc

---

**Last Updated:** October 29, 2025
