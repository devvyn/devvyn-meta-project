# Meta-Project Collaboration Framework

**Version**: 2.2
**Last Updated**: 2025-10-01
**Status**: Production

## Purpose

This framework governs multi-agent collaboration across all projects in the portfolio.
It defines how humans and AI agents work together effectively, manage resources,
handle risk, and evolve practices over time.

## Core Principles

### 1. **Human Agency First**

Agents manage operations. Humans manage themselves. Both need integration.
→ See: [`agents/human-agency-integration-framework.md`](agents/human-agency-integration-framework.md)

**Key Insights**:

- Trust-based contracts, not external control
- Personal agency domains (health, relationships, learning) integrate with operational domains
- Energy and capacity signals inform project planning

### 2. **Multi-Agent Collaboration**

Human + Claude Chat + Claude Code as professional equals with distinct authority domains.
→ See: [`agents/ai-collaboration-framework.md`](agents/ai-collaboration-framework.md)

**Key Patterns**:

- Bridge Communication System v3.0 for collision-safe messaging
- Clear authority domains prevent conflicts
- Session handoffs preserve context across time

### 3. **Portfolio Management**

Three-tier system balances production, development, and exploration.
→ See: [`rules/project-management-framework-v2.md`](rules/project-management-framework-v2.md)

**Tier Structure**:

- **Tier 1**: Production projects (revenue/employment critical)
- **Tier 2**: Development projects (high potential, active development)
- **Tier 3**: Experimental projects (proof of concepts, learning)

### 4. **Risk Management**

Proactive identification and mitigation of project risks.
→ See: [`rules/framework-risk-management.md`](rules/framework-risk-management.md)

**Health Indicators**:

- Green: On track, no blockers
- Yellow: Minor issues, monitoring required
- Red: Critical blockers, immediate action needed

## Current Implementation (v2.2)

### Command Standardization System

**Status**: ✅ Production operational across 4 projects

**Capabilities**:

- `/bridge-agent-create`: Spawn specialized agents with bridge integration
- `/session-handoff`: Coordinate cross-session work via bridge
- `/sync-with-native`: Synchronize bridge and native agent states
- `/deploy`: Component deployment with dependency resolution

**Integration Time**: ~2 hours per project
**Battle-Tested**: AAFC Herbarium (14 custom commands in production)

### Bridge Communication System v3.0

**Status**: ✅ Mathematically verified collision-safe

**Guarantees**:

- UUID-based namespace isolation (no collisions possible)
- FIFO message processing with atomic operations
- TLA+ formal specification verified
- Zero message loss under load

**Location**: `/bridge/` directory structure
**Documentation**: [`COORDINATION_PROTOCOL.md`](COORDINATION_PROTOCOL.md)

### Autonomous Exploration Framework

**Status**: ✅ Active for Tier 3 projects

**Capabilities**:

- Self-directed exploration within defined boundaries
- Pattern mining from existing work
- Idea evolution and cross-pollination

**Documentation**: [`AUTONOMOUS_EXPLORATION_FRAMEWORK.md`](AUTONOMOUS_EXPLORATION_FRAMEWORK.md)

## Active Projects (2025-10-01)

**Tier 1**:

- AAFC Herbarium (Darwin Core extraction, OCR optimization)

**Tier 2**:

- S3 Image Dataset Kit (AWS dataset management)
- VMemo (Voice memo processing)
- Music Library Data (Media library analysis)

**Tier 3**:

- Marino Notebook (Learning exploration)
- Barkour (Game development, pending approval)

## Framework Evolution

### Version History

- **v2.2** (2025-09-29): Command standardization, cross-project deployment patterns
- **v2.1** (2025-09-26): Professional collaboration language, authority domains refined
- **v2.0** (2025-09): Bridge v3.0 with collision prevention
- **v1.x** (2025-08): Initial multi-agent coordination

### Strategic Decisions Log

→ See: [`key-answers.md`](key-answers.md)

Tracks major decisions, cross-project insights, and framework guidance as the system evolves.

## Quick Start for New Projects

1. **Read this document** for framework overview
2. **Check tier classification** in project-management-framework-v2.md
3. **Set up bridge integration** using COORDINATION_PROTOCOL.md
4. **Review command system** in `.claude/commands/README.md`
5. **Create project CLAUDE.md** inheriting meta-project protocols

## Specialized Framework Components

| Component | Purpose | Location |
|-----------|---------|----------|
| Human Agency Integration | Personal domain management | `agents/human-agency-integration-framework.md` |
| AI Collaboration Patterns | Multi-agent coordination | `agents/ai-collaboration-framework.md` |
| Portfolio Management | Project tiers and resource allocation | `rules/project-management-framework-v2.md` |
| Risk Management | Health monitoring and escalation | `rules/framework-risk-management.md` |
| Bridge Communication | Agent messaging protocol | `COORDINATION_PROTOCOL.md` |
| Autonomous Exploration | Self-directed learning and pattern mining | `AUTONOMOUS_EXPLORATION_FRAMEWORK.md` |
| Framework Validation | Current status and metrics | `status/framework-validation-2025-09.md` |

## Principles in Practice

### Zen Simplicity

- One canonical entry point (this document)
- Clear separation of concerns (specialized frameworks)
- Remove what isn't essential, preserve what is

### Functional Purity

- Immutable message passing (bridge system)
- State derivation over state storage
- Pure functions for coordination logic

### Human-Agent Harmony

- Trust-based collaboration, not control
- Clear authority boundaries
- Sustainable pace over maximum throughput

---

**Next**: Choose the specialized framework that matches your current need, or continue to [`key-answers.md`](key-answers.md) for strategic context.
