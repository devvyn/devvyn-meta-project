# Tools Map

Knowledge graph connecting tools, capabilities, and interaction methods.

## Structure

### Tool Profiles

Each tool gets a profile documenting:

- What it does (capabilities)
- How to interact (keyboard, voice, API, GUI)
- Prerequisites and dependencies
- Accessibility characteristics
- Integration possibilities

### Capability Index

Reverse mapping: goal → tools that can achieve it

### Interaction Methods

Categorized by:

- Keyboard-driven (CLI, keyboard shortcuts, TUI)
- Voice-enabled (dictation-friendly, voice commands)
- Automation-ready (scriptable, API, webhook)
- Visual (GUI, requires screen interaction)

## Format

Tools documented as YAML for easy parsing by agents:

```yaml
---
tool: tool-name
category: [cli|gui|api|service|library]
interaction_methods:
  keyboard: [excellent|good|limited|none]
  voice: [excellent|good|limited|none]
  automation: [excellent|good|limited|none]
capabilities:
  - capability-1
  - capability-2
accessibility:
  cognitive_load: [low|medium|high]
  learning_curve: [shallow|moderate|steep]
  keyboard_only: [yes|no]
  voice_compatible: [yes|partial|no]
integration:
  - integrates-with-tool-1
  - integrates-with-tool-2
---
```

## Agent Usage

Agents should:

1. Query this map when exploring solutions
2. Update entries as new capabilities/integrations are discovered
3. Create new entries for newly discovered tools
4. Maintain accuracy through validation
