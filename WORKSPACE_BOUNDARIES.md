# Workspace Boundary Specification (TLA+)

**Version**: 1.0.0
**Status**: Formal Specification
**Scope**: Template for all meta-project ↔ sub-project boundaries
**Last Updated**: 2025-11-05

---

## Abstract

This document specifies the formal boundary conditions between the meta-project coordination workspace and all sub-project workspaces. The specification uses TLA+ notation to define invariants that must hold across workspace interactions, ensuring clean separation of concerns, security isolation, and systematic collaboration.

**Key Principle**: Workspaces are autonomous domains with explicit, minimal coupling through well-defined contracts.

---

## TLA+ Specification

```tla
---------------------- MODULE WorkspaceBoundaries ----------------------

EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS
    MetaProjectPath,        \* ~/devvyn-meta-project/
    SubProjects,            \* Set of all sub-project paths
    Agents,                 \* {code, chat, hopper, investigator, ...}
    SecurityLevels,         \* {SECRET, PRIVATE, PUBLISHED}
    ServiceRegistry         \* Canonical service catalog

VARIABLES
    metaFiles,              \* Files owned by meta-project
    subFiles,               \* Files owned by sub-projects (function: SubProject → FileSet)
    sharedServices,         \* Registered services available cross-workspace
    activeAgents,           \* Currently active agent sessions
    credentialStore,        \* Secret storage location
    knowledgeGraph          \* Accumulated patterns and learnings

vars == <<metaFiles, subFiles, sharedServices, activeAgents, credentialStore, knowledgeGraph>>

-----------------------------------------------------------------------------
\* INVARIANTS - Conditions that must ALWAYS hold
-----------------------------------------------------------------------------

\* INV-1: File Ownership Exclusivity
\* No file can exist in both meta-project and sub-project simultaneously
FileOwnershipExclusive ==
    ∀ f ∈ metaFiles : ∀ sp ∈ DOMAIN subFiles : f ∉ subFiles[sp]

\* INV-2: Security Boundary Separation
\* Credentials never stored in sub-project workspaces
CredentialsInMetaOnly ==
    ∀ sp ∈ DOMAIN subFiles :
        ∀ f ∈ subFiles[sp] : SecurityLevel(f) ≠ SECRET

\* INV-3: Bidirectional References
\* If sub-project references meta-project boundary doc, meta-project must reference sub-project
BoundaryDocSymmetry ==
    ∀ sp ∈ SubProjects :
        ReferencesMetaBoundaries(sp) ⇒ MetaReferencesSubProject(sp)

\* INV-4: Service Registration Protocol
\* Sub-projects offering services must register with meta-project
ServicesMustRegister ==
    ∀ sp ∈ SubProjects :
        OffersService(sp) ⇒ sp ∈ DOMAIN ServiceRegistry

\* INV-5: Tool Namespace Isolation
\* Scripts in ~/devvyn-meta-project/scripts/ cannot have same name as sub-project scripts
ToolNamespaceUnique ==
    ∀ sp ∈ SubProjects :
        ScriptNames(MetaProjectPath) ∩ ScriptNames(sp) = {}

\* INV-6: Testing Responsibility Clarity
\* Every module has exactly one workspace responsible for testing it
TestingResponsibilityUnique ==
    ∀ module ∈ (metaFiles ∪ UNION {subFiles[sp] : sp ∈ DOMAIN subFiles}) :
        ∃! workspace : ResponsibleForTesting(workspace, module)

\* INV-7: Documentation Authority
\* Each concept has a single authoritative documentation location
DocumentationAuthoritySingle ==
    ∀ concept ∈ Concepts :
        |{workspace : IsAuthority(workspace, concept)}| = 1

\* INV-8: Pattern Contribution Flow
\* Sub-projects can contribute patterns to meta-project, not vice versa
PatternFlowUpward ==
    ∀ pattern ∈ knowledgeGraph :
        Source(pattern) ∈ (SubProjects ∪ {MetaProjectPath})
        ∧ (Source(pattern) ∈ SubProjects ⇒ pattern ∈ metaFiles)

\* INV-9: Agent Session Isolation
\* An agent can have at most one active session per workspace at a time
AgentSessionIsolation ==
    ∀ agent ∈ Agents :
        ∀ ws1, ws2 ∈ (SubProjects ∪ {MetaProjectPath}) :
            HasActiveSession(agent, ws1) ∧ HasActiveSession(agent, ws2)
            ⇒ ws1 = ws2

\* INV-10: Security Classification Consistency
\* Files with same content must have same security classification across workspaces
SecurityClassificationConsistent ==
    ∀ f1, f2 ∈ (metaFiles ∪ UNION {subFiles[sp] : sp ∈ DOMAIN subFiles}) :
        Content(f1) = Content(f2) ⇒ SecurityLevel(f1) = SecurityLevel(f2)

-----------------------------------------------------------------------------
\* OPERATORS - Permitted Cross-Boundary Operations
-----------------------------------------------------------------------------

\* OP-1: Service Registration
RegisterService(subProject, serviceName, version, capabilities) ==
    /\ subProject ∈ SubProjects
    /\ ServiceRegistry' = ServiceRegistry ∪ {
        [project ↦ subProject,
         name ↦ serviceName,
         version ↦ version,
         capabilities ↦ capabilities]
       }
    /\ UNCHANGED <<metaFiles, subFiles, activeAgents, credentialStore, knowledgeGraph>>

\* OP-2: Pattern Contribution
ContributePattern(subProject, pattern, documentation) ==
    /\ subProject ∈ SubProjects
    /\ pattern ∉ knowledgeGraph
    /\ knowledgeGraph' = knowledgeGraph ∪ {pattern}
    /\ metaFiles' = metaFiles ∪ {documentation}
    /\ UNCHANGED <<subFiles, sharedServices, activeAgents, credentialStore>>

\* OP-3: Credential Access (Safe Reference)
ReferenceCredential(subProject, credentialName) ==
    /\ subProject ∈ SubProjects
    /\ credentialName ∈ DOMAIN credentialStore
    /\ SubProjectUsesEnvVar(subProject, credentialName)  \* Reference only, never reads file
    /\ UNCHANGED vars

\* OP-4: Tool Invocation
InvokeMetaTool(subProject, toolName, args) ==
    /\ subProject ∈ SubProjects
    /\ toolName ∈ MetaToolRegistry
    /\ IsPublicAPI(toolName)  \* Only tools explicitly marked public
    /\ UNCHANGED <<metaFiles, subFiles>>  \* Tools read-only from sub-project perspective

\* OP-5: Documentation Cross-Reference
CrossReferenceDoc(sourceWorkspace, targetWorkspace, docPath) ==
    /\ sourceWorkspace ∈ (SubProjects ∪ {MetaProjectPath})
    /\ targetWorkspace ∈ (SubProjects ∪ {MetaProjectPath})
    /\ sourceWorkspace ≠ targetWorkspace
    /\ IsPublicDoc(targetWorkspace, docPath)
    /\ UNCHANGED vars  \* References are read-only

-----------------------------------------------------------------------------
\* SAFETY PROPERTIES - What CANNOT happen
-----------------------------------------------------------------------------

\* SAFETY-1: No Credential Leaks
\* Sub-projects never write credential values to their files
NoCredentialLeaks ==
    □[∀ sp ∈ SubProjects :
        ∀ f ∈ subFiles[sp] :
            ∀ cred ∈ DOMAIN credentialStore :
                Value(cred) ∉ Content(f)]_vars

\* SAFETY-2: No Circular Dependencies
\* Meta-project cannot depend on sub-project internals (only registered services)
NoCircularDependencies ==
    □[∀ sp ∈ SubProjects :
        ∀ f ∈ metaFiles :
            ∀ spFile ∈ subFiles[sp] :
                DirectImport(f, spFile) ⇒ spFile ∈ sharedServices]_vars

\* SAFETY-3: No Stale Registrations
\* If service no longer exists, it cannot remain registered
NoStaleRegistrations ==
    □[∀ service ∈ ServiceRegistry :
        ∃ sp ∈ SubProjects :
            ServiceImplementationExists(sp, service)]_vars

\* SAFETY-4: No Authority Conflicts
\* Two workspaces cannot both claim authority over same concept
NoAuthorityConflicts ==
    □[∀ concept ∈ Concepts :
        |{ws : ClaimsAuthority(ws, concept)}| ≤ 1]_vars

-----------------------------------------------------------------------------
\* LIVENESS PROPERTIES - What MUST eventually happen
-----------------------------------------------------------------------------

\* LIVENESS-1: Patterns Eventually Propagate
\* Reusable patterns discovered in sub-projects must eventually be documented in meta-project
PatternsPropagate ==
    ∀ sp ∈ SubProjects :
        IsReusablePattern(sp, pattern)
        ⇝ pattern ∈ knowledgeGraph

\* LIVENESS-2: Services Eventually Registered
\* Sub-projects offering services must eventually register them
ServicesEventuallyRegistered ==
    ∀ sp ∈ SubProjects :
        OffersService(sp)
        ⇝ sp ∈ DOMAIN ServiceRegistry

\* LIVENESS-3: Boundary Violations Eventually Resolved
\* If a boundary is violated, it must eventually be fixed
BoundaryViolationsResolved ==
    ∀ violation ∈ DetectedViolations :
        violation ∈ DetectedViolations
        ⇝ violation ∉ DetectedViolations

-----------------------------------------------------------------------------
\* HELPER PREDICATES
-----------------------------------------------------------------------------

\* Check if sub-project references meta-project boundaries
ReferencesMetaBoundaries(subProject) ==
    ∃ f ∈ subFiles[subProject] :
        "WORKSPACE_BOUNDARIES.md" ∈ ReferencedDocs(f)

\* Check if meta-project tracks sub-project
MetaReferencesSubProject(subProject) ==
    ∃ f ∈ metaFiles :
        subProject ∈ TrackedSubProjects(f)

\* Check if sub-project offers services
OffersService(subProject) ==
    ∃ service : ImplementsService(subProject, service)

\* Check if workspace has active agent session
HasActiveSession(agent, workspace) ==
    ∃ session ∈ activeAgents :
        session.agent = agent ∧ session.workspace = workspace

\* Check if tool is marked for public API
IsPublicAPI(toolName) ==
    toolName ∈ PublicMetaTools

\* Check if document is marked public
IsPublicDoc(workspace, docPath) ==
    SecurityLevel(docPath) ∈ {PUBLISHED, PRIVATE}  \* Not SECRET

\* Check if file directly imports another
DirectImport(file1, file2) ==
    file2 ∈ ParsedImports(file1)

-----------------------------------------------------------------------------

TypeInvariant ==
    /\ metaFiles ⊆ AllFiles
    /\ ∀ sp ∈ DOMAIN subFiles : subFiles[sp] ⊆ AllFiles
    /\ sharedServices ⊆ ServiceRegistry
    /\ activeAgents ⊆ (Agents × (SubProjects ∪ {MetaProjectPath}))

Invariant ==
    /\ TypeInvariant
    /\ FileOwnershipExclusive
    /\ CredentialsInMetaOnly
    /\ BoundaryDocSymmetry
    /\ ServicesMustRegister
    /\ ToolNamespaceUnique
    /\ TestingResponsibilityUnique
    /\ DocumentationAuthoritySingle
    /\ PatternFlowUpward
    /\ AgentSessionIsolation
    /\ SecurityClassificationConsistent

=============================================================================
```

