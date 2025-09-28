# BSPEC Integration Guide

## Bridge-Specification Pipeline v1.0

*How to adopt specification-driven multi-agent development in any project*

### Quick Start

```bash
# 1. Initialize BSPEC pipeline in your project
cd /path/to/your/project
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh init .

# 2. Create initial specification
echo "Build user authentication system with OAuth2 support" > requirements.txt
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh exec . specify requirements.txt

# 3. Generate implementation plan
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh exec . plan

# 4. Break down into tasks
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh exec . tasks

# 5. Track implementation
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh exec . implement

# 6. Validate results
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh exec . validate
```

### Pipeline Overview

BSPEC enforces constitutional governance through a 5-stage pipeline:

```
specify → plan → tasks → implement → validate
   ↓       ↓       ↓        ↓         ↓
  SPEC → PLAN → TASKS → IMPLS → VALIDATION
```

**Authority Domains:**

- **Specification**: Can define requirements and approve plans
- **Implementation**: Can write code and modify implementations
- **Validation**: Can run tests and approve releases
- **Coordination**: Can manage tasks and orchestrate workflows

### Stage Details

#### 1. Specify Stage (`/specify`)

**Authority**: Specification domain
**Input**: Requirements document or text
**Output**: `.bspec/specs/specification.md`

```bash
# From GitHub spec-kit command
/specify "Build REST API with rate limiting"

# Or directly via BSPEC
./bridge-spec-pipeline.sh exec . specify "Build REST API with rate limiting"
```

**Validation Rules:**

- Must include Requirements section
- Must have Acceptance Criteria with checkboxes
- Must define Technical Constraints
- Minimum 50 words for completeness

#### 2. Plan Stage (`/plan`)

**Authority**: Specification domain
**Input**: Approved specification
**Output**: `.bspec/plans/implementation_plan.md`

**Required Sections:**

- Architecture Overview
- Implementation Phases
- Dependencies
- Risk Assessment

**Validation Rules:**

- Cannot execute until specification is completed
- Must reference source specification
- Minimum 4 heading levels for depth

#### 3. Tasks Stage (`/tasks`)

**Authority**: Coordination domain
**Input**: Approved implementation plan
**Output**: `.bspec/tasks/task_breakdown.json`

**Structure:**

```json
{
    "tasks": [
        {
            "id": "task-001",
            "title": "Setup project structure",
            "description": "Initialize directories and config",
            "priority": "high",
            "estimated_hours": 2,
            "dependencies": [],
            "status": "pending"
        }
    ],
    "total_estimated_hours": 12,
    "critical_path": ["task-001", "task-003"]
}
```

**Validation Rules:**

- Cannot execute until plan is completed
- All task dependencies must reference valid task IDs
- Must define critical path
- Must estimate total hours

#### 4. Implement Stage (`/implement`)

**Authority**: Implementation domain
**Input**: Approved task breakdown
**Output**: `.bspec/implementations/` directory

**Tracking:**

- `implementation_log.json` for progress tracking
- Actual code files and implementations
- Test files and documentation

**Validation Rules:**

- Cannot execute until tasks are defined
- Must create implementation log
- Should include actual implementation files

#### 5. Validate Stage (`/validate`)

**Authority**: Validation domain
**Input**: Completed implementations
**Output**: `.bspec/validations/validation_report.json`

**Checks:**

- Specification compliance
- Implementation quality
- Test coverage
- Documentation completeness

### Constitutional Governance

BSPEC enforces strict authority domain compliance:

```bash
# Validate agent has proper authority for action
./bridge-spec-validate.sh constitutional /path/to/project specification can_define_requirements

# Validate specific artifacts
./bridge-spec-validate.sh artifact specification .bspec/specs/specification.md

# Validate entire pipeline integrity
./bridge-spec-validate.sh pipeline /path/to/project
```

**Violation Severities:**

- **CRITICAL**: Must be fixed before proceeding
- **HIGH**: Should be fixed before proceeding
- **MEDIUM**: Should be addressed
- **LOW**: Optional improvement
- **INFO**: Informational only

### Bridge Integration

BSPEC integrates with the Bridge v3.0 communication system:

**Message Templates:**

```bash
# Specification stage completion
{
    "type": "SPEC_CREATED",
    "stage": "specify",
    "authority": "specification",
    "project": "my-project",
    "artifacts": ["specification.md"],
    "next_stage": "plan"
}

# Implementation request
{
    "type": "IMPLEMENTATION_REQUESTED",
    "stage": "implement",
    "authority": "coordination",
    "assignee": "implementation",
    "tasks_file": "task_breakdown.json"
}
```

