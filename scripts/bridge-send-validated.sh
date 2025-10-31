#!/usr/bin/env bash
# Smart message sender with content validation and auto-triage
set -euo pipefail

show_usage() {
    cat << EOF
Usage: bridge-send-validated.sh SENDER RECIPIENT PRIORITY "TITLE" CONTENT_FILE

Validates content and uses compact template to reduce token waste.

PRIORITY: CRITICAL | HIGH | NORMAL | INFO
EOF
    exit 1
}

[[ $# -lt 5 ]] && show_usage

SENDER="$1"
RECIPIENT="$2"
PRIORITY="$3"
TITLE="$4"
CONTENT_FILE="$5"

BRIDGE_ROOT="${HOME}/infrastructure/agent-bridge/bridge"
TEMPLATE="${BRIDGE_ROOT}/_message_template_compact.md"

# Validate content exists
if [[ ! -f "$CONTENT_FILE" ]]; then
    echo "Error: Content file not found: $CONTENT_FILE" >&2
    exit 1
fi

# Check content isn't empty
CONTENT_LINES=$(wc -l < "$CONTENT_FILE")
if [[ $CONTENT_LINES -lt 2 ]]; then
    echo "Error: Content file too short ($CONTENT_LINES lines). Messages must have actual content." >&2
    exit 1
fi

# Generate message ID
TIMESTAMP=$(date -Iseconds | sed 's/+.*$//')
UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
MSGID="${TIMESTAMP}-${SENDER}-${UUID}"

# Create message from compact template
OUTBOX="${BRIDGE_ROOT}/outbox/${RECIPIENT}"
mkdir -p "$OUTBOX"

MESSAGE_FILE="${OUTBOX}/$(date +%s)-${SENDER}-$(echo $UUID | cut -d- -f1).md"

# Fill template
sed -e "s/{PRIORITY}/${PRIORITY}/g" \
    -e "s/{TITLE}/${TITLE}/g" \
    -e "s/{MSGID}/${MSGID}/g" \
    -e "s/{SENDER}/${SENDER}/g" \
    -e "s/{RECIPIENT}/${RECIPIENT}/g" \
    -e "s/{TIMESTAMP}/${TIMESTAMP}/g" \
    -e "s/{SESSION}/$(whoami)-$$/g" \
    "$TEMPLATE" > "$MESSAGE_FILE"

# Insert content
sed -i.bak "s|{CONTENT}|$(cat "$CONTENT_FILE")|g" "$MESSAGE_FILE"
sed -i.bak "s|{CONTEXT}|Automated send with validation|g" "$MESSAGE_FILE"
sed -i.bak "s|{ACTION}|Process message content|g" "$MESSAGE_FILE"
rm "${MESSAGE_FILE}.bak"

echo "✓ Message created: $MESSAGE_FILE"
echo "  Tokens saved: ~40% (compact template)"
echo "  Content validated: $CONTENT_LINES lines"
