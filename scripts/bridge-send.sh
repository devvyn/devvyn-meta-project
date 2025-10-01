#!/bin/bash
# Bridge Send Script v3.0 - Atomic Message Creation
# Prevents race conditions and namespace collisions

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"
SCRIPT_DIR="$(dirname "$0")"

# Configuration
UUID_CMD="uuidgen"
TIMESTAMP_CMD="date -Iseconds"

usage() {
    echo "Usage: $0 <sender> <recipient> <priority> <title> [content_file]"
    echo ""
    echo "Arguments:"
    echo "  sender:     Agent namespace (chat, code, gpt, codex, human)"
    echo "  recipient:  Target agent namespace"
    echo "  priority:   CRITICAL|HIGH|NORMAL|INFO"
    echo "  title:      Message title (will be URL encoded)"
    echo "  content_file: Optional file containing message content"
    echo ""
    echo "Example:"
    echo "  $0 chat code HIGH \"Framework Update Required\" /tmp/message.md"
    exit 1
}

validate_agent() {
    local agent="$1"
    if ! jq -e ".active_agents.$agent" "$BRIDGE_ROOT/registry/agents.json" >/dev/null 2>&1; then
        echo "Error: Agent '$agent' not registered in bridge/registry/agents.json" >&2
        return 1
    fi
}

validate_priority() {
    local priority="$1"
    case "$priority" in
        CRITICAL|HIGH|NORMAL|INFO) return 0 ;;
        *) echo "Error: Invalid priority '$priority'. Must be CRITICAL|HIGH|NORMAL|INFO" >&2; return 1 ;;
    esac
}

generate_message_id() {
    local sender="$1"
    local timestamp=$($TIMESTAMP_CMD)
    local uuid=$($UUID_CMD | tr '[:upper:]' '[:lower:]')
    echo "${timestamp}-${sender}-${uuid}"
}

get_next_queue_number() {
    local queue_dir="$BRIDGE_ROOT/queue/pending"
    local last_num=0

    if [ -d "$queue_dir" ] && [ "$(ls -A "$queue_dir" 2>/dev/null)" ]; then
        last_num=$(ls "$queue_dir" | grep -E '^[0-9]+' | sed 's/-.*//' | sort -n | tail -1)
        last_num=${last_num:-0}
    fi

    printf "%03d" $((10#$last_num + 1))
}

create_message() {
    local sender="$1"
    local recipient="$2"
    local priority="$3"
    local title="$4"
    local content_file="${5:-}"

    local message_id=$(generate_message_id "$sender")
    local queue_number=$(get_next_queue_number)
    local timestamp=$($TIMESTAMP_CMD)

    # Create atomic temp file
    local temp_file=$(mktemp "$BRIDGE_ROOT/queue/.tmp.XXXXXX")
    local final_file="$BRIDGE_ROOT/queue/pending/${queue_number}-${message_id}.md"

    # Write message with required headers
    cat > "$temp_file" << EOF
# [PRIORITY: $priority] $title

**Message-ID**: $message_id
**Queue-Number**: $queue_number
**From**: $sender
**To**: $recipient
**Timestamp**: $timestamp
**Sender-Namespace**: ${sender}-
**Session**: $(whoami)-$(date +%s)

## Context

$(if [ -n "$content_file" ] && [ -f "$content_file" ]; then
    echo "Message content from: $content_file"
else
    echo "Direct message creation"
fi)

## Content

$(if [ -n "$content_file" ] && [ -f "$content_file" ]; then
    cat "$content_file"
else
    echo "[Message content - edit this file to add content]"
fi)

## Expected Action

[What the receiving agent should do with this information]

---

**Bridge v3.0 Message** - Created with collision-safe atomic operations
EOF

    # Atomic move to final location
    mv "$temp_file" "$final_file"

    # Update queue statistics
    local stats_file="$BRIDGE_ROOT/registry/queue_stats.json"
    if [ ! -f "$stats_file" ]; then
        echo '{"messages_sent": 0, "last_queue_number": 0}' > "$stats_file"
    fi

    # Update stats atomically
    local temp_stats=$(mktemp)
    jq ".messages_sent += 1 | .last_queue_number = $((10#$queue_number)) | .last_message_id = \"$message_id\"" "$stats_file" > "$temp_stats"
    mv "$temp_stats" "$stats_file"

    echo "✅ Message created: $final_file"
    echo "📋 Message ID: $message_id"
    echo "🔢 Queue Number: $queue_number"
    echo "📬 Recipient: $recipient"
    echo "⚡ Priority: $priority"

    return 0
}

# Main execution
if [ $# -lt 4 ] || [ $# -gt 5 ]; then
    usage
fi

SENDER="$1"
RECIPIENT="$2"
PRIORITY="$3"
TITLE="$4"
CONTENT_FILE="${5:-}"

# Validation
validate_agent "$SENDER" || exit 1
validate_agent "$RECIPIENT" || exit 1
validate_priority "$PRIORITY" || exit 1

if [ -n "$CONTENT_FILE" ] && [ ! -f "$CONTENT_FILE" ]; then
    echo "Error: Content file '$CONTENT_FILE' not found" >&2
    exit 1
fi

# Create message atomically
create_message "$SENDER" "$RECIPIENT" "$PRIORITY" "$TITLE" "$CONTENT_FILE"
