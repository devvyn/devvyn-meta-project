# System Invariants

**Platform**: Ludarium Behavioral Coordination Platform

Essential guarantees extracted from ClaudeCodeSystem.tla specification.

**See also**: PLATFORM_NOMENCLATURE.md for complete naming system and conceptual framework.

## Session Prerequisites

```tla
SessionActive ⇒ (Registered ∧ MessagesChecked ∧ BridgeAccessible)
```

Every active session requires:

- Agent registered with bridge
- Messages checked from inbox
- Bridge directory accessible

## Bridge Operation Safety

```tla
∀ op ∈ BridgeOps: UsesAtomicScript(op) ∧ ¬DirectFileWrite
```

All bridge operations must:

- Use provided atomic scripts
- Never write files directly (prevents race conditions)

## Escalation Triggers

```tla
MessagesLost ∨ QueueGrowing ∨ RegistrationFails ∨ TLAFails
  ⇒ ◇NotifyChatAgent
```

Escalate to Chat agent when:

- Messages disappearing from bridge
- Queue accumulating without processing
- Registration failing repeatedly
- Invariant violations detected

## Zen Minimalism (Anti-Cruft)

```tla
∀ file ∈ AgentInstructions:
  ContainsOnlyBehavior(file) ∧ ¬ContainsRationale(file)
  ∧ Length(file) < 200 \* lines
```

Agent instruction files must:

- Contain only operational behavior
- Exclude rationale and explanations
- Stay under 200 lines

## Progressive Disclosure

```tla
ContextLoaded(agent, t) ⊆ ContextLoaded(agent, t+1)
ContextLoaded(agent, t) = MinimalSufficient(TaskComplexity(t))

LoadTier(n) ⇒ LoadedTier(n-1)

∀ agent: LoadedTier(1) = TRUE
```

Context loading must:

- Be monotonic (never unload)
- Be minimal for task complexity
- Follow tier dependency order
- Always include TIER1 (essentials)

## Pattern Validity

```tla
PatternValid ≜
  (Occurrences ≥ 3 ∨ Projects ≥ 2)
  ∧ Confidence ∈ {HIGH, MEDIUM, LOW}
  ∧ ContextDocumented
```

Patterns are valid when:

- Repeated 3+ times OR seen in 2+ projects
- Confidence level assigned
- Context documented

## Decision Process

```tla
DecisionProcess ≜
  PatternExists ∧ Confidence > 90% ⇒ ApplyPattern
  ∧ PatternExists ∧ Confidence ∈ [50%, 90%] ⇒ ApplyWithNotification
  ∧ (¬PatternExists ∨ Confidence < 50%) ⇒ EscalateToHuman
```

Decision routing:

- High confidence (>90%) → Apply pattern directly
- Medium confidence (50-90%) → Apply with notification
- Low confidence (<50%) → Escalate to human

## Priority Triage

```tla
CRITICAL ≜ ProductionBlocking ∨ DataIntegrity ∨ Security ∨ CoordinationFailure
HIGH ≜ PerformanceDegradation>50% ∨ MultiProjectAffected ∨ StrategicBlocked>48h
NORMAL ≜ OptimizationOpportunity ∨ SingleProjectConcern ∨ PatternCandidate
INFO ≜ HistoricalAnalysis ∨ Documentation ∨ LowImpactObservation
```

Message priorities defined by impact and urgency.

## Workspace Boundaries

```tla
FileOwnershipExclusive ≜ ∀ f ∈ metaFiles : ∀ sp ∈ SubProjects : f ∉ subFiles[sp]

CredentialsInMetaOnly ≜ ∀ sp ∈ SubProjects : ∀ f ∈ subFiles[sp] : SecurityLevel(f) ≠ SECRET

ServicesMustRegister ≜ ∀ sp ∈ SubProjects : OffersService(sp) ⇒ sp ∈ DOMAIN ServiceRegistry

PatternFlowUpward ≜ ∀ pattern ∈ knowledgeGraph :
  Source(pattern) ∈ SubProjects ⇒ pattern ∈ metaFiles
```

Workspace separation guarantees:

- No file exists in both meta-project and sub-project (except WORKSPACE_BOUNDARIES.md)
- Credentials stored only in meta-project (~/Secrets/)
- Sub-projects offering services must register with meta-project
- Patterns discovered in sub-projects flow upward to meta-project knowledge base

**See also**: [WORKSPACE_BOUNDARIES.md](./WORKSPACE_BOUNDARIES.md) for complete formal specification with 10 invariants, safety properties, and liveness properties.

---

*For complete formal specification, see: ClaudeCodeSystem.tla*
