# Decision Patterns for HOPPER Agent

Automated decision-making based on documented user preferences

**Version**: 1.0
**Last Updated**: 2025-10-01
**Purpose**: Enable HOPPER agent to handle routine decisions without escalation

## Output File Placement

### Pattern: Long Text Output

**Condition**: Output > 24 lines
**Action**: Save to Desktop with ISO datetime naming
**Format**: `~/Desktop/YYYYMMDDHHMMSS-TIMEZONE-description.md`
**Confidence**: HIGH (95%)
**Source**: User global preferences in `~/.claude/CLAUDE.md`

### Pattern: JSON/Structured Data for Visualization

**Condition**: JSON data intended for visual tools
**Action**: Save to Desktop, no auto-cleanup
**Confidence**: HIGH (90%)

### Pattern: Work Logs (AAFC Context)

**Condition**: Work session documentation
**Action**: Append to `.kb-context/work-sessions.log`
**Confidence**: HIGH (95%)

### Pattern: Never Create Unsolicited Documentation

**Condition**: Agent asks "should I create README/docs?"
**Action**: NO - only create when explicitly requested
**Confidence**: HIGH (98%)

## AAFC Work Patterns

### Pattern: Commit Messages

- Feature: 🔬 emoji + brief description + Co-Authored-By
- Organization: 📁 emoji + structured explanation
- Bug fix: 🐛 emoji + description
**Confidence**: HIGH (95%)

### Pattern: Time Tracking

**Action**: Update `.kb-context/work-sessions.log` with session data
**Required**: session_start, tasks, artifacts_produced, duration
**Confidence**: HIGH (95%)

### Pattern: Specimen Processing

**Action**: Save to `full_dataset_processing/run_YYYYMMDD_HHMMSS/`
**Include**: provenance.json with agent+session IDs
**Confidence**: HIGH (90%)

## Security Patterns (from .security-manifest.yaml)

- **SECRET** (.env, credentials): ESCALATE to human (100% confidence)
- **PRIVATE** (meta-project, infrastructure): ALLOW with logging (100% confidence)
- **PUBLISHED** (GitHub repos): ALLOW fully (100% confidence)

## Message Routing

- Technical implementation → Code agent (95%)
- Strategic/framework → Chat agent (95%)
- Novel decisions → Human (98%)
- Content generation → GPT agent (70%)

## Confidence Levels

- **HIGH (>85%)**: Direct user statement or consistent behavior
- **MEDIUM (65-85%)**: Inferred from related patterns
- **LOW (<65%)**: Uncertain or novel - escalate

**Target Metrics**: Match rate >80%, Override rate <10%

---
**Status**: Bootstrap v1.0 - Will evolve as HOPPER learns preferences
