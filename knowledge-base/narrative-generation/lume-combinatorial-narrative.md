# Lume: Combinatorial Scene Architecture for Reactive Narratives

**Authors**: Stacey Mason, Chris Stagg, Noah Wardrip-Fruin (UC Santa Cruz)
**Venue**: FDG 2019 (Fourteenth International Conference on the Foundations of Digital Games)
**Source**: Expressive Intelligence Studio, UC Santa Cruz
**Date Synthesized**: 2025-10-31

## Core Innovation

Lume addresses a fundamental tension in interactive narrative:

**The Dilemma**:
- **Large emergent possibility spaces** → Less narrative structure, weak coherence
- **Strong narrative structure** → Small possibility spaces, limited reactivity

**Lume's Solution**: Combine both through a **combinatorial scene architecture**

## Key Concept: The Possibility Space vs. Structure Spectrum

### Traditional Approaches

**Simulation-Heavy (left side)**:
- Examples: Dwarf Fortress, The Sims
- Strength: Massive emergent possibility space
- Weakness: Weak narrative structure, random-feeling stories

**Author-Heavy (right side)**:
- Examples: Telltale Games, visual novels
- Strength: Strong narrative arc, coherent themes
- Weakness: Limited player impact, "illusion of choice"

**Lume's Position**: Center of spectrum
- **Both** large possibility space **and** narrative structure
- Reactive narratives that feel coherent

## Combinatorial Scene Architecture

### What Makes It Different?

**Traditional Storylets**: Discrete, complete scenes
- Scene A, Scene B, Scene C
- Selected based on preconditions
- Limited variability within each scene

**Lume's Parameterized Storylets**: Flexible scene templates
- Scenes are **node-trees** with parameters
- Can be **reconfigured** based on context
- **Content reuse** across different narrative situations

### Parameterized Scene Example

**Basic Storylet** (traditional):
```
Scene: "Hero confronts villain"
- Fixed dialogue
- Fixed outcome
- Plays if: hero_location == villain_location
```

**Lume Parameterized Scene**:
```
Scene: "Character A confronts Character B about [TOPIC]"
Parameters:
  - CharacterA: [any_character with motivation:revenge]
  - CharacterB: [any_character with secret:[TOPIC]]
  - TOPIC: [player_discovered_secrets]
  - Location: [CharacterB.current_location]
  - Tone: based_on(CharacterA.relationship[CharacterB])

Node Tree:
  1. Arrival → parameterized by location
  2. Accusation → parameterized by topic + tone
  3. Response → parameterized by CharacterB.personality + topic.severity
  4. Resolution → branching based on player choice + character states
```

**Advantage**: Same scene structure reusable with:
- Different characters
- Different topics
- Different locations
- Different relationship dynamics

### Content Reuse with Narrative Reactiveness

**The Goal**: Make more content feel "catered to the player's past decisions"

**How Parameterization Helps**:
1. **Reference past events**: `[TOPIC]` can be any player discovery
2. **Adapt to relationships**: Tone changes based on character history
3. **React to world state**: Location, time, character knowledge all feed in

**Example**: "Confrontation" scene might:
- Reference the bakery fire (if player investigated it)
- OR reference the missing money (if player found the ledger)
- OR reference the secret affair (if player witnessed it)
- **Same scene template**, different narrative meaning

## Logic Programming for Content Selection

**Approach**: Build on logic programming (similar to ASP, Prolog)

**Scene Selection Process**:
1. **Current context**: World state, character states, narrative position
2. **Query**: "What scenes are valid and interesting now?"
3. **Logic rules**: Evaluate preconditions for all parameterized scenes
4. **Ranking**: Score scenes by narrative appropriateness
5. **Selection**: Choose highest-ranked scene
6. **Parameterization**: Fill in scene parameters from context

**Advantage**: Construct coherent narrative through **series of contextually appropriate moments**

### Example Logic Rules

