#!/usr/bin/env bash
# analyze-specificity.sh - Analyze markdown files for JITS optimization opportunities
#
# Usage: analyze-specificity.sh <file.md>

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <file.md>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found"
    exit 1
fi

# Count total lines (excluding empty lines)
TOTAL_LINES=$(grep -c . "$FILE" || true)

# High-leverage patterns (TIER1)
INVARIANT_LINES=$(grep -c '```tla\|INVARIANT\|⇒\|∧\|∨' "$FILE" || true)
COMMAND_LINES=$(grep -c '^[[:space:]]*#.*\$\|^```bash' "$FILE" || true)
STARTUP_LINES=$(awk '/^## STARTUP/,/^##/ {print}' "$FILE" | grep -c . || true)

HIGH_LEVERAGE=$((INVARIANT_LINES + COMMAND_LINES + STARTUP_LINES))

# Low-leverage patterns (TIER3/4)
EXAMPLE_LINES=$(grep -ic 'example\|for instance\|e\.g\.' "$FILE" || true)
EXPLANATION_LINES=$(grep -ic 'this means\|in other words\|essentially\|basically' "$FILE" || true)
TEMPLATE_LINES=$(awk '/^```.*template/,/^```/ {print}' "$FILE" | grep -c . || true)
CHECKLIST_LINES=$(grep -c '^[[:space:]]*-[[:space:]]*\[' "$FILE" || true)

LOW_LEVERAGE=$((EXAMPLE_LINES + EXPLANATION_LINES + TEMPLATE_LINES + CHECKLIST_LINES))

# Calculate metrics
if [ "$TOTAL_LINES" -gt 0 ]; then
    HIGH_LEVERAGE_PCT=$((HIGH_LEVERAGE * 100 / TOTAL_LINES))
    LOW_LEVERAGE_PCT=$((LOW_LEVERAGE * 100 / TOTAL_LINES))
else
    HIGH_LEVERAGE_PCT=0
    LOW_LEVERAGE_PCT=0
fi

# Compression opportunity (based on .compact.md baseline of 70%)
TARGET_LINES=$((TOTAL_LINES * 30 / 100))
COMPRESSION_OPPORTUNITY=$((TOTAL_LINES - TARGET_LINES))
COMPRESSION_PCT=70

# Leverage score (higher is better: more high-leverage, less low-leverage)
LEVERAGE_SCORE=$((HIGH_LEVERAGE_PCT - LOW_LEVERAGE_PCT))

# Classification
if [ "$LEVERAGE_SCORE" -gt 20 ]; then
    CLASSIFICATION="EXCELLENT"
elif [ "$LEVERAGE_SCORE" -gt 0 ]; then
    CLASSIFICATION="GOOD"
elif [ "$LEVERAGE_SCORE" -gt -20 ]; then
    CLASSIFICATION="NEEDS OPTIMIZATION"
else
    CLASSIFICATION="CRITICAL - OVER-SPECIFIED"
fi

# Output
echo "=== Specificity Analysis: $(basename "$FILE") ==="
echo
echo "Total Lines: $TOTAL_LINES"
echo
echo "High-Leverage Content (TIER1):"
echo "  Invariants/Commands: $HIGH_LEVERAGE lines ($HIGH_LEVERAGE_PCT%)"
echo
echo "Low-Leverage Content (TIER3/4):"
echo "  Examples/Templates: $LOW_LEVERAGE lines ($LOW_LEVERAGE_PCT%)"
echo
echo "Leverage Score: $LEVERAGE_SCORE ($CLASSIFICATION)"
echo
echo "Compression Opportunity:"
echo "  Target lines (30% of original): $TARGET_LINES"
echo "  Can remove: ~$COMPRESSION_OPPORTUNITY lines (~$COMPRESSION_PCT%)"
echo
echo "Recommendations:"

if [ "$TOTAL_LINES" -gt 100 ]; then
    echo "  • File is large ($TOTAL_LINES lines). Consider creating .reference.md for details."
fi

if [ "$LOW_LEVERAGE_PCT" -gt 30 ]; then
    echo "  • High ratio of examples/templates ($LOW_LEVERAGE_PCT%). Move to reference doc."
fi

if [ "$HIGH_LEVERAGE_PCT" -lt 20 ]; then
    echo "  • Low ratio of invariants/commands ($HIGH_LEVERAGE_PCT%). Ensure essentials are present."
fi

if [ "$CHECKLIST_LINES" -gt 10 ]; then
    echo "  • $CHECKLIST_LINES checklist items found. Consider moving to reference."
fi

echo
echo "JITS Optimization:"
if [ "$TOTAL_LINES" -gt 80 ]; then
    echo "  1. Extract TIER1 (invariants + commands) to main file (~$TARGET_LINES lines)"
    echo "  2. Move examples/templates/checklists to .reference.md"
    echo "  3. Add tier markers: ## SECTION [TIER1/2/3]"
else
    echo "  File is already concise ($TOTAL_LINES lines). Ensure proper tier structure."
fi
