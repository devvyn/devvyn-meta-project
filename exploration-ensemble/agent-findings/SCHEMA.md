# Agent Findings Schema

Raw observations from agent exploration - not yet validated or integrated.

## Template

```yaml
---
finding_id: unique-identifier
agent: [code|chat|investigator|other]
timestamp: YYYY-MM-DDTHH:MM:SS
related_to: [friction-point-id or exploration-goal]
status: [new|reviewing|tested|validated|rejected]
---

# [Discovery Title]

## What Was Found
Clear description of the tool/method/workflow discovered

## Source
- Documentation URL
- Example code/config
- Community discussions
- Research papers

## Potential Applications
How this might address current friction points or enable new capabilities

## Prerequisites
- Tools needed
- Knowledge required
- System requirements

## Initial Assessment

### Pros
- Advantages observed
- Potential benefits

### Cons
- Limitations noticed
- Potential drawbacks

### Accessibility Considerations
- How it interfaces (keyboard/voice/visual)
- Cognitive complexity
- Learning requirements

## Next Steps
- [ ] Further research needed
- [ ] Prototype/experiment
- [ ] Consult with human
- [ ] Test in sandbox

## Agent Notes
Free-form observations, hunches, connections to other findings
```

## Agent Coordination

Agents should:

1. Create findings when discovering new possibilities
2. Cross-reference related findings
3. Flag high-potential discoveries for human review
4. Update status as findings progress through validation
