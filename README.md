# LESS to Tailwind Parser

A TypeScript-based tool that scans LESS CSS files from specified directories, parses their hierarchical structure with imports, stores the data in PostgreSQL, and exports the processed styles as Tailwind CSS-compatible output.

## Features

- **Multi-Path Scanning**: Scan multiple directories for LESS CSS files
- **Hierarchical Import Tracking**: Maintains the import hierarchy and dependencies between LESS files
- **PostgreSQL Storage**: Persists all LESS data in a structured PostgreSQL database
- **Tailwind CSS Export**: Converts and exports the parsed LESS styles to Tailwind-compatible CSS
- **Type-Safe**: Built with TypeScript for enhanced development experience
- **Database Migrations**: Automated database schema setup and management
- **Comprehensive Logging**: Detailed logging for debugging and monitoring
- **Variable Extraction**: Automatically extracts LESS variables and converts them to Tailwind theme configurations

## Tech Stack

- **Runtime**: Node.js
- **Language**: TypeScript
- **Database**: PostgreSQL
- **LESS Parser**: Built-in regex parsing for LESS syntax
- **Database Driver**: pg (node-postgres)

## Project Structure

```
less-to-tailwind-parser/
├── src/
│   ├── index.ts                      # Main entry point
│   ├── database/
│   │   └── connection.ts             # Database initialization and migrations
│   ├── services/
│   │   ├── lessService.ts            # LESS file scanning and parsing
│   │   ├── databaseService.ts        # Database operations
│   │   └── exportService.ts          # Tailwind conversion and export
│   └── utils/
│       └── logger.ts                 # Logging utility
├── database/
│   └── schema.sql                    # PostgreSQL schema definition
├── package.json                      # Project dependencies
├── tsconfig.json                     # TypeScript configuration
├── jest.config.js                    # Jest testing configuration
├── .eslintrc.json                    # ESLint configuration
├── .prettierrc                        # Prettier code formatting
├── .env.example                      # Environment variables template
└── README.md                         # This file
```

## Installation

### Prerequisites

