# STAGE 7: TESTING, VALIDATION & RELEASE

**Duration:** 1.5 weeks  
**Status:** ⏳ Ready (after Stage 6 complete)  
**Dependencies:** All previous stages  
**Enables:** Production deployment and public release

---

## Overview

Stage 7 establishes comprehensive testing, validation, and release procedures to ensure the parser is production-ready, performant, and maintainable.

**Key Deliverable:** Test suite, performance benchmarks, and release checklist.

---

## Objectives

1. ✅ Unit test coverage >90% across all services
2. ✅ Integration tests for complete pipelines
3. ✅ End-to-end tests with real LESS files
4. ✅ Performance benchmarking and optimization
5. ✅ Memory leak detection
6. ✅ Database schema validation
7. ✅ API contract testing
8. ✅ Security audit and hardening
9. ✅ Documentation completeness review
10. ✅ Release automation (versioning, changelog, deployment)

---

## Testing Strategy

### Unit Tests

```typescript
// tests/unit/variableExtractorService.test.ts

describe('VariableExtractorService', () => {
  it('should extract simple variable declarations', async () => {
    const content = '@primary-color: #ff0000;';
    const service = new VariableExtractorService();
    
    const result = service['extractVariableDeclarations'](content);
    
    expect(result).toHaveLength(1);
    expect(result[0]).toEqual({
      name: 'primary-color',
      value: '#ff0000',
      lineNumber: 1
    });
  });

  it('should handle nested variables', async () => {
    const content = `
      @base: 10px;
      @double: @base * 2;
    `;
    
    const result = service['extractVariableDeclarations'](content);
    expect(result).toHaveLength(2);
  });

  it('should classify variable types correctly', () => {
    expect(service['classifyVariableType']('primary-color', '#ff0000')).toBe('color');
    expect(service['classifyVariableType']('base-spacing', '8px')).toBe('spacing');
    expect(service['classifyVariableType']('font-family', 'Arial')).toBe('font');
  });
});
```

---

### Integration Tests

```typescript
// tests/integration/fullPipeline.test.ts

describe('Full Pipeline Integration', () => {
  it('should process LESS files end-to-end', async () => {
    const testDir = './test-fixtures/sample-project';
    
    // Create test profile
    const profile = await createTestProfile(testDir);
    
    // Run full pipeline
    const orchestration = new OrchestrationService();
    const result = await orchestration.runFullPipeline(profile.id);
    
    expect(result.success).toBe(true);
    expect(result.stages).toHaveLength(4); // Stages 2-5
    
    // Verify outputs
    const config = await getGeneratedConfig(profile.id);
    expect(config).toBeDefined();
    expect(config.theme.extend.colors).toBeDefined();
  });

  it('should detect circular imports', async () => {
    const testDir = './test-fixtures/circular-imports';
    const profile = await createTestProfile(testDir);
    
    const result = await new ImportResolverService()
      .resolveImportsForFile(testFileId, testVersionId);
    
    const cycles = await getCycles(profile.id);
    expect(cycles.length).toBeGreaterThan(0);
  });

  it('should handle missing imports gracefully', async () => {
    const testDir = './test-fixtures/missing-imports';
    const profile = await createTestProfile(testDir);
    
    const result = await orchestration.runFullPipeline(profile.id);
    
    expect(result.success).toBe(true); // Should not fail
    expect(result.stages[2].result.importsUnresolved).toBeGreaterThan(0);
  });
});
```

---

### Performance Tests

```typescript
// tests/performance/benchmarks.test.ts

describe('Performance Benchmarks', () => {
  it('should scan 1000 LESS files within timeout', async () => {
    const startTime = Date.now();
    
    const result = await scanService.scanProfile(largeProfileId);
    
    const duration = Date.now() - startTime;
    expect(duration).toBeLessThan(30000); // 30 seconds max
    
    console.log(`Scanned 1000 files in ${duration}ms`);
  });

  it('should not exceed memory limit during large scan', async () => {
    const startMemory = process.memoryUsage().heapUsed;
    
    await orchestration.runFullPipeline(largeProfileId);
    
    const endMemory = process.memoryUsage().heapUsed;
    const memoryIncrease = (endMemory - startMemory) / 1024 / 1024; // MB
    
    expect(memoryIncrease).toBeLessThan(500); // Max 500MB increase
  });

  it('should generate Tailwind config in <1s', async () => {
    const startTime = Date.now();
    
    await new TailwindConfigBuilder().buildConfig(profileId);
    
    const duration = Date.now() - startTime;
    expect(duration).toBeLessThan(1000);
  });
});
```

---

### Test Data Fixtures

```
tests/fixtures/
├── sample-project/
│   ├── variables.less
│   ├── colors.less
│   ├── mixins.less
│   └── main.less
├── circular-imports/
│   ├── a.less          @import "b.less"
│   └── b.less          @import "a.less"
├── missing-imports/
│   └── main.less       @import "nonexistent.less"
├── large-project/      (1000+ LESS files)
└── edge-cases/
    ├── commented-imports.less
    ├── nested-variables.less
    └── complex-mixins.less
```

---

## Quality Metrics

### Code Coverage

