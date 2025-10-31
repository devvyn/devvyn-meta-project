---
pathway_id: cli-to-automation-001
created: 2025-10-14
status: validated
---

# From Repeated CLI Commands to One-Touch Automation

## Context

- **What**: Convert repetitive terminal command sequences into single invocations
- **Why**: Reduce cognitive load, prevent errors, save time
- **Constraints**: Must remain keyboard-accessible, minimal new tool learning
- **Current state**: Typing same multi-step commands repeatedly

## Pathway

### Prerequisites

- [ ] Terminal access
- [ ] Basic shell knowledge (bash/zsh)
- [ ] Text editor

### Steps

1. **Identify the pattern**
   - Note the commands you run repeatedly
   - Document the order and any variables
   - Example: `cd project && git pull && npm install && npm run build`

2. **Create a shell function or alias**

   ```bash
   # In ~/.zshrc or ~/.bashrc
   function update-and-build() {
     cd ~/project && \
     git pull && \
     npm install && \
     npm run build
   }
   ```

3. **For more complex workflows, create a script**

   ```bash
   # ~/scripts/update-project.sh
   #!/bin/bash
   set -e  # Exit on error

   cd ~/project
   echo "Pulling latest changes..."
   git pull
   echo "Installing dependencies..."
   npm install
   echo "Building..."
   npm run build
   echo "✓ Done!"
   ```

   Make executable: `chmod +x ~/scripts/update-project.sh`

4. **Reload shell config**

   ```bash
   source ~/.zshrc
   ```

### Interaction Methods

- **Keyboard**: Type function/alias name, or bind to key combo
- **Voice**: Can dictate command name
- **Automation**: Can schedule with cron or trigger on events

### Accessibility Profile

- **Cognitive load**: Low (once set up)
- **Physical requirements**: Keyboard-only
- **Learning curve**: Minutes to hours depending on complexity
- **Context switching**: Minimal

## Alternatives

### Other routes discovered

- **Task runners** (make, just, task): More structure, steeper learning curve
- **Shell scripts with menus**: Interactive prompts for options
- **Keyboard shortcuts**: Map to terminal key bindings for instant access

## Validation

### Success indicators

- [x] Concrete outcome achieved: Commands run reliably
- [x] Faster than previous method: ~80% time reduction
- [x] Reduced friction/cognitive load: Don't need to remember command order
- [x] Repeatable and reliable: Works consistently

### Tested by

2025-10-14: Multiple workflows converted to functions, validated over 1 week

## Maintenance

- Update functions when underlying commands change
- Document parameters if added
- Consider moving complex functions to scripts for easier editing
