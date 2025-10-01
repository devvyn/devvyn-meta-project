# AAFC-SRDC Work Context and Obligations

**Decision Domain**: Professional Work Guidelines
**Classification**: PRIVATE (work context, not confidential)
**Last Updated**: 2025-10-01
**Applies To**: All AAFC-SRDC salary work sessions

## Contract Obligations

### Professional Accountability

- **Work hours tracking**: All work sessions logged to `.kb-context/work-sessions.log`
- **Deliverables**: Concrete, version-controlled outputs with provenance
- **Quality standards**: Production-ready scientific data processing
- **Reproducibility**: Complete documentation of processing chains

### Data Classification

- **Public scientific data**: PUBLISHED tier (herbarium specimens, Darwin Core exports)
- **Work products**: Open source, publicly accessible on GitHub
- **Infrastructure**: PRIVATE tier (meta-project coordination, not for public distribution)

### Time Management

- **Session tracking**: Start time, tasks, artifacts, duration
- **Accountability**: Work session IDs (e.g., code-37834-aafc-work-session)
- **Bridge registration**: All work sessions registered with agent identity
- **Workspace**: AAFC-SRDC Saskatoon Research Centre context

## Development Guidelines

### Scientific Accuracy Requirements

- **Taxonomic validation**: Human expert review required
- **Darwin Core compliance**: GBIF standards for biodiversity data
- **Quality thresholds**: OCR accuracy, field extraction validation
- **Stakeholder communication**: AAFC leadership approval on outputs

### Technical Standards

- **Code quality**: Ruff linting, comprehensive testing
- **Performance**: Optimize for 5,000+ specimen processing
- **Error handling**: Graceful failures, comprehensive logging
- **Documentation**: Clear technical handoff for successor teams

### Deliverable Requirements

- **Version control**: All work in git with clear commit messages
- **Provenance tracking**: Agent identity, processing tools, session context
- **Output formats**: GBIF-compliant Darwin Core Archives
- **Stakeholder packages**: Executive summaries, technical documentation

## Automation Boundaries (AAFC Work)

### Fully Automated (Tier 1)

- Work session logging and time tracking
- Git commits for code/documentation with provenance
- File organization following documented patterns
- Testing and quality assurance workflows

### Notification Required (Tier 2)

- Pattern application with 50-90% confidence
- Non-critical file cleanup operations
- Cross-project knowledge base updates

### Human Approval Required (Tier 3)

- Stakeholder communications
- Production configuration changes
- Scientific validation decisions
- Budget or resource allocation

## Strategic Context

### Project Goals

- **Primary**: Darwin Core extraction from herbarium specimens
- **Technical**: OCR optimization, quality control automation
- **Scientific**: Publication-ready biodiversity data for GBIF
- **Institutional**: Demonstrate AAFC digital capacity

### Success Metrics

- **Processing capacity**: 5,000+ specimens efficiently
- **Accuracy**: Taxonomic validation by scientific team
- **Compliance**: GBIF data standards met
- **Stakeholder satisfaction**: AAFC leadership approval

### Collaboration Model

- **Agent authority**: Technical implementation, optimization
- **Human authority**: Scientific validation, stakeholder relations
- **Shared decisions**: Architecture, priorities, quality standards

## Knowledge Base Usage

### Answering Development Questions

```bash
# Check work obligations
~/devvyn-meta-project/knowledge-base/search/kb-search.sh "obligations"

# Find automation boundaries
~/devvyn-meta-project/knowledge-base/search/kb-search.sh "approval required"

# Review data classification
~/devvyn-meta-project/knowledge-base/search/kb-search.sh "classification"
```

### Common Queries

- "What requires human approval?" → See Automation Boundaries section
- "How should I track work time?" → See Professional Accountability section
- "What are the quality standards?" → See Technical Standards section
- "Can I automate this decision?" → See Automation Boundaries section

---

**Source**: AAFC-SRDC work session practices, security manifest, decision patterns
**Confidence**: HIGH (95%) - extracted from documented user behavior and stated policies
**Review Cycle**: Update when work practices or requirements change