```bash
npm run test:coverage

# Target: >90% coverage across all services
# Critical paths: 100%

Coverage Summary:
├── Statements    : 94.2%
├── Branches      : 91.5%
├── Functions     : 93.8%
└── Lines         : 94.1%

Uncovered areas: 
└── Error edge cases in file I/O
```

---

### Performance Benchmarks

```
Scan Performance:
├── 100 files:     ~200ms
├── 1,000 files:   ~2.5s
├── 10,000 files:  ~28s

Export Performance:
├── Config generation:    <100ms
├── CSS generation:       <500ms
├── Validation:           <50ms

Memory Usage:
├── Baseline:    ~50MB
├── After scan:  ~150MB (100 files)
├── Peak:        ~300MB (1000 files)
```

---

## Security Audit

### Checklist

```
- [ ] SQL injection prevention (parameterized queries)
- [ ] Path traversal prevention (path validation)
- [ ] Environment variable handling
- [ ] Dependency vulnerability scan (npm audit)
- [ ] OWASP Top 10 coverage
- [ ] Input validation for all user inputs
- [ ] Error message sanitization
- [ ] Database credential handling
- [ ] API authentication/authorization
- [ ] Rate limiting for API endpoints
```

---

## Release Process

### Versioning (Semantic)

```
Version format: MAJOR.MINOR.PATCH

1.0.0-alpha       Initial development
1.0.0-beta        Feature complete
1.0.0             Stable release

Changes:
- MAJOR: Breaking changes (database schema changes)
- MINOR: New features (new stage, new CLI command)
- PATCH: Bug fixes (fixes to existing functionality)
```

---

### Release Checklist

```bash
# 1. Update version
npm version patch  # or minor/major

# 2. Run all tests
npm run test           # Unit tests
npm run test:integration  # Integration tests
npm run test:e2e      # End-to-end tests
npm run test:performance # Performance benchmarks

# 3. Quality checks
npm run lint          # ESLint
npm run type-check    # TypeScript
npm run test:coverage # Coverage >90%

# 4. Security audit
npm audit             # Check for vulnerabilities
npm audit fix         # Auto-fix if needed

# 5. Build
npm run build         # Compile TypeScript

# 6. Generate changelog
npm run changelog:generate

# 7. Git operations
git tag v1.0.0        # Tag release
git push origin --tags

# 8. Publish
npm publish           # To npm registry

# 9. Deploy
npm run deploy:prod   # Production deployment
```

---

### Changelog Template

```markdown
# [1.0.0] - 2025-11-15

## Added
- Stage 3: Import hierarchy resolution with cycle detection
- Stage 4: Variable extraction and scope resolution
- New CLI command: `less-parser export:tailwind`
- REST API endpoints for profile management

## Changed
- Improved scan performance by 40% with parallel processing
- Updated database schema for better indexing
- Refactored VariableExtractorService for clarity

## Fixed
- Fixed issue where circular imports caused infinite loops
- Corrected color palette generation for 50-900 shades
- Resolved memory leak in file watcher

## Deprecated
- Deprecated old config file format (migrate to new format)

## Security
- Added input validation for all CLI inputs
- Fixed SQL injection vulnerability in search endpoint
```

---

## Production Deployment

### Pre-flight Checks

```typescript
// src/cli/deploy.ts

export class PreflightChecker {
  async check(): Promise<void> {
    const checks = [
      this.checkDatabase(),
      this.checkFilesystem(),
      this.checkDependencies(),
      this.checkEnvironment(),
      this.checkPerformance()
    ];
    
    const results = await Promise.all(checks);
    
    if (results.every(r => r.passed)) {
      console.log('✓ All preflight checks passed');
    } else {
      const failures = results.filter(r => !r.passed);
      throw new Error(`Preflight checks failed:\n${failures.map(f => f.error).join('\n')}`);
    }
  }

  private async checkDatabase(): Promise<CheckResult> {
    try {
      await executeSQL('SELECT 1');
      const tables = await executeSQL(`
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public'
      `);
      
      return {
        passed: tables[0].count > 0,
        error: 'Database schema not initialized'
      };
    } catch (error) {
      return { passed: false, error: error.message };
    }
  }

  private async checkPerformance(): Promise<CheckResult> {
    const start = Date.now();
    await executeSQL('SELECT 1');
    const duration = Date.now() - start;
    
    return {
      passed: duration < 100,
      error: `Database query took ${duration}ms (expected <100ms)`
    };
  }
}
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] Unit test coverage >90%
- [ ] All integration tests passing
- [ ] Performance benchmarks within limits
- [ ] No memory leaks detected
- [ ] Security audit completed with 0 critical issues
- [ ] End-to-end tests with real LESS files passing
- [ ] Circular import detection working
- [ ] Missing import handling graceful
- [ ] Release automation scripts tested
- [ ] Documentation complete and accurate
- [ ] Changelog generated automatically
- [ ] Version bump working correctly
- [ ] npm publish process validated
- [ ] Production deployment checklist complete

---

## Post-Release

### Monitoring

```bash
# Monitor production metrics
npm run monitor:production

# Check for errors
npm run logs:errors --tail 1000

# Performance metrics
npm run metrics:performance
```

---

**Stages 8 & 9 (Extensions):** After Stage 7, optional advanced features available at [Stage 8: Chrome Extension](./08_CHROME_EXTENSION.md) and [Stage 9: DOM to Tailwind](./09_DOM_TO_TAILWIND.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
