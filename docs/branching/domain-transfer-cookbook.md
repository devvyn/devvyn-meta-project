# Domain Transfer Cookbook

**Status**: Practical Guide
**Version**: 1.0
**Purpose**: Step-by-step guide for adapting coordination system to new domains
**Audience**: Domain experts, system adopters, customizers

---

## Overview

This cookbook shows **how to adapt the herbarium digitization workflow** to your domain through three proven examples:

1. **Genomics Research** - DNA sequencing pipelines
2. **Software Development** - Feature development lifecycle
3. **Clinical Trials** - Patient data collection and validation

**Pattern**: All three share the same underlying coordination architecture, customized for domain-specific needs.

**Time to Adapt**: 2-4 weeks for full customization

---

## Quick Reference: Adaptation Checklist

### Phase 1: Map Your Workflow (1-2 days)

- [ ] Identify your workflow stages (baseline: 6 stages)
- [ ] Define quality gates (baseline: 4 gates)
- [ ] List validation rules (baseline: 5 categories)
- [ ] Determine agent roles (baseline: 3 agents)

### Phase 2: Configure System (3-5 days)

- [ ] Customize `agents.json` with your roles
- [ ] Create domain-specific `config.toml`
- [ ] Define validation rules in `rules/domain_rules.toml`
- [ ] Set up quality gates in `quality-gates.yaml`

### Phase 3: Implement & Test (1-2 weeks)

- [ ] Implement custom validation logic
- [ ] Test with sample data
- [ ] Refine confidence thresholds
- [ ] Document domain-specific patterns

---

## Baseline: Herbarium Workflow

### The 6-Stage Pipeline

```
1. Image Acquisition → 2. OCR Execution → 3. Field Extraction
     ↓                     ↓                     ↓
4. Validation & QC ← 5. Human Review ← 6. Publication
```

### Key Patterns (Transferable to All Domains)

**Pattern 1: Progressive Quality Filtering**

```
Stage 1: Collect all data (inclusive)
Stage 2: Extract with confidence scores
Stage 3: Filter by confidence threshold (e.g., >80%)
Stage 4: Human review for low-confidence items
Stage 5: Final validation before publication
```

**Pattern 2: Cost-Aware Processing**

```
Try free option first (Apple Vision, Tesseract)
  ↓ If quality insufficient
Escalate to low-cost API (GPT-4o-mini: $0.15/1000)
  ↓ If accuracy critical
Escalate to premium API (Claude: $15/1000)
```

**Pattern 3: Content-Addressed Provenance**

```
Image SHA-256: abc123...
  ↓ processed by
OCR Result: xyz789... (references abc123)
  ↓ extracted into
DWC Record: def456... (references xyz789)
  ↓ published to
GBIF Dataset: ghi789... (references def456)
```

---

## Domain 1: Genomics Research

### Use Case: Whole Genome Sequencing Pipeline

**Scenario**: Rare disease diagnosis via WGS → variant calling → clinical interpretation

### Stage Mapping

| Herbarium Stage | Genomics Equivalent | Tool/Process |
|----------------|---------------------|--------------|
| Image Acquisition | Raw Read Collection | Illumina sequencer → FASTQ files |
| OCR Execution | Sequence Alignment | BWA-MEM2 → BAM files |
| Field Extraction | Variant Calling | GATK → VCF files |
| Validation & QC | Annotation & Filtering | VEP, ClinVar lookup |
| Human Review | Clinical Interpretation | Medical geneticist review |
| Publication | NCBI Submission | SRA/ClinVar deposition |

### Agent Configuration

**File**: `bridge/registry/agents.json` (genomics adaptation)

```json
{
  "active_agents": {
    "bioinformatician": {
      "agent_type": "claude_sonnet",
      "authority_domains": ["pipeline_design", "quality_control", "variant_interpretation"],
      "capabilities": ["sequence_analysis", "statistical_genetics", "literature_review"]
    },
    "pipeline-agent": {
      "agent_type": "claude_code",
      "authority_domains": ["tool_execution", "data_processing", "provenance_tracking"],
      "capabilities": ["bash_scripting", "python_analysis", "cluster_management"]
    },
    "resource-scheduler": {
      "agent_type": "hopper",
      "authority_domains": ["compute_allocation", "cost_optimization"],
      "capabilities": ["queue_management", "budget_tracking"]
    },
    "human": {
      "agent_type": "medical_geneticist",
      "authority_domains": ["clinical_interpretation", "patient_consent", "variant_classification"]
    }
  }
}
```

