# Claude Code Meta-Project Management Framework v2.0

## Purpose

This document establishes governance for managing multiple projects using Claude Code workflows while maintaining professional employment boundaries and scalable organization.

## Project Classification System

### Tier 1: Production Projects

- **Criteria**: Revenue-generating or employment-critical
- **Context**: Dedicated git repositories with full CI/CD
- **Claude Code Role**: Feature development, debugging, optimization
- **Review Cycle**: Exception-based monitoring with automated KPI alerts

### Tier 2: Development Projects

- **Criteria**: High potential, active development, clear roadmap
- **Context**: Git repos with basic automation
- **Claude Code Role**: Rapid prototyping, architecture decisions, code generation
- **Review Cycle**: Bi-weekly progress assessment

### Tier 3: Experimental Projects

- **Criteria**: Proof of concepts, learning exercises, exploratory work
- **Context**: Simple directories or notebooks, external project trackers optional
- **Claude Code Role**: Quick implementations, research assistance, feasibility analysis
- **Review Cycle**: Monthly viability evaluation

## Resource Allocation Framework

### Time Management

- **Maximum concurrent active projects**: 7 (3 Tier 1, 3 Tier 2, 1 Tier 3)
- **Context switching budget**: 2 hours/week maximum for project transitions
- **Employment boundary**: No personal project work during contracted hours

### Financial Controls

- **Expense tracking**: All project costs logged with category tags
- **Tax implications**: Clear separation of business vs personal development
- **Tool subscriptions**: Centralized billing with project allocation

### Cognitive Load Management

- **Claude Code session strategy**: Usage-based limits rather than simultaneous caps
- **Daily Claude Code conversation limit**: Maximum 12 active conversations per day
- **Project context switching requires explicit handoff documentation**
- **Context preservation**: Each project maintains dedicated Claude Code workspace

## Dependency Resolution Protocol

### Priority Hierarchy

1. **Tier 1 projects always win** resource conflicts with lower tiers
2. **Same-tier conflicts**: Earliest deadline gets priority
3. **Cross-tier dependencies**: Higher tier project can commandeer lower tier resources temporarily

### Blocking Resolution

- **Component needed by multiple projects**: Promote component development to highest requesting tier
- **Developer bandwidth conflicts**: Lower priority project enters hibernation until bandwidth available
- **External dependency blocks**: Affected project health status immediately goes to Yellow, Red if block >2 weeks

### Escalation Process

1. **Day 1**: Identify conflict, document in project logs
2. **Day 3**: Apply priority hierarchy, reallocate if needed
3. **Week 1**: If unresolved, consider project demotion/hibernation
4. **Week 2**: Mandatory strategic review if Tier 1 project still blocked

## Project Lifecycle Management

### Promotion Criteria (Quantitative)

- **Tier 3 → Tier 2**:
  - Minimum 40 hours committed over next 8 weeks
  - Clear deliverable milestones defined
  - No blocking dependencies on other Tier 3 projects

- **Tier 2 → Tier 1**:
  - Revenue potential >$5,000 OR employment-critical designation
  - Stakeholder buy-in confirmed
  - Development infrastructure ready (CI/CD, monitoring)

### Demotion Triggers (Automatic)

- **Any Tier**: <50% planned hours for 3 consecutive weeks
- **Tier 2/1**: Dependency blocking >1 other project for >2 weeks
- **Tier 1**: KPI failure for >4 weeks despite resource adequacy

### Lifecycle Actions

- **Termination**: Failed success criteria after resource reallocation attempt
- **Hibernation**: Temporary pause with clear restart conditions and resource reallocation plan

---

**Framework Version**: 2.0
**Last Updated**: 2025-09-25
**Integration**: Active with existing devvyn-meta-project structure
