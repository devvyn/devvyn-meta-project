# Timestamp Convention

**Status**: Canonical
**Updated**: 2025-10-09T14:26:06-06:00

---

## Standard Format

**ISO 8601 with system timezone offset**

```bash
date +"%Y-%m-%dT%H:%M:%S%z"
```

**Example**: `2025-10-09T14:26:06-0600`

**Note**: Uses system-configured timezone automatically (no hard-coded offsets)

---

## Rationale

### Why This Format

1. **ISO 8601 compliant**: Industry standard, sortable
2. **System timezone**: Automatically uses configured timezone (`%z`)
3. **Data integrity**: Correct local time, not UTC misreported as local
4. **Human preference**: Minimal natural language, clear semantics
5. **Portable**: Respects system configuration, no hard-coded offsets

### Why NOT Other Formats

**❌ Wrong**: `date -u +"%Y-%m-%dT%H:%M:%S%z"`
- Problem: `-u` generates UTC, then adds local timezone offset
- Result: Time is incorrectly offset (technical misreporting)

**❌ Avoid**: Hard-coded offsets like `date +"%Y-%m-%dT%H:%M:%S-06:00"`
- Problem: Breaks portability, ignores system configuration
- Result: Wrong if system moves or timezone changes

**❌ Avoid**: Natural language (e.g., "October 9, 2025 at 2:30 PM CST")
- Problem: Verbose, not sortable, parsing ambiguity
- Result: Harder to process programmatically

**✅ Alternative (UTC explicit)**: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Acceptable for portable/distributed systems
- Example: `2025-10-09T20:26:06Z`
- Trade-off: Loses local time immediacy

---

## Usage in System

### File Naming

**Bridge events**:
```bash
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")
FILE="bridge/events/${TIMESTAMP}-story-${UUID}.md"
```

**Example**: `2025-10-09T14:26:06-0600-story-f9066afb-91b8-4102-ab0f-626d82bf528c.md`

### Metadata Fields

**In JSON/YAML**:
```json
{
  "timestamp": "2025-10-09T14:26:06-0600",
  "created": "2025-10-09T14:26:06-0600",
  "modified": "2025-10-09T15:30:00-0600"
}
```

**In Markdown frontmatter**:
```markdown
**Timestamp**: 2025-10-09T14:26:06-0600
**Created**: 2025-10-09T14:26:06-0600
```

### Git Commits

Git already uses correct timezone-aware timestamps. No changes needed.

```bash
git log --format="%ai"  # 2025-10-09 14:26:06 -0600
```

---

## Implementation

### Shell Scripts

**Correct**:
```bash
#!/bin/bash
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")
echo "Processing at: $TIMESTAMP"
```

**Python** (uses system timezone):
```python
from datetime import datetime

# System-configured timezone
timestamp = datetime.now().astimezone().isoformat()
# Result: '2025-10-09T14:26:06-06:00' (or whatever system is configured)
```

**AppleScript** (for Notes.app):
```applescript
set now to current date
set timestamp to (year of now as string) & "-" & ¬
    text -2 thru -1 of ("0" & (month of now as integer)) & "-" & ¬
    text -2 thru -1 of ("0" & day of now) & "T" & ¬
    text -2 thru -1 of ("0" & hours of now) & ":" & ¬
    text -2 thru -1 of ("0" & minutes of now) & ":" & ¬
    text -2 thru -1 of ("0" & seconds of now) & "-06:00"
```

---

## Historical Context

**2025-10-09 Discovery**: Code agent was incorrectly using:
```bash
date -u +"%Y-%m-%dT%H:%M:%S-06:00"  # WRONG! Hard-coded AND wrong flag
```

Two problems:
1. `-u` generated UTC time
2. Hard-coded `-06:00` offset (not portable)

Result: Time was 6 hours off AND not respecting system configuration.

**Correction applied**:
- Use system timezone: `date +"%Y-%m-%dT%H:%M:%S%z"`
- Story event timestamp corrected
- Convention documented
- No hard-coded timezone offsets

---

## Timezone Notes

### Saskatchewan Specifics

**No Daylight Saving Time**: Saskatchewan observes CST year-round
- Winter: CST (UTC-6)
- Summer: Still CST (UTC-6) ← **Different from most of North America**

**System offset**: Should be configured as `-0600`

**Note**: System timezone configuration handles this automatically with `%z` format specifier.

### Cross-Timezone Considerations

If working with timestamps from other locations:
- **Prefer UTC** for distributed systems: `2025-10-09T20:26:06Z`
- **Convert to local** when displaying to humans
- **Always include explicit timezone** in stored data

---

## Validation

### Quick Test

```bash
# Correct command
date +"%Y-%m-%dT%H:%M:%S%z"
# Should show current local time with system-configured timezone

# Wrong command (for comparison)
date -u +"%Y-%m-%dT%H:%M:%S%z"
# Shows UTC time with local timezone offset (incorrect)
```

### Verification Checklist

When reviewing timestamps:
- ✅ Format matches ISO 8601
- ✅ Timezone offset present (e.g., `-0600`)
- ✅ Time matches local clock
- ✅ No `-u` flag used (unless intentionally UTC)
- ✅ Uses `%z` format (respects system timezone)

---

## Priority: Data Integrity

**Devvyn's preference**: ISO 8601, minimal natural language, explicit timezone

**System priority**: **Data integrity over convenience**

If there's ever a conflict between:
- Convenience vs. correctness → Choose correctness
- Brevity vs. clarity → Choose clarity
- Portability vs. accuracy → Choose accuracy

---

## References

**ISO 8601**: https://en.wikipedia.org/wiki/ISO_8601
**Saskatchewan timezone**: https://en.wikipedia.org/wiki/Time_in_Saskatchewan
**RFC 3339**: https://tools.ietf.org/html/rfc3339 (similar to ISO 8601)

---

## Canonical Command

```bash
date +"%Y-%m-%dT%H:%M:%S%z"
```

**Remember**: No `-u` flag. Local time. System timezone. No hard-coded offsets. Data integrity first.