---

## Implementation Mapping

### Workspace Paths

**Meta-Project** (Coordination & Patterns):
```
~/devvyn-meta-project/
├── agents/                    # Agent instruction files
├── knowledge-base/            # Patterns, theory, artifacts
├── scripts/                   # Shared coordination tools
├── CLAUDE.md                  # Meta-project agent instructions
├── INVARIANTS.md              # Formal invariants (includes boundaries)
└── WORKSPACE_BOUNDARIES.md    # This document
```

**Sub-Projects** (Domain Implementation):
```
~/Documents/GitHub/{sub-project}/
├── src/                       # Domain-specific implementation
├── tests/                     # Domain-specific tests
├── docs/                      # Domain-specific documentation
├── CLAUDE.md                  # Sub-project agent instructions
└── WORKSPACE_BOUNDARIES.md    # Mirrored boundary spec
```

---

## Authority Domains

### Meta-Project Authority (Coordination)

**Owns**:
- Agent instruction files (CLAUDE.md, CHAT_AGENT_INSTRUCTIONS.md, etc.)
- Cross-project patterns (knowledge-base/patterns/)
- Coordination protocols (bridge, JITS, publication surfaces)
- Shared tooling (scripts/ - coordination tools only)
- Service registry (canonical list of sub-project services)
- Security infrastructure (credential management, scanning tools)

