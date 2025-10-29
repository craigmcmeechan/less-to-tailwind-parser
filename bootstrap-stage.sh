#!/bin/bash
# Stage Bootstrap Script
# Initializes Claude Code for a new stage
# Usage: ./bootstrap-stage.sh [STAGE_NUMBER] [STAGE_NAME]
# Example: ./bootstrap-stage.sh 1 DATABASE_FOUNDATION

set -e

if [ $# -lt 2 ]; then
    echo "Usage: ./bootstrap-stage.sh [STAGE_NUMBER] [STAGE_NAME]"
    echo "Example: ./bootstrap-stage.sh 1 DATABASE_FOUNDATION"
    exit 1
fi

STAGE_NUM=$1
STAGE_NAME=$2
STAGE_FILE="docs/stages/${STAGE_NUM}_${STAGE_NAME}.md"
TODO_FILE="STAGE_${STAGE_NUM}_TODO.md"

echo "🚀 Claude Code Stage Bootstrap"
echo "════════════════════════════════════════════════"
echo "Stage: $STAGE_NUM - $STAGE_NAME"
echo ""

# Check if stage doc exists
if [ ! -f "$STAGE_FILE" ]; then
    echo "❌ Stage documentation not found: $STAGE_FILE"
    echo ""
    echo "Available stages:"
    ls -la docs/stages/*.md 2>/dev/null | awk '{print "  " $NF}' || echo "  (none found)"
    exit 1
fi

echo "📖 Reading stage documentation..."
echo ""
echo "════════════════════════════════════════════════"
cat "$STAGE_FILE"
echo ""
echo "════════════════════════════════════════════════"
echo ""

# Create TODO file if it doesn't exist
if [ ! -f "$TODO_FILE" ]; then
    echo "📝 Creating TODO file: $TODO_FILE"
    cat > "$TODO_FILE" << EOF
# STAGE $STAGE_NUM: $STAGE_NAME - TODO

## Overview

[Review docs/stages/${STAGE_NUM}_${STAGE_NAME}.md above for full context]

### What This Stage Accomplishes
[From stage documentation - summarize in 2-3 sentences]

### Key Deliverables
- [ ] [Deliverable 1]
- [ ] [Deliverable 2]
- [ ] [Deliverable 3]

## Acceptance Criteria

Before marking this stage complete, verify:
- [ ] All code follows CODE_STANDARDS.md
- [ ] All tests passing: \`npm test\`
- [ ] No linting issues: \`npm run lint\`
- [ ] Build succeeds: \`npm run build\`
- [ ] All commits follow STAGE-$STAGE_NUM-STEP: format
- [ ] Stage-specific criteria from docs met

## Sequential Steps

### Step 1: [First Logical Step]
Brief description of what this step accomplishes

Acceptance criteria for this step:
- [ ] Code implementation complete
- [ ] Unit tests written and passing
- [ ] npm run format && npm run build && npm test passing
- [ ] Commit: "STAGE-$STAGE_NUM-1: [Description]"
- [ ] ✅ COMPLETE

### Step 2: [Second Logical Step]
Brief description of what this step accomplishes

Acceptance criteria for this step:
- [ ] Code implementation complete
- [ ] Unit tests written and passing
- [ ] npm run format && npm run build && npm test passing
- [ ] Commit: "STAGE-$STAGE_NUM-2: [Description]"
- [ ] ✅ COMPLETE

[Add more steps as needed - break the stage into logical, testable pieces]

## Implementation Notes

### Commands You'll Use
\`\`\`bash
# Before each commit
npm run format
npm run build
npm test

# When committing
git add .
git commit -m "STAGE-$STAGE_NUM-[STEP]: [description]"

# When done with all steps
npm test                    # Full test suite
npm run lint              # Check linting
git checkout -b stage-${STAGE_NUM}-complete
git push origin stage-${STAGE_NUM}-complete
# Then create PR on GitHub
\`\`\`

### Reference Documentation
- Stage guide: docs/stages/${STAGE_NUM}_${STAGE_NAME}.md
- Code standards: docs/CODE_STANDARDS.md
- Testing guide: docs/TESTING_GUIDE.md
- Error handling: docs/ERROR_HANDLING.md
- Logging guide: docs/LOGGING_GUIDE.md
- Database operations: docs/DATABASE_OPERATIONS.md
- Architecture: docs/ARCHITECTURE.md

### Dependencies
- Previous stages that must be complete: [List them]
- Stages that depend on this: [List them]

## Final Checklist

When all steps are complete:
- [ ] All steps marked complete above
- [ ] All commits follow STAGE-$STAGE_NUM-STEP: format
- [ ] \`npm test\` passes completely
- [ ] \`npm run lint\` clean
- [ ] \`npm run build\` succeeds
- [ ] No outstanding TODOs in code
- [ ] Stage PR created
- [ ] Code reviewed and approved
- [ ] PR merged to main
- [ ] PROJECT_ROADMAP.md updated to mark stage ✅

## Notes

[Add any additional context, gotchas, or helpful tips]

---

**Remember:** One step at a time. Test after each step. Commit after each step. ✅
EOF
    echo "✅ TODO file created"
else
    echo "✅ TODO file already exists: $TODO_FILE"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "NEXT STEPS:"
echo ""
echo "1. Review: $TODO_FILE"
echo "2. Fill in the sequential steps (break stage into testable pieces)"
echo "3. For each step:"
echo "   a. Implement code"
echo "   b. Write tests"
echo "   c. npm run format && npm run build && npm test"
echo "   d. git commit -m 'STAGE-${STAGE_NUM}-[STEP]: description'"
echo "   e. Mark step complete in TODO"
echo ""
echo "Quick reference commands:"
echo "  npm run build     - Check TypeScript compilation"
echo "  npm test          - Run tests"
echo "  npm run lint      - Check code quality"
echo "  npm run format    - Auto-format code"
echo ""
echo "Reference docs:"
echo "  cat docs/CLAUDE_CODE_WORKFLOW.md  - Detailed workflow"
echo "  cat docs/CODE_STANDARDS.md        - Code style guide"
echo "  cat docs/ERROR_HANDLING.md        - Error patterns"
echo "  cat docs/LOGGING_GUIDE.md         - Logging patterns"
echo "  cat docs/TESTING_GUIDE.md         - Test patterns"
echo ""
echo "🎯 Ready to start Stage $STAGE_NUM!"
echo "════════════════════════════════════════════════"
