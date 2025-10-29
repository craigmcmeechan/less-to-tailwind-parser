# Claude Code Integration & Invocation Guide

## Overview

This guide explains how to invoke Claude Code for development work on the LESS to Tailwind Parser project. Claude Code will follow the systematic stage-based workflow defined in [CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md).

---

## Quick Start

### For Any Stage

```bash
claude code \
  --instructions="
STAGE [N] INITIALIZATION

1. Run: ./bootstrap-stage.sh [N] [STAGE_NAME]
   This reads the stage docs and creates STAGE_[N]_TODO.md

2. Review STAGE_[N]_TODO.md carefully

3. Fill in the sequential steps (break stage into testable pieces)

4. For EACH sequential step:
   a. Implement code
   b. Write tests (alongside or before code)
   c. npm run format && npm run build && npm test
   d. git commit -m 'STAGE-[N]-[STEP]: description'
   e. Update STAGE_[N]_TODO.md to mark step complete
   f. Move to next step

5. When all steps complete:
   - npm test (full suite)
   - npm run lint (clean code)
   - npm run build (no errors)
   - Create PR to main
   - Update docs/PROJECT_ROADMAP.md with ✅ status

6. Always reference:
   - docs/stages/[N]_[STAGE_NAME].md (stage requirements)
   - docs/CODE_STANDARDS.md (code style)
   - docs/CLAUDE_CODE_WORKFLOW.md (detailed workflow)
   - docs/ERROR_HANDLING.md (error patterns)
   - docs/LOGGING_GUIDE.md (logging patterns)
   - docs/TESTING_GUIDE.md (test patterns)
   - docs/DATABASE_OPERATIONS.md (DB patterns)
" \
  less-to-tailwind-parser
```

---

## Stage-Specific Invocations

### Stage 1: Database Foundation

```bash
claude code \
  --instructions="
STAGE 1: DATABASE FOUNDATION

1. ./bootstrap-stage.sh 1 DATABASE_FOUNDATION

2. Review STAGE_1_TODO.md and docs/stages/01_DATABASE_FOUNDATION.md

3. Break into sequential steps like:
   - Step 1: PostgreSQL connection setup
   - Step 2: Schema creation and migrations
   - Step 3: Error handling patterns
   - Step 4: Logging integration
   - Step 5: Connection pooling

4. For each step: Implement → Test → Lint → Commit

5. Each commit should be: STAGE-1-[STEP]: [description]

6. Reference:
   - docs/DATABASE_OPERATIONS.md (connection patterns)
   - docs/ERROR_HANDLING.md (error strategies)
   - docs/LOGGING_GUIDE.md (logger setup)
   - docs/CODE_STANDARDS.md (TypeScript patterns)
" \
  less-to-tailwind-parser
```

### Stage 2: LESS File Scanning

```bash
claude code \
  --instructions="
STAGE 2: LESS FILE SCANNING

Prerequisites: Stage 1 (DATABASE FOUNDATION) must be complete ✅

1. ./bootstrap-stage.sh 2 LESS_SCANNING

2. Review STAGE_2_TODO.md and docs/stages/02_LESS_SCANNING.md

3. Break into sequential steps like:
   - Step 1: File discovery from multiple paths
   - Step 2: SHA256 file versioning
   - Step 3: Diff tracking
   - Step 4: Database storage
   - Step 5: Optional file watcher
   - Step 6: Error handling

4. For each step: Implement → Test → Lint → Commit (STAGE-2-STEP)

5. Verify integration with Stage 1:
   - Can read from database
   - Can write scanned_files table
   - Can write file_versions table

6. Reference:
   - docs/DATABASE_OPERATIONS.md (query patterns)
   - docs/LOGGING_GUIDE.md (logging)
   - docs/ERROR_HANDLING.md (error recovery)
" \
  less-to-tailwind-parser
```

### Stage 3: Import Hierarchy Resolution

```bash
claude code \
  --instructions="
STAGE 3: IMPORT HIERARCHY RESOLUTION

Prerequisites: Stage 1-2 complete ✅

1. ./bootstrap-stage.sh 3 IMPORT_HIERARCHY

2. Review STAGE_3_TODO.md and docs/stages/03_IMPORT_HIERARCHY.md

3. Break into steps:
   - Step 1: @import statement parsing
   - Step 2: Import path resolution
   - Step 3: Build parent-child relationships
   - Step 4: Create scope hierarchy
   - Step 5: Detect circular imports
   - Step 6: Database schema and storage

4. For each step: Implement → Test → Lint → Commit

5. Remember: Import hierarchy is needed by Stage 5 (variables)
   Make sure scope chain is queryable

6. Reference:
   - docs/stages/03_IMPORT_HIERARCHY.md (full spec)
   - docs/DATABASE_OPERATIONS.md (queries)
   - docs/TESTING_GUIDE.md (circular import tests)
" \
  less-to-tailwind-parser
```

