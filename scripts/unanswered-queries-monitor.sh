#!/bin/bash
# Unanswered Queries Monitor
#
# Watches for dropped threads and surfaces them proactively
# Integrates with INVESTIGATOR agent workflow
#
# Usage: ./unanswered-queries-monitor.sh [--verbose] [--dry-run]

set -euo pipefail

BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
META_ROOT="$HOME/devvyn-meta-project"
GITHUB_ROOT="$HOME/Documents/GitHub"
BRIDGE_SCRIPT="$META_ROOT/scripts/bridge-send.sh"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
REPORT_FILE="$HOME/Desktop/${TIMESTAMP}-0600-unanswered-queries-report.md"
TEMP_FILE="/tmp/unanswered-queries-$$.md"

VERBOSE=false
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose) VERBOSE=true ;;
        --dry-run) DRY_RUN=true ;;
    esac
done

log() {
    if [ "$VERBOSE" = true ]; then
        echo "[MONITOR] $1" >&2
    fi
}

# Calculate age in hours
age_in_hours() {
    local file="$1"
    local now=$(date +%s)
    local modified=$(stat -f %m "$file" 2>/dev/null || echo "$now")
    echo $(( (now - modified) / 3600 ))
}

# Initialize counters
critical_count=0
high_count=0
normal_count=0
total_items=0
human_inbox_unread=0

# Start report
{
    echo "# Unanswered Queries Report"
    echo ""
    echo "**Generated**: $(date -Iseconds)"
    echo "**Monitor Type**: INVESTIGATOR agent - Dropped thread detection"
    echo ""
} > "$TEMP_FILE"

log "Scanning bridge system for aging messages..."

# Check bridge inbox directories for aging messages
for agent_dir in "$BRIDGE_ROOT"/inbox/*/; do
    agent=$(basename "$agent_dir")

    # Skip if empty
    [ -d "$agent_dir" ] || continue

    # Find messages
    for msg in "$agent_dir"*.md; do
        [ -f "$msg" ] || continue
        [ "$(basename "$msg")" = "README.md" ] && continue

        age=$(age_in_hours "$msg")
        priority="UNKNOWN"

        # Extract priority from message
        if grep -q "PRIORITY: CRITICAL" "$msg" 2>/dev/null; then
            priority="CRITICAL"
        elif grep -q "PRIORITY: HIGH" "$msg" 2>/dev/null; then
            priority="HIGH"
        elif grep -q "PRIORITY: NORMAL" "$msg" 2>/dev/null; then
            priority="NORMAL"
        else
            priority="INFO"
        fi

        # Flag if exceeds threshold
        flag=false
        reason=""

        case $priority in
            CRITICAL)
                if [ $age -gt 24 ]; then
                    flag=true
                    reason="CRITICAL priority >24h old"
                    ((critical_count++))
                fi
                ;;
            HIGH)
                if [ $age -gt 48 ]; then
                    flag=true
                    reason="HIGH priority >48h old"
                    ((high_count++))
                fi
                ;;
            NORMAL)
                if [ $age -gt 168 ]; then  # 7 days
                    flag=true
                    reason="NORMAL priority >7d old"
                    ((normal_count++))
                fi
                ;;
        esac

        if [ "$flag" = true ]; then
            ((total_items++))

            title=$(grep "^# " "$msg" 2>/dev/null | head -1 | sed 's/^# //' || echo "Untitled")

            {
                echo "### [$priority] $agent: $title"
                echo ""
                echo "- **Age**: ${age}h ($reason)"
                echo "- **File**: $(basename "$msg")"
                echo "- **Path**: $msg"
                echo ""
            } >> "$TEMP_FILE"

            log "Flagged: $agent/$title (${age}h, $priority)"
        fi
    done
done

log "Scanning project review requests..."

# Check project CLAUDE.md files for unchecked review requests
for project_dir in "$GITHUB_ROOT"/*/; do
    project_name=$(basename "$project_dir")

    # Skip non-project directories
    [[ "$project_name" == ".claude" ]] && continue
    [[ "$project_name" =~ ^\. ]] && continue

    claude_md="$project_dir/CLAUDE.md"

    [ -f "$claude_md" ] || continue

    # Check for unchecked review requests
    if grep -q "## Review Requests" "$claude_md"; then
        pending=$(grep -A 30 "### Current Technical Questions" "$claude_md" 2>/dev/null | grep "^- \[ \]" | wc -l | tr -d ' \n')
        pending=${pending:-0}

        if [ "$pending" -gt 0 ]; then
            age=$(age_in_hours "$claude_md")

            # Consider pending if file modified >7 days ago
            if [ $age -gt 168 ]; then
                ((normal_count++))
                ((total_items++))

                {
                    echo "### [NORMAL] Project Review: $project_name"
                    echo ""
                    echo "- **Pending items**: $pending unchecked"
                    echo "- **Last modified**: ${age}h ago"
                    echo "- **File**: $claude_md"
                    echo ""
                } >> "$TEMP_FILE"

                log "Flagged: $project_name review requests ($pending pending, ${age}h)"
            fi
        fi
    fi
