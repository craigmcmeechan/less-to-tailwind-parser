import * as fs from 'fs';
import * as path from 'path';
import { logger } from '../utils/logger.js';
import { DatabaseService } from './databaseService.js';

interface TailwindConfig {
  theme: {
    extend: Record<string, unknown>;
  };
  plugins: unknown[];
}

export class ExportService {
  constructor(private databaseService: DatabaseService) {}

  async exportToTailwind(): Promise<TailwindConfig> {
    try {
      const outputDir = process.env.OUTPUT_DIR || './output';
      
      // Create output directory if it doesn't exist
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      // Get all LESS files and variables
      const lessFiles = await this.databaseService.getAllLessFiles();
      
      // Build Tailwind configuration from extracted variables
      const tailwindConfig = await this.buildTailwindConfig(lessFiles);

      // Write configuration file
      const configPath = path.join(outputDir, 'tailwind.config.js');
      this.writeTailwindConfig(configPath, tailwindConfig);
      logger.info(`Tailwind config written to: ${configPath}`);

      // Generate CSS output
      const cssPath = path.join(outputDir, 'styles.css');
      const cssContent = await this.generateCss(lessFiles);
      fs.writeFileSync(cssPath, cssContent);
      logger.info(`CSS output written to: ${cssPath}`);

      return tailwindConfig;
    } catch (error) {
      logger.error('Error exporting to Tailwind:', error);
      throw error;
    }
  }

  private async buildTailwindConfig(lessFiles: any[]): Promise<TailwindConfig> {
    const config: TailwindConfig = {
      theme: {
        extend: {},
      },
      plugins: [],
    };

    // Process LESS files to extract theme values
    for (const file of lessFiles) {
      const variables = this.extractThemeVariables(file.content);
      Object.assign(config.theme.extend, variables);
    }

    return config;
  }

  private extractThemeVariables(content: string): Record<string, unknown> {
    const variables: Record<string, unknown> = {};

    // Extract color variables
    const colorPattern = /@([a-zA-Z0-9_-]*color[a-zA-Z0-9_-]*)\s*:\s*([^;]+);/gi;
    let match;

    while ((match = colorPattern.exec(content)) !== null) {
      const name = match[1].replace(/@/, '');
      variables[name] = match[2].trim();
    }

    // Extract spacing variables
    const spacingPattern = /@([a-zA-Z0-9_-]*(?:spacing|size|width|height|margin|padding)[a-zA-Z0-9_-]*)\s*:\s*([^;]+);/gi;
    while ((match = spacingPattern.exec(content)) !== null) {
      const name = match[1].replace(/@/, '');
      variables[name] = match[2].trim();
    }

    // Extract font variables
    const fontPattern = /@([a-zA-Z0-9_-]*(?:font|text)[a-zA-Z0-9_-]*)\s*:\s*([^;]+);/gi;
    while ((match = fontPattern.exec(content)) !== null) {
      const name = match[1].replace(/@/, '');
      variables[name] = match[2].trim();
    }

    return variables;
  }

  private async generateCss(lessFiles: any[]): Promise<string> {
    let css = '/* Generated from LESS files for Tailwind CSS */\n\n';

    css += ':root {\n';
    for (const file of lessFiles) {
      const variables = this.extractCssVariables(file.content);
      for (const [name, value] of Object.entries(variables)) {
        css += `  --${name}: ${value};\n`;
      }
    }
    css += '}\n';

    return css;
  }

  private extractCssVariables(content: string): Record<string, string> {
    const variables: Record<string, string> = {};
    const pattern = /@([a-zA-Z0-9_-]+)\s*:\s*([^;]+);/g;
    let match;

    while ((match = pattern.exec(content)) !== null) {
      variables[match[1]] = match[2].trim();
    }

    return variables;
  }

  private writeTailwindConfig(filePath: string, config: TailwindConfig): void {
    const configContent = `/** @type {import('tailwindcss').Config} */
export default ${JSON.stringify(config, null, 2)};
`;
    fs.writeFileSync(filePath, configContent);
  }
}
