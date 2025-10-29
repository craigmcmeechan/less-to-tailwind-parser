# Claude Code Instructions: Stage 1 - Database Foundation

## Overview

Implement PostgreSQL database setup with connection pooling, migrations, logging utilities, and error handling patterns.

**Stage:** 1 of 9  
**Duration:** Expected 1 week  
**Files to Create:** 8-12  
**Tests Required:** 10+ unit tests  

---

## Objectives

1. ✅ PostgreSQL database connection with connection pool
2. ✅ Database migration system
3. ✅ Logger utility (Winston or similar)
4. ✅ Error handling patterns
5. ✅ Type definitions for database operations
6. ✅ Environment configuration
7. ✅ Unit tests for all services
8. ✅ Documentation

---

## Files to Create

### Core Services
```
src/shared/
├── database.ts              # Connection pool, query execution
├── logger.ts                # Logging utility
├── types.ts                 # Shared type definitions
├── errors.ts                # Custom error classes
└── config.ts                # Environment configuration

src/part1/
└── services/
    └── (none yet - will be added in Stage 2)
```

### Tests
```
tests/unit/
├── database.test.ts         # Connection pool tests
├── logger.test.ts           # Logger tests
└── errors.test.ts           # Error handling tests

tests/integration/
└── database.integration.test.ts  # Real database tests
```

### Configuration
```
├── .env.example             # Environment variables template
├── tsconfig.json            # TypeScript configuration
├── jest.config.js           # Jest testing configuration
└── package.json             # Dependencies (update)
```

---

## Implementation Requirements

### 1. Database Service (`src/shared/database.ts`)

**Must implement:**
- PostgreSQL connection pool (pg library)
- `executeQuery()` - Execute parameterized queries
- `executeTransaction()` - Handle transactions
- `close()` - Graceful shutdown
- Connection health checks
- Error recovery

**Example signature:**
```typescript
export class DatabaseService {
  private pool: Pool;
  async initialize(): Promise<void>
  async executeQuery<T>(sql: string, params?: any[]): Promise<T[]>
  async executeTransaction(callback: Function): Promise<any>
  async close(): Promise<void>
  async healthCheck(): Promise<boolean>
}
```

### 2. Logger Service (`src/shared/logger.ts`)

**Must implement:**
- Levels: debug, info, warn, error
- Structured logging (JSON)
- Console + file output
- Log rotation
- Environment-based log levels

**Example signature:**
```typescript
export const logger = {
  debug(message: string, data?: any): void
  info(message: string, data?: any): void
  warn(message: string, data?: any): void
  error(message: string, error?: Error): void
}
```

### 3. Error Classes (`src/shared/errors.ts`)

**Must implement:**
- `DatabaseError`
- `ValidationError`
- `ConfigurationError`
- `NotFoundError`

Each with:
- Custom message
- Error code
- HTTP status mapping
- Logging integration

### 4. Configuration (`src/shared/config.ts`)

**Must implement:**
- Environment variable loading (.env)
- Validation of required variables
- Default values
- Type-safe configuration object

**Required env vars:**
```
DATABASE_URL         # postgres://user:pass@host:5432/db
NODE_ENV             # development|test|production
LOG_LEVEL            # debug|info|warn|error
PORT                 # API port
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] Can connect to PostgreSQL
- [ ] Connection pool configured (min 2, max 10)
- [ ] Logger outputs structured JSON
- [ ] All error classes implement proper inheritance
- [ ] Environment variables validated at startup
- [ ] Unit tests pass with >90% coverage
- [ ] Integration tests pass against real database
- [ ] No secrets leaked (check .gitignore)
- [ ] Code follows CODE_STANDARDS.md
- [ ] TypeScript compiles without errors
- [ ] ESLint passes
- [ ] All functions have JSDoc comments

---

## Testing Requirements

### Unit Tests (10+ tests)
```typescript
// database.test.ts
- Connection pool initialization
- Query execution with parameters
- Transaction rollback on error
- Connection error handling
- Pool exhaustion handling

// logger.test.ts
- Log level filtering
- Structured output format
- Error serialization

// errors.test.ts
- Error inheritance chain
- HTTP status mapping
- Error message formatting
```

### Integration Tests (5+ tests)
```typescript
// database.integration.test.ts
- Create test database
- Execute real queries
- Transaction with rollback
- Connection cleanup
```

### Test Coverage
- Minimum: 90% line coverage
- All error paths tested
- Edge cases covered

---

## Dependencies to Install

```json
{
  "dependencies": {
    "pg": "^8.11.0",
    "winston": "^3.11.0",
    "dotenv": "^16.3.0"
  },
  "devDependencies": {
    "@types/pg": "^8.11.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.0",
    "@types/jest": "^29.5.0",
    "eslint": "^8.52.0",
    "typescript": "^5.2.0"
  }
}
```

---

## Code Standards

Follow these from `docs/CODE_STANDARDS.md`:

- ✅ Use `const`/`let`, no `var`
- ✅ Explicit return types
- ✅ JSDoc on public methods
- ✅ Error handling on all async calls
- ✅ No console.log (use logger)
- ✅ Type-safe parameters
- ✅ No `any` types

---

## Documentation

Generate:
1. **README.md** - Setup instructions, quick start
2. **DATABASE.md** - How to use database service
3. **LOGGING.md** - Logging examples
4. **ERRORS.md** - Error handling patterns
5. **Inline comments** - JSDoc on all functions

---

## Validation Checklist

Before committing, verify:

```bash
# Type checking
npm run type-check
✅ No TypeScript errors

# Linting
npm run lint
✅ No ESLint errors

# Testing
npm test -- stage-1
✅ All tests pass
✅ Coverage >90%

# Build
npm run build
✅ Compiles successfully

# Git check
git status
✅ No secrets in .env files
✅ .env not staged (in .gitignore)
```

---

## Success Criteria

Stage 1 is complete when:

1. ✅ Can initialize database connection on startup
2. ✅ Can execute parameterized queries safely
3. ✅ Logger outputs structured JSON
4. ✅ All errors are handled with custom classes
5. ✅ Configuration loads from .env
6. ✅ Tests pass with >90% coverage
7. ✅ Code compiles and lints clean
8. ✅ Documentation is complete

---

## Integration with Next Stage

Stage 2 will use:
- `DatabaseService` - for storing scanned files
- `logger` - for logging scan progress
- `errors` - for file system errors
- Configuration - for database URL

---

## Resources

- `docs/stages/01_DATABASE_FOUNDATION.md` - Full stage guide
- `docs/CODE_STANDARDS.md` - Coding standards
- `docs/TESTING_GUIDE.md` - Testing patterns
- `docs/LOGGING_GUIDE.md` - Logging guide
- `docs/ERROR_HANDLING.md` - Error strategies

---

## Claude Code Instructions

**Run this command in `.worktrees/stage-1/`:**

```bash
npx @anthropic-ai/claude-code --instruction-file ../../.claude-code/stage-1.md
```

**Expected output:**
- All files listed above
- Tests passing
- Coverage >90%
- No TypeScript errors

---

**Last Updated:** October 29, 2025
