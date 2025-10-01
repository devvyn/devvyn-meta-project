# Work Session Accountability Pattern

**Pattern Type**: Professional Work Tracking
**Confidence**: HIGH (95%)
**Applies To**: All AAFC-SRDC salary work
**Last Updated**: 2025-10-01

## Pattern Description

Track all professional work sessions with complete accountability chain linking human operator, agent sessions, processing tools, and outputs.

## When to Apply

**Trigger conditions**:

- User checks in for AAFC work day
- Starting any AAFC-SRDC related development
- Beginning herbarium specimen processing
- Any salary work requiring time tracking

**Context indicators**:

- Keywords: "AAFC", "work session", "checking in", "start work"
- Workspace: AAFC-SRDC Saskatoon
- Classification: Work context (not personal projects)

## Implementation Steps

### 1. Session Initialization

```bash
# Register with bridge system
~/devvyn-meta-project/scripts/bridge-register.sh register code <session-id>

# Create/update work session log
echo "---" >> .kb-context/work-sessions.log
echo "session_start: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .kb-context/work-sessions.log
echo "session_id: <session-id>" >> .kb-context/work-sessions.log
echo "workspace: AAFC-SRDC Saskatoon" >> .kb-context/work-sessions.log
echo "project: aafc-herbarium-dwc-extraction-2025" >> .kb-context/work-sessions.log
```

### 2. Task Tracking

```yaml
tasks:
  - Task description 1
  - Task description 2
  - Task description 3

artifacts_produced:
  - Git commits with hashes
  - Documents created
  - Processing runs completed
```

### 3. Provenance Chain

```json
{
  "agent_identity": {
    "agent_type": "claude-code",
    "human_operator": "devvynmurphy",
    "session_id": "<session-id>",
    "workspace": "AAFC-SRDC Saskatoon"
  },
  "processing_metadata": {
    "run_id": "<run-id>",
    "specimens_processed": <count>,
    "ocr_engine": "apple_vision"
  },
  "accountability": {
    "professional_context": "AAFC-SRDC salary work",
    "data_classification": "PUBLISHED"
  }
}
```

### 4. Session Close

```bash
# Update work session log with duration and summary
echo "session_end: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .kb-context/work-sessions.log
echo "duration_hours: <calculated>" >> .kb-context/work-sessions.log
echo "status: completed" >> .kb-context/work-sessions.log
```

## Quality Standards

### Required Elements

- ✅ Session start timestamp (UTC)
- ✅ Session ID (format: code-NNNNN-aafc-work-session)
- ✅ Workspace identification
- ✅ Task list with descriptions
- ✅ Artifacts produced with references
- ✅ Agent provenance for processing runs

### Optional Enhancements

- Duration calculation
- Commit message summaries
- Bridge messages sent/received
- Issues created/closed

## Examples

### Example 1: Simple Work Session

```yaml
---
session_start: 2025-10-01T19:53:12Z
session_id: code-37834-aafc-work-session
workspace: AAFC-SRDC Saskatoon
project: aafc-herbarium-dwc-extraction-2025
agent: claude-code
human: Devvyn Murphy

tasks:
  - Documentation reorganization (PR #215)
  - Bridge sync and infrastructure updates
  - Work session accountability activation

artifacts_produced:
  - Commits: 152f59f, 155741d, 07f3789, 7b19252
  - Work session log initialized
  - Agent provenance tracking added

session_end: 2025-10-01T23:30:00Z
duration_hours: 3.5
status: completed
---
```

### Example 2: Processing Run with Provenance

```json
{
  "agent_identity": {
    "agent_type": "human+tooling",
    "human_operator": "devvynmurphy",
    "processing_tools": [
      "aafc-herbarium-dwc-extraction-2025",
      "s3-image-dataset-kit",
      "Apple Vision OCR"
    ],
    "session_context": "Full dataset processing",
    "workspace": "AAFC-SRDC Saskatoon"
  },
  "processing_metadata": {
    "run_id": "run_20250930_145826",
    "specimens_processed": 5770,
    "ocr_engine": "apple_vision",
    "output_size_mb": 7.8
  },
  "accountability": {
    "professional_context": "AAFC-SRDC salary work",
    "data_classification": "PUBLISHED (public scientific data)",
    "quality_status": "OCR complete, extraction pending"
  }
}
```

## Automation Decision

**Confidence**: HIGH (95%)
**Action**: AUTOMATE (Tier 1)

**Rationale**:

- User explicitly requested professional accountability tracking
- Pattern extracted from documented work session practices
- All elements derived from user behavior and stated requirements
- No sensitive decisions, purely administrative logging

**Human override indicators**:

- User says "don't log this session" → skip logging
- User provides different session format → adapt to user's preference
- User requests privacy mode → escalate for guidance

## Integration Points

### With Bridge System

- Register session with bridge for multi-agent coordination
- Send session summaries to Chat agent (codex) for strategic tracking
- Receive delegated tasks from HOPPER agent automation

### With Git Workflow

- Include session ID in commit messages for traceability
- Link commits to work session log entries
- Track artifacts produced across version control

### With Security Manifest

- Respect data classification tiers (SECRET/PRIVATE/PUBLISHED)
- Log only appropriate work context (no sensitive data)
- Follow GC security classification guidance when available

## Troubleshooting

### Issue: Session log file doesn't exist

**Solution**: Create `.kb-context/` directory and initialize log file

```bash
mkdir -p .kb-context
touch .kb-context/work-sessions.log
echo "# Work Sessions Log - AAFC-SRDC" > .kb-context/work-sessions.log
```

### Issue: Bridge registration fails

**Solution**: Verify bridge system location and registration script

```bash
# Check bridge system
ls ~/devvyn-meta-project/scripts/bridge-register.sh

# Test registration
~/devvyn-meta-project/scripts/bridge-register.sh status code
```

### Issue: Unclear what to log

**Solution**: Focus on accountability essentials

- What work was done (tasks)
- What was produced (artifacts)
- Who did it (human + agent)
- When it happened (timestamps)

---

**Pattern Status**: ✅ VALIDATED
**Source**: code-37834-aafc-work-session (2025-10-01)
**Usage Count**: 1 (bootstrap)
**Success Rate**: 100%
