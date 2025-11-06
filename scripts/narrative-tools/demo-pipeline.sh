#!/bin/bash
#
# Demo: Simulacrum Story to Audio Pipeline
#
# Demonstrates end-to-end workflow:
# 1. Story with character voice tags (already written)
# 2. Character voice allocation (dynamic)
# 3. Multi-voice audio generation
#
# Usage: ./demo-pipeline.sh

set -e  # Exit on error

echo "=========================================="
echo "SIMULACRUM STORY → AUDIO PIPELINE DEMO"
echo "=========================================="
echo ""

# Configuration
INPUT_STORY="../../examples/simulacrum-stories/simple-dialogue-test.md"
OUTPUT_DIR="../../audio-assets/demo-story"
NARRATOR="Aman"

# Verify input exists
if [ ! -f "$INPUT_STORY" ]; then
    echo "Error: Input story not found: $INPUT_STORY"
    exit 1
fi

echo "Input Story: $INPUT_STORY"
echo "Output Directory: $OUTPUT_DIR"
echo "Narrator Voice: $NARRATOR"
echo ""

# Step 1: Validate voice tags
echo "=========================================="
echo "STEP 1: Validating Voice Tags"
echo "=========================================="
echo ""

python3 story_to_audio.py \
    --input "$INPUT_STORY" \
    --validate-only \
    --narrator "$NARRATOR"

echo ""

# Step 2: Show character-to-voice mapping
echo "=========================================="
echo "STEP 2: Character Voice Allocation"
echo "=========================================="
echo ""

python3 story_to_audio.py \
    --input "$INPUT_STORY" \
    --show-mapping \
    --narrator "$NARRATOR"

echo ""

# Step 3: Generate audio
echo "=========================================="
echo "STEP 3: Generating Multi-Voice Audio"
echo "=========================================="
echo ""

echo "Options:"
echo "  [1] Basic multi-voice (default)"
echo "  [2] Advanced mixing (crossfading + normalization)"
echo "  [3] Conservative (code-only voice changes + long pauses)"
echo ""
read -p "Select option [1-3, default=2]: " OPTION
OPTION=${OPTION:-2}

case $OPTION in
    1)
        echo "Using basic multi-voice..."
        python3 story_to_audio.py \
            --input "$INPUT_STORY" \
            --output "$OUTPUT_DIR" \
            --narrator "$NARRATOR" \
            --auto-detect-characters
        ;;
    2)
        echo "Using advanced mixing..."
        python3 story_to_audio.py \
            --input "$INPUT_STORY" \
            --output "$OUTPUT_DIR" \
            --narrator "$NARRATOR" \
            --auto-detect-characters \
            --advanced-mixing
        ;;
    3)
        echo "Using conservative mode..."
        python3 story_to_audio.py \
            --input "$INPUT_STORY" \
            --output "$OUTPUT_DIR" \
            --narrator "$NARRATOR" \
            --auto-detect-characters \
            --conservative-pauses
        ;;
    *)
        echo "Invalid option. Using default (advanced mixing)..."
        python3 story_to_audio.py \
            --input "$INPUT_STORY" \
            --output "$OUTPUT_DIR" \
            --narrator "$NARRATOR" \
            --auto-detect-characters \
            --advanced-mixing
        ;;
esac

echo ""

# Step 4: Show results
echo "=========================================="
echo "STEP 4: Results"
echo "=========================================="
echo ""

if [ -d "$OUTPUT_DIR" ]; then
    echo "Output files:"
    ls -lh "$OUTPUT_DIR"
    echo ""

    # Count MP3 files
    MP3_COUNT=$(find "$OUTPUT_DIR" -name "*.mp3" | wc -l | tr -d ' ')

    if [ "$MP3_COUNT" -gt 0 ]; then
        echo "✓ Successfully generated $MP3_COUNT audio file(s)"

        # Show total size
        TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
        echo "✓ Total size: $TOTAL_SIZE"

        # Offer to play
        echo ""
        read -p "Play audio? [y/N]: " PLAY
        if [ "$PLAY" = "y" ] || [ "$PLAY" = "Y" ]; then
            for mp3 in "$OUTPUT_DIR"/*.mp3; do
                echo "Playing: $(basename "$mp3")"
                open "$mp3"  # macOS
                # Alternative: afplay "$mp3"
            done
        fi
    else
        echo "✗ No audio files generated"
        exit 1
    fi
else
    echo "✗ Output directory not created"
    exit 1
fi

echo ""
echo "=========================================="
echo "DEMO COMPLETE"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  - Modify the story: $INPUT_STORY"
echo "  - Add more characters with <VOICE:CHARACTER_Name> tags"
echo "  - Create character profiles in JSON"
echo "  - Generate worlds with LLM (coming soon)"
echo "  - Extract narratives from simulations (coming soon)"
echo ""
echo "Documentation:"
echo "  - Narrative tools: scripts/narrative-tools/README.md"
echo "  - Design pattern: knowledge-base/narrative-generation/simulacrum-to-audio-design-pattern.md"
echo "  - Research: knowledge-base/narrative-generation/"
echo ""
