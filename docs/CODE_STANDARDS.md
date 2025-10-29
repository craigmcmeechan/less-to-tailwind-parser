# CODE STANDARDS & CONVENTIONS

This document defines the coding standards and conventions that apply across all stages of the project. These standards ensure code consistency, maintainability, and quality.

## Table of Contents

1. [TypeScript Standards](#typescript-standards)
2. [Naming Conventions](#naming-conventions)
3. [Code Organization](#code-organization)
4. [Documentation & Comments](#documentation--comments)
5. [File Structure](#file-structure)
6. [Linting & Formatting](#linting--formatting)

---

## TypeScript Standards

### Strict Mode

All code must compile with TypeScript strict mode enabled (configured in `tsconfig.json`):

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true
  }
}
```

**Violations:** No code will pass review if TypeScript compilation fails.

### Type Safety

❌ **DO NOT USE:**
```typescript
let data: any;
let result = someFunction() as any;
```

✅ **DO USE:**
```typescript
// Define proper interfaces
interface FileData {
  name: string;
  size: number;
}

let data: FileData;

// Use generics instead of 'any'
function processData<T>(item: T): T {
  return item;
}
```

### Null/Undefined Handling

❌ **DO NOT:**
```typescript
function getValue(obj: any) {
  return obj.property.nested.value; // May crash if undefined
}
```

✅ **DO:**
```typescript
function getValue(obj: Record<string, unknown>): unknown | null {
  return obj?.property?.nested?.value ?? null;
}
```

### Interfaces Over Types (mostly)

- Use `interface` for object shapes (extensible, clearer intent)
- Use `type` for unions, tuples, and primitives
- Example:

```typescript
// Object shape - use interface
interface LessFile {
  id: number;
  fileName: string;
  content: string;
}

// Union type - use type
type FileStatus = 'pending' | 'processing' | 'completed' | 'error';

// Function signature - use interface
interface FileProcessor {
  process(file: LessFile): Promise<void>;
}
```

---

## Naming Conventions

### Variables & Functions

- **camelCase** for variables and functions
- **PascalCase** for classes and interfaces
- **UPPER_SNAKE_CASE** for constants

```typescript
// ✅ Correct
const maxRetries = 3;
const isProcessing = false;
function processLessFile() {}
class LessFileProcessor {}
interface DatabaseConfig {}
const DEFAULT_TIMEOUT = 5000;

// ❌ Incorrect
const MaxRetries = 3;
const is_processing = false;
function ProcessLessFile() {}
class lessFileProcessor {}
interface databaseConfig {}
```

### Boolean Variables

Prefix boolean properties with `is`, `has`, `can`, `should`:

```typescript
interface FileStatus {
  isResolved: boolean;
  hasErrors: boolean;
  canProcess: boolean;
  shouldRetry: boolean;
}
```

### Constants

```typescript
// Top-level constants
const MAX_FILE_SIZE_MB = 100;
const DEFAULT_ENCODING = 'utf-8';
const RETRY_ATTEMPTS = 3;
```

### Event Names & Callbacks

```typescript
// Event handler names
function onFileProcessed() {}
function handleImportResolution() {}

// Callback parameters
.then((result) => {})
.catch((error) => {})
```

---

## Code Organization

### Single Responsibility Principle

Each function/class should have one reason to change:

```typescript
// ❌ Too many responsibilities
class LessProcessor {
  scanFiles() { }
  parseContent() { }
  validateSyntax() { }
  storeInDatabase() { }
  generateOutput() { }
  sendEmail() { }
}

// ✅ Proper separation
class FileScanner {
  scanFiles() { }
}

class LessParser {
  parseContent() { }
  validateSyntax() { }
}

class DatabaseService {
  storeInDatabase() { }
}

class ExportService {
  generateOutput() { }
}
```

### Module Organization

```
src/
├── database/           # Database-specific
│   ├── connection.ts
│   └── queries.ts
├── services/           # Business logic
│   ├── lessService.ts
│   ├── databaseService.ts
│   └── exportService.ts
├── models/            # Data structures & types
│   ├── LessFile.ts
│   └── types.ts
├── utils/             # Reusable utilities
│   ├── logger.ts
│   └── validators.ts
├── errors/            # Custom error classes
│   └── CustomError.ts
└── index.ts           # Main entry point
```

### Imports Organization

Group imports in this order with blank lines:

```typescript
// 1. Node.js built-ins
import * as fs from 'fs';
import * as path from 'path';

// 2. External packages
import { Client } from 'pg';
import dotenv from 'dotenv';

// 3. Local imports
import { logger } from './utils/logger.js';
import { DatabaseService } from './services/databaseService.js';
```

---

## Documentation & Comments

### JSDoc Comments

Document all public functions and exported classes:

```typescript
/**
 * Processes a LESS file and stores it in the database.
 * 
 * @param filePath - Absolute path to the LESS file
 * @param client - PostgreSQL client instance
 * @returns Promise resolving to the file ID in the database
 * @throws {FileNotFoundError} If the file does not exist
 * @throws {DatabaseError} If storage fails
 * 
 * @example
 * ```typescript
 * const fileId = await processLessFile('./styles/main.less', client);
 * ```
 */
async function processLessFile(filePath: string, client: Client): Promise<number> {
  // implementation
}
```

### Inline Comments

Use sparingly; prefer clear code over comments. Comments should explain *why*, not *what*:

```typescript
// ❌ Bad - states the obvious
let count = 0; // Initialize count to zero

// ✅ Good - explains intent
// Limit concurrent operations to prevent database overload
let activeConnections = 0;

// ❌ Bad - too detailed
for (let i = 0; i < files.length; i++) { // Loop through files
  procesFile(files[i]); // Process each file
}

// ✅ Good - explains non-obvious logic
// Process files in reverse order to handle dependencies
for (let i = files.length - 1; i >= 0; i--) {
  processFile(files[i]);
}
```

### TODO & FIXME Comments

Use sparingly and always with context:

```typescript
// TODO: Implement caching for frequently accessed files (perf improvement)
// FIXME: Circular import detection not handling self-imports
```

---

## File Structure

### One Class Per File

```
services/
├── lessService.ts      // exports LessService
├── databaseService.ts  // exports DatabaseService
└── exportService.ts    // exports ExportService
```

### Exception: Closely Related Types

```typescript
// models/types.ts
export interface LessFile {
  id: number;
  fileName: string;
}

export type FileStatus = 'pending' | 'completed' | 'error';

export interface ProcessResult {
  file: LessFile;
  status: FileStatus;
}
```

### File Naming

- `camelCase.ts` for files (unless component files)
- Match export class/interface name: `lessService.ts` exports `LessService`
- `index.ts` for barrel exports (re-export from module)

---

## Linting & Formatting

### ESLint

All code must pass ESLint with no warnings:

```bash
npm run lint
```

Configuration extends recommended TypeScript rules.

### Prettier

Code is auto-formatted with Prettier. Run before committing:

```bash
npm run format
```

Configuration in `.prettierrc`:
- 2-space indentation
- Single quotes
- Semicolons required
- Line width: 100 characters
- Trailing commas: ES5

### Pre-commit Hook (Recommended)

```bash
# Setup: npm install husky --save-dev
npx husky install
npx husky add .husky/pre-commit "npm run lint && npm run format"
```

---

## Error Handling Standards

See [ERROR_HANDLING.md](./ERROR_HANDLING.md) for detailed error patterns.

Quick reference:
- All async operations wrapped in try-catch
- Custom error types for domain-specific errors
- Errors logged with context before throwing
- User-friendly error messages

---

## Testing Standards

See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for detailed testing patterns.

Quick reference:
- Unit tests for all exported functions
- Integration tests for database operations
- Test file co-located with source: `lessService.test.ts`
- Minimum 80% code coverage

---

## Performance Considerations

### Avoid N+1 Queries

```typescript
// ❌ Bad - N+1 queries
const files = await getAllLessFiles();
for (const file of files) {
  const variables = await getVariables(file.id); // N queries
}

// ✅ Good - one query
const filesWithVariables = await getAllLessFilesWithVariables();
```

### Use Parameterized Queries

```typescript
// ❌ Bad - SQL injection vulnerability & not parametrized
const result = await client.query(`SELECT * FROM files WHERE name = '${name}'`);

// ✅ Good - safe and efficient
const result = await client.query('SELECT * FROM files WHERE name = $1', [name]);
```

### Leverage Database Indexes

See [DATABASE_OPERATIONS.md](./DATABASE_OPERATIONS.md) for index strategy.

---

## Checklist for Code Review

- [ ] TypeScript compiles with zero errors (strict mode)
- [ ] ESLint passes with no warnings
- [ ] Code is formatted with Prettier
- [ ] No `any` types (generics used instead)
- [ ] Null/undefined handled with optional chaining or nullish coalescing
- [ ] Public functions have JSDoc comments
- [ ] Comments explain *why*, not *what*
- [ ] Single responsibility principle followed
- [ ] No console.log() (use logger instead)
- [ ] Imports organized by category
- [ ] No magic numbers (use named constants)
- [ ] Error handling implemented
- [ ] Tests written for new functionality
- [ ] No unused variables or parameters

---

## Additional Resources

- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [ESLint Rules](https://eslint.org/docs/rules/)
- [Prettier Documentation](https://prettier.io/docs/en/index.html)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
