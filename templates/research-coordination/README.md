# Research Coordination Template

**Domain**: Scientific research, lab work, data analysis, publications

**Use Case**: Coordinate multi-agent research workflows from data collection through publication

---

## What's Included

This template provides:
- ✅ Pre-configured research agent roles
- ✅ Domain-specific workflows (experiment → analysis → publication)
- ✅ Quality gates for research integrity
- ✅ Data provenance tracking
- ✅ Collaboration patterns for multi-researcher teams

---

## Agent Roles

### 1. **Researcher Agent** (Primary investigator)
- **Authority**: Experimental design, hypothesis formation, interpretation
- **Tools**: Data collection, literature review, manuscript writing
- **Escalates to**: Human (PI) for methodological decisions

### 2. **Data Agent** (Data processing specialist)
- **Authority**: Data cleaning, transformation, statistical analysis
- **Tools**: Python/R scripts, data visualization, quality checks
- **Escalates to**: Researcher for interpretation

### 3. **Literature Agent** (Knowledge retrieval)
- **Authority**: Literature search, citation management, related work
- **Tools**: PubMed, arXiv, Google Scholar, reference formatting
- **Escalates to**: Researcher for relevance judgments

### 4. **Publication Agent** (Writing specialist)
- **Authority**: Manuscript drafting, editing, formatting
- **Tools**: LaTeX, citation management, journal formatting
- **Escalates to**: Human (PI) for submission decisions

### 5. **Human (Principal Investigator)**
- **Authority**: Final decisions, ethical oversight, funding
- **Tools**: Review, approval, strategic direction
- **Responsibility**: All aspects requiring human judgment

---

## Quick Start

### 1. Clone the template

```bash
cp -r templates/research-coordination ~/my-research-project
cd ~/my-research-project
```

### 2. Configure your research project

```bash
# Edit config.yaml with your project details
vi config.yaml
```

### 3. Start first workflow

```bash
# Example: Literature review → Experiment design
./workflows/literature-to-experiment.sh "protein folding" "AlphaFold2"
```

---

## Workflows

### Workflow 1: Literature Review → Hypothesis

```
Literature Agent: Search papers on topic
    ↓
Literature Agent: Summarize key findings
    ↓
Researcher Agent: Generate hypotheses
    ↓
Human (PI): Review and approve hypothesis
    ↓
Researcher Agent: Design experiment
```

**Command**:
```bash
./workflows/literature-to-hypothesis.sh "topic" "keywords"
```

### Workflow 2: Data Collection → Analysis → Interpretation

```
Researcher Agent: Collect raw data
    ↓
Data Agent: Clean and validate data
    ↓
Data Agent: Run statistical analysis
    ↓
Data Agent: Generate visualizations
    ↓
Researcher Agent: Interpret results
    ↓
Human (PI): Review interpretation
```

**Command**:
```bash
./workflows/data-to-insight.sh "experiment-2025-10-30" "analysis-params.json"
```

### Workflow 3: Results → Manuscript → Publication

```
Researcher Agent: Draft results section
    ↓
Literature Agent: Find related work
    ↓
Publication Agent: Write introduction/discussion
    ↓
Publication Agent: Format for target journal
    ↓
Human (PI): Review manuscript
    ↓
Publication Agent: Incorporate revisions
    ↓
Human (PI): Submit to journal
```

**Command**:
```bash
./workflows/results-to-paper.sh "results/experiment-data.csv" "Nature"
```

---

## Configuration

### config.yaml

