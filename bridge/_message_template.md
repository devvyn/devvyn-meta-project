# [PRIORITY: CRITICAL|HIGH|NORMAL|INFO] Message Title

**Message-ID**: [timestamp]-[sender]-[uuid]
**Queue-Number**: [auto-generated]
**From**: [sender agent namespace]
**To**: [recipient agent namespace]
**Timestamp**: YYYY-MM-DDTHH:MM:SSZ
**Sender-Namespace**: [sender]-
**Session**: [Session ID or description]
**In-Reply-To**: [parent-message-id] (optional for threaded conversations)

## Context

[Why this message matters - what triggered this communication]

## Content

[The actual information, question, update, or request]

## Expected Action

[What the receiving agent should do with this information]

---

### Priority Levels

- **CRITICAL**: Immediate action required, affects current work
- **HIGH**: Should address before next major task
- **NORMAL**: Standard information sharing or coordination
- **INFO**: FYI, no action required unless relevant to current context

### Message Creation

**Automated (Recommended)**:
```bash
# Create collision-safe message with atomic operations
./scripts/bridge-send.sh sender recipient priority "title" [content_file]

# Example:
./scripts/bridge-send.sh chat code HIGH "Framework Update" update.md
```

**Manual Creation**: Use this template but ensure:
- Unique Message-ID format: [timestamp]-[sender]-[uuid]
- Proper sender namespace prefix
- Queue number assignment (use bridge-send.sh for automation)

### Bridge v3.0 Features

✅ **Collision Prevention**: Namespace isolation prevents overwrites
✅ **Atomic Operations**: Messages created atomically, no corruption
✅ **FIFO Processing**: Queue guarantees first-in-first-out order
✅ **Unique IDs**: Every message has guaranteed unique identifier
✅ **Thread Support**: In-Reply-To enables conversation threading
