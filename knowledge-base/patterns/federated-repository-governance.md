# Federated Repository Governance

**Category**: Governance, Architecture, Multi-Repository Coordination
**Status**: Production Pattern
**Validation**: Implemented in Workspace Boundaries
**Related**: Workspace Boundaries, JITS, Publication Surfaces

---

## Problem

**Question**: "What makes a repository? If it were a nation, how would its borders and authority be expressed?"

**Traditional Model**: Repository = Single .git directory with monolithic authority
- ✅ Simple: One repo, one team, one authority
- ❌ Doesn't scale: Multi-team projects create conflicts
- ❌ No federation: Can't coordinate across independent repos
- ❌ Territorial rigidity: Hard to share infrastructure

**Real-World Scenario**:
```
~/devvyn-meta-project/           # Coordination patterns
~/Documents/GitHub/herbarium/    # Scientific domain
~/infrastructure/agent-bridge/   # Shared infrastructure

Q: How do three independent repositories coordinate without one dominating?
Q: Where does authority lie for cross-cutting concerns?
Q: How do we prevent territorial conflicts?
```

---

## Solution

**Federated Sovereignty Model**: Repositories as independent nation-states with negotiated treaties

### Core Principle

> "Each repository has exclusive authority over its domain, coordinates through negotiated protocols, governed by a constitutional document (WORKSPACE_BOUNDARIES.md)"

### Three Types of Borders

**1. Physical Borders** (Filesystem):
```bash
~/devvyn-meta-project/          # Meta-repo territory
~/Documents/GitHub/*/           # Sub-project territories
~/infrastructure/*/             # Infrastructure territories

# Hard border: .git directories define sovereignty
```

**2. Authority Borders** (Conceptual):
```yaml
meta-project:
  authority:
    - Agent instructions
    - Patterns
    - Coordination tools
    - Security infrastructure
  no_authority:
    - Domain implementation
    - Scientific validation
    - Production configs

sub-project:
  authority:
    - Domain code
    - Business logic
    - Tests
    - Production configs
  no_authority:
    - Agent behavior
    - Cross-project patterns
    - Shared tooling
```

**3. Protocol Borders** (Interface):
```yaml
interfaces:
  - Bridge messages (async communication)
  - Service registry (capability advertisement)
  - Publication surfaces (multi-format export)
  - WORKSPACE_BOUNDARIES.md (constitutional treaty)
```

---

## Constitutional Framework

### The Repository Constitution (TLA+)

```tla
---------------------- MODULE FederatedGovernance ----------------------

\* Each repository has unique authority domain
∀ repo ∈ Repositories:
    ∃! domain : HasAuthority(repo, domain)

\* No territorial overlap (except mirrored constitution)
∀ r1, r2 ∈ Repositories:
    r1 ≠ r2 ⇒ Files(r1) ∩ Files(r2) ⊆ {WORKSPACE_BOUNDARIES.md}

\* Subsidiarity: Authority at most local level
∀ concept ∈ Concepts:
    AuthorityLevel(concept) = MIN({level : CanDecide(level, concept)})

\* Shared infrastructure requires treaty
SharedInfrastructure(r1, r2) ⇒ NegotiatedBoundary(r1, r2)

\* Constitutional changes require consensus
∀ repo ∈ Repositories:
    UpdateBoundaries(repo) ⇒ AllMirrorsUpdated(repo)

=========================================================================
```

### Subsidiarity Principle

**Definition**: Decisions made at most local level capable of handling them

**Examples**:

| Decision | Wrong Level | Right Level | Rationale |
|----------|-------------|-------------|-----------|
| **Function naming** | Meta-project decides | Sub-project decides | Domain-specific, no coordination needed |
| **Agent startup protocol** | Sub-project decides | Meta-project decides | Cross-repo consistency required |
| **API key storage** | Sub-project stores | Meta-project stores | Security boundary must be central |
| **Test framework** | Meta-project mandates | Sub-project chooses | Different domains, different needs |

