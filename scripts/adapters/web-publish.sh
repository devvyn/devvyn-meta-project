#!/bin/bash
# web-publish.sh - Publish content to external web services via webhooks
# Usage: web-publish.sh <service> [channel] <content-file>

set -euo pipefail

CONFIG_FILE="${HOME}/infrastructure/agent-bridge/bridge/config/web-adapters.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

show_help() {
    echo "Usage: web-publish.sh <service> [channel] <content-file>"
    echo ""
    echo "Supported services:"
    echo "  slack       - Slack webhook"
    echo "  discord     - Discord webhook"
    echo "  github      - GitHub API (create issue/comment)"
    echo "  generic     - Generic HTTP POST webhook"
    echo ""
    echo "Examples:"
    echo "  web-publish.sh slack general message.md"
    echo "  web-publish.sh discord announcements update.md"
    echo "  web-publish.sh github '' issue-body.md"
    echo "  web-publish.sh generic '' notification.json"
    echo ""
    echo "Configuration: $CONFIG_FILE"
}

if [[ $# -lt 2 ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

SERVICE="$1"
CHANNEL="$2"
CONTENT_FILE="${3:-}"

# Handle optional channel parameter
if [[ ! -f "$CHANNEL" ]] && [[ -f "${3:-}" ]]; then
    # Channel was provided
    CONTENT_FILE="$3"
elif [[ -f "$CHANNEL" ]]; then
    # No channel, second arg is the file
    CONTENT_FILE="$CHANNEL"
    CHANNEL=""
fi

if [[ -z "$CONTENT_FILE" ]] || [[ ! -f "$CONTENT_FILE" ]]; then
    echo -e "${RED}Error: Content file not found or not specified${RESET}"
    exit 1
fi

# Create config directory if it doesn't exist
mkdir -p "$(dirname "$CONFIG_FILE")"

# Create default config if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "slack": {
    "webhook_url": "",
    "default_channel": "general",
    "enabled": false
  },
  "discord": {
    "webhook_url": "",
    "default_channel": "",
    "enabled": false
  },
  "github": {
    "token": "",
    "repo": "",
    "enabled": false
  },
  "generic": {
    "webhook_url": "",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    },
    "enabled": false
  }
}
EOF
    echo -e "${YELLOW}Created default config at: $CONFIG_FILE${RESET}"
    echo -e "${YELLOW}Please configure your webhooks before using this tool${RESET}"
    exit 1
fi

# Read service configuration
ENABLED=$(jq -r ".${SERVICE}.enabled // false" "$CONFIG_FILE")

if [[ "$ENABLED" != "true" ]]; then
    echo -e "${RED}Error: Service '$SERVICE' is not enabled in config${RESET}"
    echo "Please edit $CONFIG_FILE and set ${SERVICE}.enabled to true"
    exit 1
fi

# Read content
CONTENT=$(cat "$CONTENT_FILE")

