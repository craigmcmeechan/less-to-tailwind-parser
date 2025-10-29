import { Client, QueryResult } from 'pg';
import { LessFile } from './lessService.js';
import { logger } from '../utils/logger.js';

export interface DatabaseFile {
  id: number;
  file_name: string;
  file_path: string;
  relative_path: string;
  content: string;
  checksum: string;
  status: string;
}

export interface ImportRecord {
  id: number;
  parent_file_id: number;
  child_file_id: number;
  import_path: string;
  import_type: string;
  is_resolved: boolean;
}

export class DatabaseService {
  constructor(private client: Client) {}

  async storeLessFile(lessFile: LessFile): Promise<number> {
    const query = `
      INSERT INTO less_files (file_name, file_path, relative_path, content, checksum, status)
      VALUES ($1, $2, $3, $4, $5, 'pending')
      ON CONFLICT (file_path) DO UPDATE SET
        content = $4,
        checksum = $5,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id;
    `;

    try {
      const result = await this.client.query(query, [
        lessFile.fileName,
        lessFile.filePath,
        lessFile.relativePath,
        lessFile.content,
        lessFile.checksum,
      ]);

      return result.rows[0].id;
    } catch (error) {
      logger.error('Error storing LESS file:', error);
      throw error;
    }
  }

  async storeImportRelationship(
    parentFileId: number,
    childFilePath: string,
    importPath: string,
    importType: string = 'standard'
  ): Promise<void> {
    const query = `
      INSERT INTO less_imports (parent_file_id, child_file_id, import_path, import_type, is_resolved)
      SELECT $1, id, $3, $4, false
      FROM less_files
      WHERE file_path = $2
      ON CONFLICT DO NOTHING;
    `;

    try {
      await this.client.query(query, [parentFileId, childFilePath, importPath, importType]);
    } catch (error) {
      logger.error('Error storing import relationship:', error);
      throw error;
    }
  }

  async storeVariables(fileId: number, variables: Map<string, string>): Promise<void> {
    for (const [varName, varValue] of variables) {
      const query = `
        INSERT INTO less_variables (less_file_id, variable_name, variable_value)
        VALUES ($1, $2, $3)
        ON CONFLICT (less_file_id, variable_name) DO UPDATE SET
          variable_value = $3,
          updated_at = CURRENT_TIMESTAMP;
      `;

      try {
        await this.client.query(query, [fileId, varName, varValue]);
      } catch (error) {
        logger.error('Error storing variable:', error);
        throw error;
      }
    }
  }

  async getLessFileByPath(filePath: string): Promise<DatabaseFile | null> {
    const query = 'SELECT * FROM less_files WHERE file_path = $1;';

    try {
      const result = await this.client.query(query, [filePath]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error retrieving LESS file:', error);
      throw error;
    }
  }

  async getAllLessFiles(): Promise<DatabaseFile[]> {
    const query = 'SELECT * FROM less_files ORDER BY created_at DESC;';

    try {
      const result = await this.client.query(query);
      return result.rows;
    } catch (error) {
      logger.error('Error retrieving LESS files:', error);
      throw error;
    }
  }

  async updateFileStatus(fileId: number, status: string): Promise<void> {
    const query = 'UPDATE less_files SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2;';

    try {
      await this.client.query(query, [status, fileId]);
    } catch (error) {
      logger.error('Error updating file status:', error);
      throw error;
    }
  }

  async resolveImports(fileId: number): Promise<ImportRecord[]> {
    const query = `
      SELECT li.* FROM less_imports li
      WHERE li.parent_file_id = $1 AND li.is_resolved = false;
    `;

    try {
      const result = await this.client.query(query, [fileId]);
      return result.rows;
    } catch (error) {
      logger.error('Error resolving imports:', error);
      throw error;
    }
  }

  async markImportResolved(importId: number): Promise<void> {
    const query = `
      UPDATE less_imports
      SET is_resolved = true, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1;
    `;

    try {
      await this.client.query(query, [importId]);
    } catch (error) {
      logger.error('Error marking import as resolved:', error);
      throw error;
    }
  }

  async exportTailwindConfig(configName: string, configData: string): Promise<void> {
    const query = `
      INSERT INTO tailwind_exports (export_name, export_type, export_data, status)
      VALUES ($1, 'config', $2, 'completed')
      ON CONFLICT (export_name) DO UPDATE SET
        export_data = $2,
        updated_at = CURRENT_TIMESTAMP;
    `;

    try {
      await this.client.query(query, [configName, configData]);
      logger.info('Exported Tailwind configuration');
    } catch (error) {
      logger.error('Error exporting Tailwind config:', error);
      throw error;
    }
  }

  async getProcessingStats(): Promise<{
    total_files: number;
    processed_files: number;
    error_files: number;
  }> {
    const query = `
      SELECT
        COUNT(*) as total_files,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as processed_files,
        COUNT(CASE WHEN status = 'error' THEN 1 END) as error_files
      FROM less_files;
    `;

    try {
      const result = await this.client.query(query);
      return result.rows[0];
    } catch (error) {
      logger.error('Error getting processing stats:', error);
      throw error;
    }
  }
}
