#!/usr/bin/env bash
# measure-context-cost.sh - Measure context loading cost for agent startup
#
# Usage: measure-context-cost.sh [before|after]

set -euo pipefail

MODE="${1:-current}"
ROOT="${HOME}/devvyn-meta-project"

echo "=== Context Cost Measurement: $MODE ==="
echo

# Function to count lines in a file
count_lines() {
    if [ -f "$1" ]; then
        grep -c . "$1" || echo "0"
    else
        echo "0"
    fi
}

# Agent instruction files
if [ "$MODE" = "before" ]; then
    # Use archived originals for "before" measurement
    CLAUDE_MD="${ROOT}/docs/archived-v1/CLAUDE.md.original"
    CHAT_MD="${ROOT}/docs/archived-v1/CHAT_AGENT_INSTRUCTIONS.md.original"
    INVESTIGATOR_MD="${ROOT}/docs/archived-v1/INVESTIGATOR_AGENT_INSTRUCTIONS.md.original"
    HOPPER_MD="${ROOT}/docs/archived-v1/HOPPER_AGENT_INSTRUCTIONS.md.original"
else
    # Use current files
    CLAUDE_MD="${ROOT}/CLAUDE.md"
    CHAT_MD="${ROOT}/agents/CHAT_AGENT_INSTRUCTIONS.md"
    INVESTIGATOR_MD="${ROOT}/agents/INVESTIGATOR_AGENT_INSTRUCTIONS.md"
    HOPPER_MD="${ROOT}/agents/HOPPER_AGENT_INSTRUCTIONS.md"
fi

# Count lines for each agent
CLAUDE_LINES=$(count_lines "$CLAUDE_MD")
CHAT_LINES=$(count_lines "$CHAT_MD")
INVESTIGATOR_LINES=$(count_lines "$INVESTIGATOR_MD")
HOPPER_LINES=$(count_lines "$HOPPER_MD")

# Protocol files (these are referenced, so might be loaded)
COORD_PROTOCOL=$(count_lines "${ROOT}/COORDINATION_PROTOCOL.md")
COORD_COMPACT=$(count_lines "${ROOT}/COORDINATION_PROTOCOL.compact.md")
BRIDGE_SPEC=$(count_lines "${ROOT}/BRIDGE_SPEC_PROTOCOL.md")
BRIDGE_COMPACT=$(count_lines "${ROOT}/BRIDGE_SPEC_PROTOCOL.compact.md")

# TLA+ spec
TLA_SPEC=$(count_lines "${ROOT}/ClaudeCodeSystem.tla")

echo "Agent Instruction Files:"
echo "  CLAUDE.md: $CLAUDE_LINES lines"
echo "  CHAT_AGENT: $CHAT_LINES lines"
echo "  INVESTIGATOR_AGENT: $INVESTIGATOR_LINES lines"
echo "  HOPPER_AGENT: $HOPPER_LINES lines"
echo

# Calculate startup costs
AGENT_TOTAL=$((CLAUDE_LINES + CHAT_LINES + INVESTIGATOR_LINES + HOPPER_LINES))

echo "Referenced Protocol Files:"
echo "  COORDINATION_PROTOCOL.md: $COORD_PROTOCOL lines"
echo "  COORDINATION_PROTOCOL.compact.md: $COORD_COMPACT lines"
echo "  BRIDGE_SPEC_PROTOCOL.md: $BRIDGE_SPEC lines"
echo "  BRIDGE_SPEC_PROTOCOL.compact.md: $BRIDGE_COMPACT lines"
echo "  ClaudeCodeSystem.tla: $TLA_SPEC lines"
echo

# Estimate context load scenarios
MINIMAL_LOAD=$AGENT_TOTAL
TYPICAL_LOAD=$((AGENT_TOTAL + COORD_COMPACT + BRIDGE_COMPACT))
FULL_LOAD=$((AGENT_TOTAL + COORD_PROTOCOL + BRIDGE_SPEC + TLA_SPEC))

echo "Context Load Scenarios:"
echo "  Minimal (instructions only): $MINIMAL_LOAD lines"
echo "  Typical (+ compact protocols): $TYPICAL_LOAD lines"
echo "  Full (+ full protocols + TLA): $FULL_LOAD lines"
echo

# Calculate per-agent startup cost
echo "Per-Agent Startup Cost:"
echo "  Code Agent (CLAUDE.md): $CLAUDE_LINES lines"
if [ "$MODE" != "before" ]; then
    echo "    + OPERATIONS_REFERENCE.md: $(count_lines "${ROOT}/OPERATIONS_REFERENCE.md") lines (deferred)"
fi
echo "  Chat Agent: $CHAT_LINES lines"
if [ "$MODE" != "before" ]; then
    echo "    + CHAT_AGENT_REFERENCE.md: $(count_lines "${ROOT}/agents/CHAT_AGENT_REFERENCE.md") lines (deferred)"
fi
echo "  INVESTIGATOR Agent: $INVESTIGATOR_LINES lines"
if [ "$MODE" != "before" ]; then
    echo "    + INVESTIGATOR_REFERENCE.md: $(count_lines "${ROOT}/agents/INVESTIGATOR_REFERENCE.md") lines (deferred)"
fi
echo "  HOPPER Agent: $HOPPER_LINES lines"
if [ "$MODE" != "before" ]; then
    echo "    + HOPPER_REFERENCE.md: $(count_lines "${ROOT}/agents/HOPPER_REFERENCE.md") lines (deferred)"
fi
echo

# Summary
echo "=== Summary ==="
echo "Total Agent Instructions: $AGENT_TOTAL lines"
echo "Average per agent: $((AGENT_TOTAL / 4)) lines"

if [ "$MODE" = "before" ]; then
    echo
    echo "Run with 'after' to compare post-JITS optimization:"
    echo "  $0 after"
fi
