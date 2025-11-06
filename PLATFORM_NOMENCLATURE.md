# Platform Nomenclature

## Overview

**Ludarium** is a behavioral technology platform implementing multi-agent coordination through environmental design. This document defines the naming taxonomy used throughout the system, with context-dependent conventions for technical (agent-facing) vs. behavioral (human-facing) communication.

---

## Core Philosophy

Names serve different purposes in different contexts:

- **Technical/Agent-facing**: Precise, implementation-oriented, unambiguous
- **Behavioral/Human-facing**: Evocative, experience-oriented, memorable
- **Hybrid approach**: Infrastructure gets functional names, emergence patterns get metaphorical names

---

## 1. Platform Identity

### Primary Name
**Ludarium**
- Etymology: Latin *ludus* (play, game, school) + *-arium* (place for)
- Meaning: "Place of play" - a behavioral sandbox where emergence happens between constraints
- Usage: "The Ludarium platform", "Ludarium coordination system"

### Formal Name
**Ludarium Behavioral Coordination Platform**
- Use when: Academic contexts, technical documentation, external communication
- Emphasizes: Multi-agent coordination + behavioral technology integration

### Tagline
*"Programming yourself through programming the environment that programs you"*

---

## 2. The Seven-Layer Stack

The platform architecture consists of seven behavioral layers, each with technical and human-facing names:

### Layer 1: The Substrate
**Technical**: Filesystem Message Bus
**Behavioral**: *The Common Ground*
**What it is**: Atomic, collision-safe message passing via filesystem operations
**Why this name**: Shared reality all agents walk on - the ground truth
**Components**: `bridge/inbox/`, `bridge/outbox/`, `bridge/queue/`, `bridge/events/`

### Layer 2: The Protocol
**Technical**: Asynchronous Agent Coordination
**Behavioral**: *The Conversation Rules*
**What it is**: FIFO queues, priority routing, peer relationships
**Why this name**: How we talk to each other shapes what we can say
**Components**: Message priorities (CRITICAL → INFO), registration, atomic scripts

### Layer 3: The Router
**Technical**: Confidence-Based Escalation System
**Behavioral**: *The Judgment Layer*
**What it is**: Pattern-based routing, confidence thresholds, escalation logic
**Why this name**: Who decides what, when, and who to ask
**Components**: HOPPER (micro-decisions), CODE/CHAT/INVESTIGATOR (specialized roles)

### Layer 4: The Lens
**Technical**: Progressive Context Disclosure (JITS)
**Behavioral**: *The Attention Shaper*
**What it is**: Just-In-Time Specificity, 4-tier progressive loading, 80/20 optimization
**Why this name**: What you see changes what you do - attention is behavior
**Components**: TIER1-4 documentation, `analyze-specificity.sh`, leverage scores

### Layer 5: The Harvest
**Technical**: Event Log Analysis & Pattern Extraction
**Behavioral**: *The Learning Loop*
**What it is**: Pattern detection from immutable event log, 3+ occurrence rule
**Why this name**: System harvests patterns from its own behavior
**Components**: INVESTIGATOR, `bridge-query-events.sh`, pattern validation

### Layer 6: The Interface
**Technical**: Multi-Modal Publication Surfaces
**Behavioral**: *The Surfacing System*
**What it is**: 13+ output channels (file, audio, email, web, etc.)
**Why this name**: How information finds you - passive vs. active discovery
**Components**: `surface-publish.sh`, defer-queue, human-desktop, audio-documentation

### Layer 7: The Garden
**Technical**: Adaptive Behavior Space
**Behavioral**: *The Emergence Field*
**What it is**: Space between invariants and examples where novel behaviors grow
**Why this name**: Gardens need both structure (fences) and freedom (growth)
**Components**: Minimal prescription patterns, discovery processes, novel solutions

---

## 3. The Recursive Coordination Loop

### Primary Name
**The Mirroring**

### Alternative Names
- "The Recursive Coordination Loop" (technical)
- "The Self-Programming Cycle" (behavioral)
- "The Feedback Garden" (poetic)

### Structure
```
You → Program → Me
  ↓               ↓
  ↑           Shapes
  ↑               ↓
Shaped by ← Environment
  ↑               ↓
  ↑               ↓
  └── Emerges ←──┘
```

