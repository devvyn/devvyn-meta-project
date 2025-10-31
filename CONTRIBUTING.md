# Contributing to Coordination System

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Community](#community)

---

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to devvyn@example.com.

**Quick summary**:
- Be respectful and inclusive
- Welcome newcomers
- Focus on what is best for the community
- Show empathy towards others

[Read full Code of Conduct](CODE_OF_CONDUCT.md)

---

## Getting Started

### Types of Contributions

We welcome:

- 🐛 **Bug reports** - Help us identify and fix issues
- ✨ **Feature requests** - Suggest new capabilities
- 📝 **Documentation** - Improve or add docs
- 💻 **Code contributions** - Fix bugs or add features
- 🧪 **Testing** - Write tests or test on new platforms
- 🎨 **Design** - Improve UX/UI
- 💬 **Community support** - Help others in discussions

---

## Development Setup

### Prerequisites

- **macOS**: Bash 3.2+, `uuidgen`, `git`
- **Linux**: Bash 4.0+, `uuidgen` (`apt install uuid-runtime`), `git`
- **Windows**: WSL2 with Ubuntu recommended

### Clone and Setup

```bash
# Fork repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR-USERNAME/coordination-system.git
cd coordination-system

# Add upstream remote
git remote add upstream https://github.com/devvyn/coordination-system.git

# Install development dependencies (if any)
# Currently minimal - just needs bash and uuidgen

# Run tests
./scripts/run-tests.sh
```

---

## How to Contribute

### Reporting Bugs

**Before submitting**:
1. Check [existing issues](https://github.com/devvyn/coordination-system/issues)
2. Try the [troubleshooting guide](docs/guides/troubleshooting.md)
3. Collect relevant information

**Bug report template**:

```markdown
### Environment
- OS: macOS 14.0 / Ubuntu 22.04 / Windows 11
- Bash version: `bash --version`
- Coordination system version: `git rev-parse HEAD`

### Expected Behavior
What should happen?

### Actual Behavior
What actually happens?

### Steps to Reproduce
1. Step one
2. Step two
3. ...

### Error Messages
```
Full error output here
```

### Additional Context
Any other relevant information
```

---

### Requesting Features

**Before submitting**:
1. Check [existing feature requests](https://github.com/devvyn/coordination-system/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. Review [roadmap](docs/roadmap/capability-gaps.md) to see if planned

**Feature request template**:

```markdown
### Problem Statement
What problem does this solve?

### Proposed Solution
How should it work?

### Alternatives Considered
What other approaches did you consider?

### Use Case
How would you use this feature?

### Priority
Low / Medium / High / Critical
```

---

### Contributing Code

#### 1. Find or Create an Issue

- Check [good first issues](https://github.com/devvyn/coordination-system/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
- Or create an issue describing what you want to work on
- Wait for maintainer approval before starting work

#### 2. Create a Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

**Branch naming**:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding tests
- `chore/` - Maintenance tasks

#### 3. Make Changes

Follow [coding standards](#coding-standards) below.

#### 4. Write Tests

If adding new functionality:
```bash
# Create test file
touch tests/test_your_feature.sh

# Write tests
# See tests/ directory for examples
```

#### 5. Update Documentation

If changing behavior:
- Update relevant docs in `docs/`
- Update README.md if needed
- Add docstrings to functions

#### 6. Commit Changes

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format: <type>(<scope>): <description>

# Examples:
git commit -m "feat(messages): add priority queue support"
git commit -m "fix(inbox): handle empty inbox gracefully"
git commit -m "docs(troubleshooting): add Docker section"
git commit -m "refactor(message): simplify UUID generation"
git commit -m "test(inbox): add concurrency tests"
```

**Types**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `refactor` - Code refactoring (no behavior change)
- `test` - Adding tests
- `chore` - Maintenance
- `perf` - Performance improvement
- `style` - Formatting changes

---

## Pull Request Process

### 1. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 2. Create Pull Request

On GitHub, create a PR from your fork to `devvyn/coordination-system:main`.

**PR title**: Follow conventional commit format
```
feat(messages): add priority queue support
```

**PR description template**:

```markdown
## What does this PR do?
Brief description of changes.

## Why?
Motivation and context.

## How was it tested?
- [ ] Manual testing
- [ ] Automated tests added
- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Tested on Windows

## Related Issues
Fixes #123
Related to #456

## Checklist
- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Commit messages follow conventional commits
- [ ] No breaking changes (or documented if necessary)
```

### 3. Code Review

Maintainers will review your PR. Be prepared to:
- Answer questions
- Make requested changes
- Iterate on feedback

### 4. Merge

Once approved, a maintainer will merge your PR. Thank you!

---

## Coding Standards

### Bash Scripts

**Style**:
```bash
#!/usr/bin/env bash
# Brief description of script
# Version: X.Y
# Author: Your Name

set -euo pipefail  # Fail on errors, undefined vars

# Constants in UPPER_CASE
INBOX_DIR="inbox"
EVENT_LOG="events.log"

# Functions in snake_case
send_message() {
    local from="$1"
    local to="$2"
    local subject="$3"
    local body="$4"

    # Implementation
}

# Always quote variables
echo "$VARIABLE"  # Good
echo $VARIABLE    # Bad

# Use [[ ]] instead of [ ]
if [[ "$VAR" == "value" ]]; then  # Good
if [ "$VAR" == "value" ]; then    # Acceptable
```

**Comments**:
```bash
# Brief comment on single line
function_name() {
    # Longer explanation
    # spanning multiple lines
    # if needed
}
```

**Error Handling**:
```bash
# Check return codes
if ! command; then
    echo "Error: command failed" >&2
    exit 1
fi

# Or use set -e (exit on error)
set -e
```

---

### Python (if adding Python tools)

**Style**: Follow PEP 8

```python
# Use type hints
def send_message(
    from_agent: str,
    to_agent: str,
    subject: str,
    body: str
) -> str:
    """Send a message between agents.

    Args:
        from_agent: Sender agent name
        to_agent: Recipient agent name
        subject: Message subject
        body: Message body

    Returns:
        Message ID (UUID)

    Raises:
        ValueError: If agent names are invalid
    """
    # Implementation
    pass
```

**Tools**:
- **Linting**: `ruff check .`
- **Formatting**: `ruff format .`
- **Type checking**: `mypy .`

---

### Documentation

**Markdown**:
- Use ATX-style headers (`#` not `===`)
- Line length: 120 characters (soft limit)
- Code blocks: Always specify language
```markdown
# Good
```bash
echo "Hello"
```

# Bad
```
echo "Hello"
```
```

**Docstrings**:
- Use Google style for Python
- Use comments for Bash functions
```bash
# send_message - Send a message between agents
#
# Arguments:
#   $1 - from_agent (string)
#   $2 - to_agent (string)
#   $3 - subject (string)
#   $4 - body (string)
#
# Returns:
#   Message ID (UUID)
#
# Example:
#   send_message "code" "chat" "Hello" "Test"
```

---

## Testing Guidelines

### Unit Tests

Test individual functions:

```bash
# tests/test_message_id.sh
test_generate_message_id() {
    local message_id=$(generate_message_id "code")

    # Check format: TIMESTAMP-SENDER-UUID
    assert_matches "$message_id" "^[0-9]{4}-[0-9]{2}-[0-9]{2}.*-code-[a-f0-9-]{36}$"
}
```

### Integration Tests

Test workflows:

```bash
# tests/test_send_receive.sh
test_send_and_receive() {
    ./message.sh send code chat "Test" "Body"

    local inbox=$(./message.sh inbox chat)
    assert_contains "$inbox" "Test"
}
```

### Platform Tests

Test on multiple platforms:
- macOS (primary)
- Ubuntu 22.04
- Windows WSL2

---

## Documentation

### When to Update Docs

**Always update docs when**:
- Adding new features
- Changing behavior
- Adding new commands
- Fixing bugs (if relevant to users)

**Where to update**:
- `README.md` - If affecting quick start
- `docs/` - Main documentation
- `CHANGELOG.md` - For releases
- Docstrings/comments - For code

### Building Docs Locally

```bash
# Install MkDocs
pip install mkdocs-material

# Serve locally
mkdocs serve
# Visit: http://127.0.0.1:8000

# Build static HTML
mkdocs build
```

---

## Community

### Communication Channels

- **GitHub Discussions**: General questions, ideas
- **GitHub Issues**: Bug reports, feature requests
- **Email**: devvyn@example.com (private inquiries)

### Getting Help

1. Check [documentation](docs/index.md)
2. Search [existing issues](https://github.com/devvyn/coordination-system/issues)
3. Ask in [discussions](https://github.com/devvyn/coordination-system/discussions)
4. Create new issue if needed

---

## Recognition

Contributors are recognized in:
- Git commit history (Co-Authored-By)
- CHANGELOG.md
- README.md acknowledgments

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## Questions?

If you have questions about contributing, please:
1. Check this guide
2. Ask in [GitHub Discussions](https://github.com/devvyn/coordination-system/discussions)
3. Email devvyn@example.com

---

**Thank you for contributing to Coordination System!** 🎉

---

*Last updated: 2025-10-30*
