import { Client } from 'pg';
import { logger } from '../utils/logger.js';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function initializeDatabase(): Promise<Client> {
  const client = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'less_to_tailwind',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password',
  });

  try {
    await client.connect();
    logger.info('Connected to PostgreSQL database');

    // Run migrations
    await runMigrations(client);

    return client;
  } catch (error) {
    logger.error('Failed to connect to database:', error);
    throw error;
  }
}

async function runMigrations(client: Client): Promise<void> {
  try {
    const schemaPath = path.join(__dirname, '../../database/schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf-8');

    await client.query(schemaSql);
    logger.info('Database schema initialized');
  } catch (error) {
    logger.error('Migration error:', error);
    throw error;
  }
}
