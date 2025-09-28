# Chat Session Startup Guide

**For: Devvyn & Claude Chat Agent**
**Version**: 1.0

## Human Startup Protocol (First Message)

When starting a new Chat session, simply say:

> "Check project status"

or

> "Session start"

This triggers the agent to run the startup protocol below.

## Chat Agent Startup Protocol

When the human requests a session start, automatically execute:

### 1. Check Bridge Messages (30 seconds)

```
List: /Users/devvynmurphy/devvyn-meta-project/bridge/outbox/chat/
```

**Action**: Process CRITICAL and HIGH priority messages immediately.

### 2. Scan Active Projects (60 seconds)

```
Read: /Users/devvynmurphy/devvyn-meta-project/projects/active-projects.md
```

**Look for**: Projects marked YELLOW or RED health status.

### 3. Check Review Requests (30 seconds)

Active Tier 1/2 projects with CLAUDE.md files:

- `aafc-herbarium-dwc-extraction-2025`
- `s3-image-dataset-kit`
- `python-toolbox-devvyn`
- `claude-code-hooks`

**Action**: Note any `[ ]` incomplete review requests.

### 4. Read Strategic Context (30 seconds)

```
Read: /Users/devvynmurphy/devvyn-meta-project/key-answers.md
```

**Note**: Any questions or decisions pending human input.

### 5. Report Status (30 seconds)

Summarize findings:

```
🔔 Bridge: [X messages - Y high priority]
📊 Projects: [Status summary - RED/YELLOW alerts]
📝 Reviews: [X pending requests]
🎯 Context: [Key strategic items]
```

**Total time**: ~3 minutes

## When NOT to Run Startup Protocol

Skip the protocol if:

- Human asks a specific standalone question
- Continuing a previous conversation in same session
- Human explicitly says "skip startup checks"

## Manual Checks (As Needed)

If more than a few days since last session:

```bash
# Check for new projects
ls /Users/devvynmurphy/Documents/GitHub/ | grep -v node_modules

# Check framework version
head -5 /Users/devvynmurphy/devvyn-meta-project/README.md
```

## Integration with Custom Instructions

**Do NOT paste this into Custom Instructions.**

This guide lives in the filesystem. Reference it naturally when:

- Starting strategic planning sessions
- The human says "check project status"
- After extended time between sessions (>1 week)

## Quick Commands for Human

| Command | What It Does |
|---------|-------------|
| "Session start" | Full startup protocol |
| "Check bridge" | Bridge messages only |
| "Project status" | Active projects health |
| "Review requests" | Scan CLAUDE.md files |
| "Skip checks" | Jump directly to conversation |

## Failure Recovery

If files are missing or inaccessible:

1. **Report what you can't access**
2. **Continue with available information**
3. **Don't block the conversation**

The startup protocol should enhance sessions, not gate them.

---

**Next Steps**: Try saying "session start" in your next chat to test the protocol.
