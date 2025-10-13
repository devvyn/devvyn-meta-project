#!/bin/bash
#
# Activate Deferred Item
# Promotes item from defer queue to active routing
#
# Usage: ./activate-deferred.sh <item_id> [--route agent] [--priority HIGH]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
DEFER_ROOT="$BRIDGE_ROOT/defer-queue"
BRIDGE_SEND="$SCRIPT_DIR/bridge-send.sh"

ITEM_ID="${1:-}"
ROUTE=""
PRIORITY=""

# Parse options
shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --route) ROUTE="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [ -z "$ITEM_ID" ]; then
    echo "Usage: $0 <item_id> [--route agent] [--priority PRIORITY]" >&2
    exit 1
fi

log() {
    echo "[ACTIVATE-DEFERRED] $1"
}

# Find item in defer queue
ITEM_FILE=""
META_FILE=""

for category_dir in "$DEFER_ROOT"/*/; do
    if [ -f "$category_dir/${ITEM_ID}.md" ]; then
        ITEM_FILE="$category_dir/${ITEM_ID}.md"
        META_FILE="$category_dir/${ITEM_ID}.meta.json"
        break
    fi
done

if [ -z "$ITEM_FILE" ] || [ ! -f "$ITEM_FILE" ]; then
    log "ERROR: Item not found: $ITEM_ID"
    exit 1
fi

log "Found deferred item: $ITEM_ID"

# Load metadata
VALUE=$(jq -r '.classification.value' "$META_FILE")
CATEGORY=$(basename "$(dirname "$ITEM_FILE")")
TITLE=$(grep "^# " "$ITEM_FILE" 2>/dev/null | head -1 | sed 's/^# //' || echo "Deferred: $ITEM_ID")

log "  Category: $CATEGORY"
log "  Value: $VALUE"
log "  Title: $TITLE"

# Determine routing if not specified
if [ -z "$ROUTE" ]; then
    # Use classification to determine route
    ROUTING=$("$SCRIPT_DIR/classify-event.sh" "$ITEM_FILE" routing)
    ROUTE=$(echo "$ROUTING" | cut -d: -f1)
    [ -z "$PRIORITY" ] && PRIORITY=$(echo "$ROUTING" | cut -d: -f2)

    # If still routed to defer, default to human review
    if [[ "$ROUTE" =~ ^defer- ]]; then
        ROUTE="human"
        PRIORITY="${PRIORITY:-NORMAL}"
    fi
fi

# Default priority if not set
[ -z "$PRIORITY" ] && PRIORITY="NORMAL"

log "Activating → $ROUTE (priority: $PRIORITY)"

# Send via bridge
if [ -x "$BRIDGE_SEND" ]; then
    "$BRIDGE_SEND" defer "$ROUTE" "$PRIORITY" \
        "Activated from defer queue: $TITLE" \
        "$ITEM_FILE"

    log "✅ Message sent to $ROUTE"
else
    log "ERROR: bridge-send.sh not found or not executable"
    exit 1
fi

# Update metadata to mark as activated
TEMP_META=$(mktemp)
jq --arg timestamp "$(date -Iseconds)" \
   --arg route "$ROUTE" \
   --arg priority "$PRIORITY" \
   '.status = "activated" |
    .activated_at = $timestamp |
    .routed_to = $route |
    .routed_priority = $priority' \
   "$META_FILE" > "$TEMP_META"
mv "$TEMP_META" "$META_FILE"

# Move to activated directory (keep for reference)
ACTIVATED_DIR="$DEFER_ROOT/activated"
mkdir -p "$ACTIVATED_DIR"
mv "$ITEM_FILE" "$ACTIVATED_DIR/"
mv "$META_FILE" "$ACTIVATED_DIR/"

log "✅ Item activated and archived to: $ACTIVATED_DIR"

# Update index
INDEX_FILE="$DEFER_ROOT/index.json"
if [ -f "$INDEX_FILE" ]; then
    TEMP_INDEX=$(mktemp)
    jq --arg id "$ITEM_ID" \
       --arg timestamp "$(date -Iseconds)" \
       '.deferred_items = [.deferred_items[] | select(.id != $id)] |
        .last_updated = $timestamp' \
       "$INDEX_FILE" > "$TEMP_INDEX"
    mv "$TEMP_INDEX" "$INDEX_FILE"

    log "📋 Index updated: $(jq '.deferred_items | length' "$INDEX_FILE") items remaining"
fi

exit 0
