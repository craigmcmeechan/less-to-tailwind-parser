import * as fs from 'fs/promises';
import * as path from 'path';
import { createHash } from 'crypto';
import { logger } from '../utils/logger.js';

export interface LessFile {
  filePath: string;
  relativePath: string;
  content: string;
  checksum: string;
  fileName: string;
}

export async function scanForLessFiles(scanPaths: string[]): Promise<LessFile[]> {
  const lessFiles: LessFile[] = [];

  for (const scanPath of scanPaths) {
    try {
      const files = await scanDirectoryRecursive(scanPath);
      lessFiles.push(...files);
    } catch (error) {
      logger.warn(`Failed to scan directory ${scanPath}:`, error);
    }
  }

  logger.info(`Found ${lessFiles.length} LESS files`);
  return lessFiles;
}

async function scanDirectoryRecursive(dirPath: string): Promise<LessFile[]> {
  const results: LessFile[] = [];

  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);

      if (entry.isDirectory()) {
        if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
          const subFiles = await scanDirectoryRecursive(fullPath);
          results.push(...subFiles);
        }
      } else if (entry.isFile() && (entry.name.endsWith('.less') || entry.name.endsWith('.LESS'))) {
        const content = await fs.readFile(fullPath, 'utf-8');
        const checksum = createHash('sha256').update(content).digest('hex');
        const relativePath = path.relative(process.cwd(), fullPath);

        results.push({
          filePath: fullPath,
          relativePath,
          content,
          checksum,
          fileName: entry.name,
        });

        logger.debug(`Scanned LESS file: ${relativePath}`);
      }
    }
  } catch (error) {
    logger.error(`Error scanning directory ${dirPath}:`, error);
    throw error;
  }

  return results;
}

export function extractImports(content: string): string[] {
  const importRegex = /@import\s+['"](.*?)['"]/g;
  const imports: string[] = [];
  let match;

  while ((match = importRegex.exec(content)) !== null) {
    imports.push(match[1]);
  }

  return imports;
}

export function extractVariables(content: string): Map<string, string> {
  const variables = new Map<string, string>();
  const variableRegex = /@([\w-]+)\s*:\s*([^;]+);/g;
  let match;

  while ((match = variableRegex.exec(content)) !== null) {
    variables.set(match[1], match[2].trim());
  }

  return variables;
}

export function extractMixins(content: string): Map<string, string> {
  const mixins = new Map<string, string>();
  const mixinRegex = /\.([\w-]+)\s*\([^)]*\)\s*\{[^}]*\}/g;
  let match;

  while ((match = mixinRegex.exec(content)) !== null) {
    mixins.set(match[1], match[0]);
  }

  return mixins;
}
