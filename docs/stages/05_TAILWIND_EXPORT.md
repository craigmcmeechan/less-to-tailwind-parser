# STAGE 5: TAILWIND EXPORT & CONFIG GENERATION

**Duration:** 1.5 weeks  
**Status:** ⏳ Ready (after Stage 4 complete)  
**Dependencies:** Stage 4 (Variable Extraction)  
**Enables:** Stage 6 (Integration & Operations)

---

## Overview

Stage 5 converts the extracted LESS variables and classifications into Tailwind CSS configuration format and generates corresponding CSS output. This bridges from the source codebase analysis to usable Tailwind artifacts.

**Key Deliverable:** Production-ready `tailwind.config.js` and optimized CSS files.

---

## Objectives

1. ✅ Map LESS variables to Tailwind config structure
2. ✅ Generate `tailwind.config.js` with complete theme configuration
3. ✅ Convert classified variables to Tailwind defaults
4. ✅ Generate CSS utility classes from variables
5. ✅ Handle color palettes and shades
6. ✅ Support responsive design breakpoints
7. ✅ Export as valid JavaScript module
8. ✅ Minify/optimize output
9. ✅ Generate source maps for debugging
10. ✅ CLI commands for export and validation

---

## Database Schema

### 1. `tailwind_exports` - Export Metadata

```sql
CREATE TABLE tailwind_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Export configuration
  scan_profile_id UUID NOT NULL,
  export_name VARCHAR(255) NOT NULL,
  
  -- Variable mappings
  total_variables INTEGER,
  mapped_variables INTEGER,
  unmapped_variables INTEGER,
  
  -- Configuration
  config_path VARCHAR(2048),
  css_output_path VARCHAR(2048),
  
  -- Content
  config_content TEXT NOT NULL, -- tailwind.config.js content
  css_content TEXT, -- Generated CSS
  
  -- Metadata
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (scan_profile_id) REFERENCES scan_profiles(id) ON DELETE CASCADE
);

CREATE INDEX idx_exports_profile ON tailwind_exports(scan_profile_id);
CREATE INDEX idx_exports_generated ON tailwind_exports(generated_at DESC);
```

---

### 2. `tailwind_color_palettes` - Color Mappings

```sql
CREATE TABLE tailwind_color_palettes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Palette
  export_id UUID NOT NULL,
  color_name VARCHAR(255) NOT NULL,
  
  -- Shades
  palette TEXT NOT NULL, -- JSON: { "50": "#fff", "100": "#f3f", ... "900": "#000" }
  
  -- Source
  source_variable_ids TEXT, -- JSON array of variable IDs
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (export_id) REFERENCES tailwind_exports(id) ON DELETE CASCADE
);

CREATE INDEX idx_palettes_export ON tailwind_color_palettes(export_id);
CREATE INDEX idx_palettes_name ON tailwind_color_palettes(color_name);
```

---

## Core Services

### TailwindConfigBuilder

```typescript
// src/services/tailwindConfigBuilder.ts

export class TailwindConfigBuilder {
  async buildConfig(profileId: string): Promise<TailwindConfig> {
    const variables = await getClassifiedVariables(profileId);
    
    const config: TailwindConfig = {
      content: ['./src/**/*.{js,jsx,ts,tsx}'],
      theme: {
        extend: {
          colors: {},
          spacing: {},
          fontSize: {},
          fontWeight: {},
          borderRadius: {},
          boxShadow: {},
          opacity: {}
        }
      },
      plugins: []
    };
    
    // Group variables by category
    const grouped = this.groupByCategory(variables);
    
    for (const [category, vars] of Object.entries(grouped)) {
      const categoryConfig = this.buildCategoryConfig(category, vars);
      Object.assign(config.theme.extend[category], categoryConfig);
    }
    
    return config;
  }

  private groupByCategory(
    variables: ClassifiedVariable[]
  ): Record<string, ClassifiedVariable[]> {
    const grouped: Record<string, ClassifiedVariable[]> = {};
    
    for (const variable of variables) {
      const category = variable.tailwind_category || 'other';
      if (!grouped[category]) grouped[category] = [];
      grouped[category].push(variable);
    }
    
    return grouped;
  }

  private buildCategoryConfig(
    category: string,
    variables: ClassifiedVariable[]
  ): Record<string, any> {
    const config: Record<string, any> = {};
    
    if (category === 'colors') {
      return this.buildColorPalettes(variables);
    }
    
    for (const variable of variables) {
      const key = variable.tailwind_key || 'default';
      config[key] = variable.resolved_value;
    }
    
    return config;
  }

  private buildColorPalettes(
    colorVariables: ClassifiedVariable[]
  ): Record<string, any> {
    const palettes: Record<string, any> = {};
    
    // Group by base color name (primary, secondary, etc)
    const grouped = this.groupColorsByName(colorVariables);
    
    for (const [name, colors] of Object.entries(grouped)) {
      const palette = this.generateShadeScale(colors);
      palettes[name] = palette;
    }
    
    return palettes;
  }

  private groupColorsByName(
    colors: ClassifiedVariable[]
  ): Record<string, string[]> {
    const grouped: Record<string, string[]> = {};
    
    for (const color of colors) {
      // Extract base name (e.g., "primary" from "primary-500")
      const baseName = color.tailwind_key
        .replace(/-\d+$/, '')
        .replace(/^\d+$/, ''); // Remove trailing numbers
      
      if (!grouped[baseName]) grouped[baseName] = [];
      grouped[baseName].push(color.resolved_value);
    }
    
    return grouped;
  }

  private generateShadeScale(colors: string[]): Record<string, string> {
    const shades: Record<string, string> = {};
    const shadeNumbers = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
    
    // Simple distribution - assign colors to nearest shade
    for (let i = 0; i < Math.min(colors.length, shadeNumbers.length); i++) {
      shades[shadeNumbers[i]] = colors[i];
    }
    
    return shades;
  }
}
```

