# System Customization Guide

**Status**: Configuration Documentation
**Version**: 1.0
**Purpose**: Complete guide to customizing the coordination system for your needs
**Audience**: System adopters, forkers, domain-specific adapters

---

## Overview

The devvyn-meta-project coordination system is designed for customization at multiple layers. This guide documents **every configuration point** where you can adapt the system without breaking core guarantees.

**Philosophy**: Universal patterns (from `universal-patterns.md`) remain constant. Everything else is configurable.

---

## Configuration Layers

```
Layer 1: Agent Configuration (WHO)
  ├─ Agent roles and specializations
  ├─ Authority domains
  └─ Capabilities

Layer 2: Protocol Configuration (WHAT)
  ├─ Message priorities
  ├─ Event types
  └─ Queue thresholds

Layer 3: Tool Configuration (HOW)
  ├─ Command preferences
  ├─ Platform-specific tools
  └─ Output routing

Layer 4: Infrastructure Configuration (WHERE)
  ├─ Directory paths
  ├─ Storage backends
  └─ Scheduling (LaunchAgents/cron)

Layer 5: Domain Configuration (WHY)
  ├─ Workflow patterns
  ├─ Validation rules
  └─ Quality gates
```

---

## Layer 1: Agent Configuration

### 1.1 Agent Registry (`bridge/registry/agents.json`)

**Purpose**: Define which agents exist and their capabilities.

#### Schema

```json
{
  "registry_version": "3.0",
  "last_updated": "ISO8601 timestamp",
  "active_agents": {
    "agent-name": {
      "agent_type": "string",
      "namespace": "prefix-",
      "status": "active|inactive|maintenance",
      "capabilities": ["capability1", "capability2"],
      "authority_domains": ["domain1", "domain2"],
      "inbox_path": "bridge/inbox/agent-name/",
      "outbox_path": "bridge/outbox/agent-name/",
      "last_seen": "ISO8601 timestamp",
      "session_id": "session-identifier"
    }
  },
  "coordination_protocols": {
    "message_id_format": "[timestamp]-[sender]-[uuid]",
    "namespace_format": "[agent]-[timestamp]-[uuid].md",
    "queue_processing": "fifo|priority|weighted",
    "atomic_operations": true,
    "collision_prevention": "namespace_isolation"
  }
}
```

#### Customization Points

**1. Agent Roles** - Define your team's specializations

```json
// Default (Devvyn's setup)
{
  "chat": {
    "agent_type": "claude_chat",
    "authority_domains": ["strategic_planning", "framework_evolution"]
  },
  "code": {
    "agent_type": "claude_code",
    "authority_domains": ["technical_implementation", "system_architecture"]
  }
}

// Example: Research Lab Adaptation
{
  "researcher": {
    "agent_type": "claude_sonnet",
    "authority_domains": ["literature_review", "hypothesis_generation"]
  },
  "statistician": {
    "agent_type": "claude_code",
    "authority_domains": ["data_analysis", "statistical_validation"]
  },
  "writer": {
    "agent_type": "claude_opus",
    "authority_domains": ["manuscript_drafting", "paper_revision"]
  }
}

// Example: Software Team Adaptation
{
  "architect": {
    "agent_type": "claude_opus",
    "authority_domains": ["system_design", "technology_selection"]
  },
  "backend-dev": {
    "agent_type": "claude_code",
    "authority_domains": ["api_implementation", "database_design"]
  },
  "frontend-dev": {
    "agent_type": "claude_code",
    "authority_domains": ["ui_implementation", "component_design"]
  },
  "qa": {
    "agent_type": "claude_sonnet",
    "authority_domains": ["test_planning", "quality_assurance"]
  }
}
```

**2. Capabilities** - What each agent can do

```json
// Technical Agent
{
  "capabilities": [
    "technical_implementation",
    "code_optimization",
    "pattern_recognition",
    "system_architecture",
    "testing_and_validation",
    "tool_execution",
    "file_operations",
    "formal_verification"
  ]
}

// Research Agent
{
  "capabilities": [
    "literature_search",
    "citation_management",
    "hypothesis_testing",
    "data_visualization",
    "statistical_analysis",
    "manuscript_writing",
    "peer_review"
  ]
}

// Content Agent
{
  "capabilities": [
    "content_strategy",
    "copywriting",
    "seo_optimization",
    "social_media",
    "video_scripting",
    "brand_voice",
    "audience_analysis"
  ]
}
```

