#!/usr/bin/env python3
"""
Configuration Generator for Coordination System

Interactive tool to generate customized coordination system configuration
based on user's use case, scale, and platform requirements.

Usage:
    ./coord-init.py [--output-dir PATH]

Features:
- Interactive questionnaire
- Template selection
- Custom configuration generation
- Next steps guidance
"""

import json
import os
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

try:
    from rich import print as rprint
    from rich.console import Console
    from rich.panel import Panel
    from rich.prompt import Confirm, Prompt
    from rich.table import Table

    HAS_RICH = True
except ImportError:
    HAS_RICH = False

    # Fallback to basic print
    def rprint(*args, **kwargs):
        print(*args)


try:
    import yaml

    HAS_YAML = True
except ImportError:
    HAS_YAML = False


@dataclass
class CoordinationConfig:
    """Configuration for coordination system"""

    use_case: str  # research, software, content, custom
    scale: str  # individual, team, organization, enterprise
    platform: str  # macos, linux, windows, docker, kubernetes
    project_name: str
    project_path: str

    # Agent configuration
    agents: dict[str, Any]

    # Quality gates
    quality_gates_enabled: bool

    # Observability
    logging_enabled: bool
    metrics_enabled: bool

    # Security
    auth_enabled: bool
    encryption_enabled: bool


