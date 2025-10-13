#!/bin/bash
# Read messages from Notes.app
# Usage: ./notes-receive.sh [note-name]

set -euo pipefail

NOTE_NAME="${1:-Code Agent Inbox}"

# Read note content from Notes.app
CONTENT=$(osascript <<EOF
tell application "Notes"
    repeat with n in notes
        if name of n is "$NOTE_NAME" then
            return body of n
        end if
    end repeat
    return "Note not found: $NOTE_NAME"
end tell
EOF
)

if [[ "$CONTENT" == "Note not found:"* ]]; then
    echo "❌ $CONTENT"
    exit 1
fi

echo "📬 Messages from: $NOTE_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$CONTENT"
