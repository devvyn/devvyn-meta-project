#!/bin/bash
# surface-publish.sh - Unified interface for publishing to any surface
# Usage: surface-publish.sh <surface> [options] <content>

set -euo pipefail

REGISTRY_PATH="${HOME}/infrastructure/agent-bridge/bridge/registry/publication-surfaces.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

show_help() {
    echo "Usage: surface-publish.sh <surface> [options] <content>"
    echo ""
    echo "Surface-specific usage examples:"
    echo ""
    echo "  # Agent inbox"
    echo "  surface-publish.sh agent-inbox --from code --to chat --priority HIGH --subject 'Update' message.md"
    echo ""
    echo "  # Event log"
    echo "  surface-publish.sh event-log --type decision decision.md"
    echo ""
    echo "  # Content DAG"
    echo "  surface-publish.sh content-dag artifact.json"
    echo ""
    echo "  # Defer queue"
    echo "  surface-publish.sh defer-queue --condition 'project-start' --category strategic message.md"
    echo ""
    echo "  # Human desktop (urgent)"
    echo "  surface-publish.sh human-desktop urgent-approval.md"
    echo ""
    echo "  # Human inbox"
    echo "  surface-publish.sh human-inbox --category decisions review.md"
    echo ""
    echo "  # Audio documentation"
    echo "  surface-publish.sh audio-documentation --provider elevenlabs doc.md"
    echo ""
    echo "  # Web webhook"
    echo "  surface-publish.sh web-webhooks --service slack --channel general message.md"
    echo ""
    echo "Use 'surface-info.sh <surface>' for detailed surface information"
}

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

SURFACE="$1"
shift

# Check if registry exists
if [[ ! -f "$REGISTRY_PATH" ]]; then
    echo -e "${RED}Error: Publication surface registry not found${RESET}"
    exit 1
fi

# Verify surface exists
SURFACE_EXISTS=$(jq -r "(.surfaces[\"$SURFACE\"] // .external_surfaces[\"$SURFACE\"]) != null" "$REGISTRY_PATH")

if [[ "$SURFACE_EXISTS" != "true" ]]; then
    echo -e "${RED}Error: Unknown surface '$SURFACE'${RESET}"
    echo ""
    echo "Available surfaces:"
    jq -r '.surfaces | keys[], .external_surfaces | keys[]' "$REGISTRY_PATH" | sort
    exit 1
fi

# Check if surface is implemented
STATUS=$(jq -r "(.surfaces[\"$SURFACE\"] // .external_surfaces[\"$SURFACE\"]).status // \"active\"" "$REGISTRY_PATH")

if [[ "$STATUS" == "planned" ]]; then
    echo -e "${YELLOW}Warning: Surface '$SURFACE' is planned but not yet implemented${RESET}"
    exit 1
fi

