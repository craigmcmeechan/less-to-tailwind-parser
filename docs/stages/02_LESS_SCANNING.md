# STAGE 2: LESS FILE SCANNING & VERSION TRACKING

**Duration:** 1.5 weeks  
**Status:** ⏳ Ready (after Stage 1 complete)  
**Dependencies:** Stage 1 (Database Foundation)  
**Enables:** Stage 3 (Import Hierarchy Resolution)

---

## Overview

Stage 2 implements robust LESS file discovery and version tracking with content-based change detection. Files are identified by UUID, versions tracked with diffs, and soft-delete handling for file removal.

**Two-Tier Approach:**
- **Core (Required):** Scheduled scanning of configured paths
- **Enhancement (Optional):** Real-time file watcher for development workflows

**Key Deliverable:** Complete file scanning with version history and audit trail.

---

## Objectives

1. ✅ Configure and store scan profiles (directories to scan)
2. ✅ Recursive directory traversal finding all .less files
3. ✅ Assign UUID to each file (content-based identity)
4. ✅ Calculate SHA256 checksum of file content
5. ✅ Detect changes via content hash comparison
6. ✅ Create new file versions when content changes
7. ✅ Generate unified diffs between versions
8. ✅ Track timestamps: first_scanned, last_scanned, deleted_at
9. ✅ Soft-delete missing files (mark deleted_at)
10. ✅ Restore deleted files if they reappear
11. ✅ CLI commands for profile management and scanning
12. ✅ (Optional) Real-time file watcher for active development

---

## Existing Codebase

**Already Complete:**
- Stage 1: Database connection and basic schema
- Stage 1: Logger utility
- Stage 1: Error handling patterns

**What Needs Building (Stage 2):**
- `scanned_files` table (file metadata)
- `file_versions` table (version history with content)
- `file_diffs` table (change tracking)
- `scan_profiles` table (configuration)
- `scan_history` table (audit trail)
- `ScanService` (core scanning logic)
- `FileWatcherService` (optional)
- CLI commands (scan.ts, profile.ts)

---

## Database Schema

### 1. `scan_profiles` - Configuration

```sql
CREATE TABLE scan_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  paths TEXT[] NOT NULL, -- Array of directories to scan
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_profiles_active ON scan_profiles(is_active);
```

**Example:**
```
id: "550e8400-e29b-41d4-a716-446655440000"
name: "Production Styles"
paths: ["/app/styles", "/app/components/styles", "/app/themes"]
is_active: true
```

---

### 2. `scanned_files` - File Registry

```sql
CREATE TABLE scanned_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_path VARCHAR(2048) NOT NULL UNIQUE,
  file_name VARCHAR(255) NOT NULL,
  scan_profile_id UUID NOT NULL,
  
  -- File system metadata
  fs_created TIMESTAMP,
  fs_modified TIMESTAMP,
  file_size_bytes INTEGER,
  
  -- Version tracking
  current_version_id UUID,
  
  -- Scan tracking
  first_scanned TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_scanned TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (scan_profile_id) REFERENCES scan_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (current_version_id) REFERENCES file_versions(id)
);

CREATE INDEX idx_files_profile ON scanned_files(scan_profile_id);
CREATE INDEX idx_files_path ON scanned_files(file_path);
CREATE INDEX idx_files_deleted ON scanned_files(deleted_at);
CREATE INDEX idx_files_last_scanned ON scanned_files(last_scanned DESC);
```

---

### 3. `file_versions` - Version History

```sql
CREATE TABLE file_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL,
  version_number INTEGER NOT NULL, -- 1, 2, 3...
  content TEXT NOT NULL,
  content_hash VARCHAR(64) NOT NULL, -- SHA256
  file_size_bytes INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  UNIQUE(file_id, version_number)
);

CREATE INDEX idx_versions_file ON file_versions(file_id);
CREATE INDEX idx_versions_hash ON file_versions(content_hash);
```

---

### 4. `file_diffs` - Change History

