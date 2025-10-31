#!/usr/bin/env python3
"""
Migration Assistant for Coordination System

Analyzes existing systems and generates migration plans to coordination system.

Usage:
    ./coord-migrate.py [--path PATH] [--output REPORT.md]

Features:
- Detect existing coordination patterns
- Analyze migration complexity
- Generate step-by-step migration plan
- Risk assessment
- Rollback strategy
"""

import json
import os
import re
import sys
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

try:
    from rich import print as rprint
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table

    HAS_RICH = True
except ImportError:
    HAS_RICH = False

    def rprint(*args, **kwargs):
        print(*args)


@dataclass
class DetectionResult:
    """Results from detecting existing patterns"""

    # Existing infrastructure
    has_message_system: bool
    message_system_type: str  # file-based, database, api, none
    has_event_log: bool
    has_inbox_structure: bool
    has_agent_config: bool

    # Scale indicators
    estimated_users: int
    estimated_messages_per_day: int
    estimated_scale: str  # individual, team, organization, enterprise

    # Platform
    platform: str  # macos, linux, windows

    # Existing patterns
    existing_patterns: list[str]  # Which of the 8 universal patterns exist

    # Gaps
    gaps: list[str]  # What's missing


@dataclass
class MigrationComplexity:
    """Migration complexity assessment"""

    complexity_level: str  # simple, moderate, complex, very_complex
    estimated_hours: int  # Total effort
    risk_level: str  # low, medium, high
    breaking_changes: list[str]
    data_migration_required: bool


@dataclass
class MigrationPlan:
    """Complete migration plan"""

    detection: DetectionResult
    complexity: MigrationComplexity
    steps: list[dict[str, Any]]  # Ordered migration steps
    rollback_strategy: str
    testing_strategy: str
    estimated_timeline: str


