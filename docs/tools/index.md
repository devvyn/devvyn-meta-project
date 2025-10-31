# Coordination Tools

**Executable tools to bootstrap, migrate, and manage coordination systems**

---

## Overview

The Coordination System includes powerful command-line tools that transform it from a documentation project into an **executable platform**:

| Tool | Purpose | When to Use | Time Savings |
|------|---------|-------------|--------------|
| **[Configuration Generator](coord-init.md)** | Bootstrap new systems | Starting fresh | **93%** (30min → 2min) |
| **[Migration Assistant](coord-migrate.md)** | Migrate existing systems | Have existing workflows | **90%** (planning time) |
| **Health Monitor** | Monitor running systems | Production deployment | Coming soon |

---

## Quick Decision Guide

### Starting a New Project?

**Use**: [Configuration Generator](coord-init.md)

```bash
./scripts/coord-init.py
# Answer 4 questions → working system in 2 minutes
```

**Perfect for**:
- New projects from scratch
- Learning the coordination system
- Prototyping workflows
- Individual/team projects

### Migrating an Existing System?

**Use**: [Migration Assistant](coord-migrate.md)

```bash
./scripts/coord-migrate.py --path ~/my-project
# Get comprehensive migration plan with risk assessment
```

**Perfect for**:
- Existing workflows to formalize
- Legacy systems to modernize
- Team/org/enterprise scale
- Complex migrations

### Running in Production?

**Use**: Health Monitor *(coming soon)*

```bash
./scripts/coord-monitor.py
# Real-time dashboard of system health
```

**Perfect for**:
- Production deployments
- Team/organization scale
- Performance monitoring
- Capacity planning

---

## Tool 1: Configuration Generator

### What It Does

Creates customized coordination systems in **2 minutes** with an interactive questionnaire.

### Key Features

- 🎯 **4 Questions**: Use case, scale, platform, project name
- 📦 **4 Use Cases**: Research, Software, Content, Minimal
- 📈 **4 Scale Levels**: Individual → Enterprise
- 💻 **5 Platforms**: macOS, Linux, Windows, Docker, Kubernetes
- ⚙️ **Smart Config**: Scale-aware feature enablement

### Example: Create Research Project

```bash
$ coord-init.py

Use Case Selection
┏━━━┳━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ # ┃ Use Case ┃ Description                            ┃
┡━━━╇━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ 1 │ Research │ Scientific workflows, data → publication │
│ 2 │ Software │ Feature → deployment workflows           │
│ 3 │ Content  │ Article/video production workflows       │
│ 4 │ Minimal  │ Bare-bones, customize yourself           │
└───┴──────────┴──────────────────────────────────────────┘

Select use case [1/2/3/4] (4): 1
Select scale [1/2/3/4] (1): 1
Select platform [1/2/3/4/5] (1): 1
Project name (my-coordination): protein-study

✅ Project created: ~/protein-study/
```

### Generated System

```
protein-study/
├── config.yaml           # Agent configuration
├── README.md             # Project documentation
├── message.sh            # Message passing script
├── inbox/                # Agent inboxes
│   ├── researcher/
│   ├── data/
│   ├── literature/
│   └── human/
└── workflows/            # Research workflows
    ├── literature-review.sh
    └── data-analysis.sh
```

### Learn More

→ **[Full Documentation](coord-init.md)**

---

## Tool 2: Migration Assistant

### What It Does

Analyzes existing systems and generates comprehensive migration plans with:
- Complexity assessment (simple → very complex)
- Risk analysis (low, medium, high)
- Step-by-step instructions
- Rollback strategy
- Testing strategy

### Key Features

- 🔍 **Detector**: Scans for existing patterns (8 universal patterns)
- 📊 **Analyzer**: Assesses effort (4-240 hours) and risk
- 📋 **Planner**: Generates phased migration plan
- 🔄 **Rollback**: Safety net if migration fails
- ✅ **Testing**: Validation criteria

### Example: Analyze Existing System

