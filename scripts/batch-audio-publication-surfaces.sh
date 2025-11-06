#!/bin/bash
# batch-audio-publication-surfaces.sh
# Convert publication surface documentation to multi-voice audio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${HOME}/Desktop/audio-publication-surfaces"

# Color codes
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${BLUE}Publication Surfaces Audio Production Batch${RESET}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Files to convert
declare -a files=(
    "/Users/devvynmurphy/Desktop/2025110100-PST-publication-surfaces-implementation-summary.md"
    "/Users/devvynmurphy/devvyn-meta-project/knowledge-base/patterns/publication-surfaces.md"
    "/Users/devvynmurphy/devvyn-meta-project/examples/publication-surface-workflows.md"
)

total=${#files[@]}
current=0
success=0
failed=0

for file in "${files[@]}"; do
    ((current++))

    if [[ ! -f "$file" ]]; then
        echo -e "${YELLOW}[$current/$total] File not found: $(basename "$file")${RESET}"
        ((failed++))
        continue
    fi

    echo -e "${GREEN}[$current/$total] Converting: $(basename "$file")${RESET}"

    if python3 "${SCRIPT_DIR}/doc-to-audio.py" \
        --input "$file" \
        --output "$OUTPUT_DIR" \
        --provider macos \
        --multi-voice \
        --narrator Jamie; then
        ((success++))
        echo -e "${GREEN}✓ Complete${RESET}"
    else
        ((failed++))
        echo -e "${YELLOW}✗ Failed${RESET}"
    fi

    echo ""
done

# Summary
echo -e "${BLUE}═══════════════════════════════════════${RESET}"
echo -e "${GREEN}Success: $success${RESET}"
[[ $failed -gt 0 ]] && echo -e "${YELLOW}Failed: $failed${RESET}"
echo -e "${BLUE}Output: $OUTPUT_DIR${RESET}"
echo ""

# List generated files
if [[ $success -gt 0 ]]; then
    echo -e "${BLUE}Generated files:${RESET}"
    ls -lh "$OUTPUT_DIR"/*.mp3 2>/dev/null || echo "No MP3 files found"
fi
