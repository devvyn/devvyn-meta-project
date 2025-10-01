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

## Slash Command Development Patterns

### Advanced Orchestration Commands Pattern

**Context**: Complex projects benefit from sophisticated slash command systems for multi-agent coordination
**Implementation**:

- **Deployment Registry**: `/deploy list` showing organized component categories (infrastructure, agents, specifications, research, development)
- **Agent Creation**: `/bridge-agent-create [type] [name]` with specialized types (darwin-core, ocr-benchmark, pattern-analysis, scientific-review)
- **Session Coordination**: `/session-handoff [target] [priority] [title]` for cross-session workflows
- **Infrastructure Management**: `/bridge-extraction-prep`, `/sync-with-native` for system evolution

**Success Indicators**: Seamless multi-agent workflows, reduced coordination overhead, scalable command discovery
**Example**: AAFC Herbarium project - 14 commands enabling hybrid orchestration with proven production use
**Status**: Ready for framework propagation - HIGH priority bridge message sent for strategic review

### Command Propagation Pattern

**Context**: Valuable slash commands developed in specialized projects should benefit the broader framework
**Implementation**:

1. **Document Discovery**: Bridge context update with command inventory and value assessment
2. **Strategic Review**: HIGH priority bridge message to meta-project for evaluation
3. **Framework Integration**: Commands become standardized patterns for cross-project use
4. **Community Scaling**: Template creation for other projects to develop domain-specific commands

**Success Indicators**: Cross-project command reuse, accelerated project development, standardized orchestration patterns
**Example**: Current propagation of AAFC commands to meta-project framework
**Status**: Phase 1 (Strategic Review) initiated via bridge messaging system

---

## Pattern Template

```markdown
### Pattern Name
**Context**: [When/why this pattern applies]
**Implementation**: [How to execute this pattern]
**Success Indicators**: [How to know it's working]
**Example/Status**: [Real usage or current state]
```