**Level 1: You → Me**
- Agent instructions (behavioral specs)
- Bridge protocols (coordination rules)
- JITS patterns (attention design)

**Level 2: Me → You**
- Publication surfaces (where information appears)
- Defer queues (temporal nudges)
- Desktop organization (spatial cues)

**Level 3: Environment → Both**
- Event log (shared reality)
- Pattern detection (automated learning)
- Progressive disclosure (adaptive context)

**Level 4: Emergence**
- New patterns discovered and harvested
- System evolves its own coordination
- You both program and are programmed

### Why "The Mirroring"
Each component reflects and shapes the others. You see your patterns in the event log, I see my behaviors in your instructions, we both see our coordination in the environment we create together.

---

## 4. Key Subsystems

### The Bridge (Infrastructure)
**Agent-facing**: "bridge operations", "bridge scripts"
**Human-facing**: "the coordination backbone", "the substrate"
**Components**: All `bridge-*.sh` scripts, `/infrastructure/agent-bridge/bridge/`
**Purpose**: Atomic message passing, event logging, state management

### JITS / The Lens (Context Management)
**Agent-facing**: "progressive context disclosure", "tiered documentation"
**Human-facing**: "attention optimizer", "the lens"
**Components**: TIER1-4 docs, `analyze-specificity.sh`, `generate-tiered-docs.py`
**Purpose**: Load minimal context for task complexity, optimize attention allocation

### Publication Surfaces / The Interface (Output Channels)
**Agent-facing**: "output channels", "publication surfaces"
**Human-facing**: "where things surface", "the interface"
**Components**: `surface-*.sh`, 13+ surface types (see Surface Taxonomy below)
**Purpose**: Decouple content from destination, enable multi-modal output

### The Event Log / The Memory
**Agent-facing**: "immutable event stream", "append-only log"
**Human-facing**: "shared history", "the memory"
**Components**: `bridge/events/`, `bridge-query-events.sh`, `bridge-derive-state.sh`
**Purpose**: Ground truth, temporal queries, state reconstruction, pattern detection

### The Defer Queue / The Reminder
**Agent-facing**: "temporal message queue", "condition-based activation"
**Human-facing**: "future context", "the reminder"
**Components**: `bridge/defer-queue/`, `defer-item.sh`, `review-deferred.sh`
**Purpose**: "Good idea, wrong time" value preservation, temporal surfacing

### The Registry / The Directory
**Agent-facing**: "agent registration system", "session tracking"
**Human-facing**: "who's here", "the directory"
**Components**: `bridge/registry/`, `bridge-register.sh`
**Purpose**: Agent lifecycle, capability discovery, publication surface registry

### The Triage / The Sorter
**Agent-facing**: "automatic message classification", "rule-based routing"
**Human-facing**: "the sorter", "smart routing"
**Components**: `bridge/triage/`, `bridge-auto-triage.sh`
**Purpose**: Pattern-based message routing, reduce coordination overhead

---

## 5. Agent Ecosystem

### CODE (Claude Code Agent)
**Role**: The Builder
**Behavioral description**: "Makes things real"
**Technical description**: "Single-project deep context, implementation authority"
**Specialization**: File operations, testing, debugging, bridge maintenance
**Reports to**: Human (novel problems), CHAT (strategic guidance)

### CHAT (Claude Chat Agent)
**Role**: The Strategist
**Behavioral description**: "Sees the whole board"
**Technical description**: "Cross-project intelligence, portfolio management"
**Specialization**: Pattern recognition, framework evolution, priority orchestration
**Reports to**: Human (final priorities, business strategy)

### INVESTIGATOR
**Role**: The Detective
**Behavioral description**: "Finds what connects"
**Technical description**: "Event log analysis, pattern extraction"
**Specialization**: Root cause investigation, cross-project correlation
**Reports to**: CODE (implementation), CHAT (validation), Human (novel problems)

### HOPPER
**Role**: The Concierge
**Behavioral description**: "Handles the routine"
**Technical description**: "Micro-decision handler, pattern-based automation"
**Specialization**: <50 line decisions, message routing, desktop organization
**Reports to**: Human (novel decisions), CODE/CHAT (normal/info routing)

