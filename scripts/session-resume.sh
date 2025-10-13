#!/bin/bash
# Lightweight Session Resume - Show context from recent sessions

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HANDOFF_DIR="$PROJECT_ROOT/.session-handoffs"

usage() {
    cat << 'EOF'
Usage: ./scripts/session-resume.sh [COUNT]

Shows recent session handoffs to understand context.

Arguments:
  COUNT   Number of recent handoffs to show (default: 3)

Examples:
  ./scripts/session-resume.sh       # Show last 3 sessions
  ./scripts/session-resume.sh 5     # Show last 5 sessions
  ./scripts/session-resume.sh all   # Show all handoffs

EOF
    exit 1
}

COUNT="${1:-3}"

if [[ ! -d "$HANDOFF_DIR" ]]; then
    echo "No session handoffs found yet."
    echo ""
    echo "Create one with:"
    echo "  ./scripts/session-handoff.sh \"What you accomplished\""
    exit 0
fi

HANDOFFS=$(find "$HANDOFF_DIR" -name "*-handoff.md" -type f | sort -r)
TOTAL=$(echo "$HANDOFFS" | wc -l | xargs)

if [[ $TOTAL -eq 0 ]]; then
    echo "No session handoffs found."
    exit 0
fi

echo "📚 Recent Session Context"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$COUNT" == "all" ]]; then
    COUNT=$TOTAL
fi

echo "$HANDOFFS" | head -n "$COUNT" | while read -r handoff; do
    if [[ -z "$handoff" ]]; then
        continue
    fi

    # Extract key info
    timestamp=$(basename "$handoff" | sed 's/-handoff.md$//' | tr '-' ':' | sed 's/:/-/' | sed 's/:/-/')
    summary=$(grep -A 1 "## Summary" "$handoff" | tail -1)
    branch=$(grep "Branch" "$handoff" | sed 's/.*Branch\*\*: //')

    echo "📅 $timestamp"
    echo "   $summary"
    echo "   Branch: $branch"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Showing $COUNT of $TOTAL handoffs"
echo ""
echo "View details:"
echo "  cat $HANDOFF_DIR/[timestamp]-handoff.md"
echo ""
echo "View all:"
echo "  ./scripts/session-resume.sh all"
