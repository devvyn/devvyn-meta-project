#!/bin/bash
#
# Event Classification Engine
# Analyzes content to determine value, urgency, and authority dimensions
#
# Returns: JSON classification for routing decisions
#

set -euo pipefail

EVENT_FILE="${1:-}"
OUTPUT_FORMAT="${2:-json}"  # json or routing

if [ -z "$EVENT_FILE" ] || [ ! -f "$EVENT_FILE" ]; then
    echo "Usage: $0 <event_file> [output_format]" >&2
    exit 1
fi

# Extract key signals from content
CONTENT=$(cat "$EVENT_FILE")
TITLE=$(grep "^# " "$EVENT_FILE" 2>/dev/null | head -1 | sed 's/^# //' || echo "Untitled")
PRIORITY=$(grep -i "PRIORITY:" "$EVENT_FILE" 2>/dev/null | head -1 | sed 's/.*PRIORITY: *//' || echo "NORMAL")

# Initialize classification dimensions
VALUE="operational"
URGENCY="eventual"
AUTHORITY="agent-capable"
CONFIDENCE=0.5
TRIGGERS=()

classify_value() {
    # Strategic indicators
    if echo "$CONTENT" | grep -qiE "framework|architecture|cross-project|portfolio|strategic|vision|long-term"; then
        VALUE="strategic"
        CONFIDENCE=0.8
        return
    fi

    # Tactical indicators
    if echo "$CONTENT" | grep -qiE "implementation|optimization|refactor|algorithm|performance|pattern|approach"; then
        VALUE="tactical"
        CONFIDENCE=0.7
        return
    fi

    # Operational by default
    VALUE="operational"
    CONFIDENCE=0.6
}

classify_urgency() {
    # Check explicit priority first
    case "$PRIORITY" in
        CRITICAL)
            URGENCY="immediate"
            CONFIDENCE=$(echo "$CONFIDENCE + 0.1" | bc)
            ;;
        HIGH)
            URGENCY="soon"
            CONFIDENCE=$(echo "$CONFIDENCE + 0.1" | bc)
            ;;
        NORMAL)
            URGENCY="eventual"
            ;;
        INFO)
            URGENCY="conditional"
            ;;
    esac

    # Check for urgency language
    if echo "$CONTENT" | grep -qiE "urgent|asap|immediately|critical|blocking|broken|failing"; then
        URGENCY="immediate"
        CONFIDENCE=$(echo "$CONFIDENCE + 0.15" | bc)
    elif echo "$CONTENT" | grep -qiE "soon|this week|upcoming|deadline"; then
        URGENCY="soon"
        CONFIDENCE=$(echo "$CONFIDENCE + 0.1" | bc)
    elif echo "$CONTENT" | grep -qiE "when ready|future|eventually|consider|explore"; then
        URGENCY="eventual"
    fi

    # Check for conditional language
    if echo "$CONTENT" | grep -qiE "when|if|after|once|depends on|waiting for"; then
        URGENCY="conditional"

        # Extract trigger conditions
        while IFS= read -r line; do
            if echo "$line" | grep -qiE "when|if|after|once"; then
                TRIGGER=$(echo "$line" | sed 's/.*\(when\|if\|after\|once\) //' | sed 's/[,.].*$//')
                TRIGGERS+=("$TRIGGER")
            fi
        done < "$EVENT_FILE"
    fi
}

classify_authority() {
    # Human-only indicators
    if echo "$CONTENT" | grep -qiE "decision needed|approve|business|stakeholder|domain expertise|judgment call|ethical|political|strategic decision"; then
        AUTHORITY="human-only"
        CONFIDENCE=$(echo "$CONFIDENCE + 0.15" | bc)
        return
    fi

    # Investigative indicators
    if echo "$CONTENT" | grep -qiE "pattern|investigate|analyze|root cause|why|anomaly|correlation"; then
        AUTHORITY="investigative"
        CONFIDENCE=$(echo "$CONFIDENCE + 0.1" | bc)
        return
    fi

    # Collaborative indicators
    if echo "$CONTENT" | grep -qiE "coordinate|discuss|review together|feedback|joint"; then
        AUTHORITY="collaborative"
        CONFIDENCE=$(echo "$CONFIDENCE + 0.1" | bc)
        return
    fi

    # Agent-capable by default (technical/routine work)
    if echo "$CONTENT" | grep -qiE "implement|code|script|automate|test|deploy|refactor"; then
        AUTHORITY="agent-capable"
        CONFIDENCE=$(echo "$CONFIDENCE + 0.05" | bc)
    fi
}

determine_routing() {
    # Routing decision based on classification matrix
    local route=""
    local priority=""

    case "$VALUE:$URGENCY:$AUTHORITY" in
        strategic:immediate:human-only)
            route="human"
            priority="CRITICAL"
            ;;
        strategic:soon:human-only)
            route="human"
            priority="HIGH"
            ;;
        strategic:eventual:human-only)
            route="defer-strategic"
            priority="NORMAL"
            ;;
        strategic:conditional:*)
            route="defer-strategic"
            priority="NORMAL"
            ;;
        tactical:immediate:agent-capable)
            route="code"
            priority="HIGH"
            ;;
        tactical:soon:agent-capable)
            route="code"
            priority="NORMAL"
            ;;
        tactical:eventual:agent-capable)
            route="defer-tactical"
            priority="INFO"
            ;;
        tactical:*:investigative)
            route="investigator"
            priority="NORMAL"
            ;;
        operational:*:agent-capable)
            route="code"
            priority="INFO"
            ;;
        *:conditional:*)
            route="defer-operational"
            priority="INFO"
            ;;
        *:*:human-only)
            route="human"
            priority="${PRIORITY:-NORMAL}"
            ;;
        *:*:collaborative)
            route="chat"
            priority="NORMAL"
            ;;
        *)
            route="code"
            priority="INFO"
            ;;
    esac

    echo "$route:$priority"
}

# Run classification
classify_value
classify_urgency
classify_authority

# Cap confidence at 1.0
CONFIDENCE=$(echo "if ($CONFIDENCE > 1.0) 1.0 else $CONFIDENCE" | bc -l)

# Generate output
if [ "$OUTPUT_FORMAT" = "routing" ]; then
    # Simple routing output
    determine_routing
else
    # Full JSON classification
    TRIGGERS_JSON=$(printf '%s\n' "${TRIGGERS[@]}" | jq -R . | jq -s .)

    cat <<EOF
{
  "title": "$TITLE",
  "classification": {
    "value": "$VALUE",
    "urgency": "$URGENCY",
    "authority": "$AUTHORITY",
    "confidence": $CONFIDENCE
  },
  "routing": {
    "destination": "$(determine_routing | cut -d: -f1)",
    "priority": "$(determine_routing | cut -d: -f2)"
  },
  "triggers": $TRIGGERS_JSON,
  "timestamp": "$(date -Iseconds)"
}
EOF
fi
