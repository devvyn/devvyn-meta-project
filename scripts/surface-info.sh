#!/bin/bash
# surface-info.sh - Get detailed information about a publication surface
# Usage: surface-info.sh <surface-name>

set -euo pipefail

REGISTRY_PATH="${HOME}/infrastructure/agent-bridge/bridge/registry/publication-surfaces.json"

# Color codes
BOLD="\033[1m"
DIM="\033[2m"
BLUE="\033[34m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
MAGENTA="\033[35m"
RESET="\033[0m"

if [[ $# -lt 1 ]]; then
    echo "Usage: surface-info.sh <surface-name>"
    echo ""
    echo "Available surfaces:"
    "${BASH_SOURCE%/*}/surface-discover.sh" --json | jq -r '.local[].key, .external[].key' | sort
    exit 1
fi

SURFACE_NAME="$1"

# Check if registry exists
if [[ ! -f "$REGISTRY_PATH" ]]; then
    echo "Error: Publication surface registry not found at $REGISTRY_PATH"
    exit 1
fi

# Try to find surface in local or external
SURFACE_DATA=$(jq -r "(.surfaces[\"$SURFACE_NAME\"] // .external_surfaces[\"$SURFACE_NAME\"])" "$REGISTRY_PATH")

if [[ "$SURFACE_DATA" == "null" ]]; then
    echo "Error: Surface '$SURFACE_NAME' not found"
    echo ""
    echo "Available surfaces:"
    jq -r '.surfaces | keys[], .external_surfaces | keys[]' "$REGISTRY_PATH" | sort
    exit 1
fi

# Extract fields
NAME=$(echo "$SURFACE_DATA" | jq -r '.name')
PROTOCOL=$(echo "$SURFACE_DATA" | jq -r '.protocol')
LOCATION=$(echo "$SURFACE_DATA" | jq -r '.location_pattern')
DISCOVERY=$(echo "$SURFACE_DATA" | jq -r '.discovery_method')
ACCESS=$(echo "$SURFACE_DATA" | jq -r '.access_pattern')
PERSISTENCE=$(echo "$SURFACE_DATA" | jq -r '.persistence')
SCOPE=$(echo "$SURFACE_DATA" | jq -r '.scope')
STATUS=$(echo "$SURFACE_DATA" | jq -r '.status // "active"')
DESCRIPTION=$(echo "$SURFACE_DATA" | jq -r '.description')
PUBLISH_CMD=$(echo "$SURFACE_DATA" | jq -r '.publish_command')
CONSUME_CMD=$(echo "$SURFACE_DATA" | jq -r '.consume_command')
CAPABILITIES=$(echo "$SURFACE_DATA" | jq -r '.capabilities[]?' | tr '\n' ',' | sed 's/,$//')
USE_CASES=$(echo "$SURFACE_DATA" | jq -r '.use_cases[]?')
EXAMPLES=$(echo "$SURFACE_DATA" | jq -r '.examples[]?')

# Display formatted output
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}Publication Surface: $NAME${RESET}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"
echo ""

# Status indicator
if [[ "$STATUS" == "planned" ]]; then
    echo -e "${YELLOW}⚠ Status: PLANNED (not yet implemented)${RESET}"
    echo ""
fi

# Basic info
echo -e "${BOLD}Description:${RESET}"
echo -e "  $DESCRIPTION"
echo ""

echo -e "${BOLD}Technical Details:${RESET}"
printf "${GREEN}%-20s${RESET} %s\n" "Protocol:" "$PROTOCOL"
printf "${GREEN}%-20s${RESET} %s\n" "Scope:" "$SCOPE"
printf "${GREEN}%-20s${RESET} %s\n" "Location Pattern:" "$LOCATION"
printf "${GREEN}%-20s${RESET} %s\n" "Discovery Method:" "$DISCOVERY"
printf "${GREEN}%-20s${RESET} %s\n" "Access Pattern:" "$ACCESS"
printf "${GREEN}%-20s${RESET} %s\n" "Persistence:" "$PERSISTENCE"
echo ""

# Capabilities
if [[ -n "$CAPABILITIES" ]]; then
    echo -e "${BOLD}Capabilities:${RESET}"
    echo -e "  ${MAGENTA}$CAPABILITIES${RESET}"
    echo ""
fi

# Commands
echo -e "${BOLD}Usage:${RESET}"
echo -e "${CYAN}Publish:${RESET}"
echo -e "  ${DIM}$${RESET} $PUBLISH_CMD"
echo ""
echo -e "${CYAN}Consume:${RESET}"
echo -e "  ${DIM}$${RESET} $CONSUME_CMD"
echo ""

# Use cases
if [[ -n "$USE_CASES" ]]; then
    echo -e "${BOLD}Use Cases:${RESET}"
    echo "$USE_CASES" | while read -r use_case; do
        echo -e "  ${BLUE}•${RESET} $use_case"
    done
    echo ""
fi

# Examples
if [[ -n "$EXAMPLES" ]]; then
    echo -e "${BOLD}Examples:${RESET}"
    echo "$EXAMPLES" | while read -r example; do
        echo -e "  ${DIM}$example${RESET}"
    done
    echo ""
fi

# Related surfaces (same protocol)
RELATED=$(jq -r "(.surfaces, .external_surfaces) | to_entries[] | select(.value.protocol == \"$PROTOCOL\" and .key != \"$SURFACE_NAME\") | .key" "$REGISTRY_PATH" 2>/dev/null | head -5)

if [[ -n "$RELATED" ]]; then
    echo -e "${BOLD}Related Surfaces (same protocol):${RESET}"
    echo "$RELATED" | while read -r related; do
        echo -e "  ${DIM}•${RESET} $related ${DIM}(use 'surface-info.sh $related' for details)${RESET}"
    done
    echo ""
fi

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"
