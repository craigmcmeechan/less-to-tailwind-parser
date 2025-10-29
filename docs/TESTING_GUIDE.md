# TESTING GUIDE

This document defines testing standards and practices for all stages of the project. All code must be thoroughly tested with unit and integration tests before being merged.

## Table of Contents

1. [Testing Strategy](#testing-strategy)
2. [Jest Configuration](#jest-configuration)
3. [Unit Testing](#unit-testing)
4. [Integration Testing](#integration-testing)
5. [Test File Organization](#test-file-organization)
6. [Running Tests](#running-tests)
7. [Coverage Requirements](#coverage-requirements)
8. [Testing Best Practices](#testing-best-practices)

---

## Testing Strategy

### Test Pyramid

```
        /\
       /  \          Unit Tests (60-70%)
      /____\         Fast, isolated, many
      
      /\  /\
     /  \/  \        Integration Tests (20-30%)
    /________\       Slower, test interactions
    
    /\  /\  /\
   /  \/  \/  \      E2E Tests (10%)
  /__________\_/    Slow, full pipeline
```

### Coverage Goals

- **Overall:** ≥ 80% code coverage
- **Critical paths:** 100% coverage (database, parsing, exports)
- **Utils/helpers:** ≥ 75% coverage
- **Error handling:** 100% coverage (all error paths tested)

---

## Jest Configuration

### Installation

Already included in `package.json`. Ensure TypeScript support:

```bash
npm install --save-dev jest ts-jest @types/jest
```

### Configuration File: `jest.config.js`

```javascript
export default {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/index.ts' // Entry point, covered by E2E
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 80,
      lines: 80,
      statements: 80
    },
    './src/database/': {
      branches: 100,
      functions: 100,
      lines: 100,
      statements: 100
    },
    './src/services/': {
      branches: 85,
      functions: 85,
      lines: 85,
      statements: 85
    }
  },
  setupFilesAfterEnv: ['<rootDir>/src/__tests__/setup.ts'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', { useESM: true }]
  }
};
```

### Setup File: `src/__tests__/setup.ts`

```typescript
// Global test setup
import dotenv from 'dotenv';

// Load test environment variables
dotenv.config({ path: '.env.test' });

// Global timeout for tests
jest.setTimeout(10000);

// Suppress console output in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};
```

---

## Unit Testing

### Characteristics

- ✅ Test one function/method in isolation
- ✅ Mock external dependencies
- ✅ Fast execution (< 100ms per test)
- ✅ No database calls
- ✅ No file system access
- ✅ Deterministic (same input → same output)

### Example: Unit Test

```typescript
// src/utils/validators.test.ts
import { validateLessFilePath } from './validators';

describe('validators', () => {
  describe('validateLessFilePath', () => {
    it('should accept valid LESS file paths', () => {
      expect(validateLessFilePath('./styles/main.less')).toBe(true);
      expect(validateLessFilePath('/absolute/path/style.less')).toBe(true);
    });

    it('should reject non-LESS files', () => {
      expect(validateLessFilePath('./styles/main.css')).toBe(false);
      expect(validateLessFilePath('./styles/main.js')).toBe(false);
    });

    it('should reject null or empty paths', () => {
      expect(validateLessFilePath('')).toBe(false);
      expect(validateLessFilePath(null as any)).toBe(false);
    });

    it('should handle paths with spaces', () => {
      expect(validateLessFilePath('./my styles/main.less')).toBe(true);
    });
  });
});
```

### Mocking Example

```typescript
// src/services/lessService.test.ts
import * as fs from 'fs';
import { LessService } from './lessService';

jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('LessService', () => {
  let service: LessService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new LessService();
  });

  describe('scanLessFiles', () => {
    it('should recursively find LESS files', () => {
      // Mock fs functions
      mockFs.existsSync.mockReturnValue(true);
      mockFs.readdirSync.mockReturnValue([
        { name: 'main.less', isDirectory: () => false },
        { name: 'nested', isDirectory: () => true }
      ] as any);

      const result = service.scanLessFiles(['./styles']);

      expect(mockFs.existsSync).toHaveBeenCalled();
      expect(result).toContain('main.less');
    });

    it('should skip non-LESS files', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.readdirSync.mockReturnValue([
        { name: 'style.css', isDirectory: () => false },
        { name: 'script.js', isDirectory: () => false }
      ] as any);

      const result = service.scanLessFiles(['./styles']);

      expect(result).toHaveLength(0);
    });
  });
});
```

---

## Integration Testing

### Characteristics

- ✅ Test interactions between modules
- ✅ May use real database (or test DB)
- ✅ May access file system (test fixtures)
- ✅ Slower than unit tests (< 1s per test)
- ✅ Test complete workflows

### Example: Integration Test

```typescript
// src/services/__tests__/databaseService.integration.test.ts
import { Client } from 'pg';
import { DatabaseService } from '../databaseService';
import { setupTestDatabase, cleanupTestDatabase } from '../__tests__/fixtures';

describe('DatabaseService (Integration)', () => {
  let client: Client;
  let service: DatabaseService;

  beforeAll(async () => {
    client = await setupTestDatabase();
  });

  afterAll(async () => {
    await cleanupTestDatabase(client);
  });

  beforeEach(async () => {
    service = new DatabaseService(client);
    // Clear tables before each test
    await client.query('TRUNCATE less_files CASCADE');
  });

  describe('storeLessFile', () => {
    it('should store file and return ID', async () => {
      const fileData = {
        fileName: 'test.less',
        filePath: '/tmp/test.less',
        relativePath: 'test.less',
        content: '@color: red;',
        fileSize: 15
      };

      const id = await service.storeLessFile(fileData);

      expect(id).toBeGreaterThan(0);

      // Verify in database
      const result = await client.query('SELECT * FROM less_files WHERE id = $1', [id]);
      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].fileName).toBe('test.less');
    });

    it('should calculate checksum correctly', async () => {
      const fileData = {
        fileName: 'test.less',
        filePath: '/tmp/test.less',
        relativePath: 'test.less',
        content: 'body { color: red; }',
        fileSize: 20
      };

      const id = await service.storeLessFile(fileData);
      const result = await client.query('SELECT checksum FROM less_files WHERE id = $1', [id]);

      expect(result.rows[0].checksum).toBeDefined();
      expect(result.rows[0].checksum).toMatch(/^[a-f0-9]{64}$/); // SHA256 hex
    });

    it('should handle duplicate file paths with upsert', async () => {
      const fileData = {
        fileName: 'test.less',
        filePath: '/tmp/test.less',
        relativePath: 'test.less',
        content: 'original',
        fileSize: 8
      };

      const id1 = await service.storeLessFile(fileData);
      
      // Update same file
      const updatedData = { ...fileData, content: 'updated' };
      const id2 = await service.storeLessFile(updatedData);

      // Should return same ID
      expect(id2).toBe(id1);
      
      // Should have new content
      const result = await client.query('SELECT content FROM less_files WHERE id = $1', [id1]);
      expect(result.rows[0].content).toBe('updated');
    });
  });
});
```

### Test Fixtures

```typescript
// src/__tests__/fixtures.ts
import { Client } from 'pg';
import * as fs from 'fs';
import * as path from 'path';

export async function setupTestDatabase(): Promise<Client> {
  const client = new Client({
    host: process.env.DB_HOST_TEST || 'localhost',
    database: process.env.DB_NAME_TEST || 'less_to_tailwind_test',
    user: process.env.DB_USER_TEST || 'postgres',
    password: process.env.DB_PASSWORD_TEST || 'password'
  });

  await client.connect();

  // Run migrations
  const schemaPath = path.join(__dirname, '../../database/schema.sql');
  const schema = fs.readFileSync(schemaPath, 'utf-8');
  await client.query(schema);

  return client;
}

export async function cleanupTestDatabase(client: Client): Promise<void> {
  // Drop all tables
  await client.query(`
    DROP TABLE IF EXISTS parse_history CASCADE;
    DROP TABLE IF EXISTS tailwind_exports CASCADE;
    DROP TABLE IF EXISTS less_variables CASCADE;
    DROP TABLE IF EXISTS less_imports CASCADE;
    DROP TABLE IF EXISTS less_files CASCADE;
  `);
  
  await client.end();
}

export const FIXTURE_LESS_FILES = {
  simple: `
    @primary-color: #3498db;
    @secondary-color: #2ecc71;
    
    .button {
      color: @primary-color;
    }
  `,
  
  withImports: `
    @import 'variables.less';
    @import './mixins/helpers.less';
    
    body {
      font-family: @font-family;
    }
  `,
  
  withMixins: `
    .box-shadow(@x, @y, @blur) {
      box-shadow: @x @y @blur rgba(0, 0, 0, 0.3);
    }
    
    .card {
      .box-shadow(0, 2px, 4px);
    }
  `
};
```

---

## Test File Organization

### Structure

```
src/
├── services/
│   ├── lessService.ts
│   └── __tests__/
│       ├── lessService.test.ts          # Unit tests
│       ├── lessService.integration.test.ts # Integration tests
│       └── fixtures/
│           ├── lessService.fixtures.ts
│           └── sample-files/
│               ├── simple.less
│               └── complex.less
│
├── database/
│   ├── connection.ts
│   └── __tests__/
│       └── connection.test.ts
│
└── __tests__/
    ├── setup.ts
    ├── fixtures.ts
    └── helpers.ts
```

### Naming Conventions

- `*.test.ts` - Unit tests (faster, isolated)
- `*.integration.test.ts` - Integration tests (slower, dependencies)
- `*.fixtures.ts` - Test data and setup helpers

---

## Running Tests

### Commands

```bash
# Run all tests
npm test

# Run tests in watch mode
npm test -- --watch

# Run specific test file
npm test -- lessService.test.ts

# Run tests matching pattern
npm test -- --testNamePattern="should handle imports"

# Generate coverage report
npm test -- --coverage

# Run integration tests only
npm test -- --testPathPattern="integration"
```

### Coverage Report

```bash
npm test -- --coverage

# Output
------------------------------------|---------|----------|---------|---------|
File                                | % Stmts | % Branch | % Funcs | % Lines |
------------------------------------|---------|----------|---------|---------|
All files                           |   84.3  |   79.2   |   86.1  |   84.5  |
 src/services/lessService.ts        |   92.0  |   88.5   |   95.0  |   92.3  |
 src/services/databaseService.ts    |   78.5  |   72.1   |   80.0  |   79.2  |
------------------------------------|---------|----------|---------|---------|
```

---

## Coverage Requirements

### Minimum Thresholds

| Category | Minimum | Target |
|----------|---------|--------|
| Statements | 80% | 90% |
| Branches | 70% | 85% |
| Functions | 80% | 90% |
| Lines | 80% | 90% |

### Critical Paths (100% Required)

- Database operations (connection, queries, transactions)
- File parsing and validation
- Error handling and recovery
- Variable/mixin extraction
- Tailwind export generation

### Checking Coverage

Tests will fail if coverage drops below thresholds (configured in `jest.config.js`).

```bash
npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'
```

---

## Testing Best Practices

### ✅ DO

```typescript
// 1. Use descriptive test names
describe('LessParser', () => {
  it('should extract variables with correct syntax @variable: value', () => {
    // Clear what's being tested
  });
});

// 2. Test both success and failure paths
it('should handle valid imports', () => { });
it('should throw error for circular imports', () => { });

// 3. Use beforeEach for setup
beforeEach(() => {
  service = new LessService();
  mockDatabase();
});

// 4. Mock external dependencies
jest.mock('pg');
const mockClient = createMock<Client>();

// 5. Test edge cases
it('should handle empty LESS files', () => { });
it('should handle files with only comments', () => { });

// 6. Use matchers effectively
expect(result).toEqual({ id: 1, name: 'test' });
expect(error).toBeInstanceOf(FileNotFoundError);
expect(array).toContain('item');

// 7. Organize related tests
describe('FileScanner', () => {
  describe('scanDirectory', () => {
    it('should find LESS files', () => { });
    it('should recurse into subdirectories', () => { });
  });
  
  describe('validatePath', () => {
    it('should accept absolute paths', () => { });
    it('should accept relative paths', () => { });
  });
});
```

### ❌ DON'T

```typescript
// 1. Avoid vague test names
it('works', () => { });
it('test function', () => { });

// 2. Don't test implementation details
it('should call getFiles 3 times', () => { });

// 3. Don't have tests dependent on each other
test1();
test2(); // Depends on test1 running first

// 4. Don't mix multiple concepts in one test
it('should parse variables and mixins and resolve imports', () => { });

// 5. Don't sleep/wait in tests
setTimeout(() => {
  expect(result).toBeDefined();
}, 1000);

// 6. Avoid hardcoded magic numbers
expect(array.length).toBe(42); // Why 42?

// 7. Don't ignore test failures
it.skip('should do something', () => { });
```

### AAA Pattern (Arrange-Act-Assert)

```typescript
describe('calculateChecksum', () => {
  it('should generate SHA256 hash', () => {
    // Arrange
    const content = 'test content';
    
    // Act
    const checksum = calculateChecksum(content);
    
    // Assert
    expect(checksum).toMatch(/^[a-f0-9]{64}$/);
    expect(checksum).toHaveLength(64);
  });
});
```

---

## Continuous Integration

Tests should run automatically on:
- Pre-commit (via git hooks)
- Push to any branch
- Pull requests
- Scheduled daily

Coverage reports should be generated and tracked over time.

---

## Troubleshooting Tests

### Common Issues

**Problem:** Tests timeout  
**Solution:** Increase timeout for slow operations
```typescript
jest.setTimeout(30000); // 30 seconds
```

**Problem:** Flaky integration tests  
**Solution:** Ensure test database is clean
```typescript
beforeEach(async () => {
  await cleanupDatabase();
});
```

**Problem:** Mock not working  
**Solution:** Clear mocks between tests
```typescript
beforeEach(() => {
  jest.clearAllMocks();
});
```

---

## Additional Resources

- [Jest Documentation](https://jestjs.io/)
- [ts-jest Guide](https://kulshekhar.github.io/ts-jest/)
- [Testing Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