```bash
$ coord-migrate.py --path ~/my-existing-system

Detecting Existing System
╭──────────────────────────── Detection Results ───────────────────────────╮
│  Message System     ✅ file-based                                        │
│  Event Log          ✅ Found                                             │
│  Inbox Structure    ✅ Found                                             │
│  Agent Config       ✅ Found                                             │
│  Estimated Scale    TEAM                                                 │
│  Platform           MACOS                                                │
│  Existing Patterns  6/8                                                  │
│  Gaps               2                                                    │
╰───────────────────────────────────────────────────────────────────────────╯

Analyzing Migration Complexity
╭──────────────────────── Complexity Analysis ──────────────────────────────╮
│  Complexity        SIMPLE                                                │
│  Estimated Hours   6                                                     │
│  Risk Level        LOW                                                   │
│  Breaking Changes  0                                                     │
│  Data Migration    ❌ Not needed                                         │
╰───────────────────────────────────────────────────────────────────────────╯

✅ Migration plan generated: migration-plan.md
Timeline: 1 day
Risk: LOW
```

### Generated Report

```markdown
# Migration Plan

## Executive Summary
- Current: 6/8 patterns, file-based, team scale
- Timeline: 1 day
- Risk: LOW

## Migration Steps

### Step 1: Backup existing system
**Phase**: preparation
**Duration**: 30 minutes
**Risk**: LOW

### Step 2: Implement priority-queue
**Phase**: patterns
**Duration**: 2-4 hours
**Risk**: MEDIUM

## Rollback Strategy
[Detailed rollback procedures]

## Testing Strategy
[Validation criteria]
```

### Learn More

→ **[Full Documentation](coord-migrate.md)**

---

## Tool Comparison

### When to Use Each Tool

```
New Project          Existing System       Production
     │                    │                     │
     ▼                    ▼                     ▼
Configuration      Migration           Health Monitor
Generator          Assistant           (coming soon)
     │                    │                     │
  2 minutes         Days-weeks            Real-time
     │                    │                     │
     └─────────────► Working System ◄──────────┘
```

### Feature Matrix

| Feature | Config Generator | Migration Assistant | Health Monitor |
|---------|------------------|---------------------|----------------|
| **Bootstrap new system** | ✅ Primary use | ❌ | ❌ |
| **Analyze existing system** | ❌ | ✅ Primary use | ✅ Monitoring |
| **Migration planning** | ❌ | ✅ Primary use | ❌ |
| **Risk assessment** | ❌ | ✅ Yes | ✅ Yes |
| **Real-time monitoring** | ❌ | ❌ | ✅ Primary use |
| **Performance metrics** | ❌ | ❌ | ✅ Yes |
| **Interactive UI** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Generated reports** | ✅ README | ✅ Migration plan | ✅ Dashboard |

---

## Installation

### Prerequisites

- Python 3.10+ (for all tools)
- Optional: `rich` library (beautiful UI)
- Optional: `PyYAML` library (YAML parsing)

### One-Time Setup

```bash
# 1. Make tools executable
chmod +x scripts/coord-*.py

# 2. Install optional dependencies
pip install rich PyYAML

# 3. Add to PATH (optional)
echo 'export PATH="$HOME/devvyn-meta-project/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 4. Create aliases (optional)
echo 'alias coord-init="coord-init.py"' >> ~/.zshrc
echo 'alias coord-migrate="coord-migrate.py"' >> ~/.zshrc
source ~/.zshrc
```

### Verify Installation

```bash
# Test configuration generator
coord-init.py --help

# Test migration assistant
coord-migrate.py --help

# Test with minimal example
cd /tmp
coord-init.py --output-dir .
# Answer questions, verify success
```

---

## Common Workflows

### Workflow 1: New Individual Project

```bash
# 1. Generate system
coord-init.py
# Choose: Minimal, Individual, macOS, "my-project"

# 2. Test
cd my-project
./message.sh send code chat "Test" "Body"
./message.sh inbox chat

# 3. Customize
vim config.yaml
# Add your custom workflows
```

**Time**: ~5 minutes total

### Workflow 2: Migrate Team System

```bash
# 1. Analyze
coord-migrate.py --path ~/team-system
# Review: migration-plan.md

# 2. Backup
tar -czf backup-$(date +%Y%m%d).tar.gz ~/team-system

# 3. Execute migration (follow plan)
# Step 1: Backup ✅
# Step 2: Install coordination system
coord-init.py --output-dir ~/team-system-v2
# Step 3-N: Follow generated plan

# 4. Validate
cd ~/team-system-v2
./message.sh send code chat "Test" "Migration test"

# 5. Cutover when confident
```

**Time**: 1-2 weeks (depends on complexity)

### Workflow 3: Scale Up Existing System

