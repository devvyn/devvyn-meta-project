#!/usr/bin/env bash
# Minimal Viable Coordination (MVC) - message.sh
# Version: 1.0
# Purpose: Simple file-based agent coordination system

set -euo pipefail

# Configuration
INBOX_DIR="inbox"
EVENT_LOG="events.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize directories
init() {
    mkdir -p "$INBOX_DIR"
    touch "$EVENT_LOG"
}

# Generate collision-free message ID
# Format: TIMESTAMP-SENDER-UUID
generate_message_id() {
    local sender="$1"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%S%z)

    # Generate UUID (platform-agnostic)
    if command -v uuidgen &> /dev/null; then
        local uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    else
        # Fallback: pseudo-UUID from /dev/urandom
        local uuid=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
        uuid="${uuid:0:8}-${uuid:8:4}-${uuid:12:4}-${uuid:16:4}-${uuid:20:12}"
    fi

    echo "${timestamp}-${sender}-${uuid}"
}

# Log event to append-only event log
log_event() {
    local event_type="$1"
    local message_id="$2"
    local from="$3"
    local to="$4"
    local subject="$5"

    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%S%z)

    # Event format: TIMESTAMP|TYPE|MESSAGE_ID|FROM|TO|SUBJECT
    echo "${timestamp}|${event_type}|${message_id}|${from}|${to}|${subject}" >> "$EVENT_LOG"
}

# Send message from one agent to another
send() {
    if [ $# -lt 4 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: $0 send FROM TO SUBJECT BODY"
        exit 1
    fi

    local from="$1"
    local to="$2"
    local subject="$3"
    local body="$4"

    # Generate unique message ID
    local message_id=$(generate_message_id "$from")

    # Create inbox directory for recipient
    mkdir -p "${INBOX_DIR}/${to}"

    # Create message file
    local message_file="${INBOX_DIR}/${to}/${message_id}.msg"

    # Write message (YAML-like format, easy to parse)
    cat > "$message_file" <<EOF
id: ${message_id}
from: ${from}
to: ${to}
subject: ${subject}
timestamp: $(date -u +%Y-%m-%dT%H:%M:%S%z)
body: |
  ${body}
EOF

    # Log event (event sourcing)
    log_event "SENT" "$message_id" "$from" "$to" "$subject"

    echo -e "${GREEN}✓ Message sent${NC}"
    echo -e "  ${BLUE}ID:${NC} ${message_id}"
    echo -e "  ${BLUE}From:${NC} ${from}"
    echo -e "  ${BLUE}To:${NC} ${to}"
    echo -e "  ${BLUE}Subject:${NC} ${subject}"
}

# Check inbox for an agent
inbox() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing agent name${NC}"
        echo "Usage: $0 inbox AGENT"
        exit 1
    fi

    local agent="$1"
    local agent_inbox="${INBOX_DIR}/${agent}"

    if [ ! -d "$agent_inbox" ]; then
        echo -e "${YELLOW}No inbox found for agent: ${agent}${NC}"
        echo "Inbox will be created when first message arrives."
        return 0
    fi

    local message_count=$(find "$agent_inbox" -name "*.msg" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$message_count" -eq 0 ]; then
        echo -e "${YELLOW}No messages in inbox for: ${agent}${NC}"
        return 0
    fi

    echo -e "${GREEN}Messages for ${agent}: ${message_count}${NC}"
    echo ""

    # List messages (most recent first)
    find "$agent_inbox" -name "*.msg" -type f | sort -r | while read -r msg_file; do
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Parse message file
        local msg_id=$(grep "^id:" "$msg_file" | cut -d' ' -f2-)
        local msg_from=$(grep "^from:" "$msg_file" | cut -d' ' -f2-)
        local msg_subject=$(grep "^subject:" "$msg_file" | cut -d' ' -f2-)
        local msg_timestamp=$(grep "^timestamp:" "$msg_file" | cut -d' ' -f2-)

        echo -e "${BLUE}ID:${NC} ${msg_id}"
        echo -e "${BLUE}From:${NC} ${msg_from}"
        echo -e "${BLUE}Subject:${NC} ${msg_subject}"
        echo -e "${BLUE}Time:${NC} ${msg_timestamp}"
        echo ""
        echo -e "${BLUE}Body:${NC}"

        # Extract body (everything after "body: |")
        awk '/^body: \|/{flag=1; next} flag' "$msg_file" | sed 's/^  //'

        echo ""
    done

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Read specific message
read_message() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: $0 read AGENT MESSAGE_ID"
        exit 1
    fi

    local agent="$1"
    local message_id="$2"
    local message_file="${INBOX_DIR}/${agent}/${message_id}.msg"

    if [ ! -f "$message_file" ]; then
        echo -e "${RED}Error: Message not found${NC}"
        exit 1
    fi

    # Display message
    cat "$message_file"

    # Log read event
    local from=$(grep "^from:" "$message_file" | cut -d' ' -f2-)
    local subject=$(grep "^subject:" "$message_file" | cut -d' ' -f2-)
    log_event "READ" "$message_id" "$from" "$agent" "$subject"
}

# Delete message
delete_message() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: $0 delete AGENT MESSAGE_ID"
        exit 1
    fi

    local agent="$1"
    local message_id="$2"
    local message_file="${INBOX_DIR}/${agent}/${message_id}.msg"

    if [ ! -f "$message_file" ]; then
        echo -e "${RED}Error: Message not found${NC}"
        exit 1
    fi

    # Log deletion before removing
    local from=$(grep "^from:" "$message_file" | cut -d' ' -f2-)
    local subject=$(grep "^subject:" "$message_file" | cut -d' ' -f2-)
    log_event "DELETED" "$message_id" "$from" "$agent" "$subject"

    # Remove message file
    rm "$message_file"

    echo -e "${GREEN}✓ Message deleted${NC}"
}

