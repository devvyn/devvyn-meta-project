# Pattern: Workspace Boundaries

**Category**: Coordination Architecture
**Maturity**: Production (v1.0.0)
**Source**: Meta-project ↔ Sub-project coordination (2025-11-05)
**Confidence**: HIGH (formally specified, validated)

---

## Problem

Multi-workspace systems suffer from:
- Unclear ownership → conflicting modifications
- Security leaks → credentials in wrong locations
- Tight coupling → changes cascade unpredictably
- Knowledge silos → patterns not reused
- Testing confusion → gaps and duplicates

Without explicit boundaries, workspaces drift toward:
- File duplication
- Circular dependencies
- Authority conflicts
- Stale registrations

---

## Solution

**Formal boundary specification** defining:

1. **File Ownership**: Exclusive paths (no overlaps)
2. **Security Zones**: Credentials isolated to coordination workspace
3. **Service Contracts**: Registration protocol for cross-workspace services
4. **Pattern Flow**: Upward contribution (implementation → coordination)
5. **Testing Responsibility**: Clear ownership per module
6. **Documentation Authority**: Single source of truth per concept

**Implementation**: TLA+ specification with 10 invariants, mirrored to all workspaces, automated validation.

---

## Structure

### Two Workspace Types

**Coordination Workspace** (Meta-Project):
```
~/devvyn-meta-project/
├── agents/                  # Agent instructions
├── knowledge-base/          # Reusable patterns
├── scripts/                 # Shared coordination tools
├── WORKSPACE_BOUNDARIES.md  # Formal specification
└── INVARIANTS.md            # System-wide invariants
```

**Authority**: Patterns, protocols, agent behavior, security infrastructure

**Implementation Workspace** (Sub-Project):
```
~/Documents/GitHub/{project}/
├── src/                     # Domain implementation
├── tests/                   # Domain tests
├── docs/                    # Domain documentation
├── WORKSPACE_BOUNDARIES.md  # Mirrored specification
└── CLAUDE.md                # Workspace instructions
```

**Authority**: Domain logic, scientific/business validation, production code

---

## Key Invariants

### INV-1: File Ownership Exclusivity
```tla
∀ f ∈ metaFiles : ∀ sp ∈ SubProjects : f ∉ subFiles[sp]
```

**Meaning**: No file path exists in both workspaces
**Exception**: WORKSPACE_BOUNDARIES.md (mirrored by design)

### INV-2: Credentials in Meta Only
```tla
∀ sp ∈ SubProjects : ∀ f ∈ subFiles[sp] : SecurityLevel(f) ≠ SECRET
```

**Meaning**: Credentials never stored in implementation workspaces
**Implementation**: ~/Secrets/ managed by meta-project only

### INV-3: Service Registration
```tla
∀ sp ∈ SubProjects : OffersService(sp) ⇒ sp ∈ DOMAIN ServiceRegistry
```

**Meaning**: Services must register with coordination workspace
**Implementation**: SERVICE_REGISTRY.md in meta-project

### INV-4: Pattern Flow Upward
```tla
∀ pattern ∈ knowledgeGraph :
  Source(pattern) ∈ SubProjects ⇒ pattern ∈ metaFiles
```

**Meaning**: Reusable patterns flow from implementation to coordination
**Implementation**: Contribute to knowledge-base/patterns/

---

## Usage

### For New Sub-Projects

**1. Copy boundary specification**:
```bash
cp ~/devvyn-meta-project/WORKSPACE_BOUNDARIES.md ./{project}/
```

**2. Add to CLAUDE.md**:
```markdown
## Workspace Boundaries

**Formal specification**: [WORKSPACE_BOUNDARIES.md](./WORKSPACE_BOUNDARIES.md)

**This workspace authority**: {domain implementation}
**Meta-project authority**: Patterns, protocols, security
```

**3. Validate compliance**:
```bash
~/devvyn-meta-project/scripts/validate-boundaries.sh --project {project}
```

### For Existing Sub-Projects

**Audit current state**:
```bash
# Check for boundary violations
~/devvyn-meta-project/scripts/validate-boundaries.sh --project {project}

# Common issues:
# - Credentials in sub-project (.env files, API keys)
# - Services not registered
# - Script name collisions
# - Missing WORKSPACE_BOUNDARIES.md
```

**Remediate**:
1. Move credentials to ~/Secrets/ (meta-project managed)
2. Register services with meta-project
3. Rename conflicting scripts
4. Mirror WORKSPACE_BOUNDARIES.md
5. Update CLAUDE.md

---

## Authority Domains

### Coordination (Meta-Project)

**Owns**:
- Agent instructions (CLAUDE.md, CHAT_AGENT_INSTRUCTIONS.md, etc.)
- Cross-project patterns (knowledge-base/patterns/)
- Coordination tools (bridge-send.sh, surface-discover.sh, etc.)
- Service registry (SERVICE_REGISTRY.md)
- Security infrastructure (credential-safe-check.sh, etc.)

**Responsibilities**:
- Maintain agent behavior consistency
- Document reusable patterns
- Test pattern implementations
- Validate workspace boundaries

### Implementation (Sub-Project)

**Owns**:
- Domain source code (src/)
- Domain tests (tests/)
- Domain documentation (docs/)
- Domain tools (domain-specific scripts)

**Responsibilities**:
- Implement domain functionality
- Validate correctness (scientific, business)
- Test thoroughly
- Contribute reusable patterns upward

---

## Security Boundaries

### Credential Storage

**Rule**: Credentials ONLY in meta-project

```
SECRET:  ~/Secrets/approved-for-agents/  (meta-project)
PRIVATE: ~/devvyn-meta-project/          (git-ignored)
PUBLIC:  ~/Documents/GitHub/*/           (sub-projects)
```

