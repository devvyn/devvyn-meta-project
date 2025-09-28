#!/bin/bash
# Bridge Register Script v3.0 - Agent Registration and Session Management
# Manages agent lifecycle and prevents namespace collisions

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/devvyn-meta-project/bridge"

usage() {
    echo "Usage: $0 <action> <agent> [session_id]"
    echo ""
    echo "Actions:"
    echo "  register   - Register agent session"
    echo "  unregister - Unregister agent session"
    echo "  status     - Show agent status"
    echo "  list       - List all registered agents"
    echo ""
    echo "Arguments:"
    echo "  agent:      Agent namespace (chat, code, gpt, codex, human)"
    echo "  session_id: Optional session identifier"
    echo ""
    echo "Examples:"
    echo "  $0 register code session-123"
    echo "  $0 status chat"
    echo "  $0 list"
    exit 1
}

generate_session_id() {
    local agent="$1"
    local timestamp=$(date +%s)
    local user=$(whoami)
    echo "${agent}-${user}-${timestamp}"
}

register_agent() {
    local agent="$1"
    local session_id="${2:-$(generate_session_id "$agent")}"
    local timestamp=$(date -Iseconds)

    local registry_file="$BRIDGE_ROOT/registry/agents.json"
    local session_file="$BRIDGE_ROOT/registry/sessions/${session_id}.json"

    # Validate agent exists in registry
    if ! jq -e ".active_agents.$agent" "$registry_file" >/dev/null 2>&1; then
        echo "Error: Agent '$agent' not found in registry" >&2
        return 1
    fi

    # Update agent registry with session
    local temp_registry=$(mktemp)
    jq ".active_agents.$agent.session_id = \"$session_id\" | .active_agents.$agent.last_seen = \"$timestamp\" | .active_agents.$agent.status = \"active\"" "$registry_file" > "$temp_registry"
    mv "$temp_registry" "$registry_file"

    # Create session file
    cat > "$session_file" << EOF
{
  "session_id": "$session_id",
  "agent": "$agent",
  "registered": "$timestamp",
  "last_activity": "$timestamp",
  "status": "active",
  "messages_sent": 0,
  "messages_received": 0,
  "pid": $$,
  "user": "$(whoami)",
  "host": "$(hostname)"
}
EOF

    echo "✅ Agent '$agent' registered with session: $session_id"
    echo "📁 Session file: $session_file"
    return 0
}

unregister_agent() {
    local agent="$1"
    local timestamp=$(date -Iseconds)

    local registry_file="$BRIDGE_ROOT/registry/agents.json"

    # Get current session ID
    local session_id=$(jq -r ".active_agents.$agent.session_id" "$registry_file" 2>/dev/null)

    # Update agent registry
    local temp_registry=$(mktemp)
    jq ".active_agents.$agent.session_id = null | .active_agents.$agent.last_seen = \"$timestamp\" | .active_agents.$agent.status = \"inactive\"" "$registry_file" > "$temp_registry"
    mv "$temp_registry" "$registry_file"

    # Archive session file if it exists
    if [ "$session_id" != "null" ] && [ -f "$BRIDGE_ROOT/registry/sessions/${session_id}.json" ]; then
        local archive_dir="$BRIDGE_ROOT/registry/sessions/archive"
        mkdir -p "$archive_dir"
        mv "$BRIDGE_ROOT/registry/sessions/${session_id}.json" "$archive_dir/"
        echo "📦 Session archived: $archive_dir/${session_id}.json"
    fi

    echo "✅ Agent '$agent' unregistered"
    return 0
}

show_agent_status() {
    local agent="$1"
    local registry_file="$BRIDGE_ROOT/registry/agents.json"

    if ! jq -e ".active_agents.$agent" "$registry_file" >/dev/null 2>&1; then
        echo "Error: Agent '$agent' not found" >&2
        return 1
    fi

    echo "Agent Status: $agent"
    echo "===================="
    jq -r ".active_agents.$agent | \"Status: \\(.status)\\nNamespace: \\(.namespace)\\nLast Seen: \\(.last_seen)\\nSession ID: \\(.session_id // \"none\")\\nCapabilities: \\(.capabilities | join(\", \"))\"" "$registry_file"

    # Show session details if active
    local session_id=$(jq -r ".active_agents.$agent.session_id" "$registry_file")
    if [ "$session_id" != "null" ] && [ -f "$BRIDGE_ROOT/registry/sessions/${session_id}.json" ]; then
        echo ""
        echo "Session Details:"
        echo "================"
        jq -r ". | \"PID: \(.pid)\nUser: \(.user)\nHost: \(.host)\nMessages Sent: \(.messages_sent)\nMessages Received: \(.messages_received)\"" "$BRIDGE_ROOT/registry/sessions/${session_id}.json"
    fi

    return 0
}

list_agents() {
    local registry_file="$BRIDGE_ROOT/registry/agents.json"

    echo "Registered Agents:"
    echo "=================="
    echo ""

    jq -r '.active_agents | to_entries[] | "\(.key): \(.value.status) (\(.value.agent_type))"' "$registry_file" | while read line; do
        echo "🤖 $line"
    done

    echo ""
    echo "Active Sessions:"
    echo "================"

    local session_count=0
    for session_file in "$BRIDGE_ROOT/registry/sessions"/*.json; do
        if [ -f "$session_file" ] && [ "$(basename "$session_file")" != "*.json" ]; then
            local session_info=$(jq -r '"\(.agent): \(.session_id) (PID: \(.pid))"' "$session_file" 2>/dev/null)
            echo "🔗 $session_info"
            session_count=$((session_count + 1))
        fi
    done

    if [ $session_count -eq 0 ]; then
        echo "No active sessions"
    fi

    return 0
}

# Main execution
ACTION="$1"
AGENT="${2:-}"
SESSION_ID="${3:-}"

# Validate arguments based on action
case "$ACTION" in
    list)
        if [ $# -ne 1 ]; then
            usage
        fi
        ;;
    register|unregister|status)
        if [ $# -lt 2 ]; then
            usage
        fi
        ;;
    *)
        usage
        ;;
esac

case "$ACTION" in
    register)
        register_agent "$AGENT" "$SESSION_ID"
        ;;
    unregister)
        unregister_agent "$AGENT"
        ;;
    status)
        show_agent_status "$AGENT"
        ;;
    list)
        list_agents
        ;;
    *)
        echo "Error: Unknown action '$ACTION'" >&2
        usage
        ;;
esac