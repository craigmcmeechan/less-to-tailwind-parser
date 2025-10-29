# STAGE 4: VARIABLE EXTRACTION & SCOPE RESOLUTION

**Duration:** 2 weeks  
**Status:** ⏳ Ready (after Stage 3 complete)  
**Dependencies:** Stage 3 (Import Hierarchy)  
**Enables:** Stage 5 (Tailwind Export)

---

## Overview

Stage 4 extracts LESS variables, mixins, and functions from source files and resolves their scope based on the import hierarchy. This creates a queryable map of all CSS-in-variables across the codebase.

**Key Deliverable:** Complete variable catalog with scope resolution and override tracking.

---

## Objectives

1. ✅ Extract `@variable` declarations
2. ✅ Extract `@mixin` definitions with parameters
3. ✅ Extract `@function` definitions
4. ✅ Resolve variable scope using import hierarchy
5. ✅ Track variable overrides across files
6. ✅ Detect variable usage patterns
7. ✅ Handle nested/scoped variables
8. ✅ Build variable dependency graph
9. ✅ Classify variables by Tailwind category
10. ✅ CLI commands for variable inspection

---

## Database Schema

### 1. `variables` - Variable Declarations

```sql
CREATE TABLE variables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Variable metadata
  name VARCHAR(255) NOT NULL,
  file_id UUID NOT NULL,
  file_version_id UUID NOT NULL,
  line_number INTEGER NOT NULL,
  
  -- Variable type
  variable_type VARCHAR(50), -- 'color', 'size', 'spacing', 'font', 'shadow', 'other'
  
  -- Raw value
  raw_value TEXT NOT NULL,
  resolved_value TEXT, -- Computed value (variables substituted)
  
  -- Scope
  scope_chain TEXT, -- JSON: [file_ids] for lookup order
  
  -- Override tracking
  is_override BOOLEAN DEFAULT false,
  overrides_variable_id UUID,
  overridden_by_variable_id UUID,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (file_version_id) REFERENCES file_versions(id) ON DELETE CASCADE,
  FOREIGN KEY (overrides_variable_id) REFERENCES variables(id)
);

CREATE INDEX idx_variables_name ON variables(name);
CREATE INDEX idx_variables_file ON variables(file_id);
CREATE INDEX idx_variables_type ON variables(variable_type);
CREATE UNIQUE INDEX idx_variables_scope ON variables(name, file_id);
```

---

### 2. `mixins` - Mixin Definitions

```sql
CREATE TABLE mixins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Mixin metadata
  name VARCHAR(255) NOT NULL,
  file_id UUID NOT NULL,
  file_version_id UUID NOT NULL,
  line_number INTEGER NOT NULL,
  
  -- Signature
  parameters TEXT, -- JSON: [{ name, default, type }]
  body TEXT NOT NULL,
  
  -- Scope
  scope_chain TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (file_version_id) REFERENCES file_versions(id) ON DELETE CASCADE
);

CREATE INDEX idx_mixins_name ON mixins(name);
CREATE INDEX idx_mixins_file ON mixins(file_id);
```

---

### 3. `functions` - Function Definitions

```sql
CREATE TABLE functions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Function metadata
  name VARCHAR(255) NOT NULL,
  file_id UUID NOT NULL,
  file_version_id UUID NOT NULL,
  line_number INTEGER NOT NULL,
  
  -- Signature
  parameters TEXT, -- JSON array
  return_type VARCHAR(100),
  body TEXT NOT NULL,
  
  -- Scope
  scope_chain TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (file_version_id) REFERENCES file_versions(id) ON DELETE CASCADE
);

CREATE INDEX idx_functions_name ON functions(name);
CREATE INDEX idx_functions_file ON functions(file_id);
```

---

### 4. `variable_dependencies` - Usage Graph

```sql
CREATE TABLE variable_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Dependency
  source_variable_id UUID NOT NULL,
  dependent_variable_id UUID,
  dependent_mixin_id UUID,
  
  -- Context
  in_file_id UUID NOT NULL,
  line_number INTEGER,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (source_variable_id) REFERENCES variables(id) ON DELETE CASCADE,
  FOREIGN KEY (dependent_variable_id) REFERENCES variables(id),
  FOREIGN KEY (dependent_mixin_id) REFERENCES mixins(id),
  FOREIGN KEY (in_file_id) REFERENCES scanned_files(id)
);

CREATE INDEX idx_var_deps_source ON variable_dependencies(source_variable_id);
CREATE INDEX idx_var_deps_dependent ON variable_dependencies(dependent_variable_id);
```

