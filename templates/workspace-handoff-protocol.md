# Inter-Workspace Communication Protocol

## Overview

## Workspace Hierarchy

### Head Office: ~/devvyn-meta-project/

- `key-answers.md`: Real-time strategic consultation

- `status/current-project-state.json`: Decision tracking and alerts

**Role**: Implementation focus, pattern application, progress reporting
**Files**:

- `.claude/CLAUDE.md`: Project-specific context and development focus

## Handoff Protocol

**Before switching workspaces:**

1. Create/update `.claude/CLAUDE.md` in target project
2. Document current priorities and context
3. Update meta-project status with handoff timestamp
4. Establish communication expectations

- Current development phase and priorities
- Strategic decisions from key-answers.md
- Resource constraints and time allocation
- Cross-project patterns to apply

**When starting work in implementation workspace:**

1. Read `.claude/CLAUDE.md` for project context
2. Review `INTER_AGENT_MEMO.md` for proven patterns
3. Check recent git activity for current state

**Sync Command Response:**

- Load project-specific priorities
- Report current development focus

- Escalate blockers to meta-project
- Update progress in INTER_AGENT_MEMO

**Daily Updates** (Implementation → Meta):

- Progress on current patterns/features
- Implementation discoveries or challenges
- Pattern effectiveness feedback

**Strategic Consultation** (Meta → Implementation):

- Resource allocation changes
- Priority adjustments via key-answers.md

**Escalation Triggers**:

- Technical blockers requiring strategic decisions
- Resource conflicts or capacity issues

## File Templates

### .claude/CLAUDE.md Structure

# [Project Name] - Claude Code Configuration

## Project Context

- Phase, tech stack, meta-project integration

## Current Development Focus

- High/medium priority patterns

## Development Guidelines

- Standards, dependencies, testing requirements

## Inter-Workspace Communication

- Strategic decision references
- Progress update protocols
- Escalation procedures

## Sync Command Response Protocol

- Context loading sequence
- Priority identification process

- Progress reporting format

```

### INTER_AGENT_MEMO Updates

```markdown

## Implementation Status: [Date]
- Pattern: [Name] → Status: [In Progress/Complete/Blocked]
- Discoveries: [Technical insights or challenges]
- Next Steps: [Immediate priorities]
- Meta-Project Feedback: [Strategic implications]
```

## Best Practices

### Context Switching

1. **Clean handoff**: Complete current task or document stopping point
2. **Context preservation**: Update both workspace configurations
3. **Priority alignment**: Sync strategic objectives with implementation focus
4. **Communication setup**: Establish clear escalation channels

### Progress Tracking

1. **Implementation level**: Update INTER_AGENT_MEMO with technical progress
2. **Strategic level**: Update meta-project status with resource impacts
3. **Cross-project**: Identify pattern opportunities for other projects
4. **Timeline**: Maintain realistic development velocity expectations

### Quality Assurance

1. **Pattern validation**: Test gist-proven approaches before new solutions
2. **Documentation**: Maintain clear development decision trails
3. **Integration**: Ensure changes align with broader project portfolio
4. **Feedback loops**: Regular meta-project consultation for course correction

---

**Last Updated**: 2025-09-25
**Usage**: Apply when transitioning between strategic planning and focused development
