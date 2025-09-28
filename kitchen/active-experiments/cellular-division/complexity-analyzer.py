#!/usr/bin/env python3
"""
Project Complexity Analyzer for Cellular Division
Analyzes projects to determine if they've reached critical mass for division
"""

import json
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class DivisionMetrics:
    """Metrics used to determine if a project should be divided"""

    spec_count: int
    dependency_depth: int
    domain_divergence: float  # 0.0 to 1.0
    expertise_domains: int
    stability_score: float  # 0.0 to 1.0
    quality_score: float  # 0.0 to 1.0


@dataclass
class DivisionOpportunity:
    """Represents a potential project division"""

    project_path: str
    metrics: DivisionMetrics
    recommended_domains: list[str]
    division_recommended: bool
    reasoning: str


class ProjectComplexityAnalyzer:
    """Analyzes project complexity to identify division opportunities"""

    # Critical mass thresholds
    SPEC_COUNT_THRESHOLD = 50
    DEPENDENCY_DEPTH_THRESHOLD = 3
    DOMAIN_DIVERGENCE_THRESHOLD = 0.7
    EXPERTISE_DOMAINS_THRESHOLD = 5

    # Quality gates
    STABILITY_THRESHOLD = 0.8
    QUALITY_THRESHOLD = 0.9

    def __init__(self):
        self.domain_keywords = {
            "taxonomic": [
                "species",
                "taxonomy",
                "classification",
                "botanical",
                "scientific",
            ],
            "ocr": ["ocr", "image", "text extraction", "recognition", "vision"],
            "data_export": ["export", "darwin core", "csv", "format", "output"],
            "validation": ["validate", "verify", "check", "quality", "accuracy"],
            "processing": ["process", "pipeline", "workflow", "batch", "automation"],
            "ui": ["interface", "user", "frontend", "display", "interaction"],
            "api": ["api", "endpoint", "service", "integration", "interface"],
            "database": ["database", "storage", "persistence", "query", "schema"],
        }

    def analyze_project(self, project_path: str) -> DivisionOpportunity:
        """Analyze a project for division opportunities"""
        path = Path(project_path)

        if not path.exists():
            raise ValueError(f"Project path does not exist: {project_path}")

        # Calculate metrics
        specs = self._find_specifications(path)
        dependencies = self._analyze_dependencies(path)
        domains = self._analyze_domain_divergence(specs)
        stability = self._calculate_stability(path)
        quality = self._calculate_quality(path)

        metrics = DivisionMetrics(
            spec_count=len(specs),
            dependency_depth=self._calculate_dependency_depth(dependencies),
            domain_divergence=domains["divergence"],
            expertise_domains=len(domains["domains"]),
            stability_score=stability,
            quality_score=quality,
        )

        # Determine if division is recommended
        division_recommended, reasoning = self._evaluate_division_need(metrics, domains)

        return DivisionOpportunity(
            project_path=project_path,
            metrics=metrics,
            recommended_domains=list(domains["domains"].keys()),
            division_recommended=division_recommended,
            reasoning=reasoning,
        )

    def _find_specifications(self, project_path: Path) -> list[dict[str, Any]]:
        """Find all specification files in the project"""
        specs = []

        # Look for .bspec directory
        bspec_dir = project_path / ".bspec"
        if bspec_dir.exists():
            for spec_file in bspec_dir.glob("**/*.md"):
                specs.append(
                    {
                        "file": str(spec_file),
                        "content": self._read_file_safe(spec_file),
                        "type": "bspec",
                    }
                )

        # Look for specification files in docs/
        docs_dir = project_path / "docs"
        if docs_dir.exists():
            for spec_file in docs_dir.glob("**/*spec*.md"):
                specs.append(
                    {
                        "file": str(spec_file),
                        "content": self._read_file_safe(spec_file),
                        "type": "docs",
                    }
                )

        # Look for README files as specifications
        for readme in project_path.glob("**/README.md"):
            if len(self._read_file_safe(readme)) > 1000:  # Substantial READMEs
                specs.append(
                    {
                        "file": str(readme),
                        "content": self._read_file_safe(readme),
                        "type": "readme",
                    }
                )

        return specs

    def _analyze_dependencies(self, project_path: Path) -> dict[str, list[str]]:
        """Analyze internal dependencies between components"""
        dependencies = defaultdict(list)

        # Analyze Python imports
        for py_file in project_path.glob("**/*.py"):
            content = self._read_file_safe(py_file)
            imports = re.findall(r"from\s+(\w+)\s+import|import\s+(\w+)", content)
            for match in imports:
                imported = match[0] or match[1]
                if imported and not imported.startswith("_"):
                    dependencies[str(py_file)].append(imported)

        # Analyze JavaScript imports
        for js_file in project_path.glob("**/*.js"):
            content = self._read_file_safe(js_file)
            imports = re.findall(r'import.*from\s+[\'"]([^\'"]+)[\'"]', content)
            dependencies[str(js_file)].extend(imports)

        return dict(dependencies)

    def _analyze_domain_divergence(self, specs: list[dict[str, Any]]) -> dict[str, Any]:
        """Analyze how much specifications diverge into different domains"""
        domain_counts = defaultdict(int)
        total_specs = len(specs)

        if total_specs == 0:
            return {"divergence": 0.0, "domains": {}}

        # Categorize each specification by domain
        for spec in specs:
            content = spec["content"].lower()
            spec_domains = []

            for domain, keywords in self.domain_keywords.items():
                keyword_matches = sum(1 for keyword in keywords if keyword in content)
                if keyword_matches > 0:
                    domain_counts[domain] += keyword_matches
                    spec_domains.append(domain)

            # If no domains found, classify as 'general'
            if not spec_domains:
                domain_counts["general"] += 1

        # Calculate divergence as entropy-like measure
        if not domain_counts:
            return {"divergence": 0.0, "domains": {}}

        total_count = sum(domain_counts.values())
        divergence = 0.0

        for count in domain_counts.values():
            if count > 0:
                probability = count / total_count
                divergence -= probability * (probability**0.5)  # Modified entropy

        # Normalize to 0-1 range
        max_possible_divergence = 1.0
        normalized_divergence = min(divergence / max_possible_divergence, 1.0)

        return {"divergence": normalized_divergence, "domains": domain_counts}

    def _calculate_dependency_depth(self, dependencies: dict[str, list[str]]) -> int:
        """Calculate maximum dependency depth in the project"""
        if not dependencies:
            return 0

        # Simple depth calculation - count maximum import chains
        max_depth = 0
        for file_deps in dependencies.values():
            max_depth = max(max_depth, len(file_deps))

        return max_depth

    def _calculate_stability(self, project_path: Path) -> float:
        """Calculate project stability score based on recent changes"""
        # Simplified: check if git repo exists and recent commits
        git_dir = project_path / ".git"
        if not git_dir.exists():
            return 0.5  # Unknown, assume moderate stability

        try:
            # In a real implementation, we'd analyze git log
            # For prototype, return high stability
            return 0.85
        except Exception:
            return 0.5

    def _calculate_quality(self, project_path: Path) -> float:
        """Calculate project quality score"""
        quality_indicators = []

        # Check for test files
        test_files = list(project_path.glob("**/test*.py")) + list(
            project_path.glob("**/*test.py")
        )
        quality_indicators.append(min(len(test_files) / 10, 1.0))

        # Check for documentation
        doc_files = list(project_path.glob("**/README.md")) + list(
            project_path.glob("**/docs/**/*.md")
        )
        quality_indicators.append(min(len(doc_files) / 5, 1.0))

        # Check for configuration files (indicates mature project)
        config_files = (
            list(project_path.glob("**/*.yml"))
            + list(project_path.glob("**/*.yaml"))
            + list(project_path.glob("**/*.json"))
        )
        quality_indicators.append(min(len(config_files) / 3, 1.0))

        return (
            sum(quality_indicators) / len(quality_indicators)
            if quality_indicators
            else 0.0
        )

    def _evaluate_division_need(
        self, metrics: DivisionMetrics, domains: dict[str, Any]
    ) -> tuple[bool, str]:
        """Evaluate whether division is recommended and provide reasoning"""
        reasons = []

        # Check complexity thresholds
        complexity_exceeded = 0

        if metrics.spec_count >= self.SPEC_COUNT_THRESHOLD:
            complexity_exceeded += 1
            reasons.append(
                f"High specification count ({metrics.spec_count} >= {self.SPEC_COUNT_THRESHOLD})"
            )

        if metrics.dependency_depth >= self.DEPENDENCY_DEPTH_THRESHOLD:
            complexity_exceeded += 1
            reasons.append(
                f"Deep dependencies ({metrics.dependency_depth} >= {self.DEPENDENCY_DEPTH_THRESHOLD})"
            )

        if metrics.domain_divergence >= self.DOMAIN_DIVERGENCE_THRESHOLD:
            complexity_exceeded += 1
            reasons.append(
                f"High domain divergence ({metrics.domain_divergence:.2f} >= {self.DOMAIN_DIVERGENCE_THRESHOLD})"
            )

        if metrics.expertise_domains >= self.EXPERTISE_DOMAINS_THRESHOLD:
            complexity_exceeded += 1
            reasons.append(
                f"Many expertise domains ({metrics.expertise_domains} >= {self.EXPERTISE_DOMAINS_THRESHOLD})"
            )

        # Check quality gates
        quality_blocks = []

        if metrics.stability_score < self.STABILITY_THRESHOLD:
            quality_blocks.append(
                f"Low stability ({metrics.stability_score:.2f} < {self.STABILITY_THRESHOLD})"
            )

        if metrics.quality_score < self.QUALITY_THRESHOLD:
            quality_blocks.append(
                f"Low quality ({metrics.quality_score:.2f} < {self.QUALITY_THRESHOLD})"
            )

        # Decision logic
        if quality_blocks:
            return False, f"Division blocked: {'; '.join(quality_blocks)}"

        if complexity_exceeded >= 2:
            domain_list = ", ".join(domains["domains"].keys())
            return (
                True,
                f"Division recommended: {'; '.join(reasons)}. Suggested domains: {domain_list}",
            )

        if complexity_exceeded == 1:
            return False, f"Monitoring recommended: {'; '.join(reasons)}"

        return False, "Project within normal complexity bounds"

    def _read_file_safe(self, file_path: Path) -> str:
        """Safely read file content"""
        try:
            return file_path.read_text(encoding="utf-8")
        except Exception:
            return ""


