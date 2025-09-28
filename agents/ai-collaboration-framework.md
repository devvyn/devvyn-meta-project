# Multi-Agent Collaboration Framework v2.1

## Human + Claude Chat + Claude Code as Professional Collaboration

### Meeting Categories

#### Strategic Planning Sessions (Claude Chat)

- **Purpose**: Portfolio review, framework evolution, high-level decision making
- **Typical Duration**: 30-90 minutes
- **Deliverables**: Updated frameworks, strategic decisions, priority adjustments
- **Professional Description**: "Strategic planning and portfolio architecture review"
- **Reporting**: "Collaborative strategic planning session focused on project portfolio optimization"

#### Technical Architecture Reviews (Claude Code)

- **Purpose**: Code review, system design, implementation planning
- **Typical Duration**: 45-120 minutes
- **Deliverables**: Code implementations, architecture decisions, technical documentation
- **Professional Description**: "Technical architecture review and implementation planning"
- **Reporting**: "Collaborative technical review session for [project name] architecture"

#### Project Coordination Meetings (Claude Chat)

- **Purpose**: Cross-project dependency resolution, resource allocation, timeline planning
- **Typical Duration**: 20-60 minutes
- **Deliverables**: Resource reallocation decisions, dependency maps, timeline adjustments
- **Professional Description**: "Project coordination and resource optimization review"
- **Reporting**: "Multi-project coordination meeting addressing resource allocation and dependencies"

#### Framework Development Sessions (Claude Chat + Code)

- **Purpose**: Meta-project tooling, process improvement, automation development
- **Typical Duration**: 60-180 minutes
- **Deliverables**: Process documentation, automation tools, workflow improvements
- **Professional Description**: "Process development and automation implementation"
- **Reporting**: "Framework development session for project management optimization"

### Inter-Agent Knowledge Transfer

#### Bridge Communication System v1.0

- **Purpose**: Event-driven messaging between Claude Chat and Claude Code agents
- **Location**: `bridge/` directory with inbox/outbox structure
- **Message Format**: Priority-based with context, content, and expected action
- **Context Preservation**: `bridge/context/` for decisions, patterns, and state tracking
- **Benefits**: Eliminates polling overhead, provides clear priorities, maintains audit trail

#### INTER_AGENT_MEMO Pattern (Legacy)

- **Purpose**: Pass institutional knowledge and proven patterns between agent sessions
- **Format**: `PROJECT_ROOT/INTER_AGENT_MEMO.md`
- **Content**: Historical patterns, implementation priorities, future agent guidance
- **Example**: aafc-herbarium project's gist pattern extraction and application roadmap
- **Update Cycle**: When significant patterns or learnings emerge that future agents should know
- **Migration**: Bridge system provides structured alternative for most use cases

#### Standard Inter-Agent Memo Structure

```markdown
# Inter-Agent Memo: [Project Context]

**Project**: [name]
**Date**: [YYYY-MM-DD]
**Source**: [Context/Analysis source]
**Purpose**: [Knowledge transfer objective]

## Key Applicable Patterns
[Proven solutions from historical work]

## Implementation Priorities
[Clear roadmap for future agents]

## Integration Guidelines
[Technical requirements and constraints]

## Testing Strategy
[How to validate implementations]

---
**Note for Future Agents**: [Explicit guidance]
```

### Session Handoff Protocol

#### Bridge Communication (Recommended)

**Chat → Code**: Write priority message to `bridge/inbox/code/`
**Code → Chat**: Write response/summary to `bridge/outbox/chat/`
**Context**: Automatically preserved in `bridge/context/` files

#### Legacy Handoff Protocol

#### End of Claude Chat Session

```
## HANDOFF TO CLAUDE CODE WORKSPACE
**Session Type**: [Strategic Planning/Project Coordination/Technical Consultation]
**Date**: [YYYY-MM-DD]
**Duration**: [XX minutes]

### Decisions Made
- [ ] [Decision 1 with specific action required]
- [ ] [Decision 2 with specific action required]

### Implementation Queue
1. **IMMEDIATE** (This session): [Specific task]
2. **THIS WEEK**: [Specific task]
3. **NEXT SESSION**: [Specific task]

### Context for Claude Code
[2-3 sentence summary of where we are and what needs to happen next]
```

#### Start of Claude Code Session

```
## RECEIVING HANDOFF FROM CLAUDE CHAT
**Source Chat**: [Chat URI]
**Last Strategic Session**: [Date]

### Implementation Checklist
- [ ] Review decisions from strategic session
- [ ] Implement priority items from queue
- [ ] Update project documentation
- [ ] Prepare summary for next chat handoff
```

### Professional Language Guide

#### Use These Terms

- "Collaborative planning session"
- "Strategic architecture review"
- "Process optimization meeting"
- "Technical consultation"
- "Framework development session"
- "Resource allocation review"

#### Avoid These Terms

- "Chatting with AI"
- "Playing around with Claude"
- "AI experiment time"
- "Automated assistance"

---

**Integration**: Extends existing collaboration-rules.md with multi-agent collaboration protocols
**Bridge System**: See `bridge/README.md` for detailed usage instructions
**Status**: Active implementation phase with Bridge v1.0 operational