### Stage 4: CSS Rule Extraction

```bash
claude code \
  --instructions="
STAGE 4: CSS RULE EXTRACTION

Prerequisites: Stage 1-3 complete ✅

⚠️ CRITICAL STAGE: This is the bridge between LESS source and matching engine

1. ./bootstrap-stage.sh 4 RULE_EXTRACTION

2. Read docs/stages/04_RULE_EXTRACTION.md (understand Stage 4 criticality)

3. Break into steps:
   - Step 1: LESS to AST parsing
   - Step 2: Nesting expansion (.parent { .child {} } → .parent .child)
   - Step 3: Variable resolution (use Stage 3 scope hierarchy)
   - Step 4: CSS specificity calculation
   - Step 5: Rule ordering for cascade
   - Step 6: Media query handling
   - Step 7: Database schema and storage

4. Stage 4 output MUST be queryable by Stage 9:
   - Selectors indexed
   - Properties easily filtered
   - Rule order preserved

5. Reference:
   - docs/stages/04_RULE_EXTRACTION.md (full spec)
   - docs/ARCHITECTURE.md (data flow)
" \
  less-to-tailwind-parser
```

### Stage 5: Variable & Mixin Extraction

```bash
claude code \
  --instructions="
STAGE 5: VARIABLE & MIXIN EXTRACTION

Prerequisites: Stage 1-4 complete ✅

1. ./bootstrap-stage.sh 5 VARIABLE_EXTRACTION

2. Break into steps:
   - Step 1: Extract @variable declarations
   - Step 2: Extract @mixin definitions
   - Step 3: Extract @function definitions
   - Step 4: Classify for Tailwind mapping
   - Step 5: Database storage

3. This stage FEEDS into Stage 6 (Tailwind export)
   Make sure extracted variables are easily queryable

4. Reference docs/stages/04_VARIABLE_EXTRACTION.md
" \
  less-to-tailwind-parser
```

### Stage 6: Tailwind Export & Configuration

```bash
claude code \
  --instructions="
STAGE 6: TAILWIND EXPORT & CONFIGURATION

Prerequisites: Stage 1-5 complete ✅

1. ./bootstrap-stage.sh 6 TAILWIND_EXPORT

2. Break into steps:
   - Step 1: Load extracted variables from DB
   - Step 2: Map to Tailwind config format
   - Step 3: Generate tailwind.config.js
   - Step 4: Validate configuration
   - Step 5: CLI integration

3. Output must be a valid tailwind.config.js file

4. Reference docs/stages/05_TAILWIND_EXPORT.md
" \
  less-to-tailwind-parser
```

### Stage 7: Integration & Testing

```bash
claude code \
  --instructions="
STAGE 7: INTEGRATION & TESTING

Prerequisites: Stage 1-6 complete ✅

1. ./bootstrap-stage.sh 7 INTEGRATION

2. Break into steps:
   - Step 1: CLI orchestration
   - Step 2: Full pipeline testing (Stages 1-6 together)
   - Step 3: Error recovery
   - Step 4: Performance testing
   - Step 5: Documentation

3. This stage ties everything together
   Make sure all stages integrate cleanly

4. Reference docs/stages/06_INTEGRATION.md
" \
  less-to-tailwind-parser
```

### Stage 8: Chrome Extension

```bash
claude code \
  --instructions="
STAGE 8: CHROME EXTENSION

Prerequisites: Stage 1-7 complete ✅

1. ./bootstrap-stage.sh 8 CHROME_EXTENSION

2. Break into steps:
   - Step 1: Extension manifest and setup
   - Step 2: DOM capture (optimized)
   - Step 3: Relevant property filtering
   - Step 4: Backend communication
   - Step 5: UI and UX

3. Key: Query Stage 4 output to get relevant properties
   This reduces payload by 90%

4. Reference:
   - docs/stages/08_CHROME_EXTENSION.md
   - docs/ARCHITECTURE.md (Part 2 section)
" \
  less-to-tailwind-parser
```

### Stage 9: DOM to Tailwind Matching

