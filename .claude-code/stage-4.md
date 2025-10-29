# Claude Code Instructions: Stage 4 - CSS Rule Extraction & Compilation

## Overview

Implement LESS CSS compilation with nesting expansion, variable resolution, CSS specificity calculation, and media query handling.

**Stage:** 4 of 9  
**Duration:** Expected 2 weeks  
**Complexity:** ⭐⭐⭐ (Critical Stage)  
**Files to Create:** 12-15  
**Tests Required:** 20+ unit tests  

---

## Critical Importance

⚠️ **This stage is the bridge between LESS source and Part 2 matching engine.**

Stage 9 (Backend Matching) depends entirely on Stage 4 output:
- Compiled CSS rules with resolved variables
- Calculated specificity for cascade resolution
- Media query context
- Rule ordering

**Stage 4 MUST be 100% correct for Stage 9 to work.**

---

## Objectives

1. ✅ Parse LESS to AST (Abstract Syntax Tree)
2. ✅ Expand LESS nesting into flat CSS selectors
3. ✅ Resolve @variables using Part 1 scope hierarchy
4. ✅ Calculate CSS specificity (IDs, classes, elements)
5. ✅ Track rule order for cascade resolution
6. ✅ Handle @media queries separately
7. ✅ Expand LESS mixins/functions inline
8. ✅ Store compiled rules in database
9. ✅ Comprehensive tests and validation

---

## Files to Create

### Core Services
```
src/part1/services/
├── lessCompilerService.ts           # Main compilation logic
├── variableResolverService.ts       # @variable resolution
├── nestingExpanderService.ts        # Nesting expansion
├── specificityCalculatorService.ts  # CSS specificity
└── mediaQueryHandlerService.ts      # @media query handling
```

### Database
```
src/part1/migrations/
└── 04-create-less-rules-table.sql   # Create less_rules table
                                      # Add all indexes
```

### Tests
```
tests/unit/
├── lessCompiler.test.ts
├── variableResolver.test.ts
├── nestingExpander.test.ts
├── specificityCalculator.test.ts
└── mediaQueryHandler.test.ts

tests/integration/
└── lessCompilation.integration.test.ts

tests/fixtures/
├── sample-less-files/
│   ├── simple.less
│   ├── nested.less
│   ├── variables.less
│   ├── media-queries.less
│   └── complex.less
└── expected-output/
    └── compiled-rules.json
```

---

## Implementation Requirements

### 1. LESS Compiler Service

**Must implement:**
```typescript
export class LessCompilerService {
  async compileFile(
    fileId: string,
    versionId: string,
    scopeChain: string[]  // From Part 1
  ): Promise<CompiledRule[]>
  
  private parseToAST(content: string): LessAST
  private compileRule(...): CompiledRule[]
  private buildSelector(parent: string, current: string): string
}
```

**Key algorithm:**
1. Parse LESS content to AST
2. For each rule:
   a. Expand nesting (`.parent { .child {...} }` → `.parent .child`)
   b. Resolve variables using scope chain
   c. Expand mixins inline
   d. Handle @media queries
   e. Calculate CSS specificity
   f. Track rule order
3. Store in `less_rules` table

### 2. Variable Resolver Service

**Must implement:**
```typescript
export class VariableResolverService {
  async resolveInRule(
    rule: LessRule,
    fileId: string,
    scopeChain: string[]  // [file1, file2, file3]
  ): Promise<Record<string, string>>
}
```

**Key logic:**
1. Extract @variable references from property values
2. Search scope chain for variable definition (highest priority first)
3. Iteratively resolve (max 10 iterations to prevent infinite loops)
4. Return fully resolved properties

### 3. CSS Specificity Calculator

**Must implement:**
```typescript
export class SpecificityCalculator {
  calculate(selector: string): [number, number, number]
  // Returns [IDs, classes, elements]
  // Example: "#header .button:hover" → [1, 2, 0]
  
  compare(
    a: [number, number, number],
    b: [number, number, number]
  ): number  // Returns 1 if a wins, -1 if b wins, 0 if equal
}
```

**Key rules:**
- IDs: 1 per #id
- Classes/attributes/pseudo-classes: 1 per .class, [attr], :pseudo
- Elements: 1 per tag name
- Combinators (>, +, ~, space) don't affect specificity

### 4. Nesting Expander Service

**Must handle:**
```less
// Input:
.header {
  background: blue;
  
  .logo {
    color: white;
  }
  
  &:hover {
    opacity: 0.8;
  }
}

// Output rules:
.header { background: blue }
.header .logo { color: white }
.header:hover { opacity: 0.8 }
```

**Key logic:**
1. & means parent selector
2. Space means descendant selector
3. Recursively expand nested rules

### 5. Media Query Handler

**Must implement:**
```typescript
export class MediaQueryHandler {
  extractMediaQuery(rule: LessRule): string | null
  // Returns: "@media (min-width: 768px)" or null
  
  parseMediaQuery(query: string): {
    features: Array<{ name: string, value: string }>
  }
}
```

**Key logic:**
1. Detect @media query wrapper
2. Extract the media query text
3. Store separately from rule
4. Store rule only for matching viewport context

---

## Database Schema

Create `less_rules` table:

