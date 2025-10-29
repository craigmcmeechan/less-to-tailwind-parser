# Claude Code Stage Initialization & Workflow

## Overview

This guide describes how Claude Code should systematically approach each stage of development. Rather than implementing an entire stage at once, Claude Code reads the stage documentation, breaks it into testable sequential steps, and implements them one at a time with testing and commits after each step.

---

## Phase 1: Documentation Review & Breakdown (Initial Setup)

When Claude Code starts for a new stage, it MUST execute this initialization sequence:

### Step 1: Read Stage Documentation
```bash
# Read the stage markdown file
cat docs/stages/[STAGE_NUMBER]_[STAGE_NAME].md
```

Claude Code reviews the entire stage documentation to understand:
- Acceptance criteria (what "done" means for this stage)
- All deliverables required
- Dependencies on previous stages  
- Database schema requirements
- External integrations needed
- Error handling scenarios

### Step 2: Parse & Extract Requirements

From the stage documentation, Claude Code identifies:

**What this stage accomplishes:**
- Primary objective in 1-2 sentences
- Key outputs/deliverables

**What needs to happen:**
- Database changes
- New services/modules
- API endpoints
- CLI commands
- Error handling paths

**What tests prove success:**
- Unit tests for individual functions
- Integration tests with previous stages
- End-to-end tests for the stage as a whole

### Step 3: Break Into Testable Sequential Steps

Claude Code creates a breakdown showing the logical sequence. Example:

```
STAGE [N]: [Name]
Primary Objective: [What this stage accomplishes]

SEQUENTIAL STEPS:
1. [Setup/Initialization] - Deploy X infrastructure
2. [Core Logic] - Implement Y feature  
3. [Integration] - Connect to Z system
4. [Error Handling] - Add resilience for A, B, C scenarios
5. [Testing] - Verify X, Y, Z work together
6. [Documentation] - Update README, API docs, inline comments

DEPENDENCIES:
- Requires: [List previous stages/modules]
- Blocks: [List stages/features that depend on this]

ACCEPTANCE CRITERIA:
- [ ] All tests pass (npm test)
- [ ] No TypeScript errors (npm run build)
- [ ] ESLint passes (npm run lint)
- [ ] [Stage-specific criterion 1]
- [ ] [Stage-specific criterion 2]
```

### Step 4: Create TODO File

Claude Code creates a `STAGE_[N]_TODO.md` file in the project root:

```markdown
# STAGE [N]: [Name] - TODO

## Overview
[Brief description from stage docs]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] All tests passing
- [ ] No linting issues
- [ ] Build succeeds

## Sequential Steps

### Step 1: [Description]
Implement basic setup/infrastructure
- [ ] Task A
- [ ] Task B
- [ ] Write tests for this step
- [ ] npm run format && npm run build && npm test
- [ ] Commit: "STAGE-N-1: [Description]"
- [ ] Mark complete

### Step 2: [Description]
Implement core feature
- [ ] Task A
- [ ] Task B
- [ ] Write tests for this step
- [ ] npm run format && npm run build && npm test
- [ ] Commit: "STAGE-N-2: [Description]"
- [ ] Mark complete

[Repeat for all sequential steps]

## Final Verification Checklist
- [ ] All steps completed and committed
- [ ] All tests passing: `npm test`
- [ ] No linting issues: `npm run lint`
- [ ] Build succeeds: `npm run build`
- [ ] Stage PR created and code reviewed
- [ ] Stage marked complete in PROJECT_ROADMAP.md

## Documentation References
- Stage documentation: docs/stages/[N]_[NAME].md
- Code standards: docs/CODE_STANDARDS.md
- Testing guide: docs/TESTING_GUIDE.md
- Error handling: docs/ERROR_HANDLING.md
- Logging guide: docs/LOGGING_GUIDE.md
- Database operations: docs/DATABASE_OPERATIONS.md
```

---

## Phase 2: Implementation Loop (For Each Sequential Step)

### The Per-Step Workflow

For each step in the TODO file, Claude Code repeats this exact cycle:

#### 1️⃣ Implement the Step

