#!/bin/bash
#
# Defer Queue Manager
# Preserves valuable items for future action with context
#
# Usage: ./defer-item.sh <message_file> [--auto-classify]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
DEFER_ROOT="$BRIDGE_ROOT/defer-queue"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

MESSAGE_FILE="${1:-}"
AUTO_CLASSIFY=false

# Parse options
shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-classify) AUTO_CLASSIFY=true ;;
        *) ;;
    esac
    shift
done

if [ -z "$MESSAGE_FILE" ] || [ ! -f "$MESSAGE_FILE" ]; then
    echo "Usage: $0 <message_file> [--auto-classify]" >&2
    exit 1
fi

log() {
    echo "[DEFER-QUEUE] $1"
}

# Get classification
if [ "$AUTO_CLASSIFY" = true ]; then
    CLASSIFICATION=$("$SCRIPT_DIR/classify-event.sh" "$MESSAGE_FILE" json)
    VALUE=$(echo "$CLASSIFICATION" | jq -r '.classification.value')
    URGENCY=$(echo "$CLASSIFICATION" | jq -r '.classification.urgency')
    AUTHORITY=$(echo "$CLASSIFICATION" | jq -r '.classification.authority')
    CONFIDENCE=$(echo "$CLASSIFICATION" | jq -r '.classification.confidence')
    TRIGGERS=$(echo "$CLASSIFICATION" | jq -r '.triggers')
    ROUTING_DEST=$(echo "$CLASSIFICATION" | jq -r '.routing.destination')

    log "Auto-classified as: $VALUE/$URGENCY/$AUTHORITY (confidence: $CONFIDENCE)"

    # If routed to defer, proceed; otherwise route immediately
    if [[ ! "$ROUTING_DEST" =~ ^defer- ]]; then
        log "Item classified for immediate routing to: $ROUTING_DEST"
        log "Use bridge-send.sh to deliver immediately instead of deferring"
        exit 0
    fi

    CATEGORY=$(echo "$ROUTING_DEST" | sed 's/defer-//')
else
    # Manual classification (interactive)
    echo "Select value dimension:"
    echo "  1) strategic   - Framework evolution, cross-project patterns"
    echo "  2) tactical    - Implementation approaches, optimizations"
    echo "  3) operational - Routine tasks, maintenance"
    read -p "Choice [1-3]: " value_choice

    case $value_choice in
        1) VALUE="strategic"; CATEGORY="strategic" ;;
        2) VALUE="tactical"; CATEGORY="tactical" ;;
        3) VALUE="operational"; CATEGORY="operational" ;;
        *) VALUE="operational"; CATEGORY="operational" ;;
    esac

    URGENCY="eventual"
    AUTHORITY="unknown"
    CONFIDENCE=0.5
    TRIGGERS="[]"
fi

# Ensure category directory exists
CATEGORY_DIR="$DEFER_ROOT/$CATEGORY"
mkdir -p "$CATEGORY_DIR"

# Generate unique ID
DEFER_ID="${TIMESTAMP}-deferred-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -d- -f1)"
DEFER_FILE="$CATEGORY_DIR/$DEFER_ID.md"
METADATA_FILE="$CATEGORY_DIR/${DEFER_ID}.meta.json"

# Copy message content
cp "$MESSAGE_FILE" "$DEFER_FILE"

# Create metadata
cat > "$METADATA_FILE" <<EOF
{
  "id": "$DEFER_ID",
  "deferred_at": "$(date -Iseconds)",
  "classification": {
    "value": "$VALUE",
    "urgency": "$URGENCY",
    "authority": "$AUTHORITY",
    "confidence": $CONFIDENCE
  },
  "triggers": $TRIGGERS,
  "review_schedule": {
    "next_review": "$(date -v+7d -Iseconds 2>/dev/null || date -d '+7 days' -Iseconds)",
    "frequency": "weekly"
  },
  "status": "deferred",
  "source_file": "$(basename "$MESSAGE_FILE")"
}
EOF

log "✅ Item deferred: $DEFER_ID"
log "   Category: $CATEGORY"
log "   Location: $DEFER_FILE"
log "   Metadata: $METADATA_FILE"

# Update defer queue index
INDEX_FILE="$DEFER_ROOT/index.json"
if [ ! -f "$INDEX_FILE" ]; then
    echo '{"deferred_items": [], "last_updated": ""}' > "$INDEX_FILE"
fi

TEMP_INDEX=$(mktemp)
jq --arg id "$DEFER_ID" \
   --arg category "$CATEGORY" \
   --arg timestamp "$(date -Iseconds)" \
   '.deferred_items += [{"id": $id, "category": $category, "deferred_at": $timestamp}] |
    .last_updated = $timestamp' \
   "$INDEX_FILE" > "$TEMP_INDEX"
mv "$TEMP_INDEX" "$INDEX_FILE"

log "📋 Index updated: $(jq '.deferred_items | length' "$INDEX_FILE") total deferred items"

exit 0
