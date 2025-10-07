#!/bin/bash
#
# Update Capability YAML from Verification Evidence
# Converges documentation toward empirical truth
#
# Philosophy: Docs should reflect reality, not assumptions
#

set -euo pipefail

CAPABILITIES_DIR="$HOME/devvyn-meta-project/agents/capabilities"
EVIDENCE_DIR="$CAPABILITIES_DIR/evidence"
AGENT="${1:-}"

usage() {
    cat <<EOF
Update Capability YAML from Evidence

USAGE:
    $(basename "$0") [agent]           # Update agent YAML from latest evidence
    $(basename "$0") all               # Update all agents from evidence

PHILOSOPHY:
    1. Verification tests produce evidence
    2. Evidence files are ground truth
    3. YAML files updated to match evidence
    4. Discrepancies flagged for human review
    5. Eventual consistency with empirical reality

WORKFLOW:
    1. Run: ./verify-capabilities.sh [agent]
    2. Review: Evidence files in capabilities/evidence/
    3. Update: ./update-capabilities-from-evidence.sh [agent]
    4. Verify: Check git diff for changes

EOF
    exit 1
}

log() {
    echo "[UPDATE] $1"
}

# Update verification metadata in YAML
update_verification_metadata() {
    local yaml_file="$1"
    local agent="$2"
    local timestamp="$3"
    local confidence="$4"

    # Check if verification section exists
    if ! grep -q "^verification:" "$yaml_file"; then
        # Add verification section
        cat >> "$yaml_file" <<EOF

# Verification Evidence
verification:
  last_tested: "$timestamp"
  method: empirical_testing
  confidence: $confidence
  evidence_dir: ~/devvyn-meta-project/agents/capabilities/evidence/
  auto_updated: true

EOF
        log "Added verification metadata to $yaml_file"
    else
        # Update existing verification
        # For simplicity, append updated timestamp
        sed -i '' "/^verification:/,/^[^ ]/s/^  last_tested:.*/  last_tested: \"$timestamp\"/" "$yaml_file"
        sed -i '' "/^verification:/,/^[^ ]/s/^  confidence:.*/  confidence: $confidence/" "$yaml_file"
        log "Updated verification metadata in $yaml_file"
    fi
}

# Update capability status from evidence
update_capability_status() {
    local yaml_file="$1"
    local capability="$2"
    local status="$3"
    local evidence_file="$4"

    log "Updating $capability: $status (evidence: $evidence_file)"

    # For now, log the update
    # Actual YAML update would use yq or manual sed
    # This is the framework - human can review and apply

    echo "  → $capability: $status"
}

# Process evidence for an agent
process_agent_evidence() {
    local agent="$1"
    local yaml_file="$CAPABILITIES_DIR/${agent}.yaml"

    if [[ ! -f "$yaml_file" ]]; then
        log "ERROR: YAML file not found: $yaml_file"
        return 1
    fi

    # Find latest verification report
    local latest_report=$(ls -t "$EVIDENCE_DIR"/${agent}_verification_report_*.md 2>/dev/null | head -1)

    if [[ ! -f "$latest_report" ]]; then
        log "No verification report found for $agent"
        log "Run: ./verify-capabilities.sh $agent"
        return 1
    fi

    log "Processing evidence for $agent"
    log "Latest report: $latest_report"

    # Extract timestamp
    local timestamp=$(grep "^\\*\\*Timestamp\\*\\*:" "$latest_report" | cut -d: -f2- | xargs)

    # Extract confidence
    local confidence=$(grep "^\\*\\*Confidence\\*\\*:" "$latest_report" | grep -o '[0-9]*%' | tr -d '%')

    log "Timestamp: $timestamp"
    log "Confidence: $confidence%"

    # Find all evidence logs from this verification
    local evidence_pattern="${agent}_*_${timestamp}.log"

    echo
    log "Evidence files:"
    for evidence in "$EVIDENCE_DIR"/$evidence_pattern; do
        [[ -f "$evidence" ]] || continue

        local capability=$(basename "$evidence" | sed "s/${agent}_//" | sed "s/_${timestamp}.log//")
        local status=$(grep "^status:" "$evidence" | cut -d: -f2 | xargs)

        echo "  - $capability: $status"
    done

    echo
    log "Updating YAML verification metadata..."
    update_verification_metadata "$yaml_file" "$agent" "$timestamp" "$confidence"

    echo
    log "Update complete. Review changes:"
    echo "  git diff $yaml_file"
}

# Process all agents
process_all() {
    for agent in code-cli chat-desktop chat-mobile investigator; do
        echo "=== $agent ==="
        process_agent_evidence "$agent" || true
        echo
    done
}

# Main
case "${1:-}" in
    all)
        process_all
        ;;
    code-cli|chat-desktop|chat-mobile|investigator)
        process_agent_evidence "$1"
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