Write the code/tests needed to complete the step:
- Follow project conventions from CODE_STANDARDS.md
- Write tests alongside or before the code
- Add logging per LOGGING_GUIDE.md
- Handle errors per ERROR_HANDLING.md
- Reference DATABASE_OPERATIONS.md for DB interactions

#### 2️⃣ Run Tests

```bash
# Run tests for this specific stage (if applicable)
npm test -- stage-[N]

# Or run specific test file
npm test -- src/services/__tests__/newFeature.test.ts
```

Requirements:
- All tests must PASS
- New tests must verify the step works in isolation
- Coverage should be ≥80% for new code

#### 3️⃣ Check Linting

```bash
# Check code quality
npm run lint

# Auto-format
npm run format
```

Requirements:
- No ESLint errors or warnings
- Code is auto-formatted per project style
- TypeScript types are correct

#### 4️⃣ Build

```bash
# Verify TypeScript compilation
npm run build
```

Requirements:
- Build completes successfully
- No TypeScript errors
- No TypeScript warnings

#### 5️⃣ Commit

```bash
git add .
git commit -m "STAGE-[N]-[STEP]: [Description]"
```

Commit message format:
- Format: `STAGE-N-STEP: <description>`
- Example: `STAGE-2-1: Add recursive file discovery for LESS scanning`
- Keep commits focused on ONE step only
- Commits should be independently meaningful

#### 6️⃣ Update TODO

Update `STAGE_[N]_TODO.md` to mark this step as complete:
```markdown
### Step [N]: [Description]
- [x] Task A
- [x] Task B
- [x] Tests passing
- [x] Commit: "STAGE-[N]-[STEP]: [Description]"
- [x] **COMPLETE** ✅
```

---

## Phase 3: Stage Completion

After all sequential steps are implemented and committed:

### Full Test Suite

```bash
# Run everything
npm run build
npm test
npm run lint
```

Requirements:
- `npm test` passes completely
- `npm run lint` is clean
- `npm run build` succeeds
- Coverage meets project threshold (≥80%)

### Integration Verification

```bash
# Verify integration with previous stages
# (This varies by stage - see stage-specific guide)
```

### Create Stage PR

```bash
# Create a feature branch for the entire stage
git checkout -b stage-[N]-complete

# Push to GitHub
git push origin stage-[N]-complete

# Create Pull Request on GitHub with:
# - Title: "STAGE [N]: [Name]"
# - Description: Contents from STAGE_[N]_TODO.md
# - Reviewers: [Project lead]
```

### Mark Stage Complete

Update documentation:

1. **Update PROJECT_ROADMAP.md:**
   - Change stage status from 📝 to ✅
   - Add implementation notes if relevant

2. **Update docs/INDEX.md:**
   - Update stage status if listing

3. **Archive TODO:**
   ```bash
   # Keep for reference but move to completed section
   # Or delete if cleanup preferred
   ```

---

## Checklist: Before Marking Stage Done

Use this checklist before moving to the next stage:

- [ ] All sequential steps in STAGE_[N]_TODO.md are marked complete
- [ ] All commits follow `STAGE-N-STEP:` format
- [ ] `npm test` passes (full suite, ≥80% coverage)
- [ ] `npm run lint` passes (no errors)
- [ ] `npm run build` succeeds (TypeScript clean)
- [ ] Stage PR created and merged to main
- [ ] PROJECT_ROADMAP.md updated with ✅ status
- [ ] Stage documentation references are accurate
- [ ] All code follows CODE_STANDARDS.md
- [ ] Error handling per ERROR_HANDLING.md
- [ ] Logging per LOGGING_GUIDE.md
- [ ] Tests per TESTING_GUIDE.md
- [ ] Database work per DATABASE_OPERATIONS.md

---

## Quick Reference: Common Commands