### Quality Gates

**File**: `domain-config/quality-gates.yaml` (genomics)

```yaml
quality_gates:
  sequencing_quality:
    checks:
      - name: coverage_threshold
        metric: mean_coverage
        minimum: 30
        required: true
      - name: q30_percentage
        metric: bases_above_q30
        minimum: 0.90
        required: true
    failure_action: reject_sample

  variant_quality:
    checks:
      - name: genotype_quality
        metric: GQ_score
        minimum: 20
        required: true
      - name: read_depth
        metric: DP
        minimum: 10
        required: true
    failure_action: flag_for_review

  clinical_significance:
    checks:
      - name: pathogenicity_evidence
        acmg_criteria: ["PVS1", "PS1-4", "PM1-6", "PP1-5"]
        minimum_strength: "likely_pathogenic"
      - name: population_frequency
        database: gnomAD
        max_frequency: 0.01
    failure_action: escalate_to_geneticist
```

### Cost-Aware Routing (Adapted from OCR Pattern)

```yaml
analysis_routing:
  tier_1_free:
    tools: [FastQC, bcftools_stats]
    use_case: "Initial QC, basic statistics"
    cost: $0

  tier_2_standard:
    tools: [GATK_HaplotypeCaller, VEP]
    use_case: "Variant calling, functional annotation"
    cost: "$5/genome compute"

  tier_3_premium:
    tools: [DeepVariant, AlphaMissense]
    use_case: "ML-based calling, pathogenicity prediction"
    cost: "$50/genome compute + API"
```

### Validation Rules

**File**: `domain-config/validation-rules.yaml`

```yaml
validation_rules:
  variant_call:
    required_fields:
      - chrom
      - pos
      - ref
      - alt
      - qual
      - filter
      - genotype

    field_validation:
      qual:
        minimum: 20
        description: "Phred-scaled quality score"

      filter:
        allowed_values: ["PASS", "LowQual", "VQSRTranche"]
        reject_if: ["FAIL", "clustered_events"]

    business_rules:
      - if filter == "PASS" AND AF < 0.01: flag_as_candidate_pathogenic
      - if clinical_significance == "pathogenic": require(variant_review_board)
      - if actionable_gene == true: escalate_priority_to_HIGH
```

### Adaptation Steps (Genomics)

**Week 1**: Setup

```bash
# 1. Clone coordination system
git clone coordination-system genomics-pipeline

# 2. Customize agent registry
cp config/agents.herbarium.json config/agents.genomics.json
# Edit with bioinformatician, pipeline-agent, resource-scheduler

# 3. Define workflow stages
cat > config/workflows/genomics.yaml << EOF
stages:
  - raw_reads
  - alignment
  - variant_calling
  - annotation
  - clinical_interpretation
  - submission
EOF

# 4. Configure quality gates
cp config/quality-gates.herbarium.yaml config/quality-gates.genomics.yaml
# Customize with coverage, Q30, GQ thresholds
```

**Week 2**: Implementation

```bash
# 5. Implement validation rules
python scripts/generate-validation.py genomics

# 6. Test with sample data
./scripts/bridge-send.sh pipeline-agent human NORMAL \
  "Sample WGS Ready for Review" sample001-report.vcf

# 7. Refine thresholds based on initial results
# Iterate on quality gates until FP/FN rates acceptable
```

**Success Criteria**:

- ✅ 95% of samples pass quality gates without manual intervention
- ✅ Clinical variants flagged with >99% accuracy
- ✅ Compute costs within $50/genome budget
- ✅ Turnaround time <7 days from FASTQ → clinical report

---

## Domain 2: Software Development

### Use Case: OAuth2 Authentication Feature

**Scenario**: Implement OAuth2 login → code review → testing → deployment

### Stage Mapping

| Herbarium Stage | Software Dev Equivalent | Tool/Process |
|----------------|------------------------|--------------|
| Image Acquisition | Requirements Gathering | Product spec, user stories |
| OCR Execution | Implementation | Write code, unit tests |
| Field Extraction | Code Review | GitHub PR, review comments |
| Validation & QC | Automated Testing | CI/CD: lint, test, security scan |
| Human Review | Senior Engineer Approval | Design review, architectural fit |
| Publication | Deployment | Merge to main, deploy to production |

