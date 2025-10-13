#!/bin/bash
#
# INVESTIGATOR Session Launcher
# Activates INVESTIGATOR agent with proper context loading
#
# This script transforms the dormant INVESTIGATOR agent into an active
# problem detection and resolution system.
#

set -euo pipefail

# Paths
BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
META_ROOT="$HOME/devvyn-meta-project"
SCRIPTS="$META_ROOT/scripts"
METRICS_FILE="$META_ROOT/status/investigator-metrics.json"
INVESTIGATION_QUEUE="$BRIDGE_ROOT/queue/investigations/active"
KNOWLEDGE_BASE="$META_ROOT/knowledge-base"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
REPORT_FILE="$HOME/Desktop/${TIMESTAMP}-0600-investigator-session-report.md"

# Parse arguments
DRY_RUN=false
VERBOSE=false
DAYS_BACK=7

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --days) DAYS_BACK="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

log() {
    echo "[INVESTIGATOR $(date +%H:%M:%S)] $1"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        log "$1"
    fi
}

# Initialize report
cat > "$REPORT_FILE" <<EOF
# INVESTIGATOR Session Report

**Session Start**: $(date)
**Days Analyzed**: $DAYS_BACK
**Mode**: $(if [[ "$DRY_RUN" == true ]]; then echo "DRY RUN"; else echo "ACTIVE"; fi)

---

## Session Activities

EOF

# Step 0: Scan Defer Queue for Value Extraction
log "Extracting value from deferred items..."

DEFER_ROOT="$BRIDGE_ROOT/defer-queue"
DEFER_INSIGHTS=0

