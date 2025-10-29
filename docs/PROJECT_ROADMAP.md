# PROJECT ROADMAP: LESS to Tailwind Parser (UPDATED)

## Executive Summary

**Updated Scope:** This is now a TWO-PART system:

**Part 1 - LESS CSS Extraction:** Transform LESS CSS files from multiple source directories into a hierarchically-structured PostgreSQL database with extracted theme tokens.

**Part 2 - HTML to Tailwind Conversion:** Parse HTML DOM, match elements to extracted LESS CSS rules, and generate Tailwind-compatible class suggestions.

**Total Estimated Timeline:** 8-10 weeks (6 weeks Part 1 + 2-4 weeks Part 2)

**Approach:** Part 1 must complete fully before Part 2 begins. Part 2 depends on Part 1's rule storage and extraction.

---

## Updated Project Goals

1. ✅ **Part 1:** Store LESS hierarchical structure and theme tokens in PostgreSQL
2. ✅ **Part 1:** Export Tailwind configuration from extracted theme values
3. 🆕 **Part 2:** Parse HTML DOM strings
4. 🆕 **Part 2:** Match HTML elements to LESS CSS selectors
5. 🆕 **Part 2:** Apply CSS cascade/specificity rules
6. 🆕 **Part 2:** Generate Tailwind class suggestions for HTML elements

---

## PART 1: LESS Extraction (Weeks 1-6)

### Stage Overview

| # | Stage | Description | Testable Outcomes | Dependencies | Effort | Status |
|---|-------|-------------|-------------------|--------------|--------|--------|
| 1 | Database Foundation | PostgreSQL setup, schema creation | All tables created, connection verified | None | 1 week | ⏳ Ready |
| 2 | LESS File Scanning | Discover & store LESS files | All .less files found and stored | Stage 1 | 1 week | ⏳ Ready |
| 3 | Import Hierarchy | Parse @import relationships | Import graph built, circular refs detected | Stage 2 | 1.5 weeks | ⏳ Ready |
| 4 | Rule & Selector Extraction | Parse CSS rules and selectors ⭐ NEW | Selectors indexed, properties mapped | Stage 2 | 1.5 weeks | ⏳ New |
| 5 | Variable Extraction | Extract @variables and .mixins | Variables stored, mixin params captured | Stages 3,4 | 1 week | ⏳ Modified |
| 6 | Tailwind Export | Generate config from theme tokens | Valid tailwind.config.js created | Stages 4,5 | 1 week | ⏳ Modified |
| 7 | Integration (Part 1) | Orchestrate full Part 1 pipeline | End-to-end execution, all stages working | All above | 0.5 week | ⏳ Modified |

**Stage Reorganization Note:** Original Stage 4 (Variable Extraction) is now Stage 5. New Stage 4 extracts CSS rules and selectors (required for Part 2).

---

## PART 2: HTML to Tailwind (Weeks 7-10)

### Stage Overview

| # | Stage | Description | Testable Outcomes | Dependencies | Effort | Status |
|---|-------|-------------|-------------------|--------------|--------|--------|
| 8 | HTML Parser | Parse HTML DOM strings | DOM parsed, elements identified, classes extracted | Part 1 complete | 1 week | 📝 Coming |
| 9 | Selector Matching Engine | Match elements to LESS selectors | Selectors matched, specificity calculated | Stage 8 | 1.5 weeks | 📝 Coming |
| 10 | CSS Cascade & Specificity | Apply cascade rules, resolve conflicts | Properties properly cascaded, specificity ranked | Stage 9 | 1 week | 📝 Coming |
| 11 | Tailwind Mapping | Convert matched properties to Tailwind | Class suggestions generated, fallbacks provided | Stage 10 | 1 week | 📝 Coming |
| 12 | Integration (Part 2) | Orchestrate HTML→Tailwind pipeline | End-to-end HTML parsing to Tailwind output | All above | 0.5 week | 📝 Coming |

