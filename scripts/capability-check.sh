#!/bin/bash
#
# Capability Discovery Script
# Query agent capabilities across contexts
#
# Usage:
#   ./scripts/capability-check.sh [agent] [query]
#   ./scripts/capability-check.sh list
#   ./scripts/capability-check.sh compare [agent1] [agent2]
#

set -euo pipefail

CAPABILITIES_DIR="$HOME/devvyn-meta-project/agents/capabilities"
MANIFEST="$CAPABILITIES_DIR/manifest.yaml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Capability Discovery - Multi-Agent System

USAGE:
    $(basename "$0") list                           # List all agent contexts
    $(basename "$0") [agent]                        # Show agent summary
    $(basename "$0") [agent] [query]                # Query specific capability
    $(basename "$0") compare [agent1] [agent2]      # Compare two agents
    $(basename "$0") matrix [capability]            # Show capability matrix

AGENTS:
    code-cli        Claude Code CLI
    chat-desktop    Claude Chat Desktop
    chat-mobile     Claude Chat Mobile (iPhone)
    investigator    INVESTIGATOR Agent

EXAMPLES:
    $(basename "$0") code-cli
    $(basename "$0") code-cli "Can send bridge messages?"
    $(basename "$0") chat-mobile bridge_send
    $(basename "$0") compare code-cli chat-desktop
    $(basename "$0") matrix bridge_send

EOF
    exit 1
}

