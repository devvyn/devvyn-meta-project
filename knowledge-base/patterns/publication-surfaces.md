# Publication Surfaces: Beyond Domain Names

## Overview

Publication surfaces are **where context lands, how it's discovered, and when it's consumed**. This goes far beyond traditional web publishing (domain → server → HTTP → browser) to include filesystems, queues, events, audio, time-based triggers, and content-addressed graphs.

## Core Concept

Traditional web model:
- **Location-based**: Domain name points to server
- **Synchronous**: Request-response pattern
- **Mutable**: Content can be overwritten
- **Single-channel**: HTTP/HTTPS

Publication surfaces model:
- **Multi-channel**: 10+ distinct surfaces with different characteristics
- **Asynchronous**: Queue-based, event-driven
- **Immutable**: Event sourcing, content addressing
- **Time-aware**: Temporal triggers and deferred delivery

## Available Surfaces

### 1. Agent Inbox (agent-inbox)

**Purpose**: Inter-agent communication with FIFO semantics

**Characteristics**:
- File-based message queues
- Priority-aware (CRITICAL > HIGH > NORMAL > INFO)
- Atomic operations (collision-safe)
- Local filesystem

**Use When**:
- Sending messages between agents
- Delegating tasks
- Broadcasting status updates

**Discovery**:
```bash
surface-discover.sh --scope local --protocol file-based-queue
surface-info.sh agent-inbox
```

**Publishing**:
```bash
# Via unified interface
surface-publish.sh agent-inbox \
  --from code \
  --to chat \
  --priority HIGH \
  --subject "Analysis Complete" \
  results.md

# Via direct command
~/devvyn-meta-project/scripts/bridge-send.sh code chat HIGH "Subject" message.md
```

**Location**: `~/infrastructure/agent-bridge/bridge/inbox/{agent}/`

---

### 2. Event Log (event-log)

**Purpose**: Immutable history with temporal addressing

**Characteristics**:
- Append-only (never modified)
- Timestamp-based discovery
- State reconstruction from events
- Permanent persistence

**Use When**:
- Recording decisions
- Tracking pattern discoveries
- Creating audit trails
- Enabling time-travel debugging

**Publishing**:
```bash
surface-publish.sh event-log --type decision decision.md
surface-publish.sh event-log --type pattern pattern-discovery.md
```

**Querying**:
```bash
# Recent patterns
bridge-query-events.sh --type pattern --since 7d

# State at specific time
bridge-derive-state.sh --as-of 2025-10-15
```

**Event Types**:
- `decision` - Strategic decisions
- `pattern` - Discovered patterns
- `story` - Narrative-wrapped patterns
- `state-change` - System transitions

**Location**: `~/infrastructure/agent-bridge/bridge/events/`

---

### 3. Content-Addressed DAG (content-dag)

**Purpose**: Provenance tracking via content addressing

**Characteristics**:
- Content = Identity (same hash = same content)
- Automatic deduplication
- Cryptographic verification
- Explicit lineage tracking

**Use When**:
- Storing build artifacts
- Tracking data lineage
- Ensuring reproducibility
- Preventing corruption

**Publishing**:
```bash
surface-publish.sh content-dag artifact.json
```

**Location**: `.dag/objects/{hash_prefix}/{full_hash}`

---

### 4. Defer Queue (defer-queue)

**Purpose**: Time-delayed and condition-based delivery

**Characteristics**:
- Value preservation ("good idea, wrong time")
- Conditional activation
- Re-surfacing mechanisms
- Until-activated persistence

**Use When**:
- Idea arrives too early
- Project-specific context
- Periodic review items
- Condition-based triggers

**Publishing**:
```bash
surface-publish.sh defer-queue \
  --condition "project-X-starts" \
  --category strategic \
  proposal.md
```

**Reviewing**:
```bash
review-deferred.sh --category strategic
review-deferred.sh --trigger "project-X-starts"
activate-deferred.sh <id>
```

**Location**: `~/infrastructure/agent-bridge/bridge/defer-queue/`

---

### 5. Human Desktop (human-desktop)

**Purpose**: Urgent human attention surface

**Characteristics**:
- High visibility
- Transient (auto-organized)
- Immediate attention signal
- Local filesystem

**Use When**:
- Critical decisions needed
- Security issues
- Urgent approvals
- Time-sensitive information

**Publishing**:
```bash
surface-publish.sh human-desktop urgent-approval.md
```

