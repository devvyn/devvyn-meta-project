# Audio Documentation Setup

**Convert documentation to high-quality spoken audio**

Perfect for:
- 🎧 Passive listening while working
- 💤 Falling asleep to interesting technical content
- 🚗 Commuting / driving
- 🏃 Exercise / walking
- 📚 Accessibility (vision impairment, reading fatigue)
- 🌍 Sharing with wider audience (podcast-style)

---

## Quick Start

### 1. Install Dependencies

```bash
# Install Python packages
pip install elevenlabs  # For 11 Labs (recommended)
# OR
pip install openai  # For OpenAI TTS (alternative)

# Optional: Rich for better UI
pip install rich
```

### 2. Set API Key

#### 11 Labs (Recommended - Most Natural)

```bash
# Get API key from: https://elevenlabs.io/
export ELEVEN_LABS_API_KEY="your_api_key_here"

# Add to ~/.zshrc to persist
echo 'export ELEVEN_LABS_API_KEY="your_key"' >> ~/.zshrc
```

#### OpenAI TTS (Good Alternative)

```bash
# Use existing OpenAI API key
export OPENAI_API_KEY="your_api_key_here"
```

### 3. Convert Documentation

```bash
# Single file
./scripts/doc-to-audio.py --input docs/tools/coord-init.md --output audio/

# Entire directory
./scripts/doc-to-audio.py --input docs/tools/ --output audio/

# Recursive (all subdirectories)
./scripts/doc-to-audio.py --input docs/ --recursive --output audio/
```

---

## Usage Examples

### Example 1: Convert Tools Documentation

```bash
# Generate audio for all tool docs
cd ~/devvyn-meta-project

./scripts/doc-to-audio.py \
  --input docs/tools/ \
  --output audio/tools/ \
  --provider elevenlabs \
  --voice Adam  # Male, natural voice
```

**Output**:
```
audio/tools/
├── coord-init_part001.mp3
├── coord-init_part002.mp3
├── coord-init_part003.mp3
├── coord-init_metadata.json
├── coord-migrate_part001.mp3
├── coord-migrate_part002.mp3
├── ...
```

### Example 2: Phase Summaries

```bash
# Convert completion summaries
./scripts/doc-to-audio.py \
  --input /tmp/phase5-completion-summary.md \
  --output audio/summaries/ \
  --provider elevenlabs \
  --voice Bella  # Female, natural voice
```

### Example 3: Full Documentation Site

```bash
# Convert everything (long-running)
./scripts/doc-to-audio.py \
  --input docs/ \
  --recursive \
  --output audio/complete/ \
  --provider openai \
  --voice nova  # OpenAI voice
```

---

## Provider Comparison

### 11 Labs (Recommended)

**Pros**:
- ✅ Most natural sounding
- ✅ Multiple high-quality voices
- ✅ Emotion and intonation control
- ✅ 10,000 characters/month free tier

**Cons**:
- ⚠️ Costs after free tier ($5/10k chars)
- ⚠️ Requires separate account

**Best For**: Public sharing, podcast-style, falling asleep to

**Voices**: Adam, Antoni, Arnold, Bella, Callum, Charlie, Charlotte, Clyde, Daniel, Dave, Domi, Dorothy, Drew, Elli, Emily, Ethan, Fin, Freya, George, Gigi, Giovanni, Glinda, Grace, Harry, James, Jeremy, Jessie, Joseph, Josh, Lily, Matilda, Michael, Mimi, Nicole, Patrick, Paul, Rachel, Sam, Serena, Thomas

### OpenAI TTS

**Pros**:
- ✅ Good quality
- ✅ Same API key as ChatGPT
- ✅ Fast generation
- ✅ Competitive pricing

**Cons**:
- ⚠️ Less natural than 11 Labs
- ⚠️ Fewer voice options

**Best For**: Quick conversion, existing OpenAI users

**Voices**: alloy, echo, fable, onyx, nova, shimmer

---

## Configuration

### Voice Selection

#### For Falling Asleep / Ambient

```bash
# Calm, soothing voices
--voice Bella  # 11 Labs - female, soft
--voice Callum # 11 Labs - male, calm
--voice nova   # OpenAI - neutral, smooth
```

#### For Active Listening

```bash
# Clear, engaging voices
--voice Adam   # 11 Labs - male, clear
--voice Rachel # 11 Labs - female, articulate
--voice alloy  # OpenAI - neutral, crisp
```

### Chunk Size

Large documents are split into chunks (default: 5000 chars):

