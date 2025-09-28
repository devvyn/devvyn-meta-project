#!/bin/bash
# BRIDGE_SPEC_PIPELINE.sh - BSPEC v1.0 Workflow Automation
# Orchestrates specification-driven development through bridge coordination

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="$(dirname "$SCRIPT_DIR")/bridge"
SPECS_DIR="$(dirname "$SCRIPT_DIR")/specs"

# Source bridge utilities only if functions don't exist
if ! command -v send_bridge_message &> /dev/null; then
    # Use standalone messaging function
    send_bridge_message() {
        "$SCRIPT_DIR/bridge-send.sh" "$@"
    }
fi

# Configuration
AUTHORITY_DOMAINS=("specification" "implementation" "validation" "coordination")
PIPELINE_STAGES=("specify" "plan" "tasks" "implement" "validate")

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BSPEC: $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

# Initialize BSPEC pipeline for a project
init_pipeline() {
    local project_path="$1"
    local project_name
    project_name="$(basename "$project_path")"

    log "Initializing BSPEC pipeline for: $project_name"

    # Create spec directory structure
    mkdir -p "$project_path/.bspec"/{specs,plans,tasks,implementations,validations}

    # Create pipeline manifest
    cat > "$project_path/.bspec/manifest.json" <<EOF
{
    "project": "$project_name",
    "bspec_version": "1.0",
    "pipeline_state": "initialized",
    "stages": {
        "specify": {"status": "pending", "authority": "specification"},
        "plan": {"status": "pending", "authority": "specification"},
        "tasks": {"status": "pending", "authority": "coordination"},
        "implement": {"status": "pending", "authority": "implementation"},
        "validate": {"status": "pending", "authority": "validation"}
    },
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "bridge_namespace": "bspec-$project_name"
}
EOF

    log "Pipeline initialized at: $project_path/.bspec/"
}

# Execute pipeline stage
execute_stage() {
    local project_path="$1"
    local stage="$2"
    local input_spec="$3"

    local manifest_file="$project_path/.bspec/manifest.json"
    [[ -f "$manifest_file" ]] || error "No BSPEC manifest found. Run init_pipeline first."

    local project_name
    project_name="$(jq -r '.project' "$manifest_file")"
    local bridge_namespace
    bridge_namespace="$(jq -r '.bridge_namespace' "$manifest_file")"

    log "Executing stage: $stage for project: $project_name"

    # Validate stage transition
    validate_stage_transition "$manifest_file" "$stage"

    # Execute stage-specific logic
    case "$stage" in
        "specify")
            execute_specify_stage "$project_path" "$input_spec" "$bridge_namespace"
            ;;
        "plan")
            execute_plan_stage "$project_path" "$bridge_namespace"
            ;;
        "tasks")
            execute_tasks_stage "$project_path" "$bridge_namespace"
            ;;
        "implement")
            execute_implement_stage "$project_path" "$bridge_namespace"
            ;;
        "validate")
            execute_validate_stage "$project_path" "$bridge_namespace"
            ;;
        *)
            error "Unknown stage: $stage"
            ;;
    esac

    # Update pipeline state
    update_pipeline_state "$manifest_file" "$stage" "completed"

    log "Stage $stage completed successfully"
}

validate_stage_transition() {
    local manifest_file="$1"
    local target_stage="$2"

    # Implementation of constitutional validation rules
    local current_state
    current_state="$(jq -r '.pipeline_state' "$manifest_file")"

    case "$target_stage" in
        "specify")
            [[ "$current_state" == "initialized" ]] || error "Can only specify from initialized state"
            ;;
        "plan")
            local specify_status
            specify_status="$(jq -r '.stages.specify.status' "$manifest_file")"
            [[ "$specify_status" == "completed" ]] || error "Must complete specify stage first"
            ;;
        "tasks")
            local plan_status
            plan_status="$(jq -r '.stages.plan.status' "$manifest_file")"
            [[ "$plan_status" == "completed" ]] || error "Must complete plan stage first"
            ;;
        "implement")
            local tasks_status
            tasks_status="$(jq -r '.stages.tasks.status' "$manifest_file")"
            [[ "$tasks_status" == "completed" ]] || error "Must complete tasks stage first"
            ;;
        "validate")
            local implement_status
            implement_status="$(jq -r '.stages.implement.status' "$manifest_file")"
            [[ "$implement_status" == "completed" ]] || error "Must complete implement stage first"
            ;;
    esac
}

