# Multi-Voice TTS Narration System

**Implemented**: 2025-10-30
**Status**: ✅ Production Ready

## Overview

The multi-voice narration system automatically switches between different voices for different content types, creating distinct audio textures that enhance comprehension and engagement.

## Voice Palette (Non-US English Preference)

| Content Type | Voice | Gender | Accent | Quality | Purpose |
|-------------|-------|--------|--------|---------|---------|
| **Narration** | Jamie | Male | 🇬🇧 British | Premium | Warm, professional main content |
| **Headers** | Lee | Male | 🇦🇺 Australian | Premium | Structural markers, different accent |
| **Code Blocks** | Fred | Male | 🇺🇸 US | Basic | Robotic, technical (intentional contrast) |
| **Quotes** | Serena | Female | 🇬🇧 British | Premium | Elegant, feminine emphasis |

### Why These Voices?

- **Jamie (Narration)**: Premium UK voice, warm and professional without being boring. Perfect for long-form listening.
- **Lee (Headers)**: Australian accent provides clear structural distinction without being jarring.
- **Fred (Code)**: Intentionally robotic/technical sounding to signal "this is code/technical content".
- **Serena (Quotes)**: Premium UK female voice provides gender contrast and elegance for quoted material.

## Quick Start

### Basic Usage

```bash
# Single file with multi-voice
./scripts/doc-to-audio.py \
  --input docs/guide.md \
  --output audio/ \
  --provider macos \
  --multi-voice

# Directory with multi-voice
./scripts/doc-to-audio.py \
  --input docs/tools/ \
  --output audio/multivoice/ \
  --provider macos \
  --multi-voice \
  --recursive
```

### Compare Single vs Multi-Voice

```bash
# Single voice (Jamie only)
./scripts/doc-to-audio.py \
  --input test.md \
  --output audio/single/ \
  --provider macos \
  --voice Jamie

# Multi-voice (Jamie/Lee/Serena/Fred)
./scripts/doc-to-audio.py \
  --input test.md \
  --output audio/multi/ \
  --provider macos \
  --multi-voice
```

## How It Works

### 1. Content Tagging Phase

The `MarkdownCleaner.clean_with_tags()` method identifies and tags different content types:

```markdown
# Introduction              → <VOICE:HEADER>Section: Introduction.</VOICE:HEADER>

Regular paragraph text...  → (untagged = narration)

```python                   → <VOICE:CODE>[Python code example]</VOICE:CODE>
code here
```

> "Quoted text"            → <VOICE:QUOTE>Quoted text</VOICE:QUOTE>
```

### 2. Segment Parsing

`MultiVoiceTTS.parse_segments()` splits tagged text into voice-specific segments:

```python
[
  ("Jamie", "This is the introduction..."),
  ("Lee", "Section: Implementation."),
  ("Jamie", "The system works by..."),
  ("Fred", "[Python code example]"),
  ("Jamie", "As you can see..."),
  ("Serena", "The best code is no code at all."),
  ("Jamie", "This concludes...")
]
```

### 3. Audio Generation

Each segment is generated with its assigned voice using macOS `say` command:

```bash
say -v Jamie "This is the introduction..." -o segment_0001.aiff
say -v Lee "Section: Implementation." -o segment_0002.aiff
say -v Fred "[Python code example]" -o segment_0003.aiff
```

AIFF files are converted to MP3 using ffmpeg.

### 4. Stitching with Silence

Segments are concatenated with 300ms silence between each:

```
segment_0001.mp3 → 300ms silence → segment_0002.mp3 → 300ms silence → ...
```

This creates natural pauses between voice transitions.

## Technical Architecture

### Key Classes

#### `VoiceMapper`
Maps content types to voice names:

```python
voice_map = {
    "NARRATION": "Jamie",  # Default for unmarked text
    "HEADER": "Lee",       # Section/subsection/topic markers
    "CODE": "Fred",        # Code blocks
    "QUOTE": "Serena",     # Blockquotes
}
```

#### `MultiVoiceTTS`
Orchestrates multi-voice generation:

```python
class MultiVoiceTTS:
    def parse_segments(text) -> [(voice, content)]
    def generate_multivoice(text, output_path)
    def _stitch_audio(segments, output)
```

#### `MarkdownCleaner`
Handles content tagging:

```python
def clean_with_tags(markdown) -> str:
    # Tags code blocks, quotes, headers
    # Returns text with <VOICE:TYPE>...</VOICE:TYPE> markers
```

