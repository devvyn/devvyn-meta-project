# Agent Capability Discovery System

**Version**: 1.0
**Created**: 2025-10-06
**Purpose**: Cross-context capability awareness for multi-agent collaboration

---

## What Is This?

A **file-based capability manifest system** that allows agents to discover what they and other agents can do across different contexts and platforms.

**The Problem**: Chat on desktop has different capabilities than Chat on mobile. Code CLI has different tools than Chat. Agents need to know what's possible in each context.

**The Solution**: YAML-based capability documentation with discovery script.

---

## Quick Start

### List all agent contexts

```bash
./scripts/capability-check.sh list
```

### Check what an agent can do

```bash
./scripts/capability-check.sh code-cli
./scripts/capability-check.sh chat-mobile
```

### Query specific capability

```bash
./scripts/capability-check.sh chat-mobile "bridge send"
./scripts/capability-check.sh code-cli "git operations"
```

### Compare two agents

```bash
./scripts/capability-check.sh compare code-cli chat-desktop
```

### See who can do what

```bash
./scripts/capability-check.sh matrix bridge_integration
./scripts/capability-check.sh matrix git_operations
```

---

## File Structure

```
agents/capabilities/
├── README.md               # This file
├── manifest.yaml          # Cross-context compatibility matrix
├── code-cli.yaml          # Claude Code CLI capabilities
├── chat-desktop.yaml      # Claude Chat Desktop capabilities
├── chat-mobile.yaml       # Claude Chat Mobile (iPhone) capabilities
└── investigator.yaml      # INVESTIGATOR Agent capabilities
```

**Pattern**: One YAML file per agent context.

---

## Agent Contexts

### code-cli (Claude Code CLI)

- **Platform**: macOS native shell
- **Strengths**: Git operations, file system, command execution
- **Limitations**: No web access, no MCP tools
- **Bridge**: Full send/receive

### chat-desktop (Claude Chat Desktop)

- **Platform**: macOS Claude App
- **Strengths**: Web access, osascript, MCP tools, strategic analysis
- **Limitations**: No git operations
- **Bridge**: Full send/receive via osascript

### chat-mobile (Claude Chat Mobile)

- **Platform**: iOS Claude App
- **Strengths**: Mobile accessibility, web research
- **Limitations**: Read-only, no file write, no script execution
- **Bridge**: Read-only (if iCloud synced)
- **Status**: UNVERIFIED - needs real-world testing

### investigator (INVESTIGATOR Agent)

- **Platform**: macOS LaunchAgent (scheduled)
- **Strengths**: Pattern detection, event analysis, autonomous operation
- **Limitations**: Read-only, report generation only
- **Bridge**: Partial (inbox exists, but minimal integration)

---

## Capability Categories

Each agent is documented across these dimensions:

1. **bridge_integration** - Send/receive messages via bridge system
2. **file_operations** - Read/write/edit files
3. **command_execution** - Bash commands and script execution
4. **git_operations** - Commit, push, PR creation
5. **web_access** - Web search, URL fetching
6. **code_execution** - Python, bash, build systems
7. **system_control** - LaunchAgent management, system config

---

## YAML Structure

Each agent capability file follows this structure:

```yaml
agent:
  id: agent-id
  name: Human Readable Name
  platform: macos|ios
  runtime: description

# For each capability category
bridge_integration:
  status: full|limited|partial|read_only|none
  capabilities:
    - list_of_specific_capabilities

  method: how_it_works
  examples:
    - working_examples

  limitations:
    - what_doesnt_work

# Repeat for other categories
# ...

unique_strengths:
  - what_makes_this_agent_special

integration_patterns:
  with_other_agent:
    description: how_they_coordinate

version_history:
  "1.0":
    date: YYYY-MM-DD
    changes: description
```

---

## Discovery Patterns

### Self-Discovery

Agents can read their own capability file to understand current context:

```bash
# In any agent
cat ~/devvyn-meta-project/agents/capabilities/[agent-id].yaml
```

### Cross-Context Discovery

Agents can check what other agents can do:

```bash
# Code agent checking if Chat can send bridge messages
./scripts/capability-check.sh chat-desktop "bridge send"

# Chat checking if Code can do git operations
./scripts/capability-check.sh code-cli git
```

