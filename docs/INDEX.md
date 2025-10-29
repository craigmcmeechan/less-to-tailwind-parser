# DOCUMENTATION INDEX & GETTING STARTED

Welcome to the LESS to Tailwind Parser project documentation! This guide will help you navigate all available documentation.

---

## 🚀 Claude Code Workflow (NEW!)

**Using Claude Code for development?** Start here:

1. **[CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md)** - The complete systematic workflow
   - How Claude Code should approach each stage
   - Documentation review and breakdown process
   - Per-step implementation loop with testing
   - Completion checklist and best practices

2. **[CLAUDE_CODE_INVOCATION.md](./CLAUDE_CODE_INVOCATION.md)** - How to invoke Claude Code
   - Quick start command template
   - Stage-specific invocation examples (Stages 1-9)
   - Pre-invocation and post-completion checklists
   - Common patterns and troubleshooting

3. **Bootstrap Script** - Start any stage:
   ```bash
   ./bootstrap-stage.sh [STAGE_NUMBER] [STAGE_NAME]
   # Example: ./bootstrap-stage.sh 1 DATABASE_FOUNDATION
   ```

---

## 📋 Quick Start

**New to the project?** Start here in this order:

1. Read [PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md) (5 min) - Understand the big picture
2. Read [ARCHITECTURE.md](./ARCHITECTURE.md) (10 min) - Understand how pieces fit together  
3. Read relevant stage guide (see below) - For your current work area
4. Reference generic guides as needed while implementing

**Using Claude Code?** See the Claude Code section above instead.

---

## 📚 Documentation Structure

### Master Documents

| Document | Purpose | Read When |
|----------|---------|-----------| 
| [PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md) | Timeline, stages, deliverables | Planning work, understanding scope |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System design, modules, data flow | Understanding system design |

### Claude Code Integration (For Systematic Development)

| Document | Purpose | Used For |
|----------|---------|----------|
| [CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md) | Systematic stage breakdown and implementation workflow | When using Claude Code for development |
| [CLAUDE_CODE_INVOCATION.md](./CLAUDE_CODE_INVOCATION.md) | How to invoke Claude Code for each stage | Starting a new stage with Claude Code |

### Generic Guides (Apply to ALL Stages)

| Document | Purpose | Used For |
|----------|---------|----------|
| [CODE_STANDARDS.md](./CODE_STANDARDS.md) | TypeScript, naming, organization | Every piece of code you write |
| [TESTING_GUIDE.md](./TESTING_GUIDE.md) | Unit/integration tests, Jest setup | Writing tests for your code |
| [LOGGING_GUIDE.md](./LOGGING_GUIDE.md) | Logger usage, log levels, patterns | Adding debug output |
| [ERROR_HANDLING.md](./ERROR_HANDLING.md) | Error types, recovery strategies | Handling failures gracefully |
| [DATABASE_OPERATIONS.md](./DATABASE_OPERATIONS.md) | Query patterns, transactions, performance | Database interactions |

### Stage-Specific Guides

| Stage | Document | Status | Timeline |
|-------|----------|--------|----------|
| 1 | [01_DATABASE_FOUNDATION.md](./stages/01_DATABASE_FOUNDATION.md) | ✅ Ready | Week 1 |
| 2 | [02_LESS_SCANNING.md](./stages/02_LESS_SCANNING.md) | ✅ Ready | Week 2 |
| 3 | [03_IMPORT_HIERARCHY.md](./stages/03_IMPORT_HIERARCHY.md) | ✅ Ready | Weeks 3-4 |
| 4 | [04_RULE_EXTRACTION.md](./stages/04_RULE_EXTRACTION.md) | ✅ Ready | Weeks 5-6 |
| 5 | [04_VARIABLE_EXTRACTION.md](./stages/04_VARIABLE_EXTRACTION.md) | ✅ Ready | Weeks 7-8 |
| 6 | [05_TAILWIND_EXPORT.md](./stages/05_TAILWIND_EXPORT.md) | ✅ Ready | Week 8-9 |
| 7 | [06_INTEGRATION.md](./stages/06_INTEGRATION.md) | ✅ Ready | Week 10 |
| 8 | [08_CHROME_EXTENSION.md](./stages/08_CHROME_EXTENSION.md) | ✅ Ready | Week 11 |
| 9 | [09_DOM_TO_TAILWIND.md](./stages/09_DOM_TO_TAILWIND.md) | ✅ Ready | Week 12 |

