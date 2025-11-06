# Emily Short on World Simulation for Story Generation

**Source**: [Emily Short's Interactive Storytelling Blog](https://emshort.blog/)
**Date**: Research synthesized 2025-10-31
**Context**: Foundational approaches to world simulation for narrative generation

## Core Architectural Insights

### No Generic Solution Exists

Emily Short emphasizes a critical principle: **"There is no such thing as a generic world simulator."**

Every simulation requires deliberate choices about:
- What to model
- Abstraction levels
- Which state variables matter narratively

This is fundamentally different from generic physics engines.

### The Physics Engine Misconception

**Don't assume world simulation works like physics engines.**

- **Physics engines**: Handle well-defined domains (position, velocity, elasticity)
- **Story simulation**: Must decide what qualifies as narratively significant
- **Key difference**: Narrative significance is subjective and context-dependent

### Content Data Dominates Development

A critical warning for implementers:

> "Most of my development time on a first release has gone into working and reworking the content data."

**Implication**: The generative algorithm is only part of the work. Content curation, data structures, and narrative filtering consume the majority of development time.

## What Works: Practical Systems

### IF Engines as Scaffolding

**TADS 3**:
- Pre-built world model features
- Lighting systems
- Sound propagation
- Dark room mechanics
- Good for bounded, detailed environments

**Inform 7**:
- Flexibility for adding novel relationships
- Extensible world model concepts
- Better for experimental narrative mechanics

### Layered Simulation Approaches

**Jacob Garbe's Method**:
- Mine events from existing simulators (like Dwarf Fortress)
- Construct narratives from simulation outputs
- **Advantage**: Leverage existing simulation quality
- **Challenge**: Less control over narrative relevance

**James Ryan's "Bad News"**:
- Simulate centuries of history (1839-1979)
- Extract story-worthy events from simulation
- **Advantage**: Rich historical context, emergent relationships
- **Challenge**: Requires sophisticated filtering to find narrative gold

## Critical Limitations & Scale Challenges

### Nested Environment Problem

**The Challenge**: Scaling to complex scenarios requires sophisticated architecture.

Example hierarchy:
- Landscape
  - Cities
    - Buildings
      - Rooms
        - Objects

This fractal quality of nested environments demands careful architectural planning.

### Granularity Balance

- **Too fine**: Tracking every object transfer creates noise, not meaning
- **Too coarse**: Lose consequential detail that matters narratively

### The Curation Imperative

**Success requires treating content curation as equal to algorithmic sophistication.**

Raw simulation output ≠ narrative. You need:
1. Human curation, OR
2. Algorithmic filtering to extract compelling story arcs

Example: Dwarf Fortress succeeds partly because players choose to retell its generated events.

## Design Principles for 2025

### 1. Aesthetics Matter First

Emergent narratives function "more like nonfiction than fiction—emergent stories actually happen."

This creates a distinct aesthetic experience:
- Grounded in authenticity
- Less authored drama
- More discovered meaning

### 2. Causality Must Be Trackable

**Problem**: When multiple world-state factors could partially explain outcomes, readers can't construct coherent causal chains.

**Solutions**:
- **Contingent unlocking**: Explicit preconditions
- **Causal bookkeeping**: Record why events became possible

### 3. Modularity Enables Freshness

**Anti-pattern**: Monolithic systems that retell identical character configurations

**Better**: Abstract elements that can recombine into fresh configurations while preserving meaning

### 4. Symbolic Richness Over Completeness

**Design for expressive range, not comprehensive simulation.**

Elements supporting multiple interpretive layers (like Tarot's polysemous imagery) enable deeper engagement than exhaustive but shallow coverage.

## Practical Recommendations

### For Implementers

1. **Choose your domain carefully**: What's narratively significant in YOUR story world?
2. **Build content tools early**: You'll spend more time on data than code
3. **Track causality explicitly**: Don't rely on players inferring from utility scores
4. **Plan for curation**: Either human or algorithmic
5. **Test narrative output early**: Simulation quality ≠ narrative quality

### For Testing

- Start with bounded environments (single room, single building)
- Test narrative extraction separately from simulation quality
- Evaluate based on "would someone retell this story?" not "is this realistic?"

## Integration with Audio Lab

### Opportunities

Your multi-voice TTS system maps well to:
- **Narrator voice**: Setting description, world state changes
- **Character voices**: Dialogue generated from NPC interactions
- **Archival voice**: Historical context (e.g., "In 1843, the town was founded...")

### Workflow

```
World Simulation → Event Extraction → Narrative Construction → Voice Mapping → Audio Generation
```

## References

- Emily Short's Blog: https://emshort.blog/
- Category: Procedural Narrative: https://emshort.blog/category/procedural-narrative/
- Mailbag on World Simulation: https://emshort.blog/2018/07/10/mailbag-world-simulation-plug-ins/

## Related Patterns

- Talk of the Town (James Ryan) - Temporal simulation approach
- Lume System - Combinatorial scene architecture
- Dwarf Fortress - Event mining for narrative

---

**Last Updated**: 2025-10-31
**Status**: Foundation research complete
