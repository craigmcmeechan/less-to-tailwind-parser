# Contributing to LESS to Tailwind Parser

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Please be respectful and constructive in all interactions with other contributors.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/less-to-tailwind-parser.git
   cd less-to-tailwind-parser
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/original-owner/less-to-tailwind-parser.git
   ```
4. Create a new branch for your feature:
   ```bash
   git checkout -b feature/my-feature
   ```

## Development Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set up environment:
   ```bash
   cp .env.example .env
   # Configure .env with your local PostgreSQL settings
   ```

3. Build the project:
   ```bash
   npm run build
   ```

## Making Changes

### Code Style

- Follow the existing code style
- Use TypeScript for all new code
- Run formatter before committing:
  ```bash
  npm run format
  ```

### Running Tests

```bash
npm test
```

### Linting

Check for linting errors:
```bash
npm run lint
```

### Committing Changes

1. Make logical, atomic commits
2. Write clear commit messages:
   ```
   Add feature: Brief description of changes
   
   More detailed explanation of what was changed and why.
   ```

### Before Pushing

- Run tests: `npm test`
- Run linter: `npm run lint`
- Format code: `npm run format`
- Build: `npm run build`

## Submitting a Pull Request

1. Push your branch to your fork:
   ```bash
   git push origin feature/my-feature
   ```

2. Create a Pull Request on GitHub with:
   - Clear title describing the change
   - Detailed description of what was changed and why
   - Reference any related issues: `Fixes #123`
   - Screenshots or examples if applicable

3. Ensure all CI checks pass

4. Wait for review and address any feedback

## Pull Request Review Process

- At least one maintainer review is required
- All tests must pass
- Code coverage should not decrease
- Documentation should be updated if needed

## Reporting Issues

When reporting bugs, please include:
- Clear description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, Node.js version, etc.)
- Any relevant logs or error messages

## Suggesting Enhancements

For feature suggestions:
- Describe the use case
- Explain why this would be beneficial
- Provide examples if possible

## Documentation

- Update README.md if you change functionality
- Add JSDoc comments for new functions/classes
- Include examples for complex features

## Questions?

Feel free to open an issue or discussion if you have questions about how to contribute.

Thank you for contributing!