```sql
CREATE TABLE less_rules (
  id SERIAL PRIMARY KEY,
  file_id UUID NOT NULL,
  source_line_number INTEGER NOT NULL,
  selector VARCHAR(1024) NOT NULL,
  specificity_a INT DEFAULT 0,
  specificity_b INT DEFAULT 0,
  specificity_c INT DEFAULT 0,
  properties JSONB NOT NULL,
  media_query TEXT,
  rule_order INT NOT NULL,
  parent_selector_id INT,
  is_nested_rule BOOLEAN DEFAULT false,
  less_file_path VARCHAR(2048),
  last_processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_selector_id) REFERENCES less_rules(id)
);

-- Critical indexes for Stage 9 matching
CREATE INDEX idx_rules_selector ON less_rules(selector);
CREATE INDEX idx_rules_cascade ON less_rules(
  specificity_a DESC,
  specificity_b DESC,
  specificity_c DESC,
  rule_order DESC
);
```

---

## Test Fixtures

Create test LESS files to validate compilation:

**tests/fixtures/simple.less:**
```less
@color: #FF0000;
.button { color: @color; }
```

**tests/fixtures/nested.less:**
```less
.header {
  background: blue;
  .logo { color: white; }
}
```

**tests/fixtures/media.less:**
```less
@media (min-width: 768px) {
  .container { width: 100%; }
}
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] LESS nesting expands correctly (verify with fixture tests)
- [ ] Variables resolved to actual values (no @var in properties)
- [ ] CSS specificity calculated correctly
  - [ ] IDs: 1 per #id
  - [ ] Classes: 1 per .class
  - [ ] Elements: 1 per tag
- [ ] Rule order preserved (for cascade)
- [ ] @media queries stored and queryable
- [ ] Mixins expanded inline
- [ ] Circular variable references detected (max 10 iterations)
- [ ] All rules inserted into database
- [ ] Stage 9 can query `less_rules` table successfully
- [ ] Tests pass with >90% coverage
- [ ] No TypeScript errors
- [ ] All edge cases handled

---

## Edge Cases to Handle

1. **Deep nesting** (5+ levels)
   - Test: `docs/stages/04_RULE_EXTRACTION.md` fixture

2. **Circular variables**
   - @a: @b; @b: @a;
   - Solution: Limit to 10 iterations, detect cycles

3. **Missing variables**
   - @undefined: blue; color: @undefined;
   - Solution: Keep @undefined in output, log warning

4. **Complex selectors**
   - `.parent > .child + span ~ div`
   - Solution: Parse combinators correctly

5. **Pseudo-classes**
   - `.button:hover { opacity: 0.8; }`
   - Solution: Count as class for specificity

6. **Attributes**
   - `[data-id='123'] { color: blue; }`
   - Solution: Count as class for specificity

---

## Testing Requirements

### Unit Tests (20+ tests)

```typescript
// specificityCalculator.test.ts
- Simple selectors
- Multiple classes
- IDs and classes mixed
- Pseudo-classes
- Attributes
- Combinators (should not affect specificity)

// nestingExpander.test.ts
- Single level nesting
- Multiple levels
- & references
- Mixed nesting

// variableResolver.test.ts
- Simple resolution
- Scope chain priority
- Circular references
- Missing variables

// lessCompiler.test.ts
- Complete compilation
- Rule ordering
- Media query extraction
- Complex files
```

### Integration Tests

```typescript
// lessCompilation.integration.test.ts
- Compile real LESS file
- Insert into database
- Query from database
- Verify specificity calculation
- Verify cascade order
```

---

## Validation Workflow

Before considering Stage 4 complete:

```bash
# 1. Compile test fixtures
npm test -- lessCompiler.test.ts
✅ All fixtures compile correctly

# 2. Verify specificity
npm test -- specificityCalculator.test.ts
✅ All specificity calculations correct

# 3. Verify variable resolution
npm test -- variableResolver.test.ts
✅ All variables resolved
✅ No @var references remain

# 4. Database verification
npm test -- lessCompilation.integration.test.ts
✅ Rules stored in database
✅ All indexes created

# 5. Stage 9 readiness
Verify in psql:
SELECT selector, specificity_a, specificity_b, specificity_c 
FROM less_rules 
ORDER BY specificity_a DESC, specificity_b DESC;
✅ Can query and order by specificity

# 6. Full validation
npm test -- stage-4
✅ All tests pass
✅ Coverage >90%
```

---

## Critical Verification for Stage 9

Before committing Stage 4, Stage 9 must be able to:

```sql
-- Query rules by selector
SELECT * FROM less_rules WHERE selector LIKE '%button%';
✅ Returns rules

-- Get rules in cascade order
SELECT * FROM less_rules 
ORDER BY specificity_a DESC, specificity_b DESC, rule_order DESC
LIMIT 1;
✅ Returns correct winning rule

-- Filter by media query
SELECT * FROM less_rules WHERE media_query = '@media (min-width: 768px)';
✅ Returns media-specific rules

-- Check properties are resolved
SELECT properties FROM less_rules LIMIT 1;
✅ All properties have actual values, no @var references
```

---

## Dependencies

```json
{
  "dependencies": {
    "less": "^4.2.0"
  }
}
```

---

## Resources

- `docs/stages/04_RULE_EXTRACTION.md` - Detailed guide
- `docs/ARCHITECTURE.md` - System design
- `docs/TESTING_GUIDE.md` - Testing patterns

---

## Success Checklist

Stage 4 is complete when:

- [ ] All LESS files compile to CSS
- [ ] All nesting expands correctly
- [ ] All variables resolve to values
- [ ] All specificity calculated
- [ ] All rules ordered for cascade
- [ ] Media queries handled
- [ ] Tests pass (>90% coverage)
- [ ] Database schema correct
- [ ] Stage 9 can query rules
- [ ] No unresolved variables in output

---

**Last Updated:** October 29, 2025
