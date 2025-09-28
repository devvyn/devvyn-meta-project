# Multi-Agent Collaboration Framework

A comprehensive framework for human-agent collaboration with integrated specification-driven development, project management, and automated documentation generation.

## 🚀 Key Features

### **Specification-Driven Development**
- Integration with **GitHub spec-kit** for formal requirement management
- Constitutional governance preserving domain expertise
- Clear authority domains: human requirements ↔ agent implementation
- Quality gates preventing scope creep and requirement drift

### **Human-Agent Collaboration**
- Chat ↔ Code handoff protocols with clear authority boundaries
- Multi-agent specification pipeline: `/specify → /plan → /tasks → /implement`
- Inclusive collaboration design serving shared benefit
- Real-time project state tracking and decision management

### **Project Management**
- Tiered capacity management with quantitative limits
- Framework for quality-critical projects with domain expertise requirements
- Template patterns for different project types
- Automated quality gates and constitutional principles

### **Documentation System**
- Automated HTML generation from markdown sources
- Visual styling consistent with collaboration frameworks
- Live conversion with watch mode for active editing
- Cross-platform documentation deployment

## 📁 Structure

- `/rules/` - Framework specifications, coding standards, and project structure
- `/templates/` - Reusable project templates and session handoff protocols  
- `/agents/` - Human-agent collaboration patterns and integration frameworks
- `/status/` - Project state tracking and spec-driven development documentation
- `/doc-templates/` - Automated documentation generation templates
- `/devvyn_meta_project/` - Python package for framework utilities

## ⚡ Quick Start

### Prerequisites
- Python 3.11+ with [uv](https://github.com/astral-sh/uv) package manager
- Node.js for documentation generation
- Git for version control

### Installation
```bash
# Clone the repository
git clone https://github.com/devvyn/devvyn-meta-project.git
cd devvyn-meta-project

# Install Python dependencies
uv sync --extra dev --extra docs

# Install documentation tools
npm install

# Set up documentation generation
./setup-docs.sh
```

### Usage
```bash
# Generate documentation
npm run convert

# Watch for changes during editing
npm run watch

# View generated documentation
open docs-html/index.html
```

## 🔧 Spec-Kit Integration

This framework integrates with [GitHub's spec-kit](https://github.com/github/spec-kit) for specification-driven development:

```bash
# Install spec-kit
uv tool install spec-kit

# Initialize project specifications
cd your-project
spec init

# Create feature specifications
spec create feature-name
```

### Integration Pattern
1. **Constitutional Principles**: Define domain expertise boundaries in `.specify/memory/constitution.md`
2. **Feature Specifications**: Create formal requirements using spec templates
3. **Quality Gates**: Implement specification completeness checks before implementation
4. **Authority Domains**: Maintain clear separation between human requirements and agent implementation

## 📊 Framework Benefits

### Before Integration
- Requirement ambiguity leading to rework cycles
- Mixed authority domains causing collaboration friction
- Ad-hoc decision making without guiding principles
- Quality inconsistency across project phases

### After Integration
- Constitutional framework guides all development decisions
- Testable requirements established before implementation
- Clear authority domains (domain expertise vs technical implementation)
- Quality gates prevent scope creep and requirement drift

## 🎯 Application Scenarios

- **Domain-Expert Projects**: Requiring specialized validation and expertise preservation
- **Quality-Critical Outputs**: With measurable success criteria and formal requirements
- **Complex Requirements**: Multiple stakeholder types with clear authority boundaries
- **Multi-Agent Collaboration**: Human-agent teams with specification-driven workflows

## 📚 Documentation

- **[Documentation System Guide](DOCS-README.md)** - Automated HTML generation setup
- **[Spec-Driven Development](status/spec-driven-development-advantage.md)** - Integration patterns and benefits
- **[Framework Specifications](rules/)** - Core framework rules and standards
- **[Collaboration Patterns](agents/)** - Human-agent collaboration frameworks

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch with spec-driven development
3. Follow the constitutional principles in your domain
4. Submit a pull request with specification documentation

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Projects

- [GitHub Spec-Kit](https://github.com/github/spec-kit) - Formal specification framework
- [uv](https://github.com/astral-sh/uv) - Fast Python package manager
- [Claude Code](https://docs.claude.com/en/docs/claude-code) - AI-powered development assistant

---

**Framework Status**: Production Ready with Spec-Kit Integration  
**Version**: 2.1+ with specification-driven development  
**Maintenance**: Actively developed and maintained