```python
# Adjust in code if needed
chunker = ChunkManager(max_chunk_size=5000)
```

### Cleaning Options

Customize what gets included/excluded:

```python
# In MarkdownCleaner class:

# Option 1: Remove code blocks
text = re.sub(r'```.*?```', '[Code example omitted]', text, flags=re.DOTALL)

# Option 2: Describe code blocks
text = re.sub(r'```([\w]*)\n.*?\n```', r'[\\1 code example]', text, flags=re.DOTALL)

# Option 3: Read code aloud (verbose)
# Leave code blocks in text
```

---

## Cost Estimation

### 11 Labs

- **Free Tier**: 10,000 characters/month
- **Starter**: $5/month (30,000 chars)
- **Creator**: $22/month (100,000 chars)
- **Pro**: $99/month (500,000 chars)

**Typical Document Sizes**:
- `coord-init.md`: ~50,000 chars (after cleaning)
- `coord-migrate.md`: ~60,000 chars
- Full `docs/tools/`: ~120,000 chars
- **Phase 5 summary**: ~30,000 chars

**Estimate**: Full documentation site (~500KB markdown) ≈ 250,000 chars ≈ $50 one-time

### OpenAI TTS

- **Pricing**: $15/1M characters (0.015¢ per char)
- **HD Model**: $30/1M characters

**Estimate**: Full documentation site ≈ 250,000 chars ≈ $3.75 one-time

---

## Workflow: Create Audio Podcast

### Step 1: Generate Audio Files

```bash
# Convert docs to audio
./scripts/doc-to-audio.py \
  --input docs/tools/ \
  --output audio/coordination-podcast/ \
  --provider elevenlabs \
  --voice Adam
```

### Step 2: Combine Parts (Optional)

```bash
# Install ffmpeg
brew install ffmpeg  # macOS
# apt install ffmpeg # Linux

# Combine parts into single file
cd audio/coordination-podcast/

ffmpeg -i "concat:coord-init_part001.mp3|coord-init_part002.mp3|coord-init_part003.mp3" \
  -acodec copy \
  coord-init-full.mp3
```

### Step 3: Add Metadata (Optional)

```bash
# Install eyeD3
pip install eyeD3

# Add ID3 tags
eyeD3 --artist "Coordination System" \
      --album "Documentation Audio" \
      --title "Configuration Generator Guide" \
      --genre "Educational" \
      coord-init-full.mp3
```

### Step 4: Publish

```bash
# Option 1: Host on GitHub Releases
gh release create v1.0-audio \
  audio/coordination-podcast/*.mp3 \
  --title "Audio Documentation v1.0" \
  --notes "Spoken versions of coordination system docs"

# Option 2: Upload to podcast host (Anchor, etc.)
# Option 3: Self-host on website
# Option 4: YouTube as audio-only content
```

---

## Automation

### Bash Script for Batch Conversion

```bash
#!/bin/bash
# convert-all-docs.sh

DOCS_DIR="docs"
AUDIO_DIR="audio"
PROVIDER="elevenlabs"
VOICE="Adam"

# Create output directory
mkdir -p "$AUDIO_DIR"

# Convert each section
sections=(
  "getting-started"
  "concepts"
  "guides"
  "templates"
  "tools"
  "roadmap"
  "reference"
  "advanced"
)

for section in "${sections[@]}"; do
  echo "Converting $section..."
  ./scripts/doc-to-audio.py \
    --input "$DOCS_DIR/$section/" \
    --output "$AUDIO_DIR/$section/" \
    --provider "$PROVIDER" \
    --voice "$VOICE"
done

echo "✅ All sections converted"
```

### Makefile

```makefile
# Makefile for audio documentation

DOCS_DIR = docs
AUDIO_DIR = audio
PROVIDER = elevenlabs
VOICE = Adam

.PHONY: all clean tools summaries

all: tools summaries

tools:
	./scripts/doc-to-audio.py \
		--input $(DOCS_DIR)/tools/ \
		--output $(AUDIO_DIR)/tools/ \
		--provider $(PROVIDER) \
		--voice $(VOICE)

summaries:
	./scripts/doc-to-audio.py \
		--input /tmp/phase5-completion-summary.md \
		--output $(AUDIO_DIR)/summaries/
	./scripts/doc-to-audio.py \
		--input /tmp/phase6-completion-summary.md \
		--output $(AUDIO_DIR)/summaries/

clean:
	rm -rf $(AUDIO_DIR)/*
```

---

## Troubleshooting

### Issue: "No module named 'elevenlabs'"

