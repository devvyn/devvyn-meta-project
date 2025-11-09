# Repository Geometry & Governance

**Category**: Meta-Analysis, Code Analytics, Governance Patterns
**Status**: Exploration
**Created**: 2025-11-09
**Question**: "What makes a repo? If it were a nation, how would its borders and authority be expressed?"

---

## The Nation-State Analogy

### Traditional Git Repository (Monolithic Nation-State)

```
repo/
├── sovereignty: Single .git directory
├── borders: Repository root defines hard boundary
├── authority: Committer access = citizenship
├── law: .gitignore, branch policies, hooks
├── territory: All files within border
└── consensus: Merge = legislative process
```

**Properties**:
- **Territorial Integrity**: Everything inside is "ours"
- **Single Sovereignty**: One .git = one authority
- **Hard Borders**: Clear inside/outside distinction
- **Centralized Law**: Rules apply uniformly within

### Problem: Distributed Authority (The EU Model)

But in meta-project + sub-projects, we have:

```
~/devvyn-meta-project/           # Coordination authority
~/Documents/GitHub/herbarium/    # Domain authority
~/infrastructure/agent-bridge/   # Infrastructure authority

Q: How do three repositories coordinate without one dominating?
A: WORKSPACE_BOUNDARIES.md (The Constitution)
```

**Properties**:
- **Federated Sovereignty**: Each repo has internal authority
- **Negotiated Borders**: WORKSPACE_BOUNDARIES defines interface
- **Shared Infrastructure**: Bridge, tools, patterns cross borders
- **Subsidiarity Principle**: Authority at most local level possible

---

## Code Geometry: Spatial Analytics

### Traditional Metrics (1D - Lines of Code)

```python
# Simple count
total_lines = sum(len(file.readlines()) for file in all_files)
```

**Limited**: Treats code as linear text, ignores structure

### 2D Geometry: File-Module Topology

```python
# Clustering coefficient
files_in_dir = len(list(path.glob('*.py')))
cohesion = files_in_dir / total_files  # How clustered?

# Diffusion vs. Discretion
feature_files = find_files_for_feature("authentication")
is_discrete = all(f.parent == feature_files[0].parent for f in feature_files)
is_diffuse = len(set(f.parent for f in feature_files)) > 5
```

**Metrics**:
- **Cohesion**: Files for feature X in same directory
- **Diffusion**: Feature spread across N directories
- **Coupling**: Import graph edge density
- **Modularity**: Strong intra-module, weak inter-module connections

### 3D Geometry: Dependency Graph Topology

```python
import networkx as nx

# Build dependency graph
G = nx.DiGraph()
for file in python_files:
    imports = parse_imports(file)
    for imp in imports:
        G.add_edge(file, imp)

# Geometric properties
diameter = nx.diameter(G)  # Longest path
clustering = nx.clustering(G)  # Local density
centrality = nx.betweenness_centrality(G)  # Bottlenecks
```

**Spatial Metrics**:
- **Diameter**: Max distance between nodes (deep vs. flat)
- **Clustering**: Local interconnectedness
- **Centrality**: Which modules are "downtown" (critical hubs)
- **Communities**: Natural module boundaries

### 4D Geometry: Evolution Over Time

```python
# Git history as 4th dimension
commits = git_log(since="2024-01-01")

# Churn: Lines changed per file
churn = {file: sum(c.lines_changed(file) for c in commits)}

# Hotspots: High churn + high centrality
hotspots = [f for f in files if churn[f] > threshold and centrality[f] > threshold]
```

**Temporal Metrics**:
- **Churn Rate**: How often files change
- **Hotspots**: Frequently changed + structurally critical
- **Drift**: How much topology changes over time
- **Tectonic Zones**: Boundaries that shift frequently

---

## Analytic Features: Diffuse vs. Discrete

### Discrete Feature (Contiguous Territory)

```
src/authentication/
├── __init__.py
├── login.py
├── logout.py
├── session.py
└── tokens.py

# All authentication code in one place
# Nation-state: Like Switzerland (small, cohesive, defensible borders)
```

**Properties**:
- Easy to understand (locality)
- Easy to test (isolation)
- Easy to remove (modular)
- Risk: May become isolated island

### Diffuse Feature (Distributed Territory)

```
authentication code in:
├── src/api/auth_middleware.py      # API layer
├── src/db/user_schema.py           # Data layer
├── src/ui/login_component.jsx      # UI layer
├── src/services/auth_service.py    # Business logic
└── config/auth_config.yaml         # Configuration

# Like Roman Empire: Spread across layers, hard to isolate
```

