# Discovered Patterns Library

## Inter-Agent Communication Patterns

### INTER_AGENT_MEMO Pattern

**Context**: Transfer institutional knowledge between agent sessions
**Implementation**:

- File: `PROJECT_ROOT/INTER_AGENT_MEMO.md`
- Content: Historical patterns, implementation priorities, future agent guidance
- Update trigger: When significant patterns emerge that future agents should know

**Success Indicators**: Reduced redundant discovery, faster context switching
**Example**: AAFC herbarium project gist pattern extraction and application roadmap

### Session Handoff Protocol

**Context**: Clean transfer of context and action items between Chat and Code sessions
**Implementation**:

- End of Chat: Write handoff summary with decisions and implementation queue
- Start of Code: Review handoff, implement priority items, prepare return summary

**Success Indicators**: No dropped tasks, maintained strategic alignment
**Refinement**: Bridge system replaces manual handoff with structured messaging

### Event-Driven Bridge Communication

**Context**: Efficient information sharing without polling overhead
**Implementation**:

- Inbox/outbox directories with priority-based messages
- Context preservation through structured logs
- Clear action expectations for receiving agent

**Success Indicators**: No wasted context checks, faster response to critical updates
**Status**: Newly implemented, needs validation through use

---

## Technical Implementation Patterns

### Framework Evolution Pattern

**Context**: Systematic improvement of collaboration frameworks
**Implementation**:

1. Identify limitation or bias in current framework
2. Design inclusive solution addressing root cause
3. Implement across all relevant documents
4. Validate through practical application

**Success Indicators**: Improved collaboration efficiency, reduced friction
**Example**: v2.0 → v2.1 human-centric bias correction

### Authority Domain Separation

**Context**: Optimize agent effectiveness by working in strength domains
**Implementation**:

- Agent domains: Technical implementation, pattern recognition, code optimization
- Human domains: Strategic priorities, domain expertise, stakeholder communication
- Shared domains: Quality standards, timeline planning, resource allocation

**Success Indicators**: Reduced micromanagement, increased autonomous productivity
**Refinement**: Continuously adjust based on collaboration experience

---

## Pattern Template

```markdown
### Pattern Name
**Context**: [When/why this pattern applies]
**Implementation**: [How to execute this pattern]
**Success Indicators**: [How to know it's working]
**Example/Status**: [Real usage or current state]
```
