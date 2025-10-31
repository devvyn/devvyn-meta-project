# Coordination System Knowledge Base Index

**Master Record**: This knowledge base is the canonical source of truth
**Status**: Living documentation
**Last Updated**: 2025-10-30

---

## Knowledge Organization

### Core Architecture Documentation

These documents form the **invariant core** of the coordination system:

- **[Universal Patterns](../docs/abstractions/universal-patterns.md)** - 8 formally verified coordination patterns (95%+ portable)
- **[Customization Guide](../docs/configuration/customization-guide.md)** - 50+ configuration points across 5 layers
- **[Platform Dependencies](../docs/platform/dependency-matrix.md)** - Complete platform portability analysis

### Quick Reference

- Patterns: `/docs/abstractions/universal-patterns.md`
- Config: `/docs/configuration/customization-guide.md`
- Platforms: `/docs/platform/dependency-matrix.md`

### Future Research Areas

- DuckDB overlay for agent queries (structured SQL over coordination system)
- CLI-GUI bridge via common API/data format
- Cross-platform data interchange formats

---

## Document Lifecycle

**Master Records**: `~/devvyn-meta-project/docs/` (version controlled)
**Knowledge Base**: `~/devvyn-meta-project/knowledge-base/` (curated, indexed)
**Working Notes**: `~/inbox/` (temporary, for processing)
**Archive**: Bridge archive (event sourcing, immutable history)

**NOT**: Desktop files (transient, cluttered, hard to find)

---

## How to Use This KB

### Finding Information

```bash
# Search patterns
rg "pattern name" knowledge-base/

# List all KB documents
fd . knowledge-base/ --type f --extension md

# Query via DuckDB (future)
duckdb kb.db "SELECT * FROM documents WHERE topic='coordination'"
```

### Adding to KB

```bash
# 1. Create document in proper location
# 2. Update KB-INDEX.md with reference
# 3. Commit to git
# 4. Do NOT save to Desktop as master copy
```

### Desktop Cleanup

```bash
# Triage Desktop documents into KB
~/devvyn-meta-project/scripts/desktop-to-kb.sh --interactive
```

---

**Principle**: Knowledge base is the source of truth. Desktop is temporary workspace only.
