# DOCUMENTATION INDEX & GETTING STARTED

Welcome to the LESS to Tailwind Parser project documentation! This guide will help you navigate all available documentation.

---

## 📋 Quick Start

**New to the project?** Start here in this order:

1. Read [PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md) (5 min) - Understand the big picture
2. Read [ARCHITECTURE.md](./ARCHITECTURE.md) (10 min) - Understand how pieces fit together  
3. Read relevant stage guide (see below) - For your current work area
4. Reference generic guides as needed while implementing

---

## 📚 Documentation Structure

### Master Documents

| Document | Purpose | Read When |
|----------|---------|-----------|
| [PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md) | Timeline, stages, deliverables | Planning work, understanding scope |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System design, modules, data flow | Understanding system design |

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
| 1 | [01_DATABASE_FOUNDATION.md](./stages/01_DATABASE_FOUNDATION.md) | ⏳ Ready | Week 1 |
| 2 | [02_LESS_SCANNING.md](./stages/02_LESS_SCANNING.md) | 📝 Coming | Week 2 |
| 3 | [03_IMPORT_HIERARCHY.md](./stages/03_IMPORT_HIERARCHY.md) | 📝 Coming | Weeks 3-4 |
| 4 | [04_VARIABLE_EXTRACTION.md](./stages/04_VARIABLE_EXTRACTION.md) | 📝 Coming | Weeks 3-4 |
| 5 | [05_TAILWIND_EXPORT.md](./stages/05_TAILWIND_EXPORT.md) | 📝 Coming | Week 5 |
| 6 | [06_INTEGRATION.md](./stages/06_INTEGRATION.md) | 📝 Coming | Week 6 |

---

## 🎯 How to Use These Docs

### For Implementation Work

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

### For Developers

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

### Ready to Start 🚀
- **Stage 1: Database Foundation** - Begin immediately

### Coming Soon 📝
- Stages 2-6 guides (created as each stage begins)

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

**Q: Which document should I read first?**  
A: Read PROJECT_ROADMAP.md, then ARCHITECTURE.md, then your stage guide.

**Q: Where do I find logging examples?**  
A: LOGGING_GUIDE.md has complete examples organized by scenario.

**Q: How do I know what tests to write?**  
A: Your stage guide says what to test; TESTING_GUIDE.md shows how.

**Q: What if I'm stuck on something?**  
A: 1) Check your stage guide 2) Check relevant generic guide 3) Check ARCHITECTURE.md

**Q: Can I skip a stage?**  
A: No - stages have dependencies shown in PROJECT_ROADMAP.md.

**Q: How often do these docs update?**  
A: As new stages begin, their stage guide is created. Generic guides are stable.

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
| Git/commit message format | CODE_STANDARDS.md | (Check existing commits) |

---

## 📞 Getting Help

If you need help:

1. **Check the docs** - Most answers are here
2. **Search for keywords** - Use browser Find (Ctrl+F)
3. **Check relevant stage guide** - Stage-specific issues there
4. **Reference examples** - Documents have concrete code examples

---

## 🎓 Learning Resources

Recommended external resources for deeper learning:

- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Jest Testing Framework](https://jestjs.io/docs/getting-started)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

---

**Happy coding! 🚀**

For questions about documentation structure, see the [PROJECT_ROADMAP.md](./PROJECT_ROADMAP.md).

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
