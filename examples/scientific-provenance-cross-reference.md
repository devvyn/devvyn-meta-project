# Scientific Provenance Pattern - Cross-Project Reference

**Git-based version tracking for reproducible scientific outputs**

## Overview

The **Scientific Provenance Pattern** uses git as a read-only metadata provider to make scientific data outputs cryptographically traceable to the exact code version that generated them.

## Production Implementation

**AAFC Herbarium Project** (`~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025`)

### Status
✅ **Production-tested**: 2,885 specimens exported with full provenance metadata

### Key Files

1. **Pattern Documentation**:
   - `docs/SCIENTIFIC_PROVENANCE_PATTERN.md` - Complete pattern guide

2. **Implementation**:
   - `src/provenance.py` - Reusable utilities for any scientific workflow
   - `dwc/archive.py:90-118` - Production manifest generation
   - `cli.py:519` - Processing-time provenance capture

3. **Examples**:
   - `examples/provenance_example.py` - Basic usage patterns
   - `examples/content_dag_herbarium.py` - Evolution to Content DAG

### Core Principles

```python
# At processing start
git_info = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()

# In export manifest
manifest = {
    "git_commit": git_info,
    "git_dirty": bool(uncommitted_changes),
    "timestamp": datetime.now(timezone.utc).isoformat()
}
```

**Result**: Every export cryptographically linked to code version.

## Pattern Benefits

### For AAFC Science
- ✅ **Reproducibility**: Re-run analysis with identical code
- ✅ **Forensic analysis**: Reconstruct environment for any export
- ✅ **Compliance**: Demonstrate methodological rigor
- ✅ **Trust**: Stakeholders can verify provenance

### Implementation Quality
- ✅ **Read-only**: Never modifies git repository
- ✅ **Fail-safe**: Graceful degradation if git unavailable
- ✅ **Standardized**: Common metadata schema across projects
- ✅ **Production-proven**: Real scientific data exports

## Usage in Other Projects

### Quick Start

```bash
# Copy provenance utilities
cp ~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/src/provenance.py your_project/

# Use in your code
from provenance import capture_git_provenance, create_manifest

git_info = capture_git_provenance()
manifest = create_manifest(
    version="1.0.0",
    git_info=git_info,
    custom_metadata={"data_count": 1000}
)
```

### When to Use

✅ **Recommended for**:
- Scientific data exports
- Production data processing
- Research workflows requiring reproducibility
- Government/institutional datasets

❌ **Not needed for**:
- Exploratory analysis
- Temporary scripts
- Interactive development

## Evolution: Content DAG

For workflows with **metadata accumulation over time**, consider Content DAG pattern.

### Git Provenance → Content DAG

**Git works for**:
- Single-pass processing
- Immutable exports
- Code version tracking

**Content DAG adds**:
- Fragment accumulation (decades of updates)
- Cross-repo provenance
- Duplicate detection
- No git dependency

**See**: `~/devvyn-meta-project/docs/CONTENT_DAG_PATTERN.md`

**Herbarium example**: `examples/content_dag_herbarium.py`

## Related Patterns

### Meta-Project Coordination
- **Bridge messages**: Use git provenance for message integrity
- **Agent sessions**: Capture commit hash in session handoffs
- **Story events**: Link events to code versions

### Content DAG Integration
- **Combine approaches**: Git commit + content hash (belt-and-suspenders)
- **Natural evolution**: Start with git, add DAG for fragments
- **AAFC use case**: Specimen metadata accumulated over 1987-2025

## References

- **Pattern Guide**: `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/SCIENTIFIC_PROVENANCE_PATTERN.md`
- **Utilities**: `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/src/provenance.py`
- **Examples**: `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/examples/`
- **Content DAG**: `~/devvyn-meta-project/docs/CONTENT_DAG_PATTERN.md`

---

**Status**: Production-proven pattern, ready for cross-project adoption

**Recommended for**: All AAFC science projects requiring reproducibility
