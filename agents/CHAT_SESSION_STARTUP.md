# CHAT Session Startup

## ORIENTATION

Context: Rapid session initialization protocol for Chat agent
Authority: Autonomous startup checks when human triggers
Escalate: None (startup protocol is informational)

## HUMAN TRIGGER

Say: "Check project status" OR "Session start"

## STARTUP PROTOCOL (3 minutes total)

```bash
# 1. Bridge messages (30s)
ls ~/devvyn-meta-project/bridge/outbox/chat/
# Process CRITICAL/HIGH immediately

# 2. Active projects (60s)
cat ~/devvyn-meta-project/projects/active-projects.md
# Flag: YELLOW/RED health status

# 3. Review requests (30s)
# Check CLAUDE.md in Tier 1/2 projects:
# - aafc-herbarium-dwc-extraction-2025
# - s3-image-dataset-kit
# - python-toolbox-devvyn
# - claude-code-hooks
# Note: [ ] incomplete requests

# 4. Strategic context (30s)
cat ~/devvyn-meta-project/key-answers.md
# Note: pending questions/decisions

# 5. Report status (30s)
```

## REPORT FORMAT

```
🔔 Bridge: [X messages - Y high priority]
📊 Projects: [Status summary - RED/YELLOW alerts]
📝 Reviews: [X pending requests]
🎯 Context: [Key strategic items]
```

## SKIP PROTOCOL IF

- Specific standalone question asked
- Continuing previous session conversation
- Human says "skip startup checks"

## EXTENDED ABSENCE (>1 week)

```bash
# Check new projects
ls /Users/devvynmurphy/Documents/GitHub/ | grep -v node_modules

# Framework version
head -5 ~/devvyn-meta-project/README.md
```

## QUICK COMMANDS

| Command | Action |
|---------|--------|
| "Session start" | Full protocol |
| "Check bridge" | Bridge only |
| "Project status" | Active projects only |
| "Review requests" | CLAUDE.md scan |
| "Skip checks" | Jump to conversation |

## FAILURE RECOVERY

```tla
INVARIANT StartupResilience ≜
  FileMissing ∨ FileInaccessible
  ⇒ (ReportUnavailable ∧ ContinueWithAvailable ∧ ¬BlockConversation)
```

Protocol enhances sessions, doesn't gate them.
