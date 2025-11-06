# Narrative Generation Knowledge Base

**Created**: 2025-10-31
**Purpose**: Research synthesis for procedural narrative generation and simulacrum worlds to audio stories
**Status**: Foundation research complete

## Overview

This knowledge base contains research and design patterns for:
1. World simulation approaches
2. Narrative extraction from simulations
3. Procedural story generation techniques
4. LLM-assisted narrative creation
5. Dramatic audio reading production

## Documents

### 1. Emily Short on World Simulation
**File**: `emily-short-world-simulation.md`

**Key Insights**:
- No generic world simulator exists
- Content data dominates development time
- Causality tracking is critical
- Curation is as important as generation
- Granularity must serve narrative needs

**Applies to**: World simulation architecture, what to model vs. what to skip

### 2. Talk of the Town Framework
**File**: `talk-of-the-town-framework.md`

**Key Features**:
- 200-year temporal simulation (1839-1979)
- Sophisticated character knowledge modeling
- Social network dynamics
- Dialogue generation from character beliefs
- Narrative extraction via event salience

**Applies to**: Long-term simulation, knowledge graphs, character-centered narratives

### 3. Lume: Combinatorial Narrative
**File**: `lume-combinatorial-narrative.md`

**Key Innovation**:
- Parameterized scene templates (node-trees)
- Logic programming for scene selection
- Balance between emergence and structure
- Content reuse with narrative reactiveness

**Applies to**: Scene library design, adaptive storytelling, managing complexity

### 4. LLM + Procedural Narrative (2025)
**File**: `llm-procedural-narrative-2025.md`

**State of the Art**:
- Claude Sonnet 4.5 / Opus 4.1 for character-driven stories
- Answer Set Programming + LLM hybrid
- Narrative-to-scene generation
- Character consistency techniques
- Limitations: pacing, intentionality, dramatic conflict

**Applies to**: Using LLMs effectively, avoiding pitfalls, hybrid architectures

### 5. Simulacrum-to-Audio Design Pattern
**File**: `simulacrum-to-audio-design-pattern.md`

**Complete Pipeline**:
1. World simulation (full/light/LLM-generated)
2. Narrative extraction (event selection + story arc)
3. Scene generation (LLM-assisted with templates)
4. Voice mapping (characters → TTS voices)
5. Audio production (multi-voice TTS + mixing)

**Applies to**: Implementation roadmap, testing strategy, integration patterns

## Quick Reference

### World Simulation Approaches

| Approach | Time Span | Granularity | Complexity | Best For |
|----------|-----------|-------------|------------|----------|
| **Talk of the Town-style** | 200 years | Daily | High | Rich social histories |
| **Dwarf Fortress-style** | Centuries | Variable | Very High | Civilization-scale epics |
| **LLM-generated** | Instant | N/A | Low | Quick prototyping |
| **Light simulation** | Weeks-months | Event-based | Medium | Focused narratives |

### Narrative Extraction Methods

| Method | Pros | Cons | Best Use |
|--------|------|------|----------|
| **Event salience scoring** | Automated, scalable | May miss subtle drama | Large event sets |
| **Character-focused** | Strong POV, coherent | Limited scope | Character-driven stories |
| **Query-based** | Targeted, flexible | Requires good queries | Specific story types |
| **Human curation** | High quality | Not scalable | Final polish |

### Scene Generation Techniques

| Technique | Structure | Variation | Author Effort |
|-----------|-----------|-----------|---------------|
| **Hand-written** | Fixed | Low | High |
| **Templates** | Medium | Medium | Medium |
| **Lume-style parameterized** | Flexible | High | Medium-High |
| **Pure LLM** | Variable | Very High | Low |
| **Hybrid (template + LLM)** | Good | High | Medium |

### Voice Mapping Strategies

| Strategy | Flexibility | Complexity | Quality |
|----------|-------------|------------|---------|
| **Fixed mapping** | Low | Low | Consistent |
| **Metadata-driven** | High | Medium | Adaptive |
| **Expressive (tone/emotion)** | Very High | High | Nuanced |

## Implementation Tiers

### Tier 1: MVP (1-2 days)
- LLM-generated world + characters
- Hand-crafted 3-scene story
- Fixed character→voice mapping
- Existing multi-voice TTS

**Output**: 3-5 minute audio story

### Tier 2: Semi-Automated (1 week)
- Richer LLM world generation
- Automated event selection
- LLM scene generation from templates
- Dynamic voice allocation

**Output**: 15-20 minute audio story

### Tier 3: Full Pipeline (2-4 weeks)
- Choice of simulation backend
- Multiple extraction strategies
- Lume-style scene library
- Expressive voice selection
- Background soundscapes

**Output**: 30-60 minute complex narratives