- Node.js 16+ or higher
- npm or yarn
- PostgreSQL 12+

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/less-to-tailwind-parser.git
   cd less-to-tailwind-parser
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your PostgreSQL credentials:
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=less_to_tailwind
   DB_USER=postgres
   DB_PASSWORD=your_password
   
   LESS_SCAN_PATHS=./less,./styles
   OUTPUT_DIR=./output
   TAILWIND_CONFIG_OUTPUT=./output/tailwind.config.js
   
   NODE_ENV=development
   ```

4. **Create the PostgreSQL database**
   ```bash
   createdb less_to_tailwind
   ```

5. **Build the TypeScript code**
   ```bash
   npm run build
   ```

## Usage

### Run the Parser

```bash
npm start
```

Or use development mode with automatic TypeScript compilation:
```bash
npm run dev
```

### Database Operations

Initialize the database schema:
```bash
npm run db:migrate
```

Reset the database (careful!):
```bash
npm run db:reset
```

## API Reference

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | PostgreSQL host | localhost |
| `DB_PORT` | PostgreSQL port | 5432 |
| `DB_NAME` | Database name | less_to_tailwind |
| `DB_USER` | Database user | postgres |
| `DB_PASSWORD` | Database password | password |
| `LESS_SCAN_PATHS` | Comma-separated paths to scan | ./less,./styles |
| `OUTPUT_DIR` | Directory for exporting CSS | ./output |
| `TAILWIND_CONFIG_OUTPUT` | Path for Tailwind config file | ./output/tailwind.config.js |
| `NODE_ENV` | Environment (development/production) | development |
| `LOG_LEVEL` | Logging level (DEBUG/INFO/WARN/ERROR) | INFO |

### Services

#### LessService
Handles LESS file scanning and parsing:
- `scanForLessFiles(paths: string[])` - Scans directories for LESS files
- `extractImports(content: string)` - Extracts @import statements
- `extractVariables(content: string)` - Extracts LESS variables
- `extractMixins(content: string)` - Extracts LESS mixins

#### DatabaseService
Manages all database operations:
- `storeLessFile(lessFile: LessFile)` - Stores a LESS file in database
- `storeImportRelationship(...)` - Records import hierarchy
- `storeVariables(fileId, variables)` - Stores extracted variables
- `resolveImports(fileId)` - Resolves unresolved imports
- `getProcessingStats()` - Gets processing statistics

#### ExportService
Converts LESS to Tailwind format:
- `convertToTailwind()` - Converts stored LESS data to Tailwind config
- `exportToFile(config, path)` - Writes Tailwind config to file
- `generateCSS(config)` - Generates CSS from configuration

## Development

### Code Formatting

Format all TypeScript files:
```bash
npm run format
```

### Linting

Run ESLint to check for code issues:
```bash
npm run lint
```

### Testing

Run the test suite:
```bash
npm test
```

Watch mode for development:
```bash
npm test -- --watch
```

## Database Schema

The application uses the following main tables:

### less_files
Stores LESS files and metadata
- `id` - Primary key
- `file_name` - Original filename
- `file_path` - Absolute file path
- `relative_path` - Path relative to project root
- `content` - File content
- `checksum` - SHA256 of content
- `status` - Processing status (pending, processing, completed, error)

### less_imports
Tracks hierarchical import relationships
- `id` - Primary key
- `parent_file_id` - ID of importing file
- `child_file_id` - ID of imported file
- `import_path` - Import path string
- `import_type` - Type of import (standard, optional, reference)
- `is_resolved` - Whether the import was successfully resolved

### less_variables
Stores extracted variables and mixins
- `id` - Primary key
- `less_file_id` - Reference to less_files
- `variable_name` - Variable name
- `variable_value` - Variable value
- `is_mixin` - Whether this is a mixin

### tailwind_exports
Stores generated Tailwind configurations
- `id` - Primary key
- `export_name` - Name of export
- `export_type` - Type (config, css, etc.)
- `export_data` - Serialized export data

## Workflow

1. **Scanning**: The parser scans specified directories for `.less` files
2. **Parsing**: Each file is parsed to extract:
   - Variables (`@variable: value`)
   - Mixins (`.mixin()`)
   - Imports (`@import 'path'`)
3. **Storage**: All extracted data is stored in PostgreSQL with hierarchical relationships
4. **Processing**: Import hierarchies are resolved and tracked
5. **Export**: Data is converted to Tailwind theme configuration format
6. **Output**: Tailwind config is written to `tailwind.config.js`

## Example

Given a LESS file structure:
```less
// variables.less
@primary-color: #007bff;
@secondary-color: #6c757d;
@spacing-unit: 8px;

// components.less
@import 'variables.less';

.button {
  background: @primary-color;
  padding: @spacing-unit;
}
```

The parser will:
1. Scan and find both files
2. Extract variables and store them in database
3. Record the import relationship
4. Generate a Tailwind config:
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        'primary-color': '#007bff',
        'secondary-color': '#6c757d',
      },
      spacing: {
        'spacing-unit': '8px',
      }
    }
  }
}
```

## Troubleshooting

### Database Connection Error
- Ensure PostgreSQL is running
- Check credentials in `.env`
- Verify database exists

### No LESS Files Found
- Check `LESS_SCAN_PATHS` in `.env`
- Ensure files end with `.less` extension
- Verify paths are correct and accessible

### Import Resolution Issues
- Check import paths in LESS files
- Ensure imported files exist and are included in scan paths
- Review logs for specific path resolution errors

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT - see LICENSE file for details

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

## Roadmap

- [ ] Support for nested variable references
- [ ] Advanced mixin parameter extraction
- [ ] CSS-in-JS output format
- [ ] Web UI for managing LESS files
- [ ] CLI arguments for dynamic configuration
- [ ] Support for SCSS files
