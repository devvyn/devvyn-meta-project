#!/bin/bash
# Bridge Derive State - Pure Function State Derivation
# Computes current state from immutable event log

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/devvyn-meta-project/bridge"
EVENTS_DIR="$BRIDGE_ROOT/events"

# Derive current state from all events
derive_state() {
    local event_count=$(find "$EVENTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    echo "{"
    echo "  \"derived_at\": \"$(date -Iseconds)\","
    echo "  \"total_events\": $event_count,"

    # Recent decisions (last 10)
    echo "  \"recent_decisions\": ["
    find "$EVENTS_DIR" -name "*-decision-*.md" -type f 2>/dev/null | sort -r | head -10 | while read event; do
        local title=$(grep "^# " "$event" | head -1 | sed 's/^# //')
        local timestamp=$(grep "^\*\*Timestamp\*\*:" "$event" | cut -d: -f2- | tr -d ' ')
        echo "    {\"title\": \"$title\", \"timestamp\": \"$timestamp\"},"
    done | sed '$ s/,$//'
    echo "  ],"

    # Recent patterns (last 10)
    echo "  \"recent_patterns\": ["
    find "$EVENTS_DIR" -name "*-pattern-*.md" -type f 2>/dev/null | sort -r | head -10 | while read event; do
        local title=$(grep "^# " "$event" | head -1 | sed 's/^# //')
        local timestamp=$(grep "^\*\*Timestamp\*\*:" "$event" | cut -d: -f2- | tr -d ' ')
        echo "    {\"title\": \"$title\", \"timestamp\": \"$timestamp\"},"
    done | sed '$ s/,$//'
    echo "  ],"

    # Agent activity (last 24h)
    echo "  \"recent_agent_activity\": ["
    find "$EVENTS_DIR" -name "*-agent-registration-*.md" -type f -mtime -1 2>/dev/null | sort -r | while read event; do
        local agent=$(grep "^\*\*Agent\*\*:" "$event" | cut -d: -f2- | tr -d ' ')
        local timestamp=$(grep "^\*\*Timestamp\*\*:" "$event" | cut -d: -f2- | tr -d ' ')
        echo "    {\"agent\": \"$agent\", \"timestamp\": \"$timestamp\"},"
    done | sed '$ s/,$//'
    echo "  ]"

    echo "}"
}

# Run derivation
if [ ! -d "$EVENTS_DIR" ]; then
    echo "{\"error\": \"Events directory not found\", \"path\": \"$EVENTS_DIR\"}"
    exit 1
fi

derive_state
