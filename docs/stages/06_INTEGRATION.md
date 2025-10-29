# STAGE 6: INTEGRATION & OPERATIONS

**Duration:** 1.5 weeks  
**Status:** ⏳ Ready (after Stage 5 complete)  
**Dependencies:** All previous stages  
**Enables:** Stage 8 & 9 (Browser extensions and DOM analysis)

---

## Overview

Stage 6 integrates all previous stages into a cohesive CLI tool with automated workflows, scheduling, and operational monitoring. This transforms the parser from a collection of services into a production-ready system.

**Key Deliverable:** Complete CLI tool with automated scanning, export, and monitoring.

---

## Objectives

1. ✅ Unified CLI entry point (less-parser command)
2. ✅ Orchestrate all stages in sequence
3. ✅ Scheduled scanning (cron/node-schedule)
4. ✅ Configuration file (less-parser.config.json)
5. ✅ Environment management (.env support)
6. ✅ Health checks and monitoring
7. ✅ Export reports (JSON/HTML)
8. ✅ API server for programmatic access
9. ✅ Database maintenance and backups
10. ✅ Error recovery and resilience

---

## Database Schema

### 1. `system_config` - Runtime Configuration

```sql
CREATE TABLE system_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Configuration keys
  config_key VARCHAR(255) NOT NULL UNIQUE,
  config_value TEXT NOT NULL,
  config_type VARCHAR(50), -- 'string', 'number', 'boolean', 'json'
  
  -- Metadata
  description TEXT,
  is_system BOOLEAN DEFAULT false, -- System values vs user config
  
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_key_system UNIQUE(config_key)
);

CREATE INDEX idx_config_key ON system_config(config_key);
```

---

### 2. `system_health` - Health Monitoring

```sql
CREATE TABLE system_health (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Health status
  component VARCHAR(100), -- 'database', 'filesystem', 'parser', 'api'
  status VARCHAR(50), -- 'healthy', 'warning', 'error'
  message TEXT,
  
  -- Metrics
  last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  response_time_ms INTEGER,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_health_component ON system_health(component);
CREATE INDEX idx_health_status ON system_health(status);
CREATE INDEX idx_health_recent ON system_health(created_at DESC);
```

---

### 3. `operation_logs` - Audit Trail

```sql
CREATE TABLE operation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Operation details
  operation_type VARCHAR(100), -- 'scan', 'export', 'validate'
  operation_status VARCHAR(50), -- 'started', 'completed', 'error'
  
  -- Context
  profile_id UUID,
  user_id VARCHAR(255),
  triggered_by VARCHAR(100), -- 'manual', 'schedule', 'api'
  
  -- Results
  result_summary TEXT, -- JSON summary
  error_message TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_logs_type ON operation_logs(operation_type);
CREATE INDEX idx_logs_profile ON operation_logs(profile_id);
CREATE INDEX idx_logs_created ON operation_logs(created_at DESC);
```

---

## Core Services

### OrchestrationService