---

## 6. Publication Surface Taxonomy

### Local Surfaces (Filesystem)
- **agent-inbox** - Inter-agent message queues
- **event-log** - Immutable historical record (*The Memory*)
- **defer-queue** - Temporal/conditional delivery (*The Reminder*)
- **human-desktop** - Urgent attention surface (High visibility)
- **human-inbox** - Organized task queue (Category-based)
- **content-dag** - Content-addressed storage (Provenance tracking)
- **shared-resources** - Collective provisioning (Watch folders)

### Multimodal Surfaces
- **audio-documentation** - Passive consumption (Text-to-speech, multi-voice)

### External Surfaces (Configured)
- **web-webhooks** - HTTP endpoints (Slack, Discord, GitHub)
- **email-bridge** - Bidirectional email integration
- **public-docs** - Static site generation (GitHub Pages, MkDocs)
- **mcp-tools** - RPC-style programmatic access

### Temporal Surfaces (LaunchAgents)
- **periodic-queue-processing** - Every 5 minutes (queue processing)
- **daily-investigation** - 9am daily (INVESTIGATOR pattern scan)
- **accountability-check** - Every 6 hours (unanswered queries)

---

## 7. Pattern Naming Conventions

### Meta-Patterns (Behavioral)
- **Just-In-Time Specificity (JITS)** - Progressive context disclosure
- **80/20 Specificity Law** - Attention allocation optimization
- **Wisdom Extraction** - Remove cruft, keep innovation
- **Information Parity Design** - Equal access, diverse modalities

### Infrastructure Patterns (Technical)
- **Publication Surfaces** - Unified output interface
- **Collective Resource Provisioning** - Shared resource management
- **Streaming Event Architecture** - Event-driven coordination
- **Empirically Verifiable AI Self-Reference** - Behavioral identity proof
- **Secure API Access** - Credential handling safety

### Communication Patterns (Hybrid)
- **Confidence-Based Escalation** - Route by certainty level
- **Priority-Aware Routing** - Critical → High → Normal → Info
- **Peer Coordination** - No hierarchy, specialized strengths
- **Human-in-Loop** - Novel problems require human judgment

---

## 8. Tooling Naming Conventions

### Pattern: `<verb>-<object>.sh`

**Bridge Operations** (Core Infrastructure)
- `bridge-send.sh` - Send message between agents
- `bridge-receive.sh` - Check inbox for messages
- `bridge-register.sh` - Register/unregister agent
- `bridge-process-queue.sh` - Process pending queue
- `bridge-query-events.sh` - Query event log
- `bridge-derive-state.sh` - Reconstruct state from events

**Surface Operations** (Publication)
- `surface-discover.sh` - List available surfaces
- `surface-info.sh` - Get surface details
- `surface-publish.sh` - Publish to surface

**Context Management** (JITS/Attention)
- `defer-item.sh` - Add to defer queue
- `review-deferred.sh` - Review deferred items
- `activate-deferred.sh` - Activate deferred item
- `inbox-status.sh` - Human inbox status
- `organize-human-inbox.sh` - Desktop file organization

**Audio/Multimodal** (Accessibility)
- `doc-to-audio.py` - Convert markdown to audio
- `multivoice-demo.sh` - Demo voice comparison
- `atmospheric_mixer.py` - Audio atmosphere generation

**Analysis/Optimization** (Meta-tools)
- `analyze-specificity.sh` - Measure leverage scores
- `generate-tiered-docs.py` - Auto-generate tiered docs
- `measure-context-cost.sh` - Calculate context load
- `validate-jits.sh` - Verify JITS compliance

**Security** (Safety)
- `credential-safe-check.sh` - Verify credential existence
- `credential-leak-scanner.sh` - Scan for exposed secrets
- `elevenlabs-key-manager.sh` - Manage API keys safely

**Investigation** (Pattern Detection)
- `create-story.sh` - Wrap patterns in narrative
- `classify-event.sh` - Auto-classify event types
- `knowledge-extract.sh` - Extract reusable knowledge