---

## 🎯 How to Use These Docs

### For Claude Code Development

1. **Start here:** [CLAUDE_CODE_INVOCATION.md](./CLAUDE_CODE_INVOCATION.md)
2. **Find your stage** - Use the stage-specific invocation command
3. **Run bootstrap:** `./bootstrap-stage.sh [N] [STAGE_NAME]`
4. **Read workflow:** [CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md)
5. **Implement systematically:** One step at a time, test after each
6. **Reference guides** as needed for code patterns

### For Manual Implementation

1. **Find your stage** in the roadmap
2. **Read the stage guide** - Lists everything needed for that stage
3. **Reference generic guides** as you implement:
   - Need to write code? → See CODE_STANDARDS.md
   - Writing tests? → See TESTING_GUIDE.md
   - Adding error handling? → See ERROR_HANDLING.md
   - Database operations? → See DATABASE_OPERATIONS.md

### For Code Review

1. Check that code follows [CODE_STANDARDS.md](./CODE_STANDARDS.md)
2. Verify tests exist and follow [TESTING_GUIDE.md](./TESTING_GUIDE.md)
3. Confirm logging present per [LOGGING_GUIDE.md](./LOGGING_GUIDE.md)
4. Check error handling per [ERROR_HANDLING.md](./ERROR_HANDLING.md)

### For Debugging

1. Check [LOGGING_GUIDE.md](./LOGGING_GUIDE.md) - Adjust log levels
2. Check [ERROR_HANDLING.md](./ERROR_HANDLING.md) - Understand error types
3. Check [DATABASE_OPERATIONS.md](./DATABASE_OPERATIONS.md) - Debug queries
4. Check stage-specific guide - Stage-specific debugging tips

---

## 📌 Key Documents by Role

### For Developers Using Claude Code

- **Setup:** CLAUDE_CODE_INVOCATION.md → Run bootstrap-stage.sh
- **Workflow:** CLAUDE_CODE_WORKFLOW.md (detailed systematic approach)
- **Implementing:** CODE_STANDARDS.md + your stage guide + generic guides
- **Testing:** TESTING_GUIDE.md
- **Debugging:** LOGGING_GUIDE.md + ERROR_HANDLING.md

### For Manual Developers

- **Starting:** PROJECT_ROADMAP.md → ARCHITECTURE.md → Your stage guide
- **Implementing:** CODE_STANDARDS.md + your stage guide
- **Testing:** TESTING_GUIDE.md
- **Debugging:** LOGGING_GUIDE.md + ERROR_HANDLING.md

### For Leads/Reviewers

- **Tracking:** PROJECT_ROADMAP.md (stages and timeline)
- **Design:** ARCHITECTURE.md (system overview)
- **Quality:** CODE_STANDARDS.md, TESTING_GUIDE.md
- **Standards:** All 6 generic guides

### For DevOps/Infrastructure

- **Setup:** DATABASE_OPERATIONS.md (connection pooling section)
- **Architecture:** ARCHITECTURE.md (deployment section)
- **Monitoring:** LOGGING_GUIDE.md (log output formats)

---

## ✅ Acceptance Criteria

Each stage guide has an "Acceptance Criteria" section. **Before moving to the next stage, verify:**

- [ ] All code written per CODE_STANDARDS.md
- [ ] Tests written per TESTING_GUIDE.md with ≥80% coverage
- [ ] Logging added per LOGGING_GUIDE.md
- [ ] Error handling per ERROR_HANDLING.md
- [ ] All stage-specific requirements met
- [ ] Code review passed
- [ ] All tests passing

---

## 🚀 Current Status

### Completed ✅
- Project repository created
- Database schema designed
- Core service structure in place
- Generic documentation completed (this folder)
- Claude Code workflow documentation created

### Ready to Start 🚀
- **Stage 1: Database Foundation** - Begin immediately
  - Use: `./bootstrap-stage.sh 1 DATABASE_FOUNDATION`
  - Then follow: CLAUDE_CODE_INVOCATION.md (Stage 1 section)

### Coming Soon 📝
- Implementation of Stages 1-9

---

## 📖 Document Conventions

### Cross-References

Generic guides are referenced throughout with format:
```
See [LOGGING_GUIDE.md](./LOGGING_GUIDE.md) for logger usage patterns
```

Click these links to jump to relevant sections.

### Code Examples

