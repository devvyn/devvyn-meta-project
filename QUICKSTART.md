# Quickstart - Code Agent

**Platform**: Ludarium Behavioral Coordination Platform

## Startup (Every Session)

```bash
# 1. Register
~/devvyn-meta-project/scripts/bridge-register.sh register code

# 2. Check messages
~/devvyn-meta-project/scripts/bridge-receive.sh code

# 3. Verify bridge
ls ~/infrastructure/agent-bridge/bridge/inbox/code/
```

## Essential Commands

```bash
# Send message
./scripts/bridge-send.sh <from> <to> <priority> <subject> <file>

# Check status
./scripts/bridge-register.sh status code

# Recovery
rm -f bridge/queue/processing/*.lock && \
./scripts/bridge-register.sh unregister code && \
./scripts/bridge-register.sh register code
```

---

**Additional Resources**:

- CLAUDE.md - Detailed operations and context
- INVARIANTS.md - System guarantees and formal invariants
- PLATFORM_NOMENCLATURE.md - Complete naming system and conceptual framework
- OPERATIONS_REFERENCE.md - Advanced operations and publication surfaces