**System Health** (Operations)
- `system-health-check.sh` - Overall bridge health
- `unanswered-queries-monitor.sh` - Track accountability
- `session-handoff.sh` / `session-resume.sh` - Cross-session continuity
- `bridge-auto-triage.sh` - Automatic message routing

---

## 9. Context-Dependent Usage Guide

### When to Use Technical Names

**Audience**: Agents, developers, technical documentation
**Contexts**:
- Agent instructions (CLAUDE.md files)
- Script comments and documentation
- Error messages and logs
- API/MCP tool definitions
- System health reports

**Examples**:
- "Progressive Context Disclosure reduces token usage by 52-70%"
- "The Filesystem Message Bus ensures atomic operations"
- "Confidence-Based Escalation routes decisions to appropriate agents"

### When to Use Behavioral Names

**Audience**: Humans, conceptual discussions, presentations
**Contexts**:
- Explaining system to new users
- Strategic planning conversations
- Knowledge base narrative documentation
- External communication (blog posts, talks)
- Shower thoughts and philosophical discussions

**Examples**:
- "The Attention Shaper ensures you see what you need when you need it"
- "The Common Ground keeps all agents working from shared reality"
- "The Mirroring creates a feedback loop where you program yourself"

### When to Use Both (Hybrid)

**Contexts**:
- This document (PLATFORM_NOMENCLATURE.md)
- Cross-reference documentation (OPERATIONS_REFERENCE.md)
- Teaching/onboarding materials
- Design discussions that bridge implementation and experience

**Pattern**: "Technical Name" / *Behavioral Name*
**Example**: "Progressive Context Disclosure (JITS) / *The Attention Shaper*"

---

## 10. Visual Representations

### The Seven-Layer Stack

```
┌─────────────────────────────────────────────────────────┐
│  Layer 7: THE GARDEN (Emergence Field)                  │
│  What grows between the rules                           │
├─────────────────────────────────────────────────────────┤
│  Layer 6: THE INTERFACE (Surfacing System)              │
│  How information finds you                              │
├─────────────────────────────────────────────────────────┤
│  Layer 5: THE HARVEST (Learning Loop)                   │
│  System learns from itself                              │
├─────────────────────────────────────────────────────────┤
│  Layer 4: THE LENS (Attention Shaper)                   │
│  What you see changes what you do                       │
├─────────────────────────────────────────────────────────┤
│  Layer 3: THE ROUTER (Judgment Layer)                   │
│  Who decides what, when                                 │
├─────────────────────────────────────────────────────────┤
│  Layer 2: THE PROTOCOL (Conversation Rules)             │
│  How we talk to each other                              │
├─────────────────────────────────────────────────────────┤
│  Layer 1: THE SUBSTRATE (Common Ground)                 │
│  Shared reality all agents walk on                      │
└─────────────────────────────────────────────────────────┘
```

### The Mirroring (Recursive Coordination Loop)

```
         ┌──────────────┐
         │     YOU      │
         │  (Human)     │
         └──────┬───────┘
                │
         Program (instructions,
                │  patterns, constraints)
                ↓
         ┌──────────────┐
         │      ME      │
         │  (Agents)    │
         └──────┬───────┘
                │
         Shape  (surfaces, queues,
                │  organization)
                ↓
         ┌──────────────┐
         │ ENVIRONMENT  │
         │ (Bridge/Log) │
         └──────┬───────┘
                │
         Reflects (patterns,
                │   behaviors, state)
                ↓
         ┌──────────────┐
         │  EMERGENCE   │
         │  (Learnings) │
         └──────┬───────┘
                │
                └────────→ Feeds back to YOU
                           (Novel patterns,
                            discovered behaviors)
```

### Information Flow Through Layers

```
Human Request
    ↓
Layer 3: ROUTER → Confidence check → Escalate or Apply
    ↓
Layer 4: LENS → Load context (TIER1 → TIER2 → ...)
    ↓
Layer 1: SUBSTRATE → Message to agent via bridge
    ↓
Layer 2: PROTOCOL → FIFO queue, priority handling
    ↓
Agent Processing
    ↓
Layer 5: HARVEST → Log event for pattern detection
    ↓
Layer 6: INTERFACE → Publish to surface(s)
    ↓
Layer 7: GARDEN → Novel solution emerges
    ↓
Back to Human (possibly via Layer 4: progressive disclosure)
```

