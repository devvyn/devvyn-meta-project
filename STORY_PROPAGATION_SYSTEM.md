# Story Propagation System - Simplified

**Version**: 2.0 (Simplified)
**Philosophy**: Patterns with Evidence and Context
**Status**: Core concept preserved, analysis tools archived

---

## What Is This

Stories = **Patterns + Evidence + Context**

Traditional pattern libraries document "what works" but lack context. Stories add:
- **Context**: Where/When/Why/Who - the story of discovery  
- **Evidence**: Concrete data proving the pattern's value
- **Propagation**: Tracking adoption across projects

## Story Event Structure

### Core Fields
```markdown
# story: [Title]

**Event-ID**: [timestamp]-story-[uuid]
**Timestamp**: YYYY-MM-DDTHH:MM:SS-TIMEZONE
**Type**: story
**Discoverer**: [agent or human]
**Pattern-Source**: [Where pattern originated]
```

### Story Content
```markdown
## Story
[How was pattern discovered? What problem did it solve?
Why does it matter? Tell the story that makes it memorable.]

## Context
**Where**: [Project/environment]
**When**: [Time period and conditions]
**Why**: [Problem needing solution]
**Who**: [Agents/humans involved]

## Evidence
[Concrete data supporting the story]
- Adoption metrics
- Success rates
- Impact measurements

## Propagation History
**Origin**: [Where story emerged]
**Spread to**: [Which projects adopted]
**Current Reach**: [Adoption status]

## Memetic Fitness
**Adoption Rate**: [% of exposed contexts that adopted]
**Success Rate**: [% of adoptions that succeeded]
**Impact Score**: [Measured improvement]
**Fitness**: [adoption × success × impact]
```

## Creating Stories

### When to Create a Story Event

✅ **DO create stories for:**
- Patterns solving recurring problems
- Techniques working across multiple projects
- Insights changing how you coordinate
- Workflows succeeding in production

❌ **DON'T create stories for:**
- One-off technical fixes
- Project-specific implementation details
- Unproven ideas (wait for evidence)

### Story Creation

```bash
./scripts/create-story.sh "Story Title" discoverer "Pattern Source"

# Example
./scripts/create-story.sh \
  "Testing Strategy Enables Rapid Iteration" \
  code \
  "S3 Image Dataset Kit"
```

Script prompts for:
- Narrative (story of discovery)
- Context (Where/When/Why/Who)
- Evidence (metrics, success data)
- Propagation (origin, spread, mutations)
- Memetic Fitness (adoption, success, impact)

**Output**: Immutable story event in `bridge/events/`

## Integration with Bridge

Stories are **first-class events** in event log:
- Immutable once created
- Corrections via story-mutation events
- Included in state derivation
- Part of coordination history

## Current Stories

View stories in event log:
```bash
ls -1 bridge/events/*-story-*.md
```

## Archived Tools

**Analysis scripts archived** to `~/infrastructure/future-experiments/story-analysis-tools/`:
- `generate-reality-map.sh` - Comprehensive snapshot reports
- `information-flow-topology.sh` - Network graph analysis
- `shared-reality-registry.sh` - Reality layers visualization
- `track-story-propagation.sh` - Propagation tracking

**Why archived**: Created 1039 lines of code, but only 3 stories created in 5 days. Tools unused, pure overhead. Core concept (patterns with evidence) remains valuable.

**Restore if needed**: Tools are preserved, not deleted.

---

## Quick Reference

```bash
# Create new story
./scripts/create-story.sh "Title" discoverer "Origin"

# View all stories
ls -1 bridge/events/*-story-*.md

# Read a story
cat bridge/events/[story-file].md
```

---

**Philosophy**: Information creates reality through context + narrative + propagation.  
**Reality**: Document patterns that actually matter, skip the complexity theater.
**Status**: Simplified from 1861 lines to ~150 lines. Core value preserved.
