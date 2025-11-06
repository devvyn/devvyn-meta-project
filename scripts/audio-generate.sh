#!/usr/bin/env bash
#
# audio-generate.sh - Intelligent audio generation with automatic budget routing
#
# Usage:
#   ./audio-generate.sh doc.md                    # Auto-route based on content
#   ./audio-generate.sh doc.md --provider macos   # Force provider
#   ./audio-generate.sh docs/**/*.md              # Batch process
#
# Features:
#   - Automatic content-type detection (premium vs draft)
#   - Budget quota checking (daily/monthly limits)
#   - Intelligent fallback (draft now, queue premium for later)
#   - Real-time status updates
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIO_ROUTER="$SCRIPT_DIR/audio_router.py"
DOC_TO_AUDIO="$SCRIPT_DIR/doc-to-audio.py"
BUDGET_MANAGER="$SCRIPT_DIR/audio-budget-manager.py"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show budget status before generation
show_budget_status() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 Current Budget Status${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    "$BUDGET_MANAGER" status | grep -A 8 "AUDIO BUDGET STATUS"
    echo ""
}

# Route and generate audio for single file
generate_audio() {
    local doc_path="$1"
    shift
    local extra_args=("$@")

    if [[ ! -f "$doc_path" ]]; then
        echo -e "${RED}Error: File not found: $doc_path${NC}"
        return 1
    fi

    echo -e "${GREEN}🎙️  Processing: $(basename "$doc_path")${NC}"

    # Use audio router for intelligent routing
    python3 "$AUDIO_ROUTER" "$doc_path" "${extra_args[@]}"

    echo -e "${GREEN}✅ Complete${NC}"
    echo ""
}

# Main
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <file.md> [options]"
        echo ""
        echo "Options:"
        echo "  --provider <macos|elevenlabs|openai>   Force specific provider"
        echo "  --multi-voice                            Enable multi-voice narration"
        echo "  --advanced-mixing                        Enable crossfading & normalization"
        echo "  --status                                 Show budget status and exit"
        echo ""
        echo "Examples:"
        echo "  $0 doc.md                                Auto-route based on content"
        echo "  $0 doc.md --provider macos               Force macOS (free)"
        echo "  $0 doc.md --multi-voice --advanced-mixing  Premium quality"
        echo "  $0 docs/**/*.md                          Batch process directory"
        exit 1
    fi

    # Handle --status flag
    if [[ "$1" == "--status" ]]; then
        "$BUDGET_MANAGER" status
        exit 0
    fi

    # Show budget status
    show_budget_status

    # Process files
    local doc_paths=()
    local extra_args=()
    local in_extra_args=false

    for arg in "$@"; do
        if [[ "$arg" == --* ]]; then
            in_extra_args=true
            extra_args+=("$arg")
        elif [[ "$in_extra_args" == true ]]; then
            extra_args+=("$arg")
        else
            # Expand glob patterns
            for file in $arg; do
                if [[ -f "$file" ]]; then
                    doc_paths+=("$file")
                fi
            done
        fi
    done

    if [[ ${#doc_paths[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No files found${NC}"
        exit 1
    fi

    echo -e "${BLUE}Processing ${#doc_paths[@]} file(s)${NC}"
    echo ""

    # Generate audio for each file
    for doc_path in "${doc_paths[@]}"; do
        generate_audio "$doc_path" "${extra_args[@]}"
    done

    # Show final budget status
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 Final Budget Status${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    "$BUDGET_MANAGER" status | grep -A 6 "Daily Usage"
    echo ""

    echo -e "${GREEN}✅ All files processed${NC}"
}

main "$@"