---

### 5. `variable_classifications` - Tailwind Mapping

```sql
CREATE TABLE variable_classifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Variable
  variable_id UUID NOT NULL,
  
  -- Tailwind category
  tailwind_category VARCHAR(100), -- 'colors', 'spacing', 'fontSize', etc
  tailwind_key VARCHAR(255), -- e.g., 'primary', 'lg', 'md'
  confidence FLOAT, -- 0-1 confidence score
  
  -- Classification metadata
  classification_method VARCHAR(100), -- 'regex', 'manual', 'heuristic'
  notes TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (variable_id) REFERENCES variables(id) ON DELETE CASCADE
);

CREATE INDEX idx_classifications_category ON variable_classifications(tailwind_category);
CREATE INDEX idx_classifications_var ON variable_classifications(variable_id);
```

---

## Core Services

### VariableExtractorService

```typescript
// src/services/variableExtractorService.ts

export class VariableExtractorService {
  async extractVariablesFromFile(
    fileId: string,
    versionId: string,
    scopeChain: string[]
  ): Promise<ExtractedVariables> {
    const version = await getFileVersion(versionId);
    const result: ExtractedVariables = {
      variables: [],
      mixins: [],
      functions: []
    };
    
    // Extract variables
    const varMatches = this.extractVariableDeclarations(version.content);
    for (const match of varMatches) {
      const variable = await createVariable({
        name: match.name,
        file_id: fileId,
        file_version_id: versionId,
        line_number: match.lineNumber,
        variable_type: this.classifyVariableType(match.name, match.value),
        raw_value: match.value,
        scope_chain: JSON.stringify(scopeChain)
      });
      result.variables.push(variable);
    }
    
    // Extract mixins
    const mixinMatches = this.extractMixins(version.content);
    for (const match of mixinMatches) {
      const mixin = await createMixin({
        name: match.name,
        file_id: fileId,
        file_version_id: versionId,
        line_number: match.lineNumber,
        parameters: JSON.stringify(match.parameters),
        body: match.body,
        scope_chain: JSON.stringify(scopeChain)
      });
      result.mixins.push(mixin);
    }
    
    // Extract functions
    const funcMatches = this.extractFunctions(version.content);
    for (const match of funcMatches) {
      const func = await createFunction({
        name: match.name,
        file_id: fileId,
        file_version_id: versionId,
        line_number: match.lineNumber,
        parameters: JSON.stringify(match.parameters),
        body: match.body,
        scope_chain: JSON.stringify(scopeChain)
      });
      result.functions.push(func);
    }
    
    return result;
  }

  private extractVariableDeclarations(content: string): VariableMatch[] {
    const matches: VariableMatch[] = [];
    
    // Match @variable: value; patterns
    const regex = /@([\w-]+)\s*:\s*([^;]+);/gm;
    const lines = content.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      let match;
      
      while ((match = regex.exec(line)) !== null) {
        matches.push({
          name: match[1],
          value: match[2].trim(),
          lineNumber: i + 1
        });
      }
      
      regex.lastIndex = 0;
    }
    
    return matches;
  }

  private extractMixins(content: string): MixinMatch[] {
    const matches: MixinMatch[] = [];
    
    // Match .mixin-name(params) { body }
    const regex = /\.([\w-]+)\s*\(([^)]*)\)\s*\{([^}]+)\}/gm;
    const lines = content.split('\n');
    let lineNum = 1;
    
    for (const line of lines) {
      let match;
      while ((match = regex.exec(line)) !== null) {
        const paramStr = match[2].trim();
        const parameters = paramStr
          ? paramStr.split(',').map(p => {
              const parts = p.trim().split(/:\s*/);
              return { name: parts[0], default: parts[1] };
            })
          : [];
        
        matches.push({
          name: match[1],
          parameters,
          body: match[3],
          lineNumber: lineNum
        });
      }
      regex.lastIndex = 0;
      lineNum++;
    }
    
    return matches;
  }

  private extractFunctions(content: string): FunctionMatch[] {
    // Similar to extractMixins but for @function syntax
    // Implementation follows same pattern
    return [];
  }

  private classifyVariableType(
    name: string,
    value: string
  ): string {
    const lower = `${name} ${value}`.toLowerCase();
    
    if (lower.includes('color') || /^#|^rgb|^hsl/.test(value)) return 'color';
    if (lower.includes('size') || /^[\d.]+[a-z]+$/.test(value)) return 'size';
    if (lower.includes('spacing') || /^[\d.]+[a-z]+$/.test(value)) return 'spacing';
    if (lower.includes('font')) return 'font';
    if (lower.includes('shadow')) return 'shadow';
    
    return 'other';
  }
}
```