## Testing Examples

### Example 1: Simple Dialogue (Tier 1)
**Location**: `examples/simulacrum-stories/simple-dialogue-test.md`

**Characters**: 3 (Sheriff, Sarah, Jack)
**Structure**: Single scene, rising tension → cliffhanger
**Duration**: ~3-4 minutes

**Test**: Character voice distinction, natural pacing

### Example 2: Three-Scene Arc (Tier 2)
**Status**: To be created

**Scenes**: Discovery → Confrontation → Resolution
**Characters**: 5-7
**Duration**: ~10-15 minutes

**Test**: Narrative coherence, character consistency

### Example 3: Full Short Story (Tier 3)
**Status**: Future

**Acts**: 3-act structure
**Scenes**: 7-10
**Characters**: 10+
**Duration**: 30+ minutes

**Test**: Compelling story, dramatic satisfaction

## Integration with Audio Lab

### What You Have ✅

- Multi-voice TTS system (doc-to-audio.py)
- Advanced audio mixing (crossfading, normalization)
- Voice palette (8+ macOS voices)
- Markdown → audio pipeline
- Background music support

### What's New ✅

- Character-based voice mapping (beyond 4 fixed types)
- Dynamic voice allocation (metadata-driven)
- Voice tag validation
- Story-to-audio orchestration
- Character profile support

### What's Next

- LLM scene generation script
- World generation script
- Event extraction algorithms
- Lume-style scene library

## Workflow Patterns

### Pattern 1: Manual Story → Audio

```bash
# Write story with voice tags
vim my_story.md

# Generate audio
./scripts/narrative-tools/story_to_audio.py \
    --input my_story.md \
    --output audio/ \
    --auto-detect-characters
```

### Pattern 2: LLM Scene → Audio

```bash
# Generate scene with LLM (future)
./scripts/narrative-tools/generate_scene.py \
    --template confrontation \
    --characters Sheriff,Sarah \
    --output scene.md

# Generate audio
./scripts/narrative-tools/story_to_audio.py \
    --input scene.md \
    --output audio/
```

### Pattern 3: Simulation → Narrative → Audio

```bash
# Generate world (future)
./scripts/narrative-tools/generate_world.py \
    --town-name Millbrook \
    --time-period 1950s \
    --output world.json

# Extract narrative (future)
./scripts/narrative-tools/extract_narrative.py \
    --world world.json \
    --protagonist Sheriff \
    --output narrative.json

# Generate scenes (future)
./scripts/narrative-tools/generate_scenes.py \
    --narrative narrative.json \
    --output scenes/

# Generate audio
for scene in scenes/*.md; do
    ./scripts/narrative-tools/story_to_audio.py \
        --input "$scene" \
        --output audio/ \
        --auto-detect-characters
done
```

## Research Sources

### Academic Papers
- "Lume: a system for procedural story generation" (Mason et al., FDG 2019)
- "Simulating Character Knowledge Phenomena in Talk of the Town" (Ryan et al.)
- "Guiding and Diversifying LLM-Based Story Generation via ASP" (arXiv 2025)
- "Narrative-to-Scene Generation" (arXiv 2025)

### Practitioners
- Emily Short (Interactive Fiction, procedural narrative)
- James Ryan (Talk of the Town, Bad News)
- Chris Crawford (Interactive storytelling theory)
- Max Kreminski (Generative narrative research)

### Related Fields
- Computational narratology
- Procedural content generation
- Interactive fiction
- Immersive theater
- Audio drama production

## Key Takeaways

1. **No generic solution**: Every narrative system requires domain-specific choices
2. **Content > Code**: Spend more time on data/templates than algorithms
3. **Track causality**: Explicit cause-and-effect records enable coherence
4. **Hybrid is best**: Combine procedural rigor with LLM creativity
5. **Test narrative quality early**: Simulation quality ≠ narrative quality
6. **Audio amplifies character**: Voice mapping is storytelling, not just tech

## Related Projects

**In This Repo**:
- Audio documentation system (multi-voice TTS)
- Phase summaries (audiobook generation)
- Coordination system (agent narratives)

**External**:
- Talk of the Town (James Ryan)
- Bad News (immersive theater)
- Dwarf Fortress (historical simulation)
- AI Dungeon (LLM interactive fiction)
- Façade (drama management)

## Next Steps

1. ✅ Research foundation (complete)
2. ✅ Character voice mapping (complete)
3. ✅ Story-to-audio pipeline (complete)
4. ⏳ Test with example scene
5. 🔜 LLM scene generation script
6. 🔜 World generation script
7. 🔜 Narrative extraction algorithms

---

**Last Updated**: 2025-10-31
**Status**: Foundation complete, implementation in progress
**Contributors**: Research synthesis by Claude Code agent