**Bridge Commands:**

```bash
# Send completion notification
./bridge-send.sh bspec-myproject coordination NORMAL "Tasks Completed" task_completion.json

# Request validation
./bridge-send.sh bspec-myproject validation HIGH "Validation Request" validation_request.json
```

### Directory Structure

BSPEC creates this standardized structure:

```
your-project/
├── .bspec/
│   ├── manifest.json              # Pipeline state
│   ├── specs/
│   │   └── specification.md       # Requirements & criteria
│   ├── plans/
│   │   └── implementation_plan.md # Architecture & phases
│   ├── tasks/
│   │   └── task_breakdown.json    # Detailed tasks
│   ├── implementations/
│   │   ├── implementation_log.json
│   │   └── [your actual code]
│   └── validations/
│       ├── validation_report.json
│       └── [test results]
├── [your existing project files]
└── CLAUDE.md                      # Updated with BSPEC info
```

### Integration with GitHub Spec-Kit

BSPEC works seamlessly with GitHub's specification tools:

```bash
# GitHub spec-kit command maps to BSPEC stages
/specify → ./bridge-spec-pipeline.sh exec . specify
/plan    → ./bridge-spec-pipeline.sh exec . plan
/tasks   → ./bridge-spec-pipeline.sh exec . tasks
/implement → ./bridge-spec-pipeline.sh exec . implement
```

### Examples

#### Example 1: AAFC Herbarium OCR Pipeline

```bash
cd ~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025

# Initialize BSPEC
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh init .

# Specify OCR requirements
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh exec . specify \
    "Extract Darwin Core data from herbarium specimen images using OCR"

# Generate plan
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh exec . plan

# Check pipeline status
~/devvyn-meta-project/scripts/bridge-spec-pipeline.sh status .
```

#### Example 2: Constitutional Validation

```bash
# Validate implementation authority
~/devvyn-meta-project/scripts/bridge-spec-validate.sh constitutional \
    ~/Documents/GitHub/my-project implementation can_write_code

# Validate specification completeness
~/devvyn-meta-project/scripts/bridge-spec-validate.sh artifact specification \
    ~/Documents/GitHub/my-project/.bspec/specs/specification.md

# Full pipeline integrity check
~/devvyn-meta-project/scripts/bridge-spec-validate.sh pipeline \
    ~/Documents/GitHub/my-project
```

### Best Practices

1. **Always initialize BSPEC before starting specification work**
2. **Complete stages in order** - constitutional validation enforces this
3. **Use bridge messaging** for multi-agent coordination
4. **Validate frequently** using the validation scripts
5. **Document authority domains** clearly in your project

### Troubleshooting

**Pipeline Inconsistency:**

```bash
# Check current pipeline state
./bridge-spec-pipeline.sh status /path/to/project

# Validate pipeline integrity
./bridge-spec-validate.sh pipeline /path/to/project
```

**Authority Violations:**

```bash
# Check what actions your authority domain allows
grep "your_domain:" ~/devvyn-meta-project/scripts/bridge-spec-validate.sh

# Validate specific action
./bridge-spec-validate.sh constitutional /path/to/project your_domain your_action
```

**Bridge Message Issues:**

```bash
# Check bridge registration
~/devvyn-meta-project/scripts/bridge-register.sh status your-agent

# Check pending messages
~/devvyn-meta-project/scripts/bridge-receive.sh your-agent
```

### Advanced Configuration

#### Custom Authority Domains

Edit `bridge-spec-validate.sh` to add custom domains:

```bash
AUTHORITY_DOMAINS=(
    "specification:can_define_requirements,can_approve_plans"
    "implementation:can_write_code,can_modify_implementations"
    "validation:can_run_tests,can_approve_releases"
    "coordination:can_manage_tasks,can_orchestrate_workflows"
    "security:can_audit_code,can_approve_deployments"  # Custom domain
)
```

#### Custom Validation Rules

Add project-specific validation to the validate functions in `bridge-spec-validate.sh`.

#### Bridge Namespace Customization

Override the default namespace pattern in your project's manifest:

```json
{
    "bridge_namespace": "custom-prefix-projectname"
}
```

---

**BSPEC v1.0** provides mathematically-verified, constitutionally-governed specification-driven development. Each stage enforces authority domains and ensures proper progression through the development lifecycle.

For questions or issues, check the [troubleshooting section](#troubleshooting) or validate your pipeline with the provided tools.