**Responsibilities**:
- Maintain agent behavioral consistency
- Document reusable patterns from sub-projects
- Provide coordination tools (bridge-send.sh, etc.)
- Test pattern implementations
- Validate workspace boundary compliance

### Sub-Project Authority (Domain Implementation)

**Owns**:
- Domain-specific source code (src/)
- Domain-specific tests (tests/)
- Domain-specific documentation (docs/)
- Domain-specific tooling (scripts/ - domain tools)
- Production configurations
- Scientific/business logic

**Responsibilities**:
- Implement domain functionality
- Validate scientific/business correctness
- Test domain logic thoroughly
- Document domain-specific workflows
- Register services with meta-project
- Contribute reusable patterns upward

### Shared Responsibilities

**Both workspaces**:
- Security: Meta-project provides tools, sub-projects ensure compliance
- Testing: Meta-project tests patterns/tools, sub-projects test domain logic
- Documentation: Each documents own authority domain, cross-references explicitly
- Quality: Both enforce pre-commit hooks, linting, formatting

---

## File Ownership Rules

### Exclusive Ownership

**Rule**: No file path can exist in both workspaces simultaneously

**Exceptions**:
- WORKSPACE_BOUNDARIES.md (mirrored by design, must be identical)
- .gitignore patterns (can overlap, must be consistent on security)