```prolog
% Scene is valid if preconditions met
valid_scene(confrontation(A, B, Topic)) :-
    character(A),
    character(B),
    A \= B,
    motivated(A, confront(B)),
    topic_known_by(A, Topic),
    topic_secret_of(Topic, B),
    location(A, Loc),
    location(B, Loc).

% Scene is interesting if creates tension
interesting(confrontation(A, B, Topic), Score) :-
    relationship_tension(A, B, RTension),
    topic_severity(Topic, Severity),
    narrative_position(Act),
    Score is RTension * Severity * act_weight(Act).
```

## Architecture Components

### 1. World Model

**Tracks**:
- Character states (location, knowledge, goals, emotions)
- Object states (position, ownership, properties)
- Relationship graph (who knows/likes/opposes whom)
- Event history (what happened, when, who witnessed it)

### 2. Scene Library

**Contains**:
- Parameterized scene templates (node-trees)
- Precondition logic for each scene
- Narrative function tags (exposition, rising action, climax, etc.)

### 3. Selection Engine

**Logic programming system that**:
- Queries valid scenes given current world state
- Ranks scenes by narrative appropriateness
- Handles parameter binding

### 4. Execution Engine

**Instantiates selected scene**:
- Binds parameters to concrete values
- Traverses node-tree based on player choices + character states
- Updates world model with scene outcomes

## Narrative Coherence Mechanisms

### How Lume Maintains Story Coherence

**1. Causal Consistency**:
- Scenes update world state
- Future scene selection respects updated state
- No contradictions (if X happened, Y acknowledges it)

**2. Narrative Arc Awareness**:
- Scenes tagged with dramatic function
- Selection engine prefers appropriate function for current act
- Prevents anti-climactic ordering

**3. Character Consistency**:
- Parameterization respects character knowledge
- Characters can't reference events they didn't witness
- Personality influences scene execution (not just selection)

**4. Thematic Continuity**:
- Topics/themes tracked across scenes
- Related scenes get higher selection priority
- Creates through-lines even in emergent narratives

## Comparison to Other Systems

| System | Approach | Strength | Weakness |
|--------|----------|----------|----------|
| **Lume** | Combinatorial parameterized scenes | Balance of reactivity + structure | Complexity of scene authoring |
| **Façade** | Drama manager + beat selection | Strong reactivity | Limited scope, brittle |
| **Versu** | Social simulation + story grammar | Rich social modeling | Computationally expensive |
| **Ink** | Branching narrative scripting | Author control, proven | Less emergent, manual branching |
| **StoryNexus** | Storylets + Quality-Based Narrative | Modular, extensible | Linear feel despite branching |

**Lume's Niche**: More structured than simulation, more reactive than branching narratives

## Practical Implementation Lessons

### What Makes Parameterization Work

**Good Parameters**:
- Character roles (can bind to multiple NPCs)
- Topics/objects (can reference different player discoveries)
- Locations (scenes work in multiple places)
- Emotional tones (adapt to relationship state)

**Bad Parameters**:
- Too specific (only work in one context → no reuse)
- Too generic (lose narrative meaning)
- Unbound (infinite possibilities → hard to author for)

### Scene Authoring Challenges

**Trade-off**: Flexibility vs. Authorial Control
- More parameters → More reusable → Harder to write compelling prose
- Fewer parameters → Easier to write → Less adaptive

**Recommendation**: Parameterize **context** (who, where, what topic), keep **dialogue structure** authored

## Integration with Audio Dramatic Reading

### How Lume Principles Apply

**Parameterized Character Mapping**:
```python
# Instead of fixed NARRATOR, CODE, QUOTE
# Use parameterized character binding

scene_params = {
    'confronter': 'Sheriff_Thompson',  # → Jamie (authoritative male)
    'confronted': 'Sarah_Mitchell',     # → Serena (precise female)
    'witness': 'Jack_Turner',           # → Lee (casual male)
    'topic': 'bakery_incident'
}

# Scene generates dialogue with character tags
# TTS maps character IDs → voices
```

