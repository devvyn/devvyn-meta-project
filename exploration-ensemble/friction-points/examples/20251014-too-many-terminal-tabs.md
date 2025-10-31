---
friction_id: terminal-chaos-001
created: 2025-10-14
status: exploring
severity: moderate
---

# Terminal Tab/Window Chaos

## Context

**What I was trying to do**: Work on multiple projects simultaneously

**What happened**: End up with 10+ terminal tabs across multiple windows, lose track of which terminal is which project, constantly searching for the right context

**What I expected**: Quick navigation between project contexts without cognitive overhead

## Current Workaround

- Manually create tabs and cd to project directories
- Use window titles to identify (but they're too small/similar)
- Often give up and just cd around in one terminal

## Why It's Friction

- **Time cost**: ~30 seconds per context switch searching for right terminal
- **Cognitive load**: Mental overhead tracking which terminal is where
- **Blocks flow state**: Interrupts focus when switching between projects
- **Prevents exploration**: Hesitant to open new terminal for quick tasks

## Unknown Unknowns Suspected

- [x] Better tools for terminal session management (tmux? other?)
- [x] Workflows for named, persistent sessions
- [x] Automations for project-specific terminal setup
- [ ] Terminal multiplexers with better visual organization

## Constraints

- **Can't change**: Must stay in terminal (love keyboard-driven workflow)
- **Prefer to preserve**: Current shell config, keybindings muscle memory
- **Open to**: New tools if they enhance rather than replace current workflow

## Exploration Status

- [x] Agents dispatched to research
- [ ] Findings gathered
- [ ] Experiments running
- [ ] Solution validated
- [ ] Integrated into workflow

## Related

- Session persistence across reboots
- Project-specific environment setup
- Quick project switching