list_agents() {
    echo -e "${BLUE}Available Agent Contexts:${NC}\n"

    for yaml_file in "$CAPABILITIES_DIR"/*.yaml; do
        [[ "$(basename "$yaml_file")" == "manifest.yaml" ]] && continue

        agent_id=$(basename "$yaml_file" .yaml)
        agent_name=$(grep "^  name:" "$yaml_file" | head -1 | cut -d: -f2 | xargs)
        platform=$(grep "^  platform:" "$yaml_file" | head -1 | cut -d: -f2 | xargs)
        status=$(grep "^  status:" "$yaml_file" 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo "active")

        echo -e "  ${GREEN}$agent_id${NC}"
        echo -e "    Name: $agent_name"
        echo -e "    Platform: $platform"
        echo -e "    Status: $status"
        echo
    done
}

show_agent_summary() {
    local agent="$1"
    local file="$CAPABILITIES_DIR/${agent}.yaml"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: Agent '$agent' not found${NC}"
        echo "Run '$(basename "$0") list' to see available agents"
        exit 1
    fi

    echo -e "${BLUE}Capability Summary: $agent${NC}\n"

    # Agent info
    local name=$(grep "^  name:" "$file" | head -1 | cut -d: -f2- | xargs)
    local platform=$(grep "^  platform:" "$file" | head -1 | cut -d: -f2 | xargs)
    local runtime=$(grep "^  runtime:" "$file" | head -1 | cut -d: -f2- | xargs)

    echo -e "Name:     $name"
    echo -e "Platform: $platform"
    echo -e "Runtime:  $runtime"
    echo

    # Key capabilities
    echo -e "${BLUE}Capabilities:${NC}"

    check_capability "$file" "bridge_integration" "Bridge Integration"
    check_capability "$file" "file_operations" "File Operations"
    check_capability "$file" "command_execution" "Command Execution"
    check_capability "$file" "git_operations" "Git Operations"
    check_capability "$file" "web_access" "Web Access"
    check_capability "$file" "system_control" "System Control"

    echo

    # Unique strengths
    echo -e "${BLUE}Unique Strengths:${NC}"
    grep -A 10 "^unique_strengths:" "$file" | grep "^  - " | sed 's/^  - /  • /' || echo "  (See full file)"

    echo
    echo -e "${YELLOW}Full details: $file${NC}"
}

check_capability() {
    local file="$1"
    local capability="$2"
    local display_name="$3"

    if grep -q "^${capability}:" "$file"; then
        local status=$(grep -A 1 "^${capability}:" "$file" | grep "status:" | head -1 | cut -d: -f2 | xargs)

        case "$status" in
            full)
                echo -e "  ${GREEN}✓${NC} $display_name: Full"
                ;;
            limited|partial|read_only)
                # Capitalize first letter (compatible with older bash)
                status_cap="$(echo "${status:0:1}" | tr '[:lower:]' '[:upper:]')${status:1}"
                echo -e "  ${YELLOW}○${NC} $display_name: $status_cap"
                ;;
            none)
                echo -e "  ${RED}✗${NC} $display_name: None"
                ;;
            *)
                echo -e "  ${YELLOW}?${NC} $display_name: $status"
                ;;
        esac
    else
        echo -e "  ${RED}✗${NC} $display_name: Not documented"
    fi
}

query_capability() {
    local agent="$1"
    local query="$2"
    local file="$CAPABILITIES_DIR/${agent}.yaml"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: Agent '$agent' not found${NC}"
        exit 1
    fi

    echo -e "${BLUE}Query: $agent - $query${NC}\n"

    # Normalize query to capability key
    local capability_key=""
    case "$query" in
        *bridge*send*|*send*bridge*)
            capability_key="bridge_integration"
            section="send"
            ;;
        *bridge*receive*|*receive*bridge*)
            capability_key="bridge_integration"
            section="receive"
            ;;
        *bridge*)
            capability_key="bridge_integration"
            section=""
            ;;
        *file*write*|*write*file*)
            capability_key="file_operations"
            section="write"
            ;;
        *file*read*|*read*file*)
            capability_key="file_operations"
            section="read"
            ;;
        *file*)
            capability_key="file_operations"
            section=""
            ;;
        *git*)
            capability_key="git_operations"
            section=""
            ;;
        *web*|*search*)
            capability_key="web_access"
            section=""
            ;;
        *command*|*bash*|*shell*)
            capability_key="command_execution"
            section=""
            ;;
        *osascript*)
            capability_key="platform_specific"
            section="osascript"
            ;;
        *)
            # Try exact match
            if grep -q "^${query}:" "$file"; then
                capability_key="$query"
            else
                echo -e "${RED}Unknown query: $query${NC}"
                echo "Try: bridge_integration, file_operations, git_operations, web_access, command_execution"
                exit 1
            fi
            ;;
    esac

    # Extract and display
    if [[ -n "$section" ]]; then
        # Show specific section within capability
        echo "Section: $capability_key -> $section"
        echo
        grep -A 50 "^${capability_key}:" "$file" | grep -A 10 "^  ${section}:" | head -15
    else
        # Show entire capability
        grep -A 40 "^${capability_key}:" "$file" | head -35
    fi
}

compare_agents() {
    local agent1="$1"
    local agent2="$2"
    local file1="$CAPABILITIES_DIR/${agent1}.yaml"
    local file2="$CAPABILITIES_DIR/${agent2}.yaml"

    if [[ ! -f "$file1" ]] || [[ ! -f "$file2" ]]; then
        echo -e "${RED}Error: One or both agents not found${NC}"
        exit 1
    fi

    echo -e "${BLUE}Capability Comparison: $agent1 vs $agent2${NC}\n"

    printf "%-25s %-20s %-20s\n" "Capability" "$agent1" "$agent2"
    printf "%-25s %-20s %-20s\n" "----------" "$(printf '%*s' ${#agent1} '' | tr ' ' '-')" "$(printf '%*s' ${#agent2} '' | tr ' ' '-')"

    for cap in bridge_integration file_operations command_execution git_operations web_access system_control; do
        status1=$(grep -A 1 "^${cap}:" "$file1" | grep "status:" | head -1 | cut -d: -f2 | xargs || echo "unknown")
        status2=$(grep -A 1 "^${cap}:" "$file2" | grep "status:" | head -1 | cut -d: -f2 | xargs || echo "unknown")

        display_cap=$(echo "$cap" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

        printf "%-25s %-20s %-20s\n" "$display_cap" "$status1" "$status2"
    done

    echo
}

show_capability_matrix() {
    local capability="$1"

    echo -e "${BLUE}Capability Matrix: $capability${NC}\n"

    printf "%-20s %-15s %s\n" "Agent" "Status" "Notes"
    printf "%-20s %-15s %s\n" "-----" "------" "-----"

    for yaml_file in "$CAPABILITIES_DIR"/*.yaml; do
        [[ "$(basename "$yaml_file")" == "manifest.yaml" ]] && continue

        agent=$(basename "$yaml_file" .yaml)
        status=$(grep -A 1 "^${capability}:" "$yaml_file" | grep "status:" | head -1 | cut -d: -f2 | xargs || echo "unknown")

        # Get limitations or note if exists
        note=$(grep -A 5 "^${capability}:" "$yaml_file" | grep "limitations:" -A 1 | tail -1 | xargs | cut -c1-40 || echo "")

        printf "%-20s %-15s %s\n" "$agent" "$status" "$note"
    done

    echo

    # Show compatibility from manifest
    if grep -q "^  ${capability}:" "$MANIFEST" 2>/dev/null; then
        echo -e "${BLUE}From Manifest:${NC}"
        grep -A 10 "^  ${capability}:" "$MANIFEST" | grep ":" | head -5
    fi
}

# Main
case "${1:-}" in
    list)
        list_agents
        ;;
    compare)
        [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]] && usage
        compare_agents "$2" "$3"
        ;;
    matrix)
        [[ -z "${2:-}" ]] && usage
        show_capability_matrix "$2"
        ;;
    "")
        usage
        ;;
    *)
        agent="$1"
        if [[ -n "${2:-}" ]]; then
            query_capability "$agent" "$2"
        else
            show_agent_summary "$agent"
        fi
        ;;
esac

exit 0
