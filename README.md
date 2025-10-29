# LESS to Tailwind Parser

Convert LESS CSS files to Tailwind CSS configuration with Chrome extension DOM capture and intelligent matching.

**Status:** 📋 Ready for development  
**Architecture:** ✅ Corrected and complete  
**Workspaces:** ✅ Set up and ready to use

---

## Quick Start (5 Minutes)

```bash
# 1. Clone repository
git clone https://github.com/craigmcmeechan/less-to-tailwind-parser.git
cd less-to-tailwind-parser

# 2. Create workspaces for each stage
bash setup-workspaces.sh

# 3. Enter your first stage
cd .worktrees/stage-1

# 4. Install and start
npm install
npm run dev
```

See **QUICK_START.md** for more details.

---

## Project Overview

### Part 1: LESS Extraction (Stages 1-7)
Transform LESS CSS files into PostgreSQL with extracted theme tokens and compiled CSS rules.

**Stages:**
1. **Database Foundation** - PostgreSQL setup, migrations
2. **LESS File Scanning** - Discover and version LESS files
3. **Import Hierarchy** - Parse LESS @import relationships
4. **CSS Rule Extraction** - Compile LESS to CSS with resolved variables ⭐ CRITICAL
5. **Variable Extraction** - Extract @variables, @mixins, @functions
6. **Tailwind Export** - Generate tailwind.config.js
7. **Integration & Testing** - Full pipeline, CLI, testing

### Part 2: DOM Capture + Matching (Stages 8-9)
Chrome extension captures DOM elements → backend matches to LESS rules → generates Tailwind suggestions.

**Stages:**
8. **Chrome Extension** - Optimized DOM capture tool
9. **Backend Matching** - CSS selector matching, cascade resolution, Tailwind generation

---

## Documentation

### Start Here
- **QUICK_START.md** - 5-minute setup guide
- **GIT_WORKSPACES_GUIDE.md** - Complete workspace usage guide
- **GIT_WORKSPACES_SETUP.md** - What was created and why

### Architecture & Design
- **ARCHITECTURE_CORRECTIONS.md** - All blind spots identified and fixed
- **docs/ARCHITECTURE.md** - System design overview
- **docs/PROJECT_ROADMAP.md** - Complete timeline and milestones

### Implementation Guides
- **docs/stages/01_DATABASE_FOUNDATION.md**
- **docs/stages/02_LESS_SCANNING.md**
- **docs/stages/03_IMPORT_HIERARCHY.md**
- **docs/stages/04_RULE_EXTRACTION.md** (NEW - CRITICAL STAGE)
- **docs/stages/05_VARIABLE_EXTRACTION.md**
- **docs/stages/06_TAILWIND_EXPORT.md**
- **docs/stages/07_INTEGRATION.md**
- **docs/stages/08_CHROME_EXTENSION.md** (ENHANCED)
- **docs/stages/09_DOM_TO_TAILWIND.md** (REWRITTEN)

### Code Standards & Practices
- **docs/CODE_STANDARDS.md** - TypeScript conventions
- **docs/TESTING_GUIDE.md** - Jest setup and coverage
- **docs/LOGGING_GUIDE.md** - Logging practices
- **docs/ERROR_HANDLING.md** - Error strategies
- **docs/DATABASE_OPERATIONS.md** - Query patterns

---

## Git Workspaces

Each stage has its own independent Git worktree for parallel development.

### Available Workspaces
```
.worktrees/
├── dev/                          # Integration branch
├── stage-1/                       # Database Foundation
├── stage-2/                       # LESS File Scanning
├── stage-3/                       # Import Hierarchy
├── stage-4/                       # CSS Rule Extraction
├── stage-5/                       # Variable Extraction
├── stage-6/                       # Tailwind Export
├── stage-7/                       # Integration & Testing
├── stage-8/                       # Chrome Extension
└── stage-9/                       # DOM Matching & Tailwind
```

### Quick Commands

```bash
# Setup
bash setup-workspaces.sh

# Using shell
cd .worktrees/stage-1

# Using Makefile
make enter-stage-1
make list
make install-all
make push-all
```

See **GIT_WORKSPACES_GUIDE.md** for all commands.

---

## Architecture Highlights

### ✅ What's Correct
- Using Chrome computed styles for cascade resolution
- Hierarchical DOM storage allows parent context
- Backend-only matching keeps extension simple
- Part 1 scope hierarchy for variable resolution

### ✨ Recent Corrections
- **Stage 4 specification** - CSS compilation with specificity calculation
- **Real CSS matching** - Selector parsing, descendant/attribute/pseudo-classes
- **Cascade resolution** - Specificity + rule ordering for correct winner
- **Variable resolution** - Happens in Part 1, used by Stage 4
- **Media queries** - Full responsive design support

See **ARCHITECTURE_CORRECTIONS.md** for detailed analysis.

---

## Key Blind Spots Fixed

| Issue | Impact | Fix |
|-------|--------|-----|
| Stage 4 missing | No CSS rules for matching | Created full Stage 4 spec |
| Extension inefficient | 10x slower, huge payloads | Optimized property capture |
| Naive matching | Only matches 30% of rules | Real CSS selector engine |
| No cascade logic | Wrong rules selected | Specificity + order tracking |
| Variables unresolved | Matching fails on values | Resolved in Part 1 → Stage 4 |
| Media queries ignored | No responsive support | Full viewport context |

