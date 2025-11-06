# Archive Organization Standards

**Version**: 1.0
**Last Updated**: 2025-11-01
**Status**: Active Standard

## Purpose

This document defines standards for organizing archived materials in the meta-project to prevent confusion between current and historical content through proper information design.

## Core Principle

> **Archives must not create confusion through juxtaposition**

Historical materials must be clearly separated and marked to prevent accidental conflation with current systems, documentation, or code.

## Archive Types

### 1. Historical Snapshots (`archive/`)

**Purpose**: Complete system version snapshots
**Location**: `~/devvyn-meta-project/archive/<component>-snapshots/`
**Status**: Read-only, reference only
**Retention**: 3-12 months typical

**Examples**:

- `archive/bridge-system-snapshots/bridge-v2-2025-09-28/`

### 2. Documentation Archives (`docs/archive/`)

**Purpose**: Superseded or deprecated documentation
**Location**: `~/devvyn-meta-project/docs/archive/`
**Status**: Read-only, historical reference
**Retention**: Indefinite (minimal storage cost)

**Examples**:

- Old framework versions
- Superseded protocols
- Completed initiative documentation

### 3. Operational Archives (`<system>/archive/`)

**Purpose**: Ongoing operational history (e.g., processed messages)
**Location**: Within active system directories
**Status**: Active, continuously updated
**Retention**: Per system policy

**Examples**:

- `bridge/archive/` - Processed bridge messages (active system)

## Critical Distinction

| Type | Purpose | Status | Location Pattern |
|------|---------|--------|------------------|
| **Historical Snapshot** | Preserve old versions | Obsolete | `archive/<component>-snapshots/` |
| **Operational Archive** | Current system history | Active | `<system>/archive/` |

**Never confuse these two!** Operational archives are part of current systems. Historical snapshots are retired versions.

## Required Markers

Every archive directory MUST contain one or both of:

### 1. ARCHIVED_AT.txt (Minimal)

Simple timestamp file for quick status check:

```
2025-09-28T00:00:00-06:00
Brief reason for archival
```

**When to use**: Small archives, simple cases

### 2. ARCHIVED_SNAPSHOT.md or ARCHIVE_README.md (Comprehensive)

Full context documentation with:

- What this archive contains
- Why it was archived
- Current location of equivalent content
- Warnings against misuse
- Deletion criteria

**When to use**: Large archives, complex systems, high confusion risk

## Naming Conventions

### Historical Snapshots

```
archive/<component>-snapshots/<component>-<version>-<YYYY-MM-DD>/
```

**Examples**:

- `archive/bridge-system-snapshots/bridge-v2-2025-09-28/`
- `archive/docs-snapshots/docs-v1-2025-11-02/`

### Documentation Archives

```
docs/archive/<descriptive-name>.md
docs/archive/<initiative-name-date>/
```

**Examples**:

- `docs/archive/FRAMEWORK.md`
- `docs/archive/key-answers-cleanup-2025-10-10/`

### Version Archives

```
docs/archived-v<N>/
```

**Examples**:

- `docs/archived-v1/`
- `agents/archived-v2/`

## File Naming in Archives

Preserve original names when possible, add `.original` suffix if needed for clarity:

```
docs/archived-v1/CLAUDE.md.original
docs/archived-v1/CHAT_AGENT_INSTRUCTIONS.md.original
```

## Information Design Principles

### 1. Visual Separation

Archives must be **visually distinct** from current content:

- ✅ Separate top-level `archive/` directory
- ✅ `archived-v1/` naming convention
- ✅ `<system>/archive/` for operational archives
- ❌ Mixing archived and current files in same directory

### 2. Clear Markers

Every archive entry point must have:

- ✅ README or ARCHIVED_SNAPSHOT file at root
- ✅ ARCHIVED_AT.txt with timestamp
- ✅ Warnings against misuse
- ✅ Pointers to current equivalents

### 3. Metadata Richness

Archive markers should answer:

- **What**: What is archived here?
- **When**: When was it archived?
- **Why**: Why was it retired/superseded?
- **Where**: Where is the current version?
- **Risk**: What happens if used by mistake?
- **Deletion**: When is it safe to delete?

### 4. Prevent Accidental Reference

- ✅ Clear "DO NOT USE" warnings
- ✅ Documentation of current alternatives
- ✅ No executable scripts in historical snapshots (or mark non-executable)
- ✅ Grep-able warnings for code analysis

## When to Create an Archive

### Creating Historical Snapshots

