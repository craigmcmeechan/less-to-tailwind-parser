# LOGGING GUIDE

This document defines logging standards and patterns for all stages. All code must use the centralized logger utility for consistent, traceable logging.

## Table of Contents

1. [Logger Overview](#logger-overview)
2. [Logger Levels](#logger-levels)
3. [Using the Logger](#using-the-logger)
4. [Logging Patterns](#logging-patterns)
5. [Best Practices](#best-practices)
6. [Examples by Scenario](#examples-by-scenario)

---

## Logger Overview

The project uses a custom logger utility (`src/utils/logger.ts`) that provides structured logging with the following features:

- **Consistent formatting** - All logs include timestamps and level indicators
- **Level-based filtering** - Control verbosity via `LOG_LEVEL` environment variable
- **No external dependencies** - Uses native console for simplicity
- **Production ready** - Safe to use in all environments

### Logger Instance

```typescript
import { logger } from './utils/logger.js';
```

The logger is a singleton, so import it wherever needed.

---

## Logger Levels

The logger supports 4 levels with increasing severity:

### 1. DEBUG

**When to use:** Development only, detailed diagnostic information

```typescript
logger.debug('Scanning directory for LESS files', { path: './styles', recursive: true });
logger.debug('Cache hit for file', { fileId: 123, age: '2s' });
```

**Console output:**
```
[2025-10-29T14:45:22.123Z] [DEBUG] Scanning directory for LESS files {"path":"./styles","recursive":true}
```

### 2. INFO

**When to use:** Important lifecycle events, successful operations

```typescript
logger.info('Database connection established');
logger.info('Found 145 LESS files in total');
logger.info('Processing complete - 142 files stored');
```

**Console output:**
```
[2025-10-29T14:45:22.456Z] [INFO] Database connection established
```

### 3. WARN

**When to use:** Recoverable issues, warnings about potential problems

```typescript
logger.warn('File not found - skipping', { path: './missing.less' });
logger.warn('Circular import detected - may cause issues', { files: ['a.less', 'b.less'] });
logger.warn('Falling back to default configuration');
```

**Console output:**
```
[2025-10-29T14:45:22.789Z] [WARN] File not found - skipping {"path":"./missing.less"}
```

### 4. ERROR

**When to use:** Errors and exceptions that require attention

```typescript
logger.error('Failed to parse LESS file:', error);
logger.error('Database connection failed:', new Error('Connection timeout'));
```

**Console output:**
```
[2025-10-29T14:45:23.012Z] [ERROR] Failed to parse LESS file: Error: Invalid LESS syntax
  at parseLess (src/parser/lessParser.ts:45:12)
  at processFile (src/services/lessService.ts:120:8)
```

---

## Using the Logger

### Basic Usage

```typescript
import { logger } from '../utils/logger.js';

// Simple message
logger.info('Starting application');

// Message with context
logger.debug('User action', { userId: 123, action: 'login' });

// Error with stack trace
try {
  // something
} catch (error) {
  logger.error('Operation failed:', error);
}
```

### Environment Variables

Control logging level via `.env`:

```bash
# .env
LOG_LEVEL=info     # Only INFO and above (INFO, WARN, ERROR)
# or
LOG_LEVEL=debug    # All levels (DEBUG, INFO, WARN, ERROR)
# or
LOG_LEVEL=warn     # Only WARN and ERROR
# or
LOG_LEVEL=error    # Only ERROR
```

Default is `INFO` if not specified.

---

## Logging Patterns

### Pattern 1: Function Entry/Exit

Log when entering critical functions and exiting:

```typescript
async function processLessFile(filePath: string): Promise<void> {
  logger.debug('Entering processLessFile', { filePath });
  
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const parsed = parseLess(content);
    await storeInDatabase(parsed);
    
    logger.info('LESS file processed successfully', { filePath });
  } catch (error) {
    logger.error('Failed to process LESS file:', error);
    throw error;
  }
}
```

### Pattern 2: State Changes

Log when important state changes occur:

```typescript
async function updateFileStatus(fileId: number, status: FileStatus): Promise<void> {
  logger.info('Updating file status', { fileId, newStatus: status });
  
  await database.update('less_files', { status }, { id: fileId });
  
  logger.debug('File status updated in database', { fileId, status });
}
```

### Pattern 3: Error Handling

Log errors before throwing or recovering:

```typescript
try {
  const result = await riskyOperation();
} catch (error) {
  logger.warn('Operation failed, retrying with fallback', { 
    error: error instanceof Error ? error.message : 'Unknown error',
    attempt: attempt + 1
  });
  return fallbackValue;
}
```

### Pattern 4: Performance/Metrics

Log performance-related information:

```typescript
const startTime = Date.now();

const files = await scanDirectory('./styles');

const duration = Date.now() - startTime;
logger.info('Directory scan completed', { 
  fileCount: files.length, 
  durationMs: duration,
  filesPerSecond: (files.length / (duration / 1000)).toFixed(2)
});
```

### Pattern 5: Data Validation

Log when data fails validation:

```typescript
function validateLessVariable(variable: unknown): boolean {
  if (!isValidVariable(variable)) {
    logger.warn('Invalid variable format', { 
      variable: JSON.stringify(variable),
      expected: 'name: value'
    });
    return false;
  }
  return true;
}
```

---

## Best Practices

### ✅ DO

```typescript
// 1. Include context in logs
logger.info('File stored in database', { 
  fileName: 'main.less',
  fileSize: 1024,
  checksum: 'abc123',
  timestamp: new Date().toISOString()
});

// 2. Log errors with full context
logger.error('Failed to resolve import', error);

// 3. Use appropriate levels
logger.debug('Detailed trace info');     // Developers only
logger.info('Important event');          // Always visible
logger.warn('Something unexpected');     // Requires attention
logger.error('Critical failure');        // Must fix

// 4. Log before throwing
try {
  operation();
} catch (error) {
  logger.error('Operation failed:', error);
  throw error;
}

// 5. Include variable names and values
logger.debug('Processing batch', { 
  batchSize: batch.length, 
  startIndex: startIdx 
});

// 6. Use structured data
logger.info('Import resolved', {
  parentFile: parent.path,
  childFile: child.path,
  importPath: '@import "./style.less"'
});
```

### ❌ DON'T

```typescript
// 1. Don't use console.log
console.log('Something happened'); // ❌ Use logger instead

// 2. Don't log sensitive data
logger.info('User data', { password: userData.password }); // ❌ Never log passwords

// 3. Don't create unstructured logs
logger.info('Random debug info: ' + someValue); // ❌ Use structured data
logger.info('The result is ' + result + ' and status is ' + status);

// 4. Don't log at wrong level
logger.info('Minor debug detail'); // ❌ Should be debug()
logger.debug('Fatal error occurred'); // ❌ Should be error()

// 5. Don't leave console.log/debug in production code
if (process.env.NODE_ENV === 'development') {
  console.log('temp debug'); // ❌ Use logger or remove
}

// 6. Don't log without error context
catch (error) {
  logger.warn('Something went wrong'); // ❌ Need to log the error
}
```

---

## Examples by Scenario

### Database Operations

```typescript
async function storeLessFile(data: LessFileData): Promise<number> {
  logger.debug('Attempting to store LESS file', { 
    fileName: data.fileName,
    size: data.fileSize 
  });

  try {
    const result = await client.query(
      'INSERT INTO less_files (...) VALUES ($1, $2, ...)',
      [data.fileName, data.filePath, ...]
    );

    const id = result.rows[0].id;
    logger.info('LESS file stored successfully', { 
      fileId: id,
      fileName: data.fileName 
    });

    return id;
  } catch (error) {
    logger.error('Failed to store LESS file in database:', error);
    throw new DatabaseError(`Could not store file: ${data.fileName}`);
  }
}
```

### File Processing Loop

```typescript
async function processAllLessFiles(filePaths: string[]): Promise<void> {
  logger.info('Starting batch processing', { 
    totalFiles: filePaths.length 
  });

  let successCount = 0;
  let failureCount = 0;

  for (const filePath of filePaths) {
    try {
      logger.debug('Processing file', { filePath });
      
      await processLessFile(filePath);
      
      successCount++;
      logger.debug('File processed', { filePath, successCount });
    } catch (error) {
      failureCount++;
      logger.warn(`Failed to process file (${failureCount}/${filePaths.length})`, { 
        filePath,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  logger.info('Batch processing completed', {
    total: filePaths.length,
    successful: successCount,
    failed: failureCount,
    successRate: ((successCount / filePaths.length) * 100).toFixed(1) + '%'
  });
}
```

### Import Resolution

```typescript
async function resolveImports(): Promise<void> {
  logger.info('Starting import resolution');

  const unresolvedImports = await getUnresolvedImports();
  logger.debug('Found unresolved imports', { count: unresolvedImports.length });

  let resolvedCount = 0;
  let failedCount = 0;

  for (const importRecord of unresolvedImports) {
    try {
      logger.debug('Resolving import', { 
        parentFileId: importRecord.parentFileId,
        importPath: importRecord.importPath 
      });

      const childFileId = await findFileByPath(importRecord.importPath);
      
      if (childFileId) {
        await markImportResolved(importRecord.id, childFileId);
        resolvedCount++;
        logger.debug('Import resolved', { 
          importId: importRecord.id,
          childFileId 
        });
      } else {
        logger.warn('Could not find imported file', {
          importPath: importRecord.importPath,
          parentFileId: importRecord.parentFileId
        });
        failedCount++;
      }
    } catch (error) {
      logger.error('Error resolving import:', error);
      failedCount++;
    }
  }

  logger.info('Import resolution completed', {
    total: unresolvedImports.length,
    resolved: resolvedCount,
    failed: failedCount
  });
}
```

### Error Recovery

```typescript
async function ensureDatabaseConnection(retries = 3): Promise<Client> {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      logger.debug('Attempting database connection', { attempt, maxAttempts: retries });
      
      const client = new Client(config);
      await client.connect();
      
      logger.info('Database connection established successfully', { attempt });
      return client;
    } catch (error) {
      if (attempt < retries) {
        const delay = Math.pow(2, attempt) * 1000; // Exponential backoff
        logger.warn('Database connection failed, retrying', {
          attempt,
          nextRetryMs: delay,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
        
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        logger.error('Failed to establish database connection after all retries:', error);
        throw error;
      }
    }
  }
}
```

---

## Log Output Examples

### Successful Run

```
[2025-10-29T14:45:00.123Z] [INFO] Starting LESS to Tailwind Parser
[2025-10-29T14:45:00.145Z] [INFO] Database connection established
[2025-10-29T14:45:00.156Z] [INFO] Found 145 LESS files in total
[2025-10-29T14:45:02.234Z] [INFO] LESS files scanned and stored
[2025-10-29T14:45:05.456Z] [INFO] Import hierarchy resolved - 142 imports resolved
[2025-10-29T14:45:06.789Z] [INFO] Variables and mixins extracted - 287 total
[2025-10-29T14:45:07.012Z] [INFO] Tailwind CSS exported successfully
[2025-10-29T14:45:07.023Z] [INFO] Processing complete
```

### With Warnings

```
[2025-10-29T14:45:00.123Z] [INFO] Starting LESS to Tailwind Parser
[2025-10-29T14:45:00.145Z] [INFO] Database connection established
[2025-10-29T14:45:00.156Z] [INFO] Found 150 LESS files in total
[2025-10-29T14:45:00.789Z] [WARN] File not found - skipping {"path":"./styles/missing.less"}
[2025-10-29T14:45:01.234Z] [WARN] Circular import detected {"files":["a.less","b.less"]}
[2025-10-29T14:45:02.234Z] [INFO] LESS files scanned and stored - 148 successful
[2025-10-29T14:45:05.456Z] [INFO] Import hierarchy resolved - 140 imports resolved
[2025-10-29T14:45:06.789Z] [INFO] Variables and mixins extracted - 285 total
```

### With Errors

```
[2025-10-29T14:45:00.123Z] [INFO] Starting LESS to Tailwind Parser
[2025-10-29T14:45:00.145Z] [INFO] Database connection established
[2025-10-29T14:45:00.156Z] [INFO] Found 145 LESS files
[2025-10-29T14:45:01.234Z] [ERROR] Failed to parse LESS file: Error: Invalid LESS syntax
    at parse (src/parser/lessParser.ts:45:12)
    at processFile (src/services/lessService.ts:120:8)
[2025-10-29T14:45:01.235Z] [WARN] Skipping invalid file and continuing {"file":"./styles/broken.less"}
[2025-10-29T14:45:02.234Z] [INFO] LESS files scanned and stored - 144 successful, 1 failed
```

---

## Accessing Logs

### In Development

Set `LOG_LEVEL=debug` in `.env` to see all logs:

```bash
LOG_LEVEL=debug npm run dev
```

### In Production

Set `LOG_LEVEL=info` or `LOG_LEVEL=warn`:

```bash
LOG_LEVEL=info npm start
```

### Redirecting to File

```bash
npm start > app.log 2>&1
```

---

## Troubleshooting

**Problem:** Not seeing debug logs  
**Solution:** Check `LOG_LEVEL` is set to `debug` in `.env`

**Problem:** Too many logs, output is noisy  
**Solution:** Set `LOG_LEVEL=warn` or `LOG_LEVEL=error`

**Problem:** Can't find specific log message  
**Solution:** Use grep or search in log file
```bash
cat app.log | grep "keyword"
```

---

## Logger Implementation

For details on the logger implementation, see `src/utils/logger.ts`.

The logger is already implemented and ready to use - just import and use it as shown in the examples above.

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