---

## Updated Data Flow

```
┌─ PART 1: LESS Extraction ─────────────────────────────┐
│                                                         │
│  LESS Files                                             │
│    ↓ (Stage 2)                                          │
│  Scan & Store                                           │
│    ↓ (Stage 3)                                          │
│  Resolve Imports                                        │
│    ↓ (Stage 4) ⭐ NEW                                   │
│  Extract Selectors & Rules                             │
│    ↓ (Stage 5)                                          │
│  Extract Variables & Mixins                            │
│    ↓                                                    │
│  PostgreSQL: less_rules, less_variables                │
│    ↓ (Stage 6)                                          │
│  Export Tailwind Config                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
                       ↓
                PostgreSQL Ready
                       ↓
┌─ PART 2: HTML→Tailwind ───────────────────────────────┐
│                                                         │
│  HTML DOM String (Stage 8) ⭐ NEW                      │
│    ↓                                                    │
│  Parse HTML → Elements with classes                    │
│    ↓ (Stage 9)                                          │
│  Match selectors from LESS rules                       │
│    ↓ (Stage 10)                                         │
│  Apply cascade/specificity rules                       │
│    ↓ (Stage 11)                                         │
│  Map properties to Tailwind classes                    │
│    ↓                                                    │
│  Output: HTML with Tailwind suggestions                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Updated Database Schema

### Part 1 Tables (Existing + Modified)

- `less_files` - LESS files and metadata
- `less_imports` - File dependencies
- `less_rules` ⭐ **NEW** - CSS selectors and rule blocks (queryable)
- `less_variables` - Variables and mixins
- `theme_tokens` ⭐ **MODIFIED** - Extracted theme values (colors, spacing, fonts)
- `tailwind_exports` - Generated Tailwind config

### Part 2 Tables (New)

- `selector_matches` ⭐ **NEW** - Cached selector→element matches
- `element_styles` ⭐ **NEW** - Applied styles per HTML element (with cascade info)
- `html_conversions` ⭐ **NEW** - Audit trail of HTML→Tailwind conversions

---

## Key Architectural Addition: Selector Matching Engine

New core component to support Part 2:

```
SelectorMatchingEngine
├── parseSelectors(lessRules) → IndexedSelectors
├── matchElement(element, selectors) → MatchedRules[]
├── calculateSpecificity(selector) → number
├── applyCascade(rules) → FinalProperties
└── generateTailwindClasses(properties) → string[]
```

This engine:
- Indexes all LESS selectors for fast lookup
- Implements CSS cascade rules
- Handles selector specificity
- Maps final properties to Tailwind equivalents

---

## Critical Implementation Notes

⚠️ **Blind spots to address:**

1. **Pseudo-classes/elements** (`:hover`, `::before`) - Don't exist in static HTML, need strategy for how to handle
2. **Media queries** - How do we resolve responsive rules? Include all? Assume desktop?
3. **LESS guards & conditionals** - Rules with `when` conditions may not apply
4. **Mixin argument variations** - Same mixin called with different arguments = different output
5. **CSS cascade order matters** - File order + specificity determine final properties
6. **Duplicate selectors** - Same selector appears multiple times, last wins (or does it?)

These must be addressed in Stage 4 design before implementation.

---

## Updated Stage 4 Specifics: Rule & Selector Extraction

**New in Part 1 - Critical for Part 2**

### What's Changing

- Previous: Only extracted variables and mixins
- Now: Must also extract CSS rule blocks with selectors

### Requirements

1. Parse all CSS selectors from LESS files (after variables expanded)
2. Store selector strings in indexed, queryable format
3. Map selector → properties mapping
4. Handle LESS nesting (flatten to final selectors)
5. Track selector specificity scores
6. Store rule precedence (file order, specificity)

### Database Table: `less_rules`

```sql
CREATE TABLE less_rules (
  id SERIAL PRIMARY KEY,
  less_file_id INTEGER NOT NULL,
  selector VARCHAR(1024) NOT NULL,
  selector_specificity INTEGER, -- (ID count, class count, element count)
  properties JSONB, -- {property: value}
  line_number INTEGER,
  rule_order INTEGER, -- File order for cascade
  created_at TIMESTAMP,
  FOREIGN KEY (less_file_id) REFERENCES less_files(id)
);

