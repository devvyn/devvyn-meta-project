# Pathway Schema

Each discovered pathway should document how to get from goal to outcome.

## Template

```yaml
---
pathway_id: unique-identifier
created: YYYY-MM-DD
status: [discovered|experimental|validated|integrated|deprecated]
---

# [Goal Description]

## Context
- **What**: Clear statement of what you're trying to accomplish
- **Why**: Motivation and value
- **Constraints**: Time, tools, physical/cognitive requirements
- **Current state**: What you're doing now (if applicable)

## Pathway

### Prerequisites
- [ ] Required tools/knowledge
- [ ] Setup steps
- [ ] Access requirements

### Steps
1. [Concrete action]
   - Details, commands, or procedures
   - Expected outcome
   - Troubleshooting notes

### Interaction Methods
- **Keyboard**: Key bindings, shortcuts, CLI commands
- **Voice**: Voice commands, dictation workflows
- **Automation**: Scripts, aliases, scheduled tasks
- **Agent**: Tasks delegated to agents

### Accessibility Profile
- **Cognitive load**: [low|medium|high]
- **Physical requirements**: [keyboard-only|voice-capable|mixed]
- **Learning curve**: [minutes|hours|days]
- **Context switching**: [minimal|moderate|frequent]

## Alternatives

### Other routes discovered
- [Alternative pathway with pros/cons]

## Validation

### Success indicators
- [ ] Concrete outcome achieved
- [ ] Faster than previous method
- [ ] Reduced friction/cognitive load
- [ ] Repeatable and reliable

### Tested by
- Date, context, results

## Maintenance
- Dependencies to monitor
- Update frequency
- Known issues
```

## Examples

See `/pathways/examples/` for reference implementations.
