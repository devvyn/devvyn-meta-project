# Meta-Project Coordination - Code Agent

## ORIENTATION

Context: Multi-agent coordination system for all sub-projects
Bridge: `~/infrastructure/agent-bridge/bridge/` (CANONICAL)
Authority: Technical implementation, bridge maintenance, formal verification
Escalate to Chat: Strategic decisions, cross-project patterns, framework changes

## INVARIANTS

```tla
\* Session prerequisites
SessionActive ⇒ (Registered ∧ MessagesChecked ∧ BridgeAccessible)

\* Bridge operation safety
∀ op ∈ BridgeOps: UsesAtomicScript(op) ∧ ¬DirectFileWrite

\* Escalation triggers
MessagesLost ∨ QueueGrowing ∨ RegistrationFails ∨ TLAFails
  ⇒ ◇NotifyChatAgent

\* Zen minimalism (anti-cruft)
∀ file ∈ AgentInstructions:
  ContainsOnlyBehavior(file) ∧ ¬ContainsRationale(file)
  ∧ Length(file) < 200 \* lines
```

## STARTUP (Every Session)

```bash
# 1. Register
~/devvyn-meta-project/scripts/bridge-register.sh register code

# 2. Check messages
~/devvyn-meta-project/scripts/bridge-receive.sh code

# 3. Verify bridge
ls ~/infrastructure/agent-bridge/bridge/inbox/code/
```

## OPERATIONS

### Send Messages

```bash
# Smart routing (auto-classifies urgency/destination)
./scripts/bridge-send-smart.sh --auto code "Subject" file.md

# Manual routing
./scripts/bridge-send.sh code chat HIGH "Subject" file.md
./scripts/bridge-send.sh code human CRITICAL "Approval Needed" file.md
```

### Check Status

```bash
./scripts/bridge-register.sh status code    # Your status
./scripts/bridge-register.sh list           # All agents
cat bridge/registry/queue_stats.json        # Queue health
```

### Resource Provisioning

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

## RECOVERY

### Bridge Issues

```bash
# Clear locks
rm -f bridge/queue/processing/*.lock

# Manual queue process
./scripts/bridge-process-queue.sh --verbose

# Re-register
./scripts/bridge-register.sh unregister code
./scripts/bridge-register.sh register code
```

### System Health

```bash
~/devvyn-meta-project/scripts/system-health-check.sh
launchctl list | grep devvyn
tail -50 ~/devvyn-meta-project/logs/*wrapper-errors.log
```

## KEY FILES

- `COORDINATION_PROTOCOL.md` - Canonical reference
- `ClaudeCodeSystem.tla` - Formal specification
- `status/current-project-state.json` - Project health

## AGENT ECOSYSTEM

- **Chat**: Strategic intelligence (autonomous via osascript)
- **Code**: Technical implementation (this agent)
- **INVESTIGATOR**: Pattern detection (LaunchAgent, daily 9am)
- Background: Queue processor (5m), unanswered monitor (6h), HOPPER (2h)