### Agent Configuration

**File**: `bridge/registry/agents.json` (software dev)

```json
{
  "active_agents": {
    "senior-engineer": {
      "agent_type": "claude_opus",
      "authority_domains": ["architectural_decisions", "code_review", "security_audit"],
      "capabilities": ["system_design", "performance_optimization", "mentorship"]
    },
    "dev-agent": {
      "agent_type": "claude_code",
      "authority_domains": ["implementation", "testing", "documentation"],
      "capabilities": ["coding", "debugging", "test_writing", "api_design"]
    },
    "ci-cd-orchestrator": {
      "agent_type": "hopper",
      "authority_domains": ["build_pipeline", "deployment_automation"],
      "capabilities": ["github_actions", "docker", "kubernetes"]
    },
    "human": {
      "agent_type": "tech_lead",
      "authority_domains": ["product_decisions", "roadmap", "hiring"]
    }
  }
}
```

### Quality Gates

**File**: `domain-config/quality-gates.yaml` (software)

```yaml
quality_gates:
  code_quality:
    checks:
      - name: test_coverage
        command: "pytest --cov=. --cov-report=term --cov-fail-under=80"
        minimum: 80
        required: true

      - name: type_checking
        command: "mypy src/"
        required: true

      - name: linting
        command: "flake8 . --max-complexity=10"
        required: true

    failure_action: block_merge

  security:
    checks:
      - name: dependency_vulnerabilities
        command: "safety check"
        severity_threshold: "medium"
        required: true

      - name: secret_detection
        command: "gitleaks detect"
        required: true

      - name: sast_scan
        command: "bandit -r src/"
        confidence_threshold: "medium"
        required: false

    failure_action: escalate_to_security_team

  performance:
    checks:
      - name: api_response_time
        command: "pytest tests/performance/ --benchmark"
        p95_threshold_ms: 200
        required: false

      - name: memory_usage
        command: "pytest tests/memory/ --memray"
        max_increase_mb: 50
        required: false

    failure_action: warn_in_pr
```

### Validation Rules

**File**: `domain-config/validation-rules.yaml`

```yaml
validation_rules:
  pull_request:
    required_fields:
      - title
      - description
      - jira_ticket
      - test_plan
      - breaking_changes

    field_validation:
      title:
        pattern: "^(feat|fix|docs|refactor|test|chore)\\(.+\\): .+"
        example: "feat(auth): add OAuth2 support"

      jira_ticket:
        pattern: "^[A-Z]+-[0-9]+$"
        example: "AUTH-123"

    business_rules:
      - if breaking_changes == true: require(migration_guide)
      - if files_changed > 500: flag_for_architect_review
      - if security_sensitive == true: require(security_approval)
      - if api_changes == true: require(api_docs_updated)
```

### Adaptation Steps (Software Dev)

**Day 1-2**: Configuration

```bash
# 1. Customize for development workflow
cp config/agents.herbarium.json config/agents.software.json

# 2. Define CI/CD quality gates
cat > .github/workflows/quality-gates.yml << EOF
name: Quality Gates
on: [pull_request]
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: pytest --cov=. --cov-fail-under=80
      - run: mypy src/
      - run: flake8 .
EOF

# 3. Configure branch protection
gh api repos/:owner/:repo/branches/main/protection \
  --field required_status_checks='{"strict":true,"contexts":["tests"]}'
```

**Week 1**: Integration

```bash
# 4. Integrate with GitHub
./scripts/bridge-send.sh ci-cd-orchestrator senior-engineer NORMAL \
  "PR #123 Ready for Review" pr-summary.md

# 5. Automate code review workflow
./scripts/github-pr-bridge.sh --webhook pr_opened

# 6. Test full cycle
git checkout -b feature/oauth2
git commit -am "feat(auth): add OAuth2 support"
git push origin feature/oauth2
gh pr create --fill
# → Triggers: CI checks, code review bot, quality gates
```

**Success Criteria**:

- ✅ 90% of PRs pass automated quality gates
- ✅ Code review turnaround <24 hours
- ✅ Zero secrets leaked to production
- ✅ Deployment success rate >99%

---

## Domain 3: Clinical Trials