### Implementation Details

**Total Lines Added**: ~180 LOC
**Complexity**: Medium (regex parsing, subprocess orchestration)
**Dependencies**: ffmpeg (already required)

## Quality Comparison

### Single Voice (Jamie)
```
[Jamie] This is section one about authentication.
[Jamie] Code example omitted.
[Jamie] As the docs state, always validate input.
```

**Pros**: Consistent, professional
**Cons**: Monotonous for long content, no structural markers

### Multi-Voice (Jamie/Lee/Serena/Fred)
```
[Lee] Section: Authentication.
[Jamie] This section covers authentication strategies.
[Fred] Code example omitted.
[Jamie] As the documentation states,
[Serena] Always validate user input.
[Jamie] This ensures security.
```

**Pros**:
- ✅ Audio landmarks for structure
- ✅ Engagement through variety
- ✅ Gender/accent diversity
- ✅ Content type signaling

**Cons**:
- ⚠️ Slightly larger file size (~10% more)
- ⚠️ Longer generation time (~2x)

## Use Cases

### Perfect For:

1. **Technical Documentation**
   - Code examples clearly differentiated
   - Section headers announce structure
   - Quotes emphasize important points

2. **Long-Form Content**
   - Breaks up monotony
   - Provides audio landmarks
   - Helps maintain attention

3. **Educational Material**
   - Different voices = different content types
   - Easier to follow along
   - Better retention

4. **Accessibility**
   - Richer audio experience
   - Clearer content boundaries
   - More engaging for screen reader users

### Not Ideal For:

1. **Short Documents** (<1000 words)
   - Voice switching overhead not worth it
   - Single voice sufficient

2. **Narrative Content** (stories, blogs)
   - Voice changes may be distracting
   - Single voice maintains narrative flow

## Examples

### Example 1: Technical Guide

```bash
# Convert coordination system docs with multi-voice
./scripts/doc-to-audio.py \
  --input docs/tools/coord-init.md \
  --output audio/multivoice/ \
  --provider macos \
  --multi-voice
```

**Output**:
- Headers (Lee): "Section: Configuration Generator", "Subsection: Usage"
- Narration (Jamie): Main explanatory text
- Code (Fred): All bash/YAML examples
- Quotes (Serena): Important notes and warnings

### Example 2: Phase Summaries

```bash
# Phase 5 completion with multi-voice
./scripts/doc-to-audio.py \
  --input /tmp/phase5-completion-summary.md \
  --output ~/Desktop/phase-summaries-multivoice/ \
  --provider macos \
  --multi-voice
```

**Result**:
- 14MB (3 parts)
- ~12 minutes
- Clear voice transitions between sections
- Code examples in Fred's robotic voice
- Key insights in Serena's voice (if quoted)

### Example 3: Full Documentation Site

```bash
# Convert entire docs/ with multi-voice
./scripts/doc-to-audio.py \
  --input docs/ \
  --recursive \
  --output audio/docs-multivoice/ \
  --provider macos \
  --multi-voice
```

**Estimate**:
- Time: 2-3 hours (generation time)
- Size: ~500MB for full docs
- Quality: Premium voices throughout
- Cost: **FREE** (macOS native)

## Performance

### Generation Time

| Mode | Time per 1000 words | Total for Phase 5 |
|------|---------------------|-------------------|
| Single Voice | ~30 seconds | ~2 minutes |
| Multi-Voice | ~60 seconds | ~4 minutes |

**Slowdown**: 2x (due to segment generation + stitching)
**Worth it**: Yes, for content >2000 words

### File Size

| Mode | Phase 5 Summary |
|------|-----------------|
| Single Voice | 12.4 MB |
| Multi-Voice | 14.0 MB |

**Increase**: ~10-15% (silence padding + multiple voice models)

## Customization

### Change Voice Palette

Edit `VoiceMapper.__init__()` in `doc-to-audio.py`:

```python
self.voice_map = {
    "NARRATION": "Stephanie",  # Enhanced UK female
    "HEADER": "Moira",         # Enhanced Irish
    "CODE": "Fred",            # Keep robotic
    "QUOTE": "Lee",            # Premium AU male
}
```

### Adjust Silence Duration

Edit `MultiVoiceTTS._stitch_audio()`:

```python
# Change from 300ms to 500ms
"-t", "0.5",  # Was: "0.3"
```

