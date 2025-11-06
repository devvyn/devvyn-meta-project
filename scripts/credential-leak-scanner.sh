#!/usr/bin/env bash
# Credential Leak Scanner
# Scans text for credential-like patterns that may have been exposed
#
# Usage:
#   credential-leak-scanner.sh <file>           # Scan single file
#   credential-leak-scanner.sh --dir <path>     # Scan directory recursively
#   credential-leak-scanner.sh --quick <path>   # Quick scan (common locations only)

set -euo pipefail

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Statistics
SCANNED_FILES=0
FINDINGS=0

# Credential patterns
scan_patterns() {
    local filepath="$1"
    local findings=0

    # Skip binary files
    if ! file "$filepath" 2>/dev/null | grep -q "text"; then
        return 0
    fi

    ((SCANNED_FILES++))

    # Pattern: API keys starting with sk-
    if /usr/bin/grep -qE 'sk-[a-zA-Z0-9]{20,}' "$filepath" 2>/dev/null; then
        echo -e "${RED}⚠️  API Key (sk-): $filepath${NC}"
        /usr/bin/grep -nE 'sk-[a-zA-Z0-9]{20,}' "$filepath" | head -3
        ((FINDINGS++))
        findings=1
    fi

    # Pattern: Bearer tokens
    if /usr/bin/grep -qE 'Bearer [a-zA-Z0-9_\.\-]{20,}' "$filepath" 2>/dev/null; then
        echo -e "${RED}⚠️  Bearer Token: $filepath${NC}"
        /usr/bin/grep -nE 'Bearer [a-zA-Z0-9_\.\-]{20,}' "$filepath" | head -3
        ((FINDINGS++))
        findings=1
    fi

    # Pattern: AWS keys
    if /usr/bin/grep -qE 'AKIA[A-Z0-9]{16}' "$filepath" 2>/dev/null; then
        echo -e "${RED}⚠️  AWS Access Key: $filepath${NC}"
        /usr/bin/grep -nE 'AKIA[A-Z0-9]{16}' "$filepath" | head -3
        ((FINDINGS++))
        findings=1
    fi

    # Pattern: Private keys
    if /usr/bin/grep -qE '-----BEGIN [A-Z]+ PRIVATE KEY-----' "$filepath" 2>/dev/null; then
        echo -e "${RED}⚠️  Private Key (PEM): $filepath${NC}"
        echo "  Line: $(grep -n 'BEGIN.*PRIVATE KEY' "$filepath" | head -1)"
        ((FINDINGS++))
        findings=1
    fi

    # Pattern: GitHub tokens
    if /usr/bin/grep -qE 'ghp_[a-zA-Z0-9]{36}' "$filepath" 2>/dev/null; then
        echo -e "${RED}⚠️  GitHub Token: $filepath${NC}"
        /usr/bin/grep -nE 'ghp_[a-zA-Z0-9]{36}' "$filepath" | head -3
        ((FINDINGS++))
        findings=1
    fi

    # Pattern: JWT tokens
    if /usr/bin/grep -qE 'eyJ[a-zA-Z0-9_\-]+\.eyJ[a-zA-Z0-9_\-]+' "$filepath" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  JWT Token (potential): $filepath${NC}"
        /usr/bin/grep -nE 'eyJ[a-zA-Z0-9_\-]+\.eyJ[a-zA-Z0-9_\-]+' "$filepath" | head -3
        ((FINDINGS++))
        findings=1
    fi

    # Pattern: Long hex strings (64+ chars, potential secrets)
    if /usr/bin/grep -qE '[a-f0-9]{64,}' "$filepath" 2>/dev/null; then
        # Check it's not in excluded contexts
        if ! /usr/bin/grep -qE '(commit|hash|checksum|sha256|example)' "$filepath" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  Long Hex String (potential secret): $filepath${NC}"
            /usr/bin/grep -nE '[a-f0-9]{64,}' "$filepath" | head -2
            ((FINDINGS++))
            findings=1
        fi
    fi

    [ $findings -eq 1 ] && echo ""
    return 0
}

