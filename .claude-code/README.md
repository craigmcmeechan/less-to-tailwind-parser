# Claude Code Instructions

This directory contains instructions for using Claude Code to implement each stage of the LESS to Tailwind Parser project.

**What is Claude Code?**

Claude Code is a command-line tool that lets you delegate coding tasks to Claude. It can:
- Read project files and structure
- Generate code following your specifications
- Create tests and documentation
- Understand context from previous work

---

## Quick Start

### 1. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Or use with `npx`:
```bash
npx @anthropic-ai/claude-code
```

### 2. Set Your API Key

```bash
export ANTHROPIC_API_KEY=your-api-key-here
```

### 3. Run for a Stage

```bash
# From the stage workspace
cd .worktrees/stage-1

# Run Claude Code with stage instructions
claude-code --instruction-file ../../.claude-code/stage-1.md
```

---

## How to Use Claude Code with This Project

### Workflow

```
1. Enter stage workspace
   cd .worktrees/stage-1

2. Run Claude Code with instructions
   npx @anthropic-ai/claude-code --instruction-file ../../.claude-code/stage-1.md

3. Claude Code will:
   - Read the instruction file
   - Analyze your project structure
   - Generate/update implementation files
   - Create tests
   - Verify against acceptance criteria

4. Review generated code
   git status
   git diff

5. Test the implementation
   npm test

6. Commit your work
   git add .
   git commit -m "feat: stage implementation via Claude Code"
```

### Directory Structure

```
.claude-code/
├── README.md                      # This file
├── PATTERNS.md                    # Common code patterns
├── TEMPLATES.md                   # Code templates
├── stage-1.md                     # Stage 1 instructions
├── stage-2.md                     # Stage 2 instructions
├── ... (stages 3-9)
└── common-instructions.md         # Shared instructions for all stages
```

---

## Key Commands

### Run Claude Code for a Stage

```bash
cd .worktrees/stage-1
npx @anthropic-ai/claude-code --instruction-file ../../.claude-code/stage-1.md
```

### Run with Specific Focus

```bash
# Focus on implementation only
npx @anthropic-ai/claude-code \
  --instruction-file ../../.claude-code/stage-1.md \
  --focus implementation

# Focus on tests only
npx @anthropic-ai/claude-code \
  --instruction-file ../../.claude-code/stage-1.md \
  --focus tests

# Focus on documentation
npx @anthropic-ai/claude-code \
  --instruction-file ../../.claude-code/stage-1.md \
  --focus docs
```

### Interactive Mode

```bash
# Start interactive session
npx @anthropic-ai/claude-code --interactive

# Then enter stage context:
# "I'm working on Stage 1: Database Foundation"
# "Can you help me implement the database connection pool?"
```

---

## Stage Instructions Overview

Each stage has specific instructions that include:

1. **Objective** - What needs to be implemented
2. **Acceptance Criteria** - How to know it's done
3. **File Structure** - Where files should go
4. **Implementation Details** - Technical requirements
5. **Testing Requirements** - What needs testing
6. **Documentation** - What to document
7. **Validation Checklist** - Final verification

### Available Stages

- **Stage 1:** Database Foundation
- **Stage 2:** LESS File Scanning
- **Stage 3:** Import Hierarchy
- **Stage 4:** CSS Rule Extraction (CRITICAL)
- **Stage 5:** Variable Extraction
- **Stage 6:** Tailwind Export
- **Stage 7:** Integration & Testing
- **Stage 8:** Chrome Extension
- **Stage 9:** DOM Matching & Tailwind

---

## How Claude Code Works with Your Project

### Context Claude Code Will Have

```
1. Project structure (src/, tests/, docs/)
2. Existing code (shared services, base types)
3. Stage documentation
4. Architecture guidelines
5. Code standards
6. Test patterns
7. Git history (commits and branches)
```

### What Claude Code Will Generate

```
1. Implementation files (TypeScript)
2. Unit tests (Jest)
3. Integration tests (if needed)
4. Type definitions
5. Error handling
6. Logging
7. Documentation comments
8. README updates
```

### What Claude Code Will NOT Do

```
❌ Database migrations (you specify those)
❌ Environment setup (you set up PostgreSQL)
❌ Deploy to production
❌ Make decisions about architecture
❌ Modify unrelated code
```