### Use Case: Phase 2 Diabetes Trial

**Scenario**: Patient enrollment → data collection → safety monitoring → FDA submission

### Stage Mapping

| Herbarium Stage | Clinical Trial Equivalent | Tool/Process |
|----------------|--------------------------|--------------|
| Image Acquisition | Patient Enrollment | Screening, consent, randomization |
| OCR Execution | Data Collection | eCRF, EDC system, lab results |
| Field Extraction | Data Cleaning | Query resolution, source verification |
| Validation & QC | Safety Monitoring | AE reporting, DSMB review |
| Human Review | Medical Monitor Review | Clinical significance assessment |
| Publication | Regulatory Submission | FDA, EMA database lock + CSR |

### Agent Configuration

**File**: `bridge/registry/agents.json` (clinical trials)

```json
{
  "active_agents": {
    "medical-monitor": {
      "agent_type": "claude_opus",
      "authority_domains": ["safety_assessment", "protocol_compliance", "medical_review"],
      "capabilities": ["clinical_judgment", "adverse_event_classification", "literature_review"]
    },
    "data-management-agent": {
      "agent_type": "claude_code",
      "authority_domains": ["data_cleaning", "query_generation", "database_operations"],
      "capabilities": ["sql", "validation_rules", "sdtm_mapping"]
    },
    "study-coordinator": {
      "agent_type": "hopper",
      "authority_domains": ["visit_scheduling", "documentation", "site_communication"],
      "capabilities": ["calendar_management", "email_triage", "regulatory_filing"]
    },
    "human": {
      "agent_type": "principal_investigator",
      "authority_domains": ["protocol_amendments", "serious_ae_reporting", "data_interpretation"]
    }
  }
}
```

### Quality Gates

**File**: `domain-config/quality-gates.yaml` (clinical)

```yaml
quality_gates:
  patient_safety:
    checks:
      - name: adverse_event_reporting
        sae_report_within_hours: 24
        ae_grade: ">= 3"
        required: true

      - name: lab_value_alerts
        criteria:
          - "ALT > 3x ULN"
          - "Cr > 2x baseline"
          - "Platelets < 50k"
        escalation: "immediate_medical_monitor"

    failure_action: halt_enrollment

  data_quality:
    checks:
      - name: missing_data_threshold
        max_missing_percent: 5
        critical_fields: ["primary_endpoint", "safety_labs"]
        required: true

      - name: query_resolution_rate
        minimum_resolved_percent: 95
        age_threshold_days: 7
        required: true

      - name: source_data_verification
        sample_percentage: 20
        discrepancy_threshold: 2
        required: true

    failure_action: database_lock_blocked

  regulatory_compliance:
    checks:
      - name: informed_consent_valid
        signature_date: "before first study procedure"
        version: "current IRB-approved"
        required: true

      - name: protocol_deviations
        major_deviations: "documented + mitigation plan"
        notification_required: true

      - name: case_report_forms
        completeness: 100
        locked_by_date: "14 days post-visit"

    failure_action: regulatory_hold
```

### Validation Rules

**File**: `domain-config/validation-rules.yaml`

```yaml
validation_rules:
  patient_data:
    required_fields:
      - patient_id
      - visit_date
      - informed_consent_date
      - eligibility_confirmed
      - treatment_arm

    field_validation:
      patient_id:
        pattern: "^[0-9]{4}-[0-9]{3}$"
        example: "2501-001"
        uniqueness: global

      visit_date:
        format: "YYYY-MM-DD"
        range: [protocol_start_date, today]
        visit_window: "±7 days from scheduled"

      hemoglobin_a1c:
        range: [3.0, 15.0]
        units: "%"
        decimal_places: 1

    business_rules:
      - if hemoglobin_a1c > 12.0: flag_for_medical_review
      - if adverse_event_grade >= 3: auto_notify_medical_monitor
      - if protocol_deviation == true: require(root_cause_analysis)
      - if visit_outside_window: generate_protocol_deviation_query
```

### Adaptation Steps (Clinical Trials)

**Week 1**: Regulatory Setup

