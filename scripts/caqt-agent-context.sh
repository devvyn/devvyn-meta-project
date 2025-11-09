#!/bin/bash
# caqt-agent-context.sh - Agent Contextualization Helper
#
# Purpose: Rapidly contextualize agent in unfamiliar codebase
# Philosophy: Proactive configuration of contingent context
#
# Use Cases:
# 1. Agent session startup in new project
# 2. Human observer guides exploration
# 3. Generates questions even when agent doesn't know what to ask
#
# Integration:
#   Add to .claude/commands/context.md or session-start hook

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [PATH]

Rapidly contextualize an agent in an unfamiliar codebase by generating
architectural questions.

OPTIONS:
    -m, --mode MODE         Output mode: quick|deep|interactive (default: quick)
    -o, --output FILE       Write output to file (default: stdout)
    -t, --tier TIER         Filter by tier 1-4 (default: all)
    --top N                 Show top N questions (default: 20)
    --human-guided          Interactive mode with human observer
    --save-context          Save context to .caqt-context.md for reuse
    -h, --help              Show this help

MODES:
    quick           TIER1 questions only, <10 second analysis
    deep            All tiers, comprehensive analysis
    interactive     Human observer guides question prioritization

EXAMPLES:
    # Quick startup context (agent just opened project)
    $0 --mode quick

    # Human-guided exploration
    $0 --mode interactive --human-guided

    # Save context for later reuse
    $0 --mode deep --save-context

    # Analyze specific directory
    $0 /path/to/module --mode quick
EOF
}

log() {
    echo -e "${BLUE}[CAQT]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

# Parse arguments
MODE="quick"
OUTPUT=""
TIER=""
TOP="20"
HUMAN_GUIDED=false
SAVE_CONTEXT=false
TARGET_PATH="."

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -t|--tier)
            TIER="$2"
            shift 2
            ;;
        --top)
            TOP="$2"
            shift 2
            ;;
        --human-guided)
            HUMAN_GUIDED=true
            shift
            ;;
        --save-context)
            SAVE_CONTEXT=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            TARGET_PATH="$1"
            shift
            ;;
    esac
done

# Validate target path
if [[ ! -e "$TARGET_PATH" ]]; then
    error "Path does not exist: $TARGET_PATH"
    exit 1
fi

# Check if CAQT tool exists
CAQT_TOOL="$SCRIPT_DIR/caqt-generate.py"
if [[ ! -x "$CAQT_TOOL" ]]; then
    error "CAQT tool not found or not executable: $CAQT_TOOL"
    error "Run: chmod +x $CAQT_TOOL"
    exit 1
fi

# Human-guided interactive mode
if [[ "$HUMAN_GUIDED" == true ]]; then
    log "Starting human-guided contextualization..."
    echo ""
    echo "The agent is in an unfamiliar environment and needs your help."
    echo ""
    echo "Please answer these questions to guide the analysis:"
    echo ""

    # Question 1: Project type
    echo "1. What type of project is this?"
    echo "   a) Web application"
    echo "   b) Data processing / Science"
    echo "   c) Library / Framework"
    echo "   d) CLI tool"
    echo "   e) Other"
    read -p "   Your answer (a-e): " PROJECT_TYPE
    echo ""

    # Question 2: Focus areas
    echo "2. What should the agent focus on first?"
    echo "   a) Understanding overall architecture"
    echo "   b) Finding entry points and workflows"
    echo "   c) Identifying dependencies and integrations"
    echo "   d) Reviewing code quality and patterns"
    echo "   e) All of the above"
    read -p "   Your answer (a-e): " FOCUS_AREA
    echo ""

    # Question 3: Known issues
    echo "3. Are there known issues or areas of concern?"
    read -p "   Your answer (or press Enter to skip): " KNOWN_ISSUES
    echo ""

    # Generate context based on human guidance
    log "Generating context based on your guidance..."

    # Adjust analysis based on responses
    case $PROJECT_TYPE in
        a)
            log "Focusing on web application patterns..."
            ;;
        b)
            log "Focusing on data processing and scientific workflows..."
            ;;
        c)
            log "Focusing on API design and modularity..."
            ;;
        d)
            log "Focusing on CLI interface and user experience..."
            ;;
        *)
            log "Performing general analysis..."
            ;;
    esac
fi

# Proactive context generation
log "Analyzing codebase: $TARGET_PATH"
log "Mode: $MODE"

