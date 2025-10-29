import * as fs from 'fs/promises';
import * as path from 'path';
import { logger } from '../utils/logger.js';
import { DatabaseService } from './databaseService.js';

export interface TailwindConfig {
  theme: {
    extend: {
      colors?: Record<string, string>;
      spacing?: Record<string, string>;
      fontSize?: Record<string, string>;
      fontFamily?: Record<string, string>;
      [key: string]: Record<string, string> | undefined;
    };
  };
}

export class ExportService {
  constructor(private dbService: DatabaseService) {}

  async convertToTailwind(): Promise<TailwindConfig> {
    try {
      const files = await this.dbService.getAllLessFiles();
      const tailwindConfig: TailwindConfig = {
        theme: {
          extend: {},
        },
      };

      for (const file of files) {
        // Extract variables and convert to Tailwind theme config
        const variables = await this.extractVariablesFromContent(file.content);
        this.mergeVariablesToConfig(tailwindConfig, variables);
      }

      return tailwindConfig;
    } catch (error) {
      logger.error('Error converting to Tailwind:', error);
      throw error;
    }
  }

  private async extractVariablesFromContent(content: string): Promise<Map<string, string>> {
    const variables = new Map<string, string>();
    const variableRegex = /@([\w-]+)\s*:\s*([^;]+);/g;
    let match;

    while ((match = variableRegex.exec(content)) !== null) {
      const varName = match[1];
      const varValue = match[2].trim();
      variables.set(varName, varValue);
    }

    return variables;
  }

  private mergeVariablesToConfig(config: TailwindConfig, variables: Map<string, string>): void {
    const colorMap: Record<string, string> = {};
    const spacingMap: Record<string, string> = {};
    const fontSizeMap: Record<string, string> = {};

    for (const [name, value] of variables) {
      if (
        name.toLowerCase().includes('color') ||
        name.toLowerCase().includes('bg') ||
        name.toLowerCase().includes('text')
      ) {
        colorMap[this.camelToKebab(name)] = value;
      } else if (
        name.toLowerCase().includes('space') ||
        name.toLowerCase().includes('padding') ||
        name.toLowerCase().includes('margin')
      ) {
        spacingMap[this.camelToKebab(name)] = value;
      } else if (name.toLowerCase().includes('size') || name.toLowerCase().includes('font')) {
        fontSizeMap[this.camelToKebab(name)] = value;
      }
    }

    if (Object.keys(colorMap).length > 0) {
      config.theme.extend.colors = { ...config.theme.extend.colors, ...colorMap };
    }
    if (Object.keys(spacingMap).length > 0) {
      config.theme.extend.spacing = { ...config.theme.extend.spacing, ...spacingMap };
    }
    if (Object.keys(fontSizeMap).length > 0) {
      config.theme.extend.fontSize = { ...config.theme.extend.fontSize, ...fontSizeMap };
    }
  }

  private camelToKebab(str: string): string {
    return str.replace(/([a-z0-9]|(?=[A-Z]))([A-Z])/g, '$1-$2').toLowerCase();
  }

  async exportToFile(config: TailwindConfig, outputPath: string): Promise<void> {
    try {
      const outputDir = path.dirname(outputPath);

      // Ensure output directory exists
      await fs.mkdir(outputDir, { recursive: true });

      const configContent = this.generateTailwindConfigFile(config);
      await fs.writeFile(outputPath, configContent, 'utf-8');

      logger.info(`Exported Tailwind configuration to: ${outputPath}`);

      // Also store in database
      await this.dbService.exportTailwindConfig('main-config', JSON.stringify(config));
    } catch (error) {
      logger.error('Error exporting to file:', error);
      throw error;
    }
  }

  private generateTailwindConfigFile(config: TailwindConfig): string {
    return `/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
${this.stringifyThemeExtend(config.theme.extend)}
    },
  },
  plugins: [],
}
`;
  }

  private stringifyThemeExtend(extend: Record<string, Record<string, string> | undefined>): string {
    let result = '';

    for (const [key, value] of Object.entries(extend)) {
      if (value && typeof value === 'object') {
        result += `      ${key}: {\n`;
        for (const [k, v] of Object.entries(value)) {
          result += `        '${k}': '${v}',\n`;
        }
        result += '      },\n';
      }
    }

    return result;
  }

  async generateCSS(config: TailwindConfig): Promise<string> {
    let css = '/* Generated Tailwind CSS from LESS variables */\n\n';

    const colors = config.theme.extend.colors || {};
    if (Object.keys(colors).length > 0) {
      css += ':root {\n';
      for (const [name, value] of Object.entries(colors)) {
        css += `  --color-${name}: ${value};\n`;
      }
      css += '}\n\n';
    }

    return css;
  }
}