**3. Authority Domains** - Decision boundaries

```json
// Define clear authority boundaries
{
  "authority_domains": {
    "strategic": ["chat", "architect"],
    "technical": ["code", "backend-dev", "frontend-dev"],
    "quality": ["qa", "code-review-agent"],
    "final": ["human"]
  },

  // Authority validation rules
  "authority_rules": {
    "strategic_requires_approval": ["human"],
    "technical_autonomous": true,
    "quality_blocks_release": true
  }
}
```

### 1.2 Agent Authority Matrix

**File**: Create `bridge/config/authority-matrix.yaml`

```yaml
# Authority Matrix: Who can do what?

domains:
  strategic_planning:
    primary: chat
    can_propose: [code, investigator]
    requires_approval: human
    urgency_threshold: HIGH

  technical_implementation:
    primary: code
    can_propose: [chat]
    autonomous: true
    urgency_threshold: NORMAL

  pattern_detection:
    primary: investigator
    escalates_to: code
    autonomous_threshold: 90  # confidence percentage

  routine_decisions:
    primary: hopper
    constraints:
      max_priority: NORMAL
      escalate_if_novel: true
      pattern_confidence_min: 90

  final_authority:
    primary: human
    override_any: true
    required_for:
      - constitutional_changes
      - strategic_pivots
      - external_commitments
      - budget_decisions
```

### 1.3 Adding New Agents

**Step-by-Step**:

1. Register agent in `agents.json`
2. Create inbox directory: `mkdir -p bridge/inbox/new-agent`
3. Create outbox directory: `mkdir -p bridge/outbox/new-agent`
4. Define authority domain in `authority-matrix.yaml`
5. Update TLA+ specification if needed
6. Test with `bridge-register.sh register new-agent`

**Example**: Adding a "data-analyst" agent

```bash
# 1. Add to agents.json
jq '.active_agents["data-analyst"] = {
  "agent_type": "claude_sonnet",
  "namespace": "data-analyst-",
  "status": "active",
  "capabilities": ["statistical_analysis", "data_visualization", "report_generation"],
  "authority_domains": ["data_analysis", "statistical_validation"],
  "inbox_path": "bridge/inbox/data-analyst/",
  "outbox_path": "bridge/outbox/data-analyst/"
}' bridge/registry/agents.json > temp && mv temp bridge/registry/agents.json

# 2. Create directories
mkdir -p ~/infrastructure/agent-bridge/bridge/inbox/data-analyst
mkdir -p ~/infrastructure/agent-bridge/bridge/outbox/data-analyst

# 3. Register
~/devvyn-meta-project/scripts/bridge-register.sh register data-analyst

# 4. Test send
~/devvyn-meta-project/scripts/bridge-send.sh code data-analyst NORMAL "Test Message" /tmp/test.md
```

---

## Layer 2: Protocol Configuration

### 2.1 Message Priorities

**File**: `bridge/config/priorities.yaml` (create this file)

```yaml
# Message Priority System
# Customize levels, thresholds, and routing

priority_levels:
  CRITICAL:
    numeric_value: 0
    description: "System failures, blocking issues, immediate threats"
    sla_hours: 1
    routes_to: [human]
    escalation_after_minutes: 15
    notifications:
      - type: desktop
      - type: email
      - type: bridge_message

  HIGH:
    numeric_value: 1
    description: "Important but not breaking, significant features"
    sla_hours: 4
    routes_to: [specialized_agent, human_if_no_response]
    escalation_after_minutes: 60
    notifications:
      - type: bridge_message

  NORMAL:
    numeric_value: 2
    description: "Standard work, routine improvements"
    sla_hours: 24
    routes_to: [specialized_agent]
    escalation_after_minutes: 480  # 8 hours
    notifications:
      - type: bridge_message

  INFO:
    numeric_value: 3
    description: "FYI, context updates, no action required"
    sla_hours: null
    routes_to: [specialized_agent, defer_queue_if_busy]
    escalation_after_minutes: null
    notifications:
      - type: inbox_delivery_only

# Customization Examples

# 3-tier system (simpler)
three_tier:
  URGENT: "Immediate action required"
  NORMAL: "Standard priority"
  LOW: "Nice to have"

# 5-tier system (more granular)
five_tier:
  P0: "Service outage, data loss"
  P1: "Major feature broken"
  P2: "Minor feature issues"
  P3: "Improvements"
  P4: "Nice to have"

# Domain-specific priorities
scientific_research:
  DEADLINE_CRITICAL: "Funding proposal due, conference submission"
  REVIEWER_REQUESTED: "Peer review turnaround"
  EXPERIMENTAL: "Lab work scheduling"
  LITERATURE: "Background reading"

software_development:
  HOTFIX: "Production bug"
  FEATURE: "Sprint commitment"
  TECH_DEBT: "Refactoring"
  DOCUMENTATION: "Update docs"
```

