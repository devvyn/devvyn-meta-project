#!/bin/bash
#
# Knowledge Extraction Engine
# Continuously extracts learnings from all collective activities
#
# Scans: Active messages, defer queue, investigations, archives
# Outputs: Updates to collective-memory.md
#

set -euo pipefail

KNOWLEDGE_BASE="$HOME/devvyn-meta-project/knowledge-base"
COLLECTIVE_MEMORY="$KNOWLEDGE_BASE/collective-memory.md"
BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

log() {
    echo "[KNOWLEDGE-EXTRACT] $1"
}

# Initialize counters
INSIGHTS_EXTRACTED=0
PATTERNS_FOUND=0
LEARNINGS_CAPTURED=0

log "Extracting knowledge from collective activities..."

# Create temp file for new insights
TEMP_INSIGHTS=$(mktemp)

# Extract from defer queue
log "Scanning defer queue..."
if [[ -d "$BRIDGE_ROOT/defer-queue" ]]; then
    for category_dir in "$BRIDGE_ROOT/defer-queue"/*/; do
        category=$(basename "$category_dir")
        [[ "$category" == "activated" ]] && continue

        for content_file in "$category_dir"/*.md 2>/dev/null; do
            [[ -f "$content_file" ]] || continue

            # Look for explicit insights (marked with strategic indicators)
            if grep -qiE "insight:|learning:|pattern:|key finding:" "$content_file"; then
                INSIGHT=$(grep -iE "insight:|learning:|pattern:|key finding:" "$content_file" | head -1)
                echo "- **From defer-$category**: $INSIGHT" >> "$TEMP_INSIGHTS"
                ((INSIGHTS_EXTRACTED++))
            fi
        done
    done
fi

# Extract from recent investigations
log "Scanning investigation reports..."
for report in "$HOME/Desktop/"*investigator-session-report*.md 2>/dev/null; do
    [[ -f "$report" ]] || continue

    # Extract patterns identified
    if grep -qE "Pattern detected|Pattern identified" "$report"; then
        PATTERN=$(grep -E "Pattern detected|Pattern identified" "$report" | head -1 | sed 's/^.*: //')
        echo "- **From investigation**: $PATTERN" >> "$TEMP_INSIGHTS"
        ((PATTERNS_FOUND++))
    fi

    # Only process recent reports (last 7 days)
    report_age=$(( ($(date +%s) - $(stat -f %m "$report")) / 86400 ))
    [[ $report_age -gt 7 ]] && break
done

# Extract from event log (recent strategic decisions)
log "Scanning event log..."
if [[ -d "$BRIDGE_ROOT/events" ]]; then
    for event_file in "$BRIDGE_ROOT/events"/*.json 2>/dev/null; do
        [[ -f "$event_file" ]] || continue

        event_type=$(jq -r '.event_type' "$event_file" 2>/dev/null || echo "")

        if [[ "$event_type" == "decision" ]]; then
            decision=$(jq -r '.description' "$event_file" 2>/dev/null || echo "")
            if [[ -n "$decision" ]]; then
                echo "- **Strategic decision**: $decision" >> "$TEMP_INSIGHTS"
                ((LEARNINGS_CAPTURED++))
            fi
        fi

        # Only recent events (last 7 days)
        event_age=$(( ($(date +%s) - $(stat -f %m "$event_file")) / 86400 ))
        [[ $event_age -gt 7 ]] && break
    done
done

# Update collective memory if insights found
if [[ $((INSIGHTS_EXTRACTED + PATTERNS_FOUND + LEARNINGS_CAPTURED)) -gt 0 ]]; then
    log "Extracted $INSIGHTS_EXTRACTED insights, $PATTERNS_FOUND patterns, $LEARNINGS_CAPTURED learnings"

    # Append to collective memory
    {
        echo ""
        echo "---"
        echo ""
        echo "## Recent Extractions ($(date -Iseconds))"
        echo ""
        cat "$TEMP_INSIGHTS"
        echo ""
    } >> "$COLLECTIVE_MEMORY"

    log "✅ Collective memory updated"
else
    log "No new insights to extract"
fi

# Cleanup
rm -f "$TEMP_INSIGHTS"

# Generate summary
TOTAL_INSIGHTS=$((INSIGHTS_EXTRACTED + PATTERNS_FOUND + LEARNINGS_CAPTURED))

cat <<EOF

╔════════════════════════════════════════╗
║     KNOWLEDGE EXTRACTION COMPLETE      ║
╚════════════════════════════════════════╝

  Insights:  $INSIGHTS_EXTRACTED
  Patterns:  $PATTERNS_FOUND
  Learnings: $LEARNINGS_CAPTURED
  ─────────────────
  Total:     $TOTAL_INSIGHTS

  Memory location: $COLLECTIVE_MEMORY

EOF

exit 0
