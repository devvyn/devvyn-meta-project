# Context Inheritance Examples

*Practical patterns for graph-like context relationships*

## 1. Cross-Project References

### Scenario: Shared Library Development

```
~/projects/
├── core-utils/           # Base library
│   └── CLAUDE.md         # Core patterns and conventions
├── web-app/              # Consumer project
│   ├── .context-parent   # Points to ../core-utils
│   └── CLAUDE.md         # Web-specific context + inherited patterns
└── mobile-app/           # Another consumer
    ├── .context-parent   # Points to ../core-utils
    └── CLAUDE.md         # Mobile-specific context + inherited patterns
```

**Implementation**:

```bash
# In web-app/.context-parent
../core-utils

# In mobile-app/.context-parent
../core-utils

# Agents check inheritance chain:
# 1. ./CLAUDE.md (local context)
# 2. .context-parent → ../core-utils/CLAUDE.md (inherited patterns)
# 3. ~/.claude/CLAUDE.md (global preferences)
```

## 2. Temporal Context Bridging

### Scenario: Feature Development Across Sessions

```
# Session 1: Initial exploration
git commit -m "explore: investigate user auth patterns

Found existing JWT implementation in /auth/jwt.js:45
Consider migrating to more secure token rotation
Next: analyze session management requirements"

# Session 2: Agent reads commit history
git log --oneline --grep="explore:"
# Immediately understands previous context and continues investigation
```

## 3. Collaborative Decision Tracking

### Scenario: Multiple Agents Working on Same Feature

**Agent A (Claude Code) leaves trace**:

```markdown
# In key-answers.md
## #immediate
### 2025-09-27-14:30 Authentication Implementation
**From**: Claude Code
**Status**: Blocked on security review
**Context**: Implemented JWT rotation in /auth/tokens.js:78
**Question for review**: Is 15-minute refresh window appropriate for this use case?
**Next**: Awaiting security analysis before proceeding with integration
```

**Agent B (Claude Chat) responds**:

```markdown
## #immediate
### 2025-09-27-14:45 Security Analysis Complete
**From**: Claude Chat
**Status**: Analysis complete
**Recommendation**: 15-minute window acceptable for internal tools, consider 5-minute for external API
**Implementation note**: Add configurable timeout in /config/security.js
**Handoff to**: Claude Code for implementation
```

## 4. Project Hierarchy with Context Inheritance

### Scenario: Microservices Architecture

```
~/microservices/
├── CLAUDE.md                    # Service-wide patterns
├── shared/
│   ├── CLAUDE.md               # Shared library conventions
│   └── auth-lib/
├── services/
│   ├── user-service/
│   │   ├── .context-parent     # → ../../shared
│   │   └── CLAUDE.md           # Service-specific + inherited
│   └── payment-service/
│       ├── .context-parent     # → ../../shared
│       └── CLAUDE.md           # Service-specific + inherited
```

**Context Resolution Order**:

1. `./CLAUDE.md` (most specific)
2. `.context-parent` chain (inherited contexts)
3. Parent directory `../CLAUDE.md` (hierarchical)
4. `~/.claude/CLAUDE.md` (global)
5. `key-answers.md` (active coordination)

## 5. Stigmergic Pattern Recognition

### Example: Automated Pattern Detection

```bash
# Agent notices repeated pattern in commits
git log --oneline --all | grep "fix: null pointer"
# → 12 commits fixing null pointer errors

# Agent proactively suggests
echo "Consider adding null-safe patterns to shared/CLAUDE.md" >> key-answers.md

# Pattern gets codified in shared context
echo "
## Common Patterns
- Always use optional chaining: obj?.property?.method()
- Validate inputs at service boundaries
- Use Result<T, E> pattern for fallible operations
" >> shared/CLAUDE.md
```

## 6. Cross-Project Learning Transfer

### Scenario: Solution Discovery

```markdown
# In project-a/key-answers.md
## #cross-project
### Performance Optimization Success
**Pattern**: Lazy loading with React.memo reduced bundle size 40%
**Location**: /components/LazyLoader.tsx
**Applicable to**: Any React project with large component trees
**Date**: 2025-09-27
```

```bash
# Agent in project-b discovers pattern
grep -r "React.memo" ~/projects/*/key-answers.md
# Finds successful pattern and adapts for current context
```

## Implementation Notes

- **Discovery**: Agents check `.context-parent` files during initialization
- **Inheritance**: Merge contexts with local overrides taking precedence
- **Cycles**: Detect and break inheritance loops
- **Performance**: Cache resolved contexts, invalidate on file changes
- **Evolution**: Patterns naturally emerge and get promoted to shared contexts

This creates an organic knowledge graph where successful patterns propagate while maintaining local flexibility.
