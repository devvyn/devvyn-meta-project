#!/bin/bash
# Bridge Register Script v3.0 - Agent Registration and Session Management
# Manages agent lifecycle and prevents namespace collisions

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"

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

show_human_context() {
    local checkin_file="/Users/devvynmurphy/devvyn-meta-project/human-agency/daily-check-in.md"

    if [ ! -f "$checkin_file" ]; then
        return 0  # Silently skip if file doesn't exist
    fi

    echo ""
    echo "👤 Human Context (from daily check-in):"
    echo "========================================"

    # Extract energy level
    local energy=$(grep -A1 "^\*\*Current\*\*" "$checkin_file" | tail -1 | tr -d ' ')
    if [ -n "$energy" ] && [ "$energy" != "_" ]; then
        echo "Energy Level: $energy/10"
    fi

    # Extract what needs protecting
    local protecting=$(sed -n '/## What Needs Protecting/,/## What Wants Creating/p' "$checkin_file" | sed '1d;$d' | grep -v '^_$' | grep -v '^\[' | tr -d '\n')
    if [ -n "$protecting" ]; then
        echo "Needs Protection: $protecting"
    fi

    # Extract what wants creating
    local creating=$(sed -n '/## What Wants Creating/,/---/p' "$checkin_file" | sed '1d;$d' | grep -v '^_$' | grep -v '^\[' | tr -d '\n')
    if [ -n "$creating" ]; then
        echo "Wants Creating: $creating"
    fi

    echo ""
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

    # Show human context for awareness
    show_human_context

    # Auto-check and process inbox for pending messages
    local inbox_dir="$BRIDGE_ROOT/inbox/$agent"
    if [ -d "$inbox_dir" ]; then
        local pending_count=$(ls -1 "$inbox_dir"/*.md 2>/dev/null | grep -v "^_" | wc -l | tr -d ' ')
        if [ "$pending_count" -gt 0 ]; then
            echo ""
            echo "📬 Processing $pending_count pending message(s)..."

            # Auto-process messages (show summaries only)
            local scripts_dir="/Users/devvynmurphy/devvyn-meta-project/scripts"
            if [ -x "$scripts_dir/bridge-receive.sh" ]; then
                for i in $(seq 1 $pending_count); do
                    echo "   Message $i/$pending_count:"
                    "$scripts_dir/bridge-receive.sh" "$agent" 2>&1 | grep -E "^(From|Subject|Priority):" | sed 's/^/     /'
                done
                echo ""
                echo "✅ Inbox processed"
            else
                echo "   Manual processing required:"
                echo "   Run: ~/devvyn-meta-project/scripts/bridge-receive.sh $agent"
            fi
            echo ""
        fi
    fi

    # Show defer queue status
    local defer_root="$BRIDGE_ROOT/defer-queue"
    if [ -d "$defer_root" ] && [ -f "$defer_root/index.json" ]; then
        local defer_count=$(jq '.deferred_items | length' "$defer_root/index.json" 2>/dev/null || echo "0")
        if [ "$defer_count" -gt 0 ]; then
            echo "📋 Defer Queue: $defer_count item(s) awaiting future action"
            echo "   Review: ~/devvyn-meta-project/scripts/review-deferred.sh"
            echo ""
        fi
    fi

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