```sql
CREATE TABLE file_diffs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL,
  from_version_id UUID,
  to_version_id UUID NOT NULL,
  diff_type VARCHAR(50), -- 'created', 'modified', 'restored'
  diff_content TEXT, -- Unified diff format
  lines_added INTEGER,
  lines_removed INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (file_id) REFERENCES scanned_files(id) ON DELETE CASCADE,
  FOREIGN KEY (from_version_id) REFERENCES file_versions(id),
  FOREIGN KEY (to_version_id) REFERENCES file_versions(id)
);

CREATE INDEX idx_diffs_file ON file_diffs(file_id);
CREATE INDEX idx_diffs_created ON file_diffs(created_at DESC);
```

---

### 5. `scan_history` - Audit Trail

```sql
CREATE TABLE scan_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_profile_id UUID NOT NULL,
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  status VARCHAR(50) DEFAULT 'in_progress', -- in_progress, completed, error
  
  files_found INTEGER,
  files_added INTEGER,
  files_modified INTEGER,
  files_deleted INTEGER,
  files_restored INTEGER,
  
  error_message TEXT,
  
  FOREIGN KEY (scan_profile_id) REFERENCES scan_profiles(id) ON DELETE CASCADE
);

CREATE INDEX idx_history_profile ON scan_history(scan_profile_id);
CREATE INDEX idx_history_started ON scan_history(started_at DESC);
```

---

## Two-Tier Architecture

### Tier 1: Scheduled Scanning (Required)

**Core responsibility:** Full recursive scan of all configured paths

```
npm run scan

For each scan_profile marked active:
  ├─ Start scan_history record
  ├─ Walk all paths recursively
  ├─ For each .less file:
  │   ├─ Read file content
  │   ├─ Calculate SHA256
  │   ├─ Check if in scanned_files:
  │   │   ├─ YES:
  │   │   │   ├─ Compare hash to current_version
  │   │   │   ├─ If changed:
  │   │   │   │   ├─ Create new version
  │   │   │   │   ├─ Generate diff
  │   │   │   │   └─ Update current_version_id
  │   │   │   └─ Update last_scanned
  │   │   └─ NO:
  │   │       ├─ Create new scanned_file
  │   │       └─ Create initial version (v1)
  │   └─ Handle errors: skip file, log warning, continue
  │
  ├─ After processing all paths:
  │   ├─ Find files marked deleted that reappear
  │   │   └─ Update deleted_at = NULL
  │   ├─ Find files not in this scan
  │   │   └─ Mark deleted_at = NOW() (soft delete)
  │   └─ Update scan_history with statistics
  │
  └─ End scan_history
```

**Properties:**
- ✅ Repeatable (can run multiple times safely)
- ✅ Self-healing (recovers from errors)
- ✅ Content-based (detects real changes)
- ✅ Full state verification (marks missing as deleted)

---

### Tier 2: Real-Time Watcher (Optional Enhancement)

**Optional responsibility:** Detect changes during active development

```
npm run scan:watch

For each active profile:
  ├─ Watch all configured paths with chokidar
  ├─ On file change (debounced 500ms):
  │   ├─ Read file content
  │   ├─ Calculate SHA256
  │   ├─ Compare to current_version
  │   ├─ If changed:
  │   │   ├─ Create new version
  │   │   ├─ Generate diff
  │   │   ├─ Update current_version_id
  │   │   └─ Log: "File changed: {name} v{N}"
  │   └─ If same: skip (no change detected)
  │
  ├─ On file delete:
  │   └─ Update deleted_at = NOW()
  │
  └─ On file add:
      ├─ Create new scanned_file + version
      └─ Log: "File added: {name}"
```

**Implementation Note:**
- Watcher doesn't interfere with scan logic
- Watcher and scan can run simultaneously
- Scan validates/corrects any watcher inconsistencies
- Debounce: wait 500ms after last file event before processing

---

## Core Services

### ScanService

