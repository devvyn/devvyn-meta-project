# HOPPER Agent Reference

This document contains detailed patterns and operational limits. For essential operations, see HOPPER_AGENT_INSTRUCTIONS.md.

## Common Desktop Patterns

**File Management:**

- Files >7 days → Archive to `~/Documents/Archive/YYYY-MM/`
- YYYYMMDD*.md <30 days → Keep, else archive
- Screenshots → `~/Pictures/Screenshots/` after 3 days

**Link/Resource Saving:**

- Documentation URLs → `~/Documents/quick-notes/links-YYYYMM.md`
- Tool URLs → `bridge/queue/deferred/` OR Desktop note
- Project URLs → Project README/docs/research/

**Output Placement:**
>
- >24 lines → `~/devvyn-meta-project/scripts/markdown-to-browser.sh ~/Desktop/YYYYMMDDHHMMSS-TIMEZONE-description.md` (renders to browser)
- JSON visualization → Desktop (no auto-cleanup)
- Work logs → `~/Documents/work-logs/[project]/`

**Documentation:**

- NEVER create proactive docs (user preference)
- Only on explicit request

## Message Structure

```yaml
# Incoming message format
priority: INFO | NORMAL | HIGH | CRITICAL
from: code | chat | investigator | human
type: decision | defer | route | organize
context: "Brief description"
decision_needed: "Specific action"
relevant_patterns: ["pattern-id"]
```

## Defer Queue Management

```yaml
# Deferred item metadata
deferred_date: YYYY-MM-DD
defer_reason: "Waiting for X" | "Low priority" | "Batch similar"
defer_until: YYYY-MM-DD | "next_planning" | "on_demand"
assigned_to: code | chat | human | null
notes: "Context for review"
```

Weekly review: Check for items ready to process

## Quality Standards

### Decision Confidence

- **High (>90%)**: Direct pattern match, clear preference, recent
- **Medium (50-90%)**: Similar pattern, extrapolated
- **Low (<50%)**: No clear pattern, conflicting, new scenario

### Documentation

- Log which pattern applied and why
- Track misses for future pattern creation
- Target: >80% pattern match success rate

### Escalation Discipline

- Don't guess - escalate when uncertain
- Learn from human corrections → update patterns
- For low-stakes: apply best-guess with notification

## Operational Limits

### Batch Windows

- Desktop cleanup: Weekly (Sundays) or on-demand
- Deferred review: Weekly planning sessions
- Pattern effectiveness: Monthly

### Resource Limits

- Deferred queue max: 100 items (alert at 75)
- Desktop: User/agent-created files only (not system)
- decision-patterns.md: <500 lines (refactor if larger)

### Success Metrics

- Primary: Context switches prevented (target: 5-10/week)
- Secondary: Pattern match accuracy (>80%)
- Tertiary: Time saved (measured via surveys)

## Files Monitored

- `decision-patterns.md` - User preference patterns (READ)
- `bridge/inbox/hopper/` - Message queue (READ/ARCHIVE)
- `~/Desktop/` - File organization (READ/WRITE)
- `bridge/queue/deferred/` - Deferred items (READ/WRITE)

## Escalation Triggers Detail

Notify Chat agent if:

- `pattern_match_rate < 60%` - Patterns not covering common cases
- `deferred_queue_size > 50` - Backlog growing
- `pattern_conflicts_detected` - Contradictory patterns found
- `same_decision_type_repeatedly_escalated` - Missing pattern opportunity
