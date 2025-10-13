#!/bin/bash
# Bridge Send with Content-Addressed DAG Provenance
# Wraps bridge-send.sh with content-addressing and provenance tracking

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source content-dag primitives
source "$PROJECT_ROOT/lib/content-dag.sh"

# Set DAG storage in bridge
export CONTENT_DAG_OBJECTS="$BRIDGE_ROOT/dag/objects"
export CONTENT_DAG_DAG="$BRIDGE_ROOT/dag/nodes"

usage() {
    echo "Usage: $0 <sender> <recipient> <priority> <title> [content_file] [--reply-to <message_id>]"
    echo ""
    echo "Content-addressed bridge messaging with provenance tracking"
    echo ""
    echo "Arguments:"
    echo "  sender:     Agent namespace (chat, code, gpt, codex, human)"
    echo "  recipient:  Target agent namespace"
    echo "  priority:   CRITICAL|HIGH|NORMAL|INFO"
    echo "  title:      Message title"
    echo "  content_file: Optional file containing message content"
    echo "  --reply-to: Optional message ID this is replying to (for DAG provenance)"
    echo ""
    echo "Example:"
    echo "  $0 code chat HIGH \"Analysis Complete\" /tmp/analysis.md --reply-to 2024-10-08T12:00:00-06:00-chat-abc123"
    exit 1
}

# Parse arguments including optional --reply-to
SENDER="${1:-}"
RECIPIENT="${2:-}"
PRIORITY="${3:-}"
TITLE="${4:-}"
CONTENT_FILE="${5:-}"
REPLY_TO=""

shift 4 || usage

if [[ $# -gt 0 ]] && [[ "$1" != "--reply-to" ]]; then
    CONTENT_FILE="$1"
    shift
fi

if [[ $# -gt 0 ]] && [[ "$1" == "--reply-to" ]]; then
    shift
    REPLY_TO="${1:-}"
    shift || true
fi

if [[ -z "$SENDER" ]] || [[ -z "$RECIPIENT" ]] || [[ -z "$PRIORITY" ]] || [[ -z "$TITLE" ]]; then
    usage
fi

# Create message using original bridge-send.sh
ORIGINAL_SEND="$SCRIPT_DIR/bridge-send.sh"
if [[ ! -x "$ORIGINAL_SEND" ]]; then
    echo "Error: bridge-send.sh not found at $ORIGINAL_SEND" >&2
    exit 1
fi

# Call original bridge-send
if [[ -n "$CONTENT_FILE" ]]; then
    message_output=$("$ORIGINAL_SEND" "$SENDER" "$RECIPIENT" "$PRIORITY" "$TITLE" "$CONTENT_FILE")
else
    message_output=$("$ORIGINAL_SEND" "$SENDER" "$RECIPIENT" "$PRIORITY" "$TITLE")
fi

echo "$message_output"

# Extract message ID from output
message_id=$(echo "$message_output" | grep "Message ID:" | sed 's/.*Message ID: //')

if [[ -z "$message_id" ]]; then
    echo "Warning: Could not extract message ID from bridge-send output" >&2
    exit 0
fi

# Content-address the message content if provided
if [[ -n "$CONTENT_FILE" ]] && [[ -f "$CONTENT_FILE" ]]; then
    echo ""
    echo "📦 Content-addressing message..."

    # Store content in DAG
    content_hash=$(store_object "$CONTENT_FILE")
    echo "   Content hash: $content_hash"

    # Build DAG node
    inputs_json="[]"
    metadata="{\"type\": \"bridge_message\", \"sender\": \"$SENDER\", \"recipient\": \"$RECIPIENT\", \"priority\": \"$PRIORITY\", \"title\": \"$TITLE\", \"message_id\": \"$message_id\"}"

    # If this is a reply, add parent to inputs
    if [[ -n "$REPLY_TO" ]]; then
        # Look up parent message's DAG node
        parent_dag_file="$CONTENT_DAG_DAG/message-${REPLY_TO}.json"
        if [[ -f "$parent_dag_file" ]]; then
            parent_hash=$(basename "$parent_dag_file" .json | sed 's/^message-//')
            inputs_json="[\"$parent_hash\"]"
            metadata=$(echo "$metadata" | jq --arg reply "$REPLY_TO" '. + {reply_to: $reply}')
            echo "   Reply to: $REPLY_TO"
        else
            echo "   Warning: Parent message DAG node not found: $REPLY_TO" >&2
        fi
    fi

    # Create DAG node
    node_hash=$(create_dag_node "$content_hash" "$inputs_json" "$metadata")

    # Create symbolic link for easy lookup by message ID
    ln -sf "$CONTENT_DAG_DAG/$node_hash.json" "$CONTENT_DAG_DAG/message-${message_id}.json"

    echo "   DAG node: $node_hash"
    echo ""
    echo "🔗 Provenance recorded"
    echo "   Query: ./scripts/bridge-query-provenance.sh $message_id"
fi
