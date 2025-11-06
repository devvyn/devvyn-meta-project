# ⚠️ ARCHIVED BRIDGE V2 SNAPSHOT

**Status**: HISTORICAL SNAPSHOT - DO NOT USE
**Archived**: 2025-09-28
**Current Version**: Bridge v3.0 (see ~/devvyn-meta-project/bridge/)

## What This Is

This is a **complete snapshot of Bridge v2.0** taken on September 28, 2025, before migration to Bridge v3.0. This directory is preserved for historical reference only.

## ⚠️ WARNING: This is NOT the Current Bridge

- **Current bridge location**: `~/devvyn-meta-project/bridge/` (or `~/infrastructure/agent-bridge/bridge/`)
- **Current version**: Bridge v3.0
- **This snapshot**: Bridge v2.0 (obsolete)

## Why This Was Archived

Bridge v3.0 introduced significant protocol changes documented in COORDINATION_PROTOCOL.md. This snapshot preserves the v2.0 state for:
- Historical reference
- Protocol evolution documentation
- Rollback capability (if v3.0 had failed)
- Migration validation

## What's Included

- `archive/` - Processed messages from v2.0
- `inbox/`, `outbox/` - Message routing structure (v2.0 format)
- `queue/` - Queue system snapshots
- `registry/` - Agent registry (v2.0 format)
- `context/` - Context state files
- `README.md`, `USAGE_GUIDE.md` - v2.0 documentation

## DO NOT

- ❌ Use these files as current documentation
- ❌ Reference this structure in new code
- ❌ Send messages to these directories
- ❌ Copy configuration from here to current bridge

## DO

- ✅ Consult for historical protocol evolution
- ✅ Reference when documenting v2→v3 migration
- ✅ Use for academic/research purposes
- ✅ Delete if disk space needed (v3.0 is stable)

## Deletion Criteria

Safe to delete when:
- Bridge v3.0 has been stable for 3+ months ✓ (as of 2025-11-01)
- No active migration issues
- Historical value diminishes

**Recommendation as of 2025-11-01**: Safe to delete (v3.0 is mature and stable)

---

**Snapshot Created**: 2025-09-28
**Snapshot Size**: 244KB
**Bridge Version**: v2.0
**Superseded By**: Bridge v3.0 (COORDINATION_PROTOCOL.md)
