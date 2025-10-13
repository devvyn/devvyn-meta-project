# Coordination KB Query Modes

## Overview

The Coordination KB Pipeline supports two distinct query modes, each optimized for different coordination patterns.

## Natural Flow Mode

**When to use**: Exploratory research, pattern discovery, strategic planning

**Characteristics**:

- Human-initiated or scheduled agent tasks
- Batch processing acceptable
- Latency tolerance: seconds to minutes
- Results inform long-term decisions
- May involve multiple rounds of refinement

**Example scenarios**:

- INVESTIGATOR agent daily pattern scan at 9am
- Chat agent researching historical patterns for strategic decision
- Code agent exploring implementation precedents before major refactor
- Human exploring system capabilities

**Typical queries**:

- "Show me all coordination patterns related to resource provisioning"
- "What decisions have we made about async processing?"
- "Find examples of error recovery strategies"

**Implementation**:

- Uses full TF-IDF retrieval (`simple_retrieval.py`)
- Returns top 5-10 results with excerpts
- Logs query for audit trail
- No urgency constraints

## Real-Time Coordination Mode

**When to use**: Active coordination, immediate routing decisions, event response

**Characteristics**:

- System-initiated during live agent coordination
- Must complete within milliseconds
- Latency requirement: <100ms preferred, <500ms maximum
- Results directly influence routing or priority
- Single-shot query (no refinement)

**Example scenarios**:

- HOPPER agent classifying incoming message destination
- Queue processor determining priority from message content
- Bridge router deciding which agent handles new event
- Alert system matching events to response protocols

**Typical queries**:

- "redteam adversarial proposal" (routing decision)
- "deployment urgent production" (priority classification)
- "error recovery automatic" (protocol lookup)

**Implementation**:

- **NOT YET IMPLEMENTED** - Currently uses same pipeline as Natural Flow
- Future: Dedicated in-memory index
- Future: Precomputed routing rules
- Future: Cached frequent patterns

## Current Status

**Implemented**: Natural Flow Mode (full TF-IDF retrieval)

**Not Yet Implemented**: Real-Time Coordination Mode

- System currently doesn't require <500ms query response
- All coordination routing uses atomic shell scripts
- KB queries are exploratory, not real-time critical

**Future Work**:
When real-time coordination becomes necessary:

1. Profile query latencies under load
2. Implement in-memory index for common patterns
3. Add fast-path cache for repeated queries
4. Consider lightweight alternatives (regex patterns, hash lookups)

## Detection

The system automatically detects query mode based on `origin_agent`:

| Origin Agent | Default Mode | Rationale |
|--------------|--------------|-----------|
| `code` | Natural Flow | Human-guided exploration |
| `chat` | Natural Flow | Strategic analysis |
| `investigator` | Natural Flow | Daily batch analysis |
| `hopper` | Real-Time | Message routing (future) |
| `bridge-router` | Real-Time | Event routing (future) |

Real-Time mode is **not yet needed** because:

- Bridge uses file-based atomic operations (fast enough)
- Routing decisions use explicit patterns, not queries
- No performance bottlenecks identified in current workflow

## Performance Benchmarks

Current Natural Flow performance (as of 2025-10):

- Index build: ~500ms for 16 documents
- Query latency: <1000ms typical, <200ms for cached index
- Acceptable for all current use cases

Real-Time mode would target:

- Query latency: <100ms (p95)
- Index resident in memory
- No disk I/O during query

---

**Part of**: Coordination KB Pipeline (Recommendation #3)
**Version**: 1.0
**Last Updated**: 2025-10-12