```typescript
// src/services/scanService.ts

export class ScanService {
  async scanProfile(profileId: string): Promise<ScanResult> {
    logger.info('Starting scan', { profileId });
    
    const profile = await loadProfile(profileId);
    const scanRecord = await createScanRecord(profileId);
    
    try {
      // Recursive directory walk
      const files = await this.walkDirectories(profile.paths);
      logger.info('Files found', { count: files.length });
      
      // Process each file
      for (const filePath of files) {
        await this.processFile(filePath, profile.id);
      }
      
      // Handle deletions
      await this.markMissingAsDeleted(profile.id, files);
      
      // Finalize scan
      await updateScanRecord(scanRecord.id, {
        status: 'completed',
        completed_at: NOW()
      });
      
      logger.info('Scan complete', scanRecord);
      return scanRecord;
    } catch (error) {
      await updateScanRecord(scanRecord.id, {
        status: 'error',
        error_message: error.message
      });
      throw error;
    }
  }

  private async processFile(
    filePath: string, 
    profileId: string
  ): Promise<void> {
    try {
      const content = await fs.promises.readFile(filePath, 'utf-8');
      const hash = calculateSHA256(content);
      const stat = await fs.promises.stat(filePath);
      
      const existing = await getScannedFile(filePath);
      
      if (!existing) {
        // New file
        await createScannedFile({
          file_path: filePath,
          file_name: path.basename(filePath),
          scan_profile_id: profileId,
          fs_created: stat.birthtime,
          fs_modified: stat.mtime,
          file_size_bytes: stat.size
        });
        
        await createVersion({
          file_id: newFile.id,
          version_number: 1,
          content,
          content_hash: hash,
          file_size_bytes: stat.size
        });
        
        logger.info('File added', { filePath });
      } else if (existing.current_version_id) {
        // Existing file - check for changes
        const currentVersion = await getVersion(existing.current_version_id);
        
        if (currentVersion.content_hash !== hash) {
          // File changed - create new version
          const newVersion = await createVersion({
            file_id: existing.id,
            version_number: currentVersion.version_number + 1,
            content,
            content_hash: hash,
            file_size_bytes: stat.size
          });
          
          // Generate diff
          await createDiff({
            file_id: existing.id,
            from_version_id: currentVersion.id,
            to_version_id: newVersion.id,
            diff_type: 'modified',
            diff_content: generateUnifiedDiff(currentVersion.content, content)
          });
          
          // Update current version
          await updateScannedFile(existing.id, {
            current_version_id: newVersion.id,
            fs_modified: stat.mtime,
            file_size_bytes: stat.size,
            last_scanned: NOW()
          });
          
          logger.info('File modified', { filePath, newVersion: newVersion.version_number });
        } else {
          // No changes
          await updateScannedFile(existing.id, {
            last_scanned: NOW()
          });
        }
      } else if (existing.deleted_at) {
        // File reappeared after deletion
        const newVersion = await createVersion({
          file_id: existing.id,
          version_number: (await getMaxVersion(existing.id)) + 1,
          content,
          content_hash: hash,
          file_size_bytes: stat.size
        });
        
        await createDiff({
          file_id: existing.id,
          from_version_id: null,
          to_version_id: newVersion.id,
          diff_type: 'restored'
        });
        
        await updateScannedFile(existing.id, {
          current_version_id: newVersion.id,
          deleted_at: null,
          last_scanned: NOW()
        });
        
        logger.info('File restored', { filePath });
      }
    } catch (error) {
      logger.warn('Error processing file', { filePath, error });
      // Continue scanning other files
    }
  }

  private async markMissingAsDeleted(
    profileId: string, 
    foundFiles: string[]
  ): Promise<void> {
    const allScanned = await getAllScannedFilesForProfile(profileId);
    const foundSet = new Set(foundFiles);
    
    for (const scanned of allScanned) {
      if (!foundSet.has(scanned.file_path) && !scanned.deleted_at) {
        await updateScannedFile(scanned.id, {
          deleted_at: NOW()
        });
        logger.info('File marked deleted', { filePath: scanned.file_path });
      }
    }
  }

  private async walkDirectories(paths: string[]): Promise<string[]> {
    const results: string[] = [];
    
    for (const dir of paths) {
      try {
        await this._walk(dir, results);
      } catch (error) {
        logger.warn('Error walking directory', { dir, error });
      }
    }
    
    return results;
  }

  private async _walk(dir: string, results: string[]): Promise<void> {
    const entries = await fs.promises.readdir(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory()) {
        // Skip node_modules and hidden directories
        if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
          await this._walk(fullPath, results);
        }
      } else if (entry.isFile() && entry.name.endsWith('.less')) {
        results.push(fullPath);
      }
    }
  }
}
```

