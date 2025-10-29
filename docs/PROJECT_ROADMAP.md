# PROJECT ROADMAP: LESS to Tailwind Parser (Corrected)

## 🚀 Claude Code Integration (NEW!)

**Want to use Claude Code for development?** See:
- [CLAUDE_CODE_INVOCATION.md](./CLAUDE_CODE_INVOCATION.md) - How to invoke Claude Code for each stage
- [CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md) - The systematic development workflow
- **Bootstrap script:** `./bootstrap-stage.sh [STAGE_NUMBER] [STAGE_NAME]`

Claude Code will systematically:
1. Read stage documentation
2. Break it into testable sequential steps
3. Implement → Test → Lint → Commit (one step at a time)
4. Create a STAGE_N_TODO.md to track progress

---

## Executive Summary

**Two-Part System: LESS Extraction → DOM Matching**

**Part 1 - LESS CSS Extraction (Weeks 1-7):** Scan LESS files, parse structure, extract CSS rules with fully resolved variables, export Tailwind configuration.

**Part 2 - Chrome Extension + Matching (Weeks 8-9):** Extension captures DOM elements → backend matches to compiled LESS rules → generates Tailwind suggestions.

**Total Timeline:** 9-10 weeks (with corrections applied)

---

## Critical Correction

**Stage 4 (CSS Rule Extraction) is NOT optional.** It's the critical bridge between LESS source and matching engine. Without it, Stage 9 (backend matching) has no rules to match against.

---

## PART 1: LESS Extraction & Compilation

| Stage | Name | Duration | Key Output |
|-------|------|----------|-----------|
| 1 | Database Foundation | 1 week | PostgreSQL schemas, logging, error handling |
| 2 | LESS File Scanning | 1.5 weeks | `scanned_files`, `file_versions`, `file_diffs` tables |
| 3 | Import Hierarchy | 1.5 weeks | `import_dependencies`, `import_scope_hierarchy` tables |
| **4** | **CSS Rule Extraction** | **2 weeks** | **`less_rules` table with compiled, indexed selectors** |
| 5 | Variable Extraction | 1.5 weeks | `variables`, `mixins`, `functions` tables |
| 6 | Tailwind Export | 1.5 weeks | `tailwind.config.js` generation |
| 7 | Integration & Testing | 1 week | Full pipeline, CLI, testing infrastructure |

**Part 1 Complete:** End of Week 7

### Stage 4 Criticality

Without Stage 4, the backend matching engine (Stage 9) has nothing to query:

```
WRONG (current):
LESS files → database → Part 2 tries to match

CORRECT (after correction):
LESS files → Stage 4 compiles to CSS → database with indexed rules → Part 2 matches
```

