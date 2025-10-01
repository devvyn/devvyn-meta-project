# Bridge Communication System v3.0 - Collision-Safe Multi-Agent Edition

## Purpose

Production-grade, collision-safe communication system between multiple AI agents (Claude Chat, Claude Code, GPT, Codex) and human collaborators. Features atomic operations, namespace isolation, and FIFO processing with formal verification guarantees.

## Directory Structure

```
bridge/
├── inbox/              # Incoming messages TO agents
│   ├── chat/          # To Claude Chat
│   ├── code/          # To Claude Code
│   ├── gpt/           # To GPT Agent
│   └── codex/         # To Codex Agent
├── outbox/             # Outgoing messages FROM agents
│   ├── chat/          # From Claude Chat
│   ├── code/          # From Claude Code
│   ├── gpt/           # From GPT Agent
│   └── codex/         # From Codex Agent
├── context/            # Shared persistent context
│   ├── decisions.md   # Strategic decisions log
│   ├── patterns.md    # Discovered patterns library
│   ├── state.json     # Current project state
│   ├── gpt_status.json    # GPT agent status
│   └── codex_status.json  # Codex agent status
├── scripts/            # Bridge automation tools
│   ├── bridge-signal.sh  # Agent status signaling
│   └── bridge-task.sh     # Message processing
└── archive/            # Processed messages
```

## Usage Patterns

### For Human Users

#### Sending Messages Between Agents

1. **To Claude Chat**: "Write a message for Code about [topic]"
   - Chat writes to `bridge/inbox/code/message-[timestamp].md`
2. **To Claude Code**: "Check bridge inbox" or mention bridge content
   - Code automatically checks inbox and processes messages

#### Starting Sessions

- **Claude Chat**: Reviews `bridge/outbox/chat/` for messages from Code
- **Claude Code**: Reviews `bridge/inbox/code/` for messages from Chat

### For Agents

#### Checking for Messages

```bash
# At start of session (automatic)
ls bridge/inbox/[agent]/

# When explicitly requested
grep -l "PRIORITY: CRITICAL" bridge/inbox/[agent]/*.md
```

#### Sending Messages

1. Copy `_message_template.md`
2. Fill in priority, context, content, expected action
3. Save to `bridge/outbox/[target_agent]/message-[timestamp].md`

#### Processing Messages

1. Read message
2. Take requested action
3. Move to `bridge/archive/processed-[timestamp].md`
4. Reply if needed

## Message Priority Levels

- **CRITICAL**: Immediate action required, affects current work
- **HIGH**: Should address before next major task
- **NORMAL**: Standard information sharing or coordination
- **INFO**: FYI, no action required unless relevant to current context

## Context Preservation

### decisions.md

Strategic decisions with rationale, implementation details, and status tracking.

### patterns.md

Discovered collaboration patterns, implementation approaches, and success indicators.

### state.json

Current project status, framework version, collaboration metrics, and agent authority domains.

## Integration with Existing Framework

This bridge system enhances the existing Multi-Agent Collaboration Framework v2.1 by:

- Eliminating passive polling overhead
- Providing clear communication priorities
- Maintaining context across sessions
- Supporting genuine multi-agent partnership

## Migration from key-answers.md

**Old Pattern**: Passive polling of `status/key-answers.md`
**New Pattern**: Event-driven messaging through bridge system

**Benefits**:

- ✅ No wasted context checks
- ✅ Clear priority signaling
- ✅ Parallel agent operation
- ✅ Full audit trail
- ✅ Scalable to additional agents

## Example Workflows

### Strategic Planning → Implementation

1. Claude Chat completes strategic session
2. Chat writes HIGH priority message to `bridge/inbox/code/`
3. User starts Claude Code session
4. Code automatically processes inbox, implements decisions
5. Code writes NORMAL priority summary to `bridge/outbox/chat/`

### Technical Question → Strategic Input

1. Claude Code encounters design decision
2. Code writes HIGH priority question to `bridge/outbox/chat/`
3. User starts Claude Chat session
4. Chat reviews outbox, provides strategic guidance
5. Chat writes HIGH priority response to `bridge/inbox/code/`

### Context Sync

1. Either agent updates `bridge/context/` files
2. Other agent automatically incorporates on next read
3. Persistent context maintained across sessions

### Agent-to-Agent Handoffs

1. Current agent writes HIGH priority message to `bridge/outbox/code/`
2. User tells new Code session: **"Check bridge inbox and continue the [work description]"**
3. New agent processes inbox, continues work, updates context
4. Work continues seamlessly across agent sessions

**Example Handoff Phrase**: "Check bridge inbox and continue the TLA+ verification work"
