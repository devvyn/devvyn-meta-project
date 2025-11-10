# Naming Conventions for Communal Scope Addressable Entities

**Version**: 1.0.0
**Status**: Formal Convention
**Scope**: Meta-project ecosystem (all workspaces)
**Last Updated**: 2025-11-05

---

## Purpose

This document establishes consistent naming conventions for entities that exist in communal scope and must be addressable across workspace boundaries. Consistent naming enables:

- Clear references across documentation
- Unambiguous tool invocation
- Service discovery and composition
- Pattern reuse and citation
- Cross-workspace communication

---

## Entity Categories

### 1. Services

**Format**: `Title Case with Spaces`

**Examples**:
- CSV Magic Reader
- OCR Evaluation Framework
- Audio Budget Manager
- Publication Surface Adapter

**Registry**: `SERVICE_REGISTRY.md`

**Rationale**: Human-readable, professional naming suitable for documentation and citations.

**Constraints**:
- Must be unique within ecosystem
- Should describe functionality clearly
- Avoid abbreviations unless widely known

---

### 2. Patterns

**Format**: `kebab-case.md`

**Location**: `knowledge-base/patterns/{pattern-name}.md`

**Examples**:
- `secure-api-access.md`
- `just-in-time-specificity.md`
- `workspace-boundaries.md`
- `publication-surfaces.md`

**Citation Format**: `[Pattern Name](knowledge-base/patterns/{pattern-name}.md)`

**Rationale**: Lowercase for file system compatibility, hyphens for readability.

**Constraints**:
- Must be unique within patterns directory
- Should be descriptive and memorable
- Avoid version numbers (use versions within file)

---

### 3. Coordination Tools (Public API)

**Format**: `{domain}-{action}.sh` or `{domain}-{action}.py`

**Location**: `~/devvyn-meta-project/scripts/`

**Examples**:
- `bridge-send.sh`
- `bridge-receive.sh`
- `surface-discover.sh`
- `surface-publish.sh`
- `credential-safe-check.sh`
- `validate-boundaries.sh`
- `doc-to-audio.py`

**Domains**:
- `bridge-*` - Bridge communication
- `surface-*` - Publication surfaces
- `credential-*` - Security tools
- `validate-*` - Validation tools
- `doc-*` - Documentation tools

**Rationale**: Namespace prefix prevents collisions, action verb clarifies purpose.

**Constraints**:
- Must not conflict with sub-project tool names
- Must be executable
- Should have matching `--help` documentation

---

### 4. Agents

**Format**: `lowercase` (single word preferred)

**Examples**:
- `code`
- `chat`
- `hopper`
- `investigator`

**Bridge Addressing**: `{agent-name}-{username}-{timestamp}`

**Rationale**: Simple, memorable, easy to type in commands.

**Constraints**:
- Must be unique within agent ecosystem
- Should reflect primary role
- Avoid generic names ("agent1", "helper")

---

### 5. Publication Surfaces

**Format**: `Title Case` (single word or short phrase)

**Examples**:
- Audio
- CLI
- Web
- Email
- SMS
- Terminal UI
- E-Ink

**Documentation**: `knowledge-base/patterns/publication-surfaces.md`

**Rationale**: Clear, professional naming for interface types.

**Constraints**:
- Must describe interface clearly
- Should match industry standard terms where applicable

---

### 6. Knowledge Artifacts (Audio, Video, Generated Content)

**Format**: `{topic}-{type}-{variant}.{ext}`

**Examples**:
- `workspace-boundaries-completion-report.m4a`
- `secure-api-access-CINEMATIC.mp3`
- `jits-implementation-summary.m4a`

**Location**:
- Source: Project-specific (e.g., `/tmp/` for temporary)
- Artifact: `knowledge-base/artifacts/multimedia/{type}/`

**Variants**:
- `CINEMATIC` - Enhanced production with atmosphere
- `BASIC` - Straightforward narration
- `MULTIVOICE` - Multiple narrator voices

**Rationale**: Descriptive filename enables discovery, variant indicates production style.

**Constraints**:
- Topic should match source document name
- Type indicates content category (audio, video, etc.)
- Extension must match actual file format

---

### 7. Documentation Files (Formal Specifications)

**Format**: `SCREAMING_SNAKE_CASE.md` for formal specs, `Title-Case.md` for guides

**Formal Specifications**:
- `WORKSPACE_BOUNDARIES.md`
- `INVARIANTS.md`
- `OPERATIONS_REFERENCE.md`
- `CLAUDE.md`