### Add Content Types

1. Add tag in `MarkdownCleaner`:
```python
def _tag_tables(self, text: str) -> str:
    return re.sub(r"(\|.+\|\n)+",
                  r"<VOICE:TABLE>\1</VOICE:TABLE>",
                  text, flags=re.MULTILINE)
```

2. Add voice mapping:
```python
self.voice_map = {
    ...
    "TABLE": "Daniel",  # British male for tables
}
```

## Limitations

### Current Limitations

1. **macOS Only**
   - Multi-voice requires macOS `say` command
   - 11 Labs/OpenAI support planned but not implemented

2. **Voice Selection**
   - Fixed palette (Jamie/Lee/Serena/Fred)
   - Manual code edit to change

3. **No Inline Voice Changes**
   - Can't switch voice mid-paragraph
   - Content type = voice (1:1 mapping)

### Planned Enhancements

1. **11 Labs Multi-Voice**
   - Use voice IDs for different content types
   - Higher quality but uses API quota

2. **Configurable Voice Maps**
   - `--voice-map config.json`
   - User-defined content → voice mappings

3. **Dynamic Silence**
   - Shorter silence for same-voice transitions
   - Longer silence for voice changes

4. **Voice Preview**
   - `--preview-voices` flag
   - Generates test audio with all voices

## FAQ

### Q: Can I use this with 11 Labs?

**A**: Not yet. Current implementation uses macOS-specific voice switching. 11 Labs support planned for future release.

### Q: Does multi-voice work offline?

**A**: Yes! Uses macOS native TTS, works completely offline.

### Q: How do I know which voice is which?

**A**: Run `say -v '?'` to hear each voice introduce itself:

```bash
say -v Jamie "Hello! My name is Jamie."
say -v Lee "Hello! My name is Lee."
say -v Serena "Hello! My name is Serena."
say -v Fred "Hello, my name is Fred."
```

### Q: Can I use all female voices?

**A**: Yes! Edit `VoiceMapper`:

```python
self.voice_map = {
    "NARRATION": "Serena",    # Premium UK
    "HEADER": "Moira",        # Enhanced Irish
    "CODE": "Kathy",          # Basic US (soft)
    "QUOTE": "Stephanie",     # Enhanced UK
}
```

### Q: Why is Fred robotic sounding?

**A**: Intentional! The robotic quality signals "this is technical/code content", creating a clear audio distinction.

### Q: Does this work with existing audio files?

**A**: No. Multi-voice is generated during conversion. Existing single-voice files would need to be regenerated.

## Troubleshooting

### Issue: "Voice not found"

```
Error: Voice 'Jamie' not found
```

**Solution**: Voice not downloaded. Check available voices:

```bash
say -v '?' | grep -E 'en_GB|en_AU'
```

Download from: System Settings → Accessibility → Spoken Content → System Voice → Manage Voices

### Issue: "Multi-voice only supported with macOS provider"

```
ValueError: Multi-voice currently only supported with macOS provider
```

**Solution**: Use `--provider macos`:

```bash
./scripts/doc-to-audio.py --provider macos --multi-voice ...
```

### Issue: Choppy audio / cuts between segments

**Cause**: ffmpeg concat issue or temp file cleanup race condition

**Solution**: Increase silence duration (gives ffmpeg more buffer):

```python
# In _stitch_audio():
"-t", "0.5",  # Increase from 0.3 to 0.5
```

### Issue: Some voices sound different than expected

**Cause**: macOS has multiple variants of same voice name

**Solution**: Specify full voice name with quality tier:

```python
"NARRATION": "Jamie (Premium)",  # Not just "Jamie"
```

## Conclusion

The multi-voice narration system transforms static documentation into engaging audio content with:

- ✅ **FREE**: No API costs, completely offline
- ✅ **Premium Quality**: Uses macOS Siri-quality voices
- ✅ **Automatic**: No manual voice switching needed
- ✅ **Non-US Accents**: British/Australian preference respected
- ✅ **Production Ready**: Tested on Phase summaries

**Best for**: Technical documentation, long-form content, educational material

**Try it**:
```bash
./scripts/doc-to-audio.py \
  --input your-doc.md \
  --output audio/ \
  --provider macos \
  --multi-voice
```

---

**Last Updated**: 2025-10-30
**Version**: 1.0
**Implementation**: Option B (Full Production)
