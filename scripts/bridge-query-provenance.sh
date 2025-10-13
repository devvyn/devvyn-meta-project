#!/bin/bash
# Query message provenance from content-addressed DAG

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"

# Source content-dag primitives
source "$PROJECT_ROOT/lib/content-dag.sh"

# Set DAG storage
export CONTENT_DAG_OBJECTS="$BRIDGE_ROOT/dag/objects"
export CONTENT_DAG_DAG="$BRIDGE_ROOT/dag/nodes"

usage() {
    echo "Usage: $0 <message_id> [--full]"
    echo ""
    echo "Query provenance for a bridge message"
    echo ""
    echo "Arguments:"
    echo "  message_id: Message ID to query"
    echo "  --full:     Show full provenance tree (default: show immediate inputs)"
    echo ""
    echo "Example:"
    echo "  $0 2024-10-08T12:00:00-06:00-chat-abc123"
    echo "  $0 2024-10-08T12:00:00-06:00-chat-abc123 --full"
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

MESSAGE_ID="$1"
FULL_TRACE="${2:-}"

# Look up DAG node by message ID
dag_file="$CONTENT_DAG_DAG/message-${MESSAGE_ID}.json"

if [[ ! -f "$dag_file" ]]; then
    echo "Error: No DAG node found for message $MESSAGE_ID" >&2
    echo "This message may not have been sent with bridge-send-dag.sh" >&2
    exit 1
fi

# Extract node hash
node_hash=$(basename "$(readlink -f "$dag_file")" .json)

echo "📋 Message Provenance: $MESSAGE_ID"
echo ""

# Show node metadata
echo "🔍 Metadata:"
jq -r 'to_entries[] | "   \(.key): \(.value)"' "$dag_file"
echo ""

# Show content
content_hash=$(jq -r '.hash' "$dag_file")
echo "📦 Content Hash: $content_hash"
echo ""

# Show provenance
if [[ "$FULL_TRACE" == "--full" ]]; then
    echo "🌳 Full Provenance Tree:"
    trace_provenance "$node_hash"
else
    echo "⬆️  Immediate Inputs:"
    inputs=$(jq -r '.inputs[]' "$dag_file" 2>/dev/null || echo "")
    if [[ -z "$inputs" ]]; then
        echo "   (root message - no inputs)"
    else
        while IFS= read -r input_hash; do
            input_node="$CONTENT_DAG_DAG/$input_hash.json"
            if [[ -f "$input_node" ]]; then
                input_msg_id=$(jq -r '.metadata.message_id // "unknown"' "$input_node")
                input_title=$(jq -r '.metadata.title // "untitled"' "$input_node")
                input_timestamp=$(jq -r '.timestamp' "$input_node")
                echo "   - $input_msg_id"
                echo "     \"$input_title\" at $input_timestamp"
            else
                echo "   - $input_hash (metadata not found)"
            fi
        done <<< "$inputs"
    fi
fi

echo ""
echo "💡 Tips:"
echo "   View content: ./scripts/bridge-query-provenance.sh $MESSAGE_ID --content"
echo "   Full tree: ./scripts/bridge-query-provenance.sh $MESSAGE_ID --full"
