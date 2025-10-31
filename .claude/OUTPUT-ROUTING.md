# Output Routing Rules for CODE Agent

**Purpose**: Ensure knowledge goes to the right place, not cluttering Desktop
**Status**: Active Policy
**Last Updated**: 2025-10-30

---

## Routing Decision Tree

```
Output Created
    │
    ├─ Is it procedural knowledge? (patterns, guides, architecture)
    │   └─ YES → `docs/` directory (master record) + git commit
    │
    ├─ Is it temporary/exploratory? (scratch, experiments)
    │   └─ YES → `/tmp/` or `kitchen/` directory
    │
    ├─ Is it a session artifact? (completion summary, progress report)
    │   └─ YES → `status/` or `knowledge-base/sessions/`
    │
    ├─ Does it need human review? (decisions, approvals)
    │   └─ YES → `~/inbox/` (human accountability system)
    │
    ├─ Is it a long-form document? (>24 lines)
    │   └─ YES → markdown-to-browser.sh (for reading, not storage)
    │
    └─ Is it data/artifacts? (exports, datasets, builds)
        └─ YES → `artifacts/` or project-specific output directory
```

---

## Routing Rules by Type

### Procedural Knowledge (MASTER: `docs/`)

**Examples**: Patterns, guides, architecture, protocols, specifications

**Destination**:

```
~/devvyn-meta-project/
├── docs/
│   ├── abstractions/          # Universal patterns
│   ├── configuration/         # Customization guides
│   ├── platform/              # Platform dependencies
│   ├── branching/             # Domain transfer guides
│   ├── roadmap/               # Capability gaps, optimization
│   ├── getting-started/       # Tutorials, quick starts
│   ├── patterns/              # Pattern library
│   ├── troubleshooting/       # Playbooks
│   └── adr/                   # Architecture Decision Records
```

**Process**:

1. Create in `docs/` immediately
2. Commit to git (version control)
3. Reference from `knowledge-base/coordination-system/KB-INDEX.md`
4. If long, also route to browser for reading

**NOT**: Desktop (creates clutter, hard to find later)

### Session Artifacts (MASTER: `status/` or `knowledge-base/sessions/`)

**Examples**: Completion summaries, progress reports, daily check-ins

**Destination**:

```
~/devvyn-meta-project/
├── status/
│   ├── current-project-state.json
│   └── session-reports/
│       └── YYYYMMDD-session-summary.md
│
└── knowledge-base/
    └── sessions/
        ├── 2025-10/
        │   └── 20251030-phase1-completion.md
```

**Process**:

1. Create in `status/session-reports/` or `knowledge-base/sessions/YYYY-MM/`
2. Commit to git
3. If important, update `current-project-state.json`

### Temporary/Exploratory (MASTER: `/tmp/` or `kitchen/`)

**Examples**: Scratch notes, experiments, prototypes

**Destination**:

```
/tmp/                          # Truly temporary (auto-cleaned)

~/devvyn-meta-project/
└── kitchen/
    └── active-experiments/
        ├── duckdb-overlay/    # User's near-future research
        ├── cli-gui-bridge/
        └── experiment-name/
```

**Process**:

1. Create in `/tmp/` if truly disposable
2. Create in `kitchen/` if might be valuable later
3. Promote to `docs/` if proven valuable

### Human Review (MASTER: `~/inbox/`)

**Examples**: Decision requests, approval needed, questions

**Destination**:

```
~/inbox/
├── status.json                # Accountability tracking
├── decisions/
├── reviews/
└── questions/
```

**Process**:

1. Create in `~/inbox/` subdirectory
2. Update `~/inbox/status.json` with new item
3. Send bridge message to human if HIGH/CRITICAL priority

### Long Documents (DISPLAY: Browser, STORE: `docs/`)

**Examples**: Any markdown >24 lines

**Process**:

1. Create in proper `docs/` location (master)
2. Call `markdown-to-browser.sh` for display
3. Browser copy in `/tmp/` is ephemeral (OK to lose)

### Data/Artifacts (MASTER: `artifacts/` or project-specific)

**Examples**: Exports, datasets, build outputs, generated files

**Destination**:

```
~/devvyn-meta-project/
└── artifacts/
    ├── exports/
    ├── datasets/
    └── builds/

# OR project-specific
~/Documents/GitHub/project-name/
└── output/
```

**Process**:

1. Create in project-appropriate location
2. Consider content-addressing if provenance important
3. Archive old versions periodically

---

## Anti-Pattern: Desktop as Storage

### ❌ DON'T

```bash
# Creating "posterity" copies on Desktop
cp document.md ~/Desktop/YYYYMMDD-document.md
```

**Problems**:

- Desktop becomes cluttered
- Hard to find documents later
- No organization or categorization
- Not version controlled
- User is "drowning in Desktop files"

### ✅ DO

```bash
# Create in proper docs/ location
cp document.md ~/devvyn-meta-project/docs/category/document.md

# Commit to git (version control = posterity)
cd ~/devvyn-meta-project
git add docs/category/document.md
git commit -m "docs: add document for category"

# Display in browser if needed
~/devvyn-meta-project/scripts/markdown-to-browser.sh \
    ~/devvyn-meta-project/docs/category/document.md
```

---

