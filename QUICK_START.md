# Quick Start: Git Workspaces

Get up and running with stage development in 5 minutes.

---

## 1️⃣ Clone & Setup (2 minutes)

```bash
# Clone repository
git clone https://github.com/craigmcmeechan/less-to-tailwind-parser.git
cd less-to-tailwind-parser

# Create all stage workspaces
bash setup-workspaces.sh

# Verify setup
git worktree list
```

You now have 10 independent workspaces:
- `.worktrees/dev` - Development branch
- `.worktrees/stage-1` through `.worktrees/stage-9` - One per stage

---

## 2️⃣ Choose Your Stage

Pick which stage you want to work on.

**Recommended order:**
1. Stage 1: Database Foundation (easiest entry point)
2. Stage 2: LESS Scanning
3. Stage 3: Import Hierarchy
4. Stage 4: CSS Rule Extraction (critical stage)
5. ... then others

---

## 3️⃣ Enter Your Workspace (1 minute)

```bash
# Enter Stage 1 workspace
cd .worktrees/stage-1

# Or any other stage
cd .worktrees/stage-4
```

---

## 4️⃣ Read Documentation (1 minute)

From within your workspace:

```bash
# View stage documentation
cat ../../docs/stages/01_DATABASE_FOUNDATION.md

# View architecture overview
cat ../../docs/ARCHITECTURE.md
```

---

## 5️⃣ Install & Start Coding (1 minute)

```bash
# Install dependencies (first time only)
npm install

# Create your first file
touch src/services/myService.ts

# Run tests to verify setup
npm test

# Start development
npm run dev
```

---

## Your First Commit

```bash
# Check what changed
git status

# Stage your changes
git add .

# Commit with descriptive message
git commit -m "feat: implement database connection pool

- Configure PostgreSQL connection pooling
- Add health check endpoint
- Add tests for connection limits"

# Push to GitHub
git push origin feature/01-database-foundation
```

---

## Back to Main Directory

```bash
cd ../..
```

This takes you back to the main project directory. Your work is saved in the stage branch and can be picked up later.

---

## Multiple Stages Simultaneously

Work on different stages in different terminal tabs:

```bash
# Terminal 1: Stage 1 development
cd .worktrees/stage-1
npm run dev

# Terminal 2: Stage 4 development (in new terminal tab)
cd .worktrees/stage-4
npm run dev

# Terminal 3: Check git status
cd .
git status
```

All three work independently without conflicts.

---

## Done with Your Stage?

```bash
# From your stage workspace
git push origin feature/XX-description

# Then, from main directory
git worktree remove .worktrees/stage-X
```

---

## Common Commands

| Task | Command |
|------|---------|
| List all workspaces | `git worktree list` |
| Enter a workspace | `cd .worktrees/stage-X` |
| Go back to main | `cd ../..` |
| Check commits in stage | `cd .worktrees/stage-X && git log --oneline` |
| Push stage work | `cd .worktrees/stage-X && git push origin feature/XX-description` |
| View stage docs | `cat ../../docs/stages/0X_*.md` |
| Run tests | `npm test` |

---

## Documentation

- **Full Guide:** See `GIT_WORKSPACES_GUIDE.md`
- **Stage Details:** See `docs/stages/0X_*.md` for each stage
- **Architecture:** See `ARCHITECTURE_CORRECTIONS.md`
- **Roadmap:** See `docs/PROJECT_ROADMAP.md`

---

## Quick Help

```bash
# Show this quick start
cat QUICK_START.md

# Show full workspace guide
cat GIT_WORKSPACES_GUIDE.md

# Show architecture overview
cat docs/ARCHITECTURE.md

# Show your current stage docs
cat docs/stages/01_DATABASE_FOUNDATION.md  # (replace with your stage)
```

---

## Example Workflow

```bash
# Setup (one time)
bash setup-workspaces.sh

# Day 1: Work on Stage 1
cd .worktrees/stage-1
npm install
# ... write code ...
git add .
git commit -m "feat: database setup"
git push

# Day 2: Work on Stage 4 (different feature)
cd ../stage-4
npm install
# ... write code ...
git add .
git commit -m "feat: LESS rule extraction"
git push

# Check progress in main directory
cd ../..
git log --oneline --graph --all  # See all stage commits

# Pull request when ready
# (Create PR on GitHub from feature branch to develop)
```

---

## Troubleshooting

**Q: Workspaces not created?**
```bash
bash setup-workspaces.sh
```

**Q: Node modules missing?**
```bash
cd .worktrees/stage-X
npm install
```

**Q: Can't find stage docs?**
```bash
# From within stage workspace
cat ../../docs/stages/0X_*.md

# Or from main directory
cat docs/stages/0X_*.md
```

**Q: Lost work?**
```bash
cd .worktrees/stage-X
git reflog  # See all commits
```

**Q: Want to see all stage branches?**
```bash
git branch -a
```

---

## Next Steps

1. ✅ Run `bash setup-workspaces.sh`
2. ✅ Choose your first stage
3. ✅ `cd .worktrees/stage-X`
4. ✅ Read `docs/stages/0X_*.md`
5. ✅ `npm install`
6. ✅ Start coding!

---

**Happy coding! 🚀**

For detailed information, see `GIT_WORKSPACES_GUIDE.md`.

---

**Last Updated:** October 29, 2025
