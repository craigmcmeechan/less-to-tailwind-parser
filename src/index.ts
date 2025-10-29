import 'dotenv/config';
import { initializeDatabase } from './database/connection.js';
import { scanForLessFiles, extractImports, extractVariables, extractMixins } from './services/lessService.js';
import { DatabaseService } from './services/databaseService.js';
import { ExportService } from './services/exportService.js';
import { logger } from './utils/logger.js';
import * as path from 'path';

async function main(): Promise<void> {
  logger.info('Starting LESS to Tailwind Parser...');

  try {
    // Initialize database connection
    const client = await initializeDatabase();
    const dbService = new DatabaseService(client);
    const exportService = new ExportService(dbService);

    // Get scan paths from environment
    const scanPathsEnv = process.env.LESS_SCAN_PATHS || './less,./styles';
    const scanPaths = scanPathsEnv
      .split(',')
      .map(p => p.trim())
      .filter(p => p.length > 0);

    logger.info(`Scanning paths: ${scanPaths.join(', ')}`);

    // Scan for LESS files
    const lessFiles = await scanForLessFiles(scanPaths);

    if (lessFiles.length === 0) {
      logger.warn('No LESS files found');
      await client.end();
      return;
    }

    logger.info(`Found ${lessFiles.length} LESS files`);

    // Process each LESS file
    for (const lessFile of lessFiles) {
      try {
        logger.info(`Processing: ${lessFile.relativePath}`);

        // Store file in database
        const fileId = await dbService.storeLessFile(lessFile);
        logger.debug(`Stored file with ID: ${fileId}`);

        // Extract and store variables
        const variables = extractVariables(lessFile.content);
        if (variables.size > 0) {
          await dbService.storeVariables(fileId, variables);
          logger.debug(`Stored ${variables.size} variables`);
        }

        // Extract and process imports
        const imports = extractImports(lessFile.content);
        for (const importPath of imports) {
          // Resolve import path relative to current file
          const resolvedImportPath = path.resolve(
            path.dirname(lessFile.filePath),
            importPath + (importPath.endsWith('.less') ? '' : '.less')
          );

          try {
            await dbService.storeImportRelationship(fileId, resolvedImportPath, importPath);
            logger.debug(`Stored import: ${importPath}`);
          } catch (error) {
            logger.warn(`Could not resolve import ${importPath}:`, error);
          }
        }

        // Update file status to completed
        await dbService.updateFileStatus(fileId, 'completed');
      } catch (error) {
        logger.error(`Error processing file ${lessFile.relativePath}:`, error);
        try {
          // Store file first if it hasn't been stored yet
          const existingFile = await dbService.getLessFileByPath(lessFile.filePath);
          if (existingFile) {
            await dbService.updateFileStatus(existingFile.id, 'error');
          }
        } catch (updateError) {
          logger.error('Error updating file status:', updateError);
        }
      }
    }

    // Get processing statistics
    const stats = await dbService.getProcessingStats();
    logger.info(`Processing complete:
      - Total files: ${stats.total_files}
      - Processed: ${stats.processed_files}
      - Errors: ${stats.error_files}`);

    // Convert to Tailwind format
    logger.info('Converting to Tailwind configuration...');
    const tailwindConfig = await exportService.convertToTailwind();

    // Export to file
    const outputDir = process.env.OUTPUT_DIR || './output';
    const tailwindConfigPath =
      process.env.TAILWIND_CONFIG_OUTPUT || path.join(outputDir, 'tailwind.config.js');

    await exportService.exportToFile(tailwindConfig, tailwindConfigPath);

    // Generate and save CSS
    const cssOutput = await exportService.generateCSS(tailwindConfig);
    const cssPath = path.join(outputDir, 'generated.css');
    const fs = await import('fs/promises');
    await fs.writeFile(cssPath, cssOutput, 'utf-8');

    logger.info(`Output written to: ${outputDir}`);

    // Close database connection
    await client.end();
  } catch (error) {
    logger.error('Error in main process:', error);
    process.exit(1);
  }
}

// Run main function
main();
