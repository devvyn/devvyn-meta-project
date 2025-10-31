#!/bin/bash
# Quick capture tool for friction points

set -e

FRICTION_DIR="$HOME/devvyn-meta-project/exploration-ensemble/friction-points"
DATE=$(date +%Y%m%d)

echo "=== Friction Point Capture ==="
echo ""
read -p "Brief description (for filename): " brief
read -p "What were you trying to do? " trying
read -p "What happened (the barrier)? " barrier
read -p "What did you expect? " expected
read -p "Current workaround (if any): " workaround
read -p "Severity (minor/moderate/major/critical): " severity

FILENAME="${DATE}-${brief// /-}.md"
FILEPATH="${FRICTION_DIR}/${FILENAME}"

cat > "$FILEPATH" <<EOF
---
friction_id: ${brief// /-}-001
created: $(date +%Y-%m-%d)
status: active
severity: ${severity:-moderate}
---

# ${brief^}

## Context
**What I was trying to do**: ${trying}

**What happened**: ${barrier}

**What I expected**: ${expected}

## Current Workaround
${workaround:-None currently}

## Why It's Friction
- Time cost:
- Cognitive load:
- Physical strain:
- Blocks flow state:
- Prevents exploration:

## Unknown Unknowns Suspected
- [ ] Better tools you haven't heard of
- [ ] Workflows you can't conceive
- [ ] Automations you don't know are possible
- [ ] Accessibility features you're unaware of

## Constraints
- **Can't change**:
- **Prefer to preserve**:
- **Open to**:

## Exploration Status
- [ ] Agents dispatched to research
- [ ] Findings gathered
- [ ] Experiments running
- [ ] Solution validated
- [ ] Integrated into workflow

## Related
-
EOF

echo ""
echo "✓ Friction point captured: ${FILEPATH}"
echo ""
echo "Next steps:"
echo "  1. Edit file to add more details if needed"
echo "  2. Ask agent to research solutions"
echo "  3. Review agent findings in agent-findings/"