**Reactive Scene Selection for Audio Stories**:
1. World state: Characters, locations, events
2. Select scene: "Confrontation at general store"
3. Parameterize: Bind characters, topic, emotional tone
4. Generate: Produce markdown with character voice tags
5. Synthesize: Your multi-voice TTS system

### Example Lume-Style Audio Scene

**Scene Template**: "Private Conversation"

**Parameters**:
- SpeakerA: Character with secret
- SpeakerB: Character who suspects
- Location: Private setting
- Topic: The secret
- Tone: Based on relationship + topic severity

**Generated Output**:
```markdown
<VOICE:NARRATOR>Late evening at the schoolhouse. Sarah Mitchell sat alone, grading papers by lamplight.</VOICE:NARRATOR>

<VOICE:CHARACTER_Sheriff>Mind if I come in, Miss Mitchell?</VOICE:CHARACTER_Sheriff>

<VOICE:CHARACTER_Sarah tone="cautious">Of course, Sheriff. Is something wrong?</VOICE:CHARACTER_Sarah>

<VOICE:NARRATOR>Thompson closed the door behind him. The air grew heavy with unspoken questions.</VOICE:NARRATOR>

<VOICE:CHARACTER_Sheriff tone="serious">I think you know why I'm here. The bakery fire. You were there that morning.</VOICE:CHARACTER_Sheriff>
```

**Key**: Same template could be:
- Doctor + Patient about medical records
- Bartender + Patron about town gossip
- Siblings about family inheritance

## Implementation Path for Your Project

### Phase 1: Simple Parameterization

**Start with**:
- 3-5 character archetypes (sheriff, teacher, bartender, etc.)
- 5-10 scene templates (confrontation, confession, discovery, etc.)
- Basic parameter types (character, location, topic)

**Don't need**:
- Full logic programming (use simple if/then rules)
- Complex world simulation
- Dynamic scene generation

### Phase 2: LLM-Assisted Scene Instantiation

**Workflow**:
1. Define scene template with parameters
2. Use LLM to fill in dialogue given parameters
3. Add character voice tags
4. Process with your TTS system ✅

**Example Prompt**:
```
Scene Template: Private Conversation (Confrontation variant)
Parameters:
- SpeakerA: Sheriff Thompson (authoritative, direct, suspicious)
- SpeakerB: Sarah Mitchell (cautious, moral, hiding something)
- Location: Schoolhouse (evening, private, tense atmosphere)
- Topic: Bakery fire (SpeakerA suspects SpeakerB knows something)

Generate 8-10 lines of dialogue where SpeakerA confronts SpeakerB.
Include character voice tags: <VOICE:CHARACTER_Sheriff>, <VOICE:CHARACTER_Sarah>
Include narrator voice tags for scene-setting: <VOICE:NARRATOR>
Tone should be tense but civil.
End on unresolved tension.
```

### Phase 3: Scene Library + Selection

**Build**:
- Library of 20-30 parameterized scene templates
- Simple selection rules (if player discovered X, scene Y becomes available)
- Sequential scene selection to build story arc

**Test**: Generate 5-scene short story with narrative coherence

## Key Takeaways for Simulacrum Stories

1. **Parameterization enables reuse**: Same scene structure, different narrative contexts
2. **Logic-based selection**: Coherent scene sequencing without manual authoring
3. **Balance emergence and structure**: Reactive while maintaining narrative arc
4. **Content types**: Separate structure (reusable) from details (LLM-generated)

## References

- Paper: "Lume: a system for procedural story generation" (FDG 2019)
- PDF: https://eis.ucsc.edu/papers/Mason_Lume.pdf
- Authors: Stacey Mason, Chris Stagg, Noah Wardrip-Fruin
- Related: Expressive Intelligence Studio, UC Santa Cruz

## Next Steps

1. Implement basic scene template system
2. Test LLM scene instantiation with parameters
3. Build character-to-voice mapping in doc-to-audio.py ✅ (next task)
4. Generate first multi-scene audio story

---

**Last Updated**: 2025-10-31
**Status**: Research complete
**Next**: Design character voice mapping extension
