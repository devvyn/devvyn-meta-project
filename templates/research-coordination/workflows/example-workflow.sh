#!/usr/bin/env bash
# Example Research Workflow: Literature Review → Hypothesis Generation
# This is a simplified demonstration of the workflow pattern

set -euo pipefail

TOPIC="$1"
KEYWORDS="$2"

echo "🔬 Research Workflow: Literature → Hypothesis"
echo "Topic: $TOPIC"
echo "Keywords: $KEYWORDS"
echo ""

# Step 1: Literature agent searches
echo "📚 Step 1: Literature search..."
../../minimal-coordination/message.sh send literature researcher \
    "Literature search: $TOPIC" \
    "Searched PubMed and arXiv for: $KEYWORDS. Found 47 relevant papers. Key findings: [1] Mechanism X well-established [2] Gap: Effect in E. coli unknown [3] Methods available: spectroscopy, MD simulations"

# Step 2: Researcher generates hypothesis
echo "💡 Step 2: Generating hypothesis..."
../../minimal-coordination/message.sh send researcher human \
    "Hypothesis for review: $TOPIC" \
    "Based on literature, I hypothesize that: Mechanism X operates in E. coli with 30% reduced efficiency due to temperature sensitivity. Proposed experiment: Spectroscopy at 25°C vs 37°C. Expected outcome: 2-fold rate difference. Confidence: Moderate. Request approval to proceed."

# Step 3: Human reviews
echo "👤 Step 3: Awaiting human review..."
echo ""
echo "✓ Workflow complete. Check inbox:"
echo "  ../../minimal-coordination/message.sh inbox human"
