# Exploration Ensemble Scripts

Helper scripts for quick capture and documentation.

## For Humans

### `capture-friction.sh`

Quick interactive capture of friction points when you encounter them.

```bash
~/devvyn-meta-project/exploration-ensemble/scripts/capture-friction.sh
```

Prompts for:

- Brief description (becomes filename)
- What you were trying to do
- What barrier you hit
- What you expected
- Current workaround
- Severity level

Creates a pre-filled friction point file for agents to research.

### `new-experiment.sh`

Create a new experiment document when testing a solution.

```bash
~/devvyn-meta-project/exploration-ensemble/scripts/new-experiment.sh
```

Prompts for:

- Experiment name
- Related finding/friction
- Hypothesis

Creates structured experiment file for documenting the test.

## For Agents

### `new-finding.sh`

Document discoveries during research.

```bash
~/devvyn-meta-project/exploration-ensemble/scripts/new-finding.sh
```

Agents can use this programmatically:

```bash
echo -e "code\nTmux for session management\nterminal-chaos-001" | \
  ~/devvyn-meta-project/exploration-ensemble/scripts/new-finding.sh
```

Or call directly and fill interactively.

## Shell Integration

Consider adding aliases to your `~/.zshrc`:

```bash
# Exploration ensemble shortcuts
alias friction='~/devvyn-meta-project/exploration-ensemble/scripts/capture-friction.sh'
alias experiment='~/devvyn-meta-project/exploration-ensemble/scripts/new-experiment.sh'
alias finding='~/devvyn-meta-project/exploration-ensemble/scripts/new-finding.sh'
```

Then just type `friction` when you hit a barrier!