### Credential Access

**Sub-projects** (safe reference):
```python
import os
api_key = os.environ.get("ANTHROPIC_API_KEY")  # ✅ OK
```

**Sub-projects** (FORBIDDEN):
```python
with open("~/Secrets/openrouter.key") as f:  # ❌ NEVER
    api_key = f.read()
```

**Meta-project provides**:
```bash
# Safe checking
~/devvyn-meta-project/scripts/credential-safe-check.sh env ANTHROPIC_API_KEY

# Leak scanning
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --dir ~/Documents/GitHub/project/
```

---

## Service Registration

### Protocol

**1. Implement service** (sub-project)
**2. Test thoroughly** (sub-project tests/)
**3. Document API** (sub-project docs/)
**4. Register** (meta-project SERVICE_REGISTRY.md)

### Registry Entry

```yaml
- service: CSV Magic Reader
  project: aafc-herbarium-dwc-extraction-2025
  version: 1.2.0
  capabilities:
    - Intelligent CSV parsing
    - Automatic type inference
  status: active
```

### Discovery

```bash
# List all services
~/devvyn-meta-project/scripts/list-services.sh

# Query service
~/devvyn-meta-project/scripts/service-info.sh "CSV Magic Reader"
```

---

## Pattern Contribution

### Flow: Implementation → Coordination

**Discovery**: Sub-project implements reusable solution

**Documentation**: Sub-project documents locally first

**Proposal**: Via bridge message or PR
```bash
~/devvyn-meta-project/scripts/bridge-send.sh \
  {sub-project} \
  code \
  normal \
  "Pattern proposal: API Key Auto-Rotation" \
  /tmp/pattern-proposal.md
```

**Generalization**: Meta-project removes domain specifics

**Publication**: Added to knowledge-base/patterns/

**Citation**: Meta-project cites sub-project as source

### Example

```
Herbarium implements: Auto-rotation for long-running batch jobs
    ↓
Meta-project extracts: "API Key Auto-Rotation Pattern"
    ↓
Pattern available: knowledge-base/patterns/api-key-rotation.md
    ↓
All sub-projects benefit
```

---

## Testing Boundaries

### Coordination Tests (Meta-Project)

**Scope**: Patterns, tools, protocols

**Examples**:
- Bridge message validation
- JITS pattern compliance
- Tool integration tests

### Implementation Tests (Sub-Project)

**Scope**: Domain logic, correctness

**Examples**:
- OCR accuracy validation
- Business rule verification
- API response handling

### Contract Tests (Both)

**Scope**: Service interfaces

**Implementation**:
- Sub-project tests own implementation
- Meta-project tests integration with other services

---

## Validation

### Automated Checks

**Script**: `~/devvyn-meta-project/scripts/validate-boundaries.sh`

**Validates**:
1. File ownership exclusivity
2. Security boundaries (no credentials in sub-projects)
3. Service registrations complete
4. Tool namespace unique
5. Boundary doc symmetry (both workspaces reference)
6. WORKSPACE_BOUNDARIES.md mirroring (identical)

**Usage**:
```bash
# Validate all
~/devvyn-meta-project/scripts/validate-boundaries.sh

# Validate specific project
~/devvyn-meta-project/scripts/validate-boundaries.sh --project {name}

# Auto-fix where possible
~/devvyn-meta-project/scripts/validate-boundaries.sh --fix
```

### Manual Checklist

- [ ] WORKSPACE_BOUNDARIES.md in both locations
- [ ] WORKSPACE_BOUNDARIES.md checksums match
- [ ] CLAUDE.md references boundaries
- [ ] No credentials in sub-project
- [ ] Services registered
- [ ] No script name collisions

---

## Benefits

**Clarity**: Explicit ownership eliminates conflicts

**Security**: Credentials isolated, leaks prevented

**Reusability**: Patterns flow systematically to knowledge base

**Testing**: Clear responsibility, no gaps or duplication

**Scalability**: New sub-projects adopt pattern easily

**Maintenance**: Automated validation catches drift

---

## Anti-Patterns

### ❌ Implicit Boundaries

**Problem**: "Everyone knows" where things go
**Result**: Conflicts, confusion, drift

### ❌ Credential Duplication

**Problem**: Each workspace manages own secrets
**Result**: Leaks, rotation failures, audit complexity

### ❌ Tight Coupling

**Problem**: Sub-projects import meta-project internals
**Result**: Changes cascade, testing difficult

### ❌ Pattern Hoarding

**Problem**: Reusable solutions stay in sub-projects
**Result**: Reinvention, inconsistency

### ❌ Manual Validation

**Problem**: Rely on humans to check boundaries
**Result**: Drift, violations accumulate

---

## Related Patterns

- [Secure API Access](./secure-api-access.md) - Credential handling within boundaries
- [Just-In-Time Specificity](./just-in-time-specificity.md) - Context management across workspaces
- [Publication Surfaces](./publication-surfaces.md) - Cross-workspace interface patterns
- [Scientific Provenance](../../Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/SCIENTIFIC_PROVENANCE_PATTERN.md) - Domain-specific boundary example

---

## References

**Formal Specification**: [WORKSPACE_BOUNDARIES.md](../WORKSPACE_BOUNDARIES.md)
**System Invariants**: [INVARIANTS.md](../INVARIANTS.md)
**Example Implementation**: [aafc-herbarium-dwc-extraction-2025](~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/)

---

## Changelog

### 1.0.0 (2025-11-05)
- Initial pattern documentation
- TLA+ formal specification
- Herbarium workspace as reference implementation
- Automated validation tooling

---

**Status**: Production-ready, validated with herbarium workspace
