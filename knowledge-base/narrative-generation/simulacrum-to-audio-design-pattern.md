# Simulacrum Worlds → Dramatic Audio Reading: Design Pattern

**Date**: 2025-10-31
**Context**: End-to-end pipeline for procedurally generated narrative worlds to multi-voice audio stories
**Status**: Design pattern for implementation

## Pattern Overview

**Problem**: How to generate coherent, dramatically engaging audio stories from procedurally generated world simulations?

**Solution**: Multi-stage pipeline combining:
1. World simulation (procedural or LLM-generated)
2. Narrative extraction (event selection + story arc)
3. Scene generation (LLM-assisted with character consistency)
4. Voice mapping (characters → TTS voices)
5. Audio production (multi-voice TTS + mixing)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ STAGE 1: WORLD SIMULATION                                   │
├─────────────────────────────────────────────────────────────┤
│ Options:                                                     │
│ • Full simulation (Talk of the Town style) - 200 years      │
│ • Light simulation (key events only) - weeks/months         │
│ • LLM generation (world backstory + events) - instant       │
│                                                              │
│ Output: World state + event history + character profiles    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 2: NARRATIVE EXTRACTION                               │
├─────────────────────────────────────────────────────────────┤
│ • Event salience scoring (what's narratively interesting?)  │
│ • Story arc construction (3-act, 5-act, or hero's journey)  │
│ • Character selection (protagonist, antagonist, supporting) │
│ • Causality chain (why did events happen in this order?)    │
│                                                              │
│ Output: Ordered list of narrative beats with participants   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 3: SCENE GENERATION                                   │
├─────────────────────────────────────────────────────────────┤
│ • Scene templates (confrontation, discovery, revelation)    │
│ • LLM-assisted dialogue (character profiles → consistency)  │
│ • Voice tag insertion (<VOICE:CHARACTER_NAME>)              │
│ • Narrator beats (scene-setting, transitions)               │
│                                                              │
│ Output: Markdown with voice tags                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 4: VOICE MAPPING                                      │
├─────────────────────────────────────────────────────────────┤
│ • Character → Voice allocation (dynamic)                    │
│ • Voice palette selection (gender, accent, age balance)     │
│ • Narrator voice selection (distinct from characters)       │
│                                                              │
│ Output: Voice mapping config                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STAGE 5: AUDIO PRODUCTION                                   │
├─────────────────────────────────────────────────────────────┤
│ • Multi-voice TTS (doc-to-audio.py --multi-voice)           │
│ • Advanced mixing (crossfading, normalization)              │
│ • Background audio (atmospheric soundscape - optional)      │
│                                                              │
│ Output: Final MP3 audio story                               │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Tiers

### Tier 1: MVP (Minimal Viable Product)

**Timeline**: 1-2 days

**Components**:
1. **World**: LLM-generated town + 3 characters + event backstory
2. **Narrative**: Hand-crafted 3-scene story arc
3. **Scenes**: LLM-generated dialogue with manual voice tags
4. **Voices**: Fixed character→voice mapping
5. **Audio**: Existing doc-to-audio.py with `--multi-voice`

**Output**: 3-5 minute audio story, 3 characters, single narrative thread

**Example**:
```bash
# Generate world with LLM
echo "Generate a small American town (1950s) with 3 characters..." | \
  claude-api > world.json

# Write scenes manually with character tags
cat > scene1.md << EOF
<VOICE:NARRATOR>Summer, 1952. The town of Millbrook...</VOICE:NARRATOR>
<VOICE:CHARACTER_Sheriff>I need to ask you about the fire.</VOICE:CHARACTER_Sheriff>
...
EOF

# Generate audio
./scripts/doc-to-audio.py \
  --input scene1.md \
  --output audio/ \
  --provider macos \
  --multi-voice
```

### Tier 2: Semi-Automated

**Timeline**: 1 week

**Additions**:
1. **World**: LLM-generated with richer detail (10 characters, 20 events)
2. **Narrative**: Automated event selection (salience scoring)
3. **Scenes**: LLM generates full scenes from templates
4. **Voices**: Dynamic character→voice allocation
5. **Audio**: Same TTS system

**Output**: 15-20 minute audio story, 5-7 characters, multi-threaded plot

**New Scripts**:
- `generate-world.py`: LLM prompt → structured world data
- `extract-narrative.py`: Events → story arc with beats
- `generate-scenes.py`: Story beats → scenes with voice tags
- `allocate-voices.py`: Characters → TTS voice mapping

### Tier 3: Full Pipeline

**Timeline**: 2-4 weeks

**Additions**:
1. **World**: Choice of simulation backend (Talk of the Town-lite, LLM, or hybrid)
2. **Narrative**: Multiple extraction strategies (character-focused, event-focused, theme-focused)
3. **Scenes**: Lume-style parameterized scene library
4. **Voices**: Expressive voice selection (tone, emotion metadata)
5. **Audio**: Background soundscape generation, music cues

**Output**: 30-60 minute audio story, 10+ characters, complex narrative with subplots

## Voice Mapping Strategy

### Fixed Mapping (Tier 1)

```python
# Simple character ID → voice name
VOICE_MAP = {
    'CHARACTER_Sheriff': 'Jamie',
    'CHARACTER_Sarah': 'Serena',
    'CHARACTER_Jack': 'Lee',
    'NARRATOR': 'Aman'
}
```

### Dynamic Allocation (Tier 2)

```python
# Allocate voices based on character metadata
def allocate_voice(character, used_voices, voice_palette):
    # Consider: gender, age, role, personality

    # Sheriff (male, authoritative) → deep, serious voice
    if character.role == 'authority' and character.gender == 'male':
        return select_voice(voice_palette, ['Jamie', 'Aman'], used_voices)

    # Teacher (female, educated) → clear, precise voice
    elif character.role == 'educator' and character.gender == 'female':
        return select_voice(voice_palette, ['Serena', 'Tara'], used_voices)

    # Bartender (male, casual) → relaxed, friendly voice
    elif character.role == 'service' and character.gender == 'male':
        return select_voice(voice_palette, ['Lee'], used_voices)

    # Fallback: allocate from remaining voices
    else:
        return select_voice(voice_palette, None, used_voices)
```

### Expressive Mapping (Tier 3)

```python
# Include tone, emotion, speaking style
VOICE_CONFIG = {
    'CHARACTER_Sheriff': {
        'voice': 'Jamie',
        'default_tone': 'authoritative',
        'speaking_rate': 0.9,  # Slightly slower (deliberate)
        'pitch_shift': -0.1     # Slightly lower (gravitas)
    },
    'CHARACTER_Sarah': {
        'voice': 'Serena',
        'default_tone': 'cautious',
        'speaking_rate': 1.0,
        'pitch_shift': 0.0
    }
}
```

## Scene Templates

### Confrontation Template

```markdown
**Template ID**: confrontation_private
**Dramatic Function**: Rising action, revelation
**Participants**: 2 characters (confronter, confronted)
**Parameters**: topic, location, relationship_tension

---

<VOICE:NARRATOR>{{location_description}}. {{atmosphere_description}}.</VOICE:NARRATOR>

<VOICE:{{confronter}}>{{opening_line_based_on_relationship}}</VOICE:{{confronter}}>

<VOICE:{{confronted}} tone="{{defensive_tone}}">{{evasive_response}}</VOICE:{{confronted}}>

<VOICE:NARRATOR>{{body_language_description}}.</VOICE:NARRATOR>

<VOICE:{{confronter}} tone="{{pressing_tone}}">{{topic_specific_accusation}}</VOICE:{{confronter}}>

<VOICE:{{confronted}} tone="{{emotional_state}}">{{confession_or_denial}}</VOICE:{{confronted}}>

<VOICE:NARRATOR>{{resolution_setup}}.</VOICE:NARRATOR>
```

### Discovery Template

```markdown
**Template ID**: discovery_evidence
**Dramatic Function**: Inciting incident, complication
**Participants**: 1 character (discoverer)
**Parameters**: object, location, significance

---

<VOICE:NARRATOR>{{time_of_day}} at {{location}}. {{character}} was {{activity_before_discovery}}.</VOICE:NARRATOR>

<VOICE:{{discoverer}} tone="surprised">{{internal_monologue_reaction}}</VOICE:{{discoverer}}>

<VOICE:NARRATOR>{{object_description}}. {{why_it_matters}}.</VOICE:NARRATOR>

<VOICE:{{discoverer}} tone="{{realization_tone}}">{{decision_what_to_do_next}}</VOICE:{{discoverer}}>
```

### Group Discussion Template

```markdown
**Template ID**: group_discussion
**Dramatic Function**: Exposition, debate
**Participants**: 3+ characters
**Parameters**: topic, location, consensus_level

---

<VOICE:NARRATOR>{{gathering_description}}. {{participants_listed}}.</VOICE:NARRATOR>

<VOICE:{{character_1}}>{{opening_statement_about_topic}}</VOICE:{{character_1}}>

<VOICE:{{character_2}} tone="{{agreement_or_disagreement}}">{{response_based_on_personality}}</VOICE:{{character_2}}>

<VOICE:{{character_3}}>{{third_perspective}}</VOICE:{{character_3}}>

<VOICE:NARRATOR>{{tension_escalation_or_consensus}}.</VOICE:NARRATOR>

<VOICE:{{character_1}} tone="{{emotional_response}}">{{concluding_statement}}</VOICE:{{character_1}}>
```

## LLM Prompt Templates

### World Generation Prompt

```
You are a procedural world generator for dramatic audio stories.

Generate a small American town suitable for narrative drama.

Requirements:
- Time period: 1950s
- Population: ~300
- 5-7 named characters with depth
- 10-15 pre-existing events (backstory)
- 3-5 secrets/tensions that could drive plot
- Geographic layout (key locations)

Output format: JSON

{
  "town": {
    "name": "...",
    "population": 300,
    "founding_year": 1843,
    "economy": "..."
  },
  "characters": [
    {
      "name": "...",
      "age": 45,
      "role": "...",
      "personality": ["...", "..."],
      "secrets": ["..."],
      "relationships": {"character_id": "relationship_type"},
      "voice_characteristics": "..."
    }
  ],
  "events": [
    {
      "date": "1952-06-15",
      "description": "...",
      "participants": ["character_id"],
      "witnesses": ["character_id"],
      "significance": "high|medium|low"
    }
  ],
  "secrets": [
    {
      "description": "...",
      "known_by": ["character_id"],
      "consequences_if_revealed": "..."
    }
  ]
}
```

### Scene Generation Prompt

```
You are a dramatic scene writer for audio stories.

Scene Template: {{template_id}}
Characters:
{{#each characters}}
- {{name}}: {{personality}}, knows: {{knowledge_state}}, goals: {{goals}}
{{/each}}

Context:
- Previous scenes: {{scene_history_summary}}
- Current dramatic beat: {{beat_description}}
- Location: {{location}}
- Emotional tone: {{tone}}

Task: Generate dialogue for this scene.

Requirements:
1. Stay in character (reference personality, knowledge, goals)
2. Characters can only reference events they know about
3. Include character voice tags: <VOICE:CHARACTER_{{name}}>
4. Include narrator voice tags for scene-setting: <VOICE:NARRATOR>
5. Length: 10-15 lines of dialogue
6. End with {{ending_type}} (unresolved tension | revelation | cliffhanger | resolution)

Output format: Markdown with voice tags
```

### Narrative Arc Extraction Prompt

```
You are a narrative designer extracting stories from event timelines.

Events:
{{#each events}}
{{index}}. {{date}}: {{description}} (participants: {{participants}})
{{/each}}

Task: Create a 3-act story structure.

Requirements:
1. Select 7-10 most narratively significant events
2. Arrange in dramatic arc: Setup → Inciting Incident → Rising Action → Climax → Resolution
3. Identify protagonist, antagonist (if applicable), supporting characters
4. Define central conflict
5. Explain causality (why events happen in this order)

Output format: JSON

{
  "structure": "three_act",
  "protagonist": "character_id",
  "antagonist": "character_id or null",
  "conflict": "...",
  "acts": [
    {
      "act": 1,
      "beats": [
        {
          "event_id": "...",
          "function": "setup | inciting_incident",
          "participants": ["..."],
          "scene_template": "..."
        }
      ]
    }
  ]
}
```

## File Structure

```
project/
├── worlds/
│   ├── millbrook.json           # Generated world data
│   └── schemas/
│       └── world-schema.json    # JSON schema for validation
│
├── narratives/
│   ├── millbrook-act1.json      # Extracted story arc
│   └── schemas/
│       └── narrative-schema.json
│
├── scenes/
│   ├── millbrook-scene01.md     # Generated scenes with voice tags
│   ├── millbrook-scene02.md
│   └── templates/
│       ├── confrontation.md     # Scene templates
│       └── discovery.md
│
├── voices/
│   └── millbrook-voice-map.json # Character → voice allocation
│
├── audio/
│   ├── millbrook_part001.mp3    # Final audio output
│   └── millbrook_metadata.json
│
└── scripts/
    ├── generate-world.py        # Stage 1
    ├── extract-narrative.py     # Stage 2
    ├── generate-scenes.py       # Stage 3
    ├── allocate-voices.py       # Stage 4
    └── doc-to-audio.py          # Stage 5 (existing ✅)
```

## Testing Strategy

### Test 1: Single Scene (MVP)

**Input**: Manually written scene with 2 characters
**Output**: 1-2 minute audio clip
**Success Criteria**: Clear voice distinction, natural pacing

### Test 2: Three-Scene Arc

**Input**: LLM-generated scenes with narrative progression
**Output**: 5-7 minute audio story
**Success Criteria**: Narrative coherence, character consistency

### Test 3: Full Short Story

**Input**: Procedurally generated world → extracted narrative → generated scenes
**Output**: 15-20 minute audio story
**Success Criteria**: Compelling story, multiple characters distinguishable, dramatic arc satisfying

## Next Immediate Steps

1. **Create character voice extension** for doc-to-audio.py (beyond 4 fixed types)
2. **Write example 2-character scene** manually
3. **Test with existing multi-voice TTS**
4. **Build generate-scenes.py** for LLM-assisted scene creation
5. **Integrate end-to-end**

## References

- Emily Short: World simulation foundations
- Talk of the Town: Temporal simulation + knowledge modeling
- Lume: Combinatorial scene architecture
- LLM techniques: 2025 state of the art for narrative generation
- Your audio lab: Multi-voice TTS + advanced mixing ✅

---

**Last Updated**: 2025-10-31
**Status**: Design pattern documented
**Next**: Implement character voice mapping extension