### 2.2 Event Types

**File**: `bridge/config/event-types.yaml` (create this file)

```yaml
# Event Type Configuration
# Define what types of events your system tracks

event_types:
  decision:
    schema:
      required: [title, rationale, participants, date]
      optional: [alternatives_considered, impact_assessment]
    retention_days: 3650  # 10 years
    importance: HIGH

  pattern:
    schema:
      required: [pattern_name, problem, solution, evidence]
      optional: [alternatives, limitations, applicability]
    retention_days: 1825  # 5 years
    importance: MEDIUM

  state-change:
    schema:
      required: [from_state, to_state, trigger, timestamp]
      optional: [reason, impact]
    retention_days: 365
    importance: MEDIUM

  agent-registration:
    schema:
      required: [agent_name, session_id, timestamp]
      optional: [capabilities, authority_domains]
    retention_days: 90
    importance: LOW

  message-sent:
    schema:
      required: [message_id, sender, recipient, priority]
      optional: [content_hash, related_to]
    retention_days: 365
    importance: LOW

# Domain-specific event types

research_lab:
  experiment-completed:
    schema:
      required: [experiment_id, results, p_value, timestamp]
      optional: [methodology, notes, next_steps]
    retention_days: 3650  # Long-term research data

  hypothesis-generated:
    schema:
      required: [hypothesis, supporting_evidence, testability]
      optional: [literature_basis, methodology]
    retention_days: 1825

software_team:
  feature-shipped:
    schema:
      required: [feature_name, version, release_date, git_commit]
      optional: [breaking_changes, migration_guide]
    retention_days: 1825

  incident-occurred:
    schema:
      required: [severity, impact, detection_time, resolution_time]
      optional: [root_cause, prevention_plan]
    retention_days: 1825
```

### 2.3 Queue Configuration

**File**: `bridge/config/queue-settings.yaml` (create this file)

```yaml
# Queue Processing Configuration

queue:
  processing_mode: priority_fifo  # priority_fifo | weighted | strict_fifo

  # Depth thresholds
  thresholds:
    warning: 10
    critical: 50
    max: 100

  # Processing rates
  rates:
    messages_per_minute: 20
    batch_size: 5

  # Retry policies
  retry:
    max_attempts: 3
    backoff_strategy: exponential  # exponential | linear | constant
    base_delay_seconds: 5

  # Archive policies
  archive:
    after_days: 30
    compress: true
    retention_years: 2

# Defer Queue Configuration
defer_queue:
  enabled: true

  categories:
    strategic:
      review_interval_days: 7
      max_age_days: 90

    tactical:
      review_interval_days: 30
      max_age_days: 180

    conditional:
      check_triggers_hours: 6
      max_age_days: 365

  # Triggers
  triggers:
    project_started: "check when .git directory created"
    budget_approved: "check funding documents"
    milestone_reached: "check project progress"
```

---

## Layer 3: Tool Configuration

### 3.1 CLAUDE.md Files (AI Agent Instructions)

**Three Levels**:

1. **Global** (`~/.claude/CLAUDE.md`) - Applies to all projects
2. **Router** (`~/CLAUDE.md`) - Directs to project-specific config
3. **Project** (`~/project-name/CLAUDE.md`) - Project-specific rules

#### Global Configuration Template

**File**: `~/.claude/CLAUDE.md`

```markdown
# Agent Global Rules

## Tools
- Python packages: `uv` | `pip` | `conda`
- File search: `fd` | `find`
- Text search: `rg` | `grep` | `ag`
- JSON processing: `jq` | `python -m json.tool`

## Output Routing
Response > 24 lines → `~/scripts/markdown-to-browser.sh`

## Platform
- OS: macOS | Linux | Windows
- Shell: zsh | bash | fish
- Terminal: iTerm2 | Alacritty | Terminal.app

## Preferences
- Code style: Black (Python) | Prettier (JS) | gofmt (Go)
- Commit style: Conventional Commits
- Documentation: Markdown with examples
```

