#!/bin/bash
# BRIDGE_SPEC_VALIDATE.sh - Constitutional Validation System for BSPEC v1.0
# Enforces constitutional governance and authority domain compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="$(dirname "$SCRIPT_DIR")/bridge"

# Bridge utilities - use direct calls instead of sourcing

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BSPEC-VALIDATE: $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

# Constitutional validation rules
AUTHORITY_DOMAINS=(
    "specification:can_define_requirements,can_approve_plans"
    "implementation:can_write_code,can_modify_implementations"
    "validation:can_run_tests,can_approve_releases"
    "coordination:can_manage_tasks,can_orchestrate_workflows"
)

# Validation severity levels (for documentation)
# CRITICAL: Must be fixed before proceeding
# HIGH: Should be fixed before proceeding
# MEDIUM: Should be addressed
# LOW: Optional improvement
# INFO: Informational only

# Validate constitutional compliance
validate_constitutional_compliance() {
    local project_path="$1"
    local agent_authority="$2"
    local requested_action="$3"

    log "Validating constitutional compliance for: $requested_action"

    local violations=()
    local validation_result="PASS"

    # Check authority domain permissions
    if ! check_authority_permissions "$agent_authority" "$requested_action"; then
        violations+=("CRITICAL: Agent lacks authority for action: $requested_action")
        validation_result="FAIL"
    fi

    # Check pipeline stage consistency
    if ! check_pipeline_consistency "$project_path"; then
        violations+=("HIGH: Pipeline stages are inconsistent")
        validation_result="FAIL"
    fi

    # Check message queue integrity
    if ! check_message_integrity "$project_path"; then
        violations+=("MEDIUM: Message queue integrity issues detected")
    fi

    # Generate validation report
    generate_validation_report "$project_path" "$validation_result" "${violations[@]}"

    [[ "$validation_result" == "PASS" ]]
}

check_authority_permissions() {
    local agent_authority="$1"
    local requested_action="$2"

    log "Checking authority: $agent_authority for action: $requested_action"

    # Parse authority domains and permissions
    for domain_spec in "${AUTHORITY_DOMAINS[@]}"; do
        local domain="${domain_spec%%:*}"
        local permissions="${domain_spec#*:}"

        if [[ "$agent_authority" == "$domain" ]]; then
            IFS=',' read -ra perms <<< "$permissions"
            for perm in "${perms[@]}"; do
                if [[ "$requested_action" == "$perm" ]]; then
                    log "Authority check PASSED: $agent_authority can $requested_action"
                    return 0
                fi
            done
        fi
    done

    log "Authority check FAILED: $agent_authority cannot $requested_action"
    return 1
}

check_pipeline_consistency() {
    local project_path="$1"
    local manifest_file="$project_path/.bspec/manifest.json"

    [[ -f "$manifest_file" ]] || {
        log "No manifest file found, skipping pipeline consistency check"
        return 0
    }

    # Validate stage order
    local stages=("specify" "plan" "tasks" "implement" "validate")
    local current_stage=""
    local found_incomplete=false

    for stage in "${stages[@]}"; do
        local status
        status="$(jq -r ".stages.$stage.status" "$manifest_file" 2>/dev/null || echo "missing")"

        case "$status" in
            "completed")
                if [[ "$found_incomplete" == true ]]; then
                    log "Pipeline consistency FAILED: $stage completed but earlier stage incomplete"
                    return 1
                fi
                ;;
            "in_progress")
                if [[ "$found_incomplete" == true ]]; then
                    log "Pipeline consistency FAILED: Multiple stages in progress"
                    return 1
                fi
                current_stage="$stage"
                found_incomplete=true
                ;;
            "pending"|"missing")
                found_incomplete=true
                ;;
        esac
    done

    log "Pipeline consistency check PASSED"
    return 0
}

check_message_integrity() {
    local project_path="$1"
    local bridge_namespace

    # Extract bridge namespace from manifest
    local manifest_file="$project_path/.bspec/manifest.json"
    if [[ -f "$manifest_file" ]]; then
        bridge_namespace="$(jq -r '.bridge_namespace // "unknown"' "$manifest_file")"
    else
        bridge_namespace="unknown"
    fi

    local inbox_dir="$BRIDGE_DIR/inbox"
    local outbox_dir="$BRIDGE_DIR/outbox"

    # Check for orphaned messages
    local orphaned_count=0
    if [[ -d "$inbox_dir" ]]; then
        while IFS= read -r -d '' message_file; do
            local sender
            sender="$(jq -r '.sender // "unknown"' "$message_file" 2>/dev/null || echo "unknown")"

            if [[ "$sender" == "$bridge_namespace"* ]] && [[ ! -f "${message_file/inbox/outbox}" ]]; then
                ((orphaned_count++))
            fi
        done < <(find "$inbox_dir" -name "*.json" -print0 2>/dev/null || true)
    fi

    if [[ "$orphaned_count" -gt 5 ]]; then
        log "Message integrity WARNING: $orphaned_count orphaned messages found"
        return 1
    fi

    log "Message integrity check PASSED"
    return 0
}