class SystemDetector:
    """Detects existing coordination patterns in a directory"""

    def __init__(self, path: str):
        self.path = Path(path)
        self.console = Console() if HAS_RICH else None

    def detect(self) -> DetectionResult:
        """Scan directory and detect existing patterns"""

        self.print_header("Detecting Existing System")

        # Check for message systems
        has_message_system, message_type = self._detect_message_system()
        has_event_log = self._detect_event_log()
        has_inbox = self._detect_inbox_structure()
        has_config = self._detect_agent_config()

        # Estimate scale
        users = self._estimate_users()
        messages = self._estimate_messages_per_day()
        scale = self._determine_scale(users, messages)

        # Detect platform
        platform = self._detect_platform()

        # Check which patterns exist
        patterns = self._detect_patterns()

        # Identify gaps
        gaps = self._identify_gaps(patterns)

        result = DetectionResult(
            has_message_system=has_message_system,
            message_system_type=message_type,
            has_event_log=has_event_log,
            has_inbox_structure=has_inbox,
            has_agent_config=has_config,
            estimated_users=users,
            estimated_messages_per_day=messages,
            estimated_scale=scale,
            platform=platform,
            existing_patterns=patterns,
            gaps=gaps,
        )

        self._print_detection_results(result)
        return result

    def _detect_message_system(self) -> tuple[bool, str]:
        """Detect if message system exists and what type"""

        # Check for file-based
        if (self.path / "inbox").exists() or (self.path / "messages").exists():
            return True, "file-based"

        # Check for database config
        if (self.path / "config.yaml").exists():
            try:
                import yaml

                with open(self.path / "config.yaml") as f:
                    config = yaml.safe_load(f)
                    if "database" in config:
                        return True, "database"
            except Exception:
                pass

        # Check for API endpoints
        if (self.path / "api").exists() or (self.path / "server.py").exists():
            return True, "api"

        return False, "none"

    def _detect_event_log(self) -> bool:
        """Check for event sourcing log"""
        return (
            (self.path / "events.log").exists()
            or (self.path / "event_log").is_dir()
            or (self.path / "events").is_dir()
        )

    def _detect_inbox_structure(self) -> bool:
        """Check for inbox directory structure"""
        inbox = self.path / "inbox"
        if not inbox.exists():
            return False

        # Check if has subdirectories (agent inboxes)
        subdirs = [d for d in inbox.iterdir() if d.is_dir()]
        return len(subdirs) > 0

    def _detect_agent_config(self) -> bool:
        """Check for agent configuration"""
        config_files = [
            "config.yaml",
            "config.json",
            "agents.yaml",
            "agents.json",
        ]
        return any((self.path / cf).exists() for cf in config_files)

    def _estimate_users(self) -> int:
        """Estimate number of users"""
        # Check inbox structure for agent count
        inbox = self.path / "inbox"
        if inbox.exists():
            agents = [d for d in inbox.iterdir() if d.is_dir()]
            # Rough heuristic: agents / 3 = users (code, chat, human per user)
            return max(1, len(agents) // 3)

        return 1  # Default to single user

    def _estimate_messages_per_day(self) -> int:
        """Estimate messages per day based on existing files"""
        inbox = self.path / "inbox"
        if not inbox.exists():
            return 0

        # Count message files
        msg_files = list(inbox.rglob("*.msg")) + list(inbox.rglob("*.json"))

        if len(msg_files) == 0:
            return 0

        # Check modification times to estimate daily rate
        now = datetime.now()
        recent = [
            f for f in msg_files if (now - datetime.fromtimestamp(f.stat().st_mtime)).days < 7
        ]

        if len(recent) == 0:
            return len(msg_files) // 30  # Assume 30 day history

        return len(recent) // 7  # Messages per day based on last week

    def _determine_scale(self, users: int, messages: int) -> str:
        """Determine scale based on users and messages"""
        if users >= 100 or messages >= 100000:
            return "enterprise"
        if users >= 10 or messages >= 1000:
            return "organization"
        if users >= 2 or messages >= 100:
            return "team"
        return "individual"

    def _detect_platform(self) -> str:
        """Detect operating system platform"""
        import platform

        system = platform.system().lower()
        if system == "darwin":
            return "macos"
        if system == "windows":
            return "windows"
        return "linux"

    def _detect_patterns(self) -> list[str]:
        """Check which universal patterns are present"""
        patterns = []

        # 1. Collision-Free Message Protocol
        if self._has_uuid_messages():
            patterns.append("collision-free-messaging")

        # 2. Event Sourcing
        if self._detect_event_log():
            patterns.append("event-sourcing")

        # 3. Content-Addressed DAG
        if self._has_content_addressing():
            patterns.append("content-addressed-dag")

        # 4. Authority Domains
        if self._has_authority_config():
            patterns.append("authority-domains")

        # 5. Priority Queue
        if self._has_priority_queue():
            patterns.append("priority-queue")

        # 6. Defer Queue
        if self._has_defer_queue():
            patterns.append("defer-queue")

        # 7. Fault-Tolerant Wrappers
        if self._has_retry_logic():
            patterns.append("fault-tolerant-wrappers")

        # 8. TLA+ Verification
        if self._has_tla_specs():
            patterns.append("tla-verification")

        return patterns

    def _has_uuid_messages(self) -> bool:
        """Check if messages use UUID format"""
        inbox = self.path / "inbox"
        if not inbox.exists():
            return False

        msg_files = list(inbox.rglob("*.msg"))[:10]  # Sample 10
        uuid_pattern = re.compile(r"[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}")

        return any(uuid_pattern.search(str(f.name)) for f in msg_files)

    def _has_content_addressing(self) -> bool:
        """Check for SHA256 content addressing"""
        sha_pattern = re.compile(r"[a-f0-9]{64}")
        files = list(self.path.rglob("*.msg"))[:10]
        return any(sha_pattern.search(str(f.name)) for f in files)

    def _has_authority_config(self) -> bool:
        """Check if agent authority domains are configured"""
        if not self._detect_agent_config():
            return False

        config_file = self.path / "config.yaml"
        if config_file.exists():
            try:
                import yaml

                with open(config_file) as f:
                    config = yaml.safe_load(f)
                    if "agents" in config:
                        for agent in config["agents"].values():
                            if "authority_domains" in agent:
                                return True
            except Exception:
                pass

        return False

    def _has_priority_queue(self) -> bool:
        """Check for priority queue structure"""
        return (
            (self.path / "inbox" / "priority").exists()
            or (self.path / "queue" / "high").exists()
        )

    def _has_defer_queue(self) -> bool:
        """Check for defer queue structure"""
        return (
            (self.path / "inbox" / "defer").exists() or (self.path / "defer").exists()
        )

    def _has_retry_logic(self) -> bool:
        """Check for retry/fault tolerance patterns"""
        scripts = list(self.path.glob("*.sh")) + list(self.path.glob("scripts/*.sh"))
        retry_pattern = re.compile(r"(retry|attempt|backoff)", re.IGNORECASE)

        for script in scripts[:10]:  # Sample 10
            try:
                content = script.read_text()
                if retry_pattern.search(content):
                    return True
            except Exception:
                continue

        return False

    def _has_tla_specs(self) -> bool:
        """Check for TLA+ specifications"""
        return len(list(self.path.rglob("*.tla"))) > 0

    def _identify_gaps(self, existing_patterns: list[str]) -> list[str]:
        """Identify missing universal patterns"""
        all_patterns = [
            "collision-free-messaging",
            "event-sourcing",
            "content-addressed-dag",
            "authority-domains",
            "priority-queue",
            "defer-queue",
            "fault-tolerant-wrappers",
            "tla-verification",
        ]

        return [p for p in all_patterns if p not in existing_patterns]

    def _print_detection_results(self, result: DetectionResult):
        """Print detection results"""
        if HAS_RICH:
            table = Table(show_header=False, box=None)
            table.add_column("Component", style="cyan bold")
            table.add_column("Status", style="green")

            table.add_row(
                "Message System",
                f"{'✅' if result.has_message_system else '❌'} {result.message_system_type}",
            )
            table.add_row(
                "Event Log", "✅ Found" if result.has_event_log else "❌ Missing"
            )
            table.add_row(
                "Inbox Structure",
                "✅ Found" if result.has_inbox_structure else "❌ Missing",
            )
            table.add_row(
                "Agent Config",
                "✅ Found" if result.has_agent_config else "❌ Missing",
            )
            table.add_row("Estimated Scale", result.estimated_scale.upper())
            table.add_row("Platform", result.platform.upper())
            table.add_row(
                "Existing Patterns", f"{len(result.existing_patterns)}/8"
            )
            table.add_row("Gaps", str(len(result.gaps)))

            self.console.print(Panel(table, title="Detection Results", border_style="green"))
        else:
            print("\nDetection Results:")
            print(f"  Message System: {result.message_system_type}")
            print(f"  Event Log: {'Found' if result.has_event_log else 'Missing'}")
            print(f"  Scale: {result.estimated_scale}")
            print(f"  Patterns: {len(result.existing_patterns)}/8")
            print(f"  Gaps: {len(result.gaps)}")

    def print_header(self, text: str):
        """Print section header"""
        if HAS_RICH:
            self.console.print(f"\n[bold magenta]{text}[/bold magenta]")
        else:
            print(f"\n{'='*60}")
            print(text)
            print("=" * 60)


class MigrationAnalyzer:
    """Analyzes migration complexity based on detection results"""

    def __init__(self):
        self.console = Console() if HAS_RICH else None

    def analyze(self, detection: DetectionResult) -> MigrationComplexity:
        """Analyze migration complexity"""

        self.print_header("Analyzing Migration Complexity")

        # Determine complexity
        complexity = self._determine_complexity(detection)

        # Estimate effort
        hours = self._estimate_hours(detection, complexity)

        # Assess risk
        risk = self._assess_risk(detection)

        # Identify breaking changes
        breaking = self._identify_breaking_changes(detection)

        # Check if data migration needed
        data_migration = detection.has_message_system and detection.message_system_type != "file-based"

        result = MigrationComplexity(
            complexity_level=complexity,
            estimated_hours=hours,
            risk_level=risk,
            breaking_changes=breaking,
            data_migration_required=data_migration,
        )

        self._print_complexity_results(result)
        return result

    def _determine_complexity(self, detection: DetectionResult) -> str:
        """Determine overall complexity level"""
        score = 0

        # Existing infrastructure reduces complexity
        if detection.has_message_system:
            score -= 1
        if detection.has_event_log:
            score -= 1
        if detection.has_inbox_structure:
            score -= 1

        # Scale increases complexity
        scale_scores = {
            "individual": 0,
            "team": 1,
            "organization": 2,
            "enterprise": 3,
        }
        score += scale_scores.get(detection.estimated_scale, 0)

        # Gaps increase complexity
        score += len(detection.gaps) // 2

        if score <= 1:
            return "simple"
        if score <= 3:
            return "moderate"
        if score <= 5:
            return "complex"
        return "very_complex"

    def _estimate_hours(self, detection: DetectionResult, complexity: str) -> int:
        """Estimate migration effort in hours"""
        base_hours = {
            "simple": 4,
            "moderate": 16,
            "complex": 40,
            "very_complex": 80,
        }

        hours = base_hours.get(complexity, 40)

        # Adjust for scale
        if detection.estimated_scale == "team":
            hours = int(hours * 1.5)
        elif detection.estimated_scale == "organization":
            hours = int(hours * 2)
        elif detection.estimated_scale == "enterprise":
            hours = int(hours * 3)

        return hours

    def _assess_risk(self, detection: DetectionResult) -> str:
        """Assess migration risk level"""
        risk_score = 0

        # Data migration increases risk
        if detection.has_message_system and detection.message_system_type != "file-based":
            risk_score += 2

        # Scale increases risk
        if detection.estimated_scale in ["organization", "enterprise"]:
            risk_score += 2

        # Many gaps increase risk
        if len(detection.gaps) >= 5:
            risk_score += 1

        if risk_score <= 1:
            return "low"
        if risk_score <= 3:
            return "medium"
        return "high"

    def _identify_breaking_changes(self, detection: DetectionResult) -> list[str]:
        """Identify potential breaking changes"""
        breaking = []

        if detection.message_system_type == "database":
            breaking.append("Message format change (database → file-based)")

        if detection.message_system_type == "api":
            breaking.append("API endpoints will change")

        if not detection.has_event_log:
            breaking.append("Event log will be added (audit trail)")

        if len(detection.gaps) >= 4:
            breaking.append("Significant architectural changes required")

        return breaking

    def _print_complexity_results(self, complexity: MigrationComplexity):
        """Print complexity analysis"""
        if HAS_RICH:
            table = Table(show_header=False, box=None)
            table.add_column("Metric", style="cyan bold")
            table.add_column("Value", style="yellow")

            table.add_row("Complexity", complexity.complexity_level.upper())
            table.add_row("Estimated Hours", str(complexity.estimated_hours))
            table.add_row("Risk Level", complexity.risk_level.upper())
            table.add_row("Breaking Changes", str(len(complexity.breaking_changes)))
            table.add_row(
                "Data Migration",
                "✅ Required" if complexity.data_migration_required else "❌ Not needed",
            )

            self.console.print(
                Panel(table, title="Complexity Analysis", border_style="yellow")
            )
        else:
            print("\nComplexity Analysis:")
            print(f"  Complexity: {complexity.complexity_level}")
            print(f"  Estimated Hours: {complexity.estimated_hours}")
            print(f"  Risk: {complexity.risk_level}")

    def print_header(self, text: str):
        """Print section header"""
        if HAS_RICH:
            self.console.print(f"\n[bold magenta]{text}[/bold magenta]")
        else:
            print(f"\n{'='*60}")
            print(text)
            print("=" * 60)


class MigrationPlanner:
    """Generates step-by-step migration plan"""

    def __init__(self):
        self.console = Console() if HAS_RICH else None

    def plan(
        self, detection: DetectionResult, complexity: MigrationComplexity
    ) -> MigrationPlan:
        """Generate migration plan"""

        self.print_header("Generating Migration Plan")

        steps = self._generate_steps(detection, complexity)
        rollback = self._generate_rollback_strategy(detection)
        testing = self._generate_testing_strategy(detection)
        timeline = self._generate_timeline(complexity)

        plan = MigrationPlan(
            detection=detection,
            complexity=complexity,
            steps=steps,
            rollback_strategy=rollback,
            testing_strategy=testing,
            estimated_timeline=timeline,
        )

        self._print_plan_summary(plan)
        return plan

    def _generate_steps(
        self, detection: DetectionResult, complexity: MigrationComplexity
    ) -> list[dict[str, Any]]:
        """Generate ordered migration steps"""
        steps = []
        step_num = 1

        # Step 1: Backup
        steps.append(
            {
                "number": step_num,
                "phase": "preparation",
                "title": "Backup existing system",
                "description": "Create full backup of current system before migration",
                "commands": [
                    f"tar -czf backup-$(date +%Y%m%d).tar.gz {detection.platform}/*",
                    "mv backup-*.tar.gz ~/backups/",
                ],
                "duration": "30 minutes",
                "risk": "low",
            }
        )
        step_num += 1

        # Step 2: Install coordination system
        steps.append(
            {
                "number": step_num,
                "phase": "preparation",
                "title": "Install coordination system",
                "description": "Clone and set up coordination system",
                "commands": [
                    "git clone https://github.com/devvyn/coordination-system.git",
                    "cd coordination-system",
                    "./scripts/coord-init.py",
                ],
                "duration": "10 minutes",
                "risk": "low",
            }
        )
        step_num += 1

        # Step 3: Migrate configuration
        if not detection.has_agent_config:
            steps.append(
                {
                    "number": step_num,
                    "phase": "configuration",
                    "title": "Create agent configuration",
                    "description": "Define agent roles and authority domains",
                    "commands": ["# Edit config.yaml to define agents"],
                    "duration": "1 hour",
                    "risk": "low",
                }
            )
            step_num += 1

        # Step 4: Migrate messages
        if detection.has_message_system:
            steps.append(
                {
                    "number": step_num,
                    "phase": "data",
                    "title": "Migrate existing messages",
                    "description": f"Convert {detection.message_system_type} messages to coordination format",
                    "commands": ["# Use migration script to convert messages"],
                    "duration": "2-4 hours",
                    "risk": "medium",
                }
            )
            step_num += 1

        # Step 5: Set up event log
        if not detection.has_event_log:
            steps.append(
                {
                    "number": step_num,
                    "phase": "infrastructure",
                    "title": "Initialize event log",
                    "description": "Create event sourcing log for audit trail",
                    "commands": [
                        "touch events.log",
                        "chmod 644 events.log",
                    ],
                    "duration": "5 minutes",
                    "risk": "low",
                }
            )
            step_num += 1

        # Step 6: Add missing patterns
        for gap in detection.gaps:
            steps.append(
                {
                    "number": step_num,
                    "phase": "patterns",
                    "title": f"Implement {gap}",
                    "description": f"Add {gap} pattern to system",
                    "commands": [f"# See docs/abstractions/universal-patterns.md#{gap}"],
                    "duration": "2-4 hours",
                    "risk": "medium",
                }
            )
            step_num += 1

        # Step 7: Testing
        steps.append(
            {
                "number": step_num,
                "phase": "validation",
                "title": "Test migration",
                "description": "Verify all functionality works",
                "commands": [
                    "./message.sh send code chat 'Test' 'Migration test'",
                    "./message.sh inbox chat",
                    "./message.sh log",
                ],
                "duration": "1-2 hours",
                "risk": "low",
            }
        )
        step_num += 1

        # Step 8: Cutover
        steps.append(
            {
                "number": step_num,
                "phase": "deployment",
                "title": "Production cutover",
                "description": "Switch to new system",
                "commands": [
                    "# Stop old system",
                    "# Start coordination system",
                    "# Monitor for issues",
                ],
                "duration": "1 hour",
                "risk": "high",
            }
        )

        return steps

    def _generate_rollback_strategy(self, detection: DetectionResult) -> str:
        """Generate rollback strategy"""
        return f"""# Rollback Strategy

If migration fails or issues arise:

1. **Stop new system**:
   - Stop all coordination system processes
   - Preserve state for debugging

2. **Restore backup**:
   ```bash
   cd ~/backups
   tar -xzf backup-YYYYMMDD.tar.gz
   cp -r * /original/location/
   ```

3. **Restart old system**:
   - Verify old system functionality
   - Check data integrity

4. **Analyze failure**:
   - Review migration logs
   - Identify root cause
   - Fix issues before retry

**Time to rollback**: 15-30 minutes
**Data loss risk**: Minimal (if backup is complete)
"""

    def _generate_testing_strategy(self, detection: DetectionResult) -> str:
        """Generate testing strategy"""
        return f"""# Testing Strategy

## Unit Tests
- Test message sending between agents
- Verify inbox operations
- Check event log integrity

## Integration Tests
- Test complete workflows (send → receive → process)
- Verify authority domain enforcement
- Test priority queue functionality

## Performance Tests
- Measure message throughput
- Test with {detection.estimated_messages_per_day} messages/day load
- Verify latency requirements (p99 < 100ms for individual scale)

## Acceptance Criteria
- All messages delivered successfully
- Event log captures all operations
- No data loss during migration
- Performance meets {detection.estimated_scale} scale requirements
"""

    def _generate_timeline(self, complexity: MigrationComplexity) -> str:
        """Generate migration timeline"""
        hours = complexity.estimated_hours

        if hours <= 8:
            return "1 day"
        if hours <= 40:
            return f"{hours // 8} days"
        if hours <= 160:
            return f"{hours // 40} weeks"
        return f"{hours // 160} months"

    def _print_plan_summary(self, plan: MigrationPlan):
        """Print plan summary"""
        if HAS_RICH:
            self.console.print(
                f"\n[bold green]✅ Migration plan generated: {len(plan.steps)} steps[/bold green]"
            )
            self.console.print(f"[cyan]Timeline: {plan.estimated_timeline}[/cyan]")
            self.console.print(
                f"[yellow]Risk: {plan.complexity.risk_level.upper()}[/yellow]"
            )
        else:
            print(f"\n✅ Migration plan generated: {len(plan.steps)} steps")
            print(f"Timeline: {plan.estimated_timeline}")
            print(f"Risk: {plan.complexity.risk_level}")

    def print_header(self, text: str):
        """Print section header"""
        if HAS_RICH:
            self.console.print(f"\n[bold magenta]{text}[/bold magenta]")
        else:
            print(f"\n{'='*60}")
            print(text)
            print("=" * 60)


class MigrationAssistant:
    """Main migration assistant orchestrator"""

    def __init__(self, path: str, output: str | None = None):
        self.path = path
        self.output = output
        self.console = Console() if HAS_RICH else None

    def run(self):
        """Run complete migration analysis"""

        self.print_welcome()

        # Phase 1: Detect
        detector = SystemDetector(self.path)
        detection = detector.detect()

        # Phase 2: Analyze
        analyzer = MigrationAnalyzer()
        complexity = analyzer.analyze(detection)

        # Phase 3: Plan
        planner = MigrationPlanner()
        plan = planner.plan(detection, complexity)

        # Phase 4: Generate report
        self.generate_report(plan)

        self.print_success(
            f"\n✅ Migration analysis complete. See report: {self.output or 'migration-plan.md'}"
        )

    def print_welcome(self):
        """Print welcome message"""
        if HAS_RICH:
            self.console.print(
                Panel.fit(
                    "[bold cyan]Coordination System Migration Assistant[/bold cyan]\n\n"
                    "Analyzes existing systems and generates migration plans.",
                    border_style="cyan",
                )
            )
        else:
            print("\n" + "=" * 60)
            print("Coordination System Migration Assistant")
            print("=" * 60)

    def generate_report(self, plan: MigrationPlan):
        """Generate markdown migration report"""

        report_path = self.output or "migration-plan.md"

        today = datetime.now().strftime("%Y-%m-%d")

        content = f"""# Migration Plan

**Generated**: {today}
**Target Path**: {self.path}
**Estimated Timeline**: {plan.estimated_timeline}
**Complexity**: {plan.complexity.complexity_level.upper()}
**Risk Level**: {plan.complexity.risk_level.upper()}

---

## Executive Summary

### Current State
- **Message System**: {plan.detection.message_system_type}
- **Event Log**: {'✅ Exists' if plan.detection.has_event_log else '❌ Missing'}
- **Scale**: {plan.detection.estimated_scale.upper()}
- **Platform**: {plan.detection.platform.upper()}
- **Existing Patterns**: {len(plan.detection.existing_patterns)}/8

### Migration Overview
- **Steps**: {len(plan.steps)}
- **Estimated Hours**: {plan.complexity.estimated_hours}
- **Breaking Changes**: {len(plan.complexity.breaking_changes)}
- **Data Migration**: {'Required' if plan.complexity.data_migration_required else 'Not needed'}

---

## Gap Analysis

### Existing Patterns
{self._format_list(plan.detection.existing_patterns)}

### Missing Patterns
{self._format_list(plan.detection.gaps)}

---

## Migration Steps

"""

        for step in plan.steps:
            content += f"""### Step {step['number']}: {step['title']}

**Phase**: {step['phase']}
**Duration**: {step['duration']}
**Risk**: {step['risk'].upper()}

{step['description']}

```bash
{chr(10).join(step['commands'])}
```

---

"""

        content += f"""## Rollback Strategy

{plan.rollback_strategy}

---

## Testing Strategy

{plan.testing_strategy}

---

## Risk Assessment

**Overall Risk**: {plan.complexity.risk_level.upper()}

### Breaking Changes
{self._format_list(plan.complexity.breaking_changes) if plan.complexity.breaking_changes else 'None identified'}

### Mitigation Strategies
1. Complete backup before starting
2. Test in staging environment first
3. Incremental rollout (if team/org/enterprise scale)
4. Monitor closely during cutover
5. Have rollback plan ready

---

## Timeline

**Estimated Total**: {plan.estimated_timeline} ({plan.complexity.estimated_hours} hours)

### Phase Breakdown
- Preparation: 10% of time
- Configuration: 15% of time
- Data Migration: 30% of time
- Pattern Implementation: 30% of time
- Testing: 10% of time
- Deployment: 5% of time

---

## Success Criteria

- [ ] All existing messages migrated
- [ ] Event log capturing all operations
- [ ] All 8 universal patterns implemented
- [ ] Performance meets scale requirements
- [ ] No data loss
- [ ] Rollback tested and verified

---

**Generated by [Coordination System](https://github.com/devvyn/coordination-system)**
"""

        with open(report_path, "w") as f:
            f.write(content)

    def _format_list(self, items: list[str]) -> str:
        """Format list as markdown"""
        if not items:
            return "None"
        return "\n".join(f"- {item}" for item in items)

    def print_success(self, text: str):
        """Print success message"""
        if HAS_RICH:
            self.console.print(f"[green]{text}[/green]")
        else:
            print(text)


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Migration Assistant for Coordination System"
    )
    parser.add_argument(
        "--path",
        default=".",
        help="Path to existing system (default: current directory)",
    )
    parser.add_argument(
        "--output",
        default="migration-plan.md",
        help="Output file for migration plan (default: migration-plan.md)",
    )

    args = parser.parse_args()

    # Check for rich library
    if not HAS_RICH:
        print("Note: Install 'rich' package for better UI: pip install rich")
        print("Continuing with basic UI...\n")

    # Run assistant
    assistant = MigrationAssistant(path=args.path, output=args.output)
    try:
        assistant.run()
    except KeyboardInterrupt:
        print("\n\nCancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
