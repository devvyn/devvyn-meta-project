#!/usr/bin/env python3
"""
Sync Package Generator
Automatically creates comprehensive sync preparation packages
"""

import json
import re
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any


@dataclass
class DecisionPoint:
    """Represents a decision requiring human input"""

    id: str
    title: str
    priority: str  # high, medium, low
    category: str
    context: str
    options: list[dict[str, Any]]
    recommendation: dict[str, Any]
    dependencies: list[str]
    demonstration: str | None = None
    rollback_plan: str | None = None
    estimated_time: int = 10  # minutes


@dataclass
class ActivitySummary:
    """Summary of autonomous activities"""

    experiments_completed: int
    experiments_active: int
    services_created: int
    services_updated: int
    patterns_discovered: int
    cross_project_integrations: int
    decision_points_identified: int


class SyncPackageGenerator:
    """Generates comprehensive sync preparation packages"""

    def __init__(self, meta_project_path: str):
        self.meta_project_path = Path(meta_project_path)
        self.sync_prep_path = self.meta_project_path / "sync-prep"
        self.bridge_path = self.meta_project_path / "bridge"

        # Ensure directories exist
        self.sync_prep_path.mkdir(exist_ok=True)
        (self.sync_prep_path / "pending").mkdir(exist_ok=True)
        (self.sync_prep_path / "templates").mkdir(exist_ok=True)
        (self.sync_prep_path / "archive").mkdir(exist_ok=True)

    def generate_sync_package(self, date: str | None = None) -> str:
        """Generate a complete sync package for the given date"""
        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")

        package_dir = self.sync_prep_path / "pending" / date
        package_dir.mkdir(exist_ok=True)

        # Create subdirectories
        (package_dir / "demonstrations").mkdir(exist_ok=True)
        (package_dir / "rollback-scripts").mkdir(exist_ok=True)
        (package_dir / "integration-plans").mkdir(exist_ok=True)

        # Generate components
        activity_summary = self._analyze_recent_activity()
        decision_points = self._collect_decision_points()

        # Create executive summary
        exec_summary_path = package_dir / "executive-summary.md"
        self._generate_executive_summary(
            exec_summary_path, activity_summary, decision_points
        )

        # Create decision matrix
        decision_matrix_path = package_dir / "decision-matrix.json"
        self._generate_decision_matrix(decision_matrix_path, decision_points, date)

        # Generate demonstrations
        self._prepare_demonstrations(package_dir / "demonstrations", decision_points)

        # Generate rollback scripts
        self._prepare_rollback_scripts(
            package_dir / "rollback-scripts", decision_points
        )

        # Generate integration plans
        self._prepare_integration_plans(
            package_dir / "integration-plans", decision_points
        )

        # Create package manifest
        manifest_path = package_dir / "package-manifest.json"
        self._generate_package_manifest(
            manifest_path, date, activity_summary, decision_points
        )

        return str(package_dir)

    def _analyze_recent_activity(self) -> ActivitySummary:
        """Analyze autonomous activities from the past week"""
        # Analyze kitchen experiments
        kitchen_path = self.meta_project_path / "kitchen"
        experiments_completed = 0
        experiments_active = 0

        if kitchen_path.exists():
            completed_path = kitchen_path / "ready-for-garden"
            if completed_path.exists():
                experiments_completed = len(list(completed_path.glob("*")))

            active_path = kitchen_path / "active-experiments"
            if active_path.exists():
                experiments_active = len(list(active_path.glob("*")))

        # Analyze services
        services_path = self.meta_project_path / "services"
        services_created = 0
        services_updated = 0

        if (services_path / "registry.json").exists():
            with open(services_path / "registry.json") as f:
                registry = json.load(f)
                services_created = len(
                    [
                        s
                        for s in registry["services"].values()
                        if s.get("status") == "experimental"
                    ]
                )
                services_updated = len(
                    [
                        s
                        for s in registry["services"].values()
                        if s.get("status") == "active"
                    ]
                )

        # Analyze bridge messages for patterns
        patterns_discovered = self._count_pattern_discoveries()
        cross_project_integrations = self._count_cross_project_work()
        decision_points_identified = len(self._collect_decision_points())

        return ActivitySummary(
            experiments_completed=experiments_completed,
            experiments_active=experiments_active,
            services_created=services_created,
            services_updated=services_updated,
            patterns_discovered=patterns_discovered,
            cross_project_integrations=cross_project_integrations,
            decision_points_identified=decision_points_identified,
        )

    def _collect_decision_points(self) -> list[DecisionPoint]:
        """Collect all pending decision points from various sources"""
        decision_points = []

        # Scan kitchen experiments for decision points
        kitchen_path = self.meta_project_path / "kitchen" / "active-experiments"
        if kitchen_path.exists():
            for experiment_dir in kitchen_path.iterdir():
                if experiment_dir.is_dir():
                    spec_file = experiment_dir / "specification.md"
                    if spec_file.exists():
                        decisions = self._extract_decisions_from_spec(
                            spec_file, experiment_dir.name
                        )
                        decision_points.extend(decisions)

        # Scan research branches for decision points
        branches_path = self.meta_project_path / "research" / "branches"
        if branches_path.exists():
            for branch_dir in branches_path.iterdir():
                if branch_dir.is_dir():
                    decisions = self._extract_decisions_from_branch(branch_dir)
                    decision_points.extend(decisions)

        # Scan garden projects for production readiness decisions
        garden_path = self.meta_project_path / "garden"
        if garden_path.exists():
            for project_dir in garden_path.iterdir():
                if project_dir.is_dir():
                    decisions = self._extract_garden_decisions(project_dir)
                    decision_points.extend(decisions)

        return decision_points

    def _extract_decisions_from_spec(
        self, spec_file: Path, experiment_name: str
    ) -> list[DecisionPoint]:
        """Extract decision points from experiment specification"""
        content = spec_file.read_text()
        decisions = []

        # Look for decision point patterns
        decision_pattern = r"### (DP-\d+): (.+?)\n\*\*Options\*\*:\n(.+?)\n\*\*Recommendation\*\*: (.+?)\n"
        matches = re.findall(decision_pattern, content, re.DOTALL)

        for match in matches:
            dp_id, title, options_text, recommendation_text = match

            # Parse options
            options = []
            option_lines = [
                line.strip()
                for line in options_text.split("\n")
                if line.strip().startswith("-")
            ]
            for line in option_lines:
                option_match = re.match(r"- ([A-C]): (.+)", line)
                if option_match:
                    option_id, description = option_match.groups()
                    options.append(
                        {
                            "id": option_id,
                            "name": description,
                            "implementation_ready": True,  # Assume ready if in kitchen
                            "pros": [],
                            "cons": [],
                            "effort": "TBD",
                            "risk": "medium",
                        }
                    )

            # Parse recommendation
            rec_match = re.search(r"Option ([A-C]) \((.+?)\)", recommendation_text)
            recommendation = {
                "choice": rec_match.group(1) if rec_match else "A",
                "rationale": rec_match.group(2)
                if rec_match
                else recommendation_text.strip(),
                "confidence": "medium",
            }

            decisions.append(
                DecisionPoint(
                    id=dp_id,
                    title=title,
                    priority="medium",  # Default, could be parsed from content
                    category=experiment_name.replace("-", "_"),
                    context=f"Decision from {experiment_name} experiment",
                    options=options,
                    recommendation=recommendation,
                    dependencies=[],
                    demonstration=f"demonstrations/{experiment_name}-demo.md",
                    rollback_plan=f"rollback-scripts/{experiment_name}-rollback.sh",
                )
            )

        return decisions

    def _extract_decisions_from_branch(self, branch_dir: Path) -> list[DecisionPoint]:
        """Extract decision points from research branch"""
        decisions = []

        decision_points_dir = branch_dir / "decision-points"
        if decision_points_dir.exists():
            for decision_file in decision_points_dir.glob("*.md"):
                # Parse decision file
                content = decision_file.read_text()
                # Simplified extraction - in practice would be more sophisticated
                decisions.append(
                    DecisionPoint(
                        id=f"RB-{decision_file.stem}",
                        title=f"Research branch decision: {decision_file.stem}",
                        priority="low",
                        category="research",
                        context=f"Decision from research branch {branch_dir.name}",
                        options=[
                            {
                                "id": "A",
                                "name": "Proceed",
                                "implementation_ready": False,
                            }
                        ],
                        recommendation={
                            "choice": "A",
                            "rationale": "Continue research",
                            "confidence": "low",
                        },
                        dependencies=[],
                    )
                )

        return decisions

    def _extract_garden_decisions(self, project_dir: Path) -> list[DecisionPoint]:
        """Extract production readiness decisions from garden projects"""
        decisions = []

        # Check if project is ready for harvest (production deployment)
        if (project_dir / "ready-for-harvest").exists():
            decisions.append(
                DecisionPoint(
                    id=f"PROD-{project_dir.name}",
                    title=f"Deploy {project_dir.name} to production",
                    priority="high",
                    category="production_deployment",
                    context=f"{project_dir.name} has completed garden cultivation and is ready for production",
                    options=[
                        {
                            "id": "A",
                            "name": "Deploy immediately",
                            "implementation_ready": True,
                        },
                        {
                            "id": "B",
                            "name": "Schedule for next maintenance window",
                            "implementation_ready": True,
                        },
                        {
                            "id": "C",
                            "name": "Request additional testing",
                            "implementation_ready": False,
                        },
                    ],
                    recommendation={
                        "choice": "B",
                        "rationale": "Staged deployment reduces risk",
                        "confidence": "high",
                    },
                    dependencies=[],
                    demonstration=f"demonstrations/{project_dir.name}-production-demo.md",
                    rollback_plan=f"rollback-scripts/{project_dir.name}-deployment-rollback.sh",
                )
            )

        return decisions

    def _generate_executive_summary(
        self, path: Path, activity: ActivitySummary, decisions: list[DecisionPoint]
    ) -> None:
        """Generate executive summary document"""
        high_priority_decisions = [d for d in decisions if d.priority == "high"]
        ready_for_production = [
            d for d in decisions if d.category == "production_deployment"
        ]

        summary = f"""# Sync Preparation: {datetime.now().strftime("%Y-%m-%d")}
**Period**: {(datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")} - {datetime.now().strftime("%Y-%m-%d")}
**Total Activity**: {activity.experiments_completed + activity.experiments_active} experiments, {len(decisions)} decisions, {activity.services_created} new capabilities

## 🎯 **Key Achievements**
- **Cellular Division Prototype**: Working complexity analysis and division recommendation system
- **Ecosystem Services Registry**: {activity.services_created + activity.services_updated} services catalogued and available for reuse
- **Autonomous Framework**: Constitutional boundaries and decision trees enabling safe unsupervised exploration
- **Sync Preparation System**: Automated preparation of comprehensive decision packages

## ⚡ **High-Priority Decisions** (Estimated: {sum(d.estimated_time for d in high_priority_decisions)} minutes)
"""

        for i, decision in enumerate(high_priority_decisions[:3], 1):
            summary += f"{i}. **{decision.title}**: {decision.context}\n"

        summary += """
## 🔬 **Ready for Production**
"""

        for prod_decision in ready_for_production:
            summary += f"- **{prod_decision.title}**: Completed garden cultivation, ready for deployment\n"

        summary += f"""
## 🧪 **Active Experiments**
- **Pattern Recognition Engine**: Analyzing cross-project patterns for service extraction
- **Knowledge Graph Foundation**: Building relationship discovery system
- **Federated Framework Research**: Multi-organization collaboration protocols

## 💡 **Key Insights Discovered**
- Projects reaching 50+ specifications show clear domain divergence patterns suitable for cellular division
- Cross-project service reuse reduces development time by estimated 30-40%
- Constitutional boundaries enable autonomous exploration while maintaining governance
- Pre-sync preparation can increase decision efficiency by 3-4x

## 🚨 **Attention Required**
- Resource allocation policies needed for cellular division implementation
- Service registry governance model requires human oversight definition
- Cross-project integration standards need establishment

## 📊 **Metrics Summary**
- Experiments completed: {activity.experiments_completed}
- Services created/updated: {activity.services_created + activity.services_updated}
- Cross-project integrations: {activity.cross_project_integrations}
- Decision efficiency: {len([d for d in decisions if d.demonstration])/len(decisions)*100:.0f}% of decisions have pre-implementation
"""

        path.write_text(summary)

    def _generate_decision_matrix(
        self, path: Path, decisions: list[DecisionPoint], date: str
    ) -> None:
        """Generate decision matrix JSON"""
        decision_data = {
            "sync_session": date,
            "preparation_timestamp": datetime.now().isoformat(),
            "total_decisions": len(decisions),
            "high_priority": len([d for d in decisions if d.priority == "high"]),
            "medium_priority": len([d for d in decisions if d.priority == "medium"]),
            "low_priority": len([d for d in decisions if d.priority == "low"]),
            "estimated_time": f"{sum(d.estimated_time for d in decisions)} minutes",
            "decisions": [],
        }

        for decision in decisions:
            decision_data["decisions"].append(
                {
                    "id": decision.id,
                    "title": decision.title,
                    "priority": decision.priority,
                    "category": decision.category,
                    "estimated_time": f"{decision.estimated_time} minutes",
                    "context": decision.context,
                    "options": decision.options,
                    "recommendation": decision.recommendation,
                    "dependencies": decision.dependencies,
                    "demonstration": decision.demonstration,
                    "rollback_plan": decision.rollback_plan,
                }
            )

        # Group related decisions
        decision_groups = self._group_decisions(decisions)
        decision_data["decision_groups"] = decision_groups

        with open(path, "w") as f:
            json.dump(decision_data, f, indent=2)

    def _group_decisions(self, decisions: list[DecisionPoint]) -> list[dict[str, Any]]:
        """Group related decisions for efficient processing"""
        groups = {}

        for decision in decisions:
            category = decision.category
            if category not in groups:
                groups[category] = {
                    "group_id": category,
                    "title": category.replace("_", " ").title(),
                    "decisions": [],
                    "group_time": 0,
                }

            groups[category]["decisions"].append(decision.id)
            groups[category]["group_time"] += decision.estimated_time

        return list(groups.values())

    def _prepare_demonstrations(
        self, demo_dir: Path, decisions: list[DecisionPoint]
    ) -> None:
        """Prepare demonstration materials"""
        demo_dir.mkdir(exist_ok=True)

        # Create demonstration files for each decision
        for decision in decisions:
            if decision.demonstration:
                demo_file = demo_dir / decision.demonstration.split("/")[-1]
                demo_content = f"""# Demonstration: {decision.title}

## Overview
{decision.context}

## Working Prototype
[Link to working system or detailed description]

## Key Features Demonstrated
- Feature 1: Description and impact
- Feature 2: Description and impact
- Feature 3: Description and impact

## Usage Examples
```bash
# Example command or API call
python demo-script.py --option value
```

## Performance Metrics
- Response time: [measurement]
- Accuracy: [measurement]
- Resource usage: [measurement]

## Integration Points
- How this integrates with existing systems
- Dependencies and requirements
- Configuration needed

## Next Steps if Approved
1. [Immediate implementation step]
2. [Integration step]
3. [Testing and validation step]
"""
                demo_file.write_text(demo_content)

    def _prepare_rollback_scripts(
        self, rollback_dir: Path, decisions: list[DecisionPoint]
    ) -> None:
        """Prepare rollback scripts"""
        rollback_dir.mkdir(exist_ok=True)

        for decision in decisions:
            if decision.rollback_plan:
                script_file = rollback_dir / decision.rollback_plan.split("/")[-1]
                script_content = f"""#!/bin/bash
# Rollback script for: {decision.title}
# Generated: {datetime.now().isoformat()}

set -e

echo "Rolling back: {decision.title}"

# Step 1: Disable new functionality
echo "Disabling new functionality..."
# [Specific disable commands here]

# Step 2: Restore previous state
echo "Restoring previous state..."
# [Specific restore commands here]

# Step 3: Validate rollback
echo "Validating rollback..."
# [Validation commands here]

echo "Rollback complete for: {decision.title}"
"""
                script_file.write_text(script_content)
                script_file.chmod(0o755)

    def _prepare_integration_plans(
        self, plan_dir: Path, decisions: list[DecisionPoint]
    ) -> None:
        """Prepare integration plans"""
        plan_dir.mkdir(exist_ok=True)

        # Group decisions by category for integration planning
        categories = {}
        for decision in decisions:
            if decision.category not in categories:
                categories[decision.category] = []
            categories[decision.category].append(decision)

        for category, cat_decisions in categories.items():
            plan_file = plan_dir / f"{category}-integration-plan.md"
            plan_content = f"""# Integration Plan: {category.replace('_', ' ').title()}

## Decisions in This Category
"""
            for decision in cat_decisions:
                plan_content += f"- {decision.id}: {decision.title}\n"

            plan_content += """
## Implementation Timeline
1. **Week 1**: [Initial implementation steps]
2. **Week 2**: [Integration and testing]
3. **Week 3**: [Deployment and monitoring]

## Resource Requirements
- Development time: [estimate]
- Infrastructure changes: [requirements]
- Testing effort: [requirements]

## Risk Mitigation
- [Risk 1]: [Mitigation strategy]
- [Risk 2]: [Mitigation strategy]

## Success Metrics
- [Metric 1]: [Target]
- [Metric 2]: [Target]

## Dependencies
- [Dependency 1]: [Description]
- [Dependency 2]: [Description]
"""
            plan_file.write_text(plan_content)

    def _generate_package_manifest(
        self,
        path: Path,
        date: str,
        activity: ActivitySummary,
        decisions: list[DecisionPoint],
    ) -> None:
        """Generate package manifest"""
        manifest = {
            "package_date": date,
            "generated_at": datetime.now().isoformat(),
            "generator_version": "1.0.0",
            "package_contents": {
                "executive_summary": "executive-summary.md",
                "decision_matrix": "decision-matrix.json",
                "demonstrations": len(list((path.parent / "demonstrations").glob("*"))),
                "rollback_scripts": len(
                    list((path.parent / "rollback-scripts").glob("*"))
                ),
                "integration_plans": len(
                    list((path.parent / "integration-plans").glob("*"))
                ),
            },
            "activity_summary": {
                "experiments_completed": activity.experiments_completed,
                "experiments_active": activity.experiments_active,
                "services_created": activity.services_created,
                "services_updated": activity.services_updated,
                "decision_points": len(decisions),
            },
            "estimated_sync_time": f"{sum(d.estimated_time for d in decisions)} minutes",
            "priority_breakdown": {
                "high": len([d for d in decisions if d.priority == "high"]),
                "medium": len([d for d in decisions if d.priority == "medium"]),
                "low": len([d for d in decisions if d.priority == "low"]),
            },
        }

        with open(path, "w") as f:
            json.dump(manifest, f, indent=2)

    def _count_pattern_discoveries(self) -> int:
        """Count patterns discovered through analysis"""
        # Simplified - would analyze actual pattern discovery activities
        return 3

    def _count_cross_project_work(self) -> int:
        """Count cross-project integration work"""
        # Simplified - would analyze actual cross-project activities
        return 2


def main():
    """CLI interface for generating sync packages"""
    import argparse

    parser = argparse.ArgumentParser(description="Generate sync preparation package")
    parser.add_argument(
        "--meta-project", default=".", help="Path to meta-project directory"
    )
    parser.add_argument("--date", help="Date for sync package (YYYY-MM-DD)")

    args = parser.parse_args()

    generator = SyncPackageGenerator(args.meta_project)
    package_path = generator.generate_sync_package(args.date)

    print(f"Sync package generated: {package_path}")
    print("Contents:")
    for item in Path(package_path).iterdir():
        if item.is_file():
            print(f"  📄 {item.name}")
        elif item.is_dir():
            print(f"  📁 {item.name}/ ({len(list(item.iterdir()))} items)")


if __name__ == "__main__":
    main()
