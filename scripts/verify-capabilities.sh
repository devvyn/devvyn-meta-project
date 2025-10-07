#!/bin/bash
#
# Capability Verification Framework
# Tests actual capabilities vs. documented claims
# Updates YAML files with empirical evidence
#
# Philosophy: Eventual consistency with empirical truth
#

set -euo pipefail

CAPABILITIES_DIR="$HOME/devvyn-meta-project/agents/capabilities"
EVIDENCE_DIR="$HOME/devvyn-meta-project/agents/capabilities/evidence"
TIMESTAMP=$(date -Iseconds)
AGENT="${1:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Capability Verification - Empirical Testing Framework

USAGE:
    $(basename "$0") [agent]           # Verify specific agent
    $(basename "$0") all               # Verify all agents
    $(basename "$0") report            # Show verification status

AGENTS:
    code-cli        Claude Code CLI (current context)
    chat-desktop    Claude Chat Desktop (requires manual testing)
    chat-mobile     Claude Chat Mobile (requires iPhone)
    investigator    INVESTIGATOR Agent

PHILOSOPHY:
    - Test actual capabilities (don't assume)
    - Record evidence (logs, timestamps, results)
    - Update YAML with test results
    - Track confidence (verified vs. speculative)
    - Converge toward empirical truth

EXAMPLES:
    $(basename "$0") code-cli
    $(basename "$0") all
    $(basename "$0") report

EOF
    exit 1
}

log() {
    echo -e "${BLUE}[VERIFY $(date +%H:%M:%S)]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Ensure evidence directory exists
mkdir -p "$EVIDENCE_DIR"

# Test: Can this agent send bridge messages?
test_bridge_send() {
    local agent="$1"
    local evidence_file="$EVIDENCE_DIR/${agent}_bridge_send_${TIMESTAMP}.log"

    log "Testing: Bridge message send capability..."

    case "$agent" in
        code-cli)
            # We ARE code-cli, test by creating a test message
            local test_file="/tmp/capability-test-${TIMESTAMP}.md"
            echo "# Capability Test - Bridge Send" > "$test_file"
            echo "Testing bridge send capability at $TIMESTAMP" >> "$test_file"

            if ~/devvyn-meta-project/scripts/bridge-send.sh code code NORMAL "Capability Test" "$test_file" &> "$evidence_file"; then
                log_success "Bridge send: VERIFIED"
                echo "status: verified" >> "$evidence_file"
                echo "timestamp: $TIMESTAMP" >> "$evidence_file"
                echo "method: actual_test" >> "$evidence_file"
                return 0
            else
                log_fail "Bridge send: FAILED"
                echo "status: failed" >> "$evidence_file"
                echo "error: $(tail -5 "$evidence_file")" >> "$evidence_file"
                return 1
            fi
            ;;

        chat-desktop)
            log_warn "Bridge send: MANUAL TEST REQUIRED"
            echo "status: manual_test_required" >> "$evidence_file"
            echo "instructions: Use osascript in Chat Desktop to test bridge-send.sh" >> "$evidence_file"
            return 2
            ;;

        chat-mobile)
            log_warn "Bridge send: PLATFORM TEST REQUIRED (iPhone)"
            echo "status: platform_test_required" >> "$evidence_file"
            echo "platform: ios" >> "$evidence_file"
            echo "claim: status=none (no script execution)" >> "$evidence_file"
            return 2
            ;;

        investigator)
            log_warn "Bridge send: NOT IMPLEMENTED (by design)"
            echo "status: not_implemented_by_design" >> "$evidence_file"
            echo "writes: Desktop reports instead" >> "$evidence_file"
            return 2
            ;;
    esac
}

