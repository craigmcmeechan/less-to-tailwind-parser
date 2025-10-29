# STAGE 3: IMPORT HIERARCHY RESOLUTION

**Duration:** 1.5 weeks  
**Status:** ⏳ Ready (after Stage 2 complete)  
**Dependencies:** Stage 2 (LESS File Scanning)  
**Enables:** Stage 4 (Variable Extraction)

---

## Overview

Stage 3 analyzes `@import` statements within scanned LESS files to build a complete dependency graph. This creates a hierarchical map of how files depend on each other, enabling accurate variable scope resolution in later stages.

**Key Deliverable:** Complete import dependency graph with cycle detection and scope hierarchy.

---

## Objectives

1. ✅ Parse `@import` statements from LESS files
2. ✅ Resolve relative paths from importing file's directory
3. ✅ Handle commented-out imports (track but mark as inactive)
4. ✅ Build bidirectional dependency graph (imports + imported-by)
5. ✅ Detect circular import dependencies
6. ✅ Establish import order (topological sort)
7. ✅ Track import specificity (direct vs transitive)
8. ✅ Create variable scope hierarchy
9. ✅ Handle missing/unresolved imports gracefully
10. ✅ CLI commands for dependency visualization

---

## Database Schema

### 1. `import_statements` - Raw Imports

```sql
CREATE TABLE import_statements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL,
  file_version_id UUID NOT NULL,
  
  -- Import metadata
  import_line_number INTEGER NOT NULL,
  import_statement TEXT NOT NULL, -- Full @import line
  import_path VARCHAR(2048) NOT NULL, -- Relative path from @import
  
  -- Resolution
  resolved_file_id UUID, -- NULL if unresolved
  is_commented_out BOOLEAN DEFAULT false,
  is_resolved BOOLEAN DEFAULT false,
  resolution_error TEXT,
  
  -- Import type
  import_type VARCHAR(50), -- 'less', 'css', 'url', 'unknown'
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (file_version_id) REFERENCES file_versions(id) ON DELETE CASCADE,
  FOREIGN KEY (resolved_file_id) REFERENCES scanned_files(id)
);

CREATE INDEX idx_imports_file ON import_statements(file_id);
CREATE INDEX idx_imports_resolved ON import_statements(resolved_file_id);
CREATE INDEX idx_imports_unresolved ON import_statements(is_resolved) WHERE NOT is_resolved;
```

---

### 2. `import_dependencies` - Resolved Graph

```sql
CREATE TABLE import_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Dependency relationship
  importing_file_id UUID NOT NULL, -- File that has @import
  imported_file_id UUID NOT NULL,  -- File being imported
  
  -- Depth tracking
  import_order INTEGER, -- 1 = direct, 2 = one level deep, etc.
  is_direct BOOLEAN DEFAULT true,
  is_transitive BOOLEAN DEFAULT false,
  
  -- Circularity detection
  creates_cycle BOOLEAN DEFAULT false,
  cycle_path TEXT, -- JSON array of file IDs in cycle
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (importing_file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (imported_file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  UNIQUE(importing_file_id, imported_file_id)
);

CREATE INDEX idx_deps_importer ON import_dependencies(importing_file_id);
CREATE INDEX idx_deps_imported ON import_dependencies(imported_file_id);
CREATE INDEX idx_deps_cycles ON import_dependencies(creates_cycle) WHERE creates_cycle;
```

---

### 3. `import_scope_hierarchy` - Variable Scopes

```sql
CREATE TABLE import_scope_hierarchy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Scope level
  file_id UUID NOT NULL,
  
  -- Parent scope (file whose variables are inherited)
  parent_file_id UUID,
  
  -- Depth in hierarchy
  scope_depth INTEGER DEFAULT 0,
  
  -- Scope resolution order (for variable lookup)
  scope_chain TEXT NOT NULL, -- JSON array of file IDs in precedence order
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_file_id) REFERENCES scanned_files(id)
);

CREATE INDEX idx_scope_file ON import_scope_hierarchy(file_id);
CREATE INDEX idx_scope_parent ON import_scope_hierarchy(parent_file_id);
```

---

## Core Services

### ImportResolverService

```typescript
// src/services/importResolverService.ts

export class ImportResolverService {
  async resolveImportsForFile(
    fileId: string, 
    versionId: string
  ): Promise<ImportResolutionResult> {
    const scannedFile = await getScannedFile(fileId);
    const version = await getFileVersion(versionId);
    
    const result: ImportResolutionResult = {
      fileId,
      versionId,
      imports: [],
      unresolved: [],
      errors: []
    };
    
    // Extract @import statements
    const imports = this.extractImports(version.content);
    
    for (let i = 0; i < imports.length; i++) {
      const imp = imports[i];
      
      try {
        const resolved = await this.resolveImportPath(
          imp.path,
          scannedFile.file_path,
          imp.isCommented
        );
        
        if (resolved) {
          await createImportStatement({
            file_id: fileId,
            file_version_id: versionId,
            import_line_number: imp.lineNumber,
            import_statement: imp.statement,
            import_path: imp.path,
            resolved_file_id: resolved.fileId,
            is_commented_out: imp.isCommented,
            is_resolved: true,
            import_type: resolved.type
          });
          
          result.imports.push({
            path: imp.path,
            resolvedFileId: resolved.fileId,
            isCommented: imp.isCommented
          });
        } else {
          await createImportStatement({
            file_id: fileId,
            file_version_id: versionId,
            import_line_number: imp.lineNumber,
            import_statement: imp.statement,
            import_path: imp.path,
            is_resolved: false,
            resolution_error: 'File not found'
          });
          
          result.unresolved.push({
            path: imp.path,
            lineNumber: imp.lineNumber
          });
        }
      } catch (error) {
        result.errors.push({
          path: imp.path,
          error: error.message
        });
      }
    }
    
    return result;
  }

  private extractImports(content: string): ImportMatch[] {
    const imports: ImportMatch[] = [];
    
    // Match @import statements (including commented)
    const importRegex = /(\/\/)?\s*@import\s+['\"]([^'\"]+)['\"]/gm;
    let match;
    
    let lineNumber = 1;
    const lines = content.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineMatch = /(\/\/)?\s*@import\s+['\"]([^'\"]+)['\"]/g.exec(line);
      
      if (lineMatch) {
        imports.push({
          statement: lineMatch[0],
          path: lineMatch[2],
          isCommented: !!lineMatch[1],
          lineNumber: i + 1
        });
      }
    }
    
    return imports;
  }

  private async resolveImportPath(
    importPath: string,
    fromFilePath: string,
    isCommented: boolean
  ): Promise<ResolvedImport | null> {
    const fromDir = path.dirname(fromFilePath);
    
    // Handle various import formats
    if (importPath.startsWith('http')) {
      return { type: 'url', fileId: null };
    }
    
    // Resolve relative path
    let resolvedPath = path.resolve(fromDir, importPath);
    
    // Try variations
    const candidates = [
      resolvedPath,
      `${resolvedPath}.less`,
      path.join(path.dirname(resolvedPath), `_${path.basename(resolvedPath)}`),
      path.join(path.dirname(resolvedPath), `_${path.basename(resolvedPath)}.less`)
    ];
    
    for (const candidate of candidates) {
      const scanned = await getScannedFileByPath(candidate);
      if (scanned && !scanned.deleted_at) {
        return {
          type: 'less',
          fileId: scanned.id
        };
      }
    }
    
    return null;
  }
}
```

---

### DependencyGraphBuilder

