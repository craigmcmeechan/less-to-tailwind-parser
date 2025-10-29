# ARCHITECTURE GUIDE

This document describes the overall system architecture, module organization, responsibilities, and data flow for the LESS to Tailwind parser.

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Layers](#architecture-layers)
3. [Module Responsibilities](#module-responsibilities)
4. [Data Flow](#data-flow)
5. [Dependency Map](#dependency-map)
6. [Key Design Decisions](#key-design-decisions)

---

## System Overview

### High-Level Purpose

The LESS to Tailwind parser is a transformation system that:

1. **Scans** multiple file system paths for LESS CSS files
2. **Parses** LESS syntax and hierarchical imports
3. **Stores** file data and relationships in PostgreSQL
4. **Extracts** variables, mixins, and theme information
5. **Exports** Tailwind CSS-compatible configuration and styles

### Technology Stack

- **Runtime:** Node.js
- **Language:** TypeScript (strict mode)
- **Database:** PostgreSQL with pg driver
- **LESS Parsing:** less.js library
- **Testing:** Jest with ts-jest
- **Linting:** ESLint
- **Formatting:** Prettier

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│  CLI / Entry Point (src/index.ts)                   │
│  - Parse command-line arguments                     │
│  - Initialize services                              │
│  - Orchestrate pipeline                             │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Service Layer (src/services/)                      │
│  - LessService: File scanning & LESS processing     │
│  - DatabaseService: Data persistence                │
│  - ExportService: Tailwind config generation        │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Data Layer (src/models/, src/database/)            │
│  - Type definitions and interfaces                  │
│  - Database connection & query builders             │
│  - Schema and migrations                            │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Utilities & Infrastructure                         │
│  - logger.ts: Structured logging                    │
│  - CustomError.ts: Error types                      │
│  - Validators: Input validation                     │
└─────────────────────────────────────────────────────┘
```

---

## Module Responsibilities

### Entry Point: `src/index.ts`

**Responsibility:** Orchestrate the entire pipeline

**Exports:** Main execution function

**Key Behaviors:**
- Load environment variables
- Initialize database connection
- Create service instances
- Execute processing stages in sequence
- Handle errors and cleanup

**NOT responsible for:**
- Business logic for any specific stage
- Direct database operations
- File I/O (except configuration)

---

### Service Layer

#### `services/lessService.ts`

**Responsibility:** File discovery and LESS processing

**Public Methods:**
- `scanLessFiles(paths: string[]): Promise<string[]>` - Find all LESS files
- `processLessFile(filePath: string): Promise<void>` - Parse and store single file
- `resolveImportHierarchy(): Promise<void>` - Build import graph
- `extractVariablesAndMixins(): Promise<void>` - Extract theme data

**Dependencies:**
- `DatabaseService` - Store file data
- `logger` - Logging

**NOT responsible for:**
- Database schema or direct SQL
- Tailwind config generation

---

#### `services/databaseService.ts`

**Responsibility:** All database interactions

**Public Methods:**
- `storeLessFile(data): Promise<number>` - Insert/upsert file
- `resolveImports(): Promise<void>` - Link import relationships
- `extractVariables(): Promise<void>` - Parse and store variables
- `getFileById(id): Promise<File>`
- `getAllLessFiles(): Promise<File[]>`
- `getImportHierarchy(fileId): Promise<Import[]>`

**Dependencies:**
- PostgreSQL `Client` from pg
- `logger` - Logging

**NOT responsible for:**
- File system operations
- LESS parsing
- Configuration generation

---

#### `services/exportService.ts`

**Responsibility:** Generate Tailwind-compatible output

**Public Methods:**
- `exportToTailwind(): Promise<TailwindConfig>` - Generate complete export

**Inputs:**
- File data from database
- Extracted variables and theme data

**Outputs:**
- `tailwind.config.js` file
- `styles.css` CSS variables file
- Tailwind theme configuration object

**NOT responsible for:**
- Parsing LESS syntax
- Database queries (uses DatabaseService)

---

### Data Layer

#### `database/connection.ts`

**Responsibility:** PostgreSQL connection lifecycle

**Exports:**
- `initializeDatabase(): Promise<Client>` - Connect and init schema
- Database configuration

**Behaviors:**
- Establish connection with retry logic
- Run schema migrations
- Handle connection errors

---

#### `database/schema.sql`

**Responsibility:** Database schema definition

**Defines:**
- `less_files` table - LESS files and metadata
- `less_imports` table - File dependencies
- `less_variables` table - Extracted variables/mixins
- `tailwind_exports` table - Generated output tracking
- `parse_history` table - Execution audit
- Indexes, triggers, ENUMs

---

#### `models/`

**Responsibility:** Type safety and data contracts

**Contains:**
- `LessFile` interface - File data structure
- `LessImport` interface - Import relationship
- `LessVariable` interface - Variable definition
- Type aliases for status, import types, etc.

---

### Utilities & Infrastructure

#### `utils/logger.ts`

**Responsibility:** Centralized structured logging

**Features:**
- Four log levels: DEBUG, INFO, WARN, ERROR
- Timestamp and level prefixes
- Environment-based level filtering
- Context data support

**Usage:** `import { logger } from './utils/logger.js'`

---

#### `errors/customError.ts` and application-specific errors

**Responsibility:** Typed error handling

**Provides:**
- Base `CustomError` class
- Specific error types: `FileNotFoundError`, `DatabaseConnectionError`, etc.
- Error codes and HTTP status codes
- Error context preservation

---

## Data Flow

### Complete Pipeline Flow

```
┌─────────────────────────────────────┐
│ 1. Initialization                   │
│ - Load .env                         │
│ - Connect to PostgreSQL             │
│ - Create service instances          │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 2. File Discovery (LessService)     │
│ - Read LESS_SCAN_PATHS from env     │
│ - Recursively find *.less files     │
│ - Collect absolute paths            │
└────────────┬────────────────────────┘
             │ → List of file paths
             ▼
┌─────────────────────────────────────┐
│ 3. File Storage (DatabaseService)   │
│ - Read each file content            │
│ - Calculate SHA256 checksum         │
│ - Store in less_files table         │
│ - Mark as 'completed'               │
└────────────┬────────────────────────┘
             │ → File IDs in database
             ▼
┌─────────────────────────────────────┐
│ 4. Import Resolution                │
│ - Extract @import statements        │
│ - Create parent→child relationships │
│ - Link to actual files              │
│ - Detect circular imports           │
└────────────┬────────────────────────┘
             │ → Import hierarchy mapped
             ▼
┌─────────────────────────────────────┐
│ 5. Variable Extraction              │
│ - Parse @variables from LESS        │
│ - Extract .mixin definitions        │
│ - Link to source files              │
│ - Categorize by theme (colors, etc) │
└────────────┬────────────────────────┘
             │ → Variables in database
             ▼
┌─────────────────────────────────────┐
│ 6. Tailwind Export (ExportService)  │
│ - Query all variables               │
│ - Map to Tailwind theme structure   │
│ - Generate tailwind.config.js       │
│ - Generate CSS variables file       │
└────────────┬────────────────────────┘
             │ → Config & CSS files
             ▼
┌─────────────────────────────────────┐
│ 7. Reporting & Cleanup              │
│ - Log completion statistics         │
│ - Close database connection         │
│ - Return success/failure status     │
└─────────────────────────────────────┘
```

### Data Transformation Through Pipeline

```
File System                  
    ↓ (paths)
LessService.scanLessFiles()
    ↓ (file paths)
LessService.processLessFile()
    ↓ (file content)
DatabaseService.storeLessFile()
    ↓ (stored as less_files row)
LessService.resolveImportHierarchy()
    ↓ (import graph built)
DatabaseService.resolveImports()
    ↓ (imports linked to files)
LessService.extractVariablesAndMixins()
    ↓ (variable definitions)
DatabaseService.extractVariables()
    ↓ (variables in database)
ExportService.exportToTailwind()
    ↓ (mapped to Tailwind structure)
File System (config + CSS)
```

---

## Dependency Map

### Service Dependencies

```
src/index.ts
  ├── initializeDatabase (from database/connection.ts)
  ├── LessService
  │   └── DatabaseService
  │       └── pg.Client
  ├── DatabaseService
  │   └── pg.Client
  └── ExportService
      └── DatabaseService

LessService
  └── fs (Node.js built-in)
      └── (implicitly file system)

DatabaseService
  ├── pg.Client
  ├── crypto (for checksums)
  └── logger

ExportService
  ├── fs (for writing output)
  ├── DatabaseService
  └── logger
```

### Layers Don't Skip

- ✅ `index.ts` → `LessService` → `DatabaseService`
- ✅ `ExportService` → `DatabaseService`
- ❌ Never: `index.ts` → `DatabaseService` directly
- ❌ Never: Services → `index.ts`

---

## Key Design Decisions

### 1. Separation of Concerns

**Decision:** Three distinct services for three concerns

**Rationale:**
- Each service has single responsibility
- Easy to test in isolation
- Future extensions (e.g., TypeScript support) just add another service
- Services can evolve independently

**Alternative Considered:** Single monolithic processor class
**Why Rejected:** Harder to test, less flexible, doesn't scale

---

### 2. Database-Driven Architecture

**Decision:** Store all intermediate data in database

**Rationale:**
- Resumable processing (if interrupted, can retry stages)
- Queryable history and audit trail
- Supports future analytics/reporting
- Can track import hierarchy queries

**Alternative Considered:** In-memory processing only
**Why Rejected:** Can't handle large projects, no failure recovery

---

### 3. Parameterized Queries

**Decision:** All database queries use parameters ($1, $2, etc.)

**Rationale:**
- SQL injection prevention
- Performance (query plan caching)
- Consistency and standards

**Never:** String concatenation for queries

---

### 4. Centralized Logging

**Decision:** Single logger instance, used everywhere

**Rationale:**
- Consistent log format
- Easy to redirect logs (file, cloud, etc.)
- Single place to adjust levels
- Supports debugging

**Alternative Considered:** console.log throughout
**Why Rejected:** Not controllable, not structured, not professional

---

### 5. Custom Error Types

**Decision:** Throw specific error types, not generic Error

**Rationale:**
- Caller can handle different errors differently
- Error context preserved and queryable
- Better error messages
- Type-safe error handling

---

### 6. Transaction Boundaries

**Decision:** Transactions scoped to logical operations

**Rationale:**
- Data consistency guaranteed
- All-or-nothing semantic
- Rollback on failure is automatic
- Clear atomicity boundaries

---

## Performance Considerations

### Indexing Strategy

All frequently queried columns have indexes:
- `less_files(status)` - For status filtering
- `less_imports(parent_file_id)` - For import hierarchy queries
- `less_variables(less_file_id)` - For variable lookups

### Batch Operations

Bulk inserts use single query:
```typescript
// INSERT ... VALUES ($1,$2), ($3,$4), ... - Single query
// Better than: FOR EACH INSERT - N queries
```

### Query Optimization

JOINs preferred over multiple queries (avoid N+1):
```typescript
// SELECT files WITH variables in ONE query
// Not: for each file, SELECT variables
```

---

## Extensibility Points

### Adding New File Formats

1. Create `TypeScriptService` (similar to `LessService`)
2. Create new database table for TypeScript-specific data
3. Create handler in `ExportService` for TypeScript → Tailwind
4. Wire into `index.ts` pipeline

### Adding New Export Formats

1. Create method in `ExportService`
2. Query relevant data from database
3. Transform to target format
4. Write output files

### Adding Pre/Post Processing

1. Create new service
2. Add step in `index.ts` pipeline
3. Wire input/output through database

---

## Deployment Architecture

```
Environment Setup
├── PostgreSQL instance (external or local)
├── Node.js runtime (v18+)
├── .env configuration
└── Input LESS paths

Application
├── src/ (TypeScript source)
├── dist/ (Compiled JavaScript)
├── database/ (Schema & migrations)
└── docs/ (Documentation)

Output
├── /output/tailwind.config.js
├── /output/styles.css
└── database (persisted state)
```

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
