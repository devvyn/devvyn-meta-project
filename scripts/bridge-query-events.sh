#!/bin/bash
# Bridge Query Events - Query event log history
# Filters and retrieves events by type, agent, time range

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/devvyn-meta-project/bridge"
EVENTS_DIR="$BRIDGE_ROOT/events"

usage() {
    echo "Usage: $0 [--type TYPE] [--agent AGENT] [--since DURATION] [--limit N]"
    echo ""
    echo "Options:"
    echo "  --type TYPE      Filter by event type (decision, pattern, etc.)"
    echo "  --agent AGENT    Filter by agent (code, chat, human)"
    echo "  --since DURATION Events from last N hours/days (e.g., 24h, 7d)"
    echo "  --limit N        Limit results to N events"
    echo ""
    echo "Examples:"
    echo "  $0 --type decision --since 7d"
    echo "  $0 --agent code --limit 10"
    echo "  $0 --since 24h"
    exit 1
}

# Parse arguments
TYPE_FILTER=""
AGENT_FILTER=""
TIME_FILTER=""
LIMIT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE_FILTER="$2"
            shift 2
            ;;
        --agent)
            AGENT_FILTER="$2"
            shift 2
            ;;
        --since)
            TIME_FILTER="$2"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Build find command
FIND_CMD="find \"$EVENTS_DIR\" -name \"*.md\" -type f"

# Add time filter if specified
if [ -n "$TIME_FILTER" ]; then
    # Convert duration to find format (hours or days)
    if [[ "$TIME_FILTER" =~ ([0-9]+)h ]]; then
        HOURS="${BASH_REMATCH[1]}"
        FIND_CMD="$FIND_CMD -mmin -$((HOURS * 60))"
    elif [[ "$TIME_FILTER" =~ ([0-9]+)d ]]; then
        DAYS="${BASH_REMATCH[1]}"
        FIND_CMD="$FIND_CMD -mtime -$DAYS"
    fi
fi

# Execute find
EVENTS=$(eval "$FIND_CMD" 2>/dev/null | sort -r)

# Apply filters
if [ -n "$TYPE_FILTER" ]; then
    EVENTS=$(echo "$EVENTS" | grep "\-${TYPE_FILTER}\-")
fi

if [ -n "$AGENT_FILTER" ]; then
    FILTERED=""
    while IFS= read -r event; do
        if grep -q "^\*\*Agent\*\*: ${AGENT_FILTER}" "$event" 2>/dev/null; then
            FILTERED="${FILTERED}${event}\n"
        fi
    done <<< "$EVENTS"
    EVENTS=$(echo -e "$FILTERED")
fi

# Apply limit
if [ -n "$LIMIT" ]; then
    EVENTS=$(echo "$EVENTS" | head -"$LIMIT")
fi

# Output results
echo "Event Query Results"
echo "==================="
echo ""

if [ -z "$EVENTS" ]; then
    echo "No events found matching criteria"
    exit 0
fi

while IFS= read -r event; do
    if [ -f "$event" ]; then
        echo "Event: $(basename "$event")"
        grep "^# " "$event" | head -1
        grep "^\*\*Timestamp\*\*:" "$event"
        grep "^\*\*Agent\*\*:" "$event"
        echo ""
    fi
done <<< "$EVENTS"