---

## CLI Commands

### `npm run scan` - Manual Scan

```typescript
// src/cli/scan.ts

import { Command } from 'commander';

const program = new Command();

program
  .command('scan [profile]')
  .description('Scan LESS files for configured profile')
  .option('-a, --all', 'Scan all active profiles')
  .action(async (profile, options) => {
    try {
      if (options.all) {
        const profiles = await getAllActiveProfiles();
        for (const p of profiles) {
          await scanService.scanProfile(p.id);
        }
      } else {
        const profileId = profile || 'default';
        const result = await scanService.scanProfile(profileId);
        console.log(`Scanned: +${result.files_added} ~${result.files_modified} -${result.files_deleted}`);
      }
    } catch (error) {
      logger.error('Scan failed:', error);
      process.exit(1);
    }
  });

program.parse(process.argv);
```

### `npm run scan:profile:add` - Create Profile

```typescript
// src/cli/profile.ts - add subcommand

program
  .command('add')
  .description('Create new scan profile')
  .option('-n, --name <name>', 'Profile name')
  .option('-p, --paths <paths...>', 'Directories to scan')
  .action(async (options) => {
    const name = options.name || await prompt('Profile name:');
    const paths = options.paths || (await prompt('Paths (comma-separated):')).split(',');
    
    await createProfile({
      name,
      paths: paths.map(p => p.trim()),
      is_active: true
    });
    
    console.log(`✓ Profile "${name}" created`);
  });
```

### `npm run scan:profile:list` - List Profiles

```typescript
program
  .command('list')
  .description('List all scan profiles')
  .action(async () => {
    const profiles = await getAllProfiles();
    
    for (const p of profiles) {
      console.log(`${p.name} (${p.is_active ? 'active' : 'inactive'})`);
      console.log(`  Paths: ${p.paths.join(', ')}`);
    }
  });
```

---

## Testing Requirements

### Unit Tests

