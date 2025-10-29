-- PostgreSQL Schema for LESS to Tailwind Parser

-- Create ENUM types
CREATE TYPE file_status AS ENUM ('pending', 'processing', 'completed', 'error');
CREATE TYPE import_type AS ENUM ('standard', 'optional', 'reference');

-- Table: less_files
-- Stores individual LESS files and their metadata
CREATE TABLE IF NOT EXISTS less_files (
  id SERIAL PRIMARY KEY,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL UNIQUE,
  relative_path TEXT NOT NULL,
  content TEXT,
  file_size INTEGER,
  status file_status DEFAULT 'pending',
  checksum VARCHAR(64),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  parsed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT
);

-- Table: less_imports
-- Stores hierarchical relationships between LESS files
CREATE TABLE IF NOT EXISTS less_imports (
  id SERIAL PRIMARY KEY,
  parent_file_id INTEGER NOT NULL,
  child_file_id INTEGER,
  import_path TEXT NOT NULL,
  import_type import_type DEFAULT 'standard',
  import_line_number INTEGER,
  is_resolved BOOLEAN DEFAULT FALSE,
  resolution_error TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_parent_file FOREIGN KEY (parent_file_id) REFERENCES less_files(id) ON DELETE CASCADE,
  CONSTRAINT fk_child_file FOREIGN KEY (child_file_id) REFERENCES less_files(id) ON DELETE SET NULL
);

-- Table: less_variables
-- Stores variables and mixins extracted from LESS files
CREATE TABLE IF NOT EXISTS less_variables (
  id SERIAL PRIMARY KEY,
  less_file_id INTEGER NOT NULL,
  variable_name VARCHAR(255) NOT NULL,
  variable_type VARCHAR(50),
  variable_value TEXT,
  is_mixin BOOLEAN DEFAULT FALSE,
  mixin_params TEXT,
  line_number INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_less_file FOREIGN KEY (less_file_id) REFERENCES less_files(id) ON DELETE CASCADE
);

-- Table: tailwind_exports
-- Stores exported Tailwind CSS configurations and output
CREATE TABLE IF NOT EXISTS tailwind_exports (
  id SERIAL PRIMARY KEY,
  export_name VARCHAR(255) NOT NULL,
  export_type VARCHAR(50) NOT NULL,
  tailwind_config JSONB,
  css_output TEXT,
  source_file_ids INTEGER[] DEFAULT ARRAY[]::INTEGER[],
  export_path TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: parse_history
-- Tracks parsing jobs and their outcomes
CREATE TABLE IF NOT EXISTS parse_history (
  id SERIAL PRIMARY KEY,
  start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  end_time TIMESTAMP WITH TIME ZONE,
  total_files_processed INTEGER,
  successful_files INTEGER,
  failed_files INTEGER,
  errors_encountered TEXT,
  status VARCHAR(50)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_less_files_status ON less_files(status);
CREATE INDEX IF NOT EXISTS idx_less_files_checksum ON less_files(checksum);
CREATE INDEX IF NOT EXISTS idx_less_files_path ON less_files(file_path);
CREATE INDEX IF NOT EXISTS idx_less_imports_parent ON less_imports(parent_file_id);
CREATE INDEX IF NOT EXISTS idx_less_imports_child ON less_imports(child_file_id);
CREATE INDEX IF NOT EXISTS idx_less_imports_resolved ON less_imports(is_resolved);
CREATE INDEX IF NOT EXISTS idx_less_variables_file ON less_variables(less_file_id);
CREATE INDEX IF NOT EXISTS idx_less_variables_name ON less_variables(variable_name);
CREATE INDEX IF NOT EXISTS idx_tailwind_exports_type ON tailwind_exports(export_type);

-- Create updated_at trigger for less_files
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER less_files_update_timestamp
  BEFORE UPDATE ON less_files
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

-- Create updated_at trigger for tailwind_exports
CREATE TRIGGER tailwind_exports_update_timestamp
  BEFORE UPDATE ON tailwind_exports
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();