**Application**:
```python
def determine_authority_level(decision: str) -> str:
    """Find lowest level that can make this decision"""

    # Can single file/function decide? → Developer authority
    if decision.scope == "function":
        return "developer"

    # Can single module decide? → Module authority
    if decision.scope == "module" and not decision.affects_others:
        return "module"

    # Affects multiple modules in repo? → Repo authority
    if decision.scope == "repo":
        return "repository"

    # Affects multiple repos? → Federation authority
    if decision.scope == "cross-repo":
        return "federation"  # Requires WORKSPACE_BOUNDARIES negotiation

    # Global concern? → Meta-project authority
    if decision.is_pattern or decision.is_security:
        return "meta-project"
```

---

## Intent Qualification for Consensus

### Traditional Git

```bash
# Consensus = Tests pass + Approval
git push origin main
# If CI green + reviewer approves → merged
```

### Federated Model

```python
def qualifies_for_consensus(pr: PullRequest) -> Tuple[bool, str]:
    """Check if PR respects federal governance"""

    # 1. Authority boundary check
    for changed_file in pr.changed_files:
        owner_repo = find_authority(changed_file)
        if owner_repo != pr.source_repo:
            return False, f"Cross-border violation: {changed_file} owned by {owner_repo}"

    # 2. Constitutional compliance
    if not validates_invariants(pr):
        return False, "Violates TLA+ invariants in WORKSPACE_BOUNDARIES.md"

    # 3. Subsidiarity check
    for decision in pr.decisions:
        appropriate_level = determine_authority_level(decision)
        if pr.source_repo.level > appropriate_level:
            return False, f"Centralizing authority inappropriately: {decision}"

    # 4. Treaty synchronization
    if pr.touches('WORKSPACE_BOUNDARIES.md'):
        if not all_mirrors_updated(pr):
            return False, "Constitution changed but mirrors not synchronized"

    # 5. Shared infrastructure protocol
    if pr.affects_shared_infrastructure():
        if not has_federation_approval(pr):
            return False, "Shared infrastructure changes require federation consensus"

    return True, "Qualifies for consensus"
```

### Example Scenarios

**Scenario 1: Valid Local Change** ✅
```python
# Sub-project adds new feature
pr = PullRequest(
    source_repo="herbarium",
    changed_files=["herbarium/src/new_feature.py"],
    decision="Add OCR pipeline"
)

qualifies_for_consensus(pr)
# → (True, "Qualifies") - Within authority domain
```

**Scenario 2: Invalid Cross-Border Change** ❌
```python
# Sub-project tries to change meta-project file
pr = PullRequest(
    source_repo="herbarium",
    changed_files=["meta-project/agents/CODE_AGENT.md"],
    decision="Customize agent behavior"
)

qualifies_for_consensus(pr)
# → (False, "Cross-border violation: CODE_AGENT.md owned by meta-project")
```

**Scenario 3: Valid Treaty Change** ✅
```python
# Meta-project updates boundaries with all mirrors
pr = PullRequest(
    source_repo="meta-project",
    changed_files=[
        "meta-project/WORKSPACE_BOUNDARIES.md",
        "herbarium/WORKSPACE_BOUNDARIES.md"  # Mirror updated
    ],
    decision="Add new service registration protocol"
)

qualifies_for_consensus(pr)
# → (True, "Qualifies") - All mirrors synchronized
```

---

## Code Geometry as Governance Metric

### Spatial Structure Reveals Authority

**Hypothesis**: Natural code clusters should align with authority domains

**Metric**:
```python
def measure_authority_alignment(repo: Repository) -> float:
    """How well does code clustering match authority domains?"""

    # Detect natural communities in dependency graph
    G = build_dependency_graph(repo)
    natural_communities = nx.community.louvain_communities(G)

    # Load authority domains from WORKSPACE_BOUNDARIES.md
    authority_domains = parse_workspace_boundaries(repo)

    # Measure alignment
    aligned_nodes = 0
    total_nodes = len(G.nodes)

    for node in G.nodes:
        # Which natural community is this node in?
        natural_community = find_community(node, natural_communities)

        # Which authority domain should it be in?
        expected_domain = find_authority_domain(node, authority_domains)

        # Do they match?
        if natural_community.matches(expected_domain):
            aligned_nodes += 1

    return aligned_nodes / total_nodes  # 1.0 = perfect alignment
```

