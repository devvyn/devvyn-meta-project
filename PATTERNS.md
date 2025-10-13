# Patterns - Story-Based System

**Approach**: Patterns documented as stories with evidence
**Location**: `bridge/events/*-story-*.md`
**Philosophy**: Patterns without context are hard to remember and propagate slowly

## Pattern System

Stories = **Patterns + Evidence + Context + Propagation**

Instead of maintaining separate pattern files, we document patterns as story events that include:
- **Pattern**: What works (the technique/approach)
- **Evidence**: Measurable impact (adoption rate, success rate, ROI)
- **Context**: Where/when/why it was discovered
- **Propagation**: How it spreads across projects

## Creating Pattern Stories

```bash
./scripts/create-story.sh "Pattern Title" discoverer "Origin Project"
```

See: `STORY_PROPAGATION_SYSTEM.md` for full documentation

## Current Pattern Stories

View all pattern stories:
```bash
ls -1 bridge/events/*-story-*.md
```

Each story contains:
- Discovery narrative
- Evidence (metrics, adoption data)
- Propagation history
- Memetic fitness (adoption × success × impact)

## Why Stories Instead of Pattern Lists

**Traditional pattern library**:
```
Pattern: Command Standardization
Description: Standardize commands across projects
Implementation: [technical details]
```

**Pattern as story**:
```
Story: Command Standardization System Proves Cross-Project Valuable

Evidence:
- 100% adoption rate (4/4 exposed projects)
- 2-hour integration vs days of manual setup
- 60% coordination overhead reduction
- Zero deployment failures

Propagation: AAFC → s3-kit, python-toolbox, claude-hooks, marino
```

Stories provide context that makes patterns:
- **Memorable**: Narrative sticks better than lists
- **Measurable**: Evidence shows actual value
- **Propagatable**: Track adoption across projects
- **Trustworthy**: Proven in production, not theory

## Migrated Content

**Decision patterns for automation** archived to `~/infrastructure/future-experiments/decision-patterns-hopper.md`

**Why**: HOPPER agent (automated decision-maker) disabled - never found review requests to process. Patterns were for automation that isn't running.

**Core patterns** that matter are captured as stories with evidence.

---

**Pattern library = Story event log**  
**Decision rules = In stories, proven by evidence**
**Propagation = Tracked automatically in story structure**
