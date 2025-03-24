# Contributing to AHRQ SAS QI Software

Thank you for your interest in the AHRQ Quality Indicators (QIs). As you work with the AHRQ SAS QI Software you may report any issues you run into (ie. errors or gaps in our documentation) or suggest improvements.

This document explains our contribution process and how you can get involved.

---

## Table of Contents

- [How to Contribute](#how-to-contribute)
- [Code of Conduct](#code-of-conduct)
- [Issues and Bug Reports](#issues-and-bug-reports)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Development Workflow](#development-workflow)
- [License](#license)

---

## How to Contribute

You can contribute in several ways:

- Reporting bugs.
- Suggesting features or improvements.
- Writing documentation.
- Submitting code via pull requests.

If you're new to open source, check out the [First Contributions Guide](https://firstcontributions.github.io/) to get started.

---

## Code of Conduct

This project follows a **Code of Conduct**. Please read our [guidelines](https://github.com/panth-tyler/panth-qi/wiki) before contributing.

---

## Issues and Bug Reports

If you find a bug or have an idea for a feature, create an **issue**:

1. Search for existing issues to avoid duplicates.
2. If no similar issue exists, open a new one with:
   - A descriptive title.
   - A detailed description of the problem or feature request.
   - Steps to reproduce the issue (if it’s a bug).
   - Any relevant screenshots, logs, or links.

Tag your issues appropriately (e.g., `bug`, `feature-request`, `documentation`).

---

## Pull Request Guidelines

Before submitting a pull request (PR):

1. **Open an issue** to discuss the changes, unless it's a minor fix.
2. **Fork the repository** and create a new branch (see [Branch Naming Conventions](#branch-naming-conventions)).
3. Follow the **Development Workflow** below.
4. Ensure your code passes all tests and follows project coding standards.
5. Write or update relevant documentation.
6. Submit the pull request:
   - Use a clear and descriptive title.
   - Reference related issues (e.g., `Closes #123`).
   - Include screenshots or logs (if applicable).

Our team will review the PR, provide feedback, and request changes if needed. Be responsive to feedback and update your PR accordingly.

---

## Branch Naming Conventions

Create branches with descriptive names based on the task you’re working on:

- **Features**: `feat/add-option`
- **Bug Fixes**: `fix/measures`
- **Documentation**: `docs/update-readme`

Use lowercase letters, hyphens (`-`) to separate words, and prefix branches with `feat/`, `fix/`, or `docs/`.

---

## Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) standard to make commit history clear and structured. Use the following format:

```bash
<type>: <short description>

[optional body]
```

### Commit Types:

- **feat**: New feature (e.g., `feat: add new CONTROL option`).
- **fix**: Bug fix (e.g., `fix: resolve MEASURES output issue`).
- **docs**: Documentation changes (e.g., `docs: update README`).
- **chore**: Maintenance tasks (e.g., `chore: update old comment`).

---

## Development Workflow

1. **Fork and Clone**:

   ```bash
   git clone https://github.com/panth-tyler/panth-qi.git
   cd project
   ```

2. **Create a New Branch**:

   ```bash
   git checkout -b feat/add-option
   ```

3. **Make Changes**: Write or modify the code.

4. **Stage and Commit Changes**:

   ```bash
   git add .
   git commit -m "feat: add new CONTROL option"
   ```

5. **Push to GitHub**:

   ```bash
   git push origin feat/add-option
   ```

6. **Open a Pull Request**: Go to GitHub, select your branch, and open a pull request.

---

## License

By contributing to this project, you agree that your contributions will be licensed under the [Apache License](https://github.com/panth-tyler/panth-qi?tab=License-1-ov-file).

---

## Thank you!

We appreciate your contributions.

If you have any questions or need help, feel free to open an issue or engage in a discussion.
