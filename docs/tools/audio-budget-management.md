# Audio Budget Management

**Purpose**: Track and manage TTS API usage to stay within monthly subscription limits and daily quotas.

## Overview

The audio budget manager provides:

- **Monthly budget tracking** for subscription plans
- **Daily quota enforcement** to spread usage evenly
- **Priority queuing** for batch document processing
- **Multi-provider support** (ElevenLabs, OpenAI, macOS)
- **Cost monitoring** and usage reports

## Quick Start

### 1. Check Current Status

```bash
~/devvyn-meta-project/scripts/audio-budget-manager.py status
```

Output:
```
🎙️  AUDIO BUDGET STATUS
Active Provider: elevenlabs_v3_alpha
Plan: ElevenLabs V3 Alpha (80% discount until June 2025)
Cost: $5.00/month

📅 Monthly Usage (2025-11):
  [======>                       ] 20.0%
  Used: 30,000 / 150,000 chars
  Remaining: 120,000 chars

☀️  Daily Usage (2025-11-05):
  [===========>                  ] 40.0%
  Used: 4,000 / 10,000 chars
  Remaining: 6,000 chars
```

### 2. Set Active Provider

```bash
# Use ElevenLabs V3 Alpha (best value - 80% discount until June 2025)
~/devvyn-meta-project/scripts/audio-budget-manager.py set-provider elevenlabs_v3_alpha

# Or use macOS Native (free, unlimited)
~/devvyn-meta-project/scripts/audio-budget-manager.py set-provider macos_native

# Or use OpenAI TTS
~/devvyn-meta-project/scripts/audio-budget-manager.py set-provider openai_tts
```

### 3. Queue Documents for Processing

```bash
# Add document to queue (default: medium priority)
~/devvyn-meta-project/scripts/audio-budget-manager.py queue docs/phase-6-completion.md

# Add with high priority
~/devvyn-meta-project/scripts/audio-budget-manager.py queue docs/urgent-fix.md \
  --provider elevenlabs_v3_alpha \
  --priority high

# Add with low priority (process when quota available)
~/devvyn-meta-project/scripts/audio-budget-manager.py queue knowledge-base/patterns/jits.md \
  --priority low
```

### 4. Process Queue Within Limits

```bash
# Dry run (show what would be processed)
~/devvyn-meta-project/scripts/audio-budget-manager.py process-queue --dry-run

# Actually process queued jobs
~/devvyn-meta-project/scripts/audio-budget-manager.py process-queue
```

## Budget Plans

**Note:** Prices shown in USD. For CAD, multiply by current exchange rate (~1.35-1.40 as of Nov 2025).

### macOS Native (Free) ⭐ Best for Bulk

```json
{
  "monthly_limit": ∞,
  "daily_limit": ∞,
  "cost_per_month": $0.00 USD ($0.00 CAD),
  "quality": "Good (Premium Siri voices)",
  "voices": "Jamie, Lee, Serena, Aman, etc."
}
```

**Pros:**
- ✅ FREE, unlimited
- ✅ Offline capable
- ✅ Premium quality voices (Siri-tier)
- ✅ No API costs whatsoever

**Cons:**
- ❌ No API (subprocess only)
- ❌ Limited voice variety vs. ElevenLabs
- ❌ No emotion/tone control

**Best for:** Bulk generation, Phase documentation, testing, draft content

---

### ElevenLabs V3 Alpha (Recommended) ⭐ Best Value

**Verified Nov 2025:**

```json
{
  "monthly_limit": 150,000 chars,      // 5x effective due to 80% discount
  "daily_limit": 10,000 chars,         // Conservative quota
  "cost_per_month": $5.00 USD (~$6.75-7.00 CAD),
  "cost_per_character": 0.2 credits (80% off until June 30, 2025),
  "quality": "Excellent",
  "special": "80% discount ends June 30, 2025"
}
```

**Pros:**
- ✅ 5x effective credits vs. regular V3 (80% discount verified)
- ✅ Emotion/tone tags (`[excited]`, `[calm]`, `[whispers]`)
- ✅ 70+ languages support
- ✅ Multi-speaker dialogue
- ✅ Sound Effects API available
- ✅ Most natural, human-like voices