**Properties**:
- Cross-cutting concerns (logging, auth, monitoring)
- Hard to isolate
- Risk: Changes require coordinating across files
- Benefit: Integration with surrounding system

### Measuring Diffusion

```python
def feature_diffusion(feature_name: str) -> dict:
    """Measure spatial distribution of a feature"""

    files = find_files_for_feature(feature_name)
    directories = {f.parent for f in files}

    return {
        'file_count': len(files),
        'directory_count': len(directories),
        'diffusion_ratio': len(directories) / len(files),  # 0=discrete, 1=maximally diffuse
        'median_depth': median(f.parts.count('/') for f in files),
        'span': max_path_distance(files),  # Graph distance between farthest files
        'geometry': 'discrete' if len(directories) == 1 else 'diffuse'
    }
```

---

## Repository Governance: The Constitutional Question

### Question 1: What Defines a Repository?

**Traditional Answer**: "A .git directory"

**Better Answer**: "A **consent-based governance domain** with:**
1. **Defined authority** (who can commit)
2. **Shared substrate** (code, docs, configs)
3. **Consensus mechanism** (merge, review, CI)
4. **Boundary protocol** (what's inside/outside)
5. **Constitutional documents** (README, CONTRIBUTING, WORKSPACE_BOUNDARIES)"

### Question 2: How Do Repositories Federate?

**The Workspace Boundaries Constitution**:

```tla
\* Federal system invariant
∀ repo ∈ Repositories:
    ∃! authority_domain : HasAuthority(repo, authority_domain)
    ∧ ∀ other_repo ∈ Repositories \ {repo}:
        SharedInfrastructure(repo, other_repo) ⇒ NegotiatedBoundary(repo, other_repo)

\* Subsidiarity: Authority at most local level
∀ concept ∈ Concepts:
    AuthorityLevel(concept) = MIN({level : CanDecide(level, concept)})

\* No territorial overlap (except mirrored constitution)
∀ r1, r2 ∈ Repositories:
    r1 ≠ r2 ⇒ Files(r1) ∩ Files(r2) ⊆ {WORKSPACE_BOUNDARIES.md}
```

**Translation**:
- Each repo has **exclusive authority** over its domain
- Repos share infrastructure through **negotiated protocols**
- Authority lives at the **most local level** that can handle it
- No file overlap except the constitution itself (mirrored)

### Question 3: How Do Borders Work?

**Physical Borders** (Filesystem):
```
~/devvyn-meta-project/  (Meta repo)
~/Documents/GitHub/*/   (Sub-project repos)
~/infrastructure/*/     (Infrastructure repos)
```

**Authority Borders** (Conceptual):
```
Meta-project authority:
- Agent instructions
- Patterns
- Coordination tools
- Security infrastructure

Sub-project authority:
- Domain implementation
- Business logic
- Production configs
- Scientific validation
```

**Protocol Borders** (Interface):
```
Bridge messages:     Inter-repo communication
Service registry:    Capability advertisement
Publication surfaces: Multi-format export
```

### Question 4: How Is Intent Qualified for Consensus?

**Traditional Git**: "Merge if tests pass + reviewer approves"

**Ludarium Pattern**: "Merge if **authority boundaries respected**"

```python
def qualifies_for_consensus(pr: PullRequest) -> bool:
    """Check if PR respects governance"""

    # 1. Does PR touch files outside repo's authority?
    for changed_file in pr.changed_files:
        if not repo.has_authority(changed_file):
            return False  # Crossing border without negotiation

    # 2. Does PR maintain invariants?
    if not check_tla_invariants(pr):
        return False  # Violates constitution

    # 3. Does PR respect subsidiarity?
    for concept in pr.changes:
        if concept.authority_level < repo.authority_level:
            return False  # Centralizing authority inappropriately

    # 4. Does PR update mirrored boundaries?
    if pr.touches('WORKSPACE_BOUNDARIES.md'):
        if not all_mirror_repos_updated(pr):
            return False  # Constitution must stay synchronized

    return True
```

---

## Code Geometry Analytics Framework

### Geometric Questions for Repositories

Using CAQT-style questioning:

```python
# Spatial questions
Q1: Is feature X discrete or diffuse?
Q2: What's the diameter of the dependency graph?
Q3: Are there architectural "downtowns" (central hubs)?
Q4: Which files are on territorial boundaries?

# Temporal questions
Q5: Is the topology stable or shifting?
Q6: Are there "tectonic zones" of frequent boundary changes?
Q7: How fast is the codebase expanding? (km²/year analogy)

# Governance questions
Q8: Are authority domains clearly defined?
Q9: Do file paths reflect authority boundaries?
Q10: Are there undefended borders? (files without clear ownership)
```

### Implementation

```python
class RepositoryGeometry:
    """Analyze spatial properties of repository"""

    def __init__(self, repo_path: Path):
        self.repo = repo_path
        self.graph = self._build_dependency_graph()

    def measure_cohesion(self, feature: str) -> float:
        """How clustered is this feature?"""
        files = self.find_feature_files(feature)
        directories = {f.parent for f in files}
        return 1.0 / len(directories)  # High cohesion = few dirs

    def measure_coupling(self, module_a: str, module_b: str) -> float:
        """How dependent are these modules?"""
        edges = self.graph.edges_between(module_a, module_b)
        return len(edges)

    def find_central_hubs(self, top_n: int = 10) -> List[str]:
        """Which files are architectural downtowns?"""
        centrality = nx.betweenness_centrality(self.graph)
        return sorted(centrality, key=centrality.get, reverse=True)[:top_n]

    def detect_boundaries(self) -> List[Tuple[str, str]]:
        """Find territorial boundaries (weak connections between clusters)"""
        communities = nx.community.louvain_communities(self.graph)
        boundaries = []
        for c1, c2 in combinations(communities, 2):
            edge_count = len(self.graph.edges_between(c1, c2))
            if edge_count < threshold:  # Weak connection = boundary
                boundaries.append((c1, c2))
        return boundaries

    def measure_authority_alignment(self) -> float:
        """Do file paths align with authority domains?"""
        # Check if authority boundaries (from WORKSPACE_BOUNDARIES.md)
        # match actual file clustering
        pass
```

---

## Marimo Notebook as AI Surface

### Why Marimo?

**Marimo** is a reactive Python notebook that:
- ✅ **Reactive**: Cells update automatically on dependency changes
- ✅ **Pure Python**: No hidden state, full reproducibility
- ✅ **Interactive**: Sliders, dropdowns, visualizations
- ✅ **Git-friendly**: Stored as `.py` files, not JSON blobs
- ✅ **LLM-augmented**: Can integrate with local LLMs for analysis

### Marimo Surface for Repository Analysis

```python
import marimo as mo
import networkx as nx
import plotly.graph_objects as go

# Marimo notebook: repository_geometry.py

# Cell 1: Configuration
repo_path = mo.ui.text(value=".", label="Repository Path")
analysis_depth = mo.ui.slider(1, 10, value=5, label="Analysis Depth")

# Cell 2: Load repository (reactive to repo_path)
geometry = RepositoryGeometry(repo_path.value)
graph = geometry.graph

# Cell 3: Interactive visualization
layout_type = mo.ui.dropdown(
    ["spring", "circular", "kamada_kawai"],
    value="spring",
    label="Graph Layout"
)

# Plot dependency graph
pos = getattr(nx, f"{layout_type.value}_layout")(graph)
fig = go.Figure()
for edge in graph.edges():
    x0, y0 = pos[edge[0]]
    x1, y1 = pos[edge[1]]
    fig.add_trace(go.Scatter(x=[x0, x1], y=[y0, y1], mode='lines'))

mo.ui.plotly(fig)

# Cell 4: LLM-augmented analysis
question = mo.ui.text_area(label="Ask about this repository")

if question.value:
    # Use local LLM to analyze geometry
    context = f"""
    Repository: {repo_path.value}
    Files: {len(graph.nodes)}
    Dependencies: {len(graph.edges)}
    Diameter: {nx.diameter(graph)}

    Question: {question.value}
    """

    # Call local Ollama/llama.cpp
    answer = llm_query(context, model="codellama:7b")
    mo.md(answer)

# Cell 5: Geometric metrics (reactive to graph)
metrics = {
    'Diameter': nx.diameter(graph),
    'Avg Clustering': nx.average_clustering(graph),
    'Density': nx.density(graph),
    'Central Hub': geometry.find_central_hubs(1)[0]
}

mo.ui.table(metrics)

# Cell 6: Authority boundary validation
boundaries = geometry.detect_boundaries()
authority_domains = parse_workspace_boundaries()

misalignments = []
for detected_boundary in boundaries:
    if not matches_authority_boundary(detected_boundary, authority_domains):
        misalignments.append(detected_boundary)

if misalignments:
    mo.callout(
        f"⚠️ Found {len(misalignments)} boundaries that don't match authority domains",
        kind="warn"
    )

# Cell 7: Generate CAQT questions about geometry
geo_questions = generate_geometry_questions(geometry)
mo.accordion({q.text: q.rationale for q in geo_questions})
```

### Interactive Features

**User can**:
1. **Select repository** → Graph updates automatically
2. **Adjust layout** → Visualization reacts
3. **Ask LLM questions** → "Why is this file so central?"
4. **Explore metrics** → Interactive tables, charts
5. **Validate governance** → Check boundary alignment
6. **Generate questions** → CAQT-style geometric questions

### LLM Augmentation Efficiency

**Why Marimo + Local LLM is Efficient**:

1. **Reactive Context**: Only regenerate what changed
2. **Local Models**: No API latency/costs (Ollama, llama.cpp)
3. **Cached Computations**: Graph analysis cached, LLM only for queries
4. **Incremental Analysis**: User explores interactively, LLM fills gaps
5. **Git-friendly**: Notebook is `.py` file, version controlled

**Efficiency Comparison**:

| Approach | Computation | Cost | Latency |
|----------|-------------|------|---------|
| **Manual analysis** | Human hours | $$$ | Days |
| **Cloud LLM (GPT-4)** | Send full code | $$ | Seconds |
| **Marimo + Local LLM** | Graph cached, LLM for Q&A | $ | <100ms |

---

## Integration with Literate Garden

### The Question

> "...may in fact be a repository which belongs elsewhere just as much as the converse"

**This is the federated sovereignty question!**

### Pattern: Dual Citizenship for Repositories

```
literate-garden/
├── sovereignty: Own .git (independent evolution)
├── mirrored in: ~/devvyn-meta-project/garden/ (symlink? submodule?)
├── authority: Garden has domain authority (writing, curation)
├── coordination: Meta-project has pattern authority (structure, publication)
└── consensus: Both must agree on boundary changes
```

**Implementation**:

```bash
# Option 1: Git submodule (dual citizenship)
cd ~/devvyn-meta-project
git submodule add <literate-garden-url> garden/literate-garden

# Option 2: Symlink (shared territory)
ln -s ~/Documents/GitHub/literate-garden ~/devvyn-meta-project/garden/

# Option 3: Publication surface (no permanent residence)
# Garden remains separate, meta-project consumes via surface
~/devvyn-meta-project/scripts/surface-discover.sh --source literate-garden
```

**Authority Matrix**:

| Aspect | Literate Garden Authority | Meta-Project Authority |
|--------|---------------------------|------------------------|
| **Content** | ✅ Garden decides what/how to write | ❌ Meta can suggest, not dictate |
| **Structure** | ❌ Must follow pattern templates | ✅ Meta defines patterns |
| **Publication** | ❌ Uses meta publication surfaces | ✅ Meta provides export tools |
| **Integration** | 🤝 Negotiated (workspace boundaries) | 🤝 Negotiated |

---

## Knowledge Base Entry Spawned

Yes, this absolutely deserves KB entries! Creating:

1. **Repository Geometry Pattern** (this document)
2. **Federated Repository Governance** (constitutional model)
3. **Code Geometry Analytics** (spatial metrics)
4. **Marimo as AI Surface** (interactive notebook pattern)

---

## Summary: Answering Your Questions

### Q: "What makes a repo?"

**A**: A **consent-based governance domain** with:
- Defined authority (who decides)
- Shared substrate (code, docs)
- Consensus mechanism (how we merge)
- Constitutional documents (WORKSPACE_BOUNDARIES.md)

### Q: "If it were a nation, how would borders/authority be expressed?"

**A**: Through **federated sovereignty**:
- **Physical borders**: Filesystem paths
- **Authority borders**: Conceptual domains (coordination vs. implementation)
- **Protocol borders**: Negotiated interfaces (bridge, registry, surfaces)
- **Intent qualification**: Respects authority boundaries, maintains invariants

### Q: "What are appropriate analytics of code geometry?"

**A**: Multi-dimensional spatial metrics:
- **2D**: Clustering (discrete vs. diffuse features)
- **3D**: Dependency graph topology (diameter, centrality, communities)
- **4D**: Evolution over time (churn, hotspots, drift)
- **Governance**: Authority alignment, boundary detection

### Q: "How far can Marimo + LLM go?"

**A**: Very far! Marimo provides:
- **Reactive computation**: Only recompute what changed
- **Interactive exploration**: User guides, LLM augments
- **Git-friendly**: Notebooks are `.py` files
- **Local LLM**: No cloud costs, low latency
- **Efficient**: Graph cached, LLM only for queries

---

**Next**: Should I implement this as a Marimo notebook surface?
