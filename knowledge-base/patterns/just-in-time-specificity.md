# Just-In-Time Specificity (JITS)

## Core Principle

**Front-load invariants and commands, lazy-load explanations and examples.**

Specificity should be progressive: essential → compact → comprehensive → reference. Defer detailed specification until the moment it's needed, maintaining generality until context demands precision.

## The 80/20 Specificity Law

In any information system, ~20% of content provides ~80% of decision-making value. Optimize context throughput by:

1. **Identifying high-leverage content**: Invariants, commands, constraints, core algorithms
2. **Allocating attention accordingly**: Front-load high-leverage, defer low-leverage
3. **Progressive disclosure**: Load tiers on-demand rather than up-front

### Specificity Tiers

| Tier | Content Type | Load Time | Examples |
|------|--------------|-----------|----------|
| **TIER1** | Invariants, essential commands | Always | TLA+ guarantees, startup sequence |
| **TIER2** | Core operations, message formats | First reference | Protocol structure, recovery procedures |
| **TIER3** | Examples, anti-patterns, deep-dive | On-demand | Use case walkthroughs, architecture details |
| **TIER4** | Historical context, alternatives | Reference only | Migration guides, deprecated approaches |

## Cross-Domain Validation

### Software Development

- **YAGNI** (You Aren't Gonna Need It): Don't build features until needed
- **Defer architectural decisions**: Wait for constraints to emerge
- **Refactor when patterns crystallize**: Let structure emerge from usage
- **Progressive enhancement**: Core functionality first, optimizations later

### Law & Governance

- **Common law evolution**: General principles + case-by-case specificity
- **Constitutional framework**: Broad rights → specific legislation → judicial interpretation
- **Regulation**: Statutes remain general until case law provides precision
- **Precedent system**: Build specificity from actual disputes, not hypothetical ones

### Natural Evolution

- **Genetic diversity**: Maintain options until selection pressure demands specificity
- **Adaptive radiation**: General forms → specialized variants when niches appear
- **Exaptation**: Features find new uses (specificity discovered, not predetermined)
- **Punctuated equilibrium**: Long stasis (general) → rapid specification (environmental change)

### Information Theory

- **Minimum description length**: Encode only essential information, compress redundancy
- **Kolmogorov complexity**: Shortest program that generates output = optimal specificity
- **Progressive encoding**: JPEG/video = low-res first, details on demand
- **Entropy minimization**: High-leverage information first, noise deferred

## Pattern Manifestation in This System

### Accidental Discovery: .compact.md Files

Empirical evidence from production:

- `COORDINATION_PROTOCOL.md`: 556 lines → 150 lines (73% reduction)
- `BRIDGE_SPEC_PROTOCOL.md`: 472 lines → 167 lines (65% reduction)
- `RESOURCE_ACCESS_PROTOCOL.md`: 608 lines → 134 lines (78% reduction)

**Average compression: 70% with no operational value loss**

These files represent organic JITS discovery - they work because they preserve high-leverage content (invariants, commands) while deferring low-leverage content (examples, explanations, rationale).

### Current Anti-Patterns (Over-Specification)

1. **Front-loaded context burden**: 1,400+ lines to become operational
2. **Verbose examples**: 48 lines of workflow examples in protocol (TIER3 content at TIER1 position)
3. **Premature optimization**: Performance specs before bottlenecks proven
4. **Duplicate versioning**: CHAT_AGENT v1.1 + original = confusion, negative leverage
5. **Embedded explanations**: "Why" mixed with "what" in operational docs

### High-Leverage Content Identified

From analysis of 5,755 total lines across core files:

**Essential (20% of lines, 80% of value):**

- TLA+ invariants: 20 lines of formal guarantees
- Startup commands: 3 bash operations (register, receive, verify)
- Recovery procedures: 4 critical failure modes
- Bridge message format: Core send/receive structure
- **Total: ~600 lines** (10% of current content, 80% of operational value)

**Low-Leverage (80% of lines, 20% of value):**

- Examples for every agent combination
- Migration guides from deprecated versions
- Performance monitoring guidelines (premature)
- Explanatory prose embedded in operational docs
- **Total: ~5,155 lines** (90% of content, 20% of supplementary value)

## Implementation Guidelines

### For Documentation

```markdown
## INVARIANTS [TIER1]
[20 lines: formal guarantees, constraints]

## ESSENTIAL OPERATIONS [TIER1]
[30 lines: commands, message formats]

## COMMON PATTERNS [TIER2]
[50 lines: typical workflows, recovery]

## EXAMPLES [TIER3]
[100+ lines: detailed walkthroughs]
See [examples/] for: [list specific cases]

## ARCHITECTURE [TIER3]
[Deep-dive into design decisions]
See [full protocol] for: [performance, alternatives, history]
```

### For Agent Instructions

```markdown
## INVARIANTS
[Formal guarantees this agent must maintain]

## STARTUP
[3-4 commands to become operational]

## CORE OPERATIONS
[Essential commands, no examples]

## REFERENCE
See [OPERATIONS_REFERENCE.md] for:
- Detailed examples
- Recovery procedures
- Performance tuning
- Migration guides
```

### For Pattern Files

```markdown
# Pattern Name

## Summary [TIER1]
[50 lines: problem, solution, when to use]

## Implementation [TIER2]
[Core algorithm, key decisions]

---
## Examples [TIER3]
[Detailed use cases, anti-patterns]

## Resources [TIER4]
[Background, alternatives, references]
```

## Relationship to Other Patterns

### Wisdom Extraction Philosophy

JITS is the **dual** of wisdom extraction:

- **Wisdom extraction**: Remove baggage from received information
- **JITS**: Avoid creating baggage in emitted information

Both optimize signal-to-noise by deferring low-leverage content.

### Information Parity Design

JITS enables parity by reducing context cost:

- Agents can load TIER1 (essential) universally
- Specialized agents load TIER2/3 as needed
- No agent forced to process irrelevant detail

### Collective Resource Provisioning

JITS applied to resources:

- Essential: Availability notification (magnet link, size)
- On-demand: Metadata, samples, provenance
- Reference: Full content (streamed/downloaded)

## Validation Metrics

### Context Throughput

- **Before JITS**: 1,400+ lines to operational
- **After JITS** (target): ≤500 lines to operational
- **Compression goal**: 70% (proven by .compact.md baseline)

### Emergence Quality

- Can agents discover needed TIER2/3 content organically?
- Do agents request appropriate specificity for task complexity?
- Are TIER1 invariants sufficient for 80% of operations?

### Maintenance Burden

- Lines requiring updates when system changes
- Duplication across agent instruction files
- Context drift between versions

## Theoretical Foundation

### Progressive Disclosure Invariant (TLA+)

```tla
\* Context loaded is monotonic and minimal
ContextLoaded(agent, t) ⊆ ContextLoaded(agent, t+1)
ContextLoaded(agent, t) = MinimalSufficient(TaskComplexity(t))

\* Tier loading follows dependency order
LoadTier(n) ⇒ LoadedTier(n-1)

\* Essential context always available
∀ agent: LoadedTier(1) = TRUE
```

### Optimal Specificity Function

Given:

- `L(tier)` = leverage (value per unit attention)
- `C(tier)` = context cost (lines, complexity)
- `P(need)` = probability of needing this tier

Optimal loading:

```
Load tier n ⇔ L(n) × P(need) > C(n) × opportunity_cost
```

For TIER1: `P(need) ≈ 1.0` (always needed)
For TIER2: `P(need) ≈ 0.4` (often needed)
For TIER3: `P(need) ≈ 0.1` (occasionally needed)
For TIER4: `P(need) ≈ 0.01` (rarely needed)

## Future Directions

### Automated Tier Detection

- Analyze line-level leverage scores
- Detect command patterns (TIER1) vs. explanatory prose (TIER3)
- Suggest tier markers for unstructured docs

### Adaptive Loading

- Agents learn which TIER2/3 content they reference frequently
- Personal context profiles (this agent needs X, that agent needs Y)
- Predictive loading based on task classification

### Emergence Studies

- Log when agents request deeper tiers
- Identify missing TIER1 content (needed but not front-loaded)
- Discover organic specification patterns

## Related Patterns

- [Wisdom Extraction Philosophy](wisdom-extraction-philosophy.md)
- [Information Parity Design](information-parity-design.md)
- [Collective Resource Provisioning](collective-resource-provisioning.md)

## References

- YAGNI: Extreme Programming principle
- Minimum Description Length: Rissanen (1978)
- Punctuated Equilibrium: Eldredge & Gould (1972)
- Progressive Enhancement: Web standards community