#### Project Configuration Template

**File**: `~/project-name/CLAUDE.md`

```markdown
# Project: [Your Project Name]

## Context
[Brief description of what this project does]

## Agent Roles
- **Chat**: Strategic planning, architecture decisions
- **Code**: Implementation, testing, debugging
- **[Custom]**: [Your custom agent role]

## Startup Protocol (Code Agent)
```bash
# Run at session start
~/project/scripts/bridge-register.sh register code
~/project/scripts/bridge-receive.sh code
ls ~/infrastructure/agent-bridge/bridge/inbox/code/
```

## Invariants

```tla
\* Define your project-specific invariants
ProjectInvariant ==
  /\ TestsCoverageMet (> 80%)
  /\ DocumentationComplete
  /\ NoHardcodedSecrets
```

## Tools & Scripts

- `./scripts/build.sh` - Build project
- `./scripts/test.sh` - Run tests
- `./scripts/deploy.sh` - Deploy to environment

## Quality Gates

- [ ] All tests pass
- [ ] Documentation updated
- [ ] Code reviewed
- [ ] Performance benchmarks met

```

### 3.2 Tool Preferences Configuration

**File**: `bridge/config/tool-preferences.yaml`

```yaml
# Tool Preferences
# Define which tools to use for common operations

tools:
  file_search:
    preferred: fd
    fallback: find
    flags:
      fd: "--type f --hidden --follow"
      find: "-type f -not -path '*/\.*'"

  text_search:
    preferred: rg
    fallback: grep
    flags:
      rg: "--color=never --no-heading --with-filename"
      grep: "-r -n"

  json_processing:
    preferred: jq
    fallback: python
    python_command: "python3 -m json.tool"

  package_management:
    python: uv
    node: pnpm
    ruby: bundler

  version_control:
    git_commit_template: ".gitmessage"
    branch_naming: "feature/description" | "fix/description"

# Platform-Specific Overrides
platform_overrides:
  macos:
    date_command: "date -Iseconds"
    find_command: "/usr/bin/find"  # BSD find

  linux:
    date_command: "date --iso-8601=seconds"
    find_command: "find"  # GNU find

  windows:
    shell: "powershell"
    find_command: "Get-ChildItem -Recurse"
```

---

## Layer 4: Infrastructure Configuration

### 4.1 Directory Paths

**File**: `bridge/config/paths.yaml`

```yaml
# Path Configuration
# Customize where things are stored

paths:
  # Bridge root (canonical location)
  bridge_root: "~/infrastructure/agent-bridge/bridge"

  # Alternative for development/testing
  dev_bridge_root: "~/devvyn-meta-project/bridge"

  # Agent inboxes
  inbox_pattern: "${bridge_root}/inbox/${agent_name}/"
  outbox_pattern: "${bridge_root}/outbox/${agent_name}/"

  # Queue directories
  queue_pending: "${bridge_root}/queue/pending"
  queue_processing: "${bridge_root}/queue/processing"
  queue_archived: "${bridge_root}/queue/archived"

  # Event log
  events_dir: "${bridge_root}/events"
  events_archive: "${bridge_root}/events/archive"

  # Content DAG
  dag_objects: "${bridge_root}/.dag/objects"
  dag_nodes: "${bridge_root}/.dag/nodes"

  # Registry
  registry_dir: "${bridge_root}/registry"
  agents_json: "${registry_dir}/agents.json"
  queue_stats_json: "${registry_dir}/queue_stats.json"

  # Defer queue
  defer_queue_root: "${bridge_root}/defer-queue"
  defer_strategic: "${defer_queue_root}/strategic"
  defer_tactical: "${defer_queue_root}/tactical"
  defer_conditional: "${defer_queue_root}/conditional"

  # Logs
  logs_dir: "~/devvyn-meta-project/logs"
  wrapper_errors: "${logs_dir}/*-wrapper-errors.log"

  # Human inbox
  human_inbox: "~/inbox"
  human_desktop: "~/Desktop"

# Migration paths (for multi-user or distributed setups)
migration:
  from: filesystem
  to: database
  database_url: "postgresql://localhost/bridge"
  # or
  # to: redis
  # redis_url: "redis://localhost:6379/0"
```