**Interpretation**:
- **High alignment** (>0.8): Code structure matches governance
- **Low alignment** (<0.5): Governance mismatch, refactoring needed

**Example**:
```
Natural clusters detected:
  - Cluster A: All files in src/authentication/
  - Cluster B: All files in src/data_processing/
  - Cluster C: Mixed files from src/ui/ and src/api/

Authority domains (WORKSPACE_BOUNDARIES.md):
  - Domain 1: Authentication (sub-project authority)
  - Domain 2: Data Processing (sub-project authority)
  - Domain 3: Infrastructure (meta-project authority)

Alignment: 0.66
Misaligned: Cluster C spans authority boundary
Recommendation: Separate UI and API into distinct domains
```

---

## Dual Citizenship: The Literate Garden Case

### Question

> "Literate Garden may in fact be a repository which belongs elsewhere just as much as the converse"

**This is dual citizenship for repositories!**

### Three Models

**Model 1: Git Submodule (Dual Sovereignty)**
```bash
# Literate Garden maintains independence
cd ~/Documents/GitHub/literate-garden
git remote -v
# → origin: literate-garden repo

# Meta-project includes as submodule
cd ~/devvyn-meta-project
git submodule add <literate-garden-url> garden/literate-garden

# Result: Two .git directories, coordinated via submodule protocol
```

**Pros**:
- ✅ Garden evolves independently
- ✅ Meta-project tracks specific version
- ✅ Clear sovereignty boundaries

**Cons**:
- ❌ Submodule complexity
- ❌ Requires explicit sync

**Model 2: Symlink (Shared Territory)**
```bash
# Garden lives in one place
~/Documents/GitHub/literate-garden/

# Meta-project links to it
ln -s ~/Documents/GitHub/literate-garden ~/devvyn-meta-project/garden/

# Result: Single source of truth, multiple access points
```

**Pros**:
- ✅ Always in sync
- ✅ Simple to understand
- ✅ No duplication

**Cons**:
- ❌ Requires local filesystem proximity
- ❌ Git doesn't track symlinks well

**Model 3: Publication Surface (No Permanent Residence)**
```bash
# Garden remains completely separate
~/Documents/GitHub/literate-garden/ → publishes to surfaces

# Meta-project consumes via surface
~/devvyn-meta-project/scripts/surface-discover.sh --source literate-garden
# → Reads published content, doesn't store it

# Result: Garden as service, not territory
```

**Pros**:
- ✅ Maximum independence
- ✅ Garden can publish to multiple consumers
- ✅ Clean separation

**Cons**:
- ❌ Requires publication infrastructure
- ❌ Potentially stale (cache)

### Authority Matrix for Dual Citizenship

| Aspect | Literate Garden | Meta-Project | Decision |
|--------|-----------------|--------------|----------|
| **Content creation** | ✅ Primary | ❌ Suggest only | Garden decides what to write |
| **Structure/templates** | ❌ Must follow | ✅ Defines | Meta provides patterns |
| **Publication format** | ❌ Uses provided | ✅ Provides | Meta owns export tools |
| **Integration protocol** | 🤝 Negotiated | 🤝 Negotiated | Treaty in WORKSPACE_BOUNDARIES.md |
| **Version control** | ✅ Own .git | ❌ N/A (submodule) | Garden has commit authority |
| **Pattern contribution** | ✅ Can propose | ✅ Can accept | Garden → Meta flow |

**Recommendation**: **Model 1 (Submodule)** for literate-garden
- Garden maintains sovereignty
- Meta-project tracks stable versions
- Clear authority boundaries
- Standard Git workflow

---

## Practical Implementation

### Step 1: Create Constitutional Document

