# Getting Started with Claude Code

Quick onboarding guide for developers using Claude Code to work on the LESS to Tailwind Parser project.

---

## 🎯 Before You Start

Ensure you have:
- ✅ Cloned the repository: `git clone https://github.com/craigmcmeechan/less-to-tailwind-parser.git`
- ✅ Installed dependencies: `npm install`
- ✅ Setup database: Create PostgreSQL database `less_to_tailwind`
- ✅ Configured environment: Copy `.env.example` to `.env` and fill in your values
- ✅ Verified setup: `npm run build && npm test` should both pass

---

## 🚀 Quick Start (TL;DR)

```bash
# 1. Start any stage (example: Stage 1)
./bootstrap-stage.sh 1 DATABASE_FOUNDATION

# 2. This will:
#    - Read docs/stages/01_DATABASE_FOUNDATION.md
#    - Show you the full stage documentation
#    - Create STAGE_1_TODO.md

# 3. Review STAGE_1_TODO.md

# 4. Invoke Claude Code with stage-specific instructions:
#    See: docs/CLAUDE_CODE_INVOCATION.md → Stage 1 section

# 5. Claude Code will implement systematically:
#    - Implement step 1 → test → lint → commit
#    - Implement step 2 → test → lint → commit
#    - ... repeat for all steps

# 6. When complete:
#    - All tests pass
#    - Create PR to main
#    - Update PROJECT_ROADMAP.md with ✅
```

---

## 📖 The Three Core Documents

**You need to know about these three files:**

### 1. [CLAUDE_CODE_INVOCATION.md](./docs/CLAUDE_CODE_INVOCATION.md)
**What to copy/paste into Claude Code**

Shows the exact instructions for each stage (1-9). Copy the stage-specific invocation and paste into Claude Code.

Example:
```bash
claude code \
  --instructions="
[Copy the Stage 1 section from CLAUDE_CODE_INVOCATION.md]
" \
  less-to-tailwind-parser
```

### 2. [CLAUDE_CODE_WORKFLOW.md](./docs/CLAUDE_CODE_WORKFLOW.md)
**How Claude Code should work**

Describes the systematic approach:
1. Documentation review
2. Break into sequential steps
3. For each step: implement → test → lint → commit
4. Complete and verify

### 3. [bootstrap-stage.sh](./bootstrap-stage.sh)
**Quick script to initialize any stage**

Automatically reads stage docs and creates TODO file.

```bash
./bootstrap-stage.sh [STAGE_NUMBER] [STAGE_NAME]
```

---

## 🔄 The Workflow in 5 Steps

### Step 1: Bootstrap the Stage
```bash
./bootstrap-stage.sh 1 DATABASE_FOUNDATION
```

Claude Code reads the documentation and creates a TODO file.

### Step 2: Review the TODO
```bash
cat STAGE_1_TODO.md
```

Understand what needs to be done and how it's broken into steps.

### Step 3: Invoke Claude Code
```bash
claude code \
  --instructions="
[Content from docs/CLAUDE_CODE_INVOCATION.md - Stage 1 section]
" \
  less-to-tailwind-parser
```

### Step 4: Claude Code Implements Systematically
- Reads stage docs ✅
- Implements Step 1: code → test → lint → commit
- Implements Step 2: code → test → lint → commit
- ... repeats for all steps
- Marks each complete in TODO file

### Step 5: Verify & Merge
```bash
# Verify
npm test      # All tests pass
npm run lint  # Clean code
npm run build # No errors

# Create PR
git checkout -b stage-[N]-complete
git push origin stage-[N]-complete

# Create PR on GitHub and merge to main
```

---

## 📋 Key Commands You'll Use

