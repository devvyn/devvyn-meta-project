# Archive Directory

**Purpose**: Historical Snapshots and Superseded Systems
**Status**: Reference Only - Not Operational

## What Lives Here

This archive contains **complete snapshots of superseded system versions** and retired components. Everything in this directory is historical and should not be used for current operations.

## Current Contents

### bridge-system-snapshots/
Complete snapshots of bridge system versions:
- **bridge-v2-2025-09-28/** - Bridge v2.0 snapshot (244KB)
  - Status: SUPERSEDED by Bridge v3.0
  - Safe to delete: Yes (v3.0 is stable)
  - See: `bridge-v2-2025-09-28/ARCHIVED_SNAPSHOT.md`

## ⚠️ Critical Distinction

### This Archive (Historical Snapshots)
- **Location**: `~/devvyn-meta-project/archive/`
- **Purpose**: Preserve old system versions
- **Status**: Read-only, historical reference
- **Use case**: Understanding system evolution

### Operational Archives (Active)
- **Location**: `~/devvyn-meta-project/bridge/archive/`
- **Purpose**: Processed messages from current bridge
- **Status**: Active, continuously updated
- **Use case**: Operational message history

**Key difference**: Operational archives are part of the current system. This directory is for retired/superseded versions.

## Naming Convention

All archive snapshots should follow this pattern:
```
archive/<component>-snapshots/<component>-<version>-<date>/
  ARCHIVED_SNAPSHOT.md  # ← Required: Explains what, why, when
  <snapshot contents>
```

## When to Create a Snapshot

Create a snapshot when:
1. Major version upgrade (v2 → v3)
2. Significant architectural change
3. System retirement/replacement
4. Regulatory/compliance requirement

## When to Delete a Snapshot

Safe to delete when:
1. New version stable for 3+ months
2. No rollback scenarios remain
3. Historical value < storage cost
4. Content documented elsewhere

## Snapshot Retention Guidelines

| Version Age | Retention | Rationale |
|-------------|-----------|-----------|
| 0-3 months | Keep | Rollback safety margin |
| 3-12 months | Review | Historical value assessment |
| 12+ months | Consider deletion | Unless research value remains |

## DO NOT

- ❌ Reference archived code in active systems
- ❌ Copy configuration from archived versions
- ❌ Use archived documentation as current
- ❌ Send messages/data to archived locations

## DO

- ✅ Consult for historical decisions
- ✅ Document system evolution
- ✅ Learn from past experiments
- ✅ Compress old snapshots (tar.gz)

---

**Maintained By**: Code Agent
**Review Schedule**: Quarterly
**Last Reviewed**: 2025-11-01
