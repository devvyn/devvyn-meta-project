# LLM + Procedural Narrative Generation: 2025 State of the Art

**Research Date**: 2025-10-31
**Context**: Emerging techniques for using LLMs in procedural narrative generation
**Key Question**: How can large language models augment traditional procedural narrative systems?

## Leading Models for Story Generation (2025)

### Top Tier: Creative Writing

**Claude Sonnet 4.5 & Opus 4.1** (Anthropic)
- "LLMs with the most soul in their writing"
- Excel at creating vivid characters
- Maintain consistent narrative voice
- Strong at structured, logical narratives

**GPT-4.5** (OpenAI)
- Benchmark-setting performance
- Good at plot coherence
- Handles long-form narrative

**Claude 3.7 Sonnet**
- Best for structured, clear writing
- Logic and clarity over flair
- Good for technical narrative elements

**Gemini 2.5** (Google)
- New benchmark in creative writing
- Strong multimodal capabilities

### Key Finding

**Dramatic transformation in 2025**: Models now generate "original narratives and inventive scenarios" rather than derivative content.

## Procedural Narrative Generation Techniques

### 1. Answer Set Programming (ASP) + LLM

**Paper**: "Guiding and Diversifying LLM-Based Story Generation via Answer Set Programming"

**Approach**:
- ASP generates diverse story outlines (structure)
- LLM fills in narrative details (prose)
- ASP ensures logical consistency
- LLM provides creative variation

**Benefits**:
- Combines procedural rigor with creative flexibility
- Generates artifacts from story outlines to game levels
- Well-established in PCG research

**Use Case**: Generate 10 story variants that share structural elements but differ in character choices, outcomes

### 2. Narrative-to-Scene Generation

**Paper**: "Narrative-to-Scene Generation: An LLM-Driven Pipeline for 2D Game Environments" (arXiv 2025)

**Approach**:
- Short narrative prompts → sequences of 2D tile-based scenes
- Reflects temporal structure of stories
- Lightweight pipeline

**Innovation**: Bridges narrative and visual/spatial representation

**Example**:
```
Prompt: "The hero enters the dark forest and finds an abandoned cabin."
Output: [Forest tile grid] → [Cabin tile grid with door] → [Interior cabin scene]
```

**Relevance for Audio**: Similar temporal sequencing for audio scenes

### 3. Character-Driven Generation

**Method**: Use LLM to maintain character consistency across scenes

