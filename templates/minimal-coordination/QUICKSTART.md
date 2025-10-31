# Minimal Coordination - 30 Second Demo

## Try it now

```bash
cd templates/minimal-coordination

# Send a message
./message.sh send code chat "Hello" "This is my first coordination message!"

# Check the inbox
./message.sh inbox chat

# View the event log
./message.sh log

# Get statistics
./message.sh stats
```

## What just happened?

1. **Collision-free message**: Generated unique ID with timestamp + sender + UUID
2. **Event sourcing**: Logged event to append-only `events.log`
3. **File-based queue**: Saved message to `inbox/chat/`
4. **Authority domain**: Message from `code` to `chat` agent

## Next steps

1. **Read the code**: `message.sh` is 300 lines, fully commented
2. **Read the guide**: `README.md` explains the design
3. **Extend it**: Add features like priorities, retry logic, or automation

## Architecture

```
message.sh
    │
    ├─ send ──────────> Generate UUID ──> Save to inbox/ ──> Log event
    │
    ├─ inbox ─────────> List messages in inbox/{agent}/
    │
    ├─ read ──────────> Display message ──> Log read event
    │
    ├─ delete ────────> Remove message ──> Log deletion
    │
    ├─ log ───────────> Display last 20 events from events.log
    │
    └─ stats ─────────> Aggregate statistics from events.log
```

## Universal patterns demonstrated

✅ **Collision-Free Messaging**
```
2025-10-30T15:30:45-06:00-code-a3f9c8d1-4b2e-9876-1234-567890abcdef
```

✅ **Event Sourcing**
```bash
cat events.log
# 2025-10-30T15:30:45-06:00|SENT|...|code|chat|Hello
# 2025-10-30T15:31:12-06:00|READ|...|code|chat|Hello
```

✅ **Authority Domains**
```bash
# code agent sends to chat agent
./message.sh send code chat "Implementation complete" "..."

# chat agent responds
./message.sh send chat code "Proceed with next task" "..."
```

✅ **File-Based Queue**
```
inbox/
├── code/
│   └── 2025-10-30T15:31:12-06:00-chat-xyz.msg
└── chat/
    └── 2025-10-30T15:30:45-06:00-code-abc.msg
```

## Clean up

```bash
# Remove all messages and events
rm -rf inbox/ events.log
```

---

**Total time**: 30 seconds to understand, 5 minutes to master, infinite applications.