Good code examples are marked with ✅:
```typescript
// ✅ DO THIS
logger.info('Operation completed', { fileCount, duration });
```

Bad patterns are marked with ❌:
```typescript
// ❌ DON'T DO THIS
console.log('Done');
```

### Important Notes

Key points are highlighted:
> **Important:** Always parameterize database queries

---

## 🤔 FAQ

**Q: How do I get started with Claude Code?**  
A: Read CLAUDE_CODE_INVOCATION.md, then run `./bootstrap-stage.sh [N] [STAGE_NAME]`

**Q: Which document should I read first?**  
A: Depends on your role:
- **Using Claude Code?** → CLAUDE_CODE_INVOCATION.md
- **Manual development?** → PROJECT_ROADMAP.md, then ARCHITECTURE.md, then your stage guide
- **Implementing code?** → CODE_STANDARDS.md

**Q: Where do I find logging examples?**  
A: LOGGING_GUIDE.md has complete examples organized by scenario.

**Q: How do I know what tests to write?**  
A: Your stage guide says what to test; TESTING_GUIDE.md shows how.

**Q: What if I'm stuck on something?**  
A: 1) Check your stage guide 2) Check relevant generic guide 3) Check ARCHITECTURE.md

**Q: Can I skip a stage?**  
A: No - stages have dependencies shown in PROJECT_ROADMAP.md.

**Q: How often do these docs update?**  
A: As new stages begin, their stage guide is ready. Generic guides and Claude Code docs are stable.

**Q: What's the difference between manual and Claude Code development?**  
A: Claude Code follows a systematic workflow (CLAUDE_CODE_WORKFLOW.md) that breaks stages into testable sequential steps. Manual development gives you more flexibility but requires more discipline.

---

## 🔍 Topics Index

Find information about specific topics:

| Topic | Document | Section |
|-------|----------|---------|
| Connection retry logic | DATABASE_OPERATIONS.md | Connection Management |
| Error types | ERROR_HANDLING.md | Custom Error Types |
| Test structure | TESTING_GUIDE.md | Test File Organization |
| Logger usage | LOGGING_GUIDE.md | Using the Logger |
| TypeScript rules | CODE_STANDARDS.md | TypeScript Standards |
| Query patterns | DATABASE_OPERATIONS.md | Query Patterns |
| Module responsibilities | ARCHITECTURE.md | Module Responsibilities |
| Data flow | ARCHITECTURE.md | Data Flow |
| Naming conventions | CODE_STANDARDS.md | Naming Conventions |
| Claude Code workflow | CLAUDE_CODE_WORKFLOW.md | Complete workflow |
| Claude Code invocation | CLAUDE_CODE_INVOCATION.md | Stage-specific commands |
| Bootstrap script | README.md | (root) | Usage |

---

## 📞 Getting Help

If you need help:

1. **Check the docs** - Most answers are here
2. **Search for keywords** - Use browser Find (Ctrl+F)
3. **Check relevant stage guide** - Stage-specific issues there
4. **Check Claude Code docs** - If using Claude Code
5. **Reference examples** - Documents have concrete code examples

---

## 🎓 Learning Resources

Recommended external resources for deeper learning:

- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Jest Testing Framework](https://jestjs.io/docs/getting-started)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)

---

## 📋 Quick Navigation

**I want to...**

- **Use Claude Code** → [CLAUDE_CODE_INVOCATION.md](./CLAUDE_CODE_INVOCATION.md)
- **Understand the system** → [ARCHITECTURE.md](./ARCHITECTURE.md)
- **See the timeline** → [PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md)
- **Write code** → [CODE_STANDARDS.md](./CODE_STANDARDS.md)
- **Write tests** → [TESTING_GUIDE.md](./TESTING_GUIDE.md)
- **Add logging** → [LOGGING_GUIDE.md](./LOGGING_GUIDE.md)
- **Handle errors** → [ERROR_HANDLING.md](./ERROR_HANDLING.md)
- **Work with database** → [DATABASE_OPERATIONS.md](./DATABASE_OPERATIONS.md)
- **Work on Stage N** → `docs/stages/[N]_[NAME].md`
- **Follow the workflow** → [CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md)

---

**Happy coding! 🚀**

For questions about documentation structure, see the [PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md).

---

**Document Version:** 2.0  
**Last Updated:** October 29, 2025  
**Notable Changes:** Added Claude Code workflow and invocation guides
