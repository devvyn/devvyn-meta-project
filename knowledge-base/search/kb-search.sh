#!/bin/bash
# Knowledge Base Search - Simple grep-based cross-project search
# Version: 1.0
# Part of: Multi-Agent Security Architecture v2.0

KB_BASE="$HOME/devvyn-meta-project/knowledge-base"
PROJECTS_BASE="$HOME/Documents/GitHub"

if [[ $# -lt 1 ]]; then
  echo "Usage: kb-search.sh <query> [--case-sensitive]"
  echo ""
  echo "Searches across:"
  echo "  - Knowledge base decisions"
  echo "  - Knowledge base patterns"
  echo "  - Project CLAUDE.md files"
  echo ""
  echo "Examples:"
  echo "  kb-search.sh 'error handling'"
  echo "  kb-search.sh 'memory optimization' --case-sensitive"
  exit 1
fi

query="$1"
case_flag="-i"  # Default: case insensitive

if [[ "$2" == "--case-sensitive" ]]; then
  case_flag=""
fi

echo "🔍 Searching knowledge base for: $query"
echo "=================================================="
echo ""

# Search decisions
if [[ -d "$KB_BASE/decisions" ]]; then
  echo "📋 Decisions:"
  echo "-------------"
  if grep -r $case_flag "$query" "$KB_BASE/decisions/" 2>/dev/null | sed 's/^/  /'; then
    :
  else
    echo "  (no matches)"
  fi
  echo ""
fi

# Search patterns
if [[ -d "$KB_BASE/patterns" ]]; then
  echo "🔧 Patterns:"
  echo "------------"
  if grep -r $case_flag "$query" "$KB_BASE/patterns/" 2>/dev/null | sed 's/^/  /'; then
    :
  else
    echo "  (no matches)"
  fi
  echo ""
fi

# Search project CLAUDE.md files
echo "📁 Projects:"
echo "------------"
found_projects=0
while IFS= read -r -d '' claude_file; do
  if grep -l $case_flag "$query" "$claude_file" >/dev/null 2>&1; then
    project_name=$(basename "$(dirname "$claude_file")")
    echo "  ✓ $project_name"
    grep -n $case_flag "$query" "$claude_file" 2>/dev/null | head -3 | sed 's/^/    /'
    found_projects=$((found_projects + 1))
  fi
done < <(find "$PROJECTS_BASE" -name "CLAUDE.md" -print0 2>/dev/null)

if [[ $found_projects -eq 0 ]]; then
  echo "  (no matches)"
fi

echo ""
echo "=================================================="
echo "Search complete: found in knowledge base and $found_projects project(s)"