```bash
claude code \
  --instructions="
STAGE 9: DOM TO TAILWIND MATCHING

Prerequisites: Stage 1-8 complete ✅

1. ./bootstrap-stage.sh 9 DOM_TO_TAILWIND

2. This is the intelligent matching engine
   Break into steps:
   - Step 1: Real CSS selector matching (not naive class checking)
   - Step 2: CSS cascade resolution (specificity + order)
   - Step 3: Media query context
   - Step 4: Confidence scoring
   - Step 5: Tailwind class mapping
   - Step 6: Audit trail (explain why matched)

3. Key: Query Stage 4 (less_rules) with captured DOM
   Stage 4 provides indexed, compiled CSS rules

4. Reference:
   - docs/stages/09_DOM_TO_TAILWIND.md
   - docs/ARCHITECTURE.md (matching algorithm)
" \
  less-to-tailwind-parser
```

---

## Important Guidelines

### ✅ Do This

- **Read stage docs first** - Understand what needs to be done
- **Break into steps** - Don't try to do entire stage at once
- **Test each step** - Write tests alongside implementation
- **Commit after each step** - Keep commits atomic with `STAGE-N-STEP:` format
- **Reference standards** - Check CODE_STANDARDS.md before writing
- **Check dependencies** - Verify you have required previous stages
- **Update TODO** - Mark steps complete as you go

### ❌ Don't Do This

- **Skip the bootstrap** - Always run `./bootstrap-stage.sh` first
- **Skip the docs** - Always read stage documentation
- **Combine steps** - Don't do multiple steps in one commit
- **Ignore tests** - Every step needs tests
- **Forget linting** - Always `npm run format` before commit
- **Skip error handling** - Check ERROR_HANDLING.md
- **Forget logging** - Check LOGGING_GUIDE.md

---

## Before Invoking Claude Code

Ensure:
1. ✅ You've read the stage documentation
2. ✅ Previous stages are marked complete in PROJECT_ROADMAP.md
3. ✅ You understand the dependencies
4. ✅ You've reviewed CLAUDE_CODE_WORKFLOW.md
5. ✅ Git is clean (no uncommitted changes)

---

## After Claude Code Completes

1. **Verify all tests pass:**
   ```bash
   npm test
   npm run lint
   npm run build
   ```

2. **Check commits:**
   ```bash
   git log --oneline | grep "STAGE-"
   ```

3. **Update roadmap:**
   Edit `docs/PROJECT_ROADMAP.md` - mark stage as ✅

4. **Create PR:**
   ```bash
   git checkout -b stage-N-complete
   git push origin stage-N-complete
   ```

5. **Review and merge** to main

---

## Common Patterns

### Starting a Fresh Stage
```bash
# 1. Make sure git is clean
git status

# 2. Bootstrap the stage
./bootstrap-stage.sh [N] [NAME]

# 3. Edit STAGE_[N]_TODO.md with sequential steps

# 4. Invoke Claude Code with stage-specific instructions above
```

### Checking Progress
```bash
# See what stage completed last
git log --oneline | head -1

# See all stage commits
git log --oneline | grep "STAGE-"

# Check which stages are complete
grep "✅ STAGE" docs/PROJECT_ROADMAP.md
```

### Debugging Issues
```bash
# Run tests for a specific stage
npm test -- stage-[N]

# Check for TypeScript errors
npm run build

# Check code quality
npm run lint

# View the stage documentation
cat docs/stages/[N]_[NAME].md
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Start a stage | `./bootstrap-stage.sh [N] [NAME]` |
| Run tests | `npm test` |
| Format code | `npm run format` |
| Build | `npm run build` |
| Check linting | `npm run lint` |
| View stage docs | `cat docs/stages/[N]_[NAME].md` |
| View workflow | `cat docs/CLAUDE_CODE_WORKFLOW.md` |

---

## Getting Help

1. **Understanding what to do?** → Read the stage documentation
2. **How to code it?** → Check CODE_STANDARDS.md
3. **How to test it?** → Check TESTING_GUIDE.md
4. **How to handle errors?** → Check ERROR_HANDLING.md
5. **How to log it?** → Check LOGGING_GUIDE.md
6. **Database operations?** → Check DATABASE_OPERATIONS.md
7. **Need the workflow?** → Check CLAUDE_CODE_WORKFLOW.md

---

## Document Version

- **Version:** 1.0
- **Last Updated:** October 29, 2025

---

**Ready to build! 🚀**