class ConfigGenerator:
    """Interactive configuration generator"""

    def __init__(self, output_dir: str | None = None):
        self.console = Console() if HAS_RICH else None
        self.output_dir = output_dir or os.getcwd()
        self.template_dir = Path(__file__).parent.parent / "templates"

    def run(self):
        """Main interactive flow"""
        self.print_welcome()

        # Gather requirements
        use_case = self.ask_use_case()
        scale = self.ask_scale()
        platform = self.ask_platform()
        project_name = self.ask_project_name()

        # Generate config
        config = self.generate_config(use_case, scale, platform, project_name)

        # Show summary
        self.show_summary(config)

        # Confirm and create
        if self.confirm_create():
            self.create_project(config)
            self.show_next_steps(config)
        else:
            self.print_info("Configuration cancelled. No files created.")

    def print_welcome(self):
        """Print welcome message"""
        if HAS_RICH:
            self.console.print(
                Panel.fit(
                    "[bold cyan]Coordination System Configuration Generator[/bold cyan]\n\n"
                    "This wizard will help you set up a coordination system\n"
                    "tailored to your use case, scale, and platform.",
                    border_style="cyan",
                )
            )
        else:
            print("\n" + "=" * 60)
            print("Coordination System Configuration Generator")
            print("=" * 60)
            print("\nThis wizard will help you set up a coordination system")
            print("tailored to your use case, scale, and platform.\n")

    def ask_use_case(self) -> str:
        """Ask about use case"""
        self.print_header("Use Case Selection")

        if HAS_RICH:
            table = Table(show_header=True, header_style="bold magenta")
            table.add_column("#", style="cyan", width=3)
            table.add_column("Use Case", style="green")
            table.add_column("Description", style="white")

            table.add_row("1", "Research", "Scientific workflows, data → publication")
            table.add_row("2", "Software", "Feature → deployment workflows")
            table.add_row("3", "Content", "Article/video production workflows")
            table.add_row("4", "Minimal", "Bare-bones, customize yourself")

            self.console.print(table)

            choice = Prompt.ask(
                "\nSelect use case", choices=["1", "2", "3", "4"], default="4"
            )
        else:
            print("\nUse Cases:")
            print("  1. Research - Scientific workflows, data → publication")
            print("  2. Software - Feature → deployment workflows")
            print("  3. Content - Article/video production workflows")
            print("  4. Minimal - Bare-bones, customize yourself")
            choice = input("\nSelect use case (1-4, default: 4): ").strip() or "4"

        use_case_map = {
            "1": "research",
            "2": "software",
            "3": "content",
            "4": "minimal",
        }

        return use_case_map.get(choice, "minimal")

    def ask_scale(self) -> str:
        """Ask about scale"""
        self.print_header("Scale Selection")

        if HAS_RICH:
            table = Table(show_header=True, header_style="bold magenta")
            table.add_column("#", style="cyan", width=3)
            table.add_column("Scale", style="green")
            table.add_column("Users", style="yellow")
            table.add_column("Messages/Day", style="yellow")
            table.add_column("Cost/Month", style="yellow")

            table.add_row("1", "Individual", "1", "100", "$0")
            table.add_row("2", "Team", "2-10", "1,000", "$85")
            table.add_row("3", "Organization", "10-100", "10,000", "$8,500")
            table.add_row("4", "Enterprise", "100+", "1M", "$185,000")

            self.console.print(table)

            choice = Prompt.ask(
                "\nSelect scale", choices=["1", "2", "3", "4"], default="1"
            )
        else:
            print("\nScale Options:")
            print("  1. Individual (1 user, 100 msg/day, $0/month)")
            print("  2. Team (2-10 users, 1k msg/day, $85/month)")
            print("  3. Organization (10-100 users, 10k msg/day, $8.5k/month)")
            print("  4. Enterprise (100+ users, 1M msg/day, $185k/month)")
            choice = input("\nSelect scale (1-4, default: 1): ").strip() or "1"

        scale_map = {
            "1": "individual",
            "2": "team",
            "3": "organization",
            "4": "enterprise",
        }

        return scale_map.get(choice, "individual")

    def ask_platform(self) -> str:
        """Ask about platform"""
        self.print_header("Platform Selection")

        if HAS_RICH:
            table = Table(show_header=True, header_style="bold magenta")
            table.add_column("#", style="cyan", width=3)
            table.add_column("Platform", style="green")
            table.add_column("Setup Time", style="yellow")
            table.add_column("Status", style="yellow")

            table.add_row("1", "macOS", "1 minute", "✅ 100%")
            table.add_row("2", "Linux", "1-2 weeks", "✅ 90%")
            table.add_row("3", "Windows (WSL2)", "1-2 weeks", "✅ 85%")
            table.add_row("4", "Docker", "5 minutes", "✅ 100%")
            table.add_row("5", "Kubernetes", "1 hour", "✅ 100%")

            self.console.print(table)

            choice = Prompt.ask(
                "\nSelect platform", choices=["1", "2", "3", "4", "5"], default="1"
            )
        else:
            print("\nPlatform Options:")
            print("  1. macOS (1 min setup, 100% ready)")
            print("  2. Linux (1-2 weeks, 90% ready)")
            print("  3. Windows WSL2 (1-2 weeks, 85% ready)")
            print("  4. Docker (5 min setup, 100% ready)")
            print("  5. Kubernetes (1 hour setup, 100% ready)")
            choice = input("\nSelect platform (1-5, default: 1): ").strip() or "1"

        platform_map = {
            "1": "macos",
            "2": "linux",
            "3": "windows",
            "4": "docker",
            "5": "kubernetes",
        }

        return platform_map.get(choice, "macos")

    def ask_project_name(self) -> str:
        """Ask for project name"""
        self.print_header("Project Configuration")

        if HAS_RICH:
            name = Prompt.ask("Project name", default="my-coordination")
        else:
            name = input("\nProject name (default: my-coordination): ").strip()
            name = name or "my-coordination"

        return name

    def generate_config(
        self, use_case: str, scale: str, platform: str, project_name: str
    ) -> CoordinationConfig:
        """Generate configuration based on selections"""

        # Determine output path
        project_path = os.path.join(self.output_dir, project_name)

        # Configure agents based on use case
        agents = self.get_agents_for_use_case(use_case)

        # Configure features based on scale
        quality_gates = scale in ["organization", "enterprise"]
        logging = scale in ["team", "organization", "enterprise"]
        metrics = scale in ["organization", "enterprise"]
        auth = scale in ["team", "organization", "enterprise"]
        encryption = scale in ["organization", "enterprise"]

        config = CoordinationConfig(
            use_case=use_case,
            scale=scale,
            platform=platform,
            project_name=project_name,
            project_path=project_path,
            agents=agents,
            quality_gates_enabled=quality_gates,
            logging_enabled=logging,
            metrics_enabled=metrics,
            auth_enabled=auth,
            encryption_enabled=encryption,
        )

        return config

    def get_agents_for_use_case(self, use_case: str) -> dict[str, Any]:
        """Get agent configuration for use case"""

        agents_map = {
            "research": {
                "researcher": {
                    "authority_domains": [
                        "experimental_design",
                        "hypothesis_formation",
                        "interpretation",
                    ],
                    "tools": ["jupyter", "r_studio", "lab_equipment"],
                },
                "data": {
                    "authority_domains": [
                        "data_cleaning",
                        "statistical_analysis",
                        "visualization",
                    ],
                    "tools": ["pandas", "numpy", "matplotlib"],
                },
                "literature": {
                    "authority_domains": ["literature_search", "citation_management"],
                    "tools": ["pubmed", "arxiv", "zotero"],
                },
                "publication": {
                    "authority_domains": ["manuscript_writing", "formatting"],
                    "tools": ["latex", "reference_manager"],
                },
                "human": {"authority_domains": ["all"], "tools": []},
            },
            "software": {
                "architect": {
                    "authority_domains": ["system_design", "architecture"],
                    "tools": ["diagrams", "adr"],
                },
                "code": {
                    "authority_domains": ["implementation", "testing", "debugging"],
                    "tools": ["git", "ide", "pytest"],
                },
                "review": {
                    "authority_domains": ["code_review", "quality_gates"],
                    "tools": ["ruff", "mypy", "coverage"],
                },
                "devops": {
                    "authority_domains": ["deployment", "infrastructure", "monitoring"],
                    "tools": ["docker", "kubernetes", "terraform"],
                },
                "human": {"authority_domains": ["all"], "tools": []},
            },
            "content": {
                "strategy": {
                    "authority_domains": ["content_strategy", "audience_analysis"],
                    "tools": ["google_trends", "analytics"],
                },
                "writer": {
                    "authority_domains": ["drafting", "editing", "seo"],
                    "tools": ["grammarly", "yoast_seo"],
                },
                "production": {
                    "authority_domains": ["video_editing", "graphics", "audio"],
                    "tools": ["premiere_pro", "photoshop", "audacity"],
                },
                "distribution": {
                    "authority_domains": ["scheduling", "cross_posting"],
                    "tools": ["buffer", "hootsuite"],
                },
                "human": {"authority_domains": ["all"], "tools": []},
            },
            "minimal": {
                "code": {
                    "authority_domains": ["implementation", "testing"],
                    "tools": [],
                },
                "chat": {"authority_domains": ["strategy", "planning"], "tools": []},
                "human": {"authority_domains": ["all"], "tools": []},
            },
        }

        return agents_map.get(use_case, agents_map["minimal"])

    def show_summary(self, config: CoordinationConfig):
        """Show configuration summary"""
        self.print_header("Configuration Summary")

        if HAS_RICH:
            table = Table(show_header=False, box=None)
            table.add_column("Key", style="cyan bold")
            table.add_column("Value", style="green")

            table.add_row("Use Case", config.use_case.title())
            table.add_row("Scale", config.scale.title())
            table.add_row("Platform", config.platform.title())
            table.add_row("Project Name", config.project_name)
            table.add_row("Project Path", config.project_path)
            table.add_row("Agents", str(len(config.agents)))
            table.add_row(
                "Quality Gates",
                "✅ Enabled" if config.quality_gates_enabled else "❌ Disabled",
            )
            table.add_row(
                "Logging", "✅ Enabled" if config.logging_enabled else "❌ Disabled"
            )
            table.add_row(
                "Metrics", "✅ Enabled" if config.metrics_enabled else "❌ Disabled"
            )
            table.add_row(
                "Authentication", "✅ Enabled" if config.auth_enabled else "❌ Disabled"
            )
            table.add_row(
                "Encryption",
                "✅ Enabled" if config.encryption_enabled else "❌ Disabled",
            )

            self.console.print(Panel(table, title="Summary", border_style="green"))
        else:
            print("\nConfiguration Summary:")
            print(f"  Use Case: {config.use_case.title()}")
            print(f"  Scale: {config.scale.title()}")
            print(f"  Platform: {config.platform.title()}")
            print(f"  Project Name: {config.project_name}")
            print(f"  Project Path: {config.project_path}")
            print(f"  Agents: {len(config.agents)}")
            print(
                f"  Quality Gates: {'Enabled' if config.quality_gates_enabled else 'Disabled'}"
            )
            print(f"  Logging: {'Enabled' if config.logging_enabled else 'Disabled'}")
            print(f"  Metrics: {'Enabled' if config.metrics_enabled else 'Disabled'}")
            print(
                f"  Authentication: {'Enabled' if config.auth_enabled else 'Disabled'}"
            )
            print(
                f"  Encryption: {'Enabled' if config.encryption_enabled else 'Disabled'}"
            )

    def confirm_create(self) -> bool:
        """Confirm project creation"""
        if HAS_RICH:
            return Confirm.ask(
                "\n[bold]Create project with this configuration?[/bold]", default=True
            )
        response = (
            input("\nCreate project with this configuration? (Y/n): ").strip().lower()
        )
        return response in ["", "y", "yes"]

    def create_project(self, config: CoordinationConfig):
        """Create project directory and files"""
        self.print_info(f"\n📁 Creating project at: {config.project_path}")

        # Create project directory
        os.makedirs(config.project_path, exist_ok=True)

        # Copy template
        template_name = self.get_template_name(config)
        template_path = self.template_dir / template_name

        if template_path.exists():
            self.print_info(f"📋 Copying {template_name} template...")
            self.copy_template(template_path, config.project_path)
        else:
            self.print_warning(
                f"Template {template_name} not found, creating minimal structure"
            )
            self.create_minimal_structure(config.project_path)

        # Generate config file
        self.print_info("⚙️  Generating config.yaml...")
        self.write_config_file(config)

        # Generate README
        self.print_info("📝 Generating README.md...")
        self.write_readme(config)

        self.print_success(
            f"\n✅ Project created successfully at: {config.project_path}"
        )

    def get_template_name(self, config: CoordinationConfig) -> str:
        """Get template directory name"""
        template_map = {
            "research": "research-coordination",
            "software": "software-development",
            "content": "content-creation",
            "minimal": "minimal-coordination",
        }

        # Platform-specific templates
        if config.platform == "docker":
            return "platform-docker"
        if config.platform == "kubernetes":
            return "platform-kubernetes"

        return template_map.get(config.use_case, "minimal-coordination")

    def copy_template(self, template_path: Path, dest_path: str):
        """Copy template files"""
        for item in template_path.iterdir():
            if item.name in [".gitignore", "README.md"]:
                # Skip, we'll generate these
                continue

            dest_item = os.path.join(dest_path, item.name)

            if item.is_dir():
                shutil.copytree(item, dest_item, dirs_exist_ok=True)
            else:
                shutil.copy2(item, dest_item)

    def create_minimal_structure(self, project_path: str):
        """Create minimal project structure"""
        os.makedirs(os.path.join(project_path, "inbox"), exist_ok=True)

        # Create minimal message.sh script
        message_script = os.path.join(project_path, "message.sh")
        with open(message_script, "w") as f:
            f.write("#!/usr/bin/env bash\n")
            f.write("# Minimal coordination system\n")
            f.write("# See README.md for usage\n")

        os.chmod(message_script, 0o755)

    def write_config_file(self, config: CoordinationConfig):
        """Write config.yaml"""
        config_path = os.path.join(config.project_path, "config.yaml")

        config_dict = {
            "project": {
                "name": config.project_name,
                "use_case": config.use_case,
                "scale": config.scale,
                "platform": config.platform,
            },
            "agents": config.agents,
            "features": {
                "quality_gates": config.quality_gates_enabled,
                "logging": config.logging_enabled,
                "metrics": config.metrics_enabled,
                "authentication": config.auth_enabled,
                "encryption": config.encryption_enabled,
            },
        }

        if HAS_YAML:
            with open(config_path, "w") as f:
                yaml.dump(config_dict, f, default_flow_style=False, sort_keys=False)
        else:
            # Fallback to JSON if PyYAML not available
            self.print_warning("PyYAML not installed, writing config.json instead")
            config_path = os.path.join(config.project_path, "config.json")
            with open(config_path, "w") as f:
                json.dump(config_dict, f, indent=2)

    def write_readme(self, config: CoordinationConfig):
        """Write README.md"""
        readme_path = os.path.join(config.project_path, "README.md")

        today = datetime.now().strftime("%Y-%m-%d")

        readme_content = f"""# {config.project_name}

**Coordination System - {config.use_case.title()} Workflow**

Generated by coord-init on {today}

## Configuration

- **Use Case**: {config.use_case.title()}
- **Scale**: {config.scale.title()}
- **Platform**: {config.platform.title()}
- **Agents**: {len(config.agents)}

## Quick Start

```bash
# Send a message
./message.sh send <from> <to> <subject> <body>

# Check inbox
./message.sh inbox <agent>

# View event log
./message.sh log
```

## Agents

{self._format_agents(config.agents)}

## Next Steps

1. Review and customize `config.yaml`
2. Test message sending: `./message.sh send code chat "Test" "Body"`
3. Read the [documentation](https://coordination.local)

## Documentation

- [Universal Patterns](../docs/abstractions/universal-patterns.md)
- [Configuration Guide](../docs/configuration/customization-guide.md)
- [Troubleshooting](../docs/guides/troubleshooting.md)

---

Generated by [Coordination System](https://github.com/devvyn/coordination-system)
"""

        with open(readme_path, "w") as f:
            f.write(readme_content)

    def _format_agents(self, agents: dict[str, Any]) -> str:
        """Format agents for README"""
        lines = []
        for agent_name, agent_config in agents.items():
            domains = ", ".join(agent_config.get("authority_domains", []))
            lines.append(f"- **{agent_name}**: {domains}")
        return "\n".join(lines)

    def show_next_steps(self, config: CoordinationConfig):
        """Show next steps"""
        self.print_header("Next Steps")

        if HAS_RICH:
            self.console.print("\n[bold cyan]1. Navigate to project:[/bold cyan]")
            self.console.print(f"   cd {config.project_path}")

            self.console.print("\n[bold cyan]2. Test message sending:[/bold cyan]")
            self.console.print('   ./message.sh send code chat "Hello" "Test message"')

            self.console.print("\n[bold cyan]3. Check inbox:[/bold cyan]")
            self.console.print("   ./message.sh inbox chat")

            self.console.print("\n[bold cyan]4. Read documentation:[/bold cyan]")
            self.console.print("   cat README.md")

            if config.scale in ["team", "organization", "enterprise"]:
                self.console.print(
                    "\n[bold yellow]⚠️  For your scale, you may want to:[/bold yellow]"
                )
                self.console.print(
                    "   - Set up PostgreSQL (see docs/scaling/scale-transition-guide.md)"
                )
                self.console.print(
                    "   - Configure authentication (see docs/roadmap/security-privacy-audit.md)"
                )
                self.console.print(
                    "   - Enable monitoring (see docs/roadmap/performance-optimization.md)"
                )
        else:
            print("\nNext Steps:")
            print(f"1. cd {config.project_path}")
            print('2. ./message.sh send code chat "Hello" "Test message"')
            print("3. ./message.sh inbox chat")
            print("4. cat README.md")

    def print_header(self, text: str):
        """Print section header"""
        if HAS_RICH:
            self.console.print(f"\n[bold magenta]{text}[/bold magenta]")
        else:
            print(f"\n{'='*60}")
            print(text)
            print("=" * 60)

    def print_info(self, text: str):
        """Print info message"""
        if HAS_RICH:
            self.console.print(f"[cyan]{text}[/cyan]")
        else:
            print(text)

    def print_success(self, text: str):
        """Print success message"""
        if HAS_RICH:
            self.console.print(f"[green]{text}[/green]")
        else:
            print(text)

    def print_warning(self, text: str):
        """Print warning message"""
        if HAS_RICH:
            self.console.print(f"[yellow]{text}[/yellow]")
        else:
            print(f"WARNING: {text}")


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Interactive configuration generator for Coordination System"
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Output directory for generated project (default: current directory)",
    )

    args = parser.parse_args()

    # Check for rich library
    if not HAS_RICH:
        print("Note: Install 'rich' package for better UI: pip install rich")
        print("Continuing with basic UI...\n")

    # Run generator
    generator = ConfigGenerator(output_dir=args.output_dir)
    try:
        generator.run()
    except KeyboardInterrupt:
        print("\n\nCancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