---

## Best Practices

### ✅ DO

- **Provide context** - Tell Claude Code what you've already done
- **Be specific** - Detailed requirements = better code
- **Review changes** - Always review generated code before committing
- **Test thoroughly** - Run all tests before merging
- **Commit incrementally** - Commit after each Claude Code session
- **Provide feedback** - If something's wrong, tell Claude Code to fix it

### ❌ DON'T

- **Accept all changes blindly** - Review code first
- **Skip tests** - Always run `npm test`
- **Mix stages** - Run Claude Code for one stage at a time
- **Modify Claude Code instructions** - Use them as-is for consistency
- **Use Claude Code for multiple stages simultaneously** - Sequential is better

---

## Troubleshooting

### Issue: Claude Code can't find files

```bash
# Make sure you're in the right directory
cd .worktrees/stage-1

# Verify the instruction file exists
ls ../../.claude-code/stage-1.md
```

### Issue: Generated code has syntax errors

```bash
# Run TypeScript compiler to check
npm run type-check

# Fix the issues and tell Claude Code:
# "The generated code has TypeScript errors in [file]. Can you fix it?"
```

### Issue: Tests are failing

```bash
# Run tests to see what failed
npm test

# Share the error with Claude Code:
# "Test [test name] is failing with error: [error message]"
```

### Issue: Claude Code generated too much code

```bash
# Tell Claude Code to focus on specific areas:
# "Let's break this down. Can you implement just the database connection first?"

# Or start fresh with clearer requirements:
# "Let me provide more specific requirements for this stage..."
```

---

## Integration with Git Workspaces

### Typical Workflow

```bash
# 1. Enter stage workspace
cd .worktrees/stage-1

# 2. Check current status
git status

# 3. Run Claude Code
npx @anthropic-ai/claude-code --instruction-file ../../.claude-code/stage-1.md

# 4. Review changes
git diff

# 5. Test everything
npm test
npm run lint
npm run type-check

# 6. Commit
git add .
git commit -m "feat: stage 1 implementation

- Implemented database connection pool
- Added health check endpoint
- Added comprehensive tests
- Generated docs"

# 7. Push
git push origin feature/01-database-foundation

# 8. Create PR on GitHub
# (Link to docs/stages/01_DATABASE_FOUNDATION.md)
```

---

## Example: Running Claude Code for Stage 1

```bash
# 1. Setup
cd .worktrees/stage-1
npm install

# 2. Run Claude Code
npx @anthropic-ai/claude-code --instruction-file ../../.claude-code/stage-1.md

# 3. Claude Code outputs:
#    - src/services/databaseService.ts
#    - tests/unit/databaseService.test.ts
#    - Updated package.json with dependencies
#    - .env.example file

# 4. Review and test
git status
git diff src/services/databaseService.ts
npm test

# 5. Accept and commit
git add .
git commit -m "feat: implement database foundation"
```

---

## Documentation Files Used

Claude Code references these files to understand requirements:

```
📖 Reads:
- docs/stages/0X_*.md          (Stage requirements)
- docs/ARCHITECTURE.md          (System design)
- docs/CODE_STANDARDS.md        (Code guidelines)
- docs/TESTING_GUIDE.md         (Test patterns)
- docs/ERROR_HANDLING.md        (Error strategies)
- docs/LOGGING_GUIDE.md         (Logging patterns)
- docs/DATABASE_OPERATIONS.md   (Query patterns)

📝 Generates:
- src/services/...
- tests/unit/...
- tests/integration/...
- type definitions
- inline documentation
```

---

## Next Steps

1. ✅ Install Claude Code: `npm install -g @anthropic-ai/claude-code`
2. ✅ Set API key: `export ANTHROPIC_API_KEY=...`
3. ✅ Enter stage workspace: `cd .worktrees/stage-1`
4. ✅ Run stage instructions: `npx @anthropic-ai/claude-code --instruction-file ../../.claude-code/stage-1.md`
5. ✅ Review generated code and commit

---

## Support

See individual stage files for specific instructions:
- `.claude-code/stage-1.md`
- `.claude-code/stage-2.md`
- ... etc

For general patterns and templates, see:
- `.claude-code/PATTERNS.md`
- `.claude-code/TEMPLATES.md`

---

**Last Updated:** October 29, 2025