**Cons:**
- ⚠️ Discount ends June 30, 2025 (then 1 credit/char regular price)
- ⚠️ API rate limits apply

**Best for:** High-quality public content, pattern documentation, stories, key documents

**After June 2025:** Will cost 5x more OR switch to Starter plan at 30k chars/month

---

### ElevenLabs Starter

**Verified Nov 2025:**

```json
{
  "monthly_limit": 30,000 chars,       // Verified Nov 2025
  "daily_limit": 2,000 chars,          // Conservative estimate
  "cost_per_month": $5.00 USD (~$6.75-7.00 CAD),
  "first_month": $1.00 USD,            // Promotional pricing
  "quality": "Excellent"
}
```

**Features:**
- Commercial license included
- Instant voice cloning
- Studio and Dubbing API access
- 10 custom voices

**Best for:** Fallback after V3 Alpha discount ends (June 2025)

---

### ElevenLabs Creator

**Verified Nov 2025:**

```json
{
  "monthly_limit": 100,000 chars,      // Verified Nov 2025
  "daily_limit": 5,000 chars,          // Conservative estimate
  "cost_per_month": $22.00 USD (~$29.70-30.80 CAD),
  "first_month": $11.00 USD (50% off),
  "audio_quality": "192 kbps",
  "quality": "Excellent"
}
```

**Features:**
- Professional voice cloning
- Higher audio quality (192 kbps)
- Priority generation queue
- Project management tools

**Best for:** High-volume professional use (100k chars = ~200 minutes/month)

---

### OpenAI TTS

```json
{
  "monthly_limit": 1,000,000 chars,    // At $15 budget
  "daily_limit": 50,000 chars,
  "cost_per_month": $15.00 USD (~$20.25-21.00 CAD),
  "pricing_model": "$0.015 per 1k characters",
  "quality": "Good",
  "voices": "alloy, echo, fable, onyx, nova, shimmer"
}
```

**Pros:**
- ✅ High volume capacity
- ✅ Fast generation
- ✅ Good quality
- ✅ Pay-per-use (no monthly minimum)

**Cons:**
- ❌ 3x cost of ElevenLabs Starter
- ❌ Less natural than ElevenLabs
- ❌ No emotion tags

**Best for:** High-volume bulk generation with API budget

---

## Usage Workflow

### Daily Pattern

```bash
# Morning: Check remaining quota
~/devvyn-meta-project/scripts/audio-budget-manager.py status

# Add documents as they're written
~/devvyn-meta-project/scripts/audio-budget-manager.py queue new-pattern.md --priority medium

# End of day: Process queue
~/devvyn-meta-project/scripts/audio-budget-manager.py process-queue
```

### Monthly Pattern

```bash
# First of month: Reset counters
~/devvyn-meta-project/scripts/audio-budget-manager.py reset-month

# Review last month's usage
~/devvyn-meta-project/scripts/audio-budget-manager.py status
```

## Priority Levels

| Priority | Use Case | Processing Order |
|----------|----------|------------------|
| **urgent** | Critical fixes, immediate publish | 1st |
| **high** | Phase documentation, public content | 2nd |
| **medium** | Pattern docs, regular content | 3rd |
| **low** | Backlog, experimental, nice-to-have | 4th |

## Cost Optimization Strategy

### Hybrid Approach (Recommended)

```bash
# 1. Bulk/draft: macOS Native (FREE)
audio-budget-manager.py set-provider macos_native
audio-budget-manager.py queue draft-docs/*.md --priority low

# 2. High-impact: ElevenLabs V3 Alpha ($5/mo)
audio-budget-manager.py set-provider elevenlabs_v3_alpha
audio-budget-manager.py queue public-content/*.md --priority high

# 3. Process based on priority
audio-budget-manager.py process-queue
```

**Expected Cost:** ~$5-7/month for professional quality on key content

### Budget Scenarios

**Scenario 1: Free Tier Only**
- Provider: `macos_native`
- Cost: $0/month
- Quality: Good
- Volume: Unlimited
- Use case: Personal docs, phase summaries

**Scenario 2: ElevenLabs V3 Alpha**
- Provider: `elevenlabs_v3_alpha`
- Cost: $5/month
- Quality: Excellent
- Volume: ~300 minutes/month
- Use case: Public docs, key patterns, stories

