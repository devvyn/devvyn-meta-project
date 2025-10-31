#!/usr/bin/env bash
# Automatic message triage - reduces human inbox load
set -euo pipefail

BRIDGE_ROOT="${HOME}/infrastructure/agent-bridge/bridge"
TRIAGE_DIR="${BRIDGE_ROOT}/triage"

# Triage rules (priority-based)
triage_message() {
    local message_file="$1"
    local content
    content=$(cat "$message_file")

    # Extract metadata
    local priority
    priority=$(echo "$content" | grep "^\*\*Priority" | cut -d: -f2 | tr -d ' []')

    # Rule 1: Empty/template messages → archive immediately
    if echo "$content" | grep -q "\[edit this file to add content\]"; then
        echo "ARCHIVE_EMPTY"
        return
    fi

    # Rule 2: Auto-trigger INFO → convert to INFO log
    if echo "$content" | grep -q "Auto-Trigger.*INFO"; then
        echo "LOG_INFO"
        return
    fi

    # Rule 3: Status reports → direct to agent inbox
    if echo "$content" | grep -qE "Status Report|Session Summary"; then
        echo "ROUTE_AGENT"
        return
    fi

    # Rule 4: Questions without urgency → defer 24h
    if echo "$content" | grep -qE "Should we|Could we|What about" && [[ "$priority" != "CRITICAL" ]]; then
        echo "DEFER_24H"
        return
    fi

    # Rule 5: CRITICAL from employment work → keep in human inbox
    if echo "$content" | grep -qE "AAFC|herbarium|specimen" && [[ "$priority" == "CRITICAL" ]]; then
        echo "KEEP_HUMAN"
        return
    fi

    # Default: standard processing
    echo "PROCESS_NORMAL"
}

# Process inbox
process_inbox() {
    local inbox_dir="${BRIDGE_ROOT}/inbox/human"

    if [[ ! -d "$inbox_dir" ]]; then
        return
    fi

    local triaged=0
    local kept=0

    for msg in "$inbox_dir"/*.md 2>/dev/null; do
        [[ -f "$msg" ]] || continue

        local action
        action=$(triage_message "$msg")

        case "$action" in
            ARCHIVE_EMPTY)
                mkdir -p "$TRIAGE_DIR/archived-empty"
                mv "$msg" "$TRIAGE_DIR/archived-empty/"
                ((triaged++))
                ;;
            LOG_INFO)
                mkdir -p "$TRIAGE_DIR/info-logs"
                mv "$msg" "$TRIAGE_DIR/info-logs/"
                ((triaged++))
                ;;
            ROUTE_AGENT)
                # Extract sender and route back
                local sender
                sender=$(grep "^\*\*From\*\*:" "$msg" | cut -d: -f2 | tr -d ' ')
                if [[ -n "$sender" ]]; then
                    mkdir -p "${BRIDGE_ROOT}/inbox/${sender}"
                    mv "$msg" "${BRIDGE_ROOT}/inbox/${sender}/"
                    ((triaged++))
                fi
                ;;
            DEFER_24H)
                mkdir -p "$TRIAGE_DIR/deferred"
                mv "$msg" "$TRIAGE_DIR/deferred/"
                ((triaged++))
                ;;
            KEEP_HUMAN)
                ((kept++))
                ;;
            PROCESS_NORMAL)
                ((kept++))
                ;;
        esac
    done

    echo "Triaged: $triaged | Kept for human: $kept"
}

# Main
mkdir -p "$TRIAGE_DIR"
process_inbox