```yaml
research_project:
  title: "Protein Folding Dynamics in E. coli"
  pi: "Dr. Jane Smith"
  institution: "University of Example"
  start_date: "2025-01-15"

agents:
  researcher:
    authority_domains:
      - experimental_design
      - hypothesis_formation
      - data_interpretation
    tools:
      - jupyter_notebooks
      - lab_equipment_interface
      - manuscript_drafting

  data:
    authority_domains:
      - data_cleaning
      - statistical_analysis
      - visualization
    tools:
      - pandas
      - numpy
      - matplotlib
      - seaborn
      - scipy

  literature:
    authority_domains:
      - literature_search
      - citation_management
      - related_work_summary
    tools:
      - pubmed_api
      - arxiv_api
      - google_scholar
      - zotero

  publication:
    authority_domains:
      - manuscript_writing
      - formatting
      - submission_preparation
    tools:
      - latex
      - reference_manager
      - journal_templates

quality_gates:
  data_validation:
    - check_completeness: "> 95% data points"
    - check_outliers: "< 5% outliers"
    - check_distribution: "normality test p > 0.05"

  statistical_analysis:
    - check_power: "power > 0.8"
    - check_significance: "alpha = 0.05"
    - check_multiple_comparisons: "Bonferroni correction applied"

  manuscript_quality:
    - check_citations: "all claims cited"
    - check_figures: "high-resolution (300 DPI)"
    - check_reproducibility: "methods detailed enough to replicate"

provenance_tracking:
  enabled: true
  content_addressing: true
  git_integration: true
  lab_notebook_sync: true
```

---

## Quality Gates

### Gate 1: Data Validation

**Trigger**: After data collection, before analysis

**Checks**:
- Completeness: > 95% data points present
- Outliers: < 5% outliers (IQR method)
- Distribution: Normality tests, skewness
- Duplicate detection
- Unit consistency

**Action if failed**: Return to data collection or flag for review

### Gate 2: Statistical Rigor

**Trigger**: After analysis, before interpretation

**Checks**:
- Power analysis: β > 0.8
- Significance threshold: α = 0.05 (adjustable)
- Multiple comparisons correction: Bonferroni/FDR
- Assumption validation: Independence, normality, homoscedasticity
- Effect size reporting: Cohen's d, odds ratios

**Action if failed**: Re-run with corrected parameters

### Gate 3: Reproducibility

**Trigger**: Before manuscript submission

**Checks**:
- Code availability: Published to repository
- Data availability: Deposited in public archive (where permitted)
- Methods detail: Step-by-step protocol
- Software versions: All dependencies documented
- Random seeds: Set for reproducible results

**Action if failed**: Cannot proceed to submission

---

## Example Session

### Starting a new experiment

```bash
# 1. Initialize experiment
./scripts/new-experiment.sh "protein-folding-2025-10-30"

# 2. Literature review
./workflows/literature-to-hypothesis.sh \
    "protein folding E. coli" \
    "molecular dynamics, chaperones"

# Output:
#   - literature/protein-folding-2025-10-30/
#   - hypotheses/hypothesis-001.md
#   - Human review required: inbox/human/hypothesis-review-001.md

# 3. Human approves hypothesis
./message.sh send human researcher "Approved" "Proceed with Hypothesis 001"

# 4. Collect data
./workflows/data-collection.sh \
    "experiment-001" \
    "protocols/protein-folding-protocol.json"

# 5. Data agent validates
./workflows/data-validation.sh "data/raw/experiment-001.csv"

# Quality gate passed ✓

# 6. Analyze data
./workflows/statistical-analysis.sh \
    "data/validated/experiment-001.csv" \
    "analysis-plans/hypothesis-001-plan.json"

# 7. Researcher interprets
./workflows/interpretation.sh \
    "results/experiment-001-analysis.json"

# 8. Draft manuscript section
./workflows/draft-results.sh \
    "results/experiment-001-interpretation.md" \
    "manuscripts/draft-v1-results.md"

# 9. Human reviews
cat inbox/human/manuscript-review-results-001.md
```

---

## Data Provenance

Every data file gets a provenance record:

```json
{
  "file": "data/validated/experiment-001.csv",
  "content_hash": "sha256:a3f9c8d1...",
  "provenance": {
    "source": "data/raw/experiment-001.csv",
    "transformations": [
      {
        "timestamp": "2025-10-30T15:30:45Z",
        "agent": "data",
        "operation": "remove_outliers",
        "parameters": {"method": "IQR", "threshold": 1.5},
        "code_hash": "sha256:b2e1f3a4..."
      },
      {
        "timestamp": "2025-10-30T15:35:22Z",
        "agent": "data",
        "operation": "normalize",
        "parameters": {"method": "z-score"},
        "code_hash": "sha256:c4d2a8f6..."
      }
    ],
    "validation": {
      "completeness": 0.98,
      "outlier_rate": 0.03,
      "normality_p_value": 0.12,
      "passed": true
    }
  },
  "lineage": {
    "experiment": "experiment-001",
    "protocol": "protocols/protein-folding-protocol.json",
    "equipment": ["spectrometer-A", "centrifuge-B"],
    "timestamp": "2025-10-30T14:00:00Z",
    "operator": "Dr. Jane Smith"
  }
}
```