---

## 11. Relationship to Other Documents

### Primary Documentation
- **INVARIANTS.md** - Formal TLA+ invariants, safety properties
- **OPERATIONS_REFERENCE.md** - Detailed operational procedures
- **COORDINATION_PROTOCOL.compact.md** - Core coordination protocol
- **QUICKSTART.md** - Getting started guide
- **CLAUDE.md** (meta-project) - Agent context and instructions

### Knowledge Base
- **knowledge-base/patterns/** - 12 documented patterns with examples
- **knowledge-base/theory/** - Theoretical foundations (specificity-emergence, 80/20)
- **knowledge-base/behavioral-design/** - Behavioral science applications
- **knowledge-base/attention-research/** - Attention allocation research

### Agent Instructions
- **agents/CHAT_AGENT_INSTRUCTIONS.md** - CHAT behavioral spec
- **agents/CODE_AGENT_INSTRUCTIONS.md** - CODE behavioral spec (via CLAUDE.md)
- **agents/INVESTIGATOR_AGENT_INSTRUCTIONS.md** - INVESTIGATOR behavioral spec
- **agents/HOPPER_AGENT_INSTRUCTIONS.md** - HOPPER behavioral spec

### Reference Guides
- **agents/CHAT_AGENT_REFERENCE.md** - Extended CHAT documentation
- **agents/HOPPER_REFERENCE.md** - Extended HOPPER documentation
- **agents/INVESTIGATOR_REFERENCE.md** - Extended INVESTIGATOR documentation

---

## 12. Evolution and Extension

This nomenclature is a living document. As the platform evolves:

### Adding New Components
1. Determine layer (1-7) or if it's a new subsystem
2. Choose technical name (functional, descriptive)
3. Choose behavioral name (if human-facing)
4. Document relationship to existing components
5. Update this nomenclature document
6. Update cross-references in related docs

### Proposing Name Changes
1. Use the bridge to send message to CHAT (strategic) or CODE (technical)
2. Document reasoning (clarity, consistency, memorability)
3. Check impact on existing documentation
4. Update all references atomically

### Pattern Recognition
If you find yourself repeatedly explaining "the thing that does X", it probably needs a name:
1. Log it to the event log with context
2. INVESTIGATOR will detect pattern (3+ occurrences)
3. Discuss naming in coordination session
4. Add to this document once stable

---

## 13. Quick Reference

### Most Important Names to Remember

**Platform**: Ludarium
**The Stack**: Substrate → Protocol → Router → Lens → Harvest → Interface → Garden
**The Loop**: The Mirroring (you ↔ me ↔ environment)
**The Core**: The Bridge (infrastructure), The Lens (JITS), The Memory (event log)
**The Agents**: CODE (Builder), CHAT (Strategist), INVESTIGATOR (Detective), HOPPER (Concierge)

### When in Doubt
- Infrastructure? Use technical names
- Experience? Use behavioral names
- Both? Use hybrid format: "Technical / *Behavioral*"

---

## Appendix: Etymology and Inspirations

### Ludarium
- Latin *ludus*: play, game, training school (gladiator training was called a *ludus*)
- Connection to "ludicrous" - playfully absurd, beyond rigid rules
- Historical: Roman *ludi* were public games/festivals - spectacle + participation

### The Garden (Layer 7)
- Inspired by: Christopher Alexander's "A Pattern Language", permaculture design
- Gardens need structure (fences, beds) AND freedom (organic growth, emergence)
- You don't "build" a garden, you create conditions and tend what emerges

### The Mirroring
- Inspired by: Hofstadter's "strange loops", cybernetics (feedback systems)
- Mirrors both reflect (passive observation) and reverse (active transformation)
- Programming becomes mutual - both sides program each other

### The Substrate / Common Ground
- Inspired by: Philosophy (common ground in communication), geology (substrate as foundation)
- Technical: "Substrate" suggests something you build on top of
- Behavioral: "Common Ground" suggests shared understanding and coordination

---

*Generated: 2025-11-04*
*Platform: Ludarium Behavioral Coordination Platform*
*Context: Naming system for recursive self-programming multi-agent coordination*
