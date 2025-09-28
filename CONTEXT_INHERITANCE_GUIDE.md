# Context Inheritance Guide - CLAUDE.md Resolution

**Purpose**: Define how Claude agents resolve context across the multi-level project hierarchy
**Last Updated**: 2025-09-27

## Context Resolution Order

Claude agents should read context files in this **exact order**, with later files **overriding** earlier ones:

### **Level 1: User Global Preferences**
**File**: `~/.claude/CLAUDE.md`
**Scope**: All sessions, all projects
**Content**: Tool preferences, global settings
**Current Settings**:
- `use uv tools to help you on the command line`
- `find` is aliased to `fd` so use `fd`
- `my overall work documents are tracked in the local devvyn-meta-project directory`

### **Level 2: Meta-Project Coordination**
**File**: `~/devvyn-meta-project/CLAUDE.md`
**Scope**: Coordination infrastructure for all sub-projects
**Content**: Bridge protocols, multi-agent coordination, framework rules
**Critical Requirements**:
- Bridge v3.0 sync protocol (MANDATORY for all sub-projects)
- Agent authority domains
- Communication protocols
- Emergency procedures

### **Level 3: Project-Specific Context**
**Files**:
- `~/Documents/GitHub/[project]/CLAUDE.md`
- `~/Documents/GitHub/[project]/.claude/CLAUDE.md`

**Scope**: Individual project requirements
**Content**: Project-specific patterns, domain knowledge, review requests

## Current Project Hierarchy

```
~/.claude/CLAUDE.md                                    # Level 1: User
└── ~/devvyn-meta-project/CLAUDE.md                   # Level 2: Meta
    ├── ~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/CLAUDE.md
    ├── ~/Documents/GitHub/s3-image-dataset-kit/CLAUDE.md
    ├── ~/Documents/GitHub/music-library-data/CLAUDE.md
    └── ~/Documents/GitHub/vmemo-py/CLAUDE.md
```

## Inheritance Rules

### **Additive Inheritance**
- Tool preferences (Level 1) + Coordination protocols (Level 2) + Project specifics (Level 3)
- Each level **adds** to the context without overriding previous levels

### **Override Hierarchy**
- **Project-specific requirements** override meta-project defaults
- **Meta-project coordination** overrides user preferences when conflicts arise
- **User preferences** are baseline for all non-conflicting settings

### **Critical Requirements (Never Override)**
From Level 2 (Meta-Project), these are **MANDATORY** for all sub-projects:
- Bridge v3.0 sync protocol
- Agent registration requirements
- Collision-safe communication protocols
- TLA+ verification standards

## Agent Onboarding by Location

### **Working in Meta-Project Directory**
```bash
# Agent reads:
1. ~/.claude/CLAUDE.md              # User preferences
2. ./CLAUDE.md                      # Meta-project coordination (THIS DIR)

# Required actions:
- Follow Bridge v3.0 sync protocol
- Register with agent registry
- Use collision-safe messaging
```

### **Working in Sub-Project Directory**
```bash
# Agent reads:
1. ~/.claude/CLAUDE.md                           # User preferences
2. ~/devvyn-meta-project/CLAUDE.md              # Meta coordination
3. ./CLAUDE.md                                   # Project specifics

# Required actions:
- Follow ALL meta-project coordination requirements
- Add project-specific context
- Maintain bridge connectivity to meta-project
```

## Context Conflicts Resolution

### **Tool Preferences**
- **User**: "use uv tools" → **All projects inherit this**
- **Meta**: Bridge scripts → **All projects inherit this**
- **Project**: Project-specific tools → **Only that project**

### **Authority Domains**
- **User**: Final approval authority → **All projects**
- **Meta**: Agent coordination rules → **All projects**
- **Project**: Domain-specific expertise → **Only that project**

### **Communication Protocols**
- **Meta**: Bridge v3.0 MANDATORY → **All projects**
- **Project**: Additional communication channels → **Additive only**

## Implementation Guide

### **For New Projects**
When creating a new project under `~/Documents/GitHub/`:

1. **Always create project CLAUDE.md** with inheritance header:
```markdown
# Project Instructions - [Project Name]

**Context Level**: 3 (Project-Specific)
**Inherits From**: `~/devvyn-meta-project/CLAUDE.md` (Meta-project coordination)
**Meta Requirements**: Bridge v3.0 sync MANDATORY

[project-specific content]
```

2. **Reference meta-project coordination**:
```markdown
## Coordination Requirements

This project inherits all coordination requirements from the meta-project:
- Bridge v3.0 sync protocol
- Multi-agent communication standards
- TLA+ verification compliance

See: `~/devvyn-meta-project/CLAUDE.md` for complete coordination protocols.
```

### **For Agent Context Loading**
Claude agents should use this startup sequence:

```bash
# 1. Load user preferences
if [ -f ~/.claude/CLAUDE.md ]; then
    echo "Loading user preferences..."
fi

# 2. Load meta-project coordination (if applicable)
if [ -f ~/devvyn-meta-project/CLAUDE.md ]; then
    echo "Loading meta-project coordination..."
    # MANDATORY: Run bridge sync if working in any GitHub project
    if [[ "$PWD" == *"/Documents/GitHub/"* ]]; then
        echo "GitHub project detected - Bridge v3.0 sync required"
    fi
fi

# 3. Load project-specific context
if [ -f ./CLAUDE.md ]; then
    echo "Loading project-specific context..."
fi
```

## Troubleshooting

### **Context Not Loading**
**Problem**: Agent doesn't seem aware of bridge protocols
**Solution**: Check if agent is reading meta-project CLAUDE.md
```bash
# Verify context inheritance
echo "Current directory: $PWD"
echo "Meta-project context exists: $([ -f ~/devvyn-meta-project/CLAUDE.md ] && echo 'YES' || echo 'NO')"
echo "Project context exists: $([ -f ./CLAUDE.md ] && echo 'YES' || echo 'NO')"
```

### **Conflicting Instructions**
**Problem**: Project requirements conflict with meta-project requirements
**Resolution**: Meta-project coordination requirements ALWAYS win for:
- Bridge communication protocols
- Agent registration
- Multi-agent coordination
- Security/collision prevention

### **Missing Bridge Access**
**Problem**: Sub-project agent can't access bridge system
**Solution**: Bridge access is relative to meta-project:
```bash
# From any sub-project
~/devvyn-meta-project/scripts/bridge-send.sh sender recipient priority "title"
```

## Best Practices

### **Documentation Maintenance**
- Keep user preferences minimal and stable
- Update meta-project coordination for framework changes
- Keep project-specific context focused on domain knowledge

### **Context Testing**
- Test new agent onboarding from each project directory
- Verify bridge connectivity from sub-projects
- Validate context inheritance chain

### **Evolution Management**
- User preferences change rarely
- Meta-project coordination evolves with framework versions
- Project-specific context evolves with project needs

---

## Summary

**Context inheritance ensures**:
1. ✅ **Consistent tool usage** across all projects (uv, fd)
2. ✅ **Universal coordination** via Bridge v3.0 protocols
3. ✅ **Project flexibility** for domain-specific requirements
4. ✅ **No coordination conflicts** between projects
5. ✅ **Scalable architecture** as project portfolio grows

**The hierarchy works because each level has a clear, non-overlapping purpose.**