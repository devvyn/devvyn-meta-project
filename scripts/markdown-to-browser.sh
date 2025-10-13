#!/bin/bash
# Convert markdown to HTML and open in browser
# Usage: ./markdown-to-browser.sh input.md [output-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <markdown-file> [output-name]"
    echo "Example: $0 README.md"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_NAME="${2:-$(basename "$INPUT_FILE" .md)}"
TIMESTAMP=$(date +%Y%m%d%H%M%S%z)
OUTPUT_FILE="/tmp/${TIMESTAMP}-${OUTPUT_NAME}.html"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

# Convert markdown to HTML
python3 "$SCRIPT_DIR/md2html.py" "$INPUT_FILE" "$OUTPUT_FILE" "$OUTPUT_NAME"

# Open in browser
open "$OUTPUT_FILE"

echo "✅ Opened in browser: $OUTPUT_FILE"
