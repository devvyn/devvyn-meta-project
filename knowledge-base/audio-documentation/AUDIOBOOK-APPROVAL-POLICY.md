# Audiobook Approval Policy

**Version:** 1.0
**Effective Date:** November 1, 2025
**Status:** Active SOP

---

## Policy Statement

Comprehensive documentation files (>5KB, >100 lines) that serve as reference materials or learning resources SHALL be automatically queued for audiobook conversion approval.

## Rationale

**Why Audiobooks:**
- Enables ambient learning during commutes, exercise, household tasks
- Provides alternative learning modality (auditory vs visual)
- Makes documentation accessible while multitasking
- Supports knowledge retention through repetition
- Creates portable reference materials

**Why Approval Queue:**
- Not all documentation benefits from audio format
- Some content (code-heavy, tables, visual) translates poorly to audio
- Manual review ensures quality and appropriateness
- Human decides voice style, pacing, emphasis

## Automatic Queuing Triggers

Documentation is **automatically queued** when:

1. **File size** > 5KB OR **line count** > 100
2. **Content type** includes:
   - Knowledge bases
   - Complete guides/tutorials
   - Reference documentation
   - Agent operating instructions
   - Workflow examples
   - Best practices documentation
   - Architecture explanations

3. **Location** in:
   - `~/devvyn-meta-project/knowledge-base/`
   - `~/infrastructure/agent-bridge/workspace/docs/`
   - `~/devvyn-meta-project/docs/`
   - Any `/docs/` directory with comprehensive content

## Exclusions (NOT Queued)

- Code files (`.py`, `.js`, `.sh`, etc.)
- Configuration files (`.json`, `.yaml`, `.toml`)
- Raw logs or data dumps
- README files < 2KB (too short)
- Changelogs, issue trackers
- Highly technical API references with extensive code samples
- Files already in audio format

## Approval Queue Process

### 1. Automatic Queuing

When qualifying documentation is created/updated:

```bash
# System automatically creates symlink
ln -s <source-doc> ~/devvyn-meta-project/knowledge-base/audio-documentation/approval-queue/<descriptive-name>.md
```

### 2. Queue Location

```
~/devvyn-meta-project/knowledge-base/audio-documentation/
└── approval-queue/
    ├── README.md                           # Queue instructions
    ├── chat-agent-knowledge-base.md       # Symlink to actual file
    ├── bridge-comprehensive-guide.md      # Symlink
    └── [other-queued-docs].md             # Symlinks
```

### 3. Review Criteria

Human reviewer checks:

- [ ] **Appropriate for audio?** (narrative flow, not code-heavy)
- [ ] **Length reasonable?** (not too short/long)
- [ ] **Voice style needed?** (single voice, multi-voice, narrator style)
- [ ] **Priority level?** (critical reference vs nice-to-have)
- [ ] **Target audience?** (learning, reference, onboarding)

### 4. Approval Actions

**APPROVE:**
```bash
# Move to production queue
mv approval-queue/<doc>.md production-queue/<doc>.md

# Add metadata file
cat > production-queue/<doc>.meta.json <<EOF
{
  "title": "Chat Agent Knowledge Base",
  "voice": "professional-narrator",
  "style": "educational",
  "priority": "high",
  "target_duration": "30-45min"
}
EOF
```

**DEFER:**
```bash
# Add to deferred list with reason
echo "<doc>.md - Reason: Too code-heavy, needs editing first" >> deferred.txt
```

**REJECT:**
```bash
# Remove from queue
rm approval-queue/<doc>.md
echo "<doc>.md rejected - not suitable for audio" >> rejected-log.txt
```

## Production Pipeline (After Approval)

1. **Pre-processing**
   - Clean markdown (remove code blocks, simplify tables)
   - Add voice tags (if multi-voice)
   - Split into chapters

2. **TTS Conversion**
   ```bash
   ./scripts/doc-to-audio.py \
     --input production-queue/<doc>.md \
     --output audio-assets/<doc>/ \
     --voice-config production-queue/<doc>.meta.json
   ```

3. **Post-processing**
   - Add intro/outro music
   - Normalize audio levels
   - Generate chapters/timestamps
   - Create metadata file

4. **Distribution**
   - Save to `~/Desktop/Knowledge-Base-Audio/`
   - Add to Music library (auto-import folder)
   - Update inventory

## Current Queue

| Document | Status | Reviewer | Date Queued |
|----------|--------|----------|-------------|
| chat-agent-knowledge-base.md | Pending | - | 2025-11-01 |

## Metrics

- **Total Queued:** 1
- **Total Approved:** 0
- **Total Produced:** 0
- **Avg Queue Time:** N/A

## Policy Exceptions

Exceptions require human approval:

- **Rush production** - Skip queue for urgent training materials
- **External content** - Third-party docs need license review
- **Experimental voices** - Testing new TTS providers
- **Custom formatting** - Non-standard content structure

## Review Cycle

- **Daily:** Check approval queue for new items
- **Weekly:** Review deferred items for editing/retry
- **Monthly:** Audit policy effectiveness

## Tools & Scripts

- **Queue checker:** `ls ~/devvyn-meta-project/knowledge-base/audio-documentation/approval-queue/`
- **Production script:** `~/devvyn-meta-project/scripts/doc-to-audio.py`
- **Voice options:** See `~/devvyn-meta-project/knowledge-base/audio-documentation/multivoice-narration-guide.md`

## Responsibilities

- **Code Agent:** Automatically queues qualifying docs
- **Human:** Reviews queue, approves/defers/rejects
- **System:** Produces approved audiobooks, distributes

## Success Criteria

- ✅ All comprehensive docs reviewed within 7 days
- ✅ High-value learning materials converted to audio
- ✅ Audio quality meets listening standards
- ✅ Knowledge base accessible in multiple formats

## Related Documentation

- `multivoice-narration-guide.md` - Voice selection guide
- `audio-design-research-synthesis.md` - Audio production research
- `doc-to-audio.py` - Conversion script documentation
- `INVENTORY.md` - Audio documentation inventory

---

**Policy Owner:** Human (Devvyn)
**Implemented By:** Code Agent (automated queuing)
**Reviewed:** As needed based on usage

**Last Updated:** November 1, 2025