Create when:

1. Major version upgrade (v2 → v3)
2. Significant architectural change
3. System retirement/replacement
4. Rollback safety margin needed

### Archiving Documentation

Archive when:

1. Documentation superseded by new version
2. Pattern/approach deprecated
3. Initiative completed, outcomes documented elsewhere
4. Content outdated and not worth updating

## When to Delete an Archive

### Safety Criteria

Safe to delete when **ALL** of:

1. ✅ Archived version > 3 months old
2. ✅ New version proven stable
3. ✅ No rollback scenarios remain
4. ✅ Historical value < storage cost
5. ✅ Content documented elsewhere (if needed)
6. ✅ No active references from current code

### Warning Signs

Do NOT delete if:

- ❌ New version has unresolved issues
- ❌ Active research referencing archive
- ❌ Compliance/audit requirements
- ❌ Unique historical information
- ❌ Code still references archived material

## Archive Maintenance Schedule

| Frequency | Activity |
|-----------|----------|
| **On Creation** | Add ARCHIVED_AT.txt + README |
| **Monthly** | Review operational archive sizes |
| **Quarterly** | Review historical snapshots for deletion |
| **Yearly** | Compress old archives (tar.gz) |

## Git Integration

All archive documentation changes must be tracked in git:

```bash
git add archive/README.md
git add archive/*/ARCHIVED_*.md
git add docs/archive/ARCHIVE_README.md
git commit -m "docs: Add archive organization markers

- Add clear warnings to prevent confusion
- Document archive vs operational distinction
- Establish deletion criteria"
```

**Why**: Archive markers are as important as active documentation. Their absence or outdatedness is a defect.

## Validation Checklist

Before closing an archive organization task:

- [ ] Every archive directory has ARCHIVED_AT.txt or README
- [ ] No ambiguity between current and archived paths
- [ ] Clear warnings against misuse present
- [ ] Current alternatives documented
- [ ] Deletion criteria specified
- [ ] Changes committed to git
- [ ] No active code references archived content (or intentional)

## Examples

### Good Archive Organization ✅

```
archive/
  README.md  ← Explains distinction between historical and operational
  bridge-system-snapshots/
    bridge-v2-2025-09-28/
      ARCHIVED_SNAPSHOT.md  ← Full context
      ARCHIVED_AT.txt        ← Quick status
      <snapshot contents>

docs/archive/
  ARCHIVE_README.md  ← Explains what's here and why
  ARCHIVED_AT.txt     ← Timestamp
  FRAMEWORK.md        ← Archived doc

bridge/archive/  ← OPERATIONAL (active system)
  processed-*.md  ← Current bridge history
```

### Poor Archive Organization ❌

```
old_bridge/  ← Vague name
  <files>     ← No markers!

docs/
  FRAMEWORK-old.md  ← Mixed with current docs
  FRAMEWORK.md

bridge/
  archive_2025/  ← Unclear if operational or historical
```

## Anti-Patterns

### 1. Mixed Current and Archived

❌ **Don't**:

```
docs/
  API.md
  API-v1.md
  API-v2.md
  API-deprecated.md
```

✅ **Do**:

```
docs/
  API.md  ← Current
docs/archive/
  API-v1.md
  API-v2.md
```

### 2. Ambiguous Naming

❌ **Don't**:

```
old-stuff/
backup-2025/
deprecated/
```

✅ **Do**:

```
archive/docs-snapshots/docs-v1-2025-01-15/
docs/archived-v2/
```

### 3. Missing Markers

❌ **Don't**:

```
archive/
  bridge-v2/
    <just files, no explanation>
```

✅ **Do**:

```
archive/
  bridge-system-snapshots/
    bridge-v2-2025-09-28/
      ARCHIVED_SNAPSHOT.md  ← Critical!
      <files>
```

## Reference Implementation

See these directories for reference implementations:

- `archive/` - Root archive with README
- `archive/bridge-system-snapshots/bridge-v2-2025-09-28/` - Full snapshot markers
- `docs/archive/` - Documentation archive with README
- `docs/archived-v1/` - Version archive with ARCHIVED_AT.txt

## Related Standards

- **Git Commit Standards**: All archive changes must be committed
- **Documentation Standards**: Archive docs use same markdown conventions
- **Code Review**: Archive organization changes require review

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-01 | Initial standard, established markers and principles |

---

**Authority**: Meta-Project Coordination System
**Enforcement**: Automated checks (planned), manual review (current)
**Exceptions**: Require documentation and approval
