# Audiobook Approval Queue

**Purpose:** Human review queue for documentation→audio conversion
**Policy:** See `../AUDIOBOOK-APPROVAL-POLICY.md`

---

## Current Queue

```bash
# View queued documents
ls -lh
```

**Queued Items:**
- `chat-agent-knowledge-base.md` → Chat Agent Knowledge Base reference

---

## Quick Actions

### Review a Document

```bash
# Read the document
cat chat-agent-knowledge-base.md

# Or open in editor
open chat-agent-knowledge-base.md
```

### Approve for Production

```bash
# 1. Create metadata
cat > ../production-queue/chat-agent-knowledge-base.meta.json <<EOF
{
  "title": "Chat Agent Knowledge Base - Complete Reference",
  "source": "~/infrastructure/agent-bridge/workspace/docs/claude-project-setup/KNOWLEDGE-BASE.md",
  "voice": "professional-narrator",
  "style": "educational-reference",
  "priority": "high",
  "estimated_duration": "45-60min",
  "chapters": true,
  "notes": "Comprehensive reference for Chat agent bridge operations"
}
EOF

# 2. Move to production queue
mkdir -p ../production-queue
mv chat-agent-knowledge-base.md ../production-queue/

# 3. Log approval
echo "$(date -Iseconds) - chat-agent-knowledge-base.md - APPROVED - high priority reference" >> ../approval-log.txt
```

### Defer for Later

```bash
# Add to deferred list with reason
echo "$(date -Iseconds) - chat-agent-knowledge-base.md - DEFERRED - Needs editing for audio flow" >> ../deferred.txt

# Keep in queue for now
# (Don't delete)
```

### Reject (Not Suitable)

```bash
# Remove from queue
rm chat-agent-knowledge-base.md

# Log rejection
echo "$(date -Iseconds) - chat-agent-knowledge-base.md - REJECTED - Too technical/code-heavy" >> ../rejected-log.txt
```

---

## Review Checklist

When reviewing queued documents, consider:

### Content Appropriateness

- [ ] **Narrative flow** - Reads well aloud?
- [ ] **Code density** - Not overwhelmed by code blocks?
- [ ] **Table complexity** - Tables simple or well-described?
- [ ] **Length** - Reasonable for audio format? (not too short/long)
- [ ] **Structure** - Clear chapters/sections for navigation?

### Audio Production Needs

- [ ] **Voice style** - What voice/tone fits content?
  - Professional narrator (educational)
  - Conversational (tutorials)
  - Technical (API docs)
  - Multi-voice (dialogues, examples)

- [ ] **Priority level**
  - HIGH: Critical reference, onboarding materials
  - NORMAL: Helpful reference, nice-to-have
  - LOW: Optional supplemental content

- [ ] **Special requirements**
  - Background music?
  - Sound effects (for examples)?
  - Multiple voices?
  - Chapter markers?

### Target Audience

- [ ] **Who needs this?**
  - New users (onboarding)
  - Existing users (reference)
  - Specific agent (Chat/Code)
  - General knowledge

- [ ] **How will it be used?**
  - Ambient learning (background listening)
  - Active study (focused attention)
  - Reference (specific lookups)
  - Training (systematic learning)

---

## Voice Options

See `../multivoice-narration-guide.md` for full details.

**Quick reference:**
- **Professional Narrator** - Clear, authoritative, educational
- **Conversational** - Friendly, approachable, tutorial-style
- **Technical** - Precise, measured, specification-focused
- **Multi-voice** - Different voices for sections/speakers

---

## Production Pipeline

After approval:

1. **Pre-process** (automated)
   - Clean markdown for TTS
   - Extract chapters
   - Add voice tags if multi-voice

2. **Convert** (automated)
   ```bash
   ~/devvyn-meta-project/scripts/doc-to-audio.py \
     --input ../production-queue/chat-agent-knowledge-base.md \
     --output ~/Desktop/Knowledge-Base-Audio/ \
     --config ../production-queue/chat-agent-knowledge-base.meta.json
   ```

3. **Post-process** (automated)
   - Normalize audio
   - Add intro/outro
   - Generate chapters
   - Embed metadata

4. **Distribute** (automated)
   - Save to output directory
   - Auto-import to Music (if configured)
   - Update inventory

---

## Tips for Review

### Good Candidates for Audio

✅ **Guides & Tutorials**
- Clear narrative structure
- Step-by-step instructions
- Learning-focused content
- Conceptual explanations

✅ **Reference Documentation**
- Well-organized sections
- Natural reading flow
- Helpful for review/memorization
- Background listening value

✅ **Best Practices**
- Principle-based content
- Reasoning and rationale
- Decision frameworks
- Strategic guidance

### Poor Candidates for Audio

❌ **Code-Heavy Content**
- Extensive code samples
- API reference with syntax details
- Configuration examples
- Requires visual inspection

❌ **Highly Tabular**
- Complex comparison tables
- Data-dense matrices
- Multi-column layouts
- Requires spatial understanding

❌ **Visual-Dependent**
- Diagrams and flowcharts
- Architecture drawings
- UI mockups
- Requires seeing to understand

### Can Work With Editing

⚠️ **Needs Preparation**
- Remove/simplify code blocks
- Describe tables narratively
- Explain visual concepts verbally
- Add transitional narration

---

## Current Recommendations

### chat-agent-knowledge-base.md

**Status:** Pending Review

**Assessment:**
- **Content:** Comprehensive reference guide (30KB, 794 lines)
- **Structure:** Well-organized with clear sections
- **Code density:** Moderate (bash examples throughout)
- **Tables:** Few, simple
- **Narrative flow:** Good for sequential listening

**Recommendation:** **APPROVE with modifications**

**Suggested metadata:**
```json
{
  "title": "Chat Agent Knowledge Base - Complete Reference",
  "voice": "professional-narrator",
  "style": "educational-reference",
  "priority": "high",
  "estimated_duration": "45-60min",
  "pre_processing": [
    "Simplify code blocks to 'example commands'",
    "Add chapter intro/outro transitions",
    "Emphasize section headers for navigation"
  ],
  "chapters": [
    "Bridge Architecture",
    "Message Templates",
    "osascript Patterns",
    "Common Commands",
    "Troubleshooting",
    "Workflow Examples"
  ],
  "target_audience": "Chat agent onboarding and reference"
}
```

**Production notes:**
- Consider multi-voice for "Examples" sections (narrator + user)
- Add brief pauses between major sections
- Emphasize command syntax patterns
- Create chapter markers for easy navigation

---

## Automated Queuing

Documents are automatically queued when:
- Size > 5KB or length > 100 lines
- Located in docs/knowledge-base directories
- Matches comprehensive documentation patterns

**See:** `../AUDIOBOOK-APPROVAL-POLICY.md` for full criteria

---

**Questions?** Review the policy document or ask human reviewer.

**Ready to approve?** Follow "Approve for Production" steps above.