# Build command
CMD=("$CAQT_TOOL" "$TARGET_PATH")

if [[ "$MODE" == "quick" ]]; then
    CMD+=(--mode agent-context --tier 1 --top "$TOP")
elif [[ "$MODE" == "deep" ]]; then
    CMD+=(--mode full-report)
elif [[ "$MODE" == "interactive" ]]; then
    CMD+=(--mode agent-context --top "$TOP")
fi

if [[ -n "$TIER" ]]; then
    CMD+=(--tier "$TIER")
fi

# Generate temporary output if needed
TEMP_OUTPUT=""
if [[ -n "$OUTPUT" ]] || [[ "$SAVE_CONTEXT" == true ]]; then
    TEMP_OUTPUT=$(mktemp)
    CMD+=(--output "$TEMP_OUTPUT")
fi

# Run analysis
log "Running analysis..."
if ! "${CMD[@]}"; then
    error "Analysis failed"
    [[ -n "$TEMP_OUTPUT" ]] && rm -f "$TEMP_OUTPUT"
    exit 1
fi

# Display output
if [[ -n "$TEMP_OUTPUT" ]]; then
    if [[ -z "$OUTPUT" ]]; then
        # Display to stdout
        cat "$TEMP_OUTPUT"
    else
        # Write to specified file
        cp "$TEMP_OUTPUT" "$OUTPUT"
        success "Context written to: $OUTPUT"
    fi

    # Save context if requested
    if [[ "$SAVE_CONTEXT" == true ]]; then
        CONTEXT_FILE="$TARGET_PATH/.caqt-context.md"
        cp "$TEMP_OUTPUT" "$CONTEXT_FILE"
        success "Context saved to: $CONTEXT_FILE (reuse for future sessions)"
    fi

    # Add human guidance to output
    if [[ "$HUMAN_GUIDED" == true ]] && [[ -n "$OUTPUT" || "$SAVE_CONTEXT" == true ]]; then
        TARGET_FILE="${OUTPUT:-$CONTEXT_FILE}"
        cat >> "$TARGET_FILE" <<EOF

---

## Human Observer Guidance

**Project Type**: $PROJECT_TYPE
**Focus Area**: $FOCUS_AREA
**Known Issues**: ${KNOWN_ISSUES:-None specified}

**Human Observer Notes**:
- This context was generated with human guidance
- The agent should prioritize the indicated focus areas
- Consult the human observer if critical questions remain unanswered

EOF
        log "Added human guidance to context file"
    fi

    rm -f "$TEMP_OUTPUT"
fi

# Proactive suggestions
echo ""
echo "---"
echo ""
log "Proactive Context Configuration Complete"
echo ""
echo "NEXT STEPS FOR AGENT:"
echo ""
echo "1. Review the critical questions above"
echo "2. Explore entry points to understand execution flow"
echo "3. If uncertain, ask human observer for clarification"
echo "4. Document findings as you discover answers"
echo ""

if [[ "$SAVE_CONTEXT" == true ]]; then
    echo "5. Context saved to .caqt-context.md - reference in future sessions"
    echo ""
fi

echo "CONTINGENT CONTEXTS TO PREPARE:"
echo ""
echo "- If making changes: Review architectural questions first"
echo "- If debugging: Focus on TIER1 questions about critical paths"
echo "- If documenting: Use questions as documentation outline"
echo "- If onboarding: Answer questions to validate understanding"
echo ""

# Interactive follow-up
if [[ "$HUMAN_GUIDED" == true ]]; then
    echo "---"
    echo ""
    read -p "Would you like to add any additional context for the agent? (y/N): " ADD_CONTEXT

    if [[ "$ADD_CONTEXT" =~ ^[Yy] ]]; then
        echo "Enter additional context (press Ctrl+D when done):"
        ADDITIONAL_CONTEXT=$(cat)

        if [[ -n "$OUTPUT" || "$SAVE_CONTEXT" == true ]]; then
            TARGET_FILE="${OUTPUT:-$TARGET_PATH/.caqt-context.md}"
            cat >> "$TARGET_FILE" <<EOF

## Additional Human Context

$ADDITIONAL_CONTEXT

EOF
            success "Additional context added"
        else
            echo ""
            echo "## Additional Human Context"
            echo ""
            echo "$ADDITIONAL_CONTEXT"
        fi
    fi
fi

success "Contextualization complete!"
