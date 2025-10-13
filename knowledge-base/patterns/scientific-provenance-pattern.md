# Scientific Provenance Pattern

**Status**: Production-proven (2,885 AAFC specimens)
**Category**: Reproducibility, Scientific Integrity
**Philosophy**: Extract git wisdom (versioning), leave baggage (workflow coupling)

## Pattern

Use git as **read-only metadata provider** to make scientific outputs cryptographically traceable to exact code versions.

## Core Implementation

```python
# Capture at processing start
git_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
git_dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], text=True).strip())

# Embed in export manifest
manifest = {
    "version": "1.0.0",
    "git_commit": git_commit,
    "git_commit_short": git_commit[:7],
    "git_dirty": git_dirty,
    "timestamp": datetime.now(timezone.utc).isoformat()
}
```

## Three Rules

1. **Capture git commit** at processing start (not export)
2. **Flag dirty state** to warn about uncommitted changes
3. **Fail gracefully** if git unavailable (try/except → "unknown")

## Evidence

**AAFC Herbarium Project**:
- ✅ 2,885 specimens with full provenance
- ✅ Every export traceable to exact code version
- ✅ Reproducibility workflow validated
- ✅ Zero infrastructure overhead

**Files**:
- `dwc/archive.py:90-118` - Production manifest generation
- `cli.py:519` - Processing-time capture
- `src/provenance.py` - Reusable utilities
- `docs/SCIENTIFIC_PROVENANCE_PATTERN.md` - Complete guide

## Key Characteristics

✅ **Read-only**: Never modifies git repository
✅ **Fail-safe**: Graceful degradation without git
✅ **Zero coupling**: No workflow management
✅ **Production-proven**: Real scientific data

## Evolution Path

**When git provenance isn't enough**:
- Metadata accumulates over decades
- Cross-repository workflows
- Fragment merging required

**Solution**: Migrate to Content DAG pattern (maintains git commit + adds content hashing)

## Adoption

**Recommended for**:
- Scientific data exports
- Production processing pipelines
- Government/institutional datasets
- Any workflow requiring reproducibility

**Copy utilities**:
```bash
cp ~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/src/provenance.py your_project/
```

## Related Patterns

- Content DAG (evolution for fragment accumulation)
- "Extract Wisdom, Leave Baggage" (design philosophy)
- Native App Integration (similar principle)

## References

- Full docs: `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/SCIENTIFIC_PROVENANCE_PATTERN.md`
- Examples: `~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/examples/provenance_example.py`
- Git usage analysis: `~/Desktop/*-git-usage-analysis.md`
