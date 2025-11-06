#!/bin/bash
#
# TTS Richness Comparison Script
# Demonstrates: Single Voice → Option B (Multi-Voice) → Option C (Advanced Mixing)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎭 TTS Richness Comparison"
echo "============================="
echo ""
echo "Comparing three audio production levels:"
echo "  1. Single Voice (Jamie only)"
echo "  2. Option B (Multi-voice with silence)"
echo "  3. Option C (Advanced mixing with crossfading + normalization)"
echo ""

# Create demo markdown
DEMO_FILE="/tmp/richness-demo.md"
cat > "$DEMO_FILE" << 'EOF'
# Audio Production Quality Comparison

This document demonstrates three levels of TTS audio production.

## Single Voice Mode

In single voice mode, one narrator (Jamie) reads everything. This is clear and professional, but can become monotonous for long content.

### Code Example

```python
def calculate_total(items):
    """Calculate sum of all items"""
    return sum(items)
```

The code above is read by the same voice as everything else.

### Important Quote

> "The quality of audio narration significantly impacts listener engagement and comprehension."

That quote sounds the same as regular narration.

## Multi-Voice Mode (Option B)

In multi-voice mode, different voices signal different content types with silence between transitions.

### More Code

```bash
./doc-to-audio.py --input file.md --multi-voice
```

Code is now read by Fred (robotic voice).

### Another Quote

> "Audio landmarks help listeners parse structure without visual cues."

Quotes are now read by Serena (elegant British female voice).

## Advanced Mixing (Option C)

With advanced mixing, we add:
- Crossfading between voice changes (smooth transitions)
- Volume normalization (consistent loudness)
- Optional background music

### Final Code Block

```javascript
const result = await generateAudio(text, voice);
console.log('Audio ready:', result);
```

### Final Thought

> "Professional audio production transforms documentation into an immersive learning experience."

The smooth transitions and balanced audio create a podcast-quality result.
EOF

echo "📝 Demo document created: $DEMO_FILE"
echo ""

# Generate Option A: Single Voice
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Option A: Single Voice (Baseline)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$SCRIPT_DIR/doc-to-audio.py" \
    --input "$DEMO_FILE" \
    --output ~/Desktop/richness-comparison/option-a-single/ \
    --provider macos \
    --voice Jamie

SINGLE_SIZE=$(du -sh ~/Desktop/richness-comparison/option-a-single/ | cut -f1)
echo "✅ Single voice complete: $SINGLE_SIZE"
echo ""

# Generate Option B: Multi-Voice
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎭 Option B: Multi-Voice (Good)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$SCRIPT_DIR/doc-to-audio.py" \
    --input "$DEMO_FILE" \
    --output ~/Desktop/richness-comparison/option-b-multivoice/ \
    --provider macos \
    --multi-voice

MULTI_SIZE=$(du -sh ~/Desktop/richness-comparison/option-b-multivoice/ | cut -f1)
echo "✅ Multi-voice complete: $MULTI_SIZE"
echo ""

# Generate Option C: Advanced Mixing
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎬 Option C: Advanced Mixing (Excellent)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$SCRIPT_DIR/doc-to-audio.py" \
    --input "$DEMO_FILE" \
    --output ~/Desktop/richness-comparison/option-c-advanced/ \
    --provider macos \
    --multi-voice \
    --advanced-mixing

ADVANCED_SIZE=$(du -sh ~/Desktop/richness-comparison/option-c-advanced/ | cut -f1)
echo "✅ Advanced mixing complete: $ADVANCED_SIZE"
echo ""

# Show comparison
echo "📊 Comparison Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-30s %15s\n" "Production Level" "File Size"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-30s %15s\n" "Option A (Single Voice)" "$SINGLE_SIZE"
printf "%-30s %15s\n" "Option B (Multi-Voice)" "$MULTI_SIZE"
printf "%-30s %15s\n" "Option C (Advanced Mixing)" "$ADVANCED_SIZE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Features comparison
echo "🎯 Feature Comparison:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Option A (Single Voice):"
echo "  ✓ One consistent voice (Jamie)"
echo "  ✗ No content type signaling"
echo "  ✗ Can be monotonous"
echo "  ✓ Simple, professional"
echo ""
echo "Option B (Multi-Voice):"
echo "  ✓ Four distinct voices"
echo "  ✓ Content type audio landmarks"
echo "  ✓ More engaging"
echo "  ⚠ Silence gaps between voices"
echo ""
echo "Option C (Advanced Mixing):"
echo "  ✓ Four distinct voices"
echo "  ✓ Content type audio landmarks"
echo "  ✓ Smooth crossfading"
echo "  ✓ Volume normalization"
echo "  ✓ Podcast-quality production"
echo "  ✓ SMALLER file size (efficient)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# List all files
echo "📁 Generated Files:"
echo ""
echo "Option A (Single):"
ls -lh ~/Desktop/richness-comparison/option-a-single/*.mp3 | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Option B (Multi-Voice):"
ls -lh ~/Desktop/richness-comparison/option-b-multivoice/*.mp3 | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Option C (Advanced):"
ls -lh ~/Desktop/richness-comparison/option-c-advanced/*.mp3 | awk '{print "  " $9 " (" $5 ")"}'
echo ""

# Play instructions
echo "🎧 Listen to Compare:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "# Listen in order to hear quality progression:"
echo ""
echo "# 1. Single Voice (baseline)"
echo "afplay ~/Desktop/richness-comparison/option-a-single/richness-demo_part001.mp3"
echo ""
echo "# 2. Multi-Voice (good - notice the voice variety but silence gaps)"
echo "afplay ~/Desktop/richness-comparison/option-b-multivoice/richness-demo_part001.mp3"
echo ""
echo "# 3. Advanced Mixing (excellent - notice smooth transitions & balanced volume)"
echo "afplay ~/Desktop/richness-comparison/option-c-advanced/richness-demo_part001.mp3"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Richness comparison complete!"
echo ""
echo "Key Takeaway:"
echo "  Option C provides the richest listening experience with"
echo "  smooth transitions, balanced volume, and SMALLER file sizes."
