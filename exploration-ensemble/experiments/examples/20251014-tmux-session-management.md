---
experiment_id: tmux-001
started: 2025-10-14
status: completed
related_finding: terminal-multiplexing-001
addresses_friction: terminal-chaos-001
---

# Tmux for Project Session Management

## Hypothesis

Using tmux with named sessions for each project will eliminate terminal chaos and allow instant project switching with persistent context.

## Setup

### Environment

Local terminal (iTerm2 on macOS)

### Tools/Dependencies

```bash
brew install tmux
```

### Configuration

Created `~/.tmux.conf`:

```bash
# Prefix key
set -g prefix C-a
unbind C-b

# Easy config reload
bind r source-file ~/.tmux.conf

# Better splits
bind | split-window -h
bind - split-window -v

# Vi-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Mouse support
set -g mouse on

# Status bar
set -g status-position bottom
set -g status-style 'bg=colour234 fg=colour137'
```

## Procedure

### Steps to Execute

1. **Create named session for project**

   ```bash
   tmux new -s myproject
   ```

   - Expected result: New tmux session starts
   - Actual result: ✓ Session created, name visible in status bar

2. **Setup project windows**

   ```bash
   # Window 0: editor
   # Window 1: dev server
   # Window 2: git/misc
   ```

   - Expected result: Multiple windows in one session
   - Actual result: ✓ Easy to create with `Ctrl-a c`

3. **Detach and reattach**

   ```bash
   # Detach: Ctrl-a d
   # List sessions: tmux ls
   # Attach: tmux attach -t myproject
   ```

   - Expected result: Context preserved when reattaching
   - Actual result: ✓ Exactly where I left off!

4. **Switch between project sessions**

   ```bash
   tmux switch -t otherproject
   # Or use fuzzy finder
   tmux attach -t $(tmux ls | fzf | cut -d: -f1)
   ```

   - Expected result: Instant project context switch
   - Actual result: ✓ Sub-second switching between entire project environments

### Measurements

- **Time saved**: Context switches from ~30s to ~2s (93% reduction)
- **Cognitive load**: Dramatically reduced - no searching, named sessions obvious
- **Error rate**: Zero lost context or wrong-directory commands
- **Accessibility**: Pure keyboard, vi-style navigation feels natural

## Observations

### What Worked

- Named sessions are game-changing - instantly know project context
- Persistent sessions survive disconnects, reboots (with tmux-resurrect)
- Pane splits within sessions let me see code + output simultaneously
- Mouse support makes it approachable while learning keybindings

### What Didn't Work

- Default keybindings conflicted with shell (Ctrl-b)
- Status bar initially too minimal - couldn't see what I needed
- Learning curve: took ~1 hour to feel comfortable

### Surprises

- Can run tmux inside SSH sessions for remote work too!
- Pair programming becomes easy (multiple people attach to same session)
- Can script session creation with tmuxinator for complex setups

### Accessibility Notes

- **Keyboard**: Perfect - all keybindings customizable
- **Voice**: Could work with custom Talon commands ("switch to project foo")
- **Cognitive load**: Initial learning required, but huge reduction after
- **Learning curve**: 1 hour to basics, ongoing discovery of power features

## Validation

### Success Criteria

- [x] Can switch between projects in <5 seconds
- [x] Context persists across disconnects
- [x] Reduced mental overhead tracking terminals
- [x] Works with existing shell config

### Decision

- [x] **Adopt**: Move to validated-workflows

## Next Actions

**Integration steps:**

1. Create tmuxinator configs for main projects (auto-setup windows/panes)
2. Add fuzzy-finder session switcher to shell functions
3. Document common commands in quick reference
4. Explore tmux-resurrect for session persistence across reboots
5. Consider creating project-specific tmux configs

**Validated workflow location:** `validated-workflows/tmux-project-sessions.md`