```typescript
// src/services/orchestrationService.ts

export class OrchestrationService {
  async runFullPipeline(profileId: string): Promise<PipelineResult> {
    const result: PipelineResult = {
      profileId,
      startedAt: new Date(),
      stages: [],
      success: true,
      errors: []
    };
    
    try {
      // Stage 2: Scan
      logger.info('Starting pipeline', { profileId });
      const scanResult = await this.runScan(profileId);
      result.stages.push({ stage: 2, result: scanResult });
      
      if (!scanResult.success) {
        throw new Error('Scan failed');
      }
      
      // Stage 3: Import Resolution
      const importResult = await this.runImportResolution(profileId);
      result.stages.push({ stage: 3, result: importResult });
      
      // Stage 4: Variable Extraction
      const varResult = await this.runVariableExtraction(profileId);
      result.stages.push({ stage: 4, result: varResult });
      
      // Stage 5: Tailwind Export
      const exportResult = await this.runTailwindExport(profileId);
      result.stages.push({ stage: 5, result: exportResult });
      
      result.completedAt = new Date();
      
      logger.info('Pipeline completed', result);
      
      await this.recordOperation('pipeline', 'completed', profileId, result);
      
    } catch (error) {
      result.success = false;
      result.errors.push(error.message);
      result.completedAt = new Date();
      
      logger.error('Pipeline failed', error);
      
      await this.recordOperation('pipeline', 'error', profileId, result);
      
      throw error;
    }
    
    return result;
  }

  private async runScan(profileId: string): Promise<StageResult> {
    try {
      const scanService = new ScanService();
      const result = await scanService.scanProfile(profileId);
      
      return {
        success: true,
        filesProcessed: result.files_found,
        filesAdded: result.files_added,
        filesModified: result.files_modified,
        filesDeleted: result.files_deleted
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  private async runImportResolution(profileId: string): Promise<StageResult> {
    try {
      const files = await getAllScannedFilesForProfile(profileId);
      const resolver = new ImportResolverService();
      
      let resolved = 0;
      let unresolved = 0;
      
      for (const file of files) {
        const result = await resolver.resolveImportsForFile(
          file.id,
          file.current_version_id
        );
        resolved += result.imports.length;
        unresolved += result.unresolved.length;
      }
      
      return {
        success: true,
        importsResolved: resolved,
        importsUnresolved: unresolved
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  private async runVariableExtraction(profileId: string): Promise<StageResult> {
    try {
      const files = await getAllScannedFilesForProfile(profileId);
      const extractor = new VariableExtractorService();
      const scopeBuilder = new ScopeHierarchyBuilder();
      
      let variablesExtracted = 0;
      
      // Build scope hierarchy first
      await scopeBuilder.buildScopeHierarchy(files.map(f => f.id));
      
      for (const file of files) {
        const scope = await getScopeHierarchy(file.id);
        const result = await extractor.extractVariablesFromFile(
          file.id,
          file.current_version_id,
          JSON.parse(scope.scope_chain)
        );
        variablesExtracted += result.variables.length;
      }
      
      return {
        success: true,
        variablesExtracted
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  private async runTailwindExport(profileId: string): Promise<StageResult> {
    try {
      const builder = new TailwindConfigBuilder();
      const exporter = new TailwindCSSExporter();
      const validator = new ConfigValidator();
      
      const config = await builder.buildConfig(profileId);
      const validation = validator.validate(config);
      
      if (!validation.valid) {
        throw new Error(`Config validation failed: ${validation.errors.join(', ')}`);
      }
      
      await exporter.exportToConfig(
        config,
        './tailwind.config.js'
      );
      
      const css = await exporter.generateCSSOutput(
        config,
        await getClassifiedVariables(profileId)
      );
      
      return {
        success: true,
        configGenerated: true,
        cssGenerated: true,
        warningCount: validation.warnings.length
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  private async recordOperation(
    type: string,
    status: string,
    profileId: string,
    result: any
  ): Promise<void> {
    await createOperationLog({
      operation_type: type,
      operation_status: status,
      profile_id: profileId,
      triggered_by: 'api',
      result_summary: JSON.stringify(result)
    });
  }
}
```

---

### SchedulerService

```typescript
// src/services/schedulerService.ts

import * as schedule from 'node-schedule';

export class SchedulerService {
  private jobs: Map<string, schedule.Job> = new Map();

  async scheduleProfile(profileId: string, cronExpression: string): Promise<void> {
    const profile = await getProfile(profileId);
    
    const job = schedule.scheduleJob(cronExpression, async () => {
      logger.info('Running scheduled scan', { profileId, profile: profile.name });
      
      try {
        const orchestration = new OrchestrationService();
        await orchestration.runFullPipeline(profileId);
      } catch (error) {
        logger.error('Scheduled pipeline failed', error);
      }
    });
    
    this.jobs.set(profileId, job);
    logger.info('Profile scheduled', { profileId, cron: cronExpression });
  }

  async cancelSchedule(profileId: string): Promise<void> {
    const job = this.jobs.get(profileId);
    if (job) {
      job.cancel();
      this.jobs.delete(profileId);
      logger.info('Schedule cancelled', { profileId });
    }
  }

  listSchedules(): Array<{ profileId: string; nextRun: Date }> {
    const schedules: Array<{ profileId: string; nextRun: Date }> = [];
    
    for (const [profileId, job] of this.jobs) {
      schedules.push({
        profileId,
        nextRun: job.nextInvocation()
      });
    }
    
    return schedules;
  }
}
```

