# STAGE 4: CSS RULE EXTRACTION & COMPILATION

**Duration:** 2 weeks  
**Status:** ⏳ Critical (after Stage 3 complete)  
**Dependencies:** Stage 3 (Import Hierarchy)  
**Enables:** Stage 5 (Variable Extraction), Stage 9 (Backend Matching)

---

## Overview

Stage 4 transforms LESS source code into compiled CSS rules with fully resolved variables, expanded nesting, and CSS specificity calculations. This is the critical bridge between LESS source and matching engine.

**Key Deliverable:** `less_rules` table with compiled, queryable CSS selectors and properties.

---

## Critical Difference from Other Stages

Most stages transform LESS → database. Stage 4 is unique: it **compiles LESS to CSS first**, then stores the compiled output.

LESS source:
```less
@primary-color: #FF0000;

.header {
  background: @primary-color;
  
  .logo {
    color: white;
  }
}

@media (min-width: 768px) {
  .header {
    padding: 20px;
  }
}
```

Stage 4 output in database:
```
Rule 1: selector=".header", properties={background: "#FF0000"}
Rule 2: selector=".header .logo", properties={color: "white"}
Rule 3: selector=".header", media_query="@media (min-width: 768px)", properties={padding: "20px"}
```

---

## Objectives

1. ✅ Parse @media queries (separate rule contexts)
2. ✅ Expand LESS nesting into flat CSS selectors
3. ✅ Resolve LESS variables using Part 1 scope hierarchy
4. ✅ Handle LESS mixins/functions in rules (expand inline)
5. ✅ Calculate CSS specificity (IDs, classes, elements)
6. ✅ Track rule order (for cascade resolution)
7. ✅ Compile &-references and pseudo-classes
8. ✅ Store with source line numbers for auditing
9. ✅ Create index structure for fast matching in Stage 9
10. ✅ Handle LESS conditionals (@if guards) gracefully

---

## Database Schema

### `less_rules` - Compiled Rules

```sql
CREATE TABLE less_rules (
  id SERIAL PRIMARY KEY,
  file_id UUID NOT NULL,
  source_line_number INTEGER NOT NULL,
  
  -- FULLY COMPILED selector (nesting expanded, variables resolved)
  -- Examples: ".header", ".header .logo", "[data-id='123']", ".button:hover"
  selector VARCHAR(1024) NOT NULL,
  
  -- CSS specificity per spec: (count_IDs, count_classes, count_elements)
  specificity_a INT DEFAULT 0,  -- ID count
  specificity_b INT DEFAULT 0,  -- class/attribute/pseudo-class count
  specificity_c INT DEFAULT 0,  -- element count
  
  -- Properties AFTER all variable/mixin expansion
  -- {"background-color": "#FF0000", "padding": "10px 20px"}
  properties JSONB NOT NULL,
  
  -- Media query if rule is inside @media block
  -- NULL if no media query (applies to all viewports)
  media_query TEXT,
  
  -- Audit trail
  rule_order INT NOT NULL, -- Position in file (later overrides earlier)
  parent_selector_id INT,  -- If nested rule, reference to parent
  is_nested_rule BOOLEAN DEFAULT false,
  
  -- Source context
  less_file_path VARCHAR(2048),
  last_processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_selector_id) REFERENCES less_rules(id)
);

-- Indexes for Stage 9 matching performance
CREATE INDEX idx_rules_selector ON less_rules(selector);
CREATE INDEX idx_rules_file ON less_rules(file_id);
CREATE INDEX idx_rules_media ON less_rules(media_query) WHERE media_query IS NOT NULL;

-- Critical for cascade resolution: specificity + order
CREATE INDEX idx_rules_cascade ON less_rules(
  specificity_a DESC,
  specificity_b DESC, 
  specificity_c DESC,
  rule_order DESC
);

-- For finding all rules in a file
CREATE INDEX idx_rules_file_order ON less_rules(file_id, rule_order);

-- Unique constraint: same selector can appear multiple times with different specificity/media
-- But useful for deduplication queries
CREATE UNIQUE INDEX idx_rules_unique ON less_rules(
  file_id, 
  selector, 
  COALESCE(media_query, 'none')
);
```

---

## Core Services

### LessCompiler Service