# View event log
view_log() {
    if [ ! -f "$EVENT_LOG" ]; then
        echo -e "${YELLOW}No events logged yet${NC}"
        return 0
    fi

    echo -e "${GREEN}Event Log:${NC}"
    echo ""
    echo -e "${BLUE}TIMESTAMP                    | TYPE    | FROM    | TO      | SUBJECT${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Parse and display event log
    tail -20 "$EVENT_LOG" | while IFS='|' read -r timestamp event_type message_id from to subject; do
        printf "%-28s | %-7s | %-7s | %-7s | %s\n" "$timestamp" "$event_type" "$from" "$to" "$subject"
    done
}

# Statistics
stats() {
    if [ ! -f "$EVENT_LOG" ]; then
        echo -e "${YELLOW}No events logged yet${NC}"
        return 0
    fi

    echo -e "${GREEN}Coordination Statistics:${NC}"
    echo ""

    # Total events
    local total_events=$(wc -l < "$EVENT_LOG" | tr -d ' ')
    echo -e "  ${BLUE}Total events:${NC} ${total_events}"

    # Events by type
    echo ""
    echo -e "  ${BLUE}Events by type:${NC}"
    cut -d'|' -f2 "$EVENT_LOG" | sort | uniq -c | while read -r count type; do
        echo -e "    ${type}: ${count}"
    done

    # Messages by sender
    echo ""
    echo -e "  ${BLUE}Messages by sender:${NC}"
    grep "SENT" "$EVENT_LOG" | cut -d'|' -f4 | sort | uniq -c | while read -r count sender; do
        echo -e "    ${sender}: ${count}"
    done

    # Messages by recipient
    echo ""
    echo -e "  ${BLUE}Messages by recipient:${NC}"
    grep "SENT" "$EVENT_LOG" | cut -d'|' -f5 | sort | uniq -c | while read -r count recipient; do
        echo -e "    ${recipient}: ${count}"
    done
}

# Help message
help() {
    cat <<EOF
${GREEN}Minimal Viable Coordination (MVC)${NC}

${BLUE}Usage:${NC}
  $0 <command> [arguments]

${BLUE}Commands:${NC}
  ${YELLOW}send${NC} FROM TO SUBJECT BODY    Send message from one agent to another
  ${YELLOW}inbox${NC} AGENT                   Check inbox for an agent
  ${YELLOW}read${NC} AGENT MESSAGE_ID         Read specific message
  ${YELLOW}delete${NC} AGENT MESSAGE_ID       Delete message from inbox
  ${YELLOW}log${NC}                           View event log (last 20 events)
  ${YELLOW}stats${NC}                         Show coordination statistics
  ${YELLOW}help${NC}                          Show this help message

${BLUE}Examples:${NC}
  # Send a message
  $0 send code chat "Task complete" "Finished implementing feature X"

  # Check inbox
  $0 inbox code

  # View event log
  $0 log

  # Get statistics
  $0 stats

${BLUE}Universal Patterns:${NC}
  ✓ Collision-free messaging (UUID + timestamp)
  ✓ Event sourcing (append-only log)
  ✓ Authority domains (agent roles)
  ✓ File-based queue (portable, no database)

${BLUE}More info:${NC}
  cat README.md
EOF
}

# Main command router
main() {
    # Initialize on first run
    init

    if [ $# -eq 0 ]; then
        help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        send)
            send "$@"
            ;;
        inbox)
            inbox "$@"
            ;;
        read)
            read_message "$@"
            ;;
        delete)
            delete_message "$@"
            ;;
        log)
            view_log
            ;;
        stats)
            stats
            ;;
        help|--help|-h)
            help
            ;;
        *)
            echo -e "${RED}Error: Unknown command: ${command}${NC}"
            echo ""
            help
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"