---

## CLI Commands

### Main Entry Point

```bash
# Global commands
less-parser --help
less-parser --version

# Profile management
less-parser profile add --name production --paths ./styles ./components
less-parser profile list
less-parser profile delete production

# Scanning
less-parser scan production        # Single scan
less-parser scan --all             # Scan all profiles
less-parser scan:watch production  # Watch mode

# Scheduling
less-parser schedule add production --cron "0 2 * * *"  # Daily at 2am
less-parser schedule list
less-parser schedule remove production

# Export
less-parser export production      # Generate Tailwind config
less-parser export:validate        # Validate config

# Monitoring
less-parser health                 # Check system health
less-parser logs --tail 50         # Show recent logs
less-parser report --format json   # Generate report

# API
less-parser api:start --port 3000  # Start REST API
```

---

### Configuration File

```json
// less-parser.config.json
{
  "database": {
    "url": "${DATABASE_URL}",
    "ssl": true
  },
  "schedules": [
    {
      "profile": "production",
      "cron": "0 2 * * *"
    }
  ],
  "export": {
    "tailwindConfig": "./tailwind.config.js",
    "cssOutput": "./tailwind.css",
    "autoFormat": true
  },
  "api": {
    "port": 3000,
    "enableAuth": false
  },
  "logging": {
    "level": "info",
    "format": "json"
  }
}
```

---

## REST API

### Endpoints

```
POST   /api/profiles              - Create profile
GET    /api/profiles              - List profiles
GET    /api/profiles/:id          - Get profile
DELETE /api/profiles/:id          - Delete profile

POST   /api/scan/:profileId       - Trigger scan
GET    /api/scan/:profileId       - Get scan status
GET    /api/scan/:profileId/logs  - Get scan logs

GET    /api/variables             - List variables
GET    /api/variables/search      - Search variables

GET    /api/exports               - List exports
POST   /api/exports/:profileId    - Generate export

GET    /api/health                - Health check
GET    /api/metrics               - Metrics
```

---

## Health Checks

```typescript
// src/services/healthCheckService.ts

export class HealthCheckService {
  async checkAll(): Promise<HealthReport> {
    return {
      timestamp: new Date(),
      components: {
        database: await this.checkDatabase(),
        filesystem: await this.checkFilesystem(),
        parser: await this.checkParser()
      }
    };
  }

  private async checkDatabase(): Promise<HealthStatus> {
    try {
      const start = Date.now();
      await executeSQL('SELECT 1');
      const responseTime = Date.now() - start;
      
      return {
        status: 'healthy',
        responseTime,
        message: 'Database connection OK'
      };
    } catch (error) {
      return {
        status: 'error',
        message: error.message
      };
    }
  }
}
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] Unified CLI with all commands working
- [ ] Full pipeline orchestration (stages 2-5)
- [ ] Configuration file loading and validation
- [ ] Environment variable support
- [ ] Scheduled scanning functional
- [ ] REST API endpoints operational
- [ ] Health checks monitoring all components
- [ ] Operation logs recording all activities
- [ ] Error recovery and resilience testing
- [ ] Performance monitoring and metrics
- [ ] Database backup functionality
- [ ] CLI tests passing (>80% coverage)
- [ ] API tests passing (>80% coverage)
- [ ] Integration tests for full pipeline
- [ ] Documentation complete

---

**Next Stage:** When Stage 6 passes, proceed to [Stage 8: Chrome Extension](./08_CHROME_EXTENSION.md) or [Stage 9: DOM to Tailwind](./09_DOM_TO_TAILWIND.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