**Validation**:
```bash
# Check for file path collisions
~/devvyn-meta-project/scripts/validate-boundaries.sh --check-ownership
```

### Cross-References

**Permitted**:
- Sub-project documentation can reference meta-project patterns
- Meta-project can reference sub-project services (via registry)
- Symlinks allowed only for approved use cases (e.g., knowledge base artifacts)

**Format**:
```markdown
# In sub-project docs
See [Meta-Project Pattern](~/devvyn-meta-project/knowledge-base/patterns/secure-api-access.md)

# In meta-project docs
See [Herbarium Service](~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/README.md#csv-magic-reader)
```

---

## Security Boundaries

### Credential Storage

**Invariant**: Credentials NEVER stored in sub-project repositories

**Implementation**:
```
SECRET:  ~/Secrets/approved-for-agents/  (meta-project managed)
         Never in ~/Documents/GitHub/*/

PRIVATE: ~/devvyn-meta-project/         (git-ignored secrets/)
         ~/infrastructure/agent-bridge/  (bridge state)

PUBLISHED: ~/Documents/GitHub/*/        (sub-projects)
           Safe to push to public GitHub
```

### Credential Access

**Sub-projects**:
```python
# ✅ CORRECT: Reference environment variable
import os
api_key = os.environ.get("ANTHROPIC_API_KEY")

# ❌ FORBIDDEN: Read credential file
with open("~/Secrets/openrouter.key") as f:
    api_key = f.read()
```

**Meta-project provides**:
```bash
# Safe credential checking
~/devvyn-meta-project/scripts/credential-safe-check.sh keychain SERVICE
~/devvyn-meta-project/scripts/credential-safe-check.sh env VARIABLE

# Credential leak scanning
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --dir ~/Documents/GitHub/project/
```

---

## Service Registration Protocol

### Registration Format

**Location**: `~/devvyn-meta-project/SERVICE_REGISTRY.md`

**Entry Template**:
```yaml
- service: CSV Magic Reader
  project: aafc-herbarium-dwc-extraction-2025
  version: 1.2.0
  path: src/csv_magic_reader.py
  capabilities:
    - Intelligent CSV parsing with automatic type inference
    - Column name normalization
    - Missing data handling
  dependencies:
    - pandas>=2.0.0
  status: active
  documentation: docs/csv_magic_reader.md
```

### Registration Process

1. **Sub-project** implements service
2. **Sub-project** tests service thoroughly
3. **Sub-project** documents service API
4. **Sub-project** submits registration via bridge message or PR
5. **Meta-project** validates and adds to registry
6. **Meta-project** may add service to coordination tools

### Discovery

**Sub-projects can query**:
```bash
# List all available services
~/devvyn-meta-project/scripts/list-services.sh

# Query service capabilities
~/devvyn-meta-project/scripts/service-info.sh "CSV Magic Reader"
```

---

## Tool Namespace Isolation

### Naming Convention

**Meta-project scripts** (coordination):
- `bridge-*.sh` - Bridge communication
- `surface-*.sh` - Publication surfaces
- `validate-*.sh` - Validation tools
- `credential-*.sh` - Security tools
- `*-specificity.sh` - JITS tools

**Sub-project scripts** (domain-specific):
- Domain-specific names (e.g., `export_dwc_archive.py`, `batch_dashboard.py`)
- No overlap with meta-project script names
- Can invoke meta-project public tools