## Desktop Triage Workflow

### For Existing Desktop Clutter

```bash
# Interactive triage (recommended)
~/devvyn-meta-project/scripts/desktop-to-kb.sh --interactive

# Auto-categorize based on filename patterns
~/devvyn-meta-project/scripts/desktop-to-kb.sh --auto

# Dry run (see what would happen)
~/devvyn-meta-project/scripts/desktop-to-kb.sh --dry-run
```

### Categorization Patterns

- `*phase*|*completion*|*summary*` → `project-management/`
- `*pattern*|*architecture*|*design*` → `architecture/`
- `*guide*|*howto*|*tutorial*` → `guides/`
- `*config*|*setup*|*install*` → `configuration/`
- `*platform*|*dependency*|*porting*` → `platform/`
- `*session*|*daily*|*check-in*` → `sessions/`

---

## Knowledge Base as Master Record

### Philosophy

**The knowledge base is the single source of truth.**

- `docs/` = Procedural knowledge (how the system works)
- `knowledge-base/` = Curated, indexed, cross-referenced
- `status/` = Current state, living documents
- Git = Version control, change history
- Bridge archive = Immutable event log

**Desktop is a temporary workspace, not storage.**

### Finding Information Later

```bash
# Search knowledge base
rg "search term" ~/devvyn-meta-project/docs/
rg "search term" ~/devvyn-meta-project/knowledge-base/

# Find by type
fd . ~/devvyn-meta-project/docs/ --type f --extension md

# List all patterns
ls ~/devvyn-meta-project/docs/abstractions/

# View KB index
cat ~/devvyn-meta-project/knowledge-base/coordination-system/KB-INDEX.md
```

### Future: DuckDB Query Overlay

```sql
-- Vision: Query knowledge base with SQL
SELECT title, category, word_count, last_updated
FROM documents
WHERE category = 'patterns'
  AND word_count > 5000
ORDER BY last_updated DESC;

-- Find related documents
SELECT d1.title, d2.title, similarity_score
FROM documents d1
JOIN document_links dl ON d1.id = dl.from_id
JOIN documents d2 ON dl.to_id = d2.id
WHERE d1.title LIKE '%coordination%';
```

**Near-future research**: DuckDB as overlay for agent queries over knowledge base

---

## Examples of Correct Routing

### Example 1: Creating a new pattern document

```bash
# ✅ CORRECT
cat > ~/devvyn-meta-project/docs/patterns/new-pattern.md << EOF
# New Pattern

...
EOF

git add docs/patterns/new-pattern.md
git commit -m "docs: add new-pattern documentation"

# Display in browser if long
~/devvyn-meta-project/scripts/markdown-to-browser.sh \
    ~/devvyn-meta-project/docs/patterns/new-pattern.md

# ❌ INCORRECT (creates Desktop clutter)
cat > ~/Desktop/20251030-new-pattern.md
```

### Example 2: Session completion summary

```bash
# ✅ CORRECT
cat > ~/devvyn-meta-project/status/session-reports/$(date +%Y%m%d)-summary.md << EOF
# Session Summary

...
EOF

git add status/session-reports/
git commit -m "status: add session summary"

# ❌ INCORRECT
cat > ~/Desktop/20251030-completion-summary.md
```

### Example 3: Experimental prototype

```bash
# ✅ CORRECT (temporary)
cat > /tmp/prototype.py << EOF
# Quick experiment
...
EOF

# ✅ CORRECT (might be valuable)
mkdir -p ~/devvyn-meta-project/kitchen/active-experiments/duckdb-overlay
cat > ~/devvyn-meta-project/kitchen/active-experiments/duckdb-overlay/prototype.py << EOF
# DuckDB query overlay experiment
...
EOF
```

---

## Policy Enforcement

### Agent Behavior (CODE agent)

**MUST**:

- Create procedural knowledge in `docs/`
- Create session artifacts in `status/`
- Commit important documents to git
- Route long documents to browser for display
- **NEVER** create "posterity" copies on Desktop

**MAY**:

- Create temporary files in `/tmp/`
- Create experiments in `kitchen/`
- Display documents in browser (ephemeral `/tmp/` copy OK)

### Human Workflow (Devvyn)

**Inbox**: `~/inbox/` for items requiring human review
**Desktop**: Temporary workspace only, triage regularly
**Archive**: `~/Archive/` for rarely-accessed historical documents

---

## Summary

| Type | Master Location | Display | Git | Desktop? |
|------|----------------|---------|-----|----------|
| Procedural knowledge | `docs/` | Browser | ✅ | ❌ |
| Session artifacts | `status/` or `knowledge-base/sessions/` | Browser | ✅ | ❌ |
| Temporary files | `/tmp/` | Terminal | ❌ | ❌ |
| Experiments | `kitchen/` | Terminal/Browser | ⚠️ | ❌ |
| Human review | `~/inbox/` | Desktop (briefly) | ❌ | ⚠️ Triage |
| Data/artifacts | `artifacts/` or project | N/A | ⚠️ | ❌ |

**Golden Rule**: If you'll need it later, it goes in `docs/` or `knowledge-base/`. **Never Desktop.**

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Maintained By**: CODE agent
**Policy Status**: ACTIVE - All outputs must follow these rules