**Solution**: Install package
```bash
pip install elevenlabs
```

### Issue: "API key not found"

**Solution**: Set environment variable
```bash
export ELEVEN_LABS_API_KEY="your_key"

# Verify
echo $ELEVEN_LABS_API_KEY
```

### Issue: "Rate limit exceeded"

**Solution**: Wait or upgrade plan
```bash
# 11 Labs: Wait for rate limit reset (usually 1 minute)
# OR upgrade plan for higher limits
```

### Issue: Audio files too large

**Solution**: Adjust quality or use compression
```bash
# Compress with ffmpeg
ffmpeg -i input.mp3 -b:a 128k output.mp3
```

### Issue: Code blocks sound awkward

**Solution**: Customize cleaning
```python
# In doc-to-audio.py, adjust _handle_code_blocks():
# Option: Remove entirely
text = re.sub(r'```.*?```', '', text, flags=re.DOTALL)
```

---

## Advanced: Coordination Workflow

### Integrate with Coordination System

```bash
# Message workflow: Document updated → Generate audio
./message.sh send code audio "New doc ready" "docs/tools/new-guide.md"

# Audio agent processes (hypothetical)
# 1. Receives message
# 2. Runs doc-to-audio.py
# 3. Uploads to hosting
# 4. Sends completion message
./message.sh send audio human "Audio ready" "https://site.com/audio/new-guide.mp3"
```

### LaunchAgent (Auto-generate on doc changes)

```xml
<!-- ~/Library/LaunchAgents/com.coordination.audio-docs.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.coordination.audio-docs</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/scripts/doc-to-audio.py</string>
        <string>--input</string>
        <string>/path/to/docs/</string>
        <string>--output</string>
        <string>/path/to/audio/</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/path/to/docs/</string>
    </array>
</dict>
</plist>
```

---

## FAQ

### Q: Which provider should I use?

**A**: 11 Labs for public sharing (highest quality), OpenAI for personal use (cheaper, fast).

### Q: Can I use this commercially?

**A**: Check provider terms. 11 Labs and OpenAI both allow commercial use with paid plans.

### Q: How long does conversion take?

**A**: ~1-2 minutes per 10KB of markdown (depends on API speed). Full docs (~500KB) ≈ 50-100 minutes.

### Q: Can I change voices mid-document?

**A**: Not currently, but you could split the document and use different voices per section.

### Q: Does it work offline?

**A**: No, requires API calls. For offline, use local TTS (piper, espeak) but quality is lower.

### Q: Can I speed up/slow down audio?

**A**: Yes, in your audio player. Or use ffmpeg:
```bash
ffmpeg -i input.mp3 -filter:a "atempo=1.25" output.mp3  # 1.25x speed
```

---

## Sharing Audio Documentation

### As Podcast

1. **Host on Anchor/Spotify**:
   - Upload MP3 files
   - Add episode descriptions (from markdown headers)
   - Publish as "Coordination System Audio Docs"

2. **RSS Feed**:
   - Self-host audio files
   - Generate RSS feed
   - Users subscribe in podcast apps

### As YouTube Content

1. **Create Static Video**:
   ```bash
   # Image + audio → video
   ffmpeg -loop 1 -i cover-image.png -i audio.mp3 \
     -c:v libx264 -c:a aac -b:a 192k \
     -shortest output.mp4
   ```

2. **Upload to YouTube**:
   - Title: "Coordination System - Configuration Generator Guide (Audio)"
   - Description: Include markdown source link
   - Tags: documentation, technical, tutorial

### As GitHub Release

```bash
# Create release with audio files
gh release create v1.0-audio-docs \
  audio/**/*.mp3 \
  --title "Audio Documentation v1.0" \
  --notes "Download and listen to documentation offline"
```

---

## Next Steps

1. **Get API Key**: Sign up for 11 Labs or use existing OpenAI key
2. **Test Conversion**: Convert one small file first
3. **Batch Convert**: Run on full docs/ directory
4. **Review Quality**: Listen and adjust voice/cleaning if needed
5. **Share** (optional): Publish for community use

---

**Estimated Time**:
- Setup: 15 minutes
- First conversion: 5 minutes
- Full documentation: 1-2 hours (mostly API time)

**Cost**:
- 11 Labs: ~$50 one-time for full docs
- OpenAI: ~$4 one-time for full docs

**Value**:
- Accessible to wider audience
- Passive learning format
- Ambient listening content
- Unique offering (most projects don't have this!)

---

**Last Updated**: 2025-10-30
