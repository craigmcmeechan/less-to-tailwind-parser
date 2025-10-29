# ERROR HANDLING GUIDE

This document defines error handling strategies, custom error types, and recovery procedures for all stages. Proper error handling ensures the application is resilient and provides clear feedback.

## Table of Contents

1. [Error Handling Philosophy](#error-handling-philosophy)
2. [Custom Error Types](#custom-error-types)
3. [Error Handling Patterns](#error-handling-patterns)
4. [Recovery Strategies](#recovery-strategies)
5. [Best Practices](#best-practices)
6. [Error Scenarios](#error-scenarios)

---

## Error Handling Philosophy

### Principles

1. **Fail Fast, Recover Gracefully** - Detect errors early, but attempt recovery where possible
2. **Clear Error Messages** - Users should understand what went wrong and why
3. **Logged Context** - Errors must be logged with full context for debugging
4. **Type Safe** - Use custom error types, never bare Error objects
5. **Responsibility** - Each layer handles errors it can recover from; propagates others

### Error Hierarchy

```
Error (JavaScript built-in)
  ├── ValidationError (Input validation failed)
  ├── FileError
  │   ├── FileNotFoundError (File doesn't exist)
  │   └── FileReadError (Cannot read file)
  ├── DatabaseError
  │   ├── ConnectionError (Database unreachable)
  │   ├── QueryError (Query execution failed)
  │   └── TransactionError (Transaction failed)
  ├── ParseError (LESS syntax invalid)
  └── ExportError (Export generation failed)
```

---

## Custom Error Types

### Base Custom Error Class

```typescript
// src/errors/CustomError.ts

/**
 * Base class for all custom application errors.
 * Provides consistent error structure and context.
 */
export class CustomError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500,
    public context?: Record<string, unknown>
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      statusCode: this.statusCode,
      context: this.context
    };
  }
}
```

### Specific Error Types

```typescript
// src/errors/ApplicationErrors.ts

export class ValidationError extends CustomError {
  constructor(message: string, context?: Record<string, unknown>) {
    super('VALIDATION_ERROR', message, 400, context);
  }
}

export class FileNotFoundError extends CustomError {
  constructor(filePath: string) {
    super('FILE_NOT_FOUND', `File not found: ${filePath}`, 404, { filePath });
  }
}

export class FileReadError extends CustomError {
  constructor(filePath: string, reason: string) {
    super('FILE_READ_ERROR', `Cannot read file: ${reason}`, 500, { filePath, reason });
  }
}

export class DatabaseConnectionError extends CustomError {
  constructor(host: string, reason: string) {
    super('DB_CONNECTION_ERROR', `Cannot connect to database: ${reason}`, 503, { host, reason });
  }
}

export class QueryError extends CustomError {
  constructor(query: string, reason: string) {
    super('QUERY_ERROR', `Database query failed: ${reason}`, 500, { query, reason });
  }
}

export class CircularImportError extends CustomError {
  constructor(files: string[]) {
    super('CIRCULAR_IMPORT', `Circular import detected: ${files.join(' -> ')}`, 422, { files });
  }
}

export class ParseError extends CustomError {
  constructor(filePath: string, lineNumber: number, reason: string) {
    super('PARSE_ERROR', `Parse error in ${filePath} at line ${lineNumber}: ${reason}`, 422, {
      filePath,
      lineNumber,
      reason
    });
  }
}

export class ExportError extends CustomError {
  constructor(reason: string, context?: Record<string, unknown>) {
    super('EXPORT_ERROR', `Failed to export configuration: ${reason}`, 500, context);
  }
}
```

---

## Error Handling Patterns

### Pattern 1: Try-Catch with Logging and Re-throw

Use when you want to log but can't recover:

```typescript
async function processLessFile(filePath: string): Promise<void> {
  try {
    const content = await readFile(filePath);
    return parseLess(content);
  } catch (error) {
    if (error instanceof FileNotFoundError) {
      logger.warn('LESS file not found', { filePath });
      throw error;
    }
    
    logger.error('Unexpected error reading file:', error);
    throw new FileReadError(filePath, 
      error instanceof Error ? error.message : 'Unknown error'
    );
  }
}
```

### Pattern 2: Try-Catch with Recovery

Use when you can provide a default or fallback:

```typescript
async function getVariablesWithDefault(fileId: number): Promise<Variable[]> {
  try {
    return await database.getVariables(fileId);
  } catch (error) {
    logger.warn('Failed to retrieve variables, using empty list', { fileId, error });
    return []; // Fallback to empty list
  }
}
```

### Pattern 3: Try-Catch with Retry

Use for transient failures that might succeed on retry:

```typescript
async function executeWithRetry<T>(
  operation: () => Promise<T>,
  maxAttempts: number = 3,
  delayMs: number = 1000
): Promise<T> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt < maxAttempts) {
        const delay = delayMs * Math.pow(2, attempt - 1); // Exponential backoff
        logger.warn('Operation failed, retrying', { 
          attempt, 
          nextRetryMs: delay,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        logger.error('Operation failed after all retries:', error);
        throw error;
      }
    }
  }
}
```

### Pattern 4: Validation Before Processing

Validate inputs early to prevent cascading errors:

```typescript
function validateLessFilePath(filePath: string): void {
  if (!filePath || typeof filePath !== 'string') {
    throw new ValidationError('File path must be a non-empty string', { filePath });
  }

  if (!filePath.endsWith('.less')) {
    throw new ValidationError('File must have .less extension', { filePath });
  }

  if (filePath.includes('..')) {
    throw new ValidationError('File path contains path traversal attempt', { filePath });
  }
}

async function processFile(filePath: string): Promise<void> {
  validateLessFilePath(filePath); // Fail early with clear error
  
  // Rest of processing...
}
```

### Pattern 5: Graceful Degradation

Continue processing valid items when some fail:

```typescript
async function processAllFiles(filePaths: string[]): Promise<ProcessResult> {
  const successful: string[] = [];
  const failed: Array<{ path: string; error: string }> = [];

  for (const filePath of filePaths) {
    try {
      await processFile(filePath);
      successful.push(filePath);
    } catch (error) {
      failed.push({
        path: filePath,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
      logger.warn('Failed to process file, continuing with others', { filePath, error });
    }
  }

  if (failed.length > 0) {
    logger.warn(`${failed.length} files failed to process`, { failed });
  }

  return { successful, failed };
}
```

---

## Recovery Strategies

### Strategy 1: Retry with Exponential Backoff

For transient network/database errors:

```typescript
const MAX_RETRIES = 3;
const INITIAL_DELAY_MS = 1000;

async function connectWithRetry(): Promise<Client> {
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const client = new Client(config);
      await client.connect();
      logger.info('Database connection established', { attempt });
      return client;
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      
      if (attempt < MAX_RETRIES) {
        const delay = INITIAL_DELAY_MS * Math.pow(2, attempt - 1);
        logger.warn('Connection attempt failed, retrying', { attempt, nextDelayMs: delay });
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw new DatabaseConnectionError('localhost', 
    lastError?.message || 'All connection attempts failed'
  );
}
```

### Strategy 2: Fallback to Alternative

Use alternative source/method if primary fails:

```typescript
async function getFileContent(filePath: string): Promise<string> {
  try {
    // Try reading from disk
    return await fs.promises.readFile(filePath, 'utf-8');
  } catch (diskError) {
    logger.debug('Failed to read from disk, trying cache', { filePath });
    
    try {
      // Try reading from cache
      return await cache.get(filePath);
    } catch (cacheError) {
      logger.error('Both disk and cache failed:', diskError);
      throw new FileReadError(filePath, 'All sources unavailable');
    }
  }
}
```

### Strategy 3: Partial Success

Process what you can, report what you can't:

```typescript
interface BatchResult {
  successful: number;
  failed: number;
  errors: ProcessError[];
}

async function processBatch(items: Item[]): Promise<BatchResult> {
  const errors: ProcessError[] = [];
  let successful = 0;

  for (const item of items) {
    try {
      await processItem(item);
      successful++;
    } catch (error) {
      errors.push({
        item: item.id,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  const failed = items.length - successful;
  
  if (failed > 0) {
    logger.warn(`Batch processing completed with errors`, { 
      successful, 
      failed, 
      successRate: ((successful / items.length) * 100).toFixed(1) + '%'
    });
  }

  return { successful, failed, errors };
}
```

### Strategy 4: Cleanup and Rollback

Undo partial changes on failure:

```typescript
async function processWithRollback(files: File[]): Promise<void> {
  const processed: File[] = [];

  try {
    for (const file of files) {
      await processFile(file);
      processed.push(file);
    }
  } catch (error) {
    logger.error('Processing failed, rolling back', { processedCount: processed.length });
    
    try {
      // Undo all processed files
      for (const file of processed) {
        await undoProcessFile(file);
        logger.debug('Rolled back file', { fileId: file.id });
      }
    } catch (rollbackError) {
      logger.error('Rollback failed:', rollbackError);
      // This is critical - may need manual intervention
    }
    
    throw error;
  }
}
```

---

## Best Practices

### ✅ DO

```typescript
// 1. Create specific error types
if (condition) {
  throw new FileNotFoundError(path);
}

// 2. Include context in errors
throw new QueryError(query, `Connection timeout after ${timeout}ms`);

// 3. Log before throwing (if important)
logger.error('Critical operation failed:', error);
throw error;

// 4. Distinguish between different error types
try {
  operation();
} catch (error) {
  if (error instanceof ValidationError) {
    // Handle validation
  } else if (error instanceof DatabaseError) {
    // Handle database issue
  } else {
    // Handle unexpected
  }
}

// 5. Provide recovery options
try {
  return primaryMethod();
} catch {
  logger.warn('Primary failed, using secondary');
  return secondaryMethod();
}

// 6. Use finally for cleanup
try {
  const file = await openFile(path);
  processFile(file);
} finally {
  await file.close(); // Always runs
}
```

### ❌ DON'T

```typescript
// 1. Don't throw bare errors
throw new Error('Something went wrong'); // ❌
throw new CustomError('CODE', 'Something went wrong'); // ✅

// 2. Don't silently catch and continue
try {
  operation();
} catch (error) {
  // Silence! Very bad...
}

// 3. Don't throw in finally
try {
  operation();
} finally {
  throw new Error('In finally'); // ❌ Can mask original error
}

// 4. Don't ignore promise rejections
asyncOperation(); // ❌ Unhandled rejection
asyncOperation().catch(error => handleError(error)); // ✅

// 5. Don't use error for flow control
if (something) {
  throw new Error('Not a real error');
} // ❌ Errors are for exceptional cases

// 6. Don't lose error context
catch (error) {
  throw new Error('Failed'); // ❌ Original error lost
  throw new CustomError('CODE', 'Failed', 500, { originalError: error }); // ✅
}
```

---

## Error Scenarios

### Scenario 1: File Not Found

```typescript
async function loadLessFile(filePath: string): Promise<Content> {
  try {
    const content = await fs.promises.readFile(filePath, 'utf-8');
    return content;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      logger.warn('LESS file not found', { filePath });
      throw new FileNotFoundError(filePath);
    }
    
    logger.error('Unexpected file read error:', error);
    throw new FileReadError(filePath, 'Unexpected error');
  }
}

// Usage:
try {
  const content = await loadLessFile('./styles.less');
} catch (error) {
  if (error instanceof FileNotFoundError) {
    console.log('File not found - using default styles');
    return DEFAULT_STYLES;
  }
  throw error; // Re-throw if different error
}
```

### Scenario 2: Database Connection Failure

```typescript
async function initializeDatabase(): Promise<Client> {
  try {
    const client = new Client(config);
    await client.connect();
    logger.info('Database ready');
    return client;
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    
    if (message.includes('ECONNREFUSED')) {
      logger.error('Database server not running', { host: config.host });
      throw new DatabaseConnectionError(config.host, 'Server refused connection');
    }
    
    if (message.includes('authentication')) {
      logger.error('Database authentication failed');
      throw new DatabaseConnectionError(config.host, 'Invalid credentials');
    }
    
    logger.error('Database connection failed:', error);
    throw new DatabaseConnectionError(config.host, message);
  }
}
```

### Scenario 3: Parse Error with Line Number

```typescript
async function parseLessContent(content: string, filePath: string): Promise<AST> {
  try {
    return less.parse(content);
  } catch (error) {
    const lineNumber = (error as any).line || 0;
    const reason = (error as any).message || 'Unknown parse error';
    
    logger.error('Failed to parse LESS', { filePath, lineNumber, reason });
    
    throw new ParseError(filePath, lineNumber, reason);
  }
}
```

### Scenario 4: Circular Import Detection

```typescript
function checkCircularImports(importGraph: Map<string, string[]>): void {
  const visited = new Set<string>();
  const recursionStack = new Set<string>();

  function hasCycle(node: string, path: string[]): void {
    visited.add(node);
    recursionStack.add(node);

    const dependencies = importGraph.get(node) || [];
    
    for (const dep of dependencies) {
      if (!visited.has(dep)) {
        hasCycle(dep, [...path, dep]);
      } else if (recursionStack.has(dep)) {
        // Cycle detected
        const circlePath = [...path, dep];
        logger.error('Circular import detected', { path: circlePath });
        throw new CircularImportError(circlePath);
      }
    }

    recursionStack.delete(node);
  }

  for (const node of importGraph.keys()) {
    if (!visited.has(node)) {
      hasCycle(node, [node]);
    }
  }
}
```

---

## Error Response Format

When returning errors to clients, use consistent format:

```typescript
interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    statusCode: number;
    context?: Record<string, unknown>;
  };
}

// Example:
{
  "success": false,
  "error": {
    "code": "PARSE_ERROR",
    "message": "Parse error in styles.less at line 42: Unexpected token",
    "statusCode": 422,
    "context": {
      "filePath": "./styles.less",
      "lineNumber": 42,
      "reason": "Unexpected token }"
    }
  }
}
```

---

## Checklist for Error Handling

- [ ] All async operations wrapped in try-catch
- [ ] Custom error types used (not generic Error)
- [ ] Errors logged before throwing (for important errors)
- [ ] Error context included (path, IDs, line numbers, etc.)
- [ ] Different error types handled differently where possible
- [ ] Validation happens early
- [ ] Recoverable errors have recovery strategy
- [ ] Partial failures don't stop entire process
- [ ] Cleanup happens in finally blocks
- [ ] User-friendly error messages provided
- [ ] No console.log for errors (use logger)
- [ ] Tests verify error paths

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
