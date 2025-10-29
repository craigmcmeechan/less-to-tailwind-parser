# STAGE 1: DATABASE FOUNDATION

**Duration:** 1 week  
**Status:** ⏳ Ready to Start  
**Dependencies:** None  
**Blocks:** Stages 2-6

---

## Overview

Stage 1 establishes the database infrastructure. This stage must be 100% complete and verified before proceeding to file scanning, as all subsequent stages depend on a functioning database with correct schema.

**Key Deliverable:** PostgreSQL database with verified schema, indexes, and connection pool ready for use.

---

## Objectives

1. ✅ PostgreSQL connection module fully functional
2. ✅ Database schema created with all tables and relationships
3. ✅ All indexes in place for query optimization
4. ✅ Triggers and ENUM types defined
5. ✅ Connection pooling configured (production ready)
6. ✅ Connection resilience with retry logic
7. ✅ Schema migrations automated
8. ✅ Test database setup working

---

## Existing Codebase

**Already Complete:**
- `database/schema.sql` - Complete schema definition with all tables, indexes, and triggers
- `src/database/connection.ts` - Basic connection module with retry logic
- `src/utils/logger.ts` - Logger for debug output

**What Needs Enhancement:**
- Error handling in connection module (use `DATABASE_OPERATIONS.md` patterns)
- Connection pooling for production
- Test database configuration
- Database utilities (reset, seed, validate)

---

## Technical Specifications

### 1. PostgreSQL Connection Module

**File:** `src/database/connection.ts`

**Requirements:**
- Establish connection with environment variables
- Implement exponential backoff retry (max 3 attempts)
- Run schema migrations automatically on first connection
- Handle connection errors with specific error types
- Support both single connection and connection pooling

**Interface:**
```typescript
export async function initializeDatabase(): Promise<Client>;
export async function closeDatabase(client: Client): Promise<void>;
export interface DatabaseConfig {
  host: string;
  port: number;
  database: string;
  user: string;
  password: string;
}
```

**Reference:** See `DATABASE_OPERATIONS.md` for connection patterns

---

### 2. Schema Validation

**File:** `database/schema.sql` (already complete, validate it)

**Verify:**
- [ ] 5 tables created: `less_files`, `less_imports`, `less_variables`, `tailwind_exports`, `parse_history`
- [ ] 2 ENUM types: `file_status`, `import_type`
- [ ] All foreign key constraints present
- [ ] Indexes on frequently-queried columns exist
- [ ] Update triggers for `updated_at` timestamps work

**Validation Query:**
```sql
-- Verify tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema='public';

-- Verify indexes
SELECT indexname FROM pg_indexes 
WHERE schemaname='public';

-- Verify ENUM types
SELECT typname FROM pg_type 
WHERE typtype='e';
```

---

### 3. Custom Error Types

**File:** `src/errors/customError.ts` and `src/errors/databaseErrors.ts`

**Required Error Types:**
```typescript
export class DatabaseConnectionError extends CustomError
export class QueryError extends CustomError  
export class TransactionError extends CustomError
export class ValidationError extends CustomError
```

**Reference:** `ERROR_HANDLING.md` for error hierarchy

---

### 4. Database Utilities

**New Files:**
- `src/database/utilities.ts`
- `src/database/seed.ts`
- `src/__tests__/testDatabase.ts`

**Utilities Include:**
```typescript
export async function resetDatabase(client: Client): Promise<void>
export async function seedTestData(client: Client): Promise<void>
export async function validateSchema(client: Client): Promise<ValidationResult>
```

---

## Implementation Steps

### Step 1: Finalize Connection Module (2 days)

1. Review `src/database/connection.ts`
2. Add retry logic with exponential backoff
3. Implement error handling with custom DatabaseErrors
4. Add logging at INFO and ERROR levels
5. Test manual connection with actual PostgreSQL

**Test:** `npm run db:connect` should successfully connect

---

### Step 2: Validate Schema (2 days)

1. Review `database/schema.sql` thoroughly
2. Manually run schema against PostgreSQL
3. Verify all tables and relationships
4. Confirm indexes are created
5. Test triggers (update timestamp on row change)

**Test:** Manually verify schema in psql:
```bash
psql -h localhost -U postgres -d less_to_tailwind
\dt              # See all tables
\d less_files    # See table structure
SELECT * FROM information_schema.tables;
```

---

### Step 3: Create Test Database Setup (2 days)

1. Create `src/__tests__/testDatabase.ts` for test DB initialization
2. Create `src/__tests__/fixtures.ts` with sample data
3. Implement database reset for clean test state
4. Create seeds with realistic test data

**Key Functions:**
```typescript
export async function setupTestDatabase(): Promise<Client>
export async function cleanupTestDatabase(client: Client): Promise<void>
export async function resetAllTables(client: Client): Promise<void>
```

---

### Step 4: Create Database Utilities (1 day)

1. Create `src/database/utilities.ts`
2. Add schema validation function
3. Add statistics function (count rows, etc.)
4. Add health check function

---

## Unit Testing

**See:** `TESTING_GUIDE.md` for test structure

### Tests to Write

