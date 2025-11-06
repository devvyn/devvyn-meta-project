#!/bin/bash
#
# Batch Audio Production Script
# Processes multiple stories in sequence
#

set -e

STORIES_DIR="../../examples/simulacrum-stories"
OUTPUT_BASE=~/Desktop/story-collection
NARRATOR="Aman"

mkdir -p "$OUTPUT_BASE"

echo "=========================================="
echo "BATCH AUDIO PRODUCTION"
echo "=========================================="
echo ""

# Array of stories to process
stories=(
    "the-last-bookmark"
    "dispatch-from-mars"
    "the-demon-sommelier"
    "the-39th-floor"
    "tea-with-death"
    "the-algorithm-that-learned-to-lie"
)

total=${#stories[@]}
current=0
success=0
failed=0

for story in "${stories[@]}"; do
    current=$((current + 1))
    echo "[$current/$total] Processing: $story"
    echo "----------------------------------------"

    output_dir="$OUTPUT_BASE/$story"

    if ./story_to_audio.py \
        --input "$STORIES_DIR/${story}.md" \
        --output "$output_dir" \
        --auto-detect-characters \
        --narrator "$NARRATOR" \
        --advanced-mixing; then

        echo "✓ Success: $story"
        success=$((success + 1))
    else
        echo "✗ Failed: $story"
        failed=$((failed + 1))
    fi

    echo ""
done

echo "=========================================="
echo "BATCH COMPLETE"
echo "=========================================="
echo "Processed: $total stories"
echo "Success: $success"
echo "Failed: $failed"
echo ""
echo "Output: $OUTPUT_BASE/"
