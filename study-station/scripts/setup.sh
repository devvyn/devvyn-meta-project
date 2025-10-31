#!/usr/bin/env zsh
# Setup script for Conmigo Terminal study station

set -e

STUDY_DIR="${HOME}/devvyn-meta-project/study-station"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "${BLUE}╔════════════════════════════════════════╗${NC}"
echo "${BLUE}║${NC}  Setting up Conmigo Terminal...      ${BLUE}║${NC}"
echo "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if directories exist
if [[ ! -d "$STUDY_DIR" ]]; then
    echo "${YELLOW}Study station directory not found. Creating...${NC}"
    mkdir -p "${STUDY_DIR}"/{sessions,topics,progress,templates,artifacts,scripts}
fi

# Check for required commands
echo "Checking dependencies..."
MISSING_DEPS=""

for cmd in fd rg python3; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_DEPS="${MISSING_DEPS}  - $cmd\n"
    else
        echo "  ${GREEN}✓${NC} $cmd"
    fi
done

if [[ -n "$MISSING_DEPS" ]]; then
    echo ""
    echo "${YELLOW}Missing dependencies:${NC}"
    echo -e "$MISSING_DEPS"
    echo ""
    echo "Install with:"
    echo "  brew install fd ripgrep python3"
    exit 1
fi

# Add to PATH if not already there
if [[ ! ":$PATH:" == *":${STUDY_DIR}/scripts:"* ]]; then
    echo ""
    echo "Adding study command to PATH..."

    SHELL_RC="${HOME}/.zshrc"
    PATH_EXPORT="export PATH=\"\$HOME/devvyn-meta-project/study-station/scripts:\$PATH\""

    if ! grep -q "study-station/scripts" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Conmigo Terminal - AI Learning Station" >> "$SHELL_RC"
        echo "$PATH_EXPORT" >> "$SHELL_RC"
        echo "  ${GREEN}✓${NC} Added to $SHELL_RC"
    else
        echo "  ${GREEN}✓${NC} Already in PATH"
    fi
fi

# Make scripts executable
if [[ -f "${STUDY_DIR}/scripts/study" ]]; then
    chmod +x "${STUDY_DIR}/scripts/study"
    echo "  ${GREEN}✓${NC} Made scripts executable"
fi

# Check for Claude Code commands
if [[ -d "${HOME}/.claude/commands" ]]; then
    CLAUDE_COMMANDS=("study.md" "practice.md" "review.md")
    ALL_PRESENT=true

    for cmd in "${CLAUDE_COMMANDS[@]}"; do
        if [[ ! -f "${HOME}/.claude/commands/$cmd" ]]; then
            ALL_PRESENT=false
            break
        fi
    done

    if $ALL_PRESENT; then
        echo "  ${GREEN}✓${NC} Claude Code commands installed"
    else
        echo "  ${YELLOW}!${NC} Some Claude Code commands missing"
        echo "    Run the study station setup again to reinstall"
    fi
else
    echo "  ${YELLOW}!${NC} Claude Code commands directory not found"
    echo "    Create ~/.claude/commands/ to enable slash commands"
fi

echo ""
echo "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "${BLUE}Quick Start:${NC}"
echo "  1. Reload your shell: ${YELLOW}source ~/.zshrc${NC}"
echo "  2. Start a session: ${YELLOW}study start <topic>${NC}"
echo "  3. In Claude Code: ${YELLOW}/study${NC}"
echo ""
echo "Documentation: ${STUDY_DIR}/README.md"
echo ""
echo "${BLUE}Happy learning! 🎓${NC}"
