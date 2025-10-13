#!/bin/bash
# Zen Minimalism Linter - Detect cruft accumulation

set -euo pipefail

WORKSPACE="${1:-$HOME/devvyn-meta-project}"
VIOLATIONS=0

echo "🧘 Zen Minimalism Lint - Checking for cruft..."
echo

# Check for banned headers
echo "Checking for banned headers..."
for file in "$WORKSPACE"/*.md "$WORKSPACE"/agents/*.md; do
    [[ -f "$file" ]] || continue

    if grep -q "^## Executive Summary" "$file" 2>/dev/null; then
        echo "❌ $file: Contains 'Executive Summary' header"
        ((VIOLATIONS++))
    fi

    if grep -q "^## Core Identity" "$file" 2>/dev/null; then
        echo "❌ $file: Contains 'Core Identity' header"
        ((VIOLATIONS++))
    fi

    if grep -q "^## Philosophy" "$file" 2>/dev/null; then
        echo "❌ $file: Contains 'Philosophy' header"
        ((VIOLATIONS++))
    fi

    if grep -q "Why.*:" "$file" 2>/dev/null && [[ "$file" != *"README"* ]]; then
        echo "⚠️  $file: Contains rationale ('Why' questions)"
    fi
done

# Check line count limits
echo
echo "Checking file size limits..."

if [ -f "$WORKSPACE/CLAUDE.md" ]; then
    lines=$(wc -l < "$WORKSPACE/CLAUDE.md")
    if [ "$lines" -gt 100 ]; then
        echo "❌ CLAUDE.md exceeds 100 lines ($lines lines)"
        ((VIOLATIONS++))
    else
        echo "✅ CLAUDE.md: $lines lines"
    fi
fi

for file in "$WORKSPACE"/agents/*_INSTRUCTIONS.md "$WORKSPACE"/agents/*_CAPABILITIES.md; do
    [[ -f "$file" ]] || continue
    lines=$(wc -l < "$file")
    if [ "$lines" -gt 200 ]; then
        echo "❌ $(basename "$file"): Exceeds 200 lines ($lines lines)"
        ((VIOLATIONS++))
    else
        echo "✅ $(basename "$file"): $lines lines"
    fi
done

# Check for duplicate content (hash-based)
echo
echo "Checking for duplicate content..."
declare -A hashes
for file in "$WORKSPACE"/*.md "$WORKSPACE"/agents/*.md; do
    [[ -f "$file" ]] || continue
    hash=$(md5 -q "$file" 2>/dev/null || md5sum "$file" 2>/dev/null | cut -d' ' -f1)
    if [[ -n "${hashes[$hash]:-}" ]]; then
        echo "⚠️  Duplicate content: $file == ${hashes[$hash]}"
    fi
    hashes[$hash]="$file"
done

# Summary
echo
if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✅ Zen minimalism check passed!"
    exit 0
else
    echo "❌ Found $VIOLATIONS violations"
    exit 1
fi