Stage 4 handles:
- LESS nesting expansion (`.parent { .child { ... } }` → `.parent .child`)
- Variable resolution (@primary-color → #FF0000)
- CSS specificity calculation (critical for cascade)
- Rule ordering (for determining winner when multiple rules match)
- Media query context

---

## PART 2: DOM Capture + Intelligent Matching

| Stage | Name | Duration | Key Output |
|-------|------|----------|-----------|
| 8 | Chrome Extension (Enhanced) | 1 week | Optimized DOM capture with relevant properties |
| 9 | Backend Matching (Rewritten) | 1.5 weeks | Real CSS selector matching, specificity handling |

**Part 2 Complete:** End of Week 9

---

## Part 1 Detailed Timeline

### Week 1: Stage 1 (Database Foundation)
- PostgreSQL setup
- Base schema & migrations
- Logger utility
- Error handling patterns
- **Output:** Development database ready

### Week 2-2.5: Stage 2 (LESS File Scanning)
- Recursive directory walking
- File versioning with SHA256 checksums
- Unified diff generation
- **Output:** `scanned_files`, `file_versions`, `file_diffs` populated

### Week 3-4: Stage 3 (Import Hierarchy)
- Extract @import statements
- Resolve relative paths
- Detect circular imports
- Build dependency graph
- Create variable scope hierarchy
- **Output:** `import_dependencies`, `import_scope_hierarchy` ready for Stage 4

### **Week 5-6: Stage 4 (CSS Rule Extraction) ⭐ CRITICAL**
- Parse LESS to AST
- Expand nesting into flat selectors
- Resolve variables using Part 1 scope chain
- Calculate CSS specificity
- Track rule order
- Store media queries
- **Output:** `less_rules` table fully indexed and queryable
- **Unblocks:** Stage 9 backend matching

### Week 7-8: Stage 5 (Variable Extraction)
- Extract @variable declarations
- Extract @mixin definitions
- Extract @function definitions
- Classify for Tailwind
- **Output:** `variables`, `mixins`, `functions` tables

### Week 8.5-9: Stage 6 (Tailwind Export)
- Map extracted variables to Tailwind config
- Generate `tailwind.config.js`
- Generate CSS utilities
- Validation
- **Output:** Production `tailwind.config.js`

### Week 9.5-10: Stage 7 (Integration & Testing)
- CLI tool (less-parser command)
- Full pipeline orchestration
- Scheduled scanning
- API server
- Comprehensive testing (>80% coverage)
- **Output:** Production-ready CLI + API

---

## Part 2 Detailed Timeline

### Week 10-11: Stage 8 (Chrome Extension - Enhanced)

**Key Improvements from Correction:**
1. Query backend for relevant properties (from Stage 4 output)
2. Capture only properties that appear in `less_rules`
3. Add responsive context (viewport/breakpoint hints)
4. Compact payloads (90% size reduction)
5. Better error handling for offline scenarios

**Output:** Chrome extension ready for installation

### Week 11-12: Stage 9 (Backend Matching - Rewritten)

**Key Improvements from Correction:**
1. Real CSS selector matching (not just class checking)
   - Descendant selectors (`.parent .child`)
   - Attribute selectors (`[data-id="123"]`)
   - Pseudo-classes (`:hover`, `:focus`)
   - Complex combinators (`>`, `+`, `~`)

2. CSS specificity + cascade resolution
   - Calculate (IDs, classes, elements) per rule
   - Handle multiple matching rules
   - Use rule order as tiebreaker

3. Media query filtering
   - Only match rules for captured viewport
   - Support responsive design

4. Weighted confidence scoring
   - Different properties have different importance
   - `color` mismatch is critical
   - `margin` mismatch is okay

5. Audit trail
   - Store which properties matched
   - Explain confidence scores
   - Trace back to source LESS rule

**Output:** Production backend API returning high-confidence Tailwind suggestions

---

## Architectural Corrections Applied

### ✅ Corrected Issues

1. **Stage 4 now fully specified** (was missing critical details)
   - LESS nesting expansion algorithm
   - Variable resolution using Part 1 scope
   - CSS specificity calculation
   - Rule ordering for cascade

2. **Stage 8 (Extension) optimized**
   - Query relevant properties from Part 1
   - 90% payload reduction
   - Responsive context support

3. **Stage 9 (Backend) rewritten**
   - Real CSS selector matching (not naive class checking)
   - CSS specificity + cascade handling
   - Media query filtering
   - Proper confidence scoring

4. **Data flow clarified**
   - Variables resolved in Part 1 (Stage 5), stored in `variables` table
   - Stage 4 uses Part 1 scope hierarchy to resolve @variables in rules
   - Stage 4 output (`less_rules`) is queryable by Stage 9 backend
   - Stage 8 extension queries Part 1 for relevant properties

---

## Implementation Dependencies

```
Stage 1 (Database)
  ↓
Stage 2 (File Scanning)
  ↓
Stage 3 (Imports) ──────→ Used by Stage 5 (scope chain)
  ↓                         ↓
Stage 4 (Rules) ←────── Stage 5 (Variables resolve here)
  ↓
Stage 6 (Tailwind export)
  ↓
Stage 7 (Integration & Testing)
  ↓
Stage 8 (Extension) ← queries Stage 4 output
  ↓
Stage 9 (Matching) ← reads Stage 4 rules + Stage 8 DOM
```

---

## Success Metrics

### Part 1 Success
- ✅ Parse 1000+ LESS files without error
- ✅ Correctly expand nesting (verify selectors in `less_rules`)
- ✅ Resolve all variables (no @var references in properties)
- ✅ Calculate specificity correctly
- ✅ Generate valid `tailwind.config.js`
- ✅ CLI tool works: `less-parser scan production`

### Part 2 Success  
- ✅ Extension captures DOM without crashing
- ✅ Payload under 1MB (from optimizations)
- ✅ Backend matches element to LESS rules
- ✅ Confidence scores reasonable (0.6-1.0 range)
- ✅ Can identify winning rule via cascade logic
- ✅ Map matched properties to Tailwind classes
- ✅ API response includes audit trail (why it matched)

---

## Risk Mitigation

### Part 1 Risks
- **LESS nesting complexity:** Mitigate with comprehensive tests covering 10+ nesting levels
- **Variable resolution cycles:** Detect circular references, limit to 10 iterations
- **Performance on large files:** Test with 50K+ line LESS files; optimize indexes

### Part 2 Risks
- **CSS selector complexity:** Mitigate with selector parser library (don't reinvent)
- **Pseudo-classes not captured:** Document limitation; allow user re-capture at different states
- **Cascade ordering bugs:** Store rule order, write exhaustive cascade tests

---

## Repository Structure

```
less-to-tailwind-parser/
├── bootstrap-stage.sh              ← Use to start any stage
├── docs/
│   ├── PROJECT_ROADMAP.md         (this file)
│   ├── ARCHITECTURE.md
│   ├── CODE_STANDARDS.md
│   ├── CLAUDE_CODE_WORKFLOW.md    ← NEW: Systematic workflow
│   ├── CLAUDE_CODE_INVOCATION.md  ← NEW: How to invoke
│   ├── stages/
│   │   ├── 01_DATABASE_FOUNDATION.md ✅
│   │   ├── 02_LESS_SCANNING.md ✅
│   │   ├── 03_IMPORT_HIERARCHY.md ✅
│   │   ├── 04_RULE_EXTRACTION.md ✅ (CRITICAL STAGE)
│   │   ├── 04_VARIABLE_EXTRACTION.md ✅
│   │   ├── 05_TAILWIND_EXPORT.md ✅
│   │   ├── 06_INTEGRATION.md ✅
│   │   ├── 07_TESTING_RELEASE.md ✅
│   │   ├── 08_CHROME_EXTENSION.md ✅
│   │   └── 09_DOM_TO_TAILWIND.md ✅
│   └── ...
├── src/
│   ├── part1/
│   │   ├── services/
│   │   │   ├── scanService.ts
│   │   │   ├── importResolverService.ts
│   │   │   ├── lessCompilerService.ts ✅ (NEW - Stage 4)
│   │   │   ├── variableExtractorService.ts
│   │   │   └── tailwindExporterService.ts
│   │   └── ...
│   ├── part2/
│   │   ├── services/
│   │   │   ├── captureService.ts
│   │   │   ├── cssSelectorMatcher.ts ✅ (NEW - real matching)
│   │   │   ├── cascadeResolver.ts ✅ (NEW - specificity + order)
│   │   │   ├── mediaQueryMatcher.ts ✅ (NEW - responsive)
│   │   │   └── tailwindMapperService.ts
│   │   └── ...
│   └── ...
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/
```

---

## Start Here

### With Claude Code
1. Run: `./bootstrap-stage.sh 1 DATABASE_FOUNDATION`
2. Read: [CLAUDE_CODE_INVOCATION.md](./CLAUDE_CODE_INVOCATION.md) (Stage 1 section)
3. Follow: [CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md) for systematic approach

### Manual Development
1. **Read:** [Stage 1: Database Foundation](./stages/01_DATABASE_FOUNDATION.md)
2. **Understand:** How Stage 4 fits in (see [Stage 4: Rule Extraction](./stages/04_RULE_EXTRACTION.md))
3. **Build:** Stages 1-3 first (scanning and imports)
4. **Then:** Stage 4 (CSS compilation) - this is the critical link
5. **Then:** Stages 5-7 (variable extraction, export, testing)
6. **Finally:** Stages 8-9 (extension and matching)

---

## Stage Status

- [ ] **STAGE 1: Database Foundation** - Ready to start
- [ ] **STAGE 2: LESS Scanning** - Ready to start after Stage 1
- [ ] **STAGE 3: Import Hierarchy** - Ready to start after Stage 2
- [ ] **STAGE 4: CSS Rule Extraction** - Ready to start after Stage 3 ⚠️ CRITICAL
- [ ] **STAGE 5: Variable Extraction** - Ready to start after Stage 4
- [ ] **STAGE 6: Tailwind Export** - Ready to start after Stage 5
- [ ] **STAGE 7: Integration & Testing** - Ready to start after Stage 6
- [ ] **STAGE 8: Chrome Extension** - Ready to start after Stage 7
- [ ] **STAGE 9: Backend Matching** - Ready to start after Stage 8

---

**Last Updated:** October 29, 2025  
**Version:** 2.1 (Added Claude Code Integration)
