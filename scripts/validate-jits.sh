#!/usr/bin/env bash
# validate-jits.sh - Validate JITS compliance across the system
#
# Usage: validate-jits.sh

set -euo pipefail

ROOT="${HOME}/devvyn-meta-project"
ERRORS=0
WARNINGS=0

echo "=== JITS Validation Suite ==="
echo

# Function to check file size
check_file_size() {
    local file="$1"
    local max_lines="$2"
    local name="$3"

    if [ ! -f "$file" ]; then
        echo "⚠️  $name: File not found"
        ((WARNINGS++))
        return
    fi

    local lines=$(grep -c . "$file" || echo "0")
    if [ "$lines" -gt "$max_lines" ]; then
        echo "❌ $name: $lines lines (exceeds $max_lines line limit)"
        ((ERRORS++))
    else
        echo "✓ $name: $lines lines (within $max_lines limit)"
    fi
}

# Function to check for reference links
check_references() {
    local file="$1"
    local name="$2"

    if [ ! -f "$file" ]; then
        return
    fi

    if grep -q 'See.*REFERENCE\|See.*\.reference\.md\|See.*\.full\.md' "$file"; then
        echo "✓ $name: Contains reference links"
    else
        echo "⚠️  $name: No reference links found (may be self-contained)"
        ((WARNINGS++))
    fi
}

# Function to check for tier markers
check_tier_markers() {
    local file="$1"
    local name="$2"

    if [ ! -f "$file" ]; then
        return
    fi

    if grep -q '\[TIER[123]\]' "$file"; then
        echo "✓ $name: Contains tier markers"
    else
        echo "⚠️  $name: No tier markers found"
        ((WARNINGS++))
    fi
}

echo "1. Checking Agent Instruction Files"
echo "-----------------------------------"
check_file_size "$ROOT/CLAUDE.md" 100 "CLAUDE.md"
check_file_size "$ROOT/agents/CHAT_AGENT_INSTRUCTIONS.md" 100 "CHAT_AGENT_INSTRUCTIONS.md"
check_file_size "$ROOT/agents/INVESTIGATOR_AGENT_INSTRUCTIONS.md" 100 "INVESTIGATOR_AGENT_INSTRUCTIONS.md"
check_file_size "$ROOT/agents/HOPPER_AGENT_INSTRUCTIONS.md" 100 "HOPPER_AGENT_INSTRUCTIONS.md"
echo

echo "2. Checking Reference Links"
echo "---------------------------"
check_references "$ROOT/CLAUDE.md" "CLAUDE.md"
check_references "$ROOT/agents/CHAT_AGENT_INSTRUCTIONS.md" "CHAT_AGENT_INSTRUCTIONS.md"
check_references "$ROOT/agents/INVESTIGATOR_AGENT_INSTRUCTIONS.md" "INVESTIGATOR_AGENT_INSTRUCTIONS.md"
check_references "$ROOT/agents/HOPPER_AGENT_INSTRUCTIONS.md" "HOPPER_AGENT_INSTRUCTIONS.md"
echo

echo "3. Checking Reference Files Exist"
echo "---------------------------------"
if [ -f "$ROOT/OPERATIONS_REFERENCE.md" ]; then
    echo "✓ OPERATIONS_REFERENCE.md exists"
else
    echo "❌ OPERATIONS_REFERENCE.md missing"
    ((ERRORS++))
fi

if [ -f "$ROOT/agents/CHAT_AGENT_REFERENCE.md" ]; then
    echo "✓ CHAT_AGENT_REFERENCE.md exists"
else
    echo "❌ CHAT_AGENT_REFERENCE.md missing"
    ((ERRORS++))
fi

if [ -f "$ROOT/agents/INVESTIGATOR_REFERENCE.md" ]; then
    echo "✓ INVESTIGATOR_REFERENCE.md exists"
else
    echo "❌ INVESTIGATOR_REFERENCE.md missing"
    ((ERRORS++))
fi

if [ -f "$ROOT/agents/HOPPER_REFERENCE.md" ]; then
    echo "✓ HOPPER_REFERENCE.md exists"
else
    echo "❌ HOPPER_REFERENCE.md missing"
    ((ERRORS++))
fi
echo

echo "4. Checking JITS Pattern Documentation"
echo "--------------------------------------"
if [ -f "$ROOT/knowledge-base/patterns/just-in-time-specificity.md" ]; then
    echo "✓ JITS pattern documented"
else
    echo "❌ JITS pattern documentation missing"
    ((ERRORS++))
fi

if [ -f "$ROOT/knowledge-base/theory/specificity-emergence.md" ]; then
    echo "✓ Emergence theory documented"
else
    echo "❌ Emergence theory documentation missing"
    ((ERRORS++))
fi
echo

echo "5. Checking Originals Archived"
echo "------------------------------"
if [ -d "$ROOT/docs/archived-v1" ]; then
    echo "✓ Archive directory exists"

    if [ -f "$ROOT/docs/archived-v1/CLAUDE.md.original" ]; then
        echo "✓ CLAUDE.md.original archived"
    else
        echo "⚠️  CLAUDE.md.original not archived"
        ((WARNINGS++))
    fi

    if [ -f "$ROOT/docs/archived-v1/CHAT_AGENT_INSTRUCTIONS.md.original" ]; then
        echo "✓ CHAT_AGENT_INSTRUCTIONS.md.original archived"
    else
        echo "⚠️  CHAT_AGENT_INSTRUCTIONS.md.original not archived"
        ((WARNINGS++))
    fi
else
    echo "❌ Archive directory missing"
    ((ERRORS++))
fi
echo

echo "6. Calculating Context Reduction"
echo "--------------------------------"
BEFORE_LINES=$(grep -c . "$ROOT/docs/archived-v1/CLAUDE.md.original" 2>/dev/null || echo "0")
AFTER_LINES=$(grep -c . "$ROOT/CLAUDE.md" 2>/dev/null || echo "0")

if [ "$BEFORE_LINES" -gt 0 ] && [ "$AFTER_LINES" -gt 0 ]; then
    REDUCTION=$((BEFORE_LINES - AFTER_LINES))
    REDUCTION_PCT=$((100 * REDUCTION / BEFORE_LINES))
    echo "CLAUDE.md: $BEFORE_LINES → $AFTER_LINES lines ($REDUCTION_PCT% reduction)"

    if [ "$REDUCTION_PCT" -ge 30 ]; then
        echo "✓ Significant context reduction achieved"
    else
        echo "⚠️  Context reduction below 30% target"
        ((WARNINGS++))
    fi
else
    echo "⚠️  Cannot calculate reduction (missing files)"
    ((WARNINGS++))
fi
echo

# Summary
echo "=== Validation Summary ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "✅ All JITS validations passed!"
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo "⚠️  JITS implementation complete with $WARNINGS warnings"
    exit 0
else
    echo "❌ JITS validation failed with $ERRORS errors"
    exit 1
fi