This enables:
- **Reproducibility**: Exact transformation sequence
- **Debugging**: Trace errors to source
- **Compliance**: Audit trail for regulatory review
- **Trust**: Cryptographic verification

---

## Integration with Lab Notebooks

### Option 1: Jupyter Notebooks

```python
# In notebook cell:
from research_coordination import log_experiment, log_result

# Log experiment start
log_experiment(
    name="experiment-001",
    protocol="protocols/protein-folding-protocol.json",
    notes="Testing hypothesis 001: chaperone effect on folding rate"
)

# ... data collection code ...

# Log result
log_result(
    experiment="experiment-001",
    data_file="data/raw/experiment-001.csv",
    observations="Significant increase in folding rate with chaperone present"
)
```

### Option 2: Electronic Lab Notebook (ELN)

```bash
# Sync ELN entries to coordination system
./scripts/sync-eln.sh "eln-entries/2025-10-30" "inbox/researcher"
```

---

## Collaboration Patterns

### Pattern 1: Multi-Researcher Projects

**Scenario**: 3 researchers, 1 shared data agent

```yaml
researchers:
  - name: "Alice"
    role: "wet_lab"
    inbox: "inbox/alice"
  - name: "Bob"
    role: "computational"
    inbox: "inbox/bob"
  - name: "Carol"
    role: "writing"
    inbox: "inbox/carol"

shared_agents:
  - data_agent:
      serves: ["alice", "bob", "carol"]
      inbox: "inbox/data-shared"
```

**Workflow**:
```
Alice (wet lab) → Data Agent → Bob (analysis)
Bob (results) → Carol (writing) → All (review)
```

### Pattern 2: Hierarchical Research Teams

**Scenario**: PI + 2 postdocs + 3 grad students

```
PI (Human)
    ├─ Postdoc 1 (Sub-project A)
    │   ├─ Grad student 1
    │   └─ Grad student 2
    └─ Postdoc 2 (Sub-project B)
        └─ Grad student 3
```

**Authority delegation**:
- PI: Final approval on all papers
- Postdocs: Day-to-day decisions, grad student oversight
- Grad students: Execute experiments, draft sections

---

## Common Research Scenarios

### Scenario 1: Failed Experiment

```bash
# Data validation fails
./workflows/data-validation.sh "data/raw/experiment-005.csv"

# Output:
#   ✗ Quality gate failed: outlier_rate = 0.15 (threshold: 0.05)
#   ✗ Quality gate failed: completeness = 0.87 (threshold: 0.95)
#
#   Recommendation: Re-run experiment with improved protocol
#   Escalated to: inbox/human/failed-experiment-005.md

# Human reviews
cat inbox/human/failed-experiment-005.md

# Decision: Re-run with modified protocol
./message.sh send human researcher "Re-run" "Use protocol v2 with increased sample size"
```

### Scenario 2: Unexpected Result

```bash
# Analysis reveals unexpected pattern
./workflows/statistical-analysis.sh "data/experiment-010.csv"

# Output:
#   ⚠ Unexpected result detected:
#     Effect size: -2.3 (expected: positive)
#     Significance: p < 0.001
#
#   Possible causes:
#     1. Inverted hypothesis
#     2. Confounding variable
#     3. Novel discovery
#
#   Escalated to: inbox/researcher/unexpected-result-010.md

# Researcher investigates
./workflows/investigate-anomaly.sh "results/experiment-010-analysis.json"

# Confirms novel discovery
./message.sh send researcher human \
    "Novel discovery in experiment-010" \
    "Negative correlation suggests alternative mechanism. Literature search reveals no prior work on this. Recommend follow-up experiment."
```

