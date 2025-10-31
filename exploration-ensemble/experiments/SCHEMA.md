# Experiment Schema

Active testing of discovered pathways in safe sandbox.

## Template

```yaml
---
experiment_id: unique-identifier
started: YYYY-MM-DD
status: [setup|running|analyzing|completed|abandoned]
related_finding: agent-finding-id
addresses_friction: friction-point-id
---

# [Experiment Name]

## Hypothesis
What we expect to happen and why this might work

## Setup

### Environment
Where/how this is being tested (sandbox, test data, etc.)

### Tools/Dependencies
```bash
# Installation/setup commands
```

### Configuration

Key settings, files, or parameters

## Procedure

### Steps to Execute

1. [Action to take]
   - Expected result
   - Actual result: [to be filled during experiment]

### Measurements

What we're tracking to validate success:

- Time saved
- Cognitive load reduction
- Error rate
- Accessibility improvement

## Observations

### What Worked

Positive outcomes, unexpected benefits

### What Didn't Work

Problems encountered, limitations discovered

### Surprises

Unexpected behaviors, side effects (positive or negative)

### Accessibility Notes

How well this works with keyboard/voice, cognitive load, learning curve

## Validation

### Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2

### Decision

- [ ] **Adopt**: Move to validated-workflows
- [ ] **Iterate**: Needs modification (create new experiment)
- [ ] **Reject**: Not viable (document why)
- [ ] **Defer**: Promising but not priority now

## Next Actions

If adopting: integration steps
If iterating: what to change
If rejecting: alternatives to explore
