# ARCHITECTURE GUIDE (UPDATED FOR PART 2)

This document describes the overall system architecture for both Part 1 (LESS extraction) and Part 2 (HTML to Tailwind conversion).

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Layers](#architecture-layers)
3. [Part 1: LESS Extraction](#part-1-less-extraction)
4. [Part 2: HTML to Tailwind](#part-2-html-to-tailwind)
5. [Selector Matching Engine](#selector-matching-engine)
6. [Module Responsibilities](#module-responsibilities)
7. [Data Flow](#data-flow)
8. [Key Design Decisions](#key-design-decisions)

---

## System Overview

### Two-Part System

**Part 1 - LESS CSS Extraction (Weeks 1-6)**
- Scans multiple file system paths for LESS CSS files
- Parses LESS syntax and hierarchical imports
- **Extracts CSS selectors and rules** (NEW)
- Stores hierarchical structure in PostgreSQL
- Extracts variables, mixins, and theme tokens
- Exports Tailwind CSS configuration

**Part 2 - HTML to Tailwind Conversion (Weeks 7-10)**
- Accepts HTML DOM strings as input
- Matches HTML elements to extracted LESS CSS rules
- Applies CSS cascade and specificity rules
- Maps matched properties to Tailwind CSS classes
- Outputs HTML with Tailwind class suggestions

### Technology Stack

- **Runtime:** Node.js
- **Language:** TypeScript (strict mode)
- **Database:** PostgreSQL with pg driver
- **LESS Parsing:** less.js library
- **HTML Parsing:** cheerio (for Part 2)
- **Testing:** Jest with ts-jest

---

## Architecture Layers

### Part 1: LESS Extraction

```
┌─────────────────────────────────────────────────────┐
│  CLI / Entry Point (src/index.ts)                   │
│  - Orchestrate Part 1 pipeline                      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Service Layer (src/services/)                      │
│  - LessService: File scanning & LESS processing     │
│  - DatabaseService: Data persistence                │
│  - RuleExtractionService: CSS rule extraction ⭐    │
│  - ExportService: Tailwind config generation        │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Data Layer (src/models/, src/database/)            │
│  - Type definitions and interfaces                  │
│  - Database connection & query builders             │
│  - Schema and migrations                            │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Utilities & Infrastructure                         │
│  - logger.ts: Structured logging                    │
│  - CustomError.ts: Error types                      │
│  - Validators: Input validation                     │
└─────────────────────────────────────────────────────┘
```

### Part 2: HTML to Tailwind

```
┌─────────────────────────────────────────────────────┐
│  CLI / Entry Point (src/part2/index.ts) ⭐           │
│  - Accept HTML input                                │
│  - Orchestrate Part 2 pipeline                      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Conversion Layer (src/part2/services/) ⭐           │
│  - HtmlParserService: Parse DOM                     │
│  - SelectorMatchingEngine: Match rules ⭐⭐          │
│  - CascadeResolver: Apply CSS cascade               │
│  - TailwindMapper: Map to Tailwind classes          │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Part 1 Infrastructure (reused)                     │
│  - DatabaseService (read-only queries)              │
│  - PostgreSQL (less_rules, less_variables)          │
└─────────────────────────────────────────────────────┘
```

---

## Part 1: LESS Extraction

### Stages 1-3: Foundation & Imports (Unchanged)

See original ARCHITECTURE.md sections.

### Stage 4: Rule & Selector Extraction ⭐ NEW

**Responsibility:** Extract CSS selectors and rule blocks from LESS files

**New Components:**
- `RuleExtractionService` - Parses CSS rules, flattens nesting
- `SelectorIndexer` - Builds queryable selector index
- `SpecificityCalculator` - Computes CSS specificity scores

**Outputs:**
- `less_rules` table populated with selectors and properties
- Indexed selectors ready for Part 2 matching

---

## Part 2: HTML to Tailwind

### Core Components

#### 1. HTML Parser Service

**Responsibility:** Parse HTML and extract element information

**Public Methods:**
```typescript
parseHtml(htmlString: string): ParsedElement[]
```

**Returns:**
```typescript
interface ParsedElement {
  id: string;
  tag: string;
  classes: string[];
  id: string;
  attributes: Record<string, string>;
  children: ParsedElement[];
  computedStyle?: Record<string, string>;
}
```

---

#### 2. Selector Matching Engine ⭐⭐ CRITICAL

**Responsibility:** Match HTML elements to LESS CSS selectors

**Core Logic:**
1. Index all LESS selectors from database
2. For each HTML element, find matching selectors
3. Calculate specificity for each match
4. Sort by specificity (highest wins)

**Public Methods:**
```typescript
indexSelectors(lessRules: LessRule[]): SelectorIndex

matchElement(element: ParsedElement): MatchedRule[]
  → Returns rules sorted by specificity

calculateSpecificity(selector: string): SpecificityScore
  → (idCount, classCount, elementCount)
```

**Selector Types Supported:**
- Element selectors: `div`, `h1`
- Class selectors: `.asc-about-header`
- ID selectors: `#main`
- Descendant: `.parent .child`
- Child: `.parent > .child`
- Attribute: `[type="text"]`
- Pseudo-classes: `:hover` (flagged for manual override)

---

#### 3. Cascade Resolver

**Responsibility:** Apply CSS cascade rules and resolve conflicts

**Cascade Rules:**
1. Later rules override earlier rules (same specificity)
2. Higher specificity wins
3. `!important` highest priority
4. Inline styles override all

**Output:**
```typescript
interface ComputedStyle {
  property: string;
  value: string;
  source: 'inherited' | 'cascade' | 'inline' | 'important';
  specificity: SpecificityScore;
  ruleId: number; // Reference to less_rules
}
```

---

#### 4. Tailwind Mapper

**Responsibility:** Convert CSS properties to Tailwind classes

**Strategy:**
- Query `theme_tokens` table (from Part 1) for value mappings
- Match CSS property→value to Tailwind class equivalents
- Generate confidence score for each mapping
- Provide fallback utility classes if exact match unavailable

**Examples:**
```
CSS: color: #3498db        → Tailwind: text-blue-500 (confidence: 0.95)
CSS: font-weight: bold     → Tailwind: font-bold (confidence: 1.0)
CSS: margin: 30px          → Tailwind: m-8 (confidence: 0.80)
```

---

## Selector Matching Engine: Detailed Design

### Data Structure

```typescript
interface SelectorIndex {
  // Simple selectors (exact match)
  simpleSelectors: Map<string, LessRule[]>;
  
  // Complex selectors (regex match)
  complexSelectors: {
    pattern: RegExp;
    rule: LessRule;
    specificity: SpecificityScore;
  }[];
  
  // Class → selectors mapping (fast lookup)
  classMappings: Map<string, LessRule[]>;
  
  // ID → selectors mapping
  idMappings: Map<string, LessRule[]>;
}
```

### Matching Algorithm

```
FOR each HTML element:
  1. Collect matching selectors:
     a) Direct class match (e.g., .asc-about-header)
     b) Descendant matches (parent has required class)
     c) ID match
     d) Element tag match
  
  2. For each matching selector:
     - Calculate specificity
     - Get all properties from rule
     - Mark as "applicable"
  
  3. Sort applicable rules by specificity (desc)
  
  4. Apply cascade (resolve conflicts)
  
  5. Return final computed style
```

### Specificity Score

```typescript
interface SpecificityScore {
  idCount: number;      // #id selectors
  classCount: number;   // .class, [attr] selectors
  elementCount: number; // element selectors
  
  // Calculated: (idCount * 100) + (classCount * 10) + elementCount
  totalScore(): number
}

// Example: .parent .asc-about-header
// Result: (0, 2, 1) = 0*100 + 2*10 + 1 = 21
```

---

## Data Flow

### Part 1: Complete LESS Extraction

```
LESS Files
    ↓ (Stage 2: Scan)
LessService.scanLessFiles()
    ↓ (discovered paths)
LessService.processLessFile()
    ↓ (file content)
DatabaseService.storeLessFile()
    ↓ (stored as less_files)
LessService.resolveImportHierarchy()
    ↓ (import graph)
DatabaseService.resolveImports()
    ↓ (imports linked)
→→→ NEW: RuleExtractionService.extractRules() ⭐
    ↓ (CSS rules + selectors)
DatabaseService.storeRules()
    ↓ (stored as less_rules + selectors indexed)
LessService.extractVariablesAndMixins()
    ↓ (variables)
DatabaseService.extractVariables()
    ↓ (stored as less_variables)
ExportService.exportToTailwind()
    ↓ (theme tokens)
File System (tailwind.config.js)
```

### Part 2: HTML to Tailwind

```
HTML DOM String
    ↓ (Stage 8: Parse)
HtmlParserService.parseHtml()
    ↓ (ParsedElements[])
→→→ SelectorMatchingEngine.indexSelectors() ⭐⭐
    ↓ (query less_rules from DB)
SelectorIndex ready
    ↓
FOR each ParsedElement:
    ↓ (Stage 9: Match)
    SelectorMatchingEngine.matchElement(element)
        ↓ (MatchedRules[])
    ↓ (Stage 10: Cascade)
    CascadeResolver.resolveConflicts()
        ↓ (ComputedStyle{})
    ↓ (Stage 11: Map)
    TailwindMapper.cssToTailwind()
        ↓ (TailwindClasses[])
    ↓ (Annotate element)
    ↓
Output: HTML with Tailwind classes + mappings
```

---

## Module Responsibilities

### Part 1 Services (Existing + New)

#### New: `services/ruleExtractionService.ts`

**Responsibility:** Extract CSS selectors and rules from LESS files

**Public Methods:**
- `extractRules(lessContent: string, filePath: string): Rule[]`
- `flattenNestedSelectors(nestedRules): string[]`
- `calculateSpecificity(selector: string): SpecificityScore`

**Dependencies:**
- LESS parser (for rule structure)
- Logger
- DatabaseService

---

### Part 2 Services (New)

#### `part2/services/htmlParserService.ts`

Parse HTML DOM strings into structured element tree.

#### `part2/services/selectorMatchingEngine.ts` ⭐⭐

Core engine matching elements to CSS rules.

**Responsibilities:**
- Index all LESS selectors
- Match elements to selectors
- Calculate specificity
- Cache results for performance

#### `part2/services/cascadeResolver.ts`

Apply CSS cascade rules to resolve property conflicts.

#### `part2/services/tailwindMapper.ts`

Map CSS properties to Tailwind classes using theme tokens.

---

## Key Design Decisions

### 1. Two-Part Architecture

**Decision:** Part 1 must complete before Part 2 begins

**Rationale:**
- Part 2 depends on Part 1's data (less_rules)
- Allows independent testing and refinement
- Clear separation of concerns
- Part 1 can be deployed standalone

---

### 2. Selector Index in Memory

**Decision:** Load and cache all selectors in memory during Part 2

**Rationale:**
- Matching is fast (no DB queries per element)
- Selectors relatively small dataset
- Performance critical for Part 2
- Invalidate on LESS file changes

**Trade-off:** Memory vs speed (acceptable for typical LESS projects)

---

### 3. Specificity as Tiebreaker

**Decision:** CSS specificity rules determine final properties

**Rationale:**
- CSS standard behavior
- Matches developer expectations
- Predictable, deterministic results
- Handles complex cascades correctly

---

### 4. No Pseudo-Class Support Initially

**Decision:** Flag pseudo-classes (`:hover`, etc.) for manual review

**Rationale:**
- Pseudo-classes don't exist in static HTML
- Need runtime context to resolve
- Can add heuristics later (`.link:hover` → suggest interaction classes)
- Better to warn than silently ignore

---

## Extensibility

### Adding New CSS Property Mappings

1. Update `theme_tokens` table with new property→Tailwind mappings
2. TailwindMapper automatically uses new mappings

### Supporting New HTML Elements

1. HtmlParserService handles all HTML tags
2. SelectorMatchingEngine applies same rules
3. No code changes needed

### Adding Custom Tailwind Rules

1. Create custom theme tokens in database
2. TailwindMapper includes in output with `custom-` prefix

---

## Performance Considerations

### Part 1

- Batch insert variables/rules (single query, not N queries)
- Index selectors on (class, id, element) for fast lookups
- Lazy load large files

### Part 2

- Cache selector index in memory
- Parallelize element matching
- Generate class suggestions without blocking

---

**Document Version:** 2.0 (Updated for Part 2)  
**Last Updated:** October 29, 2025
