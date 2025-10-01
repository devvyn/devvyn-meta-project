#!/bin/bash
# Create Story Event - Harari's Nexus embodied in code
# Stories = patterns + narrative + context + propagation tracking

set -euo pipefail

BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"
EVENTS_DIR="$BRIDGE_ROOT/events"

usage() {
    echo "Usage: $0 <title> <discoverer> <pattern-source>"
    echo ""
    echo "Creates a story event with full Nexus-inspired structure"
    echo ""
    echo "Arguments:"
    echo "  title:          Story title (e.g., 'Command System Proves Valuable')"
    echo "  discoverer:     Who discovered this pattern (code, chat, human)"
    echo "  pattern-source: Where pattern originated (e.g., 'AAFC Herbarium')"
    echo ""
    echo "The script will then prompt for:"
    echo "  - Narrative"
    echo "  - Context details"
    echo "  - Evidence"
    echo "  - Propagation history"
    echo ""
    echo "Example:"
    echo "  $0 'Command Standardization Success' code 'AAFC Herbarium'"
    exit 1
}

if [ $# -lt 3 ]; then
    usage
fi

TITLE="$1"
DISCOVERER="$2"
PATTERN_SOURCE="$3"

# Generate unique event ID
TIMESTAMP=$(date -Iseconds)
UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
EVENT_ID="${TIMESTAMP}-story-${UUID}"
EVENT_FILE="$EVENTS_DIR/${EVENT_ID}.md"

echo "Creating story event: $TITLE"
echo "Event ID: $EVENT_ID"
echo ""

# Interactive prompts for story components
echo "--- STORY NARRATIVE ---"
echo "How was this pattern discovered? What problem did it solve? Why does it matter?"
echo "(Enter narrative, end with EOF on new line):"
NARRATIVE=$(cat)

echo ""
echo "--- CONTEXT ---"
echo "Project/environment where pattern emerged:"
read -r CONTEXT_WHERE

echo "Time period and conditions:"
read -r CONTEXT_WHEN

echo "Problem that needed solving:"
read -r CONTEXT_WHY

echo "Agents/humans involved:"
read -r CONTEXT_WHO

echo ""
echo "--- EVIDENCE ---"
echo "Concrete data supporting the story (one per line, end with empty line):"
EVIDENCE=""
while IFS= read -r line; do
    [ -z "$line" ] && break
    EVIDENCE="${EVIDENCE}- $line\n"
done

echo ""
echo "--- PROPAGATION ---"
echo "Projects/contexts that adopted this (comma-separated):"
read -r SPREAD_TO

echo "How story changed as it spread:"
read -r MUTATIONS

echo ""
echo "--- MEMETIC FITNESS ---"
echo "Adoption rate (e.g., '4/4 exposed contexts' or '100%'):"
read -r ADOPTION_RATE

echo "Success rate (e.g., '4/4 adoptions succeeded' or '100%'):"
read -r SUCCESS_RATE

echo "Impact description:"
read -r IMPACT_SCORE

echo ""
echo "--- NETWORK STATUS ---"
echo "Belief state (Emerging|Believed|Verified|Canonical|Obsolete):"
read -r BELIEF_STATE

echo "Verification (Unverified|Partially Verified|Proven|Disproven):"
read -r VERIFICATION

# Create story event file
cat > "$EVENT_FILE" << EOF
# story: ${TITLE}

**Event-ID**: ${EVENT_ID}
**Timestamp**: ${TIMESTAMP}
**Type**: story
**Discoverer**: ${DISCOVERER}
**Pattern-Source**: ${PATTERN_SOURCE}

## Story

${NARRATIVE}

## Context

**Where**: ${CONTEXT_WHERE}
**When**: ${CONTEXT_WHEN}
**Why**: ${CONTEXT_WHY}
**Who**: ${CONTEXT_WHO}

## Evidence

$(echo -e "$EVIDENCE")

## Propagation History

**Origin**: ${PATTERN_SOURCE}
**Spread to**: ${SPREAD_TO}
**Mutations**: ${MUTATIONS}
**Current Reach**: $(echo "$SPREAD_TO" | tr ',' '\n' | wc -l | tr -d ' ') contexts

## Memetic Fitness

**Adoption Rate**: ${ADOPTION_RATE}
**Success Rate**: ${SUCCESS_RATE}
**Impact Score**: ${IMPACT_SCORE}
**Fitness Calculation**: (adoption × success × impact)

## Network Status

**Belief State**: ${BELIEF_STATE}
**Verification**: ${VERIFICATION}
**Reality-Construction**: This story shapes how the network coordinates multi-agent workflows

---

**Immutability**: This story is append-only. Mutations are new events.
**Nexus**: Information creates reality through context + narrative + propagation.
EOF

echo ""
echo "✅ Story event created: $EVENT_ID"
echo "📁 Location: $EVENT_FILE"
echo ""
echo "To view: cat \"$EVENT_FILE\""
echo "To query all stories: ./scripts/bridge-query-events.sh --type story"

echo "$EVENT_ID"  # Return event ID for chaining