done

log "Checking defer queue for condition triggers..."

# Check defer queue for items ready to activate
DEFER_ROOT="$BRIDGE_ROOT/defer-queue"
DEFER_READY=0

if [[ -d "$DEFER_ROOT" ]]; then
    for category_dir in "$DEFER_ROOT"/*/; do
        category=$(basename "$category_dir")
        [[ "$category" == "activated" ]] && continue

        for meta_file in "$category_dir"/*.meta.json 2>/dev/null; do
            [[ -f "$meta_file" ]] || continue

            item_id=$(jq -r '.id' "$meta_file")
            next_review=$(jq -r '.review_schedule.next_review' "$meta_file")
            value=$(jq -r '.classification.value' "$meta_file")

            # Check if review date passed
            if [[ -n "$next_review" && "$next_review" != "null" ]]; then
                now=$(date +%s)
                review_timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$next_review" +%s 2>/dev/null || echo "$now")

                if [[ $review_timestamp -le $now ]]; then
                    ((DEFER_READY++))
                    ((normal_count++))
                    ((total_items++))

                    content_file="${meta_file%.meta.json}.md"
                    title=$(grep "^# " "$content_file" 2>/dev/null | head -1 | sed 's/^# //' || echo "Deferred item")

                    {
                        echo "### [NORMAL] Deferred Item Ready: $title"
                        echo ""
                        echo "- **ID**: $item_id"
                        echo "- **Category**: $category"
                        echo "- **Value**: $value"
                        echo "- **Scheduled review**: $next_review (overdue)"
                        echo "- **Action**: Review and activate: \`review-deferred.sh --category $category\`"
                        echo ""
                    } >> "$TEMP_FILE"

                    log "Deferred item ready for review: $category/$title"
                fi
            fi
        done
    done

    if [[ $DEFER_READY -gt 0 ]]; then
        log "Found $DEFER_READY deferred items ready for review"
    fi
fi

log "Checking human inbox for unprocessed reports..."

# Check human inbox status
INBOX_STATUS="$HOME/inbox/status.json"
if [[ -f "$INBOX_STATUS" ]]; then
    # Get unread count
    unread_count=$(jq '[.documents[] | select(.read == false)] | length' "$INBOX_STATUS" 2>/dev/null || echo "0")
    human_inbox_unread=$unread_count

    if [[ $unread_count -gt 0 ]]; then
        # Check for aging unread items
        oldest_unread=$(jq -r '[.documents[] | select(.read == false) | .moved_to_inbox] | sort | .[0]' "$INBOX_STATUS" 2>/dev/null)

        if [[ -n "$oldest_unread" && "$oldest_unread" != "null" ]]; then
            now=$(date +%s)
            oldest_timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$oldest_unread" +%s 2>/dev/null || echo "$now")
            age_hours=$(( (now - oldest_timestamp) / 3600 ))

            # Escalate based on age
            if [[ $age_hours -gt 168 ]]; then  # >7 days
                ((high_count++))
                ((total_items++))

                {
                    echo "### [HIGH] Human Inbox: $unread_count Unread Reports"
                    echo ""
                    echo "- **Unread documents**: $unread_count"
                    echo "- **Oldest unread**: ${age_hours}h ago (>7 days)"
                    echo "- **Location**: ~/inbox/pending/"
                    echo "- **Action**: Review and mark as read: \`inbox-status.sh summary\`"
                    echo ""
                } >> "$TEMP_FILE"

                log "FLAGGED: Human inbox has $unread_count unread ($age_hours hours old)"
            elif [[ $age_hours -gt 72 ]]; then  # >3 days
                ((normal_count++))
                ((total_items++))

                {
                    echo "### [NORMAL] Human Inbox: $unread_count Unread Reports"
                    echo ""
                    echo "- **Unread documents**: $unread_count"
                    echo "- **Oldest unread**: ${age_hours}h ago"
                    echo "- **Location**: ~/inbox/pending/"
                    echo ""
                } >> "$TEMP_FILE"

                log "Flagged: Human inbox has $unread_count unread ($age_hours hours)"
            fi
        fi
    else
        log "Human inbox clear (0 unread)"
    fi
else
    log "Human inbox not initialized (status.json not found)"
fi

# Build final report
if [ $total_items -eq 0 ]; then
    log "No unanswered queries found. System healthy."

    if [ "$VERBOSE" = true ]; then
        echo "✅ No unanswered queries detected"
        echo "   Bridge inboxes: Current"
        echo "   Project reviews: Current"
        echo "   Strategic decisions: Current"
    fi

    # Clean up temp file
    rm -f "$TEMP_FILE"

    exit 0
fi

# Generate final report with summary
{
    echo "# Unanswered Queries Report"
    echo ""
    echo "**Generated**: $(date -Iseconds)"
    echo "**Monitor Type**: INVESTIGATOR agent - Dropped thread detection"
    echo ""
    echo "## Summary"
    echo ""
    echo "**Total Items**: $total_items requiring attention"
    echo "**CRITICAL**: $critical_count (immediate action required)"
    echo "**HIGH**: $high_count (respond within 48h)"
    echo "**NORMAL**: $normal_count (respond within 7d)"
    echo ""
    echo "**Human Inbox**: $human_inbox_unread unread documents"
    echo ""
    echo "---"
    echo ""
    echo "## Flagged Items"
    echo ""

    # Append flagged items (skip header)
    tail -n +6 "$TEMP_FILE"

    echo ""
    echo "---"
    echo ""
    echo "## Recommended Actions"
    echo ""
    echo "### For Human"

    if [ $critical_count -gt 0 ] || [ $high_count -gt 0 ]; then
        echo "- **Immediate review needed**: $critical_count CRITICAL + $high_count HIGH items"
        echo "- Review and respond to flagged messages above"
    else
        echo "- No urgent items requiring immediate attention"
    fi

    echo ""
    echo "### For INVESTIGATOR Agent"
    echo "- Create investigations for pattern analysis:"
    echo "  - Why are messages aging without response?"
    echo "  - Are there systemic communication issues?"
    echo "  - Should routing patterns be adjusted?"
    echo ""
    echo "### For HOPPER Agent"
    echo "- Review flagged items for routing improvements"
    echo "- Update decision-patterns.md if patterns emerge"
    echo "- Consider defer queue for low-priority items"
    echo ""
    echo "---"
    echo ""
    echo "**Next Scan**: Run daily via cron or on-demand"
    echo "**Report Location**: $REPORT_FILE"
    echo "**Generated by**: Unanswered Queries Monitor v1.0"

} > "$REPORT_FILE"

# Clean up temp file
rm -f "$TEMP_FILE"

# Report results
echo "⚠️  Unanswered queries detected: $total_items items"
echo "   CRITICAL: $critical_count"
echo "   HIGH: $high_count"
echo "   NORMAL: $normal_count"
echo ""
echo "📄 Report saved to Desktop: $(basename "$REPORT_FILE")"

if [ "$DRY_RUN" = false ]; then
    # Open report for review
    if command -v open &> /dev/null; then
        open "$REPORT_FILE"
    fi

    # Send bridge message to investigator if critical/high items exist
    if [ $((critical_count + high_count)) -gt 0 ]; then
        if [ -f "$BRIDGE_SCRIPT" ]; then
            log "Sending bridge message to INVESTIGATOR agent..."

            "$BRIDGE_SCRIPT" monitor investigator HIGH \
                "Unanswered Queries Detected - ${total_items} items" \
                "$REPORT_FILE" 2>/dev/null || log "Bridge message failed (may not be critical)"
        fi
    fi
fi

exit 0
