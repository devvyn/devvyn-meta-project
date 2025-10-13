#!/bin/bash
#
# Session Report Generator
# Creates comprehensive end-of-session summary
#
# Usage: ./session-report.sh [session_id] [--auto]
#

set -euo pipefail

SESSION_ID="${1:-auto-$(date +%Y%m%d%H%M%S)}"
AUTO_MODE=false

if [[ "${2:-}" == "--auto" ]]; then
    AUTO_MODE=true
fi

TIMESTAMP=$(date +"%Y%m%d%H%M%S")
REPORT_FILE="$HOME/Desktop/${TIMESTAMP}-0600-session-report-${SESSION_ID}.md"
BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
META_ROOT="$HOME/devvyn-meta-project"

# Try to detect current branch/project
CURRENT_DIR=$(pwd)
if git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$CURRENT_DIR")
    PROJECT_NAME=$(basename "$GIT_ROOT")
else
    GIT_BRANCH="N/A"
    GIT_ROOT="$CURRENT_DIR"
    PROJECT_NAME="$(basename "$CURRENT_DIR")"
fi

# Initialize report
cat > "$REPORT_FILE" <<EOF
# Session Report: $SESSION_ID

**Generated**: $(date)
**Project**: $PROJECT_NAME
**Branch**: $GIT_BRANCH
**Duration**: Session active

---

## Session Summary

EOF