```typescript
// tests/scanService.test.ts

describe('ScanService', () => {
  it('should detect new LESS files', async () => {
    const file = createTempFile('.less', '@color: red;');
    const result = await scanService.scanProfile(testProfileId);
    
    expect(result.files_added).toBe(1);
  });

  it('should detect file changes via hash', async () => {
    const file = createTempFile('.less', '@color: red;');
    let result = await scanService.scanProfile(testProfileId);
    expect(result.files_added).toBe(1);
    
    // Modify file
    updateTempFile(file, '@color: blue;');
    result = await scanService.scanProfile(testProfileId);
    
    expect(result.files_modified).toBe(1);
  });

  it('should mark deleted files', async () => {
    const file = createTempFile('.less', '@color: red;');
    await scanService.scanProfile(testProfileId);
    
    fs.unlinkSync(file);
    const result = await scanService.scanProfile(testProfileId);
    
    expect(result.files_deleted).toBe(1);
  });

  it('should restore deleted files', async () => {
    const file = createTempFile('.less', '@color: red;');
    await scanService.scanProfile(testProfileId);
    
    fs.unlinkSync(file);
    await scanService.scanProfile(testProfileId);
    
    // Recreate file
    fs.writeFileSync(file, '@color: blue;');
    const result = await scanService.scanProfile(testProfileId);
    
    expect(result.files_restored).toBe(1);
  });

  it('should skip non-LESS files', async () => {
    createTempFile('.js', 'console.log("test");');
    createTempFile('.css', 'body { color: red; }');
    
    const result = await scanService.scanProfile(testProfileId);
    expect(result.files_found).toBe(0);
  });

  it('should generate unified diffs', async () => {
    const file = createTempFile('.less', 'line 1\nline 2\nline 3');
    await scanService.scanProfile(testProfileId);
    
    updateTempFile(file, 'line 1\nline 2 modified\nline 3');
    await scanService.scanProfile(testProfileId);
    
    const diff = await getDiffForFile(file);
    expect(diff.diff_content).toContain('line 2 modified');
  });
});
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] `scan_profiles` table stores configuration correctly
- [ ] `scanned_files` table tracks metadata with UUIDs
- [ ] `file_versions` table creates new versions on content change
- [ ] `file_diffs` table generates unified diffs
- [ ] `scan_history` table audits all scans
- [ ] `npm run scan` completes without errors
- [ ] New files detected and stored
- [ ] Modified files create new versions with diffs
- [ ] Deleted files marked with `deleted_at` timestamp
- [ ] Reappeared files restored (deleted_at set to NULL)
- [ ] SHA256 hash prevents false positives
- [ ] Files >100MB skipped with warning
- [ ] Permission errors logged, scanning continues
- [ ] Multiple profiles managed independently
- [ ] CLI commands working: scan, profile:add, profile:list
- [ ] Tests passing (>80% coverage)
- [ ] Logging per LOGGING_GUIDE.md
- [ ] Error handling per ERROR_HANDLING.md

---

## Deliverables Checklist

- [ ] Database migrations create all tables
- [ ] ScanService fully implemented
- [ ] SHA256 checksum calculation
- [ ] Unified diff generation
- [ ] CLI scan command
- [ ] CLI profile commands
- [ ] Unit tests for all scenarios
- [ ] Large file handling (>100MB skip)
- [ ] Permission error handling
- [ ] Package.json scripts configured
- [ ] Logging at appropriate levels

---

## Optional: File Watcher Enhancement

When Stage 2 is stable, add `FileWatcherService`:

```typescript
// src/services/fileWatcherService.ts

export class FileWatcherService {
  private watchers: FSWatcher[] = [];

  async watchProfile(profileId: string): Promise<void> {
    const profile = await getProfile(profileId);
    
    for (const path of profile.paths) {
      const watcher = chokidar.watch(path, {
        ignored: /(^|[\/\\])\.|node_modules/,
        awaitWriteFinish: { stabilityThreshold: 500 }
      });
      
      watcher.on('add', (filePath) => this.onFileAdd(filePath));
      watcher.on('change', (filePath) => this.onFileChange(filePath));
      watcher.on('unlink', (filePath) => this.onFileDelete(filePath));
      
      this.watchers.push(watcher);
    }
  }

  private async onFileChange(filePath: string): Promise<void> {
    // Similar to ScanService.processFile logic
    // Update version if content changed
  }
}
```

Install with: `npm run scan:watch`

---

## Success Verification

1. **Create profile:**
   ```bash
   npm run scan:profile:add -- --name "test" --paths "./test-less"
   ```

2. **List profiles:**
   ```bash
   npm run scan:profile:list
   ```

3. **Run scan:**
   ```bash
   npm run scan test
   ```
   → Output shows files found/added/modified

4. **Check database:**
   ```sql
   SELECT COUNT(*) FROM scanned_files;
   SELECT COUNT(*) FROM file_versions;
   SELECT COUNT(*) FROM file_diffs;
   ```

5. **Verify diffs:**
   ```sql
   SELECT * FROM file_diffs LIMIT 1;
   ```
   → Unified diff visible in diff_content

---

**Next Stage:** When Stage 2 passes all criteria, proceed to [Stage 3: Import Hierarchy Resolution](./03_IMPORT_HIERARCHY.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