# Surface-specific publishing logic
case "$SURFACE" in
    agent-inbox)
        # Parse arguments
        FROM=""
        TO=""
        PRIORITY="NORMAL"
        SUBJECT=""
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --from) FROM="$2"; shift 2 ;;
                --to) TO="$2"; shift 2 ;;
                --priority) PRIORITY="$2"; shift 2 ;;
                --subject) SUBJECT="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        if [[ -z "$FROM" ]] || [[ -z "$TO" ]] || [[ -z "$SUBJECT" ]] || [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing required arguments${RESET}"
            echo "Required: --from <agent> --to <agent> --subject <subject> <content-file>"
            exit 1
        fi

        echo -e "${GREEN}Publishing to agent inbox...${RESET}"
        exec "${SCRIPT_DIR}/bridge-send.sh" "$FROM" "$TO" "$PRIORITY" "$SUBJECT" "$CONTENT"
        ;;

    event-log)
        # Parse arguments
        TYPE=""
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --type) TYPE="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        if [[ -z "$TYPE" ]] || [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing required arguments${RESET}"
            echo "Required: --type <decision|pattern|story|state-change> <content-file>"
            exit 1
        fi

        echo -e "${GREEN}Publishing to event log...${RESET}"

        # Check if bridge-event-create.sh exists, if not create simple version
        if [[ -f "${SCRIPT_DIR}/bridge-event-create.sh" ]]; then
            exec "${SCRIPT_DIR}/bridge-event-create.sh" "$TYPE" "$CONTENT"
        else
            # Simple fallback: create event file directly
            TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
            UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
            EVENT_FILE="${HOME}/infrastructure/agent-bridge/bridge/events/${TIMESTAMP}-${TYPE}-${UUID}.md"

            cp "$CONTENT" "$EVENT_FILE"
            echo -e "${GREEN}✓ Event created: $EVENT_FILE${RESET}"
        fi
        ;;

    content-dag)
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            if [[ -z "$CONTENT" ]]; then
                CONTENT="$1"
            fi
            shift
        done

        if [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing content file${RESET}"
            exit 1
        fi

        echo -e "${GREEN}Publishing to content DAG...${RESET}"

        # Check if dag-store.sh exists
        if [[ -f "${SCRIPT_DIR}/dag-store.sh" ]]; then
            exec "${SCRIPT_DIR}/dag-store.sh" "$CONTENT"
        else
            echo -e "${YELLOW}Note: DAG storage not yet implemented${RESET}"
            echo "Content would be stored at: .dag/objects/"
            exit 1
        fi
        ;;

    defer-queue)
        CONDITION=""
        CATEGORY="tactical"
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --condition) CONDITION="$2"; shift 2 ;;
                --category) CATEGORY="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        if [[ -z "$CONDITION" ]] || [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing required arguments${RESET}"
            echo "Required: --condition <trigger> [--category strategic|tactical|operational] <content-file>"
            exit 1
        fi

        echo -e "${GREEN}Publishing to defer queue...${RESET}"

        if [[ -f "${SCRIPT_DIR}/bridge-defer.sh" ]]; then
            exec "${SCRIPT_DIR}/bridge-defer.sh" "$CONDITION" "$CONTENT"
        else
            # Simple fallback
            UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
            DEFER_FILE="${HOME}/infrastructure/agent-bridge/bridge/defer-queue/${CATEGORY}/${CONDITION}-${UUID}.md"

            mkdir -p "$(dirname "$DEFER_FILE")"
            cp "$CONTENT" "$DEFER_FILE"
            echo -e "${GREEN}✓ Deferred: $DEFER_FILE${RESET}"
            echo -e "${DIM}Condition: $CONDITION${RESET}"
        fi
        ;;

    human-desktop)
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            if [[ -z "$CONTENT" ]]; then
                CONTENT="$1"
            fi
            shift
        done

        if [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing content file${RESET}"
            exit 1
        fi

        FILENAME=$(basename "$CONTENT")
        echo -e "${GREEN}Publishing to Desktop (urgent)...${RESET}"
        cp "$CONTENT" "${HOME}/Desktop/${FILENAME}"
        echo -e "${GREEN}✓ Copied to Desktop: ${FILENAME}${RESET}"
        ;;

    human-inbox)
        CATEGORY="general"
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --category) CATEGORY="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        if [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing content file${RESET}"
            exit 1
        fi

        INBOX_DIR="${HOME}/inbox/${CATEGORY}"
        mkdir -p "$INBOX_DIR"

        FILENAME=$(basename "$CONTENT")
        echo -e "${GREEN}Publishing to human inbox...${RESET}"
        cp "$CONTENT" "${INBOX_DIR}/${FILENAME}"
        echo -e "${GREEN}✓ Added to inbox: ${CATEGORY}/${FILENAME}${RESET}"
        ;;

    audio-documentation)
        PROVIDER="macos"
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --provider) PROVIDER="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        if [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing content file${RESET}"
            exit 1
        fi

        echo -e "${GREEN}Converting to audio...${RESET}"

        if [[ -f "${SCRIPT_DIR}/doc-to-audio.py" ]]; then
            exec python3 "${SCRIPT_DIR}/doc-to-audio.py" --provider "$PROVIDER" "$CONTENT"
        else
            echo -e "${RED}Error: doc-to-audio.py not found${RESET}"
            exit 1
        fi
        ;;

    web-webhooks)
        SERVICE=""
        CHANNEL=""
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --service) SERVICE="$2"; shift 2 ;;
                --channel) CHANNEL="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        if [[ -z "$SERVICE" ]] || [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing required arguments${RESET}"
            echo "Required: --service <slack|discord|github> [--channel <channel>] <content-file>"
            exit 1
        fi

        echo -e "${GREEN}Publishing to web (${SERVICE})...${RESET}"

        if [[ -f "${SCRIPT_DIR}/adapters/web-publish.sh" ]]; then
            exec "${SCRIPT_DIR}/adapters/web-publish.sh" "$SERVICE" "$CHANNEL" "$CONTENT"
        else
            echo -e "${YELLOW}Note: Web publishing adapter not yet implemented${RESET}"
            exit 1
        fi
        ;;

    email-bridge)
        TO=""
        SUBJECT=""
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --to) TO="$2"; shift 2 ;;
                --subject) SUBJECT="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        if [[ -z "$TO" ]] || [[ -z "$SUBJECT" ]] || [[ -z "$CONTENT" ]]; then
            echo -e "${RED}Error: Missing required arguments${RESET}"
            echo "Required: --to <email> --subject <subject> <content-file>"
            exit 1
        fi

        echo -e "${GREEN}Sending email...${RESET}"

        if [[ -f "${SCRIPT_DIR}/adapters/email-send.sh" ]]; then
            exec "${SCRIPT_DIR}/adapters/email-send.sh" "$TO" "$SUBJECT" "$CONTENT"
        else
            echo -e "${YELLOW}Note: Email adapter not yet implemented${RESET}"
            exit 1
        fi
        ;;

    public-docs)
        TARGET="github-pages"
        CONTENT=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --target) TARGET="$2"; shift 2 ;;
                *)
                    if [[ -z "$CONTENT" ]]; then
                        CONTENT="$1"
                    fi
                    shift
                    ;;
            esac
        done

        echo -e "${GREEN}Publishing documentation to ${TARGET}...${RESET}"

        if [[ -f "${SCRIPT_DIR}/adapters/publish-docs.sh" ]]; then
            exec "${SCRIPT_DIR}/adapters/publish-docs.sh" "$TARGET" "$CONTENT"
        else
            echo -e "${YELLOW}Note: Documentation publishing not yet implemented${RESET}"
            exit 1
        fi
        ;;

    *)
        echo -e "${RED}Error: Publishing to '$SURFACE' not yet implemented${RESET}"
        echo "Use 'surface-info.sh $SURFACE' to see the publish command"
        exit 1
        ;;
esac