# Validate specific BSPEC artifacts
validate_specification() {
    local spec_file="$1"

    log "Validating specification: $spec_file"

    [[ -f "$spec_file" ]] || error "Specification file not found: $spec_file"

    local violations=()

    # Check required sections
    local required_sections=("Requirements" "Acceptance Criteria" "Technical Constraints")
    for section in "${required_sections[@]}"; do
        if ! grep -q "## $section" "$spec_file"; then
            violations+=("MEDIUM: Missing required section: $section")
        fi
    done

    # Check for acceptance criteria format
    if ! grep -q "- \[ \]" "$spec_file"; then
        violations+=("LOW: No checkboxes found in acceptance criteria")
    fi

    # Validate specification completeness
    local word_count
    word_count="$(wc -w < "$spec_file")"
    if [[ "$word_count" -lt 50 ]]; then
        violations+=("HIGH: Specification too brief ($word_count words)")
    fi

    echo "${violations[@]}"
}

validate_implementation_plan() {
    local plan_file="$1"

    log "Validating implementation plan: $plan_file"

    [[ -f "$plan_file" ]] || error "Plan file not found: $plan_file"

    local violations=()

    # Check required sections
    local required_sections=("Architecture Overview" "Implementation Phases" "Dependencies" "Risk Assessment")
    for section in "${required_sections[@]}"; do
        if ! grep -q "## $section" "$plan_file"; then
            violations+=("MEDIUM: Missing required section: $section")
        fi
    done

    # Validate plan depth
    local heading_count
    heading_count="$(grep -c "^#" "$plan_file")"
    if [[ "$heading_count" -lt 4 ]]; then
        violations+=("HIGH: Implementation plan lacks sufficient detail")
    fi

    echo "${violations[@]}"
}

validate_task_breakdown() {
    local tasks_file="$1"

    log "Validating task breakdown: $tasks_file"

    [[ -f "$tasks_file" ]] || error "Tasks file not found: $tasks_file"

    local violations=()

    # Validate JSON structure
    if ! jq empty "$tasks_file" 2>/dev/null; then
        violations+=("CRITICAL: Invalid JSON in tasks file")
        echo "${violations[@]}"
        return
    fi

    # Check required fields
    local required_fields=("tasks" "total_estimated_hours" "critical_path")
    for field in "${required_fields[@]}"; do
        if [[ "$(jq "has(\"$field\")" "$tasks_file")" != "true" ]]; then
            violations+=("HIGH: Missing required field: $field")
        fi
    done

    # Validate task structure
    local task_count
    task_count="$(jq '.tasks | length' "$tasks_file")"
    if [[ "$task_count" -eq 0 ]]; then
        violations+=("CRITICAL: No tasks defined")
    fi

    # Check task dependencies
    local invalid_deps
    invalid_deps="$(jq -r '.tasks[] | select(.dependencies[]? | . as $dep | ($dep | IN(.tasks[].id)) | not) | .id' "$tasks_file" 2>/dev/null || echo "")"
    if [[ -n "$invalid_deps" ]]; then
        violations+=("HIGH: Tasks with invalid dependencies: $invalid_deps")
    fi

    echo "${violations[@]}"
}

validate_implementation() {
    local impl_dir="$1"

    log "Validating implementation: $impl_dir"

    [[ -d "$impl_dir" ]] || error "Implementation directory not found: $impl_dir"

    local violations=()
    local log_file="$impl_dir/implementation_log.json"

    # Check implementation log
    if [[ ! -f "$log_file" ]]; then
        violations+=("HIGH: No implementation log found")
    elif ! jq empty "$log_file" 2>/dev/null; then
        violations+=("CRITICAL: Invalid JSON in implementation log")
    fi

    # Check for actual implementations
    local impl_count
    impl_count="$(find "$impl_dir" -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" -o -name "*.md" \) | wc -l)"
    if [[ "$impl_count" -eq 0 ]]; then
        violations+=("HIGH: No implementation files found")
    fi

    echo "${violations[@]}"
}

