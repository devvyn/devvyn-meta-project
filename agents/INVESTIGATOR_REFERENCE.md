# INVESTIGATOR Agent Reference

This document contains detailed investigation workflows and templates. For essential operations, see INVESTIGATOR_AGENT_INSTRUCTIONS.md.

## Investigation Workflow Template

```bash
# Create investigation
INVESTIGATION_ID=$(date +"%Y%m%d%H%M%S")-$(uuidgen | cut -d'-' -f1)
cat > ~/infrastructure/agent-bridge/bridge/queue/investigations/active/${INVESTIGATION_ID}-investigation.md << EOF
# Investigation: [Title]
**ID**: ${INVESTIGATION_ID}
**Priority**: CRITICAL|HIGH|NORMAL|INFO
**Type**: pattern|anomaly|optimization|correlation
**Status**: active|blocked|completed

## Trigger
[What flagged this]

## Hypothesis
[What's suspected and why]

## Evidence
- [ ] Event log: [specific queries]
- [ ] Project files: [paths]
- [ ] Pattern library: [similar cases]
- [ ] Agent consultation: [CODE/CHAT/HOPPER]

## Analysis
[Data findings, correlations]

## Root Cause
[Conclusion]

## Solution
[Recommendation with pros/cons/effort/risk]

## Pattern Extraction
**Pattern**: [name]
**Confidence**: HIGH|MEDIUM|LOW
**Add to**: decision-patterns.md OR knowledge-base/patterns/
EOF

# Send findings
~/devvyn-meta-project/scripts/bridge-send.sh investigator code HIGH \
  "Investigation ${INVESTIGATION_ID}" findings.md

# Archive when complete
mv ~/infrastructure/agent-bridge/bridge/queue/investigations/active/${INVESTIGATION_ID}-*.md \
   ~/infrastructure/agent-bridge/bridge/queue/investigations/archive/
```

## Priority Triage Details

```tla
CRITICAL ≜ ProductionBlocking ∨ DataIntegrity ∨ Security ∨ CoordinationFailure
HIGH ≜ PerformanceDegradation>50% ∨ MultiProjectAffected ∨ StrategicBlocked>48h
NORMAL ≜ OptimizationOpportunity ∨ SingleProjectConcern ∨ PatternCandidate
INFO ≜ HistoricalAnalysis ∨ Documentation ∨ LowImpactObservation
```

## Investigation Types

1. **Pattern**: 3+ repetitions → extract reusable workflow
2. **Anomaly**: Error/performance/queue degradation → root cause + fix
3. **Correlation**: Similar issues across projects → shared cause analysis
4. **Optimization**: Repeated manual work → automation opportunity
5. **Knowledge Gap**: Re-solved problems → documentation need

## Files Monitored

- `bridge/events/` - Immutable event log (READ)
- `decision-patterns.md` - Pattern library (READ)
- `bridge/queue/investigations/` - Investigation queue (READ/WRITE)
- `bridge/inbox/investigator/` - Messages (READ/ARCHIVE)
- `status/current-project-state.json` - Project health (READ)

## Agent Coordination Details

### HOPPER → INVESTIGATOR

Pattern candidates from message analysis, deferred queue items that need investigation

### CODE → INVESTIGATOR

Root cause analysis requests, performance issues, technical anomalies

### CHAT → INVESTIGATOR

Strategic pattern validation, cross-project correlation requests

### INVESTIGATOR → CODE

Implementation tasks derived from findings, technical fixes needed

### INVESTIGATOR → CHAT

Pattern proposals for framework evolution, strategic recommendations

### INVESTIGATOR → HUMAN

Novel problems without documented solutions, high-impact decisions needing approval
