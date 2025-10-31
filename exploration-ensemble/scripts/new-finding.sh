#!/bin/bash
# Create a new agent finding (for agents or humans to use)

set -e

FINDINGS_DIR="$HOME/devvyn-meta-project/exploration-ensemble/agent-findings"
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

echo "=== Agent Finding Creation ==="
echo ""
read -p "Agent name (code/chat/investigator/other): " agent
read -p "Discovery title: " title
read -p "Related to (friction-id or goal): " related

FILENAME="${DATE}-${agent^^}-${title// /-}.md"
FILEPATH="${FINDINGS_DIR}/${FILENAME}"

cat > "$FILEPATH" <<EOF
---
finding_id: ${title// /-}-001
agent: ${agent}
timestamp: ${TIMESTAMP}
related_to: ${related}
status: new
---

# ${title}

## What Was Found


## Source
- Documentation URL:
- Example code/config:
- Community discussions:
- Research papers:

## Potential Applications


## Prerequisites
- Tools needed:
- Knowledge required:
- System requirements:

## Initial Assessment

### Pros
-

### Cons
-

### Accessibility Considerations
- How it interfaces (keyboard/voice/visual):
- Cognitive complexity:
- Learning requirements:

## Next Steps
- [ ] Further research needed
- [ ] Prototype/experiment
- [ ] Consult with human
- [ ] Test in sandbox

## Agent Notes

EOF

echo ""
echo "✓ Finding created: ${FILEPATH}"
echo ""
echo "Next steps:"
echo "  1. Fill in discovery details"
echo "  2. Assess accessibility"
echo "  3. Propose experiment if promising"
