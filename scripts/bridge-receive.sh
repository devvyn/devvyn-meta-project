#!/bin/bash
# Bridge Receive Script v3.0 - FIFO Processing with Locks
# Atomic message processing prevents corruption and lost messages

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"
LOCK_TIMEOUT=30

usage() {
    echo "Usage: $0 <agent> [message_id]"
    echo ""
    echo "Arguments:"
    echo "  agent:      Agent namespace (chat, code, gpt, codex, human)"
    echo "  message_id: Optional specific message ID to process"
    echo ""
    echo "Behavior:"
    echo "  - Without message_id: Process next available message for agent"
    echo "  - With message_id: Process specific message if addressed to agent"
    echo ""
    echo "Example:"
    echo "  $0 code                           # Process next message for code agent"
    echo "  $0 chat 2025-09-27T17:30-uuid    # Process specific message"
    exit 1
}

validate_agent() {
    local agent="$1"
    if ! jq -e ".active_agents.$agent" "$BRIDGE_ROOT/registry/agents.json" >/dev/null 2>&1; then
        echo "Error: Agent '$agent' not registered" >&2
        return 1
    fi
}

acquire_lock() {
    local message_file="$1"
    local lock_file="${message_file}.lock"
    local timeout="$LOCK_TIMEOUT"

    while [ $timeout -gt 0 ]; do
        if (set -C; echo $$ > "$lock_file") 2>/dev/null; then
            echo "$lock_file"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
    done

    echo "Error: Could not acquire lock for $message_file after ${LOCK_TIMEOUT}s" >&2
    return 1
}

release_lock() {
    local lock_file="$1"
    if [ -f "$lock_file" ]; then
        rm -f "$lock_file"
    fi
}

get_next_message() {
    local agent="$1"
    local queue_dir="$BRIDGE_ROOT/queue/pending"

    if [ ! -d "$queue_dir" ]; then
        echo "No pending messages" >&2
        return 1
    fi

    # Find messages addressed to this agent (FIFO order)
    for message_file in $(ls "$queue_dir"/*.md 2>/dev/null | sort); do
        if [ -f "$message_file" ]; then
            local recipient=$(grep "^\\*\\*To\\*\\*:" "$message_file" | cut -d: -f2 | xargs)
            if [ "$recipient" = "$agent" ]; then
                echo "$message_file"
                return 0
            fi
        fi
    done

    echo "No pending messages for agent '$agent'" >&2
    return 1
}

find_message_by_id() {
    local message_id="$1"
    local queue_dir="$BRIDGE_ROOT/queue/pending"

    for message_file in $(ls "$queue_dir"/*.md 2>/dev/null); do
        if [[ "$(basename "$message_file")" == *"$message_id"* ]]; then
            echo "$message_file"
            return 0
        fi
    done

    echo "Message ID '$message_id' not found in pending queue" >&2
    return 1
}

process_message() {
    local agent="$1"
    local message_file="$2"

    # Acquire lock
    local lock_file
    lock_file=$(acquire_lock "$message_file") || return 1

    # Validate message is for this agent
    local recipient=$(grep "^\\*\\*To\\*\\*:" "$message_file" | cut -d: -f2 | xargs)
    if [ "$recipient" != "$agent" ]; then
        echo "Error: Message is addressed to '$recipient', not '$agent'" >&2
        release_lock "$lock_file"
        return 1
    fi

    local message_id=$(grep "^\\*\\*Message-ID\\*\\*:" "$message_file" | cut -d: -f2 | xargs)
    local sender=$(grep "^\\*\\*From\\*\\*:" "$message_file" | cut -d: -f2 | xargs)
    local priority=$(grep "^# \\[PRIORITY:" "$message_file" | sed 's/.*PRIORITY: *\\([^\\]]*\\).*/\\1/')

    echo "📨 Processing message: $message_id"
    echo "👤 From: $sender"
    echo "⚡ Priority: $priority"
    echo "📄 File: $(basename "$message_file")"

    # Move to processing directory
    local processing_dir="$BRIDGE_ROOT/queue/processing"
    local processing_file="$processing_dir/$(basename "$message_file")"

    mv "$message_file" "$processing_file"
    release_lock "$lock_file"

    # Display message content
    echo ""
    echo "📋 Message Content:"
    echo "=================="
    cat "$processing_file"
    echo "=================="
    echo ""

    # Archive processed message
    local archive_file="$BRIDGE_ROOT/archive/processed-$(basename "$message_file")"
    mv "$processing_file" "$archive_file"

    # Update processing statistics
    local stats_file="$BRIDGE_ROOT/registry/queue_stats.json"
    if [ -f "$stats_file" ]; then
        local temp_stats=$(mktemp)
        jq ".messages_processed += 1 | .last_processed_id = \"$message_id\" | .last_processed_agent = \"$agent\"" "$stats_file" > "$temp_stats" 2>/dev/null || {
            jq ". + {messages_processed: 1, last_processed_id: \"$message_id\", last_processed_agent: \"$agent\"}" "$stats_file" > "$temp_stats"
        }
        mv "$temp_stats" "$stats_file"
    fi

    echo "✅ Message processed and archived: $archive_file"
    return 0
}

# Main execution
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
fi

AGENT="$1"
MESSAGE_ID="${2:-}"

# Validation
validate_agent "$AGENT" || exit 1

# Find message to process
if [ -n "$MESSAGE_ID" ]; then
    MESSAGE_FILE=$(find_message_by_id "$MESSAGE_ID") || exit 1
else
    MESSAGE_FILE=$(get_next_message "$AGENT") || exit 1
fi

# Process the message
process_message "$AGENT" "$MESSAGE_FILE"