### 4.2 LaunchAgents / Cron Configuration

#### macOS LaunchAgents

**File**: `~/Library/LaunchAgents/com.yourproject.bridge-queue.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yourproject.bridge-queue</string>

    <key>ProgramArguments</key>
    <array>
        <string>/path/to/scripts/bridge-process-queue-wrapper.sh</string>
    </array>

    <!-- Schedule: Every N minutes -->
    <key>StartInterval</key>
    <integer>300</integer>  <!-- 5 minutes, customize: 60=1min, 300=5min, 3600=1hr -->

    <key>RunAtLoad</key>
    <true/>

    <key>StandardErrorPath</key>
    <string>/path/to/logs/bridge-queue-errors.log</string>

    <key>StandardOutPath</key>
    <string>/path/to/logs/bridge-queue-output.log</string>
</dict>
</plist>
```

**Customization**:

```bash
# Change interval
# 1 minute: <integer>60</integer>
# 5 minutes: <integer>300</integer>
# 15 minutes: <integer>900</integer>
# 1 hour: <integer>3600</integer>
# 6 hours: <integer>21600</integer>

# Load agent
launchctl load ~/Library/LaunchAgents/com.yourproject.bridge-queue.plist

# Unload agent
launchctl unload ~/Library/LaunchAgents/com.yourproject.bridge-queue.plist

# Check status
launchctl list | grep yourproject
```

#### Linux systemd Timers

**File**: `~/.config/systemd/user/bridge-queue.service`

```ini
[Unit]
Description=Bridge Queue Processor
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/scripts/bridge-process-queue-wrapper.sh
StandardOutput=append:/path/to/logs/bridge-queue-output.log
StandardError=append:/path/to/logs/bridge-queue-errors.log

[Install]
WantedBy=default.target
```

**File**: `~/.config/systemd/user/bridge-queue.timer`

```ini
[Unit]
Description=Bridge Queue Processing Timer
Requires=bridge-queue.service

[Timer]
# Run every 5 minutes
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
```

**Activation**:

```bash
# Reload systemd
systemctl --user daemon-reload

# Enable timer
systemctl --user enable bridge-queue.timer

# Start timer
systemctl --user start bridge-queue.timer

# Check status
systemctl --user status bridge-queue.timer

# View logs
journalctl --user -u bridge-queue.service -f
```

---

## Layer 5: Domain Configuration

### 5.1 Workflow Patterns

**File**: `domain-config/workflows.yaml`

```yaml
# Domain-Specific Workflows

workflows:
  herbarium_digitization:
    stages:
      - name: image_capture
        agent: human
        outputs: [raw_images]

      - name: ocr_processing
        agent: code
        inputs: [raw_images]
        outputs: [extracted_text]
        validation: text_quality_check

      - name: specimen_extraction
        agent: code
        inputs: [extracted_text]
        outputs: [structured_data]
        validation: field_completeness

      - name: scientific_validation
        agent: domain_expert
        inputs: [structured_data]
        outputs: [validated_specimens]
        quality_gate: true

      - name: publication
        agent: code
        inputs: [validated_specimens]
        outputs: [public_dataset]
        provenance: git_commit_tracking

  software_feature_development:
    stages:
      - name: specification
        agent: architect
        outputs: [feature_spec]

      - name: design_review
        agent: team
        inputs: [feature_spec]
        outputs: [approved_design]
        quality_gate: true

      - name: implementation
        agent: developer
        inputs: [approved_design]
        outputs: [code, tests]

      - name: code_review
        agent: senior_dev
        inputs: [code, tests]
        outputs: [approved_code]
        quality_gate: true

      - name: qa_testing
        agent: qa
        inputs: [approved_code]
        outputs: [test_results]
        quality_gate: true

      - name: deployment
        agent: devops
        inputs: [approved_code, test_results]
        outputs: [deployed_feature]

  research_paper:
    stages:
      - name: literature_review
        agent: researcher
        outputs: [citations, research_gaps]

      - name: hypothesis_generation
        agent: researcher
        inputs: [research_gaps]
        outputs: [hypotheses]

      - name: experiment_design
        agent: statistician
        inputs: [hypotheses]
        outputs: [study_protocol]

      - name: data_collection
        agent: human
        inputs: [study_protocol]
        outputs: [raw_data]

      - name: statistical_analysis
        agent: statistician
        inputs: [raw_data]
        outputs: [results, p_values]

      - name: manuscript_writing
        agent: writer
        inputs: [results, citations]
        outputs: [draft_manuscript]

      - name: peer_review
        agent: senior_researcher
        inputs: [draft_manuscript]
        outputs: [reviewed_manuscript]
        quality_gate: true

      - name: submission
        agent: human
        inputs: [reviewed_manuscript]
        outputs: [submitted_paper]
```