---

### TailwindCSSExporter

```typescript
// src/services/tailwindCssExporter.ts

export class TailwindCSSExporter {
  async exportToConfig(
    config: TailwindConfig,
    outputPath: string
  ): Promise<void> {
    const content = `
// Generated Tailwind configuration from LESS parser
// DO NOT EDIT MANUALLY - regenerate from LESS source

module.exports = ${JSON.stringify(config, null, 2)};
    `.trim();
    
    await fs.promises.writeFile(outputPath, content, 'utf-8');
  }

  async generateCSSOutput(
    config: TailwindConfig,
    variables: ClassifiedVariable[]
  ): Promise<string> {
    const css: string[] = [];
    
    // Add CSS custom properties (CSS variables)
    css.push(`:root {`);
    
    for (const variable of variables) {
      const cssVarName = this.toCssVariableName(variable.tailwind_key);
      css.push(`  --${cssVarName}: ${variable.resolved_value};`);
    }
    
    css.push(`}`);
    css.push('');
    
    // Add utility classes
    const utilities = this.generateUtilities(variables);
    css.push(...utilities);
    
    return css.join('\n');
  }

  private toCssVariableName(tailwindKey: string): string {
    return tailwindKey
      .toLowerCase()
      .replace(/([A-Z])/g, '-$1')
      .replace(/-+/g, '-');
  }

  private generateUtilities(
    variables: ClassifiedVariable[]
  ): string[] {
    const utilities: string[] = [];
    
    for (const variable of variables) {
      const category = variable.tailwind_category;
      const key = variable.tailwind_key;
      
      if (category === 'colors') {
        // Generate color utilities
        utilities.push(`.text-${key} { color: ${variable.resolved_value}; }`);
        utilities.push(`.bg-${key} { background-color: ${variable.resolved_value}; }`);
        utilities.push(`.border-${key} { border-color: ${variable.resolved_value}; }`);
      } else if (category === 'spacing') {
        utilities.push(`.m-${key} { margin: ${variable.resolved_value}; }`);
        utilities.push(`.p-${key} { padding: ${variable.resolved_value}; }`);
      } else if (category === 'fontSize') {
        utilities.push(`.text-${key} { font-size: ${variable.resolved_value}; }`);
      }
    }
    
    return utilities;
  }
}
```

---

### ConfigValidator

```typescript
// src/services/configValidator.ts

export class ConfigValidator {
  validate(config: TailwindConfig): ValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];
    
    // Validate required fields
    if (!config.content || config.content.length === 0) {
      errors.push('Missing content field');
    }
    
    if (!config.theme) {
      errors.push('Missing theme configuration');
    }
    
    // Validate colors are valid hex/rgb
    for (const [name, color] of Object.entries(config.theme?.extend?.colors || {})) {
      if (!this.isValidColor(color)) {
        warnings.push(`Invalid color for ${name}: ${color}`);
      }
    }
    
    // Validate no duplicate keys
    const allKeys = new Set<string>();
    const themeKeys = Object.keys(config.theme?.extend || {});
    
    for (const key of themeKeys) {
      if (allKeys.has(key)) {
        errors.push(`Duplicate key in theme: ${key}`);
      }
      allKeys.add(key);
    }
    
    return {
      valid: errors.length === 0,
      errors,
      warnings
    };
  }

  private isValidColor(value: any): boolean {
    if (typeof value === 'string') {
      return /^#[0-9A-F]{6}$|^rgb/i.test(value);
    }
    
    if (typeof value === 'object' && value !== null) {
      // Check if all values are valid colors
      return Object.values(value).every(v =>
        this.isValidColor(v)
      );
    }
    
    return false;
  }
}
```

---

## CLI Commands

### `npm run export:tailwind [profile]` - Generate Config

```bash
npm run export:tailwind production

# Output:
# Generating Tailwind configuration...
# ✓ 847 variables mapped
# ✓ 3 color palettes generated
# ✓ Config written to tailwind.config.js
# ✓ CSS output written to tailwind.css
# Validation: PASS
```

### `npm run export:validate` - Validate Config

```bash
npm run export:validate

# Output:
# Validating tailwind.config.js...
# ✓ Configuration is valid
# - 200+ color utilities generated
# - 50+ spacing utilities generated
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] `tailwind.config.js` generated with correct structure
- [ ] All classified variables included in config
- [ ] Color palettes built correctly (50-900 shades)
- [ ] Spacing values formatted for Tailwind
- [ ] Font sizes, weights, border radius included
- [ ] CSS custom properties (--variables) generated
- [ ] Generated CSS is valid
- [ ] Config validates with Tailwind schema
- [ ] Color validation catches invalid values
- [ ] Output minified/optimized
- [ ] Source maps generated for debugging
- [ ] CLI commands working: export:tailwind, export:validate
- [ ] Tests passing (>80% coverage)

---

**Next Stage:** When Stage 5 passes, proceed to [Stage 6: Integration & Operations](./06_INTEGRATION.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