**Guides and References**:
- `QUICKSTART.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`

**Rationale**: SCREAMING_SNAKE_CASE signals "formal, important, read me first". Title-Case for conventional guides.

**Constraints**:
- Formal specs must be at workspace root
- Guides can be in root or docs/
- Must not conflict across workspaces (except explicit mirrors)

---

### 8. Configuration Files

**Format**: `{domain}-{purpose}.{ext}`

**Examples**:
- `audio-budget.json`
- `config.default.toml`
- `pre-commit-config.yaml`

**Location**: Project-specific (usually `config/` or root)

**Rationale**: Domain prefix groups related configs, purpose clarifies usage.

**Constraints**:
- Should be self-documenting through name
- Must include extension matching format

---

### 9. Bridge Messages

**Format**: `{timestamp}-{from}-to-{to}-{priority}-{subject-slug}.md`

**Example**: `20251105-120000-code-to-chat-normal-boundary-spec-complete.md`

**Location**: `~/infrastructure/agent-bridge/bridge/queue/`

**Rationale**: Sortable by time, clear routing, searchable subject.

**Constraints**:
- Timestamp must be ISO 8601 compatible
- From/to must be valid agent names
- Priority must be: critical, high, normal, info
- Subject slug must be kebab-case

---

### 10. Sub-Projects

**Format**: `{organization}-{project}-{domain}-{year}` (if applicable)

**Examples**:
- `aafc-herbarium-dwc-extraction-2025`
- `devvyn-meta-project`

**Location**: `~/Documents/GitHub/{project-name}/`

**Rationale**: Organization prefix prevents conflicts, year indicates context vintage.

**Constraints**:
- Must be valid Git repository name
- Should be descriptive enough to understand purpose
- Year suffix optional (use when project is time-bound)

---

## Cross-Reference Formats

### Referencing Services

**Format**: `[Service Name] service` in prose

**Example**:
```markdown
The CSV Magic Reader service provides intelligent parsing...
```

**Registry Reference**:
```markdown
See [SERVICE_REGISTRY.md](~/devvyn-meta-project/SERVICE_REGISTRY.md)
```

---

### Referencing Patterns

**Format**: `[Pattern Name] pattern` in prose

**Example**:
```markdown
Following the Workspace Boundaries pattern, we ensure...
```

**Link**:
```markdown
See [Workspace Boundaries](~/devvyn-meta-project/knowledge-base/patterns/workspace-boundaries.md)
```

---

### Referencing Tools

**Format**: Inline code with full path

**Example**:
```markdown
Use `~/devvyn-meta-project/scripts/validate-boundaries.sh` to verify compliance.
```

**Help Reference**:
```bash
~/devvyn-meta-project/scripts/validate-boundaries.sh --help
```

---

### Referencing Agents

**Format**: Lowercase name with "agent" suffix in prose

**Example**:
```markdown
The code agent implements technical features while the chat agent handles strategic decisions.
```

**Bridge Address**:
```markdown
Send message via: `./scripts/bridge-send.sh code chat normal "Subject" file.md`
```

---

### Referencing Publication Surfaces

**Format**: Title Case in prose

**Example**:
```markdown
This content is available through multiple publication surfaces: Audio, Web, and CLI.
```

**Pattern Reference**:
```markdown
See [Publication Surfaces](knowledge-base/patterns/publication-surfaces.md)
```

---

## Namespace Isolation Rules

### Meta-Project Namespace

**Reserved Prefixes**:
- `bridge-*` - Bridge communication
- `surface-*` - Publication surfaces
- `credential-*` - Security tools
- `validate-*` - Validation tools
- `doc-*` - Documentation tools

**Rationale**: These prefixes are reserved for meta-project coordination tools and must not be used in sub-projects.

---

### Sub-Project Namespace

**Guidelines**:
- Use domain-specific prefixes (e.g., `herbarium-*`, `dwc-*`)
- Avoid meta-project reserved prefixes
- Can invoke meta-project public API tools
- Must not shadow meta-project tool names

**Validation**: `validate-boundaries.sh --check-namespace`

---

## Communal Scope Registry

### What Belongs in Communal Scope

**Services**: Yes - if useful to multiple projects

**Patterns**: Yes - if reusable across contexts

**Tools**: Meta-project tools only (public API)

**Knowledge Artifacts**: Yes - if educational/reference value

**Domain Code**: No - belongs in sub-project

