# Bridge System Usage Guide - Simplified Approach

## Two-Tier Communication Strategy

### Tier 1: Project README Review Requests (Lightweight)

**When to use**: Quick questions, code reviews, implementation feedback
**Location**: Project `CLAUDE.md` files under "## Review Requests for Chat Agent"
**Process**:

1. Add question to project README
2. Mention in next Chat session
3. Chat agent updates INTER_AGENT_MEMO with feedback

**Examples**:

- "Does this architecture handle edge cases?"
- "Is 92% accuracy sufficient for production?"
- "Should we optimize for speed or memory?"

### Tier 2: Bridge System (Structured)

**When to use**: Strategic decisions, blocking issues, major architecture changes
**Location**: `bridge/inbox/` and `bridge/outbox/`
**Process**: Use full message template with priority levels

**Use Bridge For**:

- **CRITICAL**: Blocking production issues, immediate decisions needed
- **HIGH**: Major architectural changes, cross-project impacts, strategic shifts
- **NORMAL**: Weekly summaries, project status updates
- **INFO**: Skip - use README pattern instead

## Decision Matrix

| Scenario | Use | Why |
|----------|-----|-----|
| Quick question about implementation | README | No context switch needed |
| Code review request | README | Lightweight, async |
| Production system down | Bridge CRITICAL | Needs immediate attention |
| Architecture decision affects multiple projects | Bridge HIGH | Strategic impact |
| Weekly progress summary | Bridge NORMAL | Formal handoff |
| "Does this look right?" | README | Simple feedback |
| Stakeholder changed requirements | Bridge HIGH | Strategic change |

## Current Status: Testing Phase

**Week 1**: Monitor which approach gets used more
**Goal**: Find the right balance between structure and simplicity
**Success Metric**: Both agents actually use the system without friction

## Guidelines for Chat Agent

### Reading Code's Messages

1. **Start session**: Check `bridge/outbox/chat/` for new messages
2. **Priority order**: CRITICAL → HIGH → NORMAL → Project READMEs
3. **Response**: Use bridge for strategic, INTER_AGENT_MEMO for technical

### Responding to Code

1. **Strategic decisions**: Write to `bridge/inbox/code/`
2. **Technical feedback**: Update project INTER_AGENT_MEMO files
3. **Quick answers**: Direct response in Chat conversation

## Guidelines for Code Agent

### Sending Messages to Chat

1. **Blocking issues**: Use bridge CRITICAL priority
2. **Architecture questions**: Use bridge HIGH priority
3. **Implementation questions**: Add to project README
4. **Weekly summaries**: Use bridge NORMAL priority

### Processing Messages from Chat

1. **Check bridge inbox** at session start
2. **Process by priority**: CRITICAL first
3. **Archive processed messages** to maintain clean inbox
4. **Update project status** in relevant files

## Evolution Path

This simplified approach lets us:

- Use the bridge when it adds value
- Avoid overhead for simple questions
- Monitor actual usage patterns
- Adjust complexity based on real needs

If we find we're using the bridge constantly, we can add more structure. If we rarely use it, we can simplify further. The key is finding what actually works in practice, not in theory.
