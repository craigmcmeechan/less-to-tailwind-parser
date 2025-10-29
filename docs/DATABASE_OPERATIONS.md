# DATABASE OPERATIONS GUIDE

This document defines database interaction patterns, query best practices, and transaction handling for all stages.

## Table of Contents

1. [Connection Management](#connection-management)
2. [Query Patterns](#query-patterns)
3. [Transactions](#transactions)
4. [Error Handling](#error-handling)
5. [Performance Optimization](#performance-optimization)
6. [Best Practices](#best-practices)

---

## Connection Management

### Initialization with Retry

```typescript
// src/database/connection.ts
async function initializeDatabase(): Promise<Client> {
  const client = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'less_to_tailwind',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password',
  });

  try {
    await client.connect();
    logger.info('Connected to PostgreSQL database');
    return client;
  } catch (error) {
    logger.error('Failed to connect to database:', error);
    throw new DatabaseConnectionError('postgres', 
      error instanceof Error ? error.message : 'Unknown error'
    );
  }
}
```

### Connection Cleanup

```typescript
// Always close connections
async function closeDatabase(client: Client): Promise<void> {
  try {
    await client.end();
    logger.info('Database connection closed');
  } catch (error) {
    logger.error('Error closing database connection:', error);
  }
}

// Usage in main
try {
  const client = await initializeDatabase();
  // ... operations ...
} finally {
  await closeDatabase(client);
}
```

---

## Query Patterns

### Pattern 1: Simple Query with Parameters

Always use parameterized queries to prevent SQL injection:

```typescript
// ❌ VULNERABLE - Never do this
const query = `SELECT * FROM less_files WHERE file_name = '${fileName}'`;

// ✅ SAFE - Always parameterize
const result = await client.query(
  'SELECT * FROM less_files WHERE file_name = $1',
  [fileName]
);
```

### Pattern 2: Multiple Parameters

```typescript
async function findFilesByStatus(
  status: string, 
  limit: number
): Promise<any[]> {
  const result = await client.query(
    'SELECT * FROM less_files WHERE status = $1 ORDER BY created_at DESC LIMIT $2',
    [status, limit]
  );
  return result.rows;
}
```

### Pattern 3: INSERT with RETURNING

```typescript
async function createFile(data: LessFileData): Promise<number> {
  const result = await client.query(
    `INSERT INTO less_files (file_name, file_path, content, file_size, status)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id`,
    [data.fileName, data.filePath, data.content, data.fileSize, 'pending']
  );
  
  return result.rows[0].id;
}
```

### Pattern 4: UPSERT (INSERT ... ON CONFLICT)

```typescript
async function upsertFile(data: LessFileData): Promise<number> {
  const result = await client.query(
    `INSERT INTO less_files (file_name, file_path, content, file_size, checksum, status)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (file_path) 
     DO UPDATE SET 
       content = $3,
       checksum = $5,
       updated_at = CURRENT_TIMESTAMP
     RETURNING id`,
    [
      data.fileName, 
      data.filePath, 
      data.content, 
      data.fileSize,
      calculateChecksum(data.content),
      'completed'
    ]
  );
  
  return result.rows[0].id;
}
```

### Pattern 5: Batch Operations

```typescript
// Efficient bulk insert
async function bulkInsertVariables(variables: Variable[]): Promise<void> {
  if (variables.length === 0) return;

  const values = variables
    .map((_, i) => `($${i * 5 + 1}, $${i * 5 + 2}, $${i * 5 + 3}, $${i * 5 + 4}, $${i * 5 + 5})`)
    .join(',');

  const params = variables.flatMap(v => [
    v.lessFileId,
    v.variableName,
    v.variableType,
    v.variableValue,
    v.isMixin
  ]);

  await client.query(
    `INSERT INTO less_variables (less_file_id, variable_name, variable_type, variable_value, is_mixin)
     VALUES ${values}
     ON CONFLICT DO NOTHING`,
    params
  );
}
```

### Pattern 6: JOIN Queries

```typescript
async function getFilesWithVariables(): Promise<any[]> {
  const result = await client.query(`
    SELECT 
      f.id,
      f.file_name,
      f.file_path,
      f.status,
      json_agg(json_build_object('name', v.variable_name, 'value', v.variable_value)) as variables
    FROM less_files f
    LEFT JOIN less_variables v ON f.id = v.less_file_id
    GROUP BY f.id, f.file_name, f.file_path, f.status
  `);
  
  return result.rows;
}
```

### Pattern 7: Aggregation Queries

```typescript
async function getStatistics(): Promise<any> {
  const result = await client.query(`
    SELECT 
      COUNT(*) as total_files,
      SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
      SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as failed,
      AVG(file_size) as avg_size,
      MAX(file_size) as max_size
    FROM less_files
  `);
  
  return result.rows[0];
}
```

---

## Transactions

### Basic Transaction

```typescript
async function transferData(): Promise<void> {
  const client = new Client();
  await client.connect();

  try {
    await client.query('BEGIN');
    
    // All operations must succeed or none are applied
    await client.query('INSERT INTO less_files (...) VALUES (...)');
    await client.query('UPDATE less_imports SET is_resolved = TRUE WHERE ...');
    
    await client.query('COMMIT');
    logger.info('Transaction committed');
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Transaction rolled back:', error);
    throw error;
  } finally {
    await client.end();
  }
}
```

### Using Query Method with Transaction

```typescript
async function bulkUpdateWithTransaction(updates: Update[]): Promise<void> {
  const client = new Client();
  await client.connect();

  try {
    await client.query('BEGIN');
    
    for (const update of updates) {
      await client.query(
        'UPDATE less_files SET status = $1 WHERE id = $2',
        [update.status, update.fileId]
      );
    }
    
    await client.query('COMMIT');
    logger.info(`${updates.length} records updated`);
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Batch update failed:', error);
    throw new DatabaseError('Batch update failed');
  } finally {
    await client.end();
  }
}
```

### Savepoints for Nested Transactions

```typescript
async function complexOperation(): Promise<void> {
  const client = new Client();
  await client.connect();

  try {
    await client.query('BEGIN');
    
    // Main operation
    await client.query('INSERT INTO less_files (...) VALUES (...)');
    
    // Savepoint for optional operation
    await client.query('SAVEPOINT sp1');
    
    try {
      await client.query('INSERT INTO less_variables (...) VALUES (...)');
    } catch (error) {
      // Rollback only to savepoint, not entire transaction
      await client.query('ROLLBACK TO sp1');
      logger.warn('Optional operation failed, continuing');
    }
    
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    await client.end();
  }
}
```

---

## Error Handling

### Query Error Handling

```typescript
async function getFile(id: number): Promise<File> {
  try {
    const result = await client.query(
      'SELECT * FROM less_files WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      throw new FileNotFoundError(`File ${id}`);
    }

    return result.rows[0];
  } catch (error) {
    if (error instanceof FileNotFoundError) {
      throw error; // Re-throw known errors
    }

    logger.error('Query failed:', error);
    throw new QueryError(
      'SELECT * FROM less_files WHERE id = $1',
      error instanceof Error ? error.message : 'Unknown error'
    );
  }
}
```

### Connection Error Recovery

```typescript
async function executeWithFallback<T>(
  query: string,
  params: unknown[],
  maxAttempts: number = 3
): Promise<T> {
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const result = await client.query(query, params);
      return result.rows[0] || null;
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      
      if ((error as any).code === 'ECONNREFUSED') {
        logger.warn('Connection refused, reconnecting', { attempt });
        // Could reconnect here
      } else if (attempt === maxAttempts) {
        throw lastError;
      }
    }
  }

  throw lastError;
}
```

---

## Performance Optimization

### Index Strategy

Indexes are defined in `database/schema.sql`:

```sql
CREATE INDEX idx_less_files_status ON less_files(status);
CREATE INDEX idx_less_imports_parent ON less_imports(parent_file_id);
CREATE INDEX idx_less_variables_file ON less_variables(less_file_id);
```

### Query Optimization

```typescript
// ❌ Inefficient - N+1 queries
async function getFilesWithVariables_Slow(fileIds: number[]): Promise<any[]> {
  const files = [];
  for (const id of fileIds) {
    const file = await client.query('SELECT * FROM less_files WHERE id = $1', [id]);
    const vars = await client.query('SELECT * FROM less_variables WHERE less_file_id = $1', [id]);
    files.push({ ...file.rows[0], variables: vars.rows });
  }
  return files;
}

// ✅ Efficient - single query with JOIN
async function getFilesWithVariables_Fast(fileIds: number[]): Promise<any[]> {
  const result = await client.query(
    `SELECT 
      f.*,
      json_agg(json_build_object('id', v.id, 'name', v.variable_name)) as variables
    FROM less_files f
    LEFT JOIN less_variables v ON f.id = v.less_file_id
    WHERE f.id = ANY($1)
    GROUP BY f.id`,
    [fileIds]
  );
  return result.rows;
}
```

### Connection Pooling

For production, use a pool:

```typescript
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  connectionTimeoutMillis: 2000,
  idleTimeoutMillis: 30000,
});

// Use pool.query instead of client.query
const result = await pool.query('SELECT * FROM less_files WHERE id = $1', [id]);
```

---

## Best Practices

### ✅ DO

```typescript
// 1. Always parameterize
await client.query('SELECT * FROM files WHERE name = $1', [name]);

// 2. Use transactions for multi-step operations
await client.query('BEGIN');
// ... operations ...
await client.query('COMMIT');

// 3. Handle connection errors
try {
  await client.connect();
} catch (error) {
  // Retry or use fallback
}

// 4. Check result rows before using
const result = await client.query(...);
if (result.rows.length === 0) {
  throw new NotFoundError();
}

// 5. Use RETURNING for efficiency
INSERT INTO files (...) VALUES (...) RETURNING id

// 6. Close connections properly
finally {
  await client.end();
}

// 7. Log important operations
logger.info('Stored file', { fileId, fileName });
```

### ❌ DON'T

```typescript
// 1. Don't concatenate SQL strings
`SELECT * FROM files WHERE name = '${name}'`

// 2. Don't ignore transaction failures
await client.query('BEGIN');
// operations that might fail without proper error handling

// 3. Don't leave connections open
const client = new Client();
await client.connect();
// ... no cleanup

// 4. Don't assume results exist
const result = await client.query(...);
return result.rows[0].value; // May crash if no rows

// 5. Don't use SELECT * in production
SELECT * FROM large_table; // May fetch unnecessary columns

// 6. Don't nest transactions without savepoints
COMMIT; ROLLBACK COMMIT; // Syntax error

// 7. Don't ignore connection timeouts
// May hang indefinitely
```

---

## Debugging Queries

### Enable Query Logging

```typescript
// During development
client.query = (text, values, callback) => {
  logger.debug('Executing query', { query: text, params: values });
  return Client.prototype.query.call(client, text, values, callback);
};
```

### Verify Schema

```bash
# Connect to database
psql -h localhost -U postgres -d less_to_tailwind

# List tables
\dt

# Describe table
\d less_files

# Run query
SELECT COUNT(*) FROM less_files;
```

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
