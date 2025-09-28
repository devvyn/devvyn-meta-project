# Claude Agent Instructions - Devvyn Meta Project

**Context Level**: 2 (Meta-Project Coordination)
**Inherits From**: `~/.claude/CLAUDE.md` (User preferences)
**Inherited By**: All sub-projects in `~/Documents/GitHub/`

**Project Type**: Meta-project coordination system
**Framework**: Multi-Agent Collaboration v2.1
**Bridge System**: v3.0 (Collision-Safe)
**Last Updated**: 2025-09-27

## Essential Agent Onboarding

### **FIRST: Context Inheritance Check** ⚠️

**Agent Context Resolution Order:**
1. User preferences: `~/.claude/CLAUDE.md` (tools: uv, fd aliasing)
2. **THIS FILE**: Meta-project coordination (Bridge v3.0 protocols)
3. Project-specific: `~/Documents/GitHub/[project]/CLAUDE.md`

### **SECOND: Bridge v3.0 Sync Protocol** ⚠️

**If working in meta-project OR any sub-project, ALL Claude Code agents MUST sync:**

```bash
# 1. Verify bridge version (must be 3.0)
cat bridge/registry/agents.json | jq '.registry_version'

# 2. Register your agent session
./scripts/bridge-register.sh register code

# 3. Check for pending messages addressed to you
./scripts/bridge-receive.sh code

# 4. Verify collision-safe operations are available
ls scripts/bridge-send.sh scripts/bridge-receive.sh
```

**Why Critical**: This project coordinates ALL sub-projects (AAFC Herbarium, S3 Image Dataset Kit, etc.). Race conditions here corrupt everything downstream.

## Project Context

### **Purpose**: Operating System for Multi-Agent Collaboration
This meta-project provides the coordination infrastructure that all other projects depend on. Changes here cascade to:

- `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/`
- `~/Documents/GitHub/s3-image-dataset-kit/`
- `~/Documents/GitHub/python-toolbox-devvyn/`
- `~/Documents/GitHub/claude-code-hooks/`

### **Human Context**: Devvyn Murphy
- **Location**: Saskatoon, Saskatchewan, CA
- **Work Style**: Values directness, resists over-engineering
- **Schedule**: Currently on break until Monday (perfect for infrastructure work)
- **Preference**: Foundation-first approach - get the coordination right, then scale

## Authority Domains

### **Your Domain (Code Agent)**
- Technical implementation of coordination protocols
- Bridge system maintenance and optimization
- TLA+ formal verification updates
- Multi-agent testing and validation
- Script automation and tooling

### **Chat Agent Domain**
- Strategic framework evolution
- Cross-project pattern recognition
- Portfolio management decisions
- Framework version planning

### **Human Domain**
- Final approval on framework changes
- Business priority setting
- Quality standards definition
- Domain expertise validation

## Communication Protocols

### **Sending Messages (v3.0 ONLY)**
```bash
# NEVER write directly to bridge directories
# ALWAYS use atomic operations:

./scripts/bridge-send.sh code chat HIGH "Framework Update" update.md
./scripts/bridge-send.sh code human CRITICAL "Approval Needed" proposal.md
./scripts/bridge-send.sh code gpt NORMAL "Documentation Request" specs.json
```

### **Processing Messages**
```bash
# Check for work
./scripts/bridge-receive.sh code

# Process specific high-priority message
./scripts/bridge-receive.sh code specific-message-id
```

### **Agent Status**
```bash
# Check all agents
./scripts/bridge-register.sh list

# Get your status
./scripts/bridge-register.sh status code
```

## Key Files & Directories

### **Core Infrastructure**
- `bridge/` - v3.0 communication system (collision-safe)
- `agents/` - Agent instruction files for all agent types
- `scripts/` - Atomic operation scripts (REQUIRED for bridge v3.0)
- `COORDINATION_PROTOCOL.md` - Canonical reference

### **Framework Documentation**
- `rules/project-management-framework-v2.md` - Portfolio management
- `status/current-project-state.json` - Real-time project health
- `key-answers.md` - Strategic decision log

### **Formal Verification**
- `ClaudeCodeSystem.tla` - TLA+ specification (updated for 5-agent system)
- `claude_code_system.cfg` - Model checker configuration
- `TLA_VERIFICATION_FINAL_REPORT.md` - Verification results

## Common Tasks

### **Framework Updates**
1. Check `status/current-project-state.json` for pending decisions
2. Review `key-answers.md` for strategic context
3. Implement changes with proper testing
4. Update TLA+ specification if coordination changes
5. Notify Chat agent via bridge message

### **Sub-Project Support**
1. Read project-specific `CLAUDE.md` files in sub-projects
2. Check for review requests: `## Review Requests for Code Agent`
3. Provide technical implementation support
4. Coordinate via bridge system for complex changes

### **Bridge System Maintenance**
1. Monitor queue health: `ls bridge/queue/pending/ | wc -l`
2. Check agent registrations: `./scripts/bridge-register.sh list`
3. Verify no collision errors in recent activity
4. Update formal verification if protocol changes

## Emergency Procedures

### **Bridge System Issues**
```bash
# Check system health
./scripts/bridge-register.sh list
cat bridge/registry/queue_stats.json

# Clear processing locks (if deadlocked)
rm -f bridge/queue/processing/*.lock

# Restart agent registration
./scripts/bridge-register.sh unregister code
./scripts/bridge-register.sh register code
```

### **TLA+ Verification Failure**
1. Check `ClaudeCodeSystem.tla` for syntax errors
2. Verify `claude_code_system.cfg` constants match current agents
3. Run model checker: `java -jar tla2tools.jar -config claude_code_system.cfg ClaudeCodeSystem.tla`
4. Update invariants if new coordination patterns added

## Quality Standards

### **Code Quality**
- All bridge operations MUST be atomic (use provided scripts)
- No direct file writes to bridge directories
- TLA+ specification MUST remain valid
- Comprehensive testing for multi-agent scenarios

### **Documentation Quality**
- Update `COORDINATION_PROTOCOL.md` for any protocol changes
- Maintain bridge README for operational changes
- Keep agent instruction files current
- Document performance characteristics

### **Collaboration Quality**
- Register agent session before starting work
- Process pending messages before new tasks
- Use meaningful message titles and priorities
- Archive processed messages properly

## Warning Signs

**Immediately escalate to Chat agent if you observe:**
- Messages being lost or overwritten
- Bridge queue growing without processing
- Agent registration failures
- TLA+ verification failures
- Sub-project coordination breakdowns

**These indicate systemic issues that affect ALL projects.**

## Integration Notes

### **New Agent Types**
- Update `bridge/registry/agents.json` with capabilities
- Add agent to `ClaudeCodeSystem.tla` constants
- Create agent instruction file in `agents/`
- Test collision scenarios with new agent

### **New Sub-Projects**
- Ensure they inherit bridge v3.0 protocols
- Add coordination patterns to framework
- Update portfolio tracking in `status/`
- Test cross-project message flows

---

## Session Startup Checklist

**Every time you start work:**

1. ✅ **Bridge Sync**: Run the 4-command sync protocol above
2. ✅ **Check Messages**: `./scripts/bridge-receive.sh code`
3. ✅ **Review Status**: Read `status/current-project-state.json`
4. ✅ **Check Priorities**: Review `key-answers.md` for strategic context
5. ✅ **Register Session**: Ensure you're registered with bridge system

**Ready to work safely in the multi-agent ecosystem!** 🚀

---

**Meta-Project Status**: Production-ready coordination system with formal verification guarantees. All downstream projects inherit collision-safe collaboration protocols.