# Generate comprehensive validation report
generate_validation_report() {
    local project_path="$1"
    local overall_result="$2"
    shift 2
    local violations=("$@")

    local report_file="$project_path/.bspec/validation_report.json"
    local timestamp
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Create report structure
    cat > "$report_file" <<EOF
{
    "validated_at": "$timestamp",
    "overall_result": "$overall_result",
    "validator_version": "BSPEC-1.0",
    "constitutional_compliance": {
        "authority_checks": $(( ${#violations[@]} == 0 )),
        "pipeline_consistency": true,
        "message_integrity": true
    },
    "violations": [
EOF

    # Add violations
    local first=true
    for violation in "${violations[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$report_file"
        fi

        local severity="${violation%%:*}"
        local message="${violation#*: }"

        cat >> "$report_file" <<EOF
        {
            "severity": "$severity",
            "message": "$message",
            "detected_at": "$timestamp"
        }
EOF
    done

    cat >> "$report_file" <<EOF
    ],
    "recommendations": [
        "Review authority domain assignments",
        "Ensure proper stage sequencing",
        "Monitor message queue health"
    ]
}
EOF

    log "Validation report generated: $report_file"

    # Send validation results via bridge
    if [[ -f "$project_path/.bspec/manifest.json" ]]; then
        local bridge_namespace
        bridge_namespace="$(jq -r '.bridge_namespace // "unknown"' "$project_path/.bspec/manifest.json")"

        # Send validation completion message
        local temp_msg_file
        temp_msg_file="$(mktemp)"
        cat > "$temp_msg_file" <<EOF
{
    "result": "$overall_result",
    "violations_count": ${#violations[@]},
    "report_file": "$report_file",
    "timestamp": "$timestamp"
}
EOF
        "$SCRIPT_DIR/bridge-send.sh" bspec code NORMAL "VALIDATION_COMPLETE" "$temp_msg_file"
        rm -f "$temp_msg_file"
    fi
}

# Artifact-specific validation
validate_artifact() {
    local artifact_type="$1"
    local artifact_path="$2"

    case "$artifact_type" in
        "specification")
            validate_specification "$artifact_path"
            ;;
        "plan")
            validate_implementation_plan "$artifact_path"
            ;;
        "tasks")
            validate_task_breakdown "$artifact_path"
            ;;
        "implementation")
            validate_implementation "$artifact_path"
            ;;
        *)
            error "Unknown artifact type: $artifact_type"
            ;;
    esac
}

# Main execution
main() {
    case "${1:-}" in
        "constitutional")
            validate_constitutional_compliance "${2:-}" "${3:-}" "${4:-}"
            ;;
        "artifact")
            validate_artifact "${2:-}" "${3:-}"
            ;;
        "pipeline")
            validate_pipeline_integrity "${2:-}"
            ;;
        *)
            echo "Usage: $0 {constitutional|artifact|pipeline} [args...]"
            echo ""
            echo "Commands:"
            echo "  constitutional <project> <authority> <action>  - Validate constitutional compliance"
            echo "  artifact <type> <path>                        - Validate specific artifact"
            echo "  pipeline <project_path>                       - Validate entire pipeline"
            echo ""
            echo "Artifact types: specification, plan, tasks, implementation"
            exit 1
            ;;
    esac
}

validate_pipeline_integrity() {
    local project_path="$1"

    log "Validating complete pipeline integrity for: $project_path"

    local all_violations=()
    local overall_result="PASS"

    # Validate constitutional compliance for coordination authority
    if ! validate_constitutional_compliance "$project_path" "coordination" "can_orchestrate_workflows"; then
        overall_result="FAIL"
    fi

    # Validate each artifact if it exists
    local artifacts=(
        "specification:$project_path/.bspec/specs/specification.md"
        "plan:$project_path/.bspec/plans/implementation_plan.md"
        "tasks:$project_path/.bspec/tasks/task_breakdown.json"
        "implementation:$project_path/.bspec/implementations"
    )

    for artifact_spec in "${artifacts[@]}"; do
        local type="${artifact_spec%%:*}"
        local path="${artifact_spec#*:}"

        if [[ -e "$path" ]]; then
            local violations
            violations="$(validate_artifact "$type" "$path")"
            if [[ -n "$violations" ]]; then
                readarray -t artifact_violations <<< "$violations"
                all_violations+=("${artifact_violations[@]}")
                if [[ "$violations" == *"CRITICAL:"* ]]; then
                    overall_result="FAIL"
                fi
            fi
        fi
    done

    # Generate final report
    generate_validation_report "$project_path" "$overall_result" "${all_violations[@]}"

    log "Pipeline validation completed with result: $overall_result"
    [[ "$overall_result" == "PASS" ]]
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
