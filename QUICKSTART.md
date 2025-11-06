# Quickstart - Code Agent

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

*For detailed operations, see: CLAUDE.md*
*For system invariants, see: INVARIANTS.md*