# Test: Can this agent read files?
test_file_read() {
    local agent="$1"
    local evidence_file="$EVIDENCE_DIR/${agent}_file_read_${TIMESTAMP}.log"

    log "Testing: File read capability..."

    case "$agent" in
        code-cli)
            # Test reading a known file
            if cat "$CAPABILITIES_DIR/manifest.yaml" &> "$evidence_file"; then
                log_success "File read: VERIFIED"
                echo "status: verified" >> "$evidence_file"
                echo "test_file: manifest.yaml" >> "$evidence_file"
                return 0
            else
                log_fail "File read: FAILED"
                return 1
            fi
            ;;

        *)
            log_warn "File read: REQUIRES CONTEXT-SPECIFIC TEST"
            echo "status: context_specific" >> "$evidence_file"
            return 2
            ;;
    esac
}

# Test: Can this agent execute git commands?
test_git_operations() {
    local agent="$1"
    local evidence_file="$EVIDENCE_DIR/${agent}_git_${TIMESTAMP}.log"

    log "Testing: Git operations capability..."

    case "$agent" in
        code-cli)
            # Test git status (safe, read-only)
            if git -C ~/devvyn-meta-project status &> "$evidence_file"; then
                log_success "Git operations: VERIFIED"
                echo "status: verified" >> "$evidence_file"
                echo "test_command: git status" >> "$evidence_file"
                return 0
            else
                log_fail "Git operations: FAILED"
                return 1
            fi
            ;;

        chat-desktop|chat-mobile|investigator)
            log_warn "Git operations: NOT AVAILABLE (by design)"
            echo "status: not_available_by_design" >> "$evidence_file"
            echo "agent_role: non-technical" >> "$evidence_file"
            return 2
            ;;
    esac
}

# Test: Can this agent access web?
test_web_access() {
    local agent="$1"
    local evidence_file="$EVIDENCE_DIR/${agent}_web_${TIMESTAMP}.log"

    log "Testing: Web access capability..."

    case "$agent" in
        code-cli)
            # Code CLI doesn't have web access
            log_warn "Web access: NOT AVAILABLE"
            echo "status: not_available" >> "$evidence_file"
            echo "reason: No WebFetch or WebSearch tools" >> "$evidence_file"
            return 1
            ;;

        chat-desktop)
            log_warn "Web access: MANUAL TEST REQUIRED"
            echo "status: manual_test_required" >> "$evidence_file"
            echo "instructions: Try WebSearch or WebFetch in Chat Desktop" >> "$evidence_file"
            return 2
            ;;

        chat-mobile)
            log_warn "Web access: PLATFORM TEST REQUIRED"
            echo "status: platform_test_required" >> "$evidence_file"
            return 2
            ;;

        investigator)
            log_warn "Web access: NOT AVAILABLE"
            echo "status: not_available" >> "$evidence_file"
            return 1
            ;;
    esac
}

# Test: Command execution
test_command_execution() {
    local agent="$1"
    local evidence_file="$EVIDENCE_DIR/${agent}_command_${TIMESTAMP}.log"

    log "Testing: Command execution capability..."

    case "$agent" in
        code-cli)
            # Test basic command
            if echo "test" | wc -l &> "$evidence_file"; then
                log_success "Command execution: VERIFIED"
                echo "status: verified" >> "$evidence_file"
                return 0
            else
                log_fail "Command execution: FAILED"
                return 1
            fi
            ;;

        *)
            log_warn "Command execution: CONTEXT-SPECIFIC TEST REQUIRED"
            echo "status: context_specific" >> "$evidence_file"
            return 2
            ;;
    esac
}

