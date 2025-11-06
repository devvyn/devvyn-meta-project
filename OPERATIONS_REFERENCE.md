# Operations Reference - Code Agent

This document contains detailed operations, alternative interfaces, and specialized features. For essential operations, see CLAUDE.md.

## Publication Surfaces

```bash
# Discover available surfaces
./scripts/surface-discover.sh

# Get details about a surface
./scripts/surface-info.sh agent-inbox

# Unified publishing interface
./scripts/surface-publish.sh <surface> [options] <content>
```

## Message Routing Options

### Smart Routing

```bash
# Auto-classifies urgency/destination
./scripts/bridge-send-smart.sh --auto code "Subject" file.md
```

### Manual Routing

```bash
./scripts/bridge-send.sh code chat HIGH "Subject" file.md
./scripts/bridge-send.sh code human CRITICAL "Approval Needed" file.md
```

### Via Unified Interface

```bash
./scripts/surface-publish.sh agent-inbox --from code --to chat --priority HIGH --subject "Update" message.md
```

## Resource Provisioning

```bash
# Check download status
transmission-remote -l

# Web UI
open http://localhost:9091

# Request resource (future)
./scripts/resource-request.sh --source "magnet:?xt=..." --purpose "reason"

# Check completions
tail -f ~/devvyn-meta-project/logs/torrent-completions.log
```

**Watch Folder**: `~/Music/Music/Media.localized/Automatically Add to Music.localized/`
**Shared Storage**: `~/infrastructure/shared-resources/`
**Pattern Doc**: `knowledge-base/patterns/collective-resource-provisioning.md`

## System Health Diagnostics

```bash
~/devvyn-meta-project/scripts/system-health-check.sh
launchctl list | grep devvyn
tail -50 ~/devvyn-meta-project/logs/*wrapper-errors.log
```

## Key Reference Files

- `COORDINATION_PROTOCOL.md` - Full coordination specification
- `COORDINATION_PROTOCOL.compact.md` - Essential protocol (recommended)
- `BRIDGE_SPEC_PROTOCOL.md` - Bridge implementation details
- `ClaudeCodeSystem.tla` - Formal specification
- `INVARIANTS.md` - Essential guarantees (extracted from TLA+)
- `status/current-project-state.json` - Project health metrics

## Agent Ecosystem

- **Chat**: Strategic intelligence (autonomous via osascript)
- **Code**: Technical implementation (this agent)
- **INVESTIGATOR**: Pattern detection (LaunchAgent, daily 9am)
- **HOPPER**: Regular analysis and summarization (LaunchAgent, 2h)
- **Background processes**: Queue processor (5m), unanswered monitor (6h)

## Advanced Bridge Operations

### Lock Management

```bash
# List locks
ls bridge/queue/processing/*.lock

# Clear specific lock
rm bridge/queue/processing/message-12345.lock

# Clear all locks (use caution)
rm -f bridge/queue/processing/*.lock
```

### Queue Inspection

```bash
# View queue statistics
cat bridge/registry/queue_stats.json

# List pending messages
ls bridge/queue/pending/

# Manual queue processing
./scripts/bridge-process-queue.sh --verbose
```

### Registration Management

```bash
# Check registration status
./scripts/bridge-register.sh status code

# List all registered agents
./scripts/bridge-register.sh list

# Unregister (rarely needed)
./scripts/bridge-register.sh unregister code

# Re-register
./scripts/bridge-register.sh register code
```

## Escalation Procedures

### When to Escalate to CHAT Agent

Escalate when encountering:

- **MessagesLost**: Bridge operations failing, messages disappearing
- **QueueGrowing**: Pending messages accumulating, not processing
- **RegistrationFails**: Cannot register with bridge after retries
- **TLAFails**: Invariant violations detected
- **StrategicDecisions**: Cross-project patterns, framework changes

### How to Escalate

```bash
# High priority coordination
./scripts/bridge-send.sh code chat HIGH "Subject" message.md

# Critical issues requiring human attention
./scripts/bridge-send.sh code human CRITICAL "Approval Needed" message.md
```

## Pattern Discovery and Documentation

When you discover valuable patterns during operations:

1. Document the pattern clearly
2. Include problem, solution, context
3. Send to INVESTIGATOR for analysis
4. If high-value, may be promoted to knowledge-base/patterns/
