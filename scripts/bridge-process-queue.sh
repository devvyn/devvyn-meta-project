#!/bin/bash
#
# Bridge Queue Processor
# Delivers messages from queue/pending to inbox/[recipient]
#
# This was MISSING from bridge v3.0! Messages were being queued but never delivered.
#

set -euo pipefail

BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
QUEUE_DIR="$BRIDGE_ROOT/queue/pending"
PROCESSING_DIR="$BRIDGE_ROOT/queue/processing"

log() {
    echo "[BRIDGE-QUEUE $(date +%H:%M:%S)] $1"
}

# Process all pending messages
if [[ ! -d "$QUEUE_DIR" ]]; then
    log "Queue directory not found: $QUEUE_DIR"
    exit 1
fi

PROCESSED=0
FAILED=0

for message in "$QUEUE_DIR"/*.md; do
    if [[ ! -f "$message" ]]; then
        continue
    fi

    filename=$(basename "$message")
    log "Processing: $filename"

    # Extract recipient from message
    RECIPIENT=$(grep "^\*\*To\*\*:" "$message" | head -1 | sed 's/\*\*To\*\*: //' | tr -d ' ')

    if [[ -z "$RECIPIENT" ]]; then
        log "ERROR: No recipient found in $filename"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Move to processing
    PROCESSING_FILE="$PROCESSING_DIR/$filename"
    mv "$message" "$PROCESSING_FILE"

    # Deliver to recipient inbox
    INBOX_DIR="$BRIDGE_ROOT/inbox/$RECIPIENT"
    mkdir -p "$INBOX_DIR"

    INBOX_FILE="$INBOX_DIR/$filename"
    mv "$PROCESSING_FILE" "$INBOX_FILE"

    log "✅ Delivered to $RECIPIENT: $filename"
    PROCESSED=$((PROCESSED + 1))
done

log "Queue processing complete: $PROCESSED delivered, $FAILED failed"
exit 0