---

## Critical Stage: Stage 4

⚠️ **Stage 4 (CSS Rule Extraction) is not optional.**

It's the bridge between LESS source and matching engine:
- Compiles LESS to CSS
- Resolves variables using Part 1 scope
- Calculates CSS specificity
- Tracks rule order for cascade
- Handles media queries

**Must be completed before Stage 9 can work.**

---

## Development Workflow

### Single Developer
```bash
# Enter Stage 1
cd .worktrees/stage-1

# Make changes
# Run tests
npm test

# Commit
git add . && git commit -m "feat: ..."
git push origin feature/01-database-foundation

# Create PR on GitHub
```

### Team (Parallel)
```bash
# Dev A: Stage 1
cd .worktrees/stage-1

# Dev B: Stage 4 (in other terminal)
cd .worktrees/stage-4

# Dev C: Stage 7 (in another terminal)
cd .worktrees/stage-7

# All work simultaneously, no conflicts
```

---

## Project Structure

```
less-to-tailwind-parser/
├── .worktrees/                     # Git worktrees (one per stage)
│   ├── stage-1/
│   ├── stage-2/
│   └── ...
├── docs/                           # Documentation (shared)
│   ├── stages/                     # Stage guides
│   └── *.md
├── src/                            # Source code (shared)
│   ├── shared/                     # Used by all stages
│   ├── part1/                      # Stages 1-7
│   └── part2/                      # Stages 8-9
├── tests/                          # Tests
├── package.json
├── Makefile                        # Workspace commands
├── setup-workspaces.sh             # Setup script
├── GIT_WORKSPACES_GUIDE.md         # Full guide
├── QUICK_START.md                  # Quick start
└── README.md                       # This file
```

---

## Technology Stack

- **Language:** TypeScript
- **Runtime:** Node.js
- **Database:** PostgreSQL
- **API:** Express.js
- **Testing:** Jest
- **Browser:** Chrome Extension (Manifest v3)
- **CSS Framework:** Tailwind CSS

---

## Getting Started

### 1. Prerequisites
- Node.js 16+
- npm or yarn
- PostgreSQL 12+
- Git
- Bash (for setup script)

### 2. Clone & Setup
```bash
git clone https://github.com/craigmcmeechan/less-to-tailwind-parser.git
cd less-to-tailwind-parser
bash setup-workspaces.sh
```

### 3. Choose Your Stage
```bash
cd .worktrees/stage-1      # Start with Database Foundation
# or any other stage
```

### 4. Read Documentation
```bash
cat ../../docs/stages/01_DATABASE_FOUNDATION.md
```

### 5. Install & Develop
```bash
npm install
npm run dev
```

---

## Command Reference

### Workspaces
```bash
git worktree list                   # List all workspaces
```

### Makefile
```bash
make help                           # Show all commands
make setup                          # Create workspaces
make enter-stage-1                  # Enter workspace
make install-all                    # Install all
make push-all                       # Push all
```

### Git
```bash
git status                          # Check changes
git add .                           # Stage files
git commit -m "message"             # Commit
git push origin branch-name         # Push
```

See **GIT_WORKSPACES_GUIDE.md** for complete command reference.

---

## Documentation Hierarchy

1. **README.md** (this file) - Overview
2. **QUICK_START.md** - Get up and running in 5 minutes
3. **GIT_WORKSPACES_GUIDE.md** - How to use workspaces
4. **docs/stages/0X_*.md** - Implementation details
5. **ARCHITECTURE_CORRECTIONS.md** - Why these corrections exist

---

## Support & Troubleshooting

### Common Issues

**Q: Workspaces not created?**
```bash
bash setup-workspaces.sh
```

**Q: Missing node_modules?**
```bash
cd .worktrees/stage-X
npm install
```

**Q: Can't find docs?**
```bash
cat ../../docs/stages/0X_*.md
```

See **GIT_WORKSPACES_GUIDE.md** Troubleshooting section for more.

---

## Key Files to Review

- **QUICK_START.md** - Start here (5 min read)
- **setup-workspaces.sh** - How workspaces are created
- **Makefile** - Convenient commands
- **docs/PROJECT_ROADMAP.md** - Complete timeline
- **ARCHITECTURE_CORRECTIONS.md** - Why things are designed this way

---

## Next Steps

1. ✅ Read **QUICK_START.md** (5 minutes)
2. ✅ Run `bash setup-workspaces.sh` (2 minutes)
3. ✅ Enter your first stage: `cd .worktrees/stage-1`
4. ✅ Read stage documentation: `cat ../../docs/stages/01_DATABASE_FOUNDATION.md`
5. ✅ Start developing: `npm install && npm run dev`

---

## Repository

**GitHub:** https://github.com/craigmcmeechan/less-to-tailwind-parser

---

## License

MIT (or your chosen license)

---

## Contributors

- Craig McMeechan - Initial architecture and design

---

**Last Updated:** October 29, 2025  
**Version:** 1.0 - Complete with Git Workspaces
