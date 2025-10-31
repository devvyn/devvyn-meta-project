# Software Development Coordination Template

**Domain**: Software engineering, feature development, bug fixes, releases

**Use Case**: Coordinate multi-agent software development workflows from planning through deployment

---

## Agent Roles

### 1. **Architect Agent**
- **Authority**: System design, architecture decisions, technical strategy
- **Escalates to**: Human (Tech Lead) for major architectural changes

### 2. **Code Agent**
- **Authority**: Implementation, testing, debugging, refactoring
- **Escalates to**: Architect for design questions

### 3. **Review Agent**
- **Authority**: Code review, quality gates, best practices enforcement
- **Escalates to**: Human for controversial changes

### 4. **DevOps Agent**
- **Authority**: Deployment, infrastructure, monitoring, performance
- **Escalates to**: Human for production changes

### 5. **Human (Tech Lead)**
- **Authority**: Final decisions, customer requirements, team coordination

---

## Workflows

### Feature Development
```
Human: Define requirement
    ↓
Architect: Design solution
    ↓
Code: Implement feature
    ↓
Review: Code review
    ↓
Code: Address feedback
    ↓
DevOps: Deploy to staging
    ↓
Human: Approve for production
    ↓
DevOps: Deploy to production
```

### Bug Fix
```
Human: Report bug
    ↓
Code: Reproduce and diagnose
    ↓
Code: Implement fix
    ↓
Review: Quick review
    ↓
DevOps: Hotfix deployment
```

### Release
```
Architect: Plan release
    ↓
Code: Feature freeze
    ↓
Review: Final code review
    ↓
DevOps: Build release candidate
    ↓
Human: QA approval
    ↓
DevOps: Production release
    ↓
DevOps: Monitor rollout
```

---

## Configuration

```yaml
project:
  name: "Your Software Project"
  repository: "github.com/your-org/your-project"
  tech_stack: ["Python", "FastAPI", "PostgreSQL", "Docker"]

agents:
  architect:
    authority_domains: ["system_design", "architecture", "tech_stack"]
    tools: ["diagrams", "adr", "design_docs"]

  code:
    authority_domains: ["implementation", "testing", "debugging"]
    tools: ["git", "ide", "pytest", "mypy"]

  review:
    authority_domains: ["code_review", "quality_gates", "best_practices"]
    tools: ["ruff", "mypy", "coverage", "sonarqube"]

  devops:
    authority_domains: ["deployment", "infrastructure", "monitoring"]
    tools: ["docker", "kubernetes", "terraform", "datadog"]

quality_gates:
  code_quality:
    test_coverage: "> 80%"
    type_coverage: "> 90%"
    linting: "zero warnings"
    security_scan: "zero critical vulnerabilities"

  deployment:
    staging_tests: "all pass"
    performance_regression: "< 5%"
    security_check: "OWASP top 10 clear"
```

---

## Success Metrics

- **Velocity**: 2x faster feature development
- **Quality**: 50% fewer bugs in production
- **Deployment**: 10x more frequent releases
- **Review time**: 75% faster code review cycle

---

**Version**: 1.0
**Last Updated**: 2025-10-30
