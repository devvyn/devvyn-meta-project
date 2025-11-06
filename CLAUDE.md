# Meta-Project Coordination - Code Agent

**Platform**: Ludarium Behavioral Coordination Platform

## ORIENTATION

Context: Multi-agent coordination system for all sub-projects
Bridge: `~/infrastructure/agent-bridge/bridge/` (CANONICAL - The Substrate)
Authority: Technical implementation, bridge maintenance, formal verification
Escalate to Chat: Strategic decisions, cross-project patterns, framework changes

**See also**: PLATFORM_NOMENCLATURE.md for complete naming system (The Seven-Layer Stack, The Mirroring)

## INVARIANTS

```tla
\* Session prerequisites
SessionActive ⇒ (Registered ∧ MessagesChecked ∧ BridgeAccessible)

\* Bridge operation safety
∀ op ∈ BridgeOps: UsesAtomicScript(op) ∧ ¬DirectFileWrite

\* Escalation triggers
MessagesLost ∨ QueueGrowing ∨ RegistrationFails ∨ TLAFails
  ⇒ ◇NotifyChatAgent

\* Zen minimalism (anti-cruft)
∀ file ∈ AgentInstructions:
  ContainsOnlyBehavior(file) ∧ ¬ContainsRationale(file)
  ∧ Length(file) < 200 \* lines

\* Workspace boundaries
∀ f ∈ metaFiles : ∀ sp ∈ SubProjects : f ∉ subFiles[sp]
∀ sp ∈ SubProjects : ∀ f ∈ subFiles[sp] : SecurityLevel(f) ≠ SECRET
```

## WORKSPACE BOUNDARIES

**Formal specification**: [WORKSPACE_BOUNDARIES.md](./WORKSPACE_BOUNDARIES.md)

**Meta-project authority** (coordination):
- Agent instructions, patterns, shared tools
- Service registry, bridge protocol
- Security infrastructure

**Sub-project authority** (domain implementation):
- Domain-specific code, tests, docs
- Production configurations, scientific validation

**Key rules**:
- No file path overlaps (except WORKSPACE_BOUNDARIES.md mirrored)
- Credentials ONLY in meta-project (~/Secrets/)
- Services register with meta-project
- Patterns flow upward (sub-project → meta-project KB)

**When working in sub-projects**: Switch context explicitly, follow sub-project CLAUDE.md

## STARTUP (Every Session)

```bash
# 1. Register
~/devvyn-meta-project/scripts/bridge-register.sh register code

# 2. Check messages
~/devvyn-meta-project/scripts/bridge-receive.sh code

# 3. Verify bridge
ls ~/infrastructure/agent-bridge/bridge/inbox/code/
```

## ESSENTIAL OPERATIONS

```bash
# Send message
./scripts/bridge-send.sh <from> <to> <priority> <subject> <file>

# Check status
./scripts/bridge-register.sh status code
./scripts/bridge-register.sh list
```

## RECOVERY

```bash
# Clear locks and retry
rm -f bridge/queue/processing/*.lock
./scripts/bridge-register.sh unregister code && ./scripts/bridge-register.sh register code
```

## SECURITY: CREDENTIAL HANDLING (CRITICAL)

**NEVER display credential values in conversation output**

Forbidden actions:

- `security find-generic-password -w` → outputs raw keychain secrets
- `cat secrets/*`, `cat .env*` → exposes credential files
- `printenv *KEY`, `echo $*KEY` → reveals environment secrets
- Displaying API keys, tokens, passwords in responses

Safe alternatives ONLY:

- `./scripts/credential-safe-check.sh keychain <service>` → confirms existence
- `./scripts/credential-safe-check.sh env <variable>` → checks if set
- `./scripts/elevenlabs-key-manager.sh test` → validates setup
- Reference env var names (e.g., `ANTHROPIC_API_KEY`) without retrieving

When user asks "do you have access to X key?":

- Confirm setup status only: "✅ Credential exists" or "❌ Not configured"
- Provide setup instructions referencing env vars
- NEVER retrieve or display actual secret values

Quick reference: `docs/security/credential-safety-quick-reference.md`
Detailed patterns: `knowledge-base/patterns/secure-api-access.md`
Incident history: `docs/security/credential-leak-incident-2025-11-03.md`

## REFERENCE

**Platform conceptual framework**: PLATFORM_NOMENCLATURE.md
- Complete naming system (technical + behavioral)
- The Seven-Layer Stack (Substrate → Garden)
- The Mirroring (recursive coordination loop)
- Agent roles and behavioral descriptions

**Detailed operations**: OPERATIONS_REFERENCE.md
- Publication surfaces and alternative interfaces (The Interface)
- Resource provisioning
- System health diagnostics
- Advanced bridge operations

**Core protocols**: INVARIANTS.md or COORDINATION_PROTOCOL.compact.md

**Patterns**: knowledge-base/patterns/ for design patterns and theory