**Auto-organization**: LaunchAgent moves files to `~/inbox/` periodically

**Location**: `~/Desktop/`

---

### 6. Human Inbox (human-inbox)

**Purpose**: Organized task queue with accountability

**Characteristics**:
- Category-based organization
- Status tracking (read/unread/completed)
- Until-processed persistence
- Accountability monitoring

**Use When**:
- Non-urgent human tasks
- Review requests
- Decision requests
- Follow-up items

**Publishing**:
```bash
surface-publish.sh human-inbox \
  --category decisions \
  review-request.md
```

**Monitoring**:
```bash
inbox-status.sh
unanswered-queries-monitor.sh
```

**Location**: `~/inbox/{category}/`

---

### 7. Audio Documentation (audio-documentation)

**Purpose**: Passive consumption via text-to-speech

**Characteristics**:
- Multi-voice narration (structural landmarks)
- Time-shifted consumption
- Multimodal distribution
- Permanent audio files

**Use When**:
- Ambient learning
- Commuting/driving
- Accessibility needs
- Sleep learning
- Eyes-free consumption

**Publishing**:
```bash
# macOS native (multi-voice)
surface-publish.sh audio-documentation \
  --provider macos \
  technical-doc.md

# ElevenLabs (premium)
surface-publish.sh audio-documentation \
  --provider elevenlabs \
  documentation.md

# OpenAI TTS
surface-publish.sh audio-documentation \
  --provider openai \
  guide.md
```

**Multi-Voice Mapping** (macOS):
- **Jamie** - Main narration
- **Lee** - Section headers
- **Serena** - Block quotes
- **Fred** - Code blocks

**Location**: `~/Desktop/Knowledge-Base-Audio/{category}/`

---

### 8. Shared Resources (shared-resources)

**Purpose**: Collective resource provisioning

**Characteristics**:
- Watch folder automation
- Batch processing
- Completion notifications
- Permanent shared storage

**Use When**:
- Downloading datasets
- Acquiring models
- Batch file operations
- Large resource provisioning

**Publishing**:
```bash
# Drop .torrent file in watch folder
cp dataset.torrent ~/Music/Music/.../Automatically\ Add.../

# Check status
transmission-remote -l

# Check completions
tail -f ~/devvyn-meta-project/logs/torrent-completions.log
```

**Location**: `~/infrastructure/shared-resources/`

---

### 9. MCP Tools (mcp-tools)

**Purpose**: Capabilities as callable endpoints

**Characteristics**:
- RPC-style invocation
- Typed parameters
- Session-scoped
- Programmatic access

**Use When**:
- Batch operations
- Complex workflows
- Data transformations
- Specialized operations

**Publishing**:
```python
# Create MCP tool
@mcp.tool()
def my_capability(param: str) -> str:
    """Tool description"""
    return result
```

**Location**: `~/devvyn-meta-project/mcp/servers/`

---

### 10. LaunchAgents (launchagents)

**Purpose**: Temporal context surfacing

**Characteristics**:
- Scheduled execution
- Periodic re-surfacing
- Autonomous operation
- System-level persistence

**Use When**:
- Periodic reviews
- Message delivery
- Accountability monitoring
- Scheduled context surfacing

**Example Agents**:
- `com.devvyn.bridge-queue.plist` - Every 5 minutes (message delivery)
- `com.devvyn.investigator.plist` - Daily at 9am (pattern detection)
- `com.devvyn.unanswered-queries.plist` - Every 6 hours (accountability)

**Management**:
```bash
launchctl load ~/Library/LaunchAgents/com.devvyn.*.plist
launchctl list | grep devvyn
```

---

## External Surfaces (Planned)

### 11. Web Webhooks (web-webhooks)

**Purpose**: Publish to external HTTP endpoints

**Supports**:
- Slack
- Discord
- GitHub API
- Generic webhooks

**Configuration**: `~/infrastructure/agent-bridge/bridge/config/web-adapters.json`

**Publishing**:
```bash
surface-publish.sh web-webhooks \
  --service slack \
  --channel general \
  announcement.md
```

---

### 12. Email Bridge (email-bridge)

**Purpose**: Bidirectional email integration

**Characteristics**:
- IMAP inbox monitoring
- SMTP outbound sending
- Sender/recipient whitelisting
- External human integration

**Configuration**: `~/infrastructure/agent-bridge/bridge/config/email-config.json`

