# Audio Budget Management System

Dynamic, runtime-intelligent audio generation with automatic budget management.

## Quick Start

```bash
# 1. Check your current budget status
./audio-budget-manager.py status

# 2. Generate audio (auto-routes based on content + quota)
./audio-generate.sh knowledge-base/patterns/my-pattern.md

# 3. Process queue of pending documents
./audio-budget-manager.py process-queue
```

## What It Does

**Automatically manages your ElevenLabs budget** without manual intervention:

- ✅ Detects content type (premium vs draft)
- ✅ Checks quota before using paid API
- ✅ Falls back to free macOS when quota exceeded
- ✅ Queues premium version for tomorrow
- ✅ Tracks usage history

## Components

### 1. Budget Manager (`audio-budget-manager.py`)

Tracks quotas and enforces limits.

```bash
# View status
./audio-budget-manager.py status

# Set active provider
./audio-budget-manager.py set-provider elevenlabs_starter

# Queue a document
./audio-budget-manager.py queue doc.md --priority high

# Process queue
./audio-budget-manager.py process-queue

# Reset monthly (automated via cron)
./audio-budget-manager.py reset-month
```

**Config file**: `~/devvyn-meta-project/config/audio-budget.json`

### 2. Smart Router (`audio_router.py`)

Routes documents to appropriate TTS provider.

```bash
# Test routing (dry run)
python3 audio_router.py knowledge-base/patterns/jits.md --dry-run

# Force specific provider
python3 audio_router.py doc.md --force-provider macos

# Actually generate audio
python3 audio_router.py doc.md
```

**Routing Rules:**
- `knowledge-base/patterns/**` → Premium (ElevenLabs)
- `docs/phase-summaries/**` → Premium
- `scratch/**`, `notes/**`, `/tmp/**` → Draft (macOS)
- Large files (>5KB) → Premium
- Small files → Draft

### 3. Generation Wrapper (`audio-generate.sh`)

Simple interface for batch processing.

```bash
# Single file
./audio-generate.sh doc.md

# Multiple files
./audio-generate.sh docs/**/*.md

# With options
./audio-generate.sh doc.md --multi-voice --advanced-mixing

# Just show status
./audio-generate.sh --status
```

## How It Works

### Example: Daily Workflow

**Morning (fresh 2k daily quota):**

```bash
$ ./audio-generate.sh knowledge-base/patterns/small-pattern.md
📊 Budget: 0/2000 chars used today
🎙️  Processing: small-pattern.md
📍 Routing: ELEVENLABS
   Reason: Premium content, quota available
   Estimated: 1,200 chars
✅ Generated: small-pattern_part001.mp3
📊 Budget: 1,200/2000 chars used today
```

**Afternoon (approaching limit):**

```bash
$ ./audio-generate.sh knowledge-base/patterns/large-pattern.md
📊 Budget: 1,200/2000 chars used today
🎙️  Processing: large-pattern.md
📍 Routing: MACOS
   Reason: Premium content, quota exceeded, fallback
   Estimated: 8,700 chars
   ⚠️  Fallback used - draft quality
   ✅ Premium version queued for tomorrow
✅ Generated: large-pattern_part001.mp3 (draft)
📊 Budget: 1,200/2000 chars used today
```

**Next Day (queue processes automatically or manually):**

```bash
$ ./audio-budget-manager.py process-queue
✅ Processed 1 job
  - large-pattern.md (8,700 chars) → Premium quality
```

## Budget Plans

### ElevenLabs Starter (Current Plan)
- **Cost**: $5 USD/month (~$7 CAD)
- **Monthly limit**: 30,000 chars
- **Daily limit**: 2,000 chars (conservative)
- **Features**: Commercial license, voice cloning, 10 custom voices

### macOS Native (Free Tier)
- **Cost**: FREE
- **Limit**: Unlimited
- **Voices**: Jamie (UK), Lee (AU), Serena (UK), Aman (India), etc.
- **Use for**: Bulk generation, drafts, testing

### Hybrid Strategy (Recommended)
- Use macOS for drafts/bulk
- Use ElevenLabs for premium content
- Total cost: ~$7 CAD/month

## Priority System

| Priority | Use Case | Processing Order |
|----------|----------|------------------|
| urgent | Critical fixes, immediate publish | 1st |
| high | Phase docs, public content | 2nd |
| medium | Pattern docs, regular content | 3rd |
| low | Backlog, experimental | 4th |

## Testing

```bash
# Run test suite
cd ~/devvyn-meta-project/scripts
python3 test_audio_budget.py

# Current status: 12/17 tests passing (70.6%)
# See docs/tools/audio-system-test-results.md for details
```

## Configuration

### Set Provider

```bash
# Use ElevenLabs Starter
./audio-budget-manager.py set-provider elevenlabs_starter

# Use ElevenLabs V3 Alpha (80% discount until June 2025)
./audio-budget-manager.py set-provider elevenlabs_v3_alpha

# Use free macOS
./audio-budget-manager.py set-provider macos_native
```

### Monthly Reset (Automated)

Add to crontab:

```bash
# Edit crontab
crontab -e

# Add line (resets on 1st of each month at midnight)
0 0 1 * * ~/devvyn-meta-project/scripts/audio-budget-manager.py reset-month
```

## Troubleshooting

### Quota Exceeded

```bash
# Check remaining quota
./audio-budget-manager.py status

# Use free macOS instead
python3 audio_router.py doc.md --force-provider macos

# Or wait for tomorrow's reset
./audio-budget-manager.py queue doc.md --priority low
```

### Provider Not Working

```bash
# Check active provider
./audio-budget-manager.py status

# Switch providers
./audio-budget-manager.py set-provider elevenlabs_starter

# Verify config
cat ~/devvyn-meta-project/config/audio-budget.json
```

### Queue Not Processing

```bash
# Check queue status
./audio-budget-manager.py status

# Force process (non-dry-run)
./audio-budget-manager.py process-queue

# Clear specific job (edit JSON directly)
vim ~/devvyn-meta-project/config/audio-budget.json
```

## File Locations

- **Scripts**: `~/devvyn-meta-project/scripts/`
  - `audio-budget-manager.py` - Budget tracking
  - `audio_router.py` - Smart routing
  - `audio-generate.sh` - Simple wrapper
  - `doc-to-audio.py` - Core TTS converter

- **Config**: `~/devvyn-meta-project/config/audio-budget.json`

- **Documentation**:
  - `docs/tools/audio-budget-management.md` - Full guide
  - `docs/tools/audio-system-test-results.md` - Test results
  - `docs/tools/audio-docs-setup.md` - TTS setup guide

## See Also

- [Audio Budget Management Guide](../docs/tools/audio-budget-management.md) - Comprehensive documentation
- [Test Results](../docs/tools/audio-system-test-results.md) - Test suite status
- [Audio Documentation Setup](../docs/tools/audio-docs-setup.md) - Initial setup
- [Multi-voice Guide](../knowledge-base/audio-documentation/multivoice-narration-guide.md) - Voice configuration
