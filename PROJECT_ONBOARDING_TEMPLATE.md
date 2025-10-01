# Project Onboarding Template - Claude Command Integration

**Framework**: Multi-Agent Collaboration v2.2
**Template Version**: 1.0
**Date**: 2025-09-28

## Quick Start (2-Hour Setup)

### Phase 1: Deploy Commands (30 minutes)

```bash
# 1. Create command directory
cd [your-project]
mkdir -p .claude/commands

# 2. Copy core commands from meta-project
cp ~/devvyn-meta-project/.claude/commands/{deploy,bridge-agent-create,session-handoff,sync-with-native}.md .claude/commands/

# 3. Optional: Add infrastructure commands
cp ~/devvyn-meta-project/.claude/commands/bridge-extraction-prep.md .claude/commands/

# 4. Verify deployment
ls .claude/commands/
```

### Phase 2: Customize Deployment Registry (30 minutes)

Edit `.claude/commands/deploy.md` to replace domain-specific components:

```bash
# Find this section in the file:
echo "📋 Specifications:"
echo "   spec-driven-development   Complete .specify/ system"
echo "   ocr-extraction-pipeline   OCR pipeline implementation"

# Replace with your project's components, for example:
echo "📊 Data Analysis Tools:"
echo "   data-processor            Core data processing pipeline"
echo "   visualization-suite       Charts and reporting toolkit"
```

**Component Categories by Project Type:**

**Scientific/Research:**

```bash
echo "🔬 Research Tools:"
echo "   data-validation           Scientific accuracy verification"
echo "   analysis-pipeline         Research data processing"
echo "   publication-toolkit       Results formatting and export"
```

**Web/API:**

```bash
echo "🌐 Web Services:"
echo "   api-endpoints             REST API implementation"
echo "   auth-system               Authentication and authorization"
echo "   deployment-pipeline       Production deployment automation"
```

**Data/Analytics:**

```bash
echo "📊 Analytics Tools:"
echo "   data-ingestion            Data source integration"
echo "   processing-pipeline       ETL and transformation"
echo "   visualization-dashboard   Reporting and charts"
```

**Utility/CLI:**

```bash
echo "🔧 Utility Tools:"
echo "   cli-interface             Command-line interface"
echo "   automation-scripts        Workflow automation"
echo "   integration-toolkit       External system connectors"
```

### Phase 3: Add Project-Specific Deployment Case (30 minutes)

Add a custom deployment case before the `*)` case in `deploy.md`:

```bash
    "[your-main-component]")
        echo
        echo "=== DEPLOYING: [Your Component Name] ==="
        echo
        echo "📦 [Your Project] Components:"
        if [ -f "[main-file]" ]; then
            echo "   ✅ Core system: [main-file]"
        else
            echo "   ❌ Core system missing"
        fi
        if [ -f "[secondary-file]" ]; then
            echo "   ✅ Support module: [secondary-file]"
        else
            echo "   ❌ Support module missing"
        fi
        echo
        echo "💡 Use: [usage instructions]"
        ;;
```

**Examples by Project Type:**

**Python Package:**

```bash
    "package-toolkit")
        echo
        echo "=== DEPLOYING: Package Toolkit ==="
        echo
        echo "📦 Python Package Components:"
        if [ -f "src/[package]/__init__.py" ]; then
            echo "   ✅ Package core: src/[package]/__init__.py"
        else
            echo "   ❌ Package core missing"
        fi
        if [ -f "pyproject.toml" ]; then
            echo "   ✅ Build config: pyproject.toml"
        else
            echo "   ❌ Build config missing"
        fi
        echo
        echo "💡 Use: pip install -e . (editable install)"
        ;;
```

**Data Analysis:**

```bash
    "data-pipeline")
        echo
        echo "=== DEPLOYING: Data Pipeline ==="
        echo
        echo "📊 Data Processing Components:"
        if [ -f "main.py" ]; then
            echo "   ✅ Main analyzer: main.py"
        else
            echo "   ❌ Main analyzer missing"
        fi
        if [ -f "data/[dataset]" ]; then
            echo "   ✅ Dataset: data/[dataset]"
        else
            echo "   ❌ Dataset missing"
        fi
        echo
        echo "💡 Use: python main.py --help for options"
        ;;
```

### Phase 4: Validation (30 minutes)

Test your command integration:

```bash
# 1. Test deployment registry
cd [your-project]
# Test in Claude Code: /deploy list

# 2. Test agent creation
# Test in Claude Code: /bridge-agent-create domain-validator "Test Agent"

# 3. Test infrastructure integration
# Test in Claude Code: /sync-with-native health-check

# 4. Test project-specific deployment
# Test in Claude Code: /deploy [your-main-component]
```

## Advanced Customization

### Agent Type Specialization

Update agent types in `.claude/commands/bridge-agent-create.md` for project-specific domains:

```bash
# Find this line:
description: Agent specialization (domain-validator, performance-benchmark, pattern-analysis, quality-reviewer)

# Customize for your domain:
# Scientific: (data-validator, experiment-runner, publication-reviewer, analysis-expert)
# Web: (api-validator, performance-tester, security-reviewer, integration-expert)
# Data: (data-validator, pipeline-optimizer, quality-reviewer, visualization-expert)
```

### Session Handoff Customization

No changes needed - `session-handoff.md` works universally with bridge path resolution.

### Infrastructure Integration

The `sync-with-native.md` command automatically detects bridge location and requires no customization.

## Project Integration Checklist

### Technical Validation

- [ ] All 4-5 core commands copied successfully
- [ ] Deployment registry lists project components correctly
- [ ] Project-specific deployment case works
- [ ] Agent creation and registration functional
- [ ] Bridge health checks pass

### Strategic Validation

- [ ] Commands reduce project setup complexity
- [ ] Agent orchestration provides value for your workflow
- [ ] Cross-session coordination addresses real needs
- [ ] Integration enhances rather than complicates development

### Documentation Updates

- [ ] Create or update project `CLAUDE.md` (root level) with command integration info
- [ ] Document agent coordination protocols for your domain
- [ ] Add usage examples specific to your project's workflow
- [ ] Test cross-session handoff scenarios

**Note**: Framework v2.2 standardizes on root-level `CLAUDE.md` files (not `.claude/CLAUDE.md`) for visibility and consistency across projects.

## Troubleshooting

### Common Issues

**Command not found:**

```bash
# Verify file exists and has correct name
ls .claude/commands/deploy.md
```

**Bridge health check fails:**

```bash
# Verify bridge system is accessible
ls ~/infrastructure/agent-bridge/bridge/ || ls ~/devvyn-meta-project/bridge/
```

**Agent creation fails:**

```bash
# Check bridge registration system
~/devvyn-meta-project/scripts/bridge-register.sh list
```

**Deployment case not working:**

```bash
# Verify syntax in deploy.md (check for missing ;; or quotes)
bash -n .claude/commands/deploy.md
```

### Rollback Procedure

If integration causes issues:

```bash
# Remove command integration
rm -rf .claude/commands/

# Or remove specific problematic commands
rm .claude/commands/[problematic-command].md
```

### Support Resources

- **Standardization Patterns**: `~/devvyn-meta-project/COMMAND_STANDARDIZATION_PATTERNS.md`
- **Bridge Documentation**: `~/infrastructure/agent-bridge/README.md`
- **Framework Guide**: `~/devvyn-meta-project/CLAUDE.md`

## Project-Specific Templates

### Template 1: Scientific Research Project

```bash
# Component categories
echo "🔬 Research Pipeline:"
echo "   data-collection           Experimental data gathering"
echo "   analysis-suite             Statistical analysis toolkit"
echo "   publication-tools          Paper and figure generation"

# Agent types
# domain-validator → research-validator
# performance-benchmark → experiment-runner
# quality-reviewer → peer-reviewer

# Deployment case
"research-pipeline")
    echo "=== DEPLOYING: Research Pipeline ==="
    # Check for analysis scripts, data files, publication tools
```

### Template 2: Web Application Project

```bash
# Component categories
echo "🌐 Web Application:"
echo "   frontend-components        UI components and styling"
echo "   backend-services           API and business logic"
echo "   deployment-config          Production deployment setup"

# Agent types
# domain-validator → api-validator
# performance-benchmark → load-tester
# quality-reviewer → security-reviewer

# Deployment case
"web-application")
    echo "=== DEPLOYING: Web Application ==="
    # Check for frontend, backend, config files
```

### Template 3: Data Science Project

```bash
# Component categories
echo "📊 Data Science:"
echo "   data-ingestion             Source data collection and cleaning"
echo "   model-training             ML model development and training"
echo "   visualization-tools        Charts, dashboards, and reporting"

# Agent types
# domain-validator → data-validator
# performance-benchmark → model-optimizer
# quality-reviewer → analysis-reviewer

# Deployment case
"data-science")
    echo "=== DEPLOYING: Data Science Pipeline ==="
    # Check for notebooks, models, data files
```

## Success Metrics

### Implementation Success

- [ ] 2-hour setup time achieved
- [ ] All commands functional in target project
- [ ] Project-specific components correctly identified
- [ ] Agent coordination working for project workflow

### Strategic Success

- [ ] Framework adoption improves development velocity
- [ ] Multi-agent coordination reduces coordination overhead
- [ ] Command patterns encode valuable project workflows
- [ ] Integration demonstrates competitive advantage

---

**Next Steps After Onboarding:**

1. Use `/deploy list` to verify your components
2. Create domain-specific agents with `/bridge-agent-create`
3. Test cross-session coordination with `/session-handoff`
4. Monitor system health with `/sync-with-native health-check`

**Framework Evolution:**
Your project is now part of the v2.2 multi-agent collaboration framework. As you use these commands, document patterns that could benefit other projects for future framework enhancements.