# Section 1: Git Activity
echo "### Git Activity" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if git rev-parse --git-dir > /dev/null 2>&1; then
    # Count commits since beginning of day
    COMMITS_TODAY=$(git log --since="today 00:00" --oneline 2>/dev/null | wc -l | tr -d ' ')

    if [ "$COMMITS_TODAY" -gt 0 ]; then
        echo "**Commits Today**: $COMMITS_TODAY" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        git log --since="today 00:00" --format="%h - %s (%ar)" 2>/dev/null >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"

        # File changes summary
        CHANGED_FILES=$(git diff --name-only --since="today 00:00" HEAD~${COMMITS_TODAY}..HEAD 2>/dev/null | wc -l | tr -d ' ')
        if [ "$CHANGED_FILES" -gt 0 ]; then
            echo "**Files Modified**: $CHANGED_FILES" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    else
        echo "No commits made today." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi

    # Working directory status
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "**Status**: Uncommitted changes present" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        git status --short 2>/dev/null >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
else
    echo "Not a git repository." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Section 2: Bridge Messages
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### Bridge Communication" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -d "$BRIDGE_ROOT" ]; then
    # Messages sent today
    OUTBOX_COUNT=$(find "$BRIDGE_ROOT/outbox" -name "*.md" -mtime 0 2>/dev/null | wc -l | tr -d ' ')
    echo "**Messages Sent**: $OUTBOX_COUNT" >> "$REPORT_FILE"

    # Messages received today
    INBOX_COUNT=$(find "$BRIDGE_ROOT/inbox" -name "*.md" -mtime 0 2>/dev/null | wc -l | tr -d ' ')
    echo "**Messages Received**: $INBOX_COUNT" >> "$REPORT_FILE"

    # Pending messages
    PENDING_COUNT=$(find "$BRIDGE_ROOT/queue/pending" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PENDING_COUNT" -gt 0 ]; then
        echo "**Queue Status**: $PENDING_COUNT pending" >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
else
    echo "Bridge system not accessible." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Section 3: Defer Queue Updates
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### Defer Queue" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -f "$BRIDGE_ROOT/defer-queue/index.json" ]; then
    DEFER_COUNT=$(jq '.deferred_items | length' "$BRIDGE_ROOT/defer-queue/index.json" 2>/dev/null || echo "0")
    echo "**Total Deferred**: $DEFER_COUNT items" >> "$REPORT_FILE"

    # Count by category
    STRATEGIC=$(find "$BRIDGE_ROOT/defer-queue/strategic" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    TACTICAL=$(find "$BRIDGE_ROOT/defer-queue/tactical" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    OPERATIONAL=$(find "$BRIDGE_ROOT/defer-queue/operational" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

    echo "- Strategic: $STRATEGIC" >> "$REPORT_FILE"
    echo "- Tactical: $TACTICAL" >> "$REPORT_FILE"
    echo "- Operational: $OPERATIONAL" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    echo "No deferred items." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Section 4: Investigation Findings
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### Investigation Activity" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Check for today's investigator reports
INVESTIGATOR_REPORTS=$(find ~/inbox/pending/investigator -name "*$(date +%Y%m%d)*" 2>/dev/null)
if [ -n "$INVESTIGATOR_REPORTS" ]; then
    echo "**Recent Reports**: $(echo "$INVESTIGATOR_REPORTS" | wc -l | tr -d ' ')" >> "$REPORT_FILE"
    echo "$INVESTIGATOR_REPORTS" | while read -r report; do
        echo "- $(basename "$report")" >> "$REPORT_FILE"
    done
    echo "" >> "$REPORT_FILE"
else
    echo "No investigation reports today." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Check investigator metrics
if [ -f "$META_ROOT/status/investigator-metrics.json" ]; then
    TOTAL_INVESTIGATIONS=$(jq -r '.investigations_total' "$META_ROOT/status/investigator-metrics.json" 2>/dev/null || echo "0")
    PATTERNS_EXTRACTED=$(jq -r '.outcomes.patterns_extracted' "$META_ROOT/status/investigator-metrics.json" 2>/dev/null || echo "0")

    echo "**Total Investigations**: $TOTAL_INVESTIGATIONS" >> "$REPORT_FILE"
    echo "**Patterns Extracted**: $PATTERNS_EXTRACTED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Section 5: Human Inbox Status
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### Human Inbox" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ -f "$HOME/inbox/status.json" ]; then
    UNREAD=$(jq '[.documents[] | select(.read == false)] | length' "$HOME/inbox/status.json" 2>/dev/null || echo "0")
    PENDING_RESPONSE=$(jq '[.documents[] | select(.read == true and .responded == false)] | length' "$HOME/inbox/status.json" 2>/dev/null || echo "0")
    COMPLETED=$(jq '[.documents[] | select(.responded == true)] | length' "$HOME/inbox/status.json" 2>/dev/null || echo "0")

    echo "- Unread: $UNREAD" >> "$REPORT_FILE"
    echo "- Pending Response: $PENDING_RESPONSE" >> "$REPORT_FILE"
    echo "- Completed: $COMPLETED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    echo "Inbox not initialized." >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Section 6: Recommended Next Actions
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Recommended Next Actions" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

RECOMMENDATIONS=()

# Check for uncommitted changes
if git rev-parse --git-dir > /dev/null 2>&1; then
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        RECOMMENDATIONS+=("- [ ] Review and commit pending changes")
    fi
fi

# Check for unread inbox
if [ "${UNREAD:-0}" -gt 0 ]; then
    RECOMMENDATIONS+=("- [ ] Review $UNREAD unread inbox item(s)")
fi

# Check for pending bridge messages
if [ "${PENDING_COUNT:-0}" -gt 0 ]; then
    RECOMMENDATIONS+=("- [ ] Process $PENDING_COUNT pending bridge message(s)")
fi

# Check for defer queue review
if [ "${DEFER_COUNT:-0}" -gt 3 ]; then
    RECOMMENDATIONS+=("- [ ] Review defer queue ($DEFER_COUNT items - consider weekly triage)")
fi

# Output recommendations
if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
    for rec in "${RECOMMENDATIONS[@]}"; do
        echo "$rec" >> "$REPORT_FILE"
    done
else
    echo "- [x] Session complete - no pending actions" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# Section 7: Session Continuity
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Session Continuity" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Next Session**: Resume work on \`$PROJECT_NAME\` branch \`$GIT_BRANCH\`" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Context Preserved**: Bridge messages, defer queue, investigator reports" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Footer
cat >> "$REPORT_FILE" <<EOF

---

**Report ID**: $SESSION_ID
**Generated**: $(date)
**Location**: $REPORT_FILE

EOF

echo "✅ Session report generated: $REPORT_FILE"

# Auto-open if not in auto mode
if [ "$AUTO_MODE" = false ]; then
    if command -v open >/dev/null 2>&1; then
        open "$REPORT_FILE"
    fi
fi

exit 0