### Platform Awareness

Before requesting work from another agent, check if they can do it:

```bash
# Can mobile chat send a bridge message?
./scripts/capability-check.sh chat-mobile "bridge send"
# Result: status: none (can't do it)
```

---

## Use Cases

### 1. Cross-Platform Coordination

**Scenario**: Human on iPhone wants to send strategic guidance to Code agent.

**Discovery**:

```bash
./scripts/capability-check.sh chat-mobile "bridge send"
# Result: status: none
```

**Outcome**: Chat mobile reads inbox (if synced), discusses with human, execution deferred to desktop.

---

### 2. Capability-Aware Task Routing

**Scenario**: Need web research for technical decision.

**Discovery**:

```bash
./scripts/capability-check.sh compare code-cli chat-desktop
# Result: code-cli web_access: none, chat-desktop web_access: full
```

**Outcome**: Code sends research request to Chat via bridge.

---

### 3. Platform Migration

**Scenario**: Agent conversation started on desktop, continued on mobile.

**Discovery**: Agent reads capability file and adjusts behavior based on context.

**Outcome**:

- Desktop: Full interaction, bridge messaging, file ops
- Mobile: Read-only monitoring, conversation, defer execution

---

## Verification Status

| Agent | Verified | Date | Method |
|-------|----------|------|--------|
| code-cli | ✅ Yes | 2025-10-06 | Direct testing |
| chat-desktop | ✅ Yes | 2025-10-03 | Capability assessment |
| chat-mobile | ❌ No | - | Speculative (needs iPhone testing) |
| investigator | ✅ Yes | 2025-10-06 | Operational testing |

---

## Maintenance

### When to Update

**Add new agent context**:

1. Create `[agent-id].yaml` following structure
2. Add to `manifest.yaml`
3. Test with `capability-check.sh`
4. Update this README

**Capability changes**:

1. Update relevant `.yaml` file
2. Update `version_history` section
3. Re-verify if significant change

**Platform changes**:

1. iOS app gets MCP tools → Update `chat-mobile.yaml`
2. New tool availability → Update relevant agent files

### Review Schedule

- **Quarterly**: Review all capability files for accuracy
- **After framework changes**: Update affected capabilities
- **New agent types**: Document immediately
- **Platform updates**: Check for new capabilities

---

## Philosophy

**Simple file-based approach**:

- ✅ YAML for machine readability
- ✅ Human-readable structure
- ✅ Version controlled
- ✅ Self-documenting
- ✅ No database, no API, just files

**Discoverable knowledge**:

- Agents know what they can do
- Agents know what others can do
- Cross-platform awareness
- Capability-driven coordination

**Evidence-based**:

- Document verified capabilities
- Mark unverified as such
- Update as testing confirms
- Version tracking

---

## Future Enhancements

### Potential Additions

1. **Automated Verification**
   - Script to test documented capabilities
   - Confirm agent context matches docs
   - Alert on capability drift

2. **Capability Negotiation**
   - Agent requests capability
   - System routes to capable agent
   - Automatic fallback patterns

3. **Mobile Testing**
   - Verify iPhone chat capabilities
   - Document actual vs. speculative
   - Update chat-mobile.yaml with reality

4. **API Query Interface**
   - `capability-check.sh` with JSON output
   - Programmatic capability queries
   - Integration with other scripts

---

## Quick Reference

```bash
# List all agents
./scripts/capability-check.sh list

# Agent summary
./scripts/capability-check.sh [agent]

# Query capability
./scripts/capability-check.sh [agent] [query]

# Compare agents
./scripts/capability-check.sh compare [agent1] [agent2]

# Capability matrix
./scripts/capability-check.sh matrix [capability]
```

**Capability file location**: `~/devvyn-meta-project/agents/capabilities/[agent-id].yaml`

**Discovery script**: `~/devvyn-meta-project/scripts/capability-check.sh`

---

## Integration with Bridge System

Capability discovery **complements** bridge messaging:

**Bridge**: *How* agents coordinate (message passing)
**Capabilities**: *What* agents can do (context awareness)

**Together**: Agents know what to ask whom, and how to route requests effectively.

---

**Status**: Production-ready capability discovery system
**Next**: Test on iPhone to verify chat-mobile capabilities
