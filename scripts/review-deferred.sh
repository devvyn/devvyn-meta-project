#!/bin/bash
#
# Review Deferred Items
# Re-surface items based on time, conditions, or category
#
# Usage:
#   ./review-deferred.sh --category strategic
#   ./review-deferred.sh --older-than 30d
#   ./review-deferred.sh --trigger "project-started"
#

set -euo pipefail

BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
DEFER_ROOT="$BRIDGE_ROOT/defer-queue"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
REPORT_FILE="$HOME/Desktop/${TIMESTAMP}-0600-deferred-items-review.md"

CATEGORY=""
AGE_THRESHOLD=""
TRIGGER=""
ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --category) CATEGORY="$2"; shift 2 ;;
        --older-than) AGE_THRESHOLD="$2"; shift 2 ;;
        --trigger) TRIGGER="$2"; shift 2 ;;
        --all) ALL=true; shift ;;
        *) shift ;;
    esac
done

log() {
    echo "[REVIEW-DEFERRED] $1"
}

# Calculate age in days
age_in_days() {
    local file="$1"
    local now=$(date +%s)
    local modified=$(stat -f %m "$file" 2>/dev/null || echo "$now")
    echo $(( (now - modified) / 86400 ))
}

# Parse age threshold (e.g., "30d" -> 30)
parse_age() {
    echo "$1" | sed 's/d$//'
}

REVIEW_COUNT=0
ITEMS_TO_REVIEW=()

# Start report
{
    echo "# Deferred Items Review"
    echo ""
    echo "**Generated**: $(date -Iseconds)"
    echo "**Review Type**: "
    [ -n "$CATEGORY" ] && echo "- Category: $CATEGORY"
    [ -n "$AGE_THRESHOLD" ] && echo "- Older than: $AGE_THRESHOLD"
    [ -n "$TRIGGER" ] && echo "- Trigger condition: $TRIGGER"
    [ "$ALL" = true ] && echo "- All deferred items"
    echo ""
} > "$REPORT_FILE"

# Scan defer queue
for category_dir in "$DEFER_ROOT"/*/; do
    category=$(basename "$category_dir")

    # Filter by category if specified
    if [ -n "$CATEGORY" ] && [ "$category" != "$CATEGORY" ]; then
        continue
    fi

    for meta_file in "$category_dir"/*.meta.json; do
        [ -f "$meta_file" ] || continue

        item_id=$(jq -r '.id' "$meta_file")
        deferred_at=$(jq -r '.deferred_at' "$meta_file")
        value=$(jq -r '.classification.value' "$meta_file")
        urgency=$(jq -r '.classification.urgency' "$meta_file")
        triggers=$(jq -r '.triggers[]' "$meta_file" 2>/dev/null || echo "")

        content_file="${meta_file%.meta.json}.md"
        title=$(grep "^# " "$content_file" 2>/dev/null | head -1 | sed 's/^# //' || echo "Untitled")

        # Apply filters
        include_item=false

        # Age filter
        if [ -n "$AGE_THRESHOLD" ]; then
            threshold_days=$(parse_age "$AGE_THRESHOLD")
            item_age=$(age_in_days "$meta_file")

            if [ "$item_age" -ge "$threshold_days" ]; then
                include_item=true
            fi
        fi

        # Trigger filter
        if [ -n "$TRIGGER" ]; then
            if echo "$triggers" | grep -qi "$TRIGGER"; then
                include_item=true
            fi
        fi

        # All items
        if [ "$ALL" = true ]; then
            include_item=true
        fi

        # Category filter already applied above
        if [ -z "$AGE_THRESHOLD" ] && [ -z "$TRIGGER" ] && [ "$ALL" = false ] && [ -n "$CATEGORY" ]; then
            include_item=true
        fi

        if [ "$include_item" = true ]; then
            ((REVIEW_COUNT++))

            {
                echo "## [$value] $title"
                echo ""
                echo "- **ID**: $item_id"
                echo "- **Category**: $category"
                echo "- **Deferred**: $deferred_at"
                echo "- **Urgency**: $urgency"

                if [ -n "$triggers" ]; then
                    echo "- **Triggers**: $triggers"
                fi

                echo "- **File**: $content_file"
                echo ""
                echo "### Content Preview"
                echo "\`\`\`"
                head -20 "$content_file" | tail -15
                echo "\`\`\`"
                echo ""
                echo "### Actions"
                echo "- **Activate**: \`~/devvyn-meta-project/scripts/activate-deferred.sh $item_id\`"
                echo "- **Re-defer**: Update metadata with new review date"
                echo "- **Archive**: Mark as no longer relevant"
                echo ""
                echo "---"
                echo ""
            } >> "$REPORT_FILE"

            ITEMS_TO_REVIEW+=("$item_id")
            log "Found: $category/$title"
        fi
    done
done

# Complete report
{
    echo ""
    echo "## Summary"
    echo ""
    echo "**Total Items for Review**: $REVIEW_COUNT"
    echo ""

    if [ $REVIEW_COUNT -eq 0 ]; then
        echo "No items match review criteria."
    else
        echo "### Recommended Process"
        echo ""
        echo "1. **Review each item above**"
        echo "2. **Decide action**:"
        echo "   - Activate if now relevant: \`activate-deferred.sh <id>\`"
        echo "   - Re-defer if still not ready: Update metadata"
        echo "   - Archive if no longer valuable: Move to archive"
        echo ""
        echo "3. **Activate items** ready for action:"
        echo "\`\`\`bash"
        for item_id in "${ITEMS_TO_REVIEW[@]}"; do
            echo "~/devvyn-meta-project/scripts/activate-deferred.sh $item_id"
        done
        echo "\`\`\`"
    fi

    echo ""
    echo "---"
    echo ""
    echo "**Report Location**: $REPORT_FILE"
    echo "**Next Review**: Schedule based on value (weekly for strategic, monthly for tactical)"
} >> "$REPORT_FILE"

# Output summary
if [ $REVIEW_COUNT -eq 0 ]; then
    echo "✅ No deferred items match review criteria"
    rm -f "$REPORT_FILE"
else
    echo "📋 Deferred items review: $REVIEW_COUNT items ready"
    echo "📄 Report saved to Desktop: $(basename "$REPORT_FILE")"

    # Open report
    if command -v open &> /dev/null; then
        open "$REPORT_FILE"
    fi
fi

exit 0