```bash
# Format code before committing
npm run format

# Verify TypeScript compilation
npm run build

# Run all tests
npm test

# Run tests for a specific stage (if configured)
npm test -- stage-[N]

# Run tests for a specific file
npm test -- src/services/__tests__/myFeature.test.ts

# Check linting
npm run lint

# View what changed since last commit
git diff HEAD~1

# View last 5 commits
git log --oneline -5

# View changes in current branch
git diff main...HEAD

# View stage documentation
cat docs/stages/[N]_[NAME].md

# View generic guides
cat docs/CODE_STANDARDS.md
cat docs/ARCHITECTURE.md
cat docs/ERROR_HANDLING.md
cat docs/LOGGING_GUIDE.md
cat docs/TESTING_GUIDE.md
cat docs/DATABASE_OPERATIONS.md
```

---

## Guidelines for Success

### ✅ Do This

- **One step at a time** - Don't try to do multiple steps in one commit
- **Test-driven** - Write tests for each step before or alongside code
- **Atomic commits** - Each commit should be independently meaningful
- **Reference standards** - Check CODE_STANDARDS.md before writing code
- **Handle errors** - Review ERROR_HANDLING.md for patterns
- **Document code** - Add JSDoc comments to new functions
- **Track progress** - Keep TODO file updated as you go

### ❌ Don't Do This

- **Skip testing** - Every step must have tests
- **Combine steps** - Don't do 2 steps in one commit
- **Ignore standards** - All code must follow CODE_STANDARDS.md
- **Skip linting** - Always run `npm run format` before committing
- **Forget logging** - Add logging per LOGGING_GUIDE.md
- **Leave TODOs** - Complete each step before moving on
- **Hardcode values** - Extract to constants/config

---

## Example: Stage 2 Step 1 Implementation

For illustration, here's what implementing **STAGE-2-1** might look like:

```bash
# Start work on Stage 2, Step 1
# (After reading docs/stages/02_LESS_SCANNING.md and creating STAGE_2_TODO.md)

# Implement the file discovery service
# Write tests in src/services/__tests__/fileDiscoveryService.test.ts
# Add logging per LOGGING_GUIDE.md
# Handle errors per ERROR_HANDLING.md

# Format code
npm run format

# Run tests
npm test -- fileDiscoveryService

# Build
npm run build

# Run linting
npm run lint

# If all pass, commit
git add .
git commit -m "STAGE-2-1: Implement recursive file discovery for LESS scanning"

# Update STAGE_2_TODO.md to mark Step 1 complete
# ... continue to Step 2 ...
```

---

## Troubleshooting

### Tests fail after implementing step
1. Check test output for specific error
2. Review error handling patterns in ERROR_HANDLING.md
3. Add more specific tests
4. Debug with `npm run dev` for interactive debugging

### Build fails with TypeScript errors
1. Check error message - it will point to exact issue
2. Review CODE_STANDARDS.md for type patterns
3. Ensure all types are properly defined
4. Check interfaces in ARCHITECTURE.md

### Linting fails
1. Run `npm run format` to auto-fix
2. Check specific error in output
3. Review CODE_STANDARDS.md for naming conventions
4. Fix manually if auto-format doesn't work

### Can't commit because tests failing
1. Don't force commit - fix tests first
2. Use `git status` to see what changed
3. Review the failing test
4. Fix code and re-test
5. Only commit when all tests pass

---

## Integration with Claude Code Invocation

When invoking Claude Code for a stage, use this pattern:

```bash
claude code \
  --instructions="
Stage [N] Implementation Instructions:

1. Run: ./bootstrap-stage.sh [N] [STAGE_NAME]

2. Review STAGE_[N]_TODO.md

3. For EACH sequential step:
   a. Implement code
   b. npm test (verify passing)
   c. npm run format && npm run build && npm run lint
   d. git commit -m 'STAGE-[N]-STEP: description'
   e. Update TODO file

4. When complete:
   - npm test (full suite)
   - Create PR to main
   - Update PROJECT_ROADMAP.md

5. Reference:
   - docs/stages/[N]_[STAGE_NAME].md
   - docs/CODE_STANDARDS.md
   - docs/ERROR_HANDLING.md
   - docs/LOGGING_GUIDE.md
   - docs/TESTING_GUIDE.md
   - docs/DATABASE_OPERATIONS.md
" \
  less-to-tailwind-parser
```

---

## Document Version

- **Version:** 1.0
- **Last Updated:** October 29, 2025
- **Maintained By:** Project Team

---

**Happy coding! 🚀**
