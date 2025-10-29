import { Client } from 'pg';
import { logger } from '../utils/logger.js';
import crypto from 'crypto';

interface LessFileData {
  fileName: string;
  filePath: string;
  relativePath: string;
  content: string;
  fileSize: number;
}

export class DatabaseService {
  constructor(private client: Client) {}

  async storeLessFile(data: LessFileData): Promise<number> {
    const checksum = crypto
      .createHash('sha256')
      .update(data.content)
      .digest('hex');

    const result = await this.client.query(
      `INSERT INTO less_files (file_name, file_path, relative_path, content, file_size, checksum, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (file_path) DO UPDATE SET 
         content = $4, checksum = $6, updated_at = CURRENT_TIMESTAMP
       RETURNING id`,
      [data.fileName, data.filePath, data.relativePath, data.content, data.fileSize, checksum, 'completed']
    );

    return result.rows[0].id;
  }

  async resolveImports(): Promise<void> {
    try {
      // Get all unresolved imports
      const result = await this.client.query(
        `SELECT id, parent_file_id, import_path FROM less_imports WHERE is_resolved = FALSE`
      );

      for (const importRecord of result.rows) {
        try {
          // Try to find the imported file in the database
          const fileResult = await this.client.query(
            `SELECT id FROM less_files WHERE file_path LIKE $1 OR relative_path LIKE $1`,
            [`%${importRecord.import_path}%`]
          );

          if (fileResult.rows.length > 0) {
            await this.client.query(
              `UPDATE less_imports SET child_file_id = $1, is_resolved = TRUE WHERE id = $2`,
              [fileResult.rows[0].id, importRecord.id]
            );
          } else {
            await this.client.query(
              `UPDATE less_imports SET is_resolved = TRUE, resolution_error = $1 WHERE id = $2`,
              ['File not found in database', importRecord.id]
            );
          }
        } catch (error) {
          logger.error(`Error resolving import ${importRecord.id}:`, error);
        }
      }
    } catch (error) {
      logger.error('Error in resolveImports:', error);
      throw error;
    }
  }

  async extractVariables(): Promise<void> {
    try {
      const result = await this.client.query(
        `SELECT id, content FROM less_files WHERE status = 'completed'`
      );

      for (const file of result.rows) {
        const variables = this.parseVariables(file.content);

        for (const variable of variables) {
          await this.client.query(
            `INSERT INTO less_variables (less_file_id, variable_name, variable_type, variable_value, is_mixin)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT DO NOTHING`,
            [file.id, variable.name, variable.type, variable.value, variable.isMixin]
          );
        }
      }
    } catch (error) {
      logger.error('Error extracting variables:', error);
      throw error;
    }
  }

  private parseVariables(
    content: string
  ): Array<{ name: string; type: string; value: string; isMixin: boolean }> {
    const variables: Array<{ name: string; type: string; value: string; isMixin: boolean }> = [];

    // Simple regex patterns for LESS variables and mixins
    const variablePattern = /@([a-zA-Z0-9_-]+)\s*:\s*([^;]+);/g;
    const mixinPattern = /\.([a-zA-Z0-9_-]+)\s*\(([^)]*)\)\s*\{/g;

    let match;

    // Extract variables
    while ((match = variablePattern.exec(content)) !== null) {
      variables.push({
        name: match[1],
        type: 'variable',
        value: match[2].trim(),
        isMixin: false,
      });
    }

    // Extract mixins
    while ((match = mixinPattern.exec(content)) !== null) {
      variables.push({
        name: match[1],
        type: 'mixin',
        value: match[2].trim(),
        isMixin: true,
      });
    }

    return variables;
  }

  async getLessFileById(id: number): Promise<any> {
    const result = await this.client.query(
      `SELECT * FROM less_files WHERE id = $1`,
      [id]
    );
    return result.rows[0];
  }

  async getAllLessFiles(): Promise<any[]> {
    const result = await this.client.query(`SELECT * FROM less_files ORDER BY file_name`);
    return result.rows;
  }

  async getImportHierarchy(fileId: number): Promise<any[]> {
    const result = await this.client.query(
      `SELECT * FROM less_imports WHERE parent_file_id = $1 OR child_file_id = $1`,
      [fileId]
    );
    return result.rows;
  }
}