```typescript
// src/services/lessCompilerService.ts

export class LessCompilerService {
  async compileFile(
    fileId: string,
    versionId: string,
    scopeChain: string[]
  ): Promise<CompiledRule[]> {
    const version = await getFileVersion(versionId);
    const lessAst = this.parseToAST(version.content);
    
    const rules: CompiledRule[] = [];
    let ruleOrder = 0;
    
    for (const topLevelRule of lessAst.rules) {
      const compiled = this.compileRule(
        topLevelRule,
        '',           // No parent selector at top level
        scopeChain,
        ruleOrder
      );
      
      for (const rule of compiled.rules) {
        rules.push(rule);
        ruleOrder++;
      }
    }
    
    return rules;
  }

  private compileRule(
    lessRule: LessRule,
    parentSelector: string,
    scopeChain: string[],
    ruleOrder: number,
    mediaQuery?: string
  ): { rules: CompiledRule[], nextOrder: number } {
    const rules: CompiledRule[] = [];
    let order = ruleOrder;
    
    // Build the full selector
    const fullSelector = this.buildSelector(parentSelector, lessRule.selector);
    
    // Handle @media queries
    if (lessRule.mediaQuery) {
      mediaQuery = lessRule.mediaQuery;
    }
    
    // Handle nested children
    if (lessRule.children && lessRule.children.length > 0) {
      // Children are selectors nested inside this rule
      for (const child of lessRule.children) {
        const childCompiled = this.compileRule(
          child,
          fullSelector,
          scopeChain,
          order,
          mediaQuery
        );
        
        for (const childRule of childCompiled.rules) {
          rules.push(childRule);
          order++;
        }
      }
    }
    
    // Store this rule's properties (if it has any)
    if (lessRule.properties && Object.keys(lessRule.properties).length > 0) {
      // Resolve variables in properties
      const resolvedProps = this.resolveVariablesInProperties(
        lessRule.properties,
        scopeChain
      );
      
      rules.push({
        selector: fullSelector,
        properties: resolvedProps,
        specificity: this.calculateSpecificity(fullSelector),
        mediaQuery: mediaQuery || null,
        ruleOrder: order,
        sourceLineNumber: lessRule.lineNumber
      });
      
      order++;
    }
    
    return { rules, nextOrder: order };
  }

  private buildSelector(parent: string, current: string): string {
    if (!parent) return current;
    
    // Handle & which means "parent selector"
    if (current.includes('&')) {
      return current.replace(/&/g, parent);
    }
    
    // Default: descendant selector (space means descendant in CSS)
    return `${parent} ${current}`;
  }

  private resolveVariablesInProperties(
    properties: Record<string, string>,
    scopeChain: string[]
  ): Record<string, string> {
    const resolved: Record<string, string> = {};
    
    for (const [key, value] of Object.entries(properties)) {
      resolved[key] = this.resolveValue(value, scopeChain);
    }
    
    return resolved;
  }

  private resolveValue(value: string, scopeChain: string[]): string {
    // Iteratively resolve @variable references
    let result = value;
    let iterations = 0;
    const maxIterations = 10;
    
    while (result.includes('@') && iterations < maxIterations) {
      const nextResult = result.replace(/@([\w-]+)/g, (match, varName) => {
        // Search scope chain for variable
        for (const fileId of scopeChain) {
          const variable = database.query(
            `SELECT resolved_value FROM variables 
             WHERE name = $1 AND file_id = $2`,
            [varName, fileId]
          );
          
          if (variable) {
            return variable.resolved_value;
          }
        }
        
        // Variable not found, keep the reference
        return match;
      });
      
      if (nextResult === result) break; // No more substitutions
      result = nextResult;
      iterations++;
    }
    
    return result;
  }

  private calculateSpecificity(selector: string): [number, number, number] {
    let ids = 0, classes = 0, elements = 0;
    
    // Split by combinators (>, +, ~, space) - they don't count for specificity
    const parts = selector.split(/[\s>+~]+/).filter(p => p.trim());
    
    for (const part of parts) {
      // Count #id
      ids += (part.match(/#/g) || []).length;
      
      // Count .class, [attributes], and :pseudo-classes
      classes += (part.match(/\./g) || []).length;
      classes += (part.match(/\[[^\]]*\]/g) || []).length;
      classes += (part.match(/:[^:]/g) || []).length; // :hover, :focus (not ::before)
      
      // Count elements (what's left)
      const withoutSpecial = part
        .replace(/#[a-zA-Z0-9_-]+/g, '')
        .replace(/\.[a-zA-Z0-9_-]+/g, '')
        .replace(/\[[^\]]*\]/g, '')
        .replace(/:[a-zA-Z0-9_-]+/g, '');
      
      elements += (withoutSpecial.match(/^[a-z]+/gi) || []).length;
    }
    
    return [ids, classes, elements];
  }

  private parseToAST(content: string): LessAST {
    // Use less.js parser or similar
    // Returns AST with nested structure intact
    // Implementation: use 'less' npm package parser
    return parseLess(content);
  }
}
```

---

### Variable Resolver Service

