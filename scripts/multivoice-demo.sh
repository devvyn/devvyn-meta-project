#!/bin/bash
#
# Multi-Voice TTS Demo Script
# Demonstrates single-voice vs multi-voice narration
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎙️  Multi-Voice TTS Demonstration"
echo "=================================="
echo ""

# Check if doc-to-audio.py exists
if [ ! -f "$SCRIPT_DIR/doc-to-audio.py" ]; then
    echo "❌ Error: doc-to-audio.py not found"
    exit 1
fi

# Create demo markdown if it doesn't exist
DEMO_FILE="/tmp/multivoice-demo.md"
cat > "$DEMO_FILE" << 'EOF'
# Multi-Voice Narration Demo

This is a demonstration of the multi-voice TTS system.

## Section One: Introduction

This section is narrated by Jamie in a warm British accent. The content is professional and engaging, perfect for long-form documentation.

### Code Example

Here's a simple Python function:

```python
def generate_audio(text, voice):
    """Generate TTS audio"""
    return tts_engine.synthesize(text, voice)
```

The code block above was described by Fred in a robotic voice.

### Important Quote

> "The best documentation is the documentation people actually read—or in this case, listen to."

That quote was delivered by Serena in an elegant British female voice.

## Section Two: Technical Details

This section header was announced by Lee in an Australian accent, providing a clear audio landmark for structural changes.

The multi-voice system automatically:
- Detects content types (headers, code, quotes)
- Assigns appropriate voices
- Stitches segments with natural pauses

## Conclusion

Multi-voice narration creates an engaging audio experience with distinct textures for different content types.
EOF

echo "📝 Demo document created: $DEMO_FILE"
echo ""

# Generate single-voice version
echo "🔹 Generating SINGLE-VOICE version..."
"$SCRIPT_DIR/doc-to-audio.py" \
    --input "$DEMO_FILE" \
    --output ~/Desktop/audio-comparison/single/ \
    --provider macos \
    --voice Jamie

SINGLE_SIZE=$(du -sh ~/Desktop/audio-comparison/single/ | cut -f1)
echo "✅ Single-voice complete: $SINGLE_SIZE"
echo ""

# Generate multi-voice version
echo "🔹 Generating MULTI-VOICE version..."
"$SCRIPT_DIR/doc-to-audio.py" \
    --input "$DEMO_FILE" \
    --output ~/Desktop/audio-comparison/multi/ \
    --provider macos \
    --multi-voice

MULTI_SIZE=$(du -sh ~/Desktop/audio-comparison/multi/ | cut -f1)
echo "✅ Multi-voice complete: $MULTI_SIZE"
echo ""

# Show comparison
echo "📊 Comparison:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Single Voice (Jamie only):     $SINGLE_SIZE"
echo "Multi-Voice (Jamie/Lee/Serena/Fred): $MULTI_SIZE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# List files
echo "📁 Files generated:"
echo ""
echo "Single-voice:"
ls -lh ~/Desktop/audio-comparison/single/*.mp3 | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Multi-voice:"
ls -lh ~/Desktop/audio-comparison/multi/*.mp3 | awk '{print "  " $9 " (" $5 ")"}'
echo ""

# Play instructions
echo "🎧 Listen to the results:"
echo ""
echo "  Single-voice:"
echo "    afplay ~/Desktop/audio-comparison/single/multivoice-demo_part001.mp3"
echo ""
echo "  Multi-voice:"
echo "    afplay ~/Desktop/audio-comparison/multi/multivoice-demo_part001.mp3"
echo ""
echo "✅ Demo complete!"