### Public API

**Meta-project tools marked public**:
```bash
# Publication surfaces
~/devvyn-meta-project/scripts/surface-discover.sh    # Public API
~/devvyn-meta-project/scripts/surface-info.sh        # Public API
~/devvyn-meta-project/scripts/surface-publish.sh     # Public API

# Security
~/devvyn-meta-project/scripts/credential-safe-check.sh      # Public API
~/devvyn-meta-project/scripts/credential-leak-scanner.sh    # Public API

# Documentation
~/devvyn-meta-project/scripts/doc-to-audio.py        # Public API
```

**Private tools** (meta-project internal):
- `bridge-register.sh` (internal state management)
- `validate-jits.sh` (meta-project specific)

---

## Testing Responsibilities

### Meta-Project Tests

**Scope**: Coordination patterns, shared tools, agent instructions

**Location**: `~/devvyn-meta-project/tests/` (if created)

**Examples**:
- Bridge message protocol validation
- JITS pattern compliance checking
- Publication surface adapter contracts
- Tool invocation integration tests

### Sub-Project Tests

**Scope**: Domain logic, scientific validation, production workflows

**Location**: `~/Documents/GitHub/{project}/tests/`

**Examples**:
- OCR accuracy validation (herbarium)
- Darwin Core field mapping correctness (herbarium)
- CSV parsing edge cases (herbarium)
- Domain-specific regression tests

### Contract Tests

**Both workspaces test**:
- Service APIs (sub-project tests implementation, meta-project tests integration)
- Tool invocations (meta-project tests tool, sub-project tests usage)
- Security boundaries (both validate credential isolation)

---

## Documentation Authority

### Single Source of Truth

**Principle**: Each concept has exactly one authoritative documentation location

**Examples**:

| Concept | Authority | Location |
|---------|-----------|----------|
| JITS Pattern | Meta-project | `~/devvyn-meta-project/knowledge-base/patterns/just-in-time-specificity.md` |
| Bridge Protocol | Meta-project | `~/devvyn-meta-project/OPERATIONS_REFERENCE.md` |
| Darwin Core Mapping | Herbarium | `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/DATA_PUBLICATION_GUIDE.md` |
| OCR Pipeline | Herbarium | `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/OCR_PIPELINE.md` |
| Agent Coordination | Meta-project | `~/devvyn-meta-project/CLAUDE.md` |
| Herbarium Workflows | Herbarium | `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/CLAUDE.md` |

### Cross-References

**Rule**: When concept is documented in one workspace and referenced in another, use explicit link

**Format**:
```markdown
# Sub-project references meta-project
For credential management, see [Secure API Access Pattern](
  ~/devvyn-meta-project/knowledge-base/patterns/secure-api-access.md
)

# Meta-project references sub-project
Example implementation: [Herbarium OCR Pipeline](
  ~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/OCR_PIPELINE.md
)
```

---

## Pattern Contribution Flow

### Upward Flow (Sub-Project → Meta-Project)

**Process**:
1. **Discover**: Sub-project implements reusable solution
2. **Document**: Sub-project documents pattern locally
3. **Propose**: Sub-project sends bridge message or PR proposing pattern extraction
4. **Generalize**: Meta-project generalizes pattern (removes domain specifics)
5. **Document**: Meta-project adds to `knowledge-base/patterns/`
6. **Cite**: Meta-project cites sub-project as source/example

**Example**:
```
Herbarium implements: API key auto-rotation for long-running batch jobs
    ↓
Meta-project extracts: "API Key Auto-Rotation Pattern"
    ↓
Meta-project documents: knowledge-base/patterns/api-key-rotation.md
    ↓
Pattern available to all sub-projects
```

### No Downward Flow

**Rule**: Meta-project does NOT push patterns to sub-projects

**Rationale**: Sub-projects pull patterns as needed, maintaining autonomy

**Discovery**: Sub-projects can search knowledge base for applicable patterns

---

## Agent Session Isolation

### One Session Per Workspace

**Invariant**: An agent can have at most one active session per workspace at a time

**Implementation**:
- Agent working in meta-project cannot simultaneously work in sub-project
- Context switch requires explicit session handoff
- Bridge messages facilitate async communication between sessions

### Session Handoff Protocol