**Scenario 3: Hybrid (Recommended)**
- Providers: `macos_native` + `elevenlabs_v3_alpha`
- Cost: $5/month
- Quality: Good for bulk, Excellent for highlights
- Volume: Unlimited + 300 minutes premium
- Use case: Everything - optimize cost vs. quality

**Scenario 4: High Volume**
- Providers: `macos_native` + `openai_tts`
- Cost: $15/month
- Quality: Good across the board
- Volume: Unlimited + 2000 minutes API
- Use case: Heavy batch processing, team docs

## Integration with doc-to-audio.py

The budget manager integrates seamlessly:

```python
# In doc-to-audio.py (future integration)
from audio_budget_manager import AudioBudgetManager

def convert_with_budget_check(doc: str, provider: str):
    """Convert document with budget enforcement"""
    manager = AudioBudgetManager()

    # Estimate characters
    estimated_chars = len(Path(doc).read_text())

    # Check quota
    can_use, reason = manager.can_use(provider, estimated_chars)

    if not can_use:
        # Add to queue instead
        job_id = manager.add_to_queue(doc, provider, "medium", estimated_chars)
        print(f"⏸️  Quota exceeded. Queued as {job_id}")
        return None

    # Generate audio
    audio_file = generate_audio(doc, provider)

    # Record actual usage
    actual_chars = len(Path(doc).read_text())
    manager.record_usage(provider, actual_chars, doc)

    return audio_file
```

## Monthly Reset (Automated)

Add to crontab for automatic monthly reset:

```bash
# Edit crontab
crontab -e

# Add line (resets on 1st of each month at midnight)
0 0 1 * * ~/devvyn-meta-project/scripts/audio-budget-manager.py reset-month
```

## Configuration File

Budget config stored at: `~/devvyn-meta-project/config/audio-budget.json`

```json
{
  "active_provider": "elevenlabs_v3_alpha",
  "budgets": { ... },
  "usage": {
    "elevenlabs_v3_alpha": {
      "provider": "elevenlabs_v3_alpha",
      "month": "2025-11",
      "monthly_used": 45000,
      "daily_used": 3500,
      "last_reset_date": "2025-11-05",
      "history": [
        {
          "date": "2025-11-05T14:30:00",
          "chars": 3500,
          "doc": "docs/phase-6-completion.md"
        }
      ]
    }
  },
  "queue": [
    {
      "job_id": "2025-11-05-0",
      "doc_path": "knowledge-base/patterns/jits.md",
      "provider": "elevenlabs_v3_alpha",
      "priority": "low",
      "estimated_chars": 8500,
      "added_date": "2025-11-05T15:00:00",
      "status": "queued"
    }
  ],
  "last_updated": "2025-11-05T15:00:00"
}
```

## Troubleshooting

### Quota Exceeded

```bash
# Check remaining quota
audio-budget-manager.py status

# Add to queue for tomorrow
audio-budget-manager.py queue doc.md --priority low

# Or switch to free provider
audio-budget-manager.py set-provider macos_native
```

### Queue Not Processing

```bash
# Check queue status
audio-budget-manager.py status

# Try dry run
audio-budget-manager.py process-queue --dry-run

# Check provider limits
# (Queue may be waiting for daily reset)
```

### Wrong Provider Used

```bash
# Check active provider
audio-budget-manager.py status

# Change provider
audio-budget-manager.py set-provider elevenlabs_v3_alpha
```

## Future Enhancements

**Planned features:**

1. **Auto-fallback**: If quota exceeded, automatically fallback to macOS
2. **Smart routing**: Route by content type (public → ElevenLabs, draft → macOS)
3. **Cost alerts**: Email/Slack when approaching monthly limit
4. **Usage analytics**: Visualize monthly trends
5. **Team quotas**: Multiple users sharing one API key

## See Also

- [Audio Documentation Setup](./audio-docs-setup.md)
- [Multi-voice Narration Guide](../knowledge-base/audio-documentation/multivoice-narration-guide.md)
- [ElevenLabs 2025 Capabilities](../knowledge-base/audio-documentation/elevenlabs-2025-capabilities-research.md)