**Technique**:
1. Define character profile (personality, background, goals, voice)
2. Include profile in every generation prompt
3. Ask LLM to generate dialogue/actions "in character"
4. Track character knowledge state (what they know/don't know)

**Example Prompt Template**:
```
Character: Sarah Mitchell
- Age: 34, schoolteacher
- Personality: Observant, moral, cautious
- Current knowledge: Witnessed the bakery incident, hasn't told anyone
- Speaking style: Precise, uses complete sentences, rarely uses contractions

Scene: Sarah encounters the Sheriff at the general store.
Generate dialogue where Sarah hints at what she knows without directly confessing.
```

### 4. Narrative Planning Perspective

**Paper**: "Can LLMs Generate Good Stories? Insights and Challenges from a Narrative Planning Perspective"

**Key Findings**:
- GPT-4 tier LLMs can generate causally sound stories at **small scales**
- **Struggle with**: Character intentionality, dramatic conflict planning
- **Best at**: Local coherence (sentence-to-sentence)
- **Weak at**: Global coherence (plot arc over full story)

**Implication**: Use LLMs for scene-level generation, use traditional planning for plot structure.

## Current Limitations (2025)

### 1. Narrative Pacing Problems

**Finding**: GPT-4 exhibits "notable deficiencies in narrative pacing"

**Specific Issues**:
- Inadequate development of turning points
- Weak major setbacks
- Anti-climactic climaxes
- Rush through important moments

**Workaround**:
- Human-authored plot points
- LLM generates transitions/details
- Explicit pacing instructions in prompts

### 2. Character Intentionality

**Problem**: LLMs struggle to maintain character goals across story arc

**Example Failure**:
- Character wants revenge in Act 1
- Forgets about it in Act 2
- Suddenly remembers in Act 3 (inconsistent)

**Solution**:
- Maintain explicit character goal tracker
- Include in every prompt: "Character X is currently pursuing [goal]"
- Use structured representation (not just prose)

### 3. Dramatic Conflict

**Challenge**: LLMs tend toward conflict resolution, not escalation

**Pattern**: Stories end too early, tensions deflate prematurely

**Technique**:
- Prompt engineering: "The situation gets WORSE, not better"
- Explicit dramatic arc specification
- Prevent resolution until designated climax point

## Hybrid Architectures (Best Practice 2025)

### Pattern 1: Structure + Flesh

```
Traditional PCG → High-level plot structure
         ↓
LLM → Scene details, dialogue, descriptions
         ↓
Post-processing → Consistency check, editing
```

**Example**:
- ASP generates: "Character A betrays Character B at the town meeting"
- LLM generates: Dialogue, emotional reactions, setting details
- Human/algorithm verifies: Consistent with character profiles

### Pattern 2: Simulation + Narration

```
World Simulation (e.g., Talk of the Town) → Events
         ↓
Event Extraction → Narratively significant moments
         ↓
LLM → Convert events to prose narrative
         ↓
TTS → Audio generation
```

**Advantage**: Simulation ensures causal consistency, LLM handles prose quality

### Pattern 3: Iterative Refinement

```
LLM → Draft story
         ↓
Evaluation → Check pacing, conflict, character consistency
         ↓
LLM → Refine with explicit feedback
         ↓
Repeat until quality threshold met
```

**Cost**: Multiple LLM calls per story
**Benefit**: Higher quality output

## Prompt Engineering for Narrative Quality

### Voice Consistency Template

```
You are writing in the voice of [CHARACTER].

Character Profile:
- Background: [...]
- Personality: [...]
- Current emotional state: [...]
- Speaking style: [examples]

Context: [What character knows about current situation]

Task: Generate dialogue for this scene where [scenario].
Constraints:
- Stay in character
- Use established speaking patterns
- React based on character's knowledge only (not omniscient)
```

### Pacing Control Template

```
Story Arc Position: [Act 2, Scene 3 of 5]
Dramatic Function: [Rising Action - complications increase]

Current Tension Level: 6/10
Target Tension Level: 8/10

Task: Generate the next scene.
Requirements:
- Introduce new obstacle
- Do NOT resolve main conflict
- Increase stakes
- End on cliffhanger or revelation
```

### Narrative Coherence Template

```
Story So Far:
- Major events: [bullet list]
- Character states: [who knows what, current goals]
- Unresolved threads: [active plot points]
- World state: [relevant facts about setting]

Constraints:
- Must reference at least one prior event
- Cannot contradict established facts
- Must advance at least one unresolved thread

Generate next scene:
```

## Integration with Audio Production

### Voice Mapping Strategy

**Approach**: Use LLM to generate voice direction tags

**Example Output**:
```markdown
<VOICE:NARRATOR tone="mysterious">The town fell silent as the stranger approached.</VOICE:NARRATOR>

<VOICE:SHERIFF tone="suspicious">I don't recognize you. State your business.</VOICE:SHERIFF>

<VOICE:STRANGER tone="calm" accent="slight-southern">Just passing through, officer. Heard this was a friendly town.</VOICE:STRANGER>
```

**Your System Can**:
- Parse character tags → map to TTS voices
- Use tone/accent as prompt metadata (future enhancement)
- Narrator vs. character already supported ✅

### Scene-Based Generation

**Unit of Work**: Single scene (not full story)

**Workflow**:
1. Generate scene with LLM (with character profiles, plot point)
2. Parse for voice tags
3. Send to your doc-to-audio.py with `--multi-voice`
4. Stitch scenes together

**Advantage**: Manage complexity, enable parallelization

## Practical Recommendations for Your Project

### Start Simple: 3-Character Dialogue

**Scenario**: Three townsfolk discussing a mysterious event

**Characters**:
1. Sheriff (Jamie - authoritative UK male)
2. Schoolteacher (Serena - precise UK female)
3. Bartender (Lee - casual AU male)

**Method**:
1. Write character profiles (100 words each)
2. Define event they're discussing
3. Prompt Claude/GPT to generate 10 lines of dialogue
4. Add voice tags manually
5. Process with your TTS system

**Test**: Does it sound like a dramatic reading?

### Scale Up: Short Story Generation

**Approach**: Hybrid ASP + LLM

1. **Structure** (manual or ASP):
   - Opening: Town introduction, 3 characters
   - Inciting incident: Strange event occurs
   - Rising action: Characters investigate, conflict emerges
   - Climax: Revelation and confrontation
   - Resolution: New equilibrium

2. **Scene Generation** (LLM):
   - Generate each scene with explicit pacing instructions
   - Include character knowledge tracking
   - Maintain voice consistency

3. **Audio Production** (your system ✅):
   - Multi-voice TTS with character mapping
   - Advanced mixing with crossfading
   - Background atmospheric audio

### Full Pipeline: Simulacrum Worlds

**Vision**: Procedurally generated towns → extracted narratives → dramatic audio

**Phase 1**: Story generation (LLM-based)
- Character profiles generated by LLM
- Plot structure from templates or ASP
- Scene details from LLM with character consistency

**Phase 2**: Voice mapping (extend your system)
- Character-to-voice mapping (beyond 4 fixed types)
- Dynamic voice allocation based on character count
- Tone/emotion parameters (future)

**Phase 3**: Audio production (existing system ✅)
- Your multi-voice TTS
- Advanced mixing
- Background audio layers

## Tools & Libraries

**Story Structure**:
- Clingo (ASP solver)
- Inform 7 (IF engine with narrative tools)
- Tracery (grammar-based generation)

**LLM Integration**:
- Anthropic Claude API
- OpenAI GPT API
- LangChain (orchestration)

**Audio** (you have):
- doc-to-audio.py ✅
- Multi-voice TTS ✅
- Audio mixing ✅

## References

- "Guiding and Diversifying LLM-Based Story Generation via Answer Set Programming" (arXiv)
- "Narrative-to-Scene Generation" (arXiv 2509.04481)
- "Can LLMs Generate Good Stories?" (arXiv 2506.10161)
- "Are LLMs Capable of Human-Level Narratives?" (arXiv 2407.13248)
- Papers with Code: Story Generation (https://paperswithcode.com/task/story-generation/)

---

**Last Updated**: 2025-10-31
**Status**: Research complete
**Next**: Implement character voice mapping in doc-to-audio.py