if [[ -d "$DEFER_ROOT" ]]; then
    for category_dir in "$DEFER_ROOT"/*/; do
        category=$(basename "$category_dir")

        # Skip activated directory
        [[ "$category" == "activated" ]] && continue

        for meta_file in "$category_dir"/*.meta.json; do
            [[ -f "$meta_file" ]] || continue

            item_id=$(jq -r '.id' "$meta_file")
            value=$(jq -r '.classification.value' "$meta_file")
            content_file="${meta_file%.meta.json}.md"

            # Extract patterns from deferred content
            if grep -qiE "pattern|approach|optimization|architecture" "$content_file" 2>/dev/null; then
                ((DEFER_INSIGHTS++))
                log_verbose "Found insight in deferred item: $item_id ($value)"
            fi
        done
    done

    log "Extracted insights from $DEFER_INSIGHTS deferred items"

    cat >> "$REPORT_FILE" <<EOF
### Defer Queue Value Extraction

**Deferred Items Analyzed**: $DEFER_INSIGHTS
**Categories Scanned**: strategic, tactical, operational

Deferred items contribute to pattern detection and knowledge accumulation even while waiting for activation.

---

EOF
fi

# Step 1: Scan Event Log for Patterns
log "Scanning event log for patterns (last ${DAYS_BACK} days)..."

PATTERN_COUNT=0
ANOMALY_COUNT=0

EVENTS_DIR="$BRIDGE_ROOT/events"

if [[ -d "$EVENTS_DIR" ]]; then
    log_verbose "Querying events directly from $EVENTS_DIR..."

    # Get recent event files (last N days) - use BSD find explicitly
    EVENT_FILES=$(/usr/bin/find "$EVENTS_DIR" -name "*.md" -type f -mtime -${DAYS_BACK} ! -name "README.md" 2>/dev/null || echo "")

    if [[ -n "$EVENT_FILES" ]]; then
        EVENT_COUNT=$(echo "$EVENT_FILES" | wc -l | tr -d ' ')
        log "Found $EVENT_COUNT events in last $DAYS_BACK days"

        # Extract event types from filenames (format: TIMESTAMP-TYPE-UUID.md)
        EVENT_TYPES=$(echo "$EVENT_FILES" | xargs -n1 basename | sed -E 's/.*-([a-z-]+)-[0-9a-f-]+\.md$/\1/' | sort | uniq -c | sort -rn)

        cat >> "$REPORT_FILE" <<EOF
### Event Log Analysis

**Total Events**: $EVENT_COUNT

**Event Type Distribution**:
\`\`\`
$EVENT_TYPES
\`\`\`

EOF

        # Check for 3x repetition rule (pattern candidate)
        while read -r count type; do
            if [[ $count -ge 3 ]]; then
                PATTERN_COUNT=$((PATTERN_COUNT + 1))
                log "⚠️  Pattern detected: '$type' repeated ${count}x (pattern candidate)"

                cat >> "$REPORT_FILE" <<EOF
**Pattern Candidate #$PATTERN_COUNT**: Event type \`$type\` repeated ${count} times
- **Threshold**: 3+ repetitions triggers pattern detection
- **Recommendation**: Investigate if this represents automation opportunity
- **Action**: Review events to determine if abstraction possible

EOF
            fi
        done <<< "$EVENT_TYPES"
    else
        log "No events found in last $DAYS_BACK days"
        echo "**No events found** in analysis window." >> "$REPORT_FILE"
    fi
else
    log "⚠️  Events directory not found: $EVENTS_DIR"
    echo "**ERROR**: Events directory not available" >> "$REPORT_FILE"
fi

# Step 2: Check Active Investigations
log "Checking investigation queue..."

if [[ -d "$INVESTIGATION_QUEUE" ]]; then
    ACTIVE_COUNT=$(fd "\.md$" "$INVESTIGATION_QUEUE" --type f | wc -l | tr -d ' ')

    if [[ $ACTIVE_COUNT -gt 0 ]]; then
        log "Found $ACTIVE_COUNT active investigations"

        cat >> "$REPORT_FILE" <<EOF

### Active Investigations

**Count**: $ACTIVE_COUNT

EOF

        fd "\.md$" "$INVESTIGATION_QUEUE" --type f --exec bash -c '
            file={}
            age_hours=$(( ( $(date +%s) - $(stat -f %m "$file") ) / 3600 ))
            echo "- $(basename "$file"): ${age_hours}h old"
        ' >> "$REPORT_FILE"
    else
        log "No active investigations"
        echo "**No active investigations** in queue." >> "$REPORT_FILE"
    fi
else
    log "Investigation queue directory not found: $INVESTIGATION_QUEUE"
    echo "**Investigation queue not initialized**" >> "$REPORT_FILE"
fi

# Step 3: Process Pending Messages
log "Processing investigator inbox..."

INBOX_DIR="$BRIDGE_ROOT/inbox/investigator"
if [[ -d "$INBOX_DIR" ]]; then
    MESSAGE_COUNT=$(fd "\.md$" "$INBOX_DIR" --type f 2>/dev/null | grep -v "^_" | wc -l | tr -d ' ')

    if [[ $MESSAGE_COUNT -gt 0 ]]; then
        log "Found $MESSAGE_COUNT pending messages"

        cat >> "$REPORT_FILE" <<EOF

### Pending Messages

**Count**: $MESSAGE_COUNT

EOF

        fd "\.md$" "$INBOX_DIR" --type f 2>/dev/null | grep -v "^_" | while read -r msg; do
            basename "$msg" >> "$REPORT_FILE"
        done
    else
        log "No pending messages"
        echo "**No pending messages** for INVESTIGATOR." >> "$REPORT_FILE"
    fi
else
    log "Investigator inbox not found: $INBOX_DIR"
    mkdir -p "$INBOX_DIR"
    log "Created investigator inbox directory"
    echo "**Investigator inbox initialized**" >> "$REPORT_FILE"
fi

# Step 4: Review Pattern Library
log "Reviewing pattern library..."

PATTERNS_DIR="$KNOWLEDGE_BASE/patterns"
if [[ -d "$PATTERNS_DIR" ]]; then
    PATTERN_FILE_COUNT=$(fd "\.md$" "$PATTERNS_DIR" --type f | wc -l | tr -d ' ')
    log "Pattern library contains $PATTERN_FILE_COUNT documented patterns"

    cat >> "$REPORT_FILE" <<EOF

### Pattern Library

**Documented Patterns**: $PATTERN_FILE_COUNT

EOF
else
    log "Pattern library not found: $PATTERNS_DIR"
    echo "**Pattern library not initialized**" >> "$REPORT_FILE"
fi

# Step 5: Update Metrics
log "Updating INVESTIGATOR metrics..."

if [[ -f "$METRICS_FILE" ]]; then
    # Read current metrics
    TOTAL_INVESTIGATIONS=$(jq -r '.investigations_total' "$METRICS_FILE")

    # Increment by patterns detected this session
    NEW_TOTAL=$((TOTAL_INVESTIGATIONS + PATTERN_COUNT))

    if [[ "$DRY_RUN" == false ]]; then
        # Update metrics file
        TEMP_METRICS=$(mktemp)
        jq --arg timestamp "$(date -Iseconds)" \
           --arg total "$NEW_TOTAL" \
           --arg patterns "$PATTERN_COUNT" \
           '.last_updated = $timestamp |
            .investigations_total = ($total | tonumber) |
            .investigations_by_type.pattern += ($patterns | tonumber) |
            .investigations_by_status.active += ($patterns | tonumber)' \
           "$METRICS_FILE" > "$TEMP_METRICS"

        mv "$TEMP_METRICS" "$METRICS_FILE"
        log "✅ Metrics updated: $PATTERN_COUNT new pattern investigations"
    else
        log "[DRY RUN] Would update metrics: +$PATTERN_COUNT patterns"
    fi
else
    log "⚠️  Metrics file not found: $METRICS_FILE"
fi

# Step 6: Generate Summary
cat >> "$REPORT_FILE" <<EOF

---

## Session Summary

- **Patterns Detected**: $PATTERN_COUNT
- **Anomalies Flagged**: $ANOMALY_COUNT
- **Active Investigations**: ${ACTIVE_COUNT:-0}
- **Pending Messages**: ${MESSAGE_COUNT:-0}
- **Pattern Library Size**: ${PATTERN_FILE_COUNT:-0}

## Recommendations

EOF

if [[ $PATTERN_COUNT -gt 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF
1. **High Priority**: Review pattern candidates for automation opportunities
2. **Action**: Create investigation tasks for each pattern detected
3. **Framework**: Consider proposing framework improvements

EOF
fi

if [[ ${ACTIVE_COUNT:-0} -gt 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF
4. **Active Work**: Process stalled investigations (>7 days old)
5. **Resolution**: Complete or escalate blocked investigations

EOF
fi

cat >> "$REPORT_FILE" <<EOF

## Next Steps

1. Human review of this report
2. Approve pattern investigations for deeper analysis
3. Schedule next INVESTIGATOR session (recommended: daily)

---

**Session End**: $(date)
**Report Location**: $REPORT_FILE
**Metrics Updated**: $(if [[ "$DRY_RUN" == false ]]; then echo "YES"; else echo "NO (dry run)"; fi)
EOF

log "✅ INVESTIGATOR session complete"
log "📄 Report: $REPORT_FILE"

# Open report if not in dry run and in interactive session
if [[ "$DRY_RUN" == false ]] && [[ -n "${DISPLAY:-}" || -n "${SSH_TTY:-}" || -t 0 ]]; then
    open "$REPORT_FILE" 2>/dev/null || log "Note: Report saved but could not auto-open (non-interactive session)"
fi

exit 0