---

### VariableScopeResolver

```typescript
// src/services/variableScopeResolver.ts

export class VariableScopeResolver {
  async resolveVariableScope(
    variableName: string,
    lookupChain: string[]
  ): Promise<ResolvedVariable | null> {
    // Search through scope chain in order (highest priority first)
    for (const fileId of lookupChain) {
      const variable = await getVariableByNameInFile(variableName, fileId);
      
      if (variable) {
        // Check for overrides
        const resolved = await this.resolveValue(variable);
        return {
          ...variable,
          resolved_value: resolved,
          resolvedInFile: fileId
        };
      }
    }
    
    return null;
  }

  private async resolveValue(variable: Variable): Promise<string> {
    let value = variable.raw_value;
    let iterations = 0;
    const maxIterations = 10; // Prevent infinite loops
    
    // Recursively substitute variable references
    while (iterations < maxIterations) {
      const refs = this.extractVariableReferences(value);
      if (refs.length === 0) break;
      
      let changed = false;
      for (const ref of refs) {
        const resolved = await this.resolveVariableScope(ref, [variable.file_id]);
        if (resolved) {
          value = value.replace(`@${ref}`, resolved.resolved_value);
          changed = true;
        }
      }
      
      if (!changed) break;
      iterations++;
    }
    
    return value;
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

### VariableClassifier

```typescript
// src/services/variableClassifier.ts

export class VariableClassifier {
  async classifyForTailwind(
    variableId: string,
    name: string,
    value: string
  ): Promise<TailwindClassification> {
    const patterns = [
      { category: 'colors', pattern: /color|shade|palette/i, confidence: 0.9 },
      { category: 'spacing', pattern: /spacing|margin|padding|gap/i, confidence: 0.85 },
      { category: 'fontSize', pattern: /font-?size|text/i, confidence: 0.8 },
      { category: 'fontWeight', pattern: /font-?weight|bold|regular/i, confidence: 0.8 },
      { category: 'borderRadius', pattern: /radius|rounded/i, confidence: 0.8 },
      { category: 'boxShadow', pattern: /shadow/i, confidence: 0.9 },
      { category: 'opacity', pattern: /opacity|alpha/i, confidence: 0.8 }
    ];
    
    let bestMatch = { category: 'other', confidence: 0 };
    
    for (const pattern of patterns) {
      if (pattern.pattern.test(name) || pattern.pattern.test(value)) {
        if (pattern.confidence > bestMatch.confidence) {
          bestMatch = pattern;
        }
      }
    }
    
    // Extract Tailwind key
    const tailwindKey = this.extractTailwindKey(name, value, bestMatch.category);
    
    return {
      tailwind_category: bestMatch.category,
      tailwind_key: tailwindKey,
      confidence: bestMatch.confidence
    };
  }

  private extractTailwindKey(
    name: string,
    value: string,
    category: string
  ): string {
    // Remove common prefixes
    let key = name
      .replace(/^(color|font|bg|text|border|shadow|spacing)-?/, '')
      .replace(/^@/, '')
      .replace(/-/g, '');
    
    return key || 'default';
  }
}
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] `variables` table captures all @variable declarations
- [ ] `mixins` table captures all .mixin-name definitions
- [ ] Variable types classified correctly (color, spacing, etc)
- [ ] Scope chain computed using import hierarchy
- [ ] Variable overrides detected and tracked
- [ ] Nested/scoped variables handled correctly
- [ ] Variable dependencies mapped
- [ ] Circular variable references detected
- [ ] Tailwind classifications assigned with confidence scores
- [ ] CLI commands working: var:list, var:inspect, var:graph
- [ ] Resolved values computed correctly (variables substituted)
- [ ] Tests passing (>80% coverage)
- [ ] Error handling per ERROR_HANDLING.md

---

**Next Stage:** When Stage 4 passes, proceed to [Stage 5: Tailwind Export](./05_TAILWIND_EXPORT.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