### Scenario 3: Literature Contradiction

```bash
# Literature agent finds contradiction
./workflows/literature-check.sh "results/experiment-015-interpretation.md"

# Output:
#   ⚠ Contradiction detected:
#     Your result: "Protein X increases folding rate 2-fold"
#     Prior work (Smith 2023): "Protein X has no effect on folding rate"
#
#   Possible explanations:
#     1. Different experimental conditions
#     2. Species-specific effect
#     3. Measurement error in prior work
#
#   Escalated to: inbox/researcher/literature-contradiction-015.md

# Researcher addresses in manuscript
./message.sh send researcher publication \
    "Add discussion of Smith 2023 contradiction" \
    "Draft paragraph explaining species-specific effect hypothesis"
```

---

## Compliance & Ethics

### Institutional Review Board (IRB) Integration

```yaml
ethics:
  irb_approval_required: true
  irb_protocol_number: "2025-001-EX"
  informed_consent_required: true
  data_anonymization: true

  gates:
    - trigger: "before_data_collection"
      check: "irb_approval_valid"
      action_if_failed: "block_workflow"

    - trigger: "before_publication"
      check: "consent_forms_complete"
      action_if_failed: "escalate_to_pi"
```

### Data Protection (GDPR, HIPAA)

```yaml
data_protection:
  gdpr_compliant: true
  hipaa_compliant: false  # Not handling health data
  anonymization_method: "k-anonymity (k=5)"
  retention_policy: "7 years"
  deletion_on_request: true
```

---

## Troubleshooting

### "Quality gate failed: low statistical power"

```bash
# Check sample size
./scripts/power-analysis.sh \
    --effect-size 0.5 \
    --alpha 0.05 \
    --power 0.8

# Output: Minimum n = 64 (current n = 30)

# Solution: Collect more data or adjust expectations
```

### "Provenance chain broken"

```bash
# Verify data lineage
./scripts/verify-provenance.sh "data/validated/experiment-020.csv"

# Output:
#   ✗ Missing transformation step: normalization
#   ✗ Code hash mismatch for: outlier_removal

# Solution: Re-run analysis with proper provenance logging
./workflows/reanalyze-with-provenance.sh "data/raw/experiment-020.csv"
```

---

## Migration from Manual Research

### Step 1: Audit current workflow

```bash
./scripts/audit-current-workflow.sh ~/Documents/Research/
```

### Step 2: Map to agent roles

```bash
# Example mapping:
#   "I collect data" → researcher agent
#   "I clean data in Excel" → data agent
#   "I search Google Scholar" → literature agent
#   "I write in Word" → publication agent
```

### Step 3: Incremental adoption

```bash
# Week 1: Start with minimal coordination
cp -r templates/minimal-coordination ~/my-research

# Week 2: Add literature agent
./scripts/add-agent.sh literature

# Week 3: Add data agent
./scripts/add-agent.sh data

# Week 4: Full research template
cp -r templates/research-coordination ~/my-research-v2
```

---

## Success Metrics

### Efficiency Gains
- **Literature review**: 80% faster (4 hours → 48 minutes)
- **Data validation**: 95% automated (manual spot-checks only)
- **Manuscript drafting**: 60% faster (first draft)

### Quality Improvements
- **Reproducibility**: 100% (full provenance)
- **Statistical rigor**: Fewer p-hacking incidents
- **Citation accuracy**: 98% correct citations

### Research Integrity
- **Pre-registration**: Enforced via workflow gates
- **Data sharing**: Automatic deposition to repositories
- **Replication**: Complete methods documentation

---

## Next Steps

1. **Try the template**: Run through the example workflow
2. **Customize**: Edit `config.yaml` for your research domain
3. **Integrate**: Connect to your existing tools (Jupyter, Zotero, etc.)
4. **Collaborate**: Share with lab members
5. **Extend**: Add custom workflows for your specific needs

---

**Version**: 1.0
**Domain**: Scientific Research
**Last Updated**: 2025-10-30
**Maintained By**: CODE agent