def main():
    """CLI interface for testing the analyzer"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Analyze project complexity for cellular division"
    )
    parser.add_argument("project_path", help="Path to the project to analyze")
    parser.add_argument("--json", action="store_true", help="Output results as JSON")

    args = parser.parse_args()

    analyzer = ProjectComplexityAnalyzer()
    try:
        opportunity = analyzer.analyze_project(args.project_path)

        if args.json:
            # JSON output for programmatic use
            result = {
                "project_path": opportunity.project_path,
                "division_recommended": opportunity.division_recommended,
                "reasoning": opportunity.reasoning,
                "metrics": {
                    "spec_count": opportunity.metrics.spec_count,
                    "dependency_depth": opportunity.metrics.dependency_depth,
                    "domain_divergence": opportunity.metrics.domain_divergence,
                    "expertise_domains": opportunity.metrics.expertise_domains,
                    "stability_score": opportunity.metrics.stability_score,
                    "quality_score": opportunity.metrics.quality_score,
                },
                "recommended_domains": opportunity.recommended_domains,
            }
            print(json.dumps(result, indent=2))
        else:
            # Human-readable output
            print(f"Project Complexity Analysis: {opportunity.project_path}")
            print("=" * 60)
            print(f"Specifications: {opportunity.metrics.spec_count}")
            print(f"Dependency Depth: {opportunity.metrics.dependency_depth}")
            print(f"Domain Divergence: {opportunity.metrics.domain_divergence:.2f}")
            print(f"Expertise Domains: {opportunity.metrics.expertise_domains}")
            print(f"Stability Score: {opportunity.metrics.stability_score:.2f}")
            print(f"Quality Score: {opportunity.metrics.quality_score:.2f}")
            print()
            print(
                f"Division Recommended: {'YES' if opportunity.division_recommended else 'NO'}"
            )
            print(f"Reasoning: {opportunity.reasoning}")
            if opportunity.recommended_domains:
                print(
                    f"Suggested Domains: {', '.join(opportunity.recommended_domains)}"
                )

    except Exception as e:
        print(f"Error analyzing project: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
