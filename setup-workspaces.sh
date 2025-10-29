#!/bin/bash

# setup-workspaces.sh
# Creates Git worktrees for each stage of the LESS to Tailwind Parser project
# Usage: bash setup-workspaces.sh

set -e

PROJECT_ROOT=$(pwd)
WORKTREES_DIR="$PROJECT_ROOT/.worktrees"

echo "🚀 Setting up Git workspaces for LESS to Tailwind Parser"
echo "Project root: $PROJECT_ROOT"
echo "Worktrees directory: $WORKTREES_DIR"
echo ""

# Create worktrees directory
mkdir -p "$WORKTREES_DIR"

# Define all stages
declare -a STAGES=(
  "dev:develop:Development branch for work-in-progress"
  "stage-1:feature/01-database-foundation:Stage 1 - Database Foundation"
  "stage-2:feature/02-less-scanning:Stage 2 - LESS File Scanning"
  "stage-3:feature/03-import-hierarchy:Stage 3 - Import Hierarchy"
  "stage-4:feature/04-rule-extraction:Stage 4 - CSS Rule Extraction"
  "stage-5:feature/05-variable-extraction:Stage 5 - Variable Extraction"
  "stage-6:feature/06-tailwind-export:Stage 6 - Tailwind Export"
  "stage-7:feature/07-integration:Stage 7 - Integration & Testing"
  "stage-8:feature/08-chrome-extension:Stage 8 - Chrome Extension"
  "stage-9:feature/09-dom-matching:Stage 9 - DOM Matching & Tailwind"
)

# Function to create branch if it doesn't exist
create_branch_if_needed() {
  local branch=$1
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "  ↳ Creating branch: $branch"
    git branch "$branch" main
  else
    echo "  ↳ Branch exists: $branch"
  fi
}

# Function to create worktree
create_worktree() {
  local worktree_name=$1
  local branch=$2
  local description=$3
  
  local worktree_path="$WORKTREES_DIR/$worktree_name"
  
  if [ -d "$worktree_path" ]; then
    echo "  ✓ Worktree already exists: $worktree_name"
    return
  fi
  
  echo "  ↳ Creating worktree: $worktree_name → $branch"
  git worktree add "$worktree_path" "$branch"
  
  # Create a descriptive file in the worktree
  cat > "$worktree_path/.stage-info.md" << EOF
# $description

**Worktree:** $worktree_name  
**Branch:** $branch  
**Path:** $worktree_path

## Quick Start

1. Enter this worktree:
   \`\`\`bash
   cd .worktrees/$worktree_name
   \`\`\`

2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Check documentation:
   \`\`\`bash
   cat ../docs/stages/0X_*.md
   \`\`\`

4. Start working on this stage

## When Done

Commit your changes:
\`\`\`bash
git add .
git commit -m "WIP: $description"
\`\`\`

Return to main:
\`\`\`bash
cd ../..
\`\`\`
EOF
  
  echo "  ✓ Worktree created: $worktree_name"
}

# Main setup
echo "📦 Creating branches..."
for stage in "${STAGES[@]}"; do
  IFS=':' read -r worktree branch description <<< "$stage"
  create_branch_if_needed "$branch"
done

echo ""
echo "🏗️  Creating worktrees..."
for stage in "${STAGES[@]}"; do
  IFS=':' read -r worktree branch description <<< "$stage"
  create_worktree "$worktree" "$branch" "$description"
done

echo ""
echo "✅ Setup complete!"
echo ""
echo "📂 Worktree locations:"
for stage in "${STAGES[@]}"; do
  IFS=':' read -r worktree branch description <<< "$stage"
  echo "  • $worktree → .worktrees/$worktree"
done

echo ""
echo "🚀 Quick Start:"
echo "  cd .worktrees/stage-1"
echo "  npm install"
echo "  # Start working..."
echo ""
echo "📋 View all worktrees:"
echo "  git worktree list"
echo ""
echo "🧹 Remove a worktree when done:"
echo "  git worktree remove .worktrees/stage-1"
echo "  git branch -d feature/01-database-foundation"