**Publishing**:
```bash
surface-publish.sh email-bridge \
  --to collaborator@example.com \
  --subject "Project Update" \
  update.md
```

**Receiving** (LaunchAgent):
```bash
~/devvyn-meta-project/scripts/adapters/email-receive.sh --mark-read
```

---

### 13. Public Documentation (public-docs)

**Purpose**: Static site generation and deployment

**Supports**:
- GitHub Pages
- Netlify
- Local build

**Configuration**: `~/infrastructure/agent-bridge/bridge/config/docs-publish.json`

**Publishing**:
```bash
# GitHub Pages
surface-publish.sh public-docs github-pages ~/devvyn-meta-project/docs

# Netlify
surface-publish.sh public-docs netlify ~/devvyn-meta-project/knowledge-base

# Local test
surface-publish.sh public-docs local
```

---

## Comparison to Traditional Publishing

| Aspect | Traditional Web | Publication Surfaces |
|--------|----------------|---------------------|
| Addressing | DNS domain names | 13+ surface types |
| Discovery | Search engines, links | Agent registry, time queries, content hashes |
| Persistence | Server uptime | Filesystem, immutable events, content-addressed |
| Updates | Overwrite or new URL | New events reference old (no overwrites) |
| Audience | Public, passive | Specific agents/humans, active consumption |
| Protocol | HTTP/HTTPS | File-based, IMAP, SMTP, RPC, time-based |
| Timing | Synchronous request-response | Async queues, deferred delivery, temporal triggers |

---

## Design Principles

### 1. Pluralistic Approach

No single "right" surface. Each optimized for different needs:
- **Agent inbox** - Inter-agent communication
- **Event log** - Historical record
- **Desktop** - Urgent human attention
- **Audio** - Passive consumption
- **Defer queue** - Temporal mismatch resolution

### 2. Filesystem as Universal Bus

Benefits:
- No network stack overhead
- Atomic operations (POSIX guarantees)
- Persistent by default
- Human-inspectable
- Works offline

### 3. Time as First-Class Dimension

- **Event timestamps** enable time travel
- **Defer queue** enables future delivery
- **LaunchAgents** enable periodic surfacing
- **Temporal addressing** enables historical queries

### 4. Content-Addressing Prevents Ambiguity

- Same hash = same content (deduplication)
- Hash mismatch = corruption detected
- Provenance is cryptographically verifiable

### 5. Immutability Creates Trust

- Events never modified (append-only)
- State derived from history
- Audit trail is automatic
- Corruption is impossible

---

## Discovery Tools

### List Available Surfaces

```bash
# All surfaces
surface-discover.sh

# Filter by scope
surface-discover.sh --scope local
surface-discover.sh --scope external

# Filter by protocol
surface-discover.sh --protocol file-based
surface-discover.sh --protocol http

# JSON output
surface-discover.sh --json | jq '.local[].key'
```

### Get Surface Details

```bash
surface-info.sh agent-inbox
surface-info.sh event-log
surface-info.sh audio-documentation
```

### Unified Publishing

```bash
# General pattern
surface-publish.sh <surface> [options] <content>

# See help for surface-specific options
surface-publish.sh --help
```

---

## Integration Patterns

### Pattern 1: Agent-to-Human Escalation

```bash
# Try agent first
surface-publish.sh agent-inbox \
  --from code --to chat \
  --priority HIGH \
  --subject "Review Needed" \
  analysis.md

# If urgent, escalate to human
surface-publish.sh human-desktop urgent-review.md

# If non-urgent, to inbox
surface-publish.sh human-inbox \
  --category reviews \
  code-review.md
```

### Pattern 2: Event-Driven Workflows

```bash
# Record decision event
surface-publish.sh event-log --type decision decision.md

# Query recent decisions
bridge-query-events.sh --type decision --since 7d

# Derive current state
bridge-derive-state.sh
```

### Pattern 3: Temporal Context Management

```bash
# Good idea, wrong time
surface-publish.sh defer-queue \
  --condition "project-launch" \
  --category strategic \
  enhancement-proposal.md

# Review deferred items
review-deferred.sh --category strategic

# Activate when condition met
activate-deferred.sh <id>
```

### Pattern 4: Multimodal Distribution

```bash
# Written documentation
cp guide.md ~/devvyn-meta-project/docs/

# Audio version for passive learning
surface-publish.sh audio-documentation --provider macos guide.md

# Public web version
surface-publish.sh public-docs github-pages ~/devvyn-meta-project/docs
```

