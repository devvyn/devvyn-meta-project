#!/bin/bash
# Lightweight Session Handoff - End session with context for next

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HANDOFF_DIR="$PROJECT_ROOT/.session-handoffs"

usage() {
    cat << 'EOF'
Usage: ./scripts/session-handoff.sh "Brief summary of session work"

Captures session context for next Code instance.

Examples:
  ./scripts/session-handoff.sh "Built content-DAG pattern, integrated bridge"
  ./scripts/session-handoff.sh "Fixed AAFC docs, added OpenRouter budget system"

Stores: What was done, files changed, decisions made
EOF
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

SUMMARY="$1"

# Create handoff directory
mkdir -p "$HANDOFF_DIR"

# Generate handoff file
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
HANDOFF_FILE="$HANDOFF_DIR/${TIMESTAMP//:/-}-handoff.md"

# Collect context
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
MODIFIED=$(git status --short 2>/dev/null | head -20 || echo "No git status")
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "No commits")

# Create handoff document
cat > "$HANDOFF_FILE" << EOF
# Session Handoff: $TIMESTAMP

## Summary
$SUMMARY

## Context
- **Branch**: $BRANCH
- **User**: $(whoami)
- **Working Dir**: $PROJECT_ROOT

## Changes
\`\`\`
$MODIFIED
\`\`\`

## Recent Commits
\`\`\`
$RECENT_COMMITS
\`\`\`

## Notes
[Add any specific notes, blockers, or next steps here]

---
**Handoff created**: $TIMESTAMP
EOF

echo "✅ Session handoff created: $HANDOFF_FILE"
echo ""
echo "📝 Summary: $SUMMARY"
echo "📊 Captured: git status, recent commits"
echo ""
echo "Next session will see this context via:"
echo "  ./scripts/session-resume.sh"
echo ""
echo "To add notes, edit:"
echo "  $HANDOFF_FILE"

# Optional: Open in editor for additional notes
if [[ "${EDITOR:-}" != "" ]] && [[ -t 0 ]]; then
    read -p "Open in editor to add notes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $EDITOR "$HANDOFF_FILE"
    fi
fi