### 5.2 Quality Gates

**File**: `domain-config/quality-gates.yaml`

```yaml
# Quality Gates Configuration

quality_gates:
  code_quality:
    checks:
      - name: tests_pass
        command: "./scripts/test.sh"
        required: true

      - name: coverage_threshold
        command: "coverage report --fail-under=80"
        required: true

      - name: linting
        command: "flake8 ."
        required: false
        warning_only: true

      - name: type_checking
        command: "mypy ."
        required: false

    failure_action: block_merge

  scientific_validation:
    checks:
      - name: field_completeness
        threshold: 95
        required_fields: [species, location, date, collector]

      - name: taxonomy_validation
        authority: GBIF
        confidence_min: 90

      - name: geographic_validation
        bounds_check: true
        coordinate_system: WGS84

    failure_action: escalate_to_human

  manuscript_quality:
    checks:
      - name: citation_completeness
        all_references_cited: true
        all_citations_referenced: true

      - name: statistical_rigor
        p_values_reported: true
        effect_sizes_reported: true
        confidence_intervals: true

      - name: reproducibility
        data_availability_statement: true
        code_availability_statement: true
        protocol_documented: true

    failure_action: request_revision
```

### 5.3 Validation Rules

**File**: `domain-config/validation-rules.yaml`

```yaml
# Domain-Specific Validation Rules

validation_rules:
  herbarium_specimen:
    required_fields:
      - scientific_name
      - collection_date
      - collector
      - location
      - specimen_id

    field_validation:
      scientific_name:
        pattern: "^[A-Z][a-z]+ [a-z]+( [a-z]+)?$"
        example: "Quercus alba"

      collection_date:
        format: "YYYY-MM-DD"
        range: [1800-01-01, today]

      location:
        format: "lat,lon"
        bounds: [-90, 90, -180, 180]

    business_rules:
      - if collection_date > 2000: require(gps_coordinates)
      - if endangered_species: require(permit_number)
      - if invasive_species: flag_for_review

  software_commit:
    required_fields:
      - commit_message
      - author
      - timestamp
      - changed_files

    commit_message_format:
      pattern: "^(feat|fix|docs|style|refactor|test|chore)(\\([a-z]+\\))?: .+"
      examples:
        - "feat(auth): add OAuth2 support"
        - "fix: resolve memory leak in parser"
        - "docs: update API documentation"

    business_rules:
      - if changed_files.includes("*.py"): require(tests_updated)
      - if changed_files.includes("api/*"): require(docs_updated)
      - if breaking_change: require(migration_guide)

  research_data:
    required_fields:
      - dataset_name
      - methodology
      - sample_size
      - variables
      - collection_period

    quality_checks:
      sample_size:
        minimum: 30
        power_analysis_required: true

      missing_data:
        max_percentage: 10
        imputation_method_documented: true

      outliers:
        detection_method: "IQR"
        handling_documented: true

    business_rules:
      - if human_subjects: require(ethics_approval)
      - if animal_research: require(iacuc_approval)
      - if sensitive_data: require(data_protection_plan)
```

---

## Configuration Best Practices

### 1. Version Control Your Configuration

```bash
# Track configuration files in git
git add bridge/config/
git commit -m "config: add quality gates for herbarium workflow"
```

### 2. Environment-Specific Configs

```yaml
# config/environments.yaml

environments:
  development:
    bridge_root: "~/devvyn-meta-project/bridge"
    log_level: DEBUG
    retry_attempts: 1

  staging:
    bridge_root: "~/infrastructure/agent-bridge/bridge"
    log_level: INFO
    retry_attempts: 2

  production:
    bridge_root: "/var/lib/bridge"
    log_level: WARNING
    retry_attempts: 3
```

### 3. Configuration Validation