```typescript
// src/database/__tests__/connection.test.ts

describe('Database Connection', () => {
  it('should connect successfully to PostgreSQL', async () => {
    const client = await initializeDatabase();
    expect(client).toBeDefined();
    await client.end();
  });

  it('should retry on connection failure', async () => {
    // Mock failure then success
    // Verify retry logic works
  });

  it('should create all schema tables', async () => {
    const result = await client.query(
      `SELECT COUNT(*) FROM information_schema.tables 
       WHERE table_schema='public'`
    );
    expect(result.rows[0].count).toBe(5);
  });

  it('should have all required indexes', async () => {
    const result = await client.query(
      `SELECT COUNT(*) FROM pg_indexes WHERE schemaname='public'`
    );
    expect(result.rows[0].count).toBeGreaterThan(8);
  });
});
```

**Coverage Target:** 90%+ for connection module

---

## Integration Testing

```typescript
// src/database/__tests__/connection.integration.test.ts

describe('Database Integration', () => {
  let client: Client;

  beforeAll(async () => {
    client = await initializeDatabase();
  });

  afterAll(async () => {
    await closeDatabase(client);
  });

  it('should insert and retrieve data', async () => {
    const result = await client.query(
      `INSERT INTO less_files (file_name, file_path, status) 
       VALUES ($1, $2, $3) RETURNING id`,
      ['test.less', '/tmp/test.less', 'pending']
    );
    
    expect(result.rows[0].id).toBeGreaterThan(0);
  });

  it('should update timestamp automatically', async () => {
    const insertResult = await client.query(
      `INSERT INTO less_files (file_name, file_path, status) 
       VALUES ($1, $2, $3) RETURNING id, created_at`,
      ['test2.less', '/tmp/test2.less', 'pending']
    );

    const id = insertResult.rows[0].id;
    
    // Wait, then update
    await new Promise(r => setTimeout(r, 100));
    
    await client.query(
      `UPDATE less_files SET status = $1 WHERE id = $2`,
      ['completed', id]
    );

    const result = await client.query(
      `SELECT created_at, updated_at FROM less_files WHERE id = $1`,
      [id]
    );

    expect(result.rows[0].updated_at).toBeGreaterThan(result.rows[0].created_at);
  });
});
```

---

## Logging Strategy

**See:** `LOGGING_GUIDE.md` for logger usage

### What to Log

```typescript
logger.info('Database connection established', { host, database });
logger.info('Schema created successfully');
logger.debug('Running migration', { migrationFile: 'schema.sql' });
logger.warn('Connection attempt failed, retrying', { attempt, nextDelayMs });
logger.error('Failed to connect after all retries:', error);
```

### Log Levels

- `DEBUG` - Connection attempts, retry details
- `INFO` - Connection success, schema creation complete
- `WARN` - Retry attempts, missing configurations
- `ERROR` - Connection failures, schema errors

---

## Error Handling

**See:** `ERROR_HANDLING.md` for patterns

### Specific Scenarios

```typescript
// Handle ECONNREFUSED
if ((error as any).code === 'ECONNREFUSED') {
  throw new DatabaseConnectionError(host, 'Server not responding');
}

// Handle auth failures  
if (message.includes('authentication')) {
  throw new DatabaseConnectionError(host, 'Invalid credentials');
}

// Handle timeout
if (message.includes('timeout')) {
  // Retry with backoff
}
```

---

## Code Standards

**See:** `CODE_STANDARDS.md` for conventions

### Apply These Standards

- ✅ Use strict TypeScript (no `any`)
- ✅ Parameterized SQL queries (never string concat)
- ✅ Interface for all data structures
- ✅ JSDoc comments for public functions
- ✅ ESLint/Prettier pass
- ✅ No console.log (use logger)

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] PostgreSQL 12+ running and accessible
- [ ] `npm run build` compiles with zero errors
- [ ] ESLint passes all checks
- [ ] TypeScript strict mode: no errors
- [ ] All 5 database tables created
- [ ] All indexes created and optimized
- [ ] ENUM types defined
- [ ] Triggers working (timestamps update)
- [ ] Connection retry logic functioning
- [ ] Custom DatabaseErrors used
- [ ] Unit tests pass (>90% coverage)
- [ ] Integration tests pass
- [ ] Logging at appropriate levels
- [ ] `.env.example` documents DB_* variables

---

## Deliverables Checklist

- [ ] `src/database/connection.ts` - Production-ready
- [ ] `database/schema.sql` - Validated and complete
- [ ] `src/errors/databaseErrors.ts` - All error types defined
- [ ] `src/__tests__/testDatabase.ts` - Test DB setup
- [ ] `src/database/utilities.ts` - Schema validation and helpers
- [ ] Unit tests with >90% coverage
- [ ] Integration tests passing
- [ ] README.md section on database setup
- [ ] `.env.example` with DB variables
- [ ] Manual verification in psql completed

---

## Success Verification

Run these commands - all should succeed:

```bash
# Build with no errors
npm run build

# Lint with no errors  
npm run lint

# Run database tests
npm test -- connection

# Manual verification
psql -h localhost -U postgres -d less_to_tailwind
  \dt              # Should see 5 tables
  \d less_files    # Should see correct schema
  SELECT * FROM information_schema.tables;  # Should see all tables
```

---

**Next Stage:** When Stage 1 passes all criteria, proceed to [Stage 2: LESS File Scanning](./02_LESS_SCANNING.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