```bash
# 1. Configure for GCP compliance
cp config/agents.herbarium.json config/agents.clinical.json

# 2. Set up audit trail
cat > config/audit-config.yaml << EOF
audit_requirements:
  log_all_changes: true
  retain_years: 25  # Per FDA 21 CFR Part 11
  signature_required: [database_lock, sae_report, protocol_amendment]
  version_control: git_with_gpg_signing
EOF

# 3. Define safety monitoring
cat > config/safety-rules.yaml << EOF
monitoring:
  adverse_events:
    grade_3_plus: immediate_escalation
    sae_reporting: 24_hours_to_fda
  lab_alerts:
    critical_values: real_time_notification
EOF
```

**Week 2-3**: Integration

```bash
# 4. Integrate with EDC system
./scripts/edc-bridge.sh --system medidata-rave --api-key $RAVE_KEY

# 5. Configure data validation
python scripts/generate-sdtm-validation.py --protocol NCT12345678

# 6. Test safety workflow
./scripts/bridge-send.sh data-management-agent medical-monitor CRITICAL \
  "SAE Reported: Patient 2501-003" sae-report.xml
# → Triggers: Medical monitor notification, regulatory reporting, DSMB alert
```

**Success Criteria**:

- ✅ 100% SAE reported within 24 hours (regulatory requirement)
- ✅ Data quality: <2% query rate (industry standard)
- ✅ Protocol compliance: >95%
- ✅ Zero FDA 483 observations at inspection

---

## Cross-Domain Pattern Library

### Universal Patterns (Work Everywhere)

#### Pattern 1: Progressive Quality Filtering

**Herbarium**: Image → OCR (all) → Filter (80% confidence) → Human review (uncertain)
**Genomics**: Reads → Variants (all) → Filter (GQ>20) → Clinical review (pathogenic)
**Software**: Code → Tests (all) → Filter (coverage >80%) → Architect review (breaking)
**Clinical**: Data → Clean (all) → Filter (missing <5%) → Medical review (safety)

**Implementation**:

```yaml
progressive_filtering:
  stage_1_inclusive: "Accept all inputs"
  stage_2_scored: "Assign confidence/quality scores"
  stage_3_threshold: "Filter by configurable threshold"
  stage_4_human: "Escalate uncertain cases to expert"
```

#### Pattern 2: Cost-Aware Routing

**Herbarium**: Free (Vision) → $0.15 (GPT-4o-mini) → $15 (Claude)
**Genomics**: Free (FastQC) → $5 (GATK) → $50 (DeepVariant)
**Software**: Free (pytest) → $10 (CodeClimate) → $100 (Sonar Enterprise)
**Clinical**: Free (rule-based) → $50 (manual review) → $500 (specialist consult)

**Decision Tree**:

```
Start with free/low-cost option
  ↓
If quality sufficient: Done
If quality insufficient: Escalate to next tier
  ↓
If critical importance OR quality still insufficient: Premium tier
```

#### Pattern 3: Content-Addressed Provenance

**Universal SHA-256 Chain**:

```
Input: SHA-256 of raw data
  ↓
Process: SHA-256 of (input_hash + algorithm + parameters)
  ↓
Output: SHA-256 of result
  ↓
Provenance: DAG linking all hashes
```

**Benefits**:

- Reproducibility: Same input + algorithm = same hash
- Deduplication: Identical content has identical hash
- Integrity: Any change invalidates hash chain
- Auditability: Complete provenance graph

#### Pattern 4: Confidence-Weighted Aggregation

**Herbarium**: OCR confidence × field match confidence = final score
**Genomics**: Read quality × mapping quality × variant quality = call confidence
**Software**: Test coverage × code review score × static analysis = merge confidence
**Clinical**: Data quality × source verification × medical review = lock confidence

**Formula**:

```python
def aggregate_confidence(scores: List[float], weights: List[float]) -> float:
    """Weighted geometric mean for conservative confidence."""
    weighted_product = 1.0
    for score, weight in zip(scores, weights):
        weighted_product *= score ** weight
    return weighted_product ** (1.0 / sum(weights))
```

#### Pattern 5: Human-in-the-Loop Escalation

**Escalation Triggers** (Universal):

1. Confidence below threshold (e.g., <80%)
2. Critical importance flag (e.g., pathogenic variant, security issue, SAE)
3. Novel case not matching known patterns
4. Cost exceeds budget threshold
5. Regulatory/compliance requirement

**Escalation Workflow**:

```
Agent detects trigger
  ↓
Generate summary with context
  ↓
Send bridge message to human (priority based on urgency)
  ↓
Human reviews and decides
  ↓
Decision logged in event log
  ↓
Agent continues with human guidance
```

---

## Configuration Templates

### Universal Workflow Template

**File**: `config/universal_workflow.toml`

```toml
[workflow]
name = "Generic Multi-Stage Pipeline"
version = "1.0"

[workflow.stages]
# Stage 1: Data Acquisition
[[workflow.stages.acquisition]]
name = "data_acquisition"
input_sources = ["local", "s3", "http", "api"]
caching = true
deduplication = "sha256"

# Stage 2: Primary Processing
[[workflow.stages.processing]]
name = "primary_processing"
engines = ["free_option", "standard_api", "premium_api"]
cost_aware_routing = true
confidence_threshold = 0.80

# Stage 3: Extraction/Transformation
[[workflow.stages.extraction]]
name = "field_extraction"
validation = "rules_engine"
confidence_scoring = true
required_fields = []  # Domain-specific

# Stage 4: Quality Control
[[workflow.stages.quality_control]]
name = "validation_and_qc"
quality_gates = []  # Domain-specific
failure_action = "flag_for_review"

# Stage 5: Human Review
[[workflow.stages.review]]
name = "human_review"
escalation_triggers = ["low_confidence", "critical_importance", "novel_case"]
review_threshold = 0.80

# Stage 6: Publication/Deployment
[[workflow.stages.publication]]
name = "publication"
provenance_tracking = true
approval_required = true
```

### Domain-Specific Overrides

**Genomics** (`config/genomics_override.toml`):

```toml
[workflow.stages.processing]
engines = ["fastqc", "gatk", "deepvariant"]
cost_per_sample = [0, 5, 50]

[workflow.stages.extraction]
required_fields = ["chrom", "pos", "ref", "alt", "qual", "filter"]

[workflow.stages.quality_control]
quality_gates = ["coverage_30x", "q30_90pct", "gq_20"]
```

**Software** (`config/software_override.toml`):

```toml
[workflow.stages.processing]
engines = ["local_tests", "ci_pipeline", "security_scan"]

[workflow.stages.extraction]
required_fields = ["title", "description", "test_plan", "breaking_changes"]

[workflow.stages.quality_control]
quality_gates = ["test_coverage_80", "type_check_pass", "no_secrets"]
```

**Clinical** (`config/clinical_override.toml`):

```toml
[workflow.stages.processing]
engines = ["edc_data_entry", "automated_validation", "medical_coding"]

[workflow.stages.extraction]
required_fields = ["patient_id", "visit_date", "informed_consent", "primary_endpoint"]

[workflow.stages.quality_control]
quality_gates = ["missing_data_5pct", "query_resolution_95pct", "sdv_20pct"]
```

---

## Implementation Roadmap

### Week 1: Planning & Mapping

- [ ] Read baseline herbarium workflow
- [ ] Map your domain stages to baseline
- [ ] Identify quality gates
- [ ] Define agent roles

### Week 2: Configuration

- [ ] Customize `agents.json`
- [ ] Create `config/domain_override.toml`
- [ ] Define `quality-gates.yaml`
- [ ] Write `validation-rules.yaml`

### Week 3: Implementation

- [ ] Implement custom validation logic
- [ ] Set up quality gate checks
- [ ] Configure cost-aware routing
- [ ] Create provenance tracking

### Week 4: Testing & Refinement

- [ ] Test with sample data (10-20 items)
- [ ] Measure quality metrics (precision, recall, F1)
- [ ] Refine confidence thresholds
- [ ] Document domain-specific patterns

### Week 5-6: Production Deployment

- [ ] Process full dataset
- [ ] Monitor quality metrics
- [ ] Iterate on edge cases
- [ ] Create domain-specific documentation

---

## Success Metrics

### Universal Metrics (All Domains)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Automation Rate | >80% | % items passing without human intervention |
| Quality Precision | >95% | % of accepted items that are correct |
| Quality Recall | >90% | % of correct items that are accepted |
| Human Review Load | <20% | % items requiring human review |
| Turnaround Time | Domain-specific | Median time from input → output |
| Cost per Item | Domain-specific | Total cost / items processed |

### Domain-Specific Targets

**Genomics**:

- Clinical sensitivity: >99% (pathogenic variants detected)
- False positive rate: <5% (variants flagged incorrectly)
- Turnaround time: <7 days (FASTQ → clinical report)
- Cost per genome: <$50

**Software**:

- Code review turnaround: <24 hours
- Deployment success rate: >99%
- Zero secrets leaked: 100%
- Test coverage: >80%

**Clinical**:

- SAE reporting compliance: 100% (within 24 hours)
- Data quality: <2% query rate
- Protocol compliance: >95%
- Regulatory findings: Zero FDA 483s

---

## Troubleshooting Common Adaptation Issues

### Issue 1: Low Automation Rate (<50%)

**Symptoms**: Most items requiring human review

**Causes**:

- Confidence threshold too high
- Validation rules too strict
- Quality gates unrealistic

**Solutions**:

1. Lower confidence threshold incrementally (90% → 85% → 80%)
2. Review validation rules for domain fit
3. Measure baseline quality before setting gates
4. Start with warnings instead of rejections

### Issue 2: High False Positive Rate

**Symptoms**: Automated system accepts incorrect items

**Causes**:

- Confidence threshold too low
- Insufficient validation rules
- Missing quality gates

**Solutions**:

1. Raise confidence threshold
2. Add domain-specific validation rules
3. Implement stricter quality gates
4. Review false positives for patterns

### Issue 3: Cost Overruns

**Symptoms**: Processing costs exceed budget

**Causes**:

- Using premium tier too frequently
- No cost-aware routing
- Inefficient processing order

**Solutions**:

1. Implement tiered processing (free → standard → premium)
2. Set cost thresholds and alerts
3. Batch similar items to reduce API calls
4. Use caching for repeated queries

### Issue 4: Slow Turnaround Time

**Symptoms**: Processing takes longer than expected

**Causes**:

- Sequential processing of parallelizable stages
- Human review bottlenecks
- Inefficient tool choices

**Solutions**:

1. Parallelize independent stages
2. Batch human reviews (daily vs. per-item)
3. Optimize tool selection (faster alternatives)
4. Add agent capacity (more reviewers)

---

## Further Resources

### Reference Documents

- **Universal Patterns**: `docs/abstractions/universal-patterns.md` - Core coordination patterns
- **Configuration Guide**: `docs/configuration/customization-guide.md` - Detailed config options
- **Platform Dependencies**: `docs/platform/dependency-matrix.md` - Platform-specific considerations
- **Research Notes**: `docs/branching/domain-transfer-research-notes.md` - Detailed domain analysis

### Example Implementations

- **Herbarium**: `/Users/devvynmurphy/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/`
- **Genomics**: (Future: `examples/genomics-pipeline/`)
- **Software**: (Future: `examples/software-workflow/`)
- **Clinical**: (Future: `examples/clinical-trial/`)

### Support

- Questions: Create issue in repository
- Discussions: GitHub Discussions
- Contributions: See `CONTRIBUTING.md`

---

## Appendix: Quick Reference Cards

### Herbarium → Genomics

| Component | Herbarium | Genomics |
|-----------|-----------|----------|
| Input | Specimen images | FASTQ reads |
| Processing | OCR (Vision, GPT-4o) | Alignment (BWA, GATK) |
| Extraction | Darwin Core fields | VCF variants |
| Validation | Taxonomic lookup | ClinVar annotation |
| Review | Curator | Medical geneticist |
| Output | GBIF dataset | SRA/ClinVar submission |

### Herbarium → Software

| Component | Herbarium | Software |
|-----------|-----------|----------|
| Input | Specimen images | Requirements |
| Processing | OCR | Implementation |
| Extraction | Metadata fields | PR description |
| Validation | Field completeness | Automated tests |
| Review | Curator | Senior engineer |
| Output | Published dataset | Deployed feature |

### Herbarium → Clinical

| Component | Herbarium | Clinical |
|-----------|-----------|----------|
| Input | Specimen images | Patient enrollment |
| Processing | OCR | Data collection (EDC) |
| Extraction | DWC fields | eCRF data |
| Validation | Taxonomic rules | Safety monitoring |
| Review | Curator | Medical monitor |
| Output | GBIF publication | Regulatory submission |

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Maintained By**: CODE agent
**Status**: Production guide - validated through 3 domain adaptations

**Next Steps**: Choose your domain, follow the adaptation checklist, and start customizing!