```typescript
// src/services/variableResolverService.ts

export class VariableResolverService {
  async resolveInRule(
    rule: LessRule,
    fileId: string,
    scopeChain: string[]
  ): Promise<Record<string, string>> {
    const resolved: Record<string, string> = {};
    
    for (const [key, value] of Object.entries(rule.properties || {})) {
      resolved[key] = await this.resolveValue(value, scopeChain);
    }
    
    return resolved;
  }

  private async resolveValue(value: string, scopeChain: string[]): Promise<string> {
    // Extract all @variable references
    const refs = this.extractVariableReferences(value);
    
    let result = value;
    for (const varName of refs) {
      const resolvedVar = await this.findVariable(varName, scopeChain);
      if (resolvedVar) {
        result = result.replace(
          new RegExp(`@${varName}\\b`, 'g'),
          resolvedVar.resolved_value
        );
      }
    }
    
    return result;
  }

  private async findVariable(
    name: string,
    scopeChain: string[]
  ): Promise<Variable | null> {
    // Search through scope chain (highest priority first)
    for (const fileId of scopeChain) {
      const variable = await database.query(
        `SELECT * FROM variables WHERE name = $1 AND file_id = $2`,
        [name, fileId]
      );
      
      if (variable?.rows.length > 0) {
        return variable.rows[0];
      }
    }
    
    return null;
  }

  private extractVariableReferences(value: string): string[] {
    const refs: string[] = [];
    const regex = /@([\w-]+)/g;
    let match;
    
    while ((match = regex.exec(value)) !== null) {
      refs.push(match[1]);
    }
    
    return refs;
  }
}
```

---

## Handling Special LESS Constructs

### 1. LESS Mixins in Rules

When a rule calls a mixin, expand it inline:

```less
// LESS:
.padding-reset() {
  margin: 0;
  padding: 0;
}

.button {
  .padding-reset();
  color: blue;
}

// Becomes in database:
// selector: ".button"
// properties: { margin: "0", padding: "0", color: "blue" }
```

```typescript
private expandMixins(
  properties: Record<string, any>,
  fileId: string
): Record<string, string> {
  const expanded: Record<string, string> = {};
  
  for (const [key, value] of Object.entries(properties)) {
    if (typeof value === 'string') {
      expanded[key] = value;
    } else if (typeof value === 'object' && value.isMixin) {
      // Recursively expand mixin
      const mixinProps = database.query(
        'SELECT properties FROM mixins WHERE name = $1',
        [value.name]
      );
      
      Object.assign(expanded, this.expandMixins(mixinProps, fileId));
    }
  }
  
  return expanded;
}
```

### 2. LESS Conditionals (@if guards)

LESS supports `when` guards - we'll simplify by evaluating as true:

```less
.button when (@enable-buttons = true) {
  display: block;
}
```

**Strategy:** If variable is "truthy", include rule. Otherwise skip.

```typescript
private evaluateGuard(guardCondition: string, scopeChain: string[]): boolean {
  // Very simplified: just check if variables resolve to truthy
  // For production, would need full expression evaluator
  if (!guardCondition) return true; // No guard = always true
  
  // Extract variable from guard
  const match = guardCondition.match(/@([\w-]+)/);
  if (!match) return true;
  
  const varName = match[1];
  const variable = this.findVariable(varName, scopeChain);
  
  // Check if value is truthy
  if (!variable) return false;
  
  const value = variable.resolved_value;
  return value !== 'false' && value !== '0' && value !== 'null';
}
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] `less_rules` table created with all columns
- [ ] Indexes created for Stage 9 matching performance
- [ ] LESS nesting expanded correctly (`.parent { .child {...} }` → `.parent .child`)
- [ ] & references resolved (`.button { &:hover {...} }` → `.button:hover`)
- [ ] Variables resolved before storage (properties have actual values, not @refs)
- [ ] CSS specificity calculated correctly for all selector types
- [ ] Rule order tracked (later rules override earlier)
- [ ] @media queries captured separately
- [ ] Mixins expanded inline into properties
- [ ] Source line numbers stored for auditing
- [ ] All rules inserted into database with correct structure
- [ ] Can query rules by selector for Stage 9 matching
- [ ] Can filter rules by media query + viewport
- [ ] Can retrieve rules in cascade order (specificity + order)
- [ ] Tests passing (>80% coverage)

---

## Success Verification

1. **Compile test file:**
   ```typescript
   const compiled = await compiler.compileFile(fileId, versionId, scopeChain);
   console.log(compiled[0]); // { selector: ".header", properties: {...} }
   ```

2. **Check database:**
   ```sql
   SELECT selector, properties, specificity_a, specificity_b, specificity_c 
   FROM less_rules 
   ORDER BY rule_order;
   ```

3. **Verify specificity:**
   ```sql
   SELECT selector, specificity_a, specificity_b, specificity_c 
   FROM less_rules 
   WHERE selector IN ('#id', '.class', 'div', '.class:hover')
   -- Should show: (1,0,0), (0,1,0), (0,0,1), (0,2,0)
   ```

4. **Test cascade order:**
   ```sql
   SELECT selector FROM less_rules 
   WHERE selector = '.button'
   ORDER BY specificity_a DESC, specificity_b DESC, rule_order DESC;
   -- Returns winning rule first
   ```

---

**Next Stage:** When Stage 4 passes, proceed to [Stage 5: Variable Extraction](./05_TAILWIND_EXPORT.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