execute_specify_stage() {
    local project_path="$1"
    local input_spec="$2"
    local bridge_namespace="$3"

    local spec_file="$project_path/.bspec/specs/specification.md"

    # Process input specification
    if [[ -f "$input_spec" ]]; then
        cp "$input_spec" "$spec_file"
    else
        # Create from template
        cat > "$spec_file" <<EOF
# Project Specification

## Requirements
$input_spec

## Acceptance Criteria
- [ ] Requirements are clearly defined
- [ ] Success metrics are established
- [ ] Constraints are documented

## Technical Constraints
<!-- Add any technical limitations or requirements -->

## Success Metrics
<!-- Define how success will be measured -->
EOF
    fi

    # Send bridge message (use bspec agent with project context)
    local temp_msg_file
    temp_msg_file="$(mktemp)"
    cat > "$temp_msg_file" <<EOF
{
    "stage": "specify",
    "project": "$(basename "$project_path")",
    "spec_file": "$spec_file",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    "$SCRIPT_DIR/bridge-send.sh" bspec code NORMAL "SPEC_CREATED" "$temp_msg_file"
    rm -f "$temp_msg_file"
}

execute_plan_stage() {
    local project_path="$1"
    local bridge_namespace="$2"

    local spec_file="$project_path/.bspec/specs/specification.md"
    local plan_file="$project_path/.bspec/plans/implementation_plan.md"

    # Generate implementation plan from specification
    cat > "$plan_file" <<EOF
# Implementation Plan

Generated from: $(basename "$spec_file")
Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Architecture Overview
<!-- High-level system design -->

## Implementation Phases
<!-- Break down into phases -->

## Dependencies
<!-- External dependencies and requirements -->

## Risk Assessment
<!-- Potential risks and mitigation strategies -->
EOF

    # Send bridge message
    local temp_msg_file
    temp_msg_file="$(mktemp)"
    cat > "$temp_msg_file" <<EOF
{
    "stage": "plan",
    "project": "$(basename "$project_path")",
    "plan_file": "$plan_file",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    "$SCRIPT_DIR/bridge-send.sh" bspec code NORMAL "PLAN_CREATED" "$temp_msg_file"
    rm -f "$temp_msg_file"
}

execute_tasks_stage() {
    local project_path="$1"
    local bridge_namespace="$2"

    local plan_file="$project_path/.bspec/plans/implementation_plan.md"
    local tasks_file="$project_path/.bspec/tasks/task_breakdown.json"

    # Generate task breakdown
    cat > "$tasks_file" <<EOF
{
    "generated_from": "$(basename "$plan_file")",
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "tasks": [
        {
            "id": "task-001",
            "title": "Setup project structure",
            "description": "Initialize project directories and configuration files",
            "priority": "high",
            "estimated_hours": 2,
            "dependencies": [],
            "status": "pending"
        }
    ],
    "total_estimated_hours": 2,
    "critical_path": ["task-001"]
}
EOF

    # Send bridge message
    local temp_msg_file
    temp_msg_file="$(mktemp)"
    cat > "$temp_msg_file" <<EOF
{
    "stage": "tasks",
    "project": "$(basename "$project_path")",
    "tasks_file": "$tasks_file",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    "$SCRIPT_DIR/bridge-send.sh" bspec code NORMAL "TASKS_CREATED" "$temp_msg_file"
    rm -f "$temp_msg_file"
}

execute_implement_stage() {
    local project_path="$1"
    local bridge_namespace="$2"

    local tasks_file="$project_path/.bspec/tasks/task_breakdown.json"
    local impl_dir="$project_path/.bspec/implementations"

    # Create implementation tracking
    mkdir -p "$impl_dir"

    cat > "$impl_dir/implementation_log.json" <<EOF
{
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "based_on_tasks": "$(basename "$tasks_file")",
    "implementations": [],
    "status": "in_progress"
}
EOF

    # Send bridge message
    local temp_msg_file
    temp_msg_file="$(mktemp)"
    cat > "$temp_msg_file" <<EOF
{
    "stage": "implement",
    "project": "$(basename "$project_path")",
    "log_file": "$impl_dir/implementation_log.json",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    "$SCRIPT_DIR/bridge-send.sh" bspec code NORMAL "IMPLEMENTATION_STARTED" "$temp_msg_file"
    rm -f "$temp_msg_file"
}

execute_validate_stage() {
    local project_path="$1"
    local bridge_namespace="$2"

    local validation_dir="$project_path/.bspec/validations"
    mkdir -p "$validation_dir"

    local validation_report="$validation_dir/validation_report.json"

    cat > "$validation_report" <<EOF
{
    "validated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "validation_type": "automated",
    "checks": {
        "specification_compliance": {"status": "pending"},
        "implementation_quality": {"status": "pending"},
        "test_coverage": {"status": "pending"},
        "documentation": {"status": "pending"}
    },
    "overall_status": "pending"
}
EOF

    # Send bridge message
    local temp_msg_file
    temp_msg_file="$(mktemp)"
    cat > "$temp_msg_file" <<EOF
{
    "stage": "validate",
    "project": "$(basename "$project_path")",
    "report_file": "$validation_report",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    "$SCRIPT_DIR/bridge-send.sh" bspec code NORMAL "VALIDATION_STARTED" "$temp_msg_file"
    rm -f "$temp_msg_file"
}

update_pipeline_state() {
    local manifest_file="$1"
    local stage="$2"
    local status="$3"

    local temp_file
    temp_file="$(mktemp)"

    jq ".stages.$stage.status = \"$status\" | .stages.$stage.completed_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" \
        "$manifest_file" > "$temp_file"

    mv "$temp_file" "$manifest_file"
}

# Main execution
main() {
    case "${1:-}" in
        "init")
            init_pipeline "${2:-}"
            ;;
        "exec")
            execute_stage "${2:-}" "${3:-}" "${4:-}"
            ;;
        "status")
            show_pipeline_status "${2:-}"
            ;;
        *)
            echo "Usage: $0 {init|exec|status} [project_path] [stage] [input_spec]"
            echo ""
            echo "Commands:"
            echo "  init <project_path>                    - Initialize BSPEC pipeline"
            echo "  exec <project_path> <stage> [input]   - Execute pipeline stage"
            echo "  status <project_path>                 - Show pipeline status"
            echo ""
            echo "Stages: specify, plan, tasks, implement, validate"
            exit 1
            ;;
    esac
}

show_pipeline_status() {
    local project_path="$1"
    local manifest_file="$project_path/.bspec/manifest.json"

    [[ -f "$manifest_file" ]] || error "No BSPEC manifest found"

    echo "BSPEC Pipeline Status:"
    jq -r '
        "Project: " + .project + "\n" +
        "State: " + .pipeline_state + "\n" +
        "Stages:" + "\n" +
        (.stages | to_entries[] | "  " + .key + ": " + .value.status)
    ' "$manifest_file"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