CREATE INDEX idx_less_rules_selector ON less_rules(selector);
CREATE INDEX idx_less_rules_file ON less_rules(less_file_id);
```

---

## Updated Dependency Graph

```
Stage 1 (DB)
    ↓
Stage 2 (Scan)
    ↓
Stage 3 (Imports)
    ↓
Stage 4 (Rules) ⭐ NEW - CRITICAL DEPENDENCY
    ├──→ Stage 5 (Variables)
    └──→ Part 2 stages depend on this
    
Stage 5 (Variables)
    ├──→ Stage 6 (Export Part 1)
    
Stage 6 (Export Part 1)
    ↓
Stage 7 (Integrate Part 1)
    ↓ (Gates Part 2)
    
Stage 8 (HTML Parser) ⭐ NEW
    ↓
Stage 9 (Selector Matching) ⭐ NEW - Uses Stage 4 rules
    ↓
Stage 10 (Cascade)
    ↓
Stage 11 (Tailwind Mapping)
    ↓
Stage 12 (Integrate Part 2)
```

---

## Acceptance Criteria - Part 1 Unchanged

Part 1 stages maintain original acceptance criteria. Part 2 stages will have specific acceptance criteria (documented when stages begin).

---

## Timeline Visualization

```
Week 1:    [══ Stage 1: DB ══]
Week 2:                   [══ Stage 2: Scan ══]
Week 3:                               [═ Stage 3 ═][═ Stage 4* ═]
Week 4:                        [════ Stages 3,4,5 (parallel start) ════]
Week 5:                                              [═ Stage 5 ═][═ Stage 6 ═]
Week 6:                                                    [═ Stage 6 ═][S7]
                                                                      ↓
Week 7:    [═ Stage 8: HTML Parser ═]
Week 8:                   [═ Stage 9: Selector Matching ═]
Week 9:                               [═ Stage 10: Cascade ═]
Week 10:                                     [═ Stage 11: Tailwind ═][S12]

* = New stage in Part 1
```

---

## Part 2 API Concept (Preview)

```typescript
// Input: HTML string
const htmlInput = `
  <div class="asc-about-header">
    <h1>About Us</h1>
  </div>
`;

// Process: Match to LESS rules and convert
const converter = new HtmlToTailwindConverter(lessDatabase);
const result = await converter.convert(htmlInput);

// Output: HTML with Tailwind suggestions
{
  html: '<div class="text-lg font-bold text-gray-900">...</div>',
  mappings: [
    {
      selector: '.asc-about-header',
      originalProperties: { 'font-size': '12px', ... },
      tailwindClasses: ['text-lg', 'font-bold', ...],
      confidence: 0.92
    }
  ]
}
```

---

## Document Updates Needed

- ✅ PROJECT_ROADMAP.md (this file - updated)
- 📝 ARCHITECTURE.md - Add Part 2 architecture, selector matching engine
- 📝 DATABASE_OPERATIONS.md - Add less_rules queries
- 📝 Stage 4 guide - NEW: Rule & Selector Extraction
- 📝 Stage 8 guide - NEW: HTML Parser
- 📝 Stage 9 guide - NEW: Selector Matching Engine
- 📝 Stage 10 guide - NEW: CSS Cascade & Specificity
- 📝 Stage 11 guide - NEW: Tailwind Mapping

---

**Next Step:** Begin Stage 1 with updated understanding that Stage 4 requires selector extraction (not in original plan).

---

**Document Version:** 2.0 (Updated for Part 2)  
**Last Updated:** October 29, 2025