**From Meta-Project to Sub-Project**:
```bash
# Meta-project agent sends message
~/devvyn-meta-project/scripts/bridge-send.sh \
  code \
  herbarium \
  normal \
  "Boundary specification complete" \
  /tmp/handoff-context.md

# Sub-project agent receives
cd ~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025
~/devvyn-meta-project/scripts/bridge-receive.sh herbarium
```

**Handoff Content**:
```markdown
## Session Handoff Context
**From**: code agent (meta-project)
**To**: code agent (herbarium sub-project)
**Phase**: Workspace boundary establishment
**Completed**: WORKSPACE_BOUNDARIES.md created and validated
**Next**: Implement herbarium-specific boundary compliance
```

---

## Validation

### Automated Validation

**Script**: `~/devvyn-meta-project/scripts/validate-boundaries.sh`

**Checks**:
1. ✅ File ownership exclusivity (no collisions except WORKSPACE_BOUNDARIES.md)
2. ✅ Security boundaries (no credentials in sub-project repos)
3. ✅ Service registrations (all services registered)
4. ✅ Tool namespace uniqueness (no script name collisions)
5. ✅ Boundary doc symmetry (both workspaces reference boundaries)
6. ✅ Documentation authority (no conflicting claims)
7. ✅ WORKSPACE_BOUNDARIES.md mirroring (identical checksums)

**Usage**:
```bash
# Validate all boundaries
~/devvyn-meta-project/scripts/validate-boundaries.sh

# Validate specific sub-project
~/devvyn-meta-project/scripts/validate-boundaries.sh --project aafc-herbarium-dwc-extraction-2025

# Fix violations automatically (where possible)
~/devvyn-meta-project/scripts/validate-boundaries.sh --fix
```

### Manual Verification

**Checklist** (in both workspace CLAUDE.md files):
- [ ] WORKSPACE_BOUNDARIES.md exists in both locations
- [ ] WORKSPACE_BOUNDARIES.md checksums match
- [ ] CLAUDE.md references boundaries
- [ ] No credential files in sub-project
- [ ] Services registered in meta-project
- [ ] No script name collisions
- [ ] Cross-references use full paths

---

## Adoption Template for New Sub-Projects

### Setup Checklist

When creating a new sub-project:

**1. Create sub-project structure**:
```bash
mkdir -p ~/Documents/GitHub/{new-project}
cd ~/Documents/GitHub/{new-project}
```

**2. Copy boundary specification**:
```bash
cp ~/devvyn-meta-project/WORKSPACE_BOUNDARIES.md ./
```

**3. Create CLAUDE.md with boundary reference**:
```markdown
# {Project} - Code Agent Instructions

## Workspace Boundaries

This project operates under formal workspace boundaries defined in:
- Local: [WORKSPACE_BOUNDARIES.md](./WORKSPACE_BOUNDARIES.md)
- Meta-project: [~/devvyn-meta-project/WORKSPACE_BOUNDARIES.md]

**Authority**: This workspace has authority over {domain} implementation.
**Coordination**: Meta-project has authority over patterns and shared tools.
```

**4. Register with meta-project**:
```bash
# Add to meta-project tracking
~/devvyn-meta-project/scripts/register-subproject.sh \
  --name "{new-project}" \
  --path "~/Documents/GitHub/{new-project}" \
  --domain "{domain-description}"
```

**5. Validate compliance**:
```bash
~/devvyn-meta-project/scripts/validate-boundaries.sh --project {new-project}
```

---

## References

**Meta-Project Specifications**:
- [INVARIANTS.md](./INVARIANTS.md) - Complete formal invariants (includes workspace boundaries)
- [OPERATIONS_REFERENCE.md](./OPERATIONS_REFERENCE.md) - Operational procedures
- [QUICKSTART.md](./QUICKSTART.md) - Session startup protocols

**Patterns**:
- [knowledge-base/patterns/workspace-boundaries.md] - Detailed pattern documentation
- [knowledge-base/patterns/secure-api-access.md] - Security boundary implementation

**Sub-Project Examples**:
- [aafc-herbarium-dwc-extraction-2025](~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/) - Reference implementation

---

## Changelog

### 1.0.0 (2025-11-05)
- Initial formal specification
- TLA+ invariants for 10 boundary conditions
- Safety and liveness properties
- Implementation mapping
- Validation tooling
- Adoption template

---

**Formal Verification**: This specification can be checked with TLC model checker.
**Status**: Production-ready for all meta-project ↔ sub-project interactions.