```bash
# In each repository
cp ~/devvyn-meta-project/WORKSPACE_BOUNDARIES.md ./

# Customize for your repo
vim WORKSPACE_BOUNDARIES.md
```

### Step 2: Define Authority Domains

```yaml
# In WORKSPACE_BOUNDARIES.md
authority_domains:
  this_repo:
    - src/domain_code/
    - tests/
    - docs/domain_specific/

  meta_project:
    - agents/
    - patterns/
    - tools/coordination/

  shared:
    - .gitignore (patterns)
    - WORKSPACE_BOUNDARIES.md (mirrored)
```

### Step 3: Validate Compliance

```bash
# Run boundary validator
~/devvyn-meta-project/scripts/validate-boundaries.sh --repo .

# Check authority alignment
python -m scripts.repository_geometry --repo . --check-authority
```

### Step 4: Enforce at PR Time

```yaml
# .github/workflows/governance.yml
name: Validate Governance

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Check authority boundaries
        run: |
          ~/devvyn-meta-project/scripts/validate-boundaries.sh --repo .

      - name: Check code geometry alignment
        run: |
          python -m scripts.repository_geometry \
            --repo . \
            --check-authority \
            --fail-if-misaligned
```

---

## Validation Metrics

### Boundary Integrity Score

```python
def calculate_boundary_integrity(repo: Repository) -> float:
    """Measure how well repository respects boundaries"""

    violations = {
        'cross_border_files': 0,       # Files in wrong repo
        'authority_conflicts': 0,      # Multiple repos claim same authority
        'undefended_borders': 0,       # Files without clear ownership
        'stale_mirrors': 0,            # Constitution out of sync
        'geometry_misalignment': 0.0   # Code clusters don't match domains
    }

    # Check each violation type...
    # (Implementation details)

    # Score: 1.0 = perfect, 0.0 = total chaos
    max_violations = 100
    total_violations = sum(violations.values())
    return max(0.0, 1.0 - (total_violations / max_violations))
```

**Target**: Maintain >0.9 boundary integrity

---

## Relationship to Other Patterns

### JITS (Just-In-Time Specificity)

**Governance Tiers**:
- **TIER1**: Constitutional invariants (always enforced)
- **TIER2**: Authority domains (checked at PR time)
- **TIER3**: Code geometry recommendations (monitored)
- **TIER4**: Historical analysis (on-demand)

### Workspace Boundaries

**This pattern IS the implementation of Workspace Boundaries at governance level**

### Publication Surfaces

**Governance as Surface**:
```
Input: Repository structure
Surface: Authority boundary API
Output: Can this change be made? Why/why not?
```

---

## Summary

**Question**: "What makes a repo? How would borders/authority be expressed?"

**Answer**: Repositories are **federated nation-states** with:

1. **Physical borders**: .git boundaries
2. **Authority borders**: Conceptual domains (WORKSPACE_BOUNDARIES.md)
3. **Protocol borders**: Negotiated interfaces (bridge, registry, surfaces)
4. **Constitutional law**: TLA+ invariants
5. **Subsidiarity**: Authority at most local level
6. **Intent qualification**: Consensus requires governance compliance
7. **Code geometry**: Spatial structure should align with authority

**Implementation**:
- Constitutional document (WORKSPACE_BOUNDARIES.md) in each repo
- Validation tools (validate-boundaries.sh)
- Geometry analysis (repository_geometry.py Marimo notebook)
- CI enforcement (GitHub Actions)
- Authority alignment metrics

**Philosophy**: Governance emerges from spatial structure, not imposed top-down.

---

## References

- [Workspace Boundaries](../../WORKSPACE_BOUNDARIES.md) - Full TLA+ specification
- [Repository Geometry](../incubator/repository-geometry-governance.md) - Spatial analytics
- [Marimo Notebook](../../scripts/repository_geometry.py) - Interactive analysis
- Subsidiarity Principle: Catholic social teaching, EU governance
- Federalism: US Constitution, distributed authority

**Status**: Production pattern, validated across meta-project + sub-projects