```typescript
// src/services/dependencyGraphBuilder.ts

export class DependencyGraphBuilder {
  async buildGraph(fileIds: string[]): Promise<DependencyGraph> {
    const graph = new Map<string, Set<string>>();
    const visited = new Set<string>();
    const cycles: string[][] = [];
    
    // Build adjacency list
    for (const fileId of fileIds) {
      const deps = await getImportDependencies(fileId);
      graph.set(fileId, new Set(deps));
    }
    
    // Detect cycles using DFS
    for (const fileId of fileIds) {
      await this.detectCycles(fileId, new Set(), [], graph, cycles);
    }
    
    // Store cycles in database
    for (const cycle of cycles) {
      for (let i = 0; i < cycle.length; i++) {
        const from = cycle[i];
        const to = cycle[(i + 1) % cycle.length];
        
        await updateDependency(from, to, {
          creates_cycle: true,
          cycle_path: JSON.stringify(cycle)
        });
      }
    }
    
    return {
      vertices: fileIds,
      edges: graph,
      cycles,
      topologicalSort: this.topologicalSort(graph, cycles)
    };
  }

  private async detectCycles(
    node: string,
    visited: Set<string>,
    path: string[],
    graph: Map<string, Set<string>>,
    cycles: string[][]
  ): Promise<void> {
    if (path.includes(node)) {
      const cycleStart = path.indexOf(node);
      cycles.push(path.slice(cycleStart).concat(node));
      return;
    }
    
    if (visited.has(node)) return;
    
    visited.add(node);
    const neighbors = graph.get(node) || new Set();
    
    for (const neighbor of neighbors) {
      await this.detectCycles(
        neighbor,
        visited,
        [...path, node],
        graph,
        cycles
      );
    }
  }

  private topologicalSort(
    graph: Map<string, Set<string>>,
    cycles: string[][]
  ): string[] {
    // Kahn's algorithm - returns ordering for non-cyclic dependencies
    const result: string[] = [];
    const inDegree = new Map<string, number>();
    const queue: string[] = [];
    
    // Calculate in-degrees
    for (const [node, neighbors] of graph) {
      if (!inDegree.has(node)) inDegree.set(node, 0);
      for (const neighbor of neighbors) {
        inDegree.set(neighbor, (inDegree.get(neighbor) || 0) + 1);
      }
    }
    
    // Find all nodes with in-degree 0
    for (const [node, degree] of inDegree) {
      if (degree === 0) queue.push(node);
    }
    
    while (queue.length > 0) {
      const node = queue.shift()!;
      result.push(node);
      
      for (const neighbor of graph.get(node) || []) {
        inDegree.set(neighbor, inDegree.get(neighbor)! - 1);
        if (inDegree.get(neighbor) === 0) {
          queue.push(neighbor);
        }
      }
    }
    
    return result;
  }
}
```

---

### ScopeHierarchyBuilder

```typescript
// src/services/scopeHierarchyBuilder.ts

export class ScopeHierarchyBuilder {
  async buildScopeHierarchy(fileIds: string[]): Promise<void> {
    for (const fileId of fileIds) {
      const scopeChain = await this.computeScopeChain(fileId);
      
      await createScopeHierarchy({
        file_id: fileId,
        scope_chain: JSON.stringify(scopeChain),
        scope_depth: scopeChain.length - 1
      });
    }
  }

  private async computeScopeChain(fileId: string): Promise<string[]> {
    const chain = [fileId]; // Own scope first (highest priority)
    const visited = new Set<string>([fileId]);
    const queue: string[] = [fileId];
    
    // BFS through imports to build scope visibility
    while (queue.length > 0) {
      const current = queue.shift()!;
      const imports = await getDirectImports(current);
      
      for (const imp of imports) {
        if (!visited.has(imp.resolved_file_id)) {
          visited.add(imp.resolved_file_id);
          chain.push(imp.resolved_file_id);
          queue.push(imp.resolved_file_id);
        }
      }
    }
    
    return chain;
  }
}
```

---

## CLI Commands

### `npm run import:resolve [profile]` - Resolve Imports

```bash
npm run import:resolve production

# Output:
# Resolving imports for profile: production
# ✓ 1,243 imports resolved
# ✗ 12 unresolved (files not found)
# ⚠ 2 circular dependencies detected
```

### `npm run import:graph [file]` - Visualize Dependency Graph

```bash
npm run import:graph variables.less

# Output:
# Dependency Graph: variables.less
# 
# ├── mixins.less
# ├── colors.less
# │   └── config.less
# └── typography.less
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] `import_statements` table captures all @import lines
- [ ] Relative paths resolved correctly from importing file's directory
- [ ] Commented-out imports tracked separately
- [ ] Unresolved imports logged without breaking process
- [ ] Circular imports detected and flagged
- [ ] `import_dependencies` table built correctly
- [ ] Direct vs transitive imports distinguished
- [ ] Topological sort returns valid ordering
- [ ] Scope hierarchy computed for all files
- [ ] Variable lookup order matches scope chain
- [ ] CLI commands working: import:resolve, import:graph
- [ ] Tests passing (>80% coverage)
- [ ] Error handling per ERROR_HANDLING.md

---

**Next Stage:** When Stage 3 passes, proceed to [Stage 4: Variable Extraction](./04_VARIABLE_EXTRACTION.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
