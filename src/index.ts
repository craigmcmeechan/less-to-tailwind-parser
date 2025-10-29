import dotenv from 'dotenv';
import { logger } from './utils/logger.js';
import { initializeDatabase } from './database/connection.js';
import { LessService } from './services/lessService.js';
import { DatabaseService } from './services/databaseService.js';
import { ExportService } from './services/exportService.js';

// Load environment variables
dotenv.config();

async function main() {
  try {
    logger.info('Starting LESS to Tailwind Parser...');

    // Initialize database connection
    logger.info('Initializing database connection...');
    const client = await initializeDatabase();

    // Create service instances
    const databaseService = new DatabaseService(client);
    const lessService = new LessService(databaseService);
    const exportService = new ExportService(databaseService);

    // Get scan paths from environment
    const scanPaths = (process.env.LESS_SCAN_PATHS || './less,./styles')
      .split(',')
      .map(p => p.trim());

    logger.info(`Scanning paths: ${scanPaths.join(', ')}`);

    // Scan for LESS files
    const lessFiles = await lessService.scanLessFiles(scanPaths);
    logger.info(`Found ${lessFiles.length} LESS files`);

    // Store files in database
    for (const filePath of lessFiles) {
      await lessService.processLessFile(filePath);
    }

    // Resolve imports and build hierarchy
    logger.info('Resolving import hierarchy...');
    await lessService.resolveImportHierarchy();

    // Extract variables and mixins
    logger.info('Extracting variables and mixins...');
    await lessService.extractVariablesAndMixins();

    // Export to Tailwind CSS
    logger.info('Exporting to Tailwind CSS...');
    const tailwindConfig = await exportService.exportToTailwind();

    logger.info('Processing complete!');
    logger.info(`Output written to: ${process.env.OUTPUT_DIR}`);

    // Close database connection
    await client.end();
  } catch (error) {
    logger.error('Error in main process:', error);
    process.exit(1);
  }
}

// Run main function
main();
