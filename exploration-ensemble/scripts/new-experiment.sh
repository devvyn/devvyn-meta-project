#!/bin/bash
# Create a new experiment

set -e

EXPERIMENTS_DIR="$HOME/devvyn-meta-project/exploration-ensemble/experiments"
DATE=$(date +%Y%m%d)

echo "=== Experiment Creation ==="
echo ""
read -p "Experiment name: " name
read -p "Related finding ID: " finding
read -p "Addresses friction ID: " friction
read -p "Hypothesis: " hypothesis

FILENAME="${DATE}-${name// /-}.md"
FILEPATH="${EXPERIMENTS_DIR}/${FILENAME}"

cat > "$FILEPATH" <<EOF
---
experiment_id: ${name// /-}-001
started: $(date +%Y-%m-%d)
status: setup
related_finding: ${finding}
addresses_friction: ${friction}
---

# ${name}

## Hypothesis
${hypothesis}

## Setup

### Environment


### Tools/Dependencies
\`\`\`bash
# Installation/setup commands

\`\`\`

### Configuration


## Procedure

### Steps to Execute
1. [Action to take]
   - Expected result:
   - Actual result:

### Measurements
What we're tracking to validate success:
- Time saved:
- Cognitive load reduction:
- Error rate:
- Accessibility improvement:

## Observations

### What Worked


### What Didn't Work


### Surprises


### Accessibility Notes


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

EOF

echo ""
echo "✓ Experiment created: ${FILEPATH}"
echo ""
echo "Next steps:"
echo "  1. Set up the environment"
echo "  2. Run the experiment"
echo "  3. Document observations"
echo "  4. Make adoption decision"