**Domain Tests**: No - belongs in sub-project

**Domain Docs**: No - belongs in sub-project (unless contributing pattern)

---

## Deprecation and Versioning

### Services

**Versioning**: Semantic versioning in registry entry

**Deprecation**: Mark as `deprecated` in SERVICE_REGISTRY.md, provide migration path

**Format**:
```yaml
- service: Old Service Name
  status: deprecated
  deprecated_since: 2025-11-01
  replacement: New Service Name
```

---

### Patterns

**Versioning**: Version number in frontmatter

**Deprecation**: Add deprecation notice at top, link to replacement

**Format**:
```markdown
> **DEPRECATED**: This pattern is deprecated as of 2025-11-01.
> See [New Pattern](new-pattern.md) for the current approach.
```

---

### Tools

**Versioning**: `--version` flag should return version

**Deprecation**: Print deprecation warning, exit code 0, suggest replacement

**Format**:
```bash
#!/usr/bin/env bash
echo "WARNING: old-tool.sh is deprecated. Use new-tool.sh instead."
echo "See: ~/devvyn-meta-project/docs/migration/old-to-new.md"
# Still execute for backward compatibility
```

---

## Validation

### Automated Checks

**Script**: `~/devvyn-meta-project/scripts/validate-names.sh` (to be created)

**Checks**:
1. Service names unique in registry
2. Pattern filenames match convention
3. Tool names don't collide with sub-projects
4. Agent names unique
5. No reserved prefix violations

---

### Manual Review

**Pre-commit checklist**:
- [ ] New service added to SERVICE_REGISTRY.md
- [ ] Pattern filename follows kebab-case
- [ ] Tool name uses appropriate domain prefix
- [ ] No namespace collisions with meta-project

---

## Examples by Use Case

### Registering a New Service

```yaml
# In SERVICE_REGISTRY.md
- service: Specimen Image Classifier
  project: aafc-herbarium-dwc-extraction-2025
  version: 1.0.0
  capabilities:
    - Image classification
    - Confidence scoring
  status: active
```

**Reference in docs**:
```markdown
The Specimen Image Classifier service provides automated taxonomic classification...
```

---

### Creating a New Pattern

**File**: `knowledge-base/patterns/async-batch-processing.md`

**Frontmatter**:
```markdown
# Pattern: Async Batch Processing

**Category**: Processing Architecture
**Version**: 1.0.0
**Source**: aafc-herbarium-dwc-extraction-2025
```

**Citation**:
```markdown
See [Async Batch Processing](knowledge-base/patterns/async-batch-processing.md)
```

---

### Creating a New Tool

**File**: `scripts/specimen-validator.sh`

**Header**:
```bash
#!/usr/bin/env bash
#
# specimen-validator.sh - Validate specimen data quality
#
# Usage:
#   ./specimen-validator.sh <data-file>
```

**Reference**:
```markdown
Validate using `~/devvyn-meta-project/scripts/specimen-validator.sh data.csv`
```

---

### Generating Knowledge Artifact

**Command**:
```bash
~/devvyn-meta-project/scripts/doc-to-audio.py \
  --input ~/devvyn-meta-project/knowledge-base/patterns/workspace-boundaries.md \
  --output ~/Desktop/workspace-boundaries-pattern-CINEMATIC.mp3 \
  --provider elevenlabs \
  --multi-voice
```

**Result**: `workspace-boundaries-pattern-CINEMATIC.mp3`

**Catalog**:
```markdown
# In knowledge-base/artifacts/multimedia/audio/INVENTORY.md
- workspace-boundaries-pattern-CINEMATIC.mp3
  Source: knowledge-base/patterns/workspace-boundaries.md
  Provider: ElevenLabs
  Style: Cinematic (multi-voice, atmosphere)
  Duration: 18:42
```

---

## Changelog

### 1.0.0 (2025-11-05)
- Initial naming conventions established
- Nine entity categories defined
- Namespace isolation rules
- Cross-reference formats
- Validation guidelines

---

## References

**Workspace Boundaries**: [WORKSPACE_BOUNDARIES.md](./WORKSPACE_BOUNDARIES.md)
**Platform Nomenclature**: [PLATFORM_NOMENCLATURE.md](./PLATFORM_NOMENCLATURE.md)
**Service Registry**: [SERVICE_REGISTRY.md](./SERVICE_REGISTRY.md)

---

**Status**: Production-ready, applies to all workspaces in meta-project ecosystem.
