#!/bin/bash
# Append Event Script - Immutable Event Log
# Creates append-only events with guaranteed uniqueness

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/devvyn-meta-project/bridge"
EVENTS_DIR="$BRIDGE_ROOT/events"

usage() {
    echo "Usage: $0 <type> <title> <agent> [content_file]"
    echo ""
    echo "Event Types:"
    echo "  decision, pattern, state-change, agent-registration,"
    echo "  message-sent, message-received, context-update"
    echo ""
    echo "Arguments:"
    echo "  type:         Event type (from list above)"
    echo "  title:        Brief event title"
    echo "  agent:        Agent creating event (code, chat, human)"
    echo "  content_file: Optional file with additional event data"
    echo ""
    echo "Example:"
    echo "  $0 decision 'Framework v2.3 Approved' human decision-data.md"
    exit 1
}

if [ $# -lt 3 ]; then
    usage
fi

EVENT_TYPE="$1"
EVENT_TITLE="$2"
EVENT_AGENT="$3"
CONTENT_FILE="${4:-}"

# Generate unique event ID
TIMESTAMP=$(date -Iseconds)
UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
EVENT_ID="${TIMESTAMP}-${EVENT_TYPE}-${UUID}"
EVENT_FILE="$EVENTS_DIR/${EVENT_ID}.md"

# Ensure events directory exists
mkdir -p "$EVENTS_DIR"

# Create immutable event file
cat > "$EVENT_FILE" << EOF
# ${EVENT_TYPE}: ${EVENT_TITLE}

**Event-ID**: ${EVENT_ID}
**Timestamp**: ${TIMESTAMP}
**Type**: ${EVENT_TYPE}
**Agent**: ${EVENT_AGENT}

## Event Data

EOF

# Append content from file if provided
if [ -n "$CONTENT_FILE" ] && [ -f "$CONTENT_FILE" ]; then
    cat "$CONTENT_FILE" >> "$EVENT_FILE"
else
    echo "(No additional data)" >> "$EVENT_FILE"
fi

cat >> "$EVENT_FILE" << EOF

## Context

Event created via append-event.sh

---

**Immutability**: This event is append-only. Never modify. Corrections are new events.
EOF

echo "✅ Event appended: $EVENT_ID"
echo "📁 Location: $EVENT_FILE"

echo "$EVENT_ID"  # Return event ID for chaining
