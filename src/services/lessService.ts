import * as fs from 'fs';
import * as path from 'path';
import { logger } from '../utils/logger.js';
import { DatabaseService } from './databaseService.js';

export class LessService {
  constructor(private databaseService: DatabaseService) {}

  async scanLessFiles(scanPaths: string[]): Promise<string[]> {
    const lessFiles: string[] = [];

    for (const scanPath of scanPaths) {
      const absolutePath = path.resolve(scanPath);
      
      if (!fs.existsSync(absolutePath)) {
        logger.warn(`Scan path does not exist: ${scanPath}`);
        continue;
      }

      const files = this.walkDirectory(absolutePath);
      lessFiles.push(...files);
    }

    return lessFiles;
  }

  private walkDirectory(dir: string): string[] {
    let results: string[] = [];
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory()) {
        results = results.concat(this.walkDirectory(fullPath));
      } else if (entry.name.endsWith('.less')) {
        results.push(fullPath);
      }
    }

    return results;
  }

  async processLessFile(filePath: string): Promise<void> {
    try {
      const content = fs.readFileSync(filePath, 'utf-8');
      const fileSize = fs.statSync(filePath).size;
      const relativePath = path.relative(process.cwd(), filePath);
      const fileName = path.basename(filePath);

      await this.databaseService.storeLessFile({
        fileName,
        filePath,
        relativePath,
        content,
        fileSize,
      });

      logger.info(`Processed LESS file: ${fileName}`);
    } catch (error) {
      logger.error(`Error processing LESS file ${filePath}:`, error);
    }
  }

  async resolveImportHierarchy(): Promise<void> {
    try {
      await this.databaseService.resolveImports();
      logger.info('Import hierarchy resolved');
    } catch (error) {
      logger.error('Error resolving import hierarchy:', error);
      throw error;
    }
  }

  async extractVariablesAndMixins(): Promise<void> {
    try {
      await this.databaseService.extractVariables();
      logger.info('Variables and mixins extracted');
    } catch (error) {
      logger.error('Error extracting variables:', error);
      throw error;
    }
  }
}