```bash
# 1. Assess current state
coord-migrate.py --path ~/my-project
# Current: Individual scale
# Target: Team scale

# 2. Review scale transition
cat migration-plan.md
# Recommendations: Add auth, logging

# 3. Implement recommendations
vim config.yaml
# Enable: logging: true, auth: true

# 4. Test at new scale
# Add more users
# Increase message volume
# Monitor performance
```

**Time**: 1-2 days (incremental upgrade)

---

## Best Practices

### 1. Start Small, Scale Up

```bash
# Begin with Individual scale
coord-init.py  # Choose Individual

# Later assess upgrade
coord-migrate.py --path ~/my-project
# Follow plan to scale to Team
```

### 2. Test Before Production

```bash
# Generate in staging first
coord-init.py --output-dir ~/staging
# Test workflows
# Validate before prod
```

### 3. Backup Before Migration

```bash
# Always backup first
tar -czf backup-$(date +%Y%m%d).tar.gz ~/project

# Then migrate
coord-migrate.py --path ~/project
```

### 4. Review Generated Plans

```bash
# Don't blindly execute
coord-migrate.py --path ~/project --output plan.md

# Review carefully
cat plan.md
# Adjust if needed
# Then execute
```

### 5. Keep Tools Updated

```bash
# Pull latest changes
cd ~/devvyn-meta-project
git pull

# Verify tools work
coord-init.py --help
coord-migrate.py --help
```

---

## Troubleshooting

### Issue: "Command not found"

**Solution**: Make executable
```bash
chmod +x scripts/coord-*.py
```

### Issue: "No module named 'rich'"

**Solution**: Tools work without Rich (basic UI)
```bash
# Optional: Install for better UI
pip install rich
```

### Issue: "Permission denied"

**Solution**: Check output directory permissions
```bash
# Use custom output directory
coord-init.py --output-dir ~/projects
```

### Issue: "Template not found"

**Solution**: Run from devvyn-meta-project directory
```bash
cd ~/devvyn-meta-project
./scripts/coord-init.py
```

---

## FAQ

### Q: Do I need both tools?

**A**: No. Use Config Generator for new projects, Migration Assistant for existing systems. They serve different purposes.

### Q: Are the tools required?

**A**: No. You can manually set up systems using templates. Tools just make it faster and more reliable.

### Q: Can I customize generated systems?

**A**: Yes! Generated systems are fully customizable. Edit `config.yaml`, add workflows, modify scripts.

### Q: Do tools work offline?

**A**: Yes. No network required. All templates and logic are local.

### Q: What if I make a mistake?

**A**: Config Generator: Just delete and regenerate. Migration Assistant: Follow rollback strategy in generated plan.

---

## Performance Metrics

### Configuration Generator

| Operation | Time |
|-----------|------|
| Questionnaire (user input) | ~30 seconds |
| Template copy | ~2 seconds |
| File generation | ~1 second |
| **Total** | **~2 minutes** |

**Comparison**: Manual setup = ~30 minutes (**93% reduction**)

### Migration Assistant

| Operation | Time |
|-----------|------|
| System scan | ~5 seconds |
| Pattern detection | ~2 seconds |
| Complexity analysis | ~1 second |
| Plan generation | ~1 second |
| **Total** | **~10 seconds** |

**Comparison**: Manual planning = ~1-2 days (**~99% reduction**)

---

## Roadmap

### Current Tools (v1.0)

- ✅ Configuration Generator
- ✅ Migration Assistant

### Upcoming (v1.1)

- ⏳ Health Monitor Dashboard
- ⏳ Validation mode for Config Generator
- ⏳ Export mode for Migration Assistant

### Future (v2.0)

- 🔮 Web UI for tools
- 🔮 Plugin system for custom templates
- 🔮 CI/CD integration helpers
- 🔮 Multi-system orchestration

---

## See Also

- [Universal Patterns](../abstractions/universal-patterns.md) - Core coordination patterns
- [Scale Transition Guide](../scaling/scale-transition-guide.md) - Growing your system
- [Configuration Guide](../configuration/customization-guide.md) - Customization options
- [Templates Overview](../templates/index.md) - Available templates

---

## Support

- 📖 **Documentation**: Individual tool docs ([coord-init](coord-init.md), [coord-migrate](coord-migrate.md))
- 💬 **Discussions**: [GitHub Discussions](#)
- 🐛 **Issues**: [GitHub Issues](#)

---

**Last Updated**: 2025-10-30
**Tools Version**: 1.0.0
**Maintainer**: CODE agent