```bash
# scripts/validate-config.sh
#!/bin/bash

# Validate agents.json schema
jq empty bridge/registry/agents.json || exit 1

# Check required directories exist
for dir in inbox outbox queue events; do
    if [ ! -d "bridge/$dir" ]; then
        echo "Missing directory: bridge/$dir"
        exit 1
    fi
done

# Validate authority matrix
python3 scripts/validate-authority.py

echo "✅ Configuration valid"
```

### 4. Configuration Documentation

Always document **why** you made configuration choices:

```yaml
# config/decisions.yaml

decision_log:
  - date: 2025-10-30
    decision: "Set queue depth warning threshold to 10"
    rationale: "Based on observed processing rate of 20 msgs/min, 10 messages = 30s queue time, acceptable latency"
    alternatives_considered:
      - 5 (too sensitive, frequent false alarms)
      - 20 (too lenient, latency spikes)
```

---

## Migration Guide: Customizing Existing System

### Step 1: Identify Your Use Case

- [ ] Individual vs. team
- [ ] Domain (research, software, content, other)
- [ ] Scale (messages per day, agents count)
- [ ] Platform (macOS, Linux, Windows)

### Step 2: Customize Agent Roles

1. Copy `bridge/registry/agents.json` to `agents.json.backup`
2. Edit `active_agents` section with your roles
3. Define authority domains
4. Test with `bridge-register.sh list`

### Step 3: Adapt Message Priorities

1. Create `bridge/config/priorities.yaml`
2. Define your priority levels
3. Update scripts to use new priorities
4. Test with priority-sorted queue processing

### Step 4: Configure Tools

1. Create `~/.claude/CLAUDE.md` with your tool preferences
2. Create project-specific `CLAUDE.md`
3. Test tool availability: `which fd rg jq`

### Step 5: Set Up Automation

1. **macOS**: Create LaunchAgents plists
2. **Linux**: Create systemd timers
3. **Windows**: Create Task Scheduler jobs
4. Test: Watch logs for automated processing

### Step 6: Define Quality Gates

1. Create `domain-config/quality-gates.yaml`
2. Implement validation scripts
3. Integrate into workflow
4. Test failure scenarios

### Step 7: Validate Complete System

```bash
# Run validation suite
./scripts/validate-config.sh
./scripts/system-health-check.sh

# Test message flow
./scripts/bridge-send.sh test-sender test-recipient NORMAL "Test" /tmp/test.md
./scripts/bridge-receive.sh test-recipient

# Check automation
launchctl list | grep yourproject  # macOS
systemctl --user list-timers      # Linux
```

---

## Configuration Files Summary

```
Project Root/
├── bridge/
│   ├── config/
│   │   ├── priorities.yaml              # Message priority levels
│   │   ├── event-types.yaml             # Event type definitions
│   │   ├── queue-settings.yaml          # Queue processing config
│   │   ├── tool-preferences.yaml        # Tool selection preferences
│   │   ├── paths.yaml                   # Directory path configuration
│   │   └── authority-matrix.yaml        # Agent authority rules
│   └── registry/
│       ├── agents.json                  # Agent registration
│       └── queue_stats.json             # Runtime statistics
│
├── domain-config/
│   ├── workflows.yaml                   # Domain-specific workflows
│   ├── quality-gates.yaml               # Quality gate definitions
│   ├── validation-rules.yaml            # Validation rules
│   └── decisions.yaml                   # Configuration decision log
│
├── ~/.claude/
│   └── CLAUDE.md                        # Global AI agent instructions
│
├── ~/Library/LaunchAgents/              # macOS automation
│   ├── com.project.bridge-queue.plist
│   ├── com.project.investigator.plist
│   └── ...
│
└── ~/.config/systemd/user/              # Linux automation
    ├── bridge-queue.service
    ├── bridge-queue.timer
    └── ...
```

---

## Next Steps

1. **Read**: `universal-patterns.md` (understand what stays constant)
2. **Configure**: Customize agent roles for your domain
3. **Test**: Validate configuration with test messages
4. **Automate**: Set up LaunchAgents/cron for background processing
5. **Monitor**: Use `system-health-check.sh` to verify operation

**Support**: For questions about configuration, consult:

- `docs/platform/dependency-matrix.md` (platform-specific details)
- `docs/branching/domain-transfer-cookbook.md` (domain adaptation examples)
- `COORDINATION_PROTOCOL.md` (protocol specifications)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Maintained By**: CODE agent
**Status**: Living document (update as system evolves)