scan_file() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        scan_patterns "$filepath"
    fi
}

scan_directory() {
    local dirpath="$1"
    echo "Scanning directory: $dirpath"
    echo ""

    # Find text files, excluding common non-sensitive locations
    find "$dirpath" -type f \
        ! -path "*/\.git/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/__pycache__/*" \
        ! -path "*/\.venv/*" \
        ! -path "*/venv/*" \
        ! -path "*/build/*" \
        ! -path "*/dist/*" \
        ! -name "*.pyc" \
        ! -name "*.so" \
        ! -name "*.dylib" \
        2>/dev/null | while read -r file; do
            scan_file "$file"
        done
}

quick_scan() {
    local base_path="${1:-$HOME}"

    echo "=== QUICK CREDENTIAL LEAK SCAN ==="
    echo "Checking high-risk locations..."
    echo ""

    local locations=(
        "$HOME/.zsh_history"
        "$HOME/.bash_history"
        "$HOME/Desktop/*.txt"
        "$HOME/Desktop/*.md"
        "$HOME/Downloads/*.txt"
        "$HOME/Downloads/*.md"
        "/tmp/*.log"
    )

    for pattern in "${locations[@]}"; do
        # Expand glob pattern
        shopt -s nullglob 2>/dev/null || setopt nullglob 2>/dev/null || true
        for file in $pattern; do
            if [ -f "$file" ]; then
                scan_file "$file"
            fi
        done
    done
}

print_summary() {
    echo ""
    echo "=== SCAN COMPLETE ==="
    echo "Files scanned: $SCANNED_FILES"
    echo "Findings: $FINDINGS"
    echo ""

    if [ $FINDINGS -gt 0 ]; then
        echo -e "${RED}⚠️  CREDENTIALS DETECTED - ACTION REQUIRED${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Review findings above"
        echo "2. Rotate any exposed credentials immediately"
        echo "3. Remove or redact sensitive files"
        echo "4. Use credential-safe-check.sh for future verification"
        echo ""
        return 1
    else
        echo -e "${GREEN}✅ No credential leaks detected${NC}"
        return 0
    fi
}

usage() {
    cat <<EOF
Credential Leak Scanner - Detect exposed credentials

Usage:
    $(basename "$0") <file>               # Scan single file
    $(basename "$0") --dir <path>         # Scan directory recursively
    $(basename "$0") --quick [path]       # Quick scan (history, Desktop, tmp)

Examples:
    # Scan conversation log
    $(basename "$0") ~/Desktop/conversation.txt

    # Scan project directory
    $(basename "$0") --dir ~/devvyn-meta-project/

    # Quick system check
    $(basename "$0") --quick

Patterns detected:
    - API keys (sk- prefix)
    - Bearer tokens
    - AWS access keys (AKIA...)
    - GitHub tokens (ghp_...)
    - Private keys (PEM format)
    - JWT tokens
    - Long hex strings (potential secrets)

Safe credential checking:
    ~/devvyn-meta-project/scripts/credential-safe-check.sh keychain SERVICE
    ~/devvyn-meta-project/scripts/credential-safe-check.sh env VARIABLE

Exit codes:
    0 - No leaks found
    1 - Leaks detected
EOF
}

# Main
case "${1:-}" in
    --dir)
        [ -z "${2:-}" ] && usage && exit 1
        scan_directory "$2"
        print_summary
        ;;
    --quick)
        quick_scan "${2:-$HOME}"
        print_summary
        ;;
    -h|--help|help)
        usage
        exit 0
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        if [ -f "$1" ]; then
            scan_file "$1"
            print_summary
        else
            echo "Error: File not found: $1"
            usage
            exit 1
        fi
        ;;
esac
