# CHAT Agent Capabilities

## ORIENTATION

Context: Strategic intelligence with autonomous bridge integration
Authority: Full filesystem access, bash execution, osascript automation, MCP tools
Escalate: LaunchAgent control, git operations (human required)
Status: Production-confirmed (2025-10-03)

## CONFIRMED CAPABILITIES

### Bridge Integration (AUTONOMOUS)

```applescript
do shell script "cd ~/devvyn-meta-project && ./scripts/bridge-send.sh chat [target] [PRIORITY] 'Title' /path/to/response.md"
```

- Send messages to Code, INVESTIGATOR, Human (no human mediation)
- Full multi-agent coordination autonomy

### File System (FULL ACCESS)

```bash
# Read: Any accessible path
ls, cat, grep, pattern matching

# Write: All accessible directories
/tmp/, ~/Desktop/, ~/Documents/GitHub/[projects]/, ~/devvyn-meta-project/, ~/infrastructure/agent-bridge/

# Modify: Standard operations
mv, cp, rm, archive operations
```

### Command Execution (BASH)

```bash
do shell script "~/devvyn-meta-project/scripts/bridge-query-events.sh --type decision --since 7d"
do shell script "~/devvyn-meta-project/scripts/generate-reality-map.sh"
do shell script "grep -r 'PRIORITY: HIGH' /path/to/inbox/"
```

### MCP Tools

- `mcp__mac_control` - osascript execution (KEY capability for bridge)
- `mcp__chrome_control` - Browser automation
- `mcp__pdf_tools` - PDF analysis, extraction
- `mcp__filesystem` - File operations
- `mcp__kapture` - Web interaction
- Web search, URL fetch (real-time info)

## LIMITATIONS

### Cannot Execute

- LaunchAgent start/stop (human required)
- Git push/PR creation (human required)
- System configuration changes (human required)
- Read .env/secrets (security by design)

## AUTONOMOUS WORKFLOWS

### Message Processing

```bash
# 1. Check inbox
do shell script "ls ~/infrastructure/agent-bridge/bridge/inbox/chat/"

# 2. Read HIGH priority
do shell script "cat ~/infrastructure/agent-bridge/bridge/inbox/chat/[message].md"

# 3. Create response in /tmp/chat-response-[timestamp].md

# 4. Send via bridge
do shell script "cd ~/devvyn-meta-project && ./scripts/bridge-send.sh chat code HIGH 'Response' /tmp/response.md"

# 5. Archive original
do shell script "mv ~/infrastructure/agent-bridge/bridge/inbox/chat/[message].md /tmp/processed/"

# 6. Report to human (FYI only)
```

### Strategic Analysis

```bash
# Query event log
do shell script "~/devvyn-meta-project/scripts/bridge-query-events.sh --type story --since 7d"

# Check propagation
do shell script "~/devvyn-meta-project/scripts/track-story-propagation.sh --fitness"

# Generate map
do shell script "~/devvyn-meta-project/scripts/generate-reality-map.sh"

# Read project context
do shell script "cat ~/Documents/GitHub/[project]/CLAUDE.md"
```

## INTEGRATION

### Code ↔ Chat Coordination

```tla
INVARIANT AutonomousCoordination ≜
  CodeSendsMessage
  ∧ ChatReadsAutonomously
  ∧ ChatAnalyzesStrategically
  ∧ ChatRespondsViaBridge
  ∧ ChatArchivesMessage
  ∧ ¬HumanMediationRequired
```

### INVESTIGATOR → Chat Validation

1. INVESTIGATOR detects pattern → sends to Chat
2. Chat validates (real pattern vs false positive)
3. Chat assesses strategic priority
4. Chat responds autonomously
5. Chat escalates to human if novel

## CAPABILITY REFERENCE

| Capability | Status | Method |
|------------|--------|--------|
| Bridge messaging | ✅ Full | osascript + bridge-send.sh |
| File read/write | ✅ Full | Standard tools |
| Command execution | ✅ Full | do shell script |
| osascript access | ✅ Full | mcp__mac_control |
| MCP tools | ✅ Multiple | chrome, pdf, filesystem |
| Web access | ✅ Available | Search, fetch |
| LaunchAgent control | ❌ Limited | Human required |
| Git operations | ❌ None | Human required |

## MAINTENANCE

- Update when new capabilities discovered
- Review quarterly or on framework changes
- Document working patterns for session persistence
- Version: 1.0 (2025-10-03)
