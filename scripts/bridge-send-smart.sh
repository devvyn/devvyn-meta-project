#!/bin/bash
#
# Intelligent Bridge Send
# Automatically classifies and routes messages with defer queue support
#
# Usage:
#   ./bridge-send-smart.sh <sender> <recipient> <priority> "title" [content_file]
#   ./bridge-send-smart.sh --auto <sender> "title" [content_file]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_SEND="$SCRIPT_DIR/bridge-send.sh"
CLASSIFY="$SCRIPT_DIR/classify-event.sh"
DEFER="$SCRIPT_DIR/defer-item.sh"

AUTO_MODE=false
SENDER=""
RECIPIENT=""
PRIORITY=""
TITLE=""
CONTENT_FILE=""

# Parse arguments
if [[ "${1:-}" == "--auto" ]]; then
    AUTO_MODE=true
    SENDER="${2:-}"
    TITLE="${3:-}"
    CONTENT_FILE="${4:-}"
else
    SENDER="${1:-}"
    RECIPIENT="${2:-}"
    PRIORITY="${3:-}"
    TITLE="${4:-}"
    CONTENT_FILE="${5:-}"
fi

if [ -z "$SENDER" ] || [ -z "$TITLE" ]; then
    cat >&2 <<EOF
Usage:
  # Manual routing (classic bridge-send)
  $0 <sender> <recipient> <priority> "title" [content_file]

  # Automatic classification and routing
  $0 --auto <sender> "title" [content_file]

Examples:
  # Automatic - will classify and route intelligently
  $0 --auto code "Investigation findings" findings.md

  # Manual - traditional routing
  $0 code human HIGH "Approval needed" proposal.md
EOF
    exit 1
fi

log() {
    echo "[SMART-BRIDGE] $1"
}

# Create temp message file if content provided as file
TEMP_MSG=""
if [ -n "$CONTENT_FILE" ] && [ -f "$CONTENT_FILE" ]; then
    TEMP_MSG=$(mktemp)
    cat > "$TEMP_MSG" <<EOF
# $TITLE

$(cat "$CONTENT_FILE")
EOF
    MESSAGE_FILE="$TEMP_MSG"
else
    # Create minimal message for classification
    TEMP_MSG=$(mktemp)
    cat > "$TEMP_MSG" <<EOF
# $TITLE

Message content.
EOF
    MESSAGE_FILE="$TEMP_MSG"
fi

# Auto-classification mode
if [ "$AUTO_MODE" = true ]; then
    log "Auto-classifying message: $TITLE"

    # Get classification
    CLASSIFICATION=$("$CLASSIFY" "$MESSAGE_FILE" json)
    ROUTING_DEST=$(echo "$CLASSIFICATION" | jq -r '.routing.destination')
    ROUTING_PRIORITY=$(echo "$CLASSIFICATION" | jq -r '.routing.priority')
    CONFIDENCE=$(echo "$CLASSIFICATION" | jq -r '.classification.confidence')
    VALUE=$(echo "$CLASSIFICATION" | jq -r '.classification.value')
    URGENCY=$(echo "$CLASSIFICATION" | jq -r '.classification.urgency')

    log "Classification: $VALUE/$URGENCY (confidence: $CONFIDENCE)"
    log "Routing: $ROUTING_DEST @ $ROUTING_PRIORITY"

    # Handle defer routing
    if [[ "$ROUTING_DEST" =~ ^defer- ]]; then
        log "Message classified for deferral"

        # Defer the item
        "$DEFER" "$MESSAGE_FILE" --auto-classify

        log "✅ Message deferred successfully"
        [ -n "$TEMP_MSG" ] && rm -f "$TEMP_MSG"
        exit 0
    fi

    # Route immediately
    RECIPIENT="$ROUTING_DEST"
    PRIORITY="$ROUTING_PRIORITY"
fi

# Send via standard bridge
if [ -n "$CONTENT_FILE" ] && [ -f "$CONTENT_FILE" ]; then
    "$BRIDGE_SEND" "$SENDER" "$RECIPIENT" "$PRIORITY" "$TITLE" "$CONTENT_FILE"
else
    "$BRIDGE_SEND" "$SENDER" "$RECIPIENT" "$PRIORITY" "$TITLE"
fi

log "✅ Message sent to $RECIPIENT (priority: $PRIORITY)"

# Cleanup
[ -n "$TEMP_MSG" ] && rm -f "$TEMP_MSG"

exit 0