# Service-specific publishing
case "$SERVICE" in
    slack)
        WEBHOOK_URL=$(jq -r '.slack.webhook_url' "$CONFIG_FILE")
        DEFAULT_CHANNEL=$(jq -r '.slack.default_channel' "$CONFIG_FILE")
        CHANNEL="${CHANNEL:-$DEFAULT_CHANNEL}"

        if [[ -z "$WEBHOOK_URL" ]] || [[ "$WEBHOOK_URL" == "null" ]]; then
            echo -e "${RED}Error: Slack webhook URL not configured${RESET}"
            exit 1
        fi

        # Prepare Slack payload
        PAYLOAD=$(jq -n \
            --arg channel "$CHANNEL" \
            --arg text "$CONTENT" \
            '{channel: $channel, text: $text}')

        echo -e "${GREEN}Publishing to Slack (#${CHANNEL})...${RESET}"

        RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "$PAYLOAD")

        if [[ "$RESPONSE" == "ok" ]]; then
            echo -e "${GREEN}✓ Published successfully${RESET}"
        else
            echo -e "${RED}✗ Failed: $RESPONSE${RESET}"
            exit 1
        fi
        ;;

    discord)
        WEBHOOK_URL=$(jq -r '.discord.webhook_url' "$CONFIG_FILE")

        if [[ -z "$WEBHOOK_URL" ]] || [[ "$WEBHOOK_URL" == "null" ]]; then
            echo -e "${RED}Error: Discord webhook URL not configured${RESET}"
            exit 1
        fi

        # Prepare Discord payload
        PAYLOAD=$(jq -n --arg content "$CONTENT" '{content: $content}')

        echo -e "${GREEN}Publishing to Discord...${RESET}"

        RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "$PAYLOAD")

        # Discord returns empty response on success
        if [[ -z "$RESPONSE" ]]; then
            echo -e "${GREEN}✓ Published successfully${RESET}"
        else
            echo -e "${RED}✗ Failed: $RESPONSE${RESET}"
            exit 1
        fi
        ;;

    github)
        TOKEN=$(jq -r '.github.token' "$CONFIG_FILE")
        REPO=$(jq -r '.github.repo' "$CONFIG_FILE")

        if [[ -z "$TOKEN" ]] || [[ "$TOKEN" == "null" ]] || [[ -z "$REPO" ]] || [[ "$REPO" == "null" ]]; then
            echo -e "${RED}Error: GitHub token or repo not configured${RESET}"
            exit 1
        fi

        # Assume content is in format: title\n\nbody
        TITLE=$(echo "$CONTENT" | head -1)
        BODY=$(echo "$CONTENT" | tail -n +3)

        # Prepare GitHub issue payload
        PAYLOAD=$(jq -n \
            --arg title "$TITLE" \
            --arg body "$BODY" \
            '{title: $title, body: $body}')

        echo -e "${GREEN}Creating GitHub issue in ${REPO}...${RESET}"

        RESPONSE=$(curl -s -X POST \
            "https://api.github.com/repos/${REPO}/issues" \
            -H "Authorization: token ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD")

        ISSUE_URL=$(echo "$RESPONSE" | jq -r '.html_url // empty')

        if [[ -n "$ISSUE_URL" ]]; then
            echo -e "${GREEN}✓ Issue created: $ISSUE_URL${RESET}"
        else
            ERROR=$(echo "$RESPONSE" | jq -r '.message // "Unknown error"')
            echo -e "${RED}✗ Failed: $ERROR${RESET}"
            exit 1
        fi
        ;;

    generic)
        WEBHOOK_URL=$(jq -r '.generic.webhook_url' "$CONFIG_FILE")
        METHOD=$(jq -r '.generic.method // "POST"' "$CONFIG_FILE")

        if [[ -z "$WEBHOOK_URL" ]] || [[ "$WEBHOOK_URL" == "null" ]]; then
            echo -e "${RED}Error: Generic webhook URL not configured${RESET}"
            exit 1
        fi

        echo -e "${GREEN}Publishing to generic webhook ($METHOD)...${RESET}"

        # Read headers from config
        HEADERS=()
        while IFS= read -r header; do
            HEADERS+=(-H "$header")
        done < <(jq -r '.generic.headers | to_entries[] | "\(.key): \(.value)"' "$CONFIG_FILE")

        # Determine content type and prepare data
        if jq -e . "$CONTENT_FILE" >/dev/null 2>&1; then
            # Content is valid JSON
            RESPONSE=$(curl -s -X "$METHOD" "$WEBHOOK_URL" \
                "${HEADERS[@]}" \
                -d "@$CONTENT_FILE")
        else
            # Content is plain text, wrap in JSON
            PAYLOAD=$(jq -n --arg text "$CONTENT" '{text: $text}')
            RESPONSE=$(curl -s -X "$METHOD" "$WEBHOOK_URL" \
                "${HEADERS[@]}" \
                -d "$PAYLOAD")
        fi

        echo -e "${GREEN}✓ Published successfully${RESET}"
        echo -e "${GREEN}Response: $RESPONSE${RESET}"
        ;;

    *)
        echo -e "${RED}Error: Unknown service '$SERVICE'${RESET}"
        show_help
        exit 1
        ;;
esac
