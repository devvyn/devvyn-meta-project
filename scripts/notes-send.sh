#!/bin/bash
# Send message to Notes.app and signal recipient
# Usage: ./notes-send.sh <note-name> <message-content> [recipient]

set -euo pipefail

NOTE_NAME="${1:-}"
MESSAGE="${2:-}"
RECIPIENT="${3:-chat}"

if [[ -z "$NOTE_NAME" || -z "$MESSAGE" ]]; then
    echo "Usage: $0 <note-name> <message-content> [recipient]"
    echo "Example: $0 'Code Agent Updates' 'Implementation started' chat"
    exit 1
fi

# Timestamp for message
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Escape quotes in message
MESSAGE_ESCAPED=$(echo "$MESSAGE" | sed 's/"/\\"/g')

# Create/update note in Notes.app
osascript <<EOF
tell application "Notes"
    -- Try to find existing note
    set noteFound to false
    repeat with n in notes
        if name of n is "$NOTE_NAME" then
            set noteFound to true
            set existingBody to body of n
            set body of n to existingBody & "<br><br><b>[$TIMESTAMP]</b><br>" & "$MESSAGE_ESCAPED"
            exit repeat
        end if
    end repeat

    -- Create new note if not found
    if not noteFound then
        set newNote to make new note with properties {name:"$NOTE_NAME", body:"<b>[$TIMESTAMP]</b><br>$MESSAGE_ESCAPED"}
    end if
end tell
EOF

# Signal recipient via notifyutil
NOTIFICATION_KEY="com.anthropic.code.to.$RECIPIENT"
notifyutil -p "$NOTIFICATION_KEY"

echo "✅ Message sent to Notes.app: $NOTE_NAME"
echo "📡 Notification posted: $NOTIFICATION_KEY"