```bash
# Start a stage
./bootstrap-stage.sh [N] [STAGE_NAME]

# Check what's in the TODO
cat STAGE_[N]_TODO.md

# View stage documentation
cat docs/stages/[N]_[NAME].md

# View workflow guide
cat docs/CLAUDE_CODE_WORKFLOW.md

# View invocation instructions
cat docs/CLAUDE_CODE_INVOCATION.md

# Check git history (see what was completed)
git log --oneline | grep "STAGE-"

# View any generic guide
cat docs/CODE_STANDARDS.md       # Code style
cat docs/TESTING_GUIDE.md        # How to test
cat docs/ERROR_HANDLING.md       # Error patterns
cat docs/LOGGING_GUIDE.md        # Logging
cat docs/DATABASE_OPERATIONS.md  # DB patterns
```

---

## 🎓 Understanding the Stages

The project has 9 stages broken into 2 parts:

### Part 1: LESS Extraction (Stages 1-7)
- **Stage 1:** Database setup
- **Stage 2:** Scan LESS files
- **Stage 3:** Parse import hierarchy
- **Stage 4:** Extract CSS rules ⚠️ CRITICAL STAGE
- **Stage 5:** Extract variables
- **Stage 6:** Generate Tailwind config
- **Stage 7:** Full integration & testing

### Part 2: DOM Matching (Stages 8-9)
- **Stage 8:** Chrome extension for DOM capture
- **Stage 9:** Smart matching engine

**Important:** Stages must be completed in order (dependencies shown in PROJECT_ROADMAP.md).

---

## 💡 Pro Tips

### For Getting Started
1. **Read the stage docs first** - Understand what needs to be built before invoking Claude Code
2. **Start with Stage 1** - Database foundation is simplest and has no dependencies
3. **Keep terminal open** - Monitor Claude Code's progress

### For Efficiency
1. **One stage at a time** - Don't start Stage 2 until Stage 1 is done and merged
2. **Review TODOs** - The STAGE_N_TODO.md file is your progress tracker
3. **Check git history** - `git log --oneline | grep STAGE-` shows what was completed

### For Debugging
1. **Tests failing?** - Run `npm test` to see what broke
2. **Build errors?** - Run `npm run build` to see TypeScript issues
3. **Linting errors?** - Run `npm run lint` to check code quality
4. **Confused about patterns?** - Check the relevant generic guide (see table below)

### For Troubleshooting
| Issue | Check |
|-------|-------|
| "What should I code?" | Stage docs + CLAUDE_CODE_WORKFLOW.md |
| "How should I test?" | TESTING_GUIDE.md |
| "How should I handle errors?" | ERROR_HANDLING.md |
| "How should I add logging?" | LOGGING_GUIDE.md |
| "Database operations?" | DATABASE_OPERATIONS.md |
| "Code style?" | CODE_STANDARDS.md |

---

## 🔍 Documentation Hierarchy

```
PROJECT_ROADMAP.md ← Start here for overview
    ↓
[Pick your stage]
    ↓
CLAUDE_CODE_INVOCATION.md ← Find your stage's invocation
    ↓
./bootstrap-stage.sh [N] [NAME] ← Initialize
    ↓
STAGE_[N]_TODO.md ← Track progress
    ↓
CLAUDE_CODE_WORKFLOW.md ← Understand the approach
    ↓
[Reference guides as needed during implementation]
    ├── CODE_STANDARDS.md
    ├── TESTING_GUIDE.md
    ├── ERROR_HANDLING.md
    ├── LOGGING_GUIDE.md
    └── DATABASE_OPERATIONS.md
```

---

## 🎯 Example: Starting Stage 1

Here's exactly what you'd do to start Stage 1:

```bash
# 1. Bootstrap Stage 1
./bootstrap-stage.sh 1 DATABASE_FOUNDATION

# This outputs:
# - Full stage documentation (read carefully!)
# - Creates STAGE_1_TODO.md
# - Shows next steps

# 2. Review the TODO
cat STAGE_1_TODO.md

# You see sequential steps like:
# - Step 1: PostgreSQL connection setup
# - Step 2: Schema creation
# - Step 3: Error handling
# - etc.

# 3. Open docs/CLAUDE_CODE_INVOCATION.md
# Find the "Stage 1: Database Foundation" section

# 4. Copy that entire section and invoke Claude Code:
claude code \
  --instructions="
STAGE 1: DATABASE FOUNDATION

1. ./bootstrap-stage.sh 1 DATABASE_FOUNDATION
... [rest of the Stage 1 section from CLAUDE_CODE_INVOCATION.md]
" \
  less-to-tailwind-parser

# 5. Claude Code then:
# - Reads the stage docs (which were already printed)
# - Breaks into sequential steps
# - Implements Step 1: code → test → lint → commit (STAGE-1-1)
# - Implements Step 2: code → test → lint → commit (STAGE-1-2)
# - ... continues for all steps
# - Updates STAGE_1_TODO.md as it goes

# 6. Monitor progress by checking STAGE_1_TODO.md
cat STAGE_1_TODO.md

# 7. When done, verify:
npm test
npm run lint
npm run build

# 8. Create PR and merge to main
```

---

## ❓ FAQ

**Q: How long does each stage take?**  
A: Depends on complexity. Stage 1 is ~1 week. Check PROJECT_ROADMAP.md for estimates.

**Q: Can I do multiple stages in parallel?**  
A: No - stages have dependencies. Start with Stage 1, complete it, then Stage 2, etc.

**Q: What if a test fails?**  
A: Claude Code should handle it, but if stuck, check docs/TESTING_GUIDE.md for patterns.

**Q: How do I know if Claude Code completed the stage?**  
A: Check STAGE_[N]_TODO.md - all steps should be marked complete, all tests passing.

**Q: Where do I find code style rules?**  
A: docs/CODE_STANDARDS.md - tells you TypeScript conventions, naming, etc.

**Q: What if I hit the context window limit?**  
A: Shouldn't happen with the systematic approach, but if it does, see CLAUDE_CODE_WORKFLOW.md for guidance.

**Q: How do I see what was completed?**  
A: Run `git log --oneline | grep "STAGE-"` - shows all commits in order.

**Q: Can I commit my own changes?**  
A: Yes, after Claude Code finishes a stage, review, merge to main, then move to next stage.

---

## 🚀 Next Steps

1. **Read:** [PROJECT_ROADMAP.md](./docs/PROJECT_ROADMAP.md) - Understand the full project
2. **Bootstrap:** `./bootstrap-stage.sh 1 DATABASE_FOUNDATION`
3. **Invoke:** Copy Stage 1 section from [CLAUDE_CODE_INVOCATION.md](./docs/CLAUDE_CODE_INVOCATION.md)
4. **Monitor:** Watch Claude Code implement systematically
5. **Verify:** `npm test && npm run lint && npm run build`
6. **Merge:** Create PR to main and merge

---

## 📚 Full Documentation

- [PROJECT_ROADMAP.md](./docs/PROJECT_ROADMAP.md) - Full timeline and architecture
- [CLAUDE_CODE_WORKFLOW.md](./docs/CLAUDE_CODE_WORKFLOW.md) - Detailed workflow
- [CLAUDE_CODE_INVOCATION.md](./docs/CLAUDE_CODE_INVOCATION.md) - Stage-specific commands
- [INDEX.md](./docs/INDEX.md) - Complete documentation index
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - System design
- [CODE_STANDARDS.md](./docs/CODE_STANDARDS.md) - Code style guide
- [TESTING_GUIDE.md](./docs/TESTING_GUIDE.md) - Testing patterns
- [ERROR_HANDLING.md](./docs/ERROR_HANDLING.md) - Error patterns
- [LOGGING_GUIDE.md](./docs/LOGGING_GUIDE.md) - Logging patterns
- [DATABASE_OPERATIONS.md](./docs/DATABASE_OPERATIONS.md) - Database patterns

---

## 🎓 Learn More

- External: [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- External: [Jest Testing](https://jestjs.io/docs/getting-started)
- External: [PostgreSQL Docs](https://www.postgresql.org/docs/)
- External: [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)

---

**Ready to build? 🚀**

Start with: `./bootstrap-stage.sh 1 DATABASE_FOUNDATION`

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
