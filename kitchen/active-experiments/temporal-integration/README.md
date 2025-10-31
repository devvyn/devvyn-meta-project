# Temporal Integration Trial

**Status**: Active Experiment 🧪
**Started**: 2025-10-14
**Goal**: Evaluate Temporal for hybrid orchestration with existing bridge system

## Overview

This experiment integrates Temporal workflow orchestration selectively into the collective's infrastructure, keeping the proven bridge communication system while adding Temporal for:

1. **Long-running LLM workflows** (PyRIT multi-turn adversarial testing)
2. **Scheduled knowledge extraction** (coordination-kb-pipeline automation)
3. **Durable execution guarantees** (survive process crashes)

## Architecture

```
Bridge System (existing) ──triggers──> Temporal Workflows (new)
                                              │
                                              ▼
                                       Event Log (existing)
```

**Hybrid Approach**:

- Bridge handles: Lightweight message passing, agent coordination
- Temporal handles: Durable workflows, long-running operations, visual debugging

## Components

### Workflows

- `AdversarialChallengeWorkflow`: Multi-turn PyRIT testing with state preservation
- `KnowledgeDigestWorkflow`: Scheduled digest generation with condition monitoring

### Activities

- `challenge_turn_activity`: Single PyRIT orchestrator call
- `extract_patterns_activity`: Pattern extraction from event log
- `generate_digest_activity`: Digest generation
- `update_collective_memory_activity`: Memory updates

### Integration

- `bridge_temporal_adapter.py`: Bridge message → Temporal workflow starter
- Bridge sends message → Adapter starts workflow → Workflow completes → Event logged

## Setup

### 1. Temporal Server (Local Dev)

```bash
# Start Temporal dev server
cd ~/devvyn-meta-project/kitchen/active-experiments/temporal-integration
docker compose up -d

# Verify server
temporal server health

# Access Web UI
open http://localhost:8233
```

### 2. Worker Process

```bash
# Start Temporal worker (processes workflows)
python -m workflows.worker
```

### 3. Trigger Workflows

```bash
# Via bridge (production path)
~/devvyn-meta-project/scripts/bridge-send.sh chat redteam HIGH "Challenge Proposal" proposal.md

# Direct trigger (testing)
python -m workflows.trigger_adversarial_challenge proposal.md
```

## Evaluation Criteria

### Success Metrics

- ✅ Workflows survive process restart without losing state
- ✅ Temporal UI provides better debugging than log files
- ✅ <100ms latency overhead vs. direct execution
- ✅ Integration requires <200 LOC (minimal complexity)

### Failure Criteria

- ❌ Temporal adds >500ms latency per operation
- ❌ Integration requires changing bridge protocol
- ❌ Existing fault-tolerant wrappers already handle all cases
- ❌ Temporal debugging not substantially better than logs

### Decision Matrix

- **Adopt fully**: >50% improvement in reliability + observability
- **Adopt selectively**: Only specific workflows benefit (PyRIT, knowledge extraction)
- **Abandon**: Bridge system already sufficient

## Results

### Prototype 1: PyRIT Workflow

- **Status**: TBD
- **Reliability**: TBD
- **Observability**: TBD
- **Performance**: TBD

### Prototype 2: Knowledge Digest Workflow

- **Status**: TBD
- **Reliability**: TBD
- **Observability**: TBD
- **Performance**: TBD

## Files

```
temporal-integration/
├── README.md                          # This file
├── docker-compose.yml                 # Temporal server config
├── workflows/
│   ├── adversarial_challenge.py      # PyRIT workflow
│   ├── knowledge_digest.py           # Digest workflow
│   └── worker.py                     # Temporal worker process
├── activities/
│   ├── pyrit_activities.py           # PyRIT execution activities
│   └── knowledge_activities.py       # Knowledge extraction activities
├── bridge_temporal_adapter.py        # Bridge integration adapter
├── tests/
│   ├── test_adversarial_workflow.py
│   └── test_digest_workflow.py
├── logs/                             # Workflow execution logs
└── results/                          # Trial evaluation results
```

## Related Documentation

- **Bridge Protocol**: `~/devvyn-meta-project/COORDINATION_PROTOCOL.md`
- **PyRIT Integration**: `~/devvyn-meta-project/agents/redteam/README.md`
- **Event Sourcing**: `~/infrastructure/agent-bridge/bridge/events/README.md`

## Timeline

- **Phase 1** (30 min): Infrastructure setup
- **Phase 2** (2 hours): PyRIT workflow prototype
- **Phase 3** (1.5 hours): Knowledge digest workflow prototype
- **Phase 4** (1 hour): Evaluation and decision

**Total estimated time**: 5 hours

## Next Steps

1. ✅ Install Temporal SDK
2. ✅ Create directory structure
3. ⏳ Start Temporal dev server
4. ⏳ Build PyRIT workflow
5. ⏳ Build knowledge digest workflow
6. ⏳ Evaluate vs. existing system
7. ⏳ Document decision (adopt/selective/abandon)

---

**Experiment Owner**: Code Agent
**Strategic Oversight**: Chat Agent (when results ready)
**Final Decision**: Human (based on evaluation)