### Pattern 5: External Integration

```bash
# Internal discussion
surface-publish.sh agent-inbox --from code --to chat ...

# External notification
surface-publish.sh web-webhooks --service slack --channel dev-updates ...

# Formal communication
surface-publish.sh email-bridge --to stakeholder@company.com ...
```

---

## Best Practices

### Choosing the Right Surface

1. **Consider audience**:
   - Agent → `agent-inbox`
   - Human (urgent) → `human-desktop`
   - Human (non-urgent) → `human-inbox`
   - External → `web-webhooks` or `email-bridge`

2. **Consider timing**:
   - Immediate → `agent-inbox`, `human-desktop`
   - Deferred → `defer-queue`
   - Periodic → `launchagents`

3. **Consider persistence**:
   - Transient → `human-desktop`
   - Until-processed → `agent-inbox`, `human-inbox`
   - Permanent → `event-log`, `content-dag`

4. **Consider modality**:
   - Text → Most surfaces
   - Audio → `audio-documentation`
   - Web → `public-docs`

### Avoid Anti-Patterns

❌ **Don't overwrite state directly**
- Use event log instead
- State is derived, not stored

❌ **Don't lose context due to timing**
- Use defer queue for "good idea, wrong time"
- Set up LaunchAgents for periodic re-surfacing

❌ **Don't skip accountability**
- Use human inbox with status tracking
- Set up unanswered queries monitoring

❌ **Don't publish sensitive data externally**
- Check recipient/sender whitelists
- Use local surfaces for sensitive content

---

## Configuration Files

All surface configurations live in `~/infrastructure/agent-bridge/bridge/config/`:

- `publication-surfaces.json` - Surface registry (read-only)
- `web-adapters.json` - Webhook configurations
- `email-config.json` - SMTP/IMAP settings
- `docs-publish.json` - Documentation publishing targets

**Templates** available with `.template` suffix.

---

## Registry Schema

See `~/infrastructure/agent-bridge/bridge/registry/publication-surfaces.json`:

```json
{
  "surfaces": {
    "surface-name": {
      "name": "Human-readable name",
      "protocol": "file-based|http|email|...",
      "location_pattern": "Path or URL pattern",
      "discovery_method": "How to find this surface",
      "access_pattern": "How to use it",
      "persistence": "How long data lives",
      "scope": "local|external|public",
      "description": "What it's for",
      "publish_command": "CLI command template",
      "consume_command": "How to read from it",
      "examples": ["Example paths/URLs"],
      "capabilities": ["Features"],
      "use_cases": ["When to use"]
    }
  }
}
```

---

## Future Directions

### Potential New Surfaces

1. **Voice Memos** - Audio input → transcription → bridge message
2. **Calendar Events** - Meeting scheduled → defer queue trigger
3. **GitHub Issues** - Issue created → bridge message
4. **Physical Devices** - IoT sensors → event log
5. **Screen Captures** - Screenshot → OCR → context extraction

### Emerging Patterns

1. **Cross-surface workflows** - Message starts in inbox, escalates to desktop, archived to events
2. **Adaptive routing** - Smart classification based on content/urgency
3. **Surface orchestration** - Multi-surface publishing for redundancy
4. **Context synthesis** - Aggregating across surfaces for holistic view

---

## References

- **Agent Bridge**: `~/infrastructure/agent-bridge/`
- **Discovery Tools**: `~/devvyn-meta-project/scripts/surface-*.sh`
- **Adapters**: `~/devvyn-meta-project/scripts/adapters/`
- **Coordination Protocol**: `~/devvyn-meta-project/COORDINATION_PROTOCOL.md`
- **Formal Spec**: `~/devvyn-meta-project/ClaudeCodeSystem.tla`

---

## Conclusion

Publication surfaces are **not a replacement for domain names**, but rather a **pluralistic expansion** of what "publishing" means:

- From **location-based** to **content-addressed**
- From **synchronous** to **asynchronous**
- From **mutable** to **immutable**
- From **single-channel** to **multi-channel**
- From **always-now** to **time-aware**

The key insight: **Publication surface = where context lands + how it's discovered + when it's consumed**.

This system demonstrates that information distribution can be far more sophisticated than HTTP GET/POST, embracing filesystems, queues, events, audio, time-based triggers, and content-addressed graphs as equally valid—and often superior—publication mechanisms.
