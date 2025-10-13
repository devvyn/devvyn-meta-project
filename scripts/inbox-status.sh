#!/bin/bash
#
# Human Inbox Status Manager
# Track read/responded status for accountability
#

set -euo pipefail

INBOX="$HOME/inbox"
STATUS_FILE="$INBOX/status.json"

usage() {
    echo "Usage: $0 <command> [filename]"
    echo ""
    echo "Commands:"
    echo "  summary           Show inbox status summary"
    echo "  mark-read <file>  Mark document as read"
    echo "  mark-complete <file>  Mark document as read + responded"
    echo "  pending           List all pending documents"
    echo ""
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

COMMAND="$1"
FILENAME="${2:-}"

case "$COMMAND" in
    summary)
        if [[ ! -f "$STATUS_FILE" ]]; then
            echo "No status file found. Run organize-human-inbox.sh first."
            exit 1
        fi

        echo "=== Human Inbox Summary ==="
        echo ""

        TOTAL=$(jq '.documents | length' "$STATUS_FILE")
        UNREAD=$(jq '[.documents[] | select(.read == false)] | length' "$STATUS_FILE")
        READ=$(jq '[.documents[] | select(.read == true and .responded == false)] | length' "$STATUS_FILE")
        COMPLETED=$(jq '[.documents[] | select(.responded == true)] | length' "$STATUS_FILE")

        echo "Total documents: $TOTAL"
        echo "├─ Unread: $UNREAD"
        echo "├─ Read (pending response): $READ"
        echo "└─ Completed: $COMPLETED"
        echo ""

        if [[ $UNREAD -gt 0 ]]; then
            echo "Unread documents:"
            jq -r '.documents | to_entries[] | select(.value.read == false) | "  - \(.key) (\(.value.category))"' "$STATUS_FILE"
        fi
        ;;

    mark-read)
        if [[ -z "$FILENAME" ]]; then
            echo "Error: filename required"
            usage
        fi

        TEMP=$(mktemp)
        jq --arg file "$FILENAME" \
           --arg timestamp "$(date -Iseconds)" \
           '.documents[$file].read = true |
            .documents[$file].read_at = $timestamp |
            .last_updated = $timestamp' \
           "$STATUS_FILE" > "$TEMP"
        mv "$TEMP" "$STATUS_FILE"

        echo "✅ Marked as read: $FILENAME"
        ;;

    mark-complete)
        if [[ -z "$FILENAME" ]]; then
            echo "Error: filename required"
            usage
        fi

        TEMP=$(mktemp)
        jq --arg file "$FILENAME" \
           --arg timestamp "$(date -Iseconds)" \
           '.documents[$file].read = true |
            .documents[$file].responded = true |
            .documents[$file].completed_at = $timestamp |
            .last_updated = $timestamp' \
           "$STATUS_FILE" > "$TEMP"
        mv "$TEMP" "$STATUS_FILE"

        echo "✅ Marked as complete: $FILENAME"
        ;;

    pending)
        if [[ ! -f "$STATUS_FILE" ]]; then
            echo "No status file found."
            exit 1
        fi

        echo "=== Pending Review ==="
        jq -r '.documents | to_entries[] |
               select(.value.read == false) |
               "\(.key)\n  Category: \(.value.category)\n  Added: \(.value.moved_to_inbox)\n"' \
           "$STATUS_FILE"
        ;;

    *)
        echo "Unknown command: $COMMAND"
        usage
        ;;
esac