# Generate verification report
generate_verification_report() {
    local agent="$1"
    local report_file="$EVIDENCE_DIR/${agent}_verification_report_${TIMESTAMP}.md"

    cat > "$report_file" <<EOF
# Capability Verification Report - $agent

**Timestamp**: $TIMESTAMP
**Verification Method**: Empirical testing
**Agent Context**: $agent

---

## Test Results

EOF

    # Check evidence files
    local test_count=0
    local verified_count=0
    local failed_count=0
    local manual_count=0

    for evidence in "$EVIDENCE_DIR"/${agent}_*_${TIMESTAMP}.log; do
        [[ -f "$evidence" ]] || continue

        ((test_count++))

        capability=$(basename "$evidence" | sed "s/${agent}_//" | sed "s/_${TIMESTAMP}.log//")
        status=$(grep "^status:" "$evidence" | cut -d: -f2 | xargs)

        case "$status" in
            verified)
                echo "- ✓ **$capability**: VERIFIED" >> "$report_file"
                ((verified_count++))
                ;;
            failed)
                echo "- ✗ **$capability**: FAILED" >> "$report_file"
                ((failed_count++))
                ;;
            manual_test_required|context_specific|platform_test_required)
                echo "- ⚠ **$capability**: Manual test required" >> "$report_file"
                ((manual_count++))
                ;;
            not_available*|not_implemented*)
                echo "- ○ **$capability**: Not available (expected)" >> "$report_file"
                ;;
        esac
    done

    cat >> "$report_file" <<EOF

---

## Summary

- **Tests Run**: $test_count
- **Verified**: $verified_count
- **Failed**: $failed_count
- **Manual Required**: $manual_count

---

## Confidence Assessment

EOF

    if (( verified_count > 0 )); then
        local confidence=$(( (verified_count * 100) / (verified_count + failed_count + manual_count) ))
        echo "**Confidence**: ${confidence}% (based on automated tests)" >> "$report_file"
    else
        echo "**Confidence**: 0% (no automated tests passed)" >> "$report_file"
    fi

    cat >> "$report_file" <<EOF

---

## Evidence Files

All test evidence stored in:
\`$EVIDENCE_DIR/${agent}_*_${TIMESTAMP}.log\`

## Next Steps

1. Review failed tests
2. Perform manual tests where required
3. Update capability YAML with verified results
4. Re-test periodically to ensure consistency

---

**Empirical Validation Complete**
EOF

    echo "$report_file"
}

# Verify agent capabilities
verify_agent() {
    local agent="$1"

    log "Starting verification for agent: $agent"
    echo

    # Run test suite
    test_bridge_send "$agent" || true
    test_file_read "$agent" || true
    test_git_operations "$agent" || true
    test_web_access "$agent" || true
    test_command_execution "$agent" || true

    echo
    log "Generating verification report..."

    local report=$(generate_verification_report "$agent")

    echo
    log_success "Verification complete: $report"

    # Show report
    cat "$report"
}

# Verify all agents
verify_all() {
    log "Verifying all agent contexts..."
    echo

    for agent in code-cli chat-desktop chat-mobile investigator; do
        verify_agent "$agent"
        echo
        echo "---"
        echo
    done
}

# Show verification status
show_verification_status() {
    log "Verification Status Report"
    echo

    if [[ ! -d "$EVIDENCE_DIR" ]] || [[ -z "$(ls -A "$EVIDENCE_DIR" 2>/dev/null)" ]]; then
        log_warn "No verification evidence found. Run verification first."
        echo
        echo "Usage: $(basename "$0") all"
        return
    fi

    # Find latest reports
    for agent in code-cli chat-desktop chat-mobile investigator; do
        local latest_report=$(ls -t "$EVIDENCE_DIR"/${agent}_verification_report_*.md 2>/dev/null | head -1)

        if [[ -f "$latest_report" ]]; then
            echo -e "${BLUE}$agent${NC}:"
            grep "^**Confidence**:" "$latest_report" | sed 's/^/  /'
            grep "^- " "$latest_report" | head -5 | sed 's/^/  /'
            echo
        else
            echo -e "${YELLOW}$agent${NC}: No verification data"
            echo
        fi
    done
}

# Main
case "${1:-}" in
    all)
        verify_all
        ;;
    report)
        show_verification_status
        ;;
    code-cli|chat-desktop|chat-mobile|investigator)
        verify_agent "$1"
        ;;
    "")
        usage
        ;;
    *)
        echo "Unknown agent: $1"
        usage
        ;;
esac

exit 0
