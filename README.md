# LESS to Tailwind Parser

A TypeScript-based tool that scans LESS CSS files from specified directories, parses their hierarchical structure with imports, stores the data in PostgreSQL, and exports the processed styles as Tailwind CSS-compatible output.

## Features

- **Multi-Path Scanning**: Scan multiple directories for LESS CSS files
- **Hierarchical Import Tracking**: Maintains the import hierarchy and dependencies between LESS files
- **PostgreSQL Storage**: Persists all LESS data in a structured PostgreSQL database
- **Tailwind CSS Export**: Converts and exports the parsed LESS styles to Tailwind-compatible CSS
- **Type-Safe**: Built with TypeScript for enhanced development experience
- **Database Migrations**: Automated database schema setup and management

## Tech Stack

- **Runtime**: Node.js
- **Language**: TypeScript
- **Database**: PostgreSQL
- **LESS Parser**: less.js
- **Database Driver**: pg (node-postgres)

## Project Structure

```
.
├── src/
│   ├── index.ts                 # Main entry point
│   ├── config.ts                # Configuration management
│   ├── database/
│   │   ├── connection.ts        # PostgreSQL connection setup
│   │   ├── migrations.ts        # Database schema migrations
│   │   └── queries.ts           # Database query builders
│   ├── parser/
│   │   ├── lessScanner.ts       # LESS file discovery
│   │   ├── lessParser.ts        # LESS file parsing
│   │   └── importResolver.ts    # Import hierarchy resolution
│   ├── models/
│   │   ├── LessFile.ts          # LESS file data model
│   │   ├── LessImport.ts        # Import relationship model
│   │   └── TailwindOutput.ts    # Tailwind export model
│   ├── services/
│   │   ├── lessService.ts       # LESS processing service
│   │   ├── databaseService.ts   # Database operations
│   │   └── exportService.ts     # Tailwind CSS export service
│   └── utils/
│       └── logger.ts            # Logging utility
├── database/
│   └── schema.sql               # PostgreSQL schema definition
├── dist/                        # Compiled JavaScript output
├── package.json
├── tsconfig.json
├── .env.example
└── .gitignore
```

## Database Schema

The project uses PostgreSQL to store:

- **less_files**: Individual LESS files and their metadata
- **less_imports**: Hierarchical import relationships between files
- **less_variables**: Variables and mixins extracted from LESS files
- **tailwind_exports**: Exported Tailwind CSS configurations

## Getting Started

### Prerequisites

- Node.js (v18+)
- PostgreSQL (v12+)
- npm or yarn

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/less-to-tailwind-parser.git
   cd less-to-tailwind-parser
   ```

2. Install dependencies
   ```bash
   npm install
   ```

3. Configure environment variables
   ```bash
   cp .env.example .env
   # Edit .env with your PostgreSQL credentials
   ```

4. Create the database
   ```bash
   createdb less_to_tailwind
   ```

5. Run migrations
   ```bash
   npm run db:migrate
   ```

### Usage

1. Build the project
   ```bash
   npm run build
   ```

2. Run the parser
   ```bash
   npm start
   ```

Or use development mode with auto-reload:
   ```bash
   npm run dev
   ```

## API

### Configuration

Set the following environment variables in `.env`:

- `DB_HOST`: PostgreSQL host
- `DB_PORT`: PostgreSQL port (default: 5432)
- `DB_NAME`: Database name
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password
- `LESS_SCAN_PATHS`: Comma-separated paths to scan for LESS files
- `OUTPUT_DIR`: Directory for exporting processed CSS
- `TAILWIND_CONFIG_OUTPUT`: Path for Tailwind configuration output

## Development

### Run Tests
```bash
npm test
```

### Code Formatting
```bash
npm run format
```

### Linting
```bash
npm run lint
```

## License

MIT
