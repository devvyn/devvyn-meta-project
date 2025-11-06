#!/bin/bash
# surface-discover.sh - Discover available publication surfaces
# Usage: surface-discover.sh [--scope local|external|public] [--protocol file-based|http|...]

set -euo pipefail

REGISTRY_PATH="${HOME}/infrastructure/agent-bridge/bridge/registry/publication-surfaces.json"

# Color codes
BOLD="\033[1m"
DIM="\033[2m"
BLUE="\033[34m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# Parse arguments
SCOPE_FILTER=""
PROTOCOL_FILTER=""
STATUS_FILTER=""
OUTPUT_FORMAT="table" # table or json

while [[ $# -gt 0 ]]; do
    case $1 in
        --scope)
            SCOPE_FILTER="$2"
            shift 2
            ;;
        --protocol)
            PROTOCOL_FILTER="$2"
            shift 2
            ;;
        --status)
            STATUS_FILTER="$2"
            shift 2
            ;;
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --help)
            echo "Usage: surface-discover.sh [options]"
            echo ""
            echo "Options:"
            echo "  --scope <local|external|public>    Filter by scope"
            echo "  --protocol <protocol>              Filter by protocol"
            echo "  --status <active|planned>          Filter by status (external surfaces)"
            echo "  --json                             Output as JSON"
            echo "  --help                             Show this help"
            echo ""
            echo "Examples:"
            echo "  surface-discover.sh                         # List all surfaces"
            echo "  surface-discover.sh --scope local           # Only local surfaces"
            echo "  surface-discover.sh --protocol file-based   # Only file-based surfaces"
            echo "  surface-discover.sh --status planned        # Only planned surfaces"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if registry exists
if [[ ! -f "$REGISTRY_PATH" ]]; then
    echo "Error: Publication surface registry not found at $REGISTRY_PATH"
    exit 1
fi

# Function to extract surface data
extract_surfaces() {
    local surface_type=$1  # "surfaces" or "external_surfaces"
    local filter_scope=$2
    local filter_protocol=$3
    local filter_status=$4

    # Build jq filter
    local jq_filter=".${surface_type} | to_entries | map({key: .key, value: .value})"

    # Apply filters
    if [[ -n "$filter_scope" ]]; then
        jq_filter="${jq_filter} | map(select(.value.scope == \"$filter_scope\"))"
    fi

    if [[ -n "$filter_protocol" ]]; then
        jq_filter="${jq_filter} | map(select(.value.protocol == \"$filter_protocol\"))"
    fi

    if [[ -n "$filter_status" ]]; then
        jq_filter="${jq_filter} | map(select(.value.status == \"$filter_status\"))"
    fi

    jq -r "$jq_filter" "$REGISTRY_PATH"
}

# Output functions
output_table() {
    echo -e "${BOLD}Available Publication Surfaces${RESET}\n"

    # Local surfaces
    echo -e "${CYAN}━━━ Local Surfaces ━━━${RESET}"
    local surfaces=$(extract_surfaces "surfaces" "$SCOPE_FILTER" "$PROTOCOL_FILTER" "$STATUS_FILTER")

    if [[ "$surfaces" != "[]" ]]; then
        echo "$surfaces" | jq -r '.[] | "\(.key)|\(.value.protocol)|\(.value.description)"' | while IFS='|' read -r key protocol desc; do
            printf "${GREEN}%-25s${RESET} ${DIM}%-20s${RESET} %s\n" "$key" "[$protocol]" "$desc"
        done
    else
        echo -e "${DIM}No matching surfaces${RESET}"
    fi

    echo ""

    # External surfaces
    echo -e "${CYAN}━━━ External Surfaces ━━━${RESET}"
    local ext_surfaces=$(extract_surfaces "external_surfaces" "$SCOPE_FILTER" "$PROTOCOL_FILTER" "$STATUS_FILTER")

    if [[ "$ext_surfaces" != "[]" ]]; then
        echo "$ext_surfaces" | jq -r '.[] | "\(.key)|\(.value.protocol)|\(.value.status // "active")|\(.value.description)"' | while IFS='|' read -r key protocol status desc; do
            local status_color="$GREEN"
            [[ "$status" == "planned" ]] && status_color="$YELLOW"
            printf "${status_color}%-25s${RESET} ${DIM}%-20s${RESET} ${DIM}[%s]${RESET} %s\n" "$key" "[$protocol]" "$status" "$desc"
        done
    else
        echo -e "${DIM}No matching surfaces${RESET}"
    fi

    echo ""
    echo -e "${DIM}Use 'surface-info.sh <surface-name>' for detailed information${RESET}"
}

output_json() {
    jq '{
        local: (.surfaces | to_entries | map({key: .key, value: .value})),
        external: (.external_surfaces | to_entries | map({key: .key, value: .value}))
    }' "$REGISTRY_PATH"
}

# Main output
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    output_json
else
    output_table
fi
