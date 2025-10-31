# Domain Transfer Cookbook Research Notes

**Herbarium Digitization Workflow → Target Domains**

**Date**: 2025-10-30
**Source System**: AAFC Herbarium DWC Extraction v2.0
**Research Focus**: Identifying transferable patterns for genomics, software dev, clinical trials

---

## Table of Contents

1. [Baseline: Herbarium Workflow Analysis](#baseline-herbarium-workflow-analysis)
2. [Domain 1: Genomics Research](#domain-1-genomics-research)
3. [Domain 2: Software Development](#domain-2-software-development)
4. [Domain 3: Clinical Trials](#domain-3-clinical-trials)
5. [Cross-Domain Pattern Library](#cross-domain-pattern-library)
6. [Configuration Examples](#configuration-examples)

---

## Baseline: Herbarium Workflow Analysis

### System Overview

**Purpose**: Extract structured Darwin Core metadata from herbarium specimen images for GBIF publication

**Repository**: `/Users/devvynmurphy/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/`

### Workflow Stages (6 Stages)

#### Stage 1: Image Acquisition

```
INPUT: Raw herbarium photos (JPG/PNG)
SOURCE: S3 bucket, local filesystem, HTTP endpoints
OUTPUT: Cached images with content hashing (SHA-256)
STORAGE: Content-addressed with specimen-centric provenance
```

**Key Features**:

- Multi-backend storage abstraction (local, S3, MinIO, HTTP)
- Automatic caching for remote sources
- Deduplication at image SHA-256 level
- S3 integration with lifecycle management

#### Stage 2: OCR Execution

```
INPUT: Images from cache
ENGINES: Apple Vision (primary), GPT-4o-mini, Claude, Google Vision, Azure, Tesseract
OUTPUT: Raw text extraction + confidence scores
COST-AWARE: $0 (Vision API) → $0.15/1000 (GPT-4o-mini) → $50/1000 (GPT-4 Vision)
```

**Engine Selection Matrix**:

| Engine | Cost/1000 | Fields Extracted | Quality | Platform | Use Case |
|--------|-----------|------------------|---------|----------|----------|
| **Apple Vision** | $0 | 7 (via rules) | Medium | macOS | Zero-budget baseline |
| **GPT-4o-mini** | $3.70 | 16 | High | All | Production standard |
| **Claude Sonnet** | $15.00 | 16 | Very High | All | Premium accuracy |
| **GPT-4 Vision** | $50.00 | 16 | Ultra | All | Research-grade |
| **Tesseract** | $0 | 0 (text) | Low | All | Fallback only |

**Configuration Example** (`config/config.default.toml`):

```toml
[ocr]
preferred_engine = "vision"
enabled_engines = ["vision", "google", "azure", "textract", "gemini", "claude", "gpt4o", "gpt4omini", "gpt"]
confidence_threshold = 0.80
require_api_fallback_on_windows = true
langs = ["eng", "fra", "lat"]

[gpt4omini]
fallback_threshold = 0.85
model = "gpt-4o-mini"
cost_per_1000 = 0.15
```

#### Stage 3: Field Extraction

```
INPUT: Raw OCR text
PROCESS: Rules engine (free) OR AI direct extraction (paid)
OUTPUT: Darwin Core candidate fields with confidence scores
VALIDATION: Field mapping, controlled vocabularies, taxonomic lookup
```

**Field Mapping Rules** (`config/rules/dwc_rules.toml`):

```toml
[fields]
barcode = "catalogNumber"
collector = "recordedBy"
"collector number" = "recordNumber"
"date collected" = "eventDate"
country = "country"
province = "stateProvince"
locality = "locality"
habitat = "habitat"
"scientific name" = "scientificName"
```

**Required Fields (7)**:

1. `catalogNumber` - Specimen catalog ID
2. `scientificName` - Taxonomic name
3. `eventDate` - Collection date (ISO 8601)
4. `recordedBy` - Collector name
5. `locality` - Collection location description
6. `stateProvince` - Administrative area
7. `country` - Country name

**Extended Fields (9 additional)**:

- `habitat`, `minimumElevationInMeters`, `recordNumber`
- `identifiedBy`, `dateIdentified`, `verbatimLocality`
- `verbatimEventDate`, `verbatimElevation`, `associatedTaxa`

#### Stage 4: Quality Control & Validation

```
INPUT: Candidate field extractions
VALIDATORS: Confidence scoring, completeness checking, GBIF taxonomy validation
OUTPUT: Prioritized review queue (CRITICAL → HIGH → MEDIUM → LOW → MINIMAL)
GATES: Quality score threshold (75%), completeness threshold (85%)
```

**Quality Metrics**:

1. **Completeness Score**: `(present_fields / required_fields) × 100`
   - 100%: All 7 required fields
   - 85.7%: 6/7 fields
   - 71.4%: 5/7 fields
   - <50%: Critical issues

2. **Confidence Score**: `average(field_confidence_values)`
   - 1.0: Human-verified
   - 0.8-0.99: High AI confidence
   - 0.5-0.79: Moderate confidence
   - 0.0-0.49: Low confidence (needs review)

3. **Quality Score**: `(completeness × 0.6) + (confidence × 0.4)`
   - ≥75: High quality
   - 50-74: Moderate quality
   - <50: Low quality (manual review required)

**Priority Levels**:

| Priority | Triggers | Review Strategy |
|----------|----------|-----------------|
| **CRITICAL** | API errors, extraction failed, no DWC data | Immediate triage, investigate errors |
| **HIGH** | Quality <50%, GBIF validation failed, multiple missing fields | Careful manual review + corrections |
| **MEDIUM** | Quality 50-75%, minor GBIF issues, some missing fields | Quick verification, spot corrections |
| **LOW** | Quality 75-90%, all required fields, warnings only | Minimal review, spot-check |
| **MINIMAL** | Quality ≥90%, GBIF verified, high confidence | Fast-track approval |

#### Stage 5: Human Review & Curation

```
INPUT: Prioritized specimen queue
INTERFACE: Web-based review dashboard (Quart async framework)
ACTIONS: Approve, reject, flag for expert, edit fields
OUTPUT: Curator-approved records with corrections
```

**Review Interface Features**:

- Image preview alongside extracted data
- GBIF live taxonomy lookup
- Field-level editing with confidence updates
- Keyboard shortcuts (j/k navigation, a/r/f actions)
- Filter by status (PENDING, APPROVED, REJECTED, FLAGGED)
- Filter by priority level
- Batch operations

**Validation Integration**:

- **GBIF Taxonomy**: Real-time species name verification
- **Locality Validation**: Coordinate consistency checks
- **Name Suggestions**: Autocomplete for scientific names
- **Synonym Resolution**: Accepted name lookup

**Review Workflow**:

```
1. Filter queue by priority (CRITICAL first)
2. For each specimen:
   a. Check image vs extracted data
   b. Verify required fields present
   c. Review quality indicators
   d. Run GBIF validation
   e. Make decision: Approve/Reject/Flag/Edit
3. Export approved records
```

#### Stage 6: Publication & Export

```
INPUT: Approved specimen records
FORMAT: Darwin Core Archive (DwC-A) ZIP
OUTPUT: GBIF-compliant biodiversity dataset
PROVENANCE: Git commit hash, processing metadata, agent identity
```

**Export Configuration** (`config/config.default.toml`):

```toml
[export]
enable_versioned_exports = true
default_export_version = "1.0.0"
bundle_format = "rich"  # includes metadata
include_checksums = true
include_git_info = true
include_system_info = true
export_retention_days = 365
```

**Provenance Tracking**:

```python
manifest = {
    "version": "1.0.0",
    "git_commit": "fd028e2a4...",  # Full SHA
    "git_commit_short": "fd028e2",
    "git_dirty": False,
    "timestamp": "2025-10-30T15:30:00Z",
    "agent_identity": {
        "agent_type": "claude-code",
        "human_operator": "devvynmurphy",
        "session_id": "code-37834-aafc-work-session",
        "workspace": "AAFC-SRDC Saskatoon"
    },
    "processing_metadata": {
        "specimens_processed": 2885,
        "ocr_engine": "gpt-4o-mini",
        "extraction_runtime": "2h 15m"
    }
}
```

### Agent Roles (3 Primary Roles)

#### Role 1: Human Curator (Domain Expert)

**Authority**: Scientific validation, taxonomic decisions, stakeholder communication

**Responsibilities**:

- Verify specimen identification accuracy
- Validate Darwin Core field mappings
- Review GBIF taxonomy matches
- Approve/reject records for publication
- Flag specimens for expert consultation
- Define acceptable quality thresholds

**Automation Boundary**: Tier 3 (requires approval)

- Scientific validation decisions
- Stakeholder communications
- Production configuration changes
- Budget/resource allocation

#### Role 2: Code Agent (Technical Implementation)

**Authority**: Pipeline execution, optimization, error handling, documentation

**Responsibilities**:

- Execute OCR engines with cost optimization
- Implement quality gates and validation
- Generate provenance metadata
- Maintain code quality (linting, testing)
- Create technical documentation
- Commit and push code every 30-45 minutes

**Automation Boundary**: Tier 1 (fully automated)

- Work session logging and time tracking
- Git commits with provenance
- File organization following patterns
- Testing and QA workflows

**Pre-Commit Checks**:

```bash
uv run ruff check . --fix && \
uv run ruff format . && \
uv run python -m pytest tests/unit/ -q && \
git diff --check
```

#### Role 3: Pipeline Composer Agent (Orchestration)

**Authority**: Engine selection, pipeline assembly, cost optimization

**Responsibilities**:

- Evaluate constraints (budget, deadline, quality)
- Inventory available OCR engines
- Compose optimal processing pipeline
- Route specimens to appropriate engines
- Monitor cost vs quality tradeoffs

**Decision Logic**:

```python
def compose_pipeline(budget: float, deadline: str, quality: str):
    if budget == 0:
        if quality == "baseline":
            return ["vision", "rules"]  # FREE
        else:
            return ["gpt_free_tier", "rules_fallback"]

    if budget >= 1.60 and quality == "high":
        return ["gpt_direct"]  # 16 fields

    if quality == "research-grade":
        return ["vision", "gpt", "claude", "ensemble_vote"]

    # Hybrid: free baseline + selective enhancement
    return ["vision", "validate_confidence", "gpt_if_needed"]
```

### Quality Gates (4 Critical Gates)

#### Gate 1: Dependency Check

**Location**: Pre-processing
**Validation**: OCR engine availability, API keys configured, storage backend accessible
**Action on Failure**: Prevent extraction run, display missing dependencies

```bash
uv run python cli.py check-deps
```

#### Gate 2: Confidence Threshold

**Location**: Post-OCR extraction
**Validation**: Field confidence ≥ 0.80 (configurable)
**Action on Failure**: Flag for higher-tier engine or human review

```toml
[ocr]
confidence_threshold = 0.80

[gpt4omini]
fallback_threshold = 0.85
```

#### Gate 3: Completeness Check

**Location**: Pre-review queue
**Validation**: Required fields present (7/7 for minimal quality)
**Action on Failure**: Assign HIGH or CRITICAL priority

```toml
[dwc]
strict_minimal_fields = ["catalogNumber","scientificName","eventDate","recordedBy","locality","stateProvince","country"]
flag_if_missing_minimal = true
```

#### Gate 4: GBIF Validation

**Location**: Review workflow
**Validation**: Scientific names verified in GBIF backbone taxonomy
**Action on Failure**: Flag for taxonomic expert review

```toml
[qc.gbif]
enabled = false  # Enable for production
min_confidence_score = 0.80
enable_fuzzy_matching = true
```

### Validation Rules (5 Rule Categories)

#### Category 1: Field Format Validation

```python
# Date format validation (ISO 8601)
eventDate_pattern = r'^\d{4}-\d{2}-\d{2}$'  # YYYY-MM-DD

# Coordinate validation
latitude_range = (-90, 90)
longitude_range = (-180, 180)

# Catalog number format (institution-specific)
catalogNumber_pattern = r'^\d{6}$'  # 6-digit barcode
```

#### Category 2: Controlled Vocabulary

```toml
# config/rules/vocab.toml
[countries]
allowed = ["Canada", "United States", "Mexico"]

[provinces_canada]
allowed = ["Alberta", "Saskatchewan", "Manitoba", "Ontario", "Quebec"]
```

#### Category 3: Taxonomic Validation

```python
# GBIF species match endpoint
gbif_api = "https://api.gbif.org/v1/species/match"

def validate_scientific_name(name: str) -> dict:
    response = requests.get(gbif_api, params={"name": name})
    return {
        "verified": response.get("matchType") == "EXACT",
        "accepted_name": response.get("scientificName"),
        "taxon_key": response.get("usageKey"),
        "confidence": response.get("confidence", 0) / 100
    }
```

#### Category 4: Cross-Field Consistency

```python
# Locality consistency checks
def validate_locality_consistency(record: dict) -> list[str]:
    issues = []

    # Country/province match
    if record["country"] == "Canada" and record["stateProvince"] not in CANADIAN_PROVINCES:
        issues.append("Province not in Canada")

    # Coordinates within country bounds
    if record.get("decimalLatitude") and record.get("decimalLongitude"):
        if not coordinates_in_country(record["decimalLatitude"],
                                     record["decimalLongitude"],
                                     record["country"]):
            issues.append("Coordinates outside country bounds")

    return issues
```

#### Category 5: Duplicate Detection

```toml
[qc]
dupes = ["catalog", "sha256", "phash"]
phash_threshold = 10  # Perceptual hash similarity threshold
```

### Key Patterns Used

#### Pattern 1: Scientific Provenance Pattern

**File**: `/Users/devvynmurphy/devvyn-meta-project/knowledge-base/patterns/scientific-provenance-pattern.md`

**Description**: Use git as read-only metadata provider for cryptographic traceability

**Implementation**:

```python
# Capture at processing start (read-only)
git_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
git_dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], text=True).strip())

# Embed in export manifest
manifest = {
    "git_commit": git_commit,
    "git_commit_short": git_commit[:7],
    "git_dirty": git_dirty,
    "timestamp": datetime.now(timezone.utc).isoformat()
}
```

**Evidence**: 2,885 AAFC specimens with full provenance, every export traceable to exact code version

#### Pattern 2: Work Session Accountability Pattern

**File**: `/Users/devvynmurphy/devvyn-meta-project/knowledge-base/patterns/work-session-accountability.md`

**Description**: Track professional work sessions with complete accountability chain

**Implementation**:

```yaml
---
session_start: 2025-10-01T19:53:12Z
session_id: code-37834-aafc-work-session
workspace: AAFC-SRDC Saskatoon
project: aafc-herbarium-dwc-extraction-2025
agent: claude-code
human: Devvyn Murphy

tasks:
  - Documentation reorganization (PR #215)
  - Bridge sync and infrastructure updates
  - Work session accountability activation

artifacts_produced:
  - Commits: 152f59f, 155741d, 07f3789
  - Work session log initialized
  - Agent provenance tracking added

session_end: 2025-10-01T23:30:00Z
duration_hours: 3.5
status: completed
---
```

#### Pattern 3: Documentation Quality Gates Pattern

**File**: `/Users/devvynmurphy/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/decisions/001-documentation-quality-gates.md`

**Description**: Shift-left validation for docs-as-code

**Quality Gates**:

1. **Link validation**: All internal links resolve
2. **Code examples**: Executable and tested
3. **Version consistency**: Docs match codebase version
4. **External references**: GitHub URLs valid after tagging

**CI Integration**:

```yaml
# .github/workflows/docs-validation.yml
quality-gate:
  name: Documentation Quality Gate
  runs-on: ubuntu-latest
  steps:
    - name: Check doc links
      run: ./github/scripts/check-doc-links.sh
    - name: Validate examples
      run: pytest docs/examples/
```

#### Pattern 4: Multi-Backend Storage Abstraction

**File**: `/Users/devvynmurphy/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/STORAGE_ABSTRACTION.md`

**Description**: Unified interface for local, S3, MinIO, HTTP image sources

**Configuration**:

```toml
[storage]
backend = "s3"  # Options: "local", "s3", "minio", "http"

[storage.s3]
bucket = "aafc-herbarium"
prefix = "specimens/"
region = "ca-central-1"

# Caching for remote backends
cache_enabled = true
cache_dir = "/tmp/herbarium-image-cache"
cache_max_size_mb = 1000
```

**Key Features**:

- Content-addressed caching (SHA-256)
- Automatic download on first access
- Lifecycle management for cache eviction
- Transparent switching between backends

#### Pattern 5: Specimen-Centric Provenance Architecture

**File**: `/Users/devvynmurphy/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/docs/specimen_provenance_architecture.md`

**Description**: Track complete lineage from raw images through all transformations

**Architecture Shift**:

- **Before**: Image-centric (lost specimen identity across runs)
- **After**: Specimen-centric (complete lineage tracking)

**Deduplication Key**: `(image_sha256, extraction_params)`

- Same image + same parameters = reuse previous extraction
- Same image + different parameters = new extraction variant

**Multi-Extraction Aggregation**:

```python
# Aggregate fields from multiple extraction runs
def aggregate_extractions(specimen_id: str) -> dict:
    extractions = get_all_extractions(specimen_id)

    aggregated = {}
    for field in DARWIN_CORE_FIELDS:
        candidates = [(e[field]["value"], e[field]["confidence"])
                      for e in extractions if field in e]

        # Confidence-weighted selection
        aggregated[field] = max(candidates, key=lambda x: x[1])

    return aggregated
```

---

## Domain 1: Genomics Research

### Domain Overview

**Context**: DNA sequencing workflows from sample collection to variant calling

**Data Pipeline**: Biological sample → DNA extraction → Sequencing → Quality control → Variant calling → Annotation → Publication

**Similar Complexity**: Multi-stage processing, quality thresholds, expensive computation, regulatory compliance

### Stage Mapping from Herbarium

#### Herbarium → Genomics Stage Mapping

| Herbarium Stage | Genomics Equivalent | Mapping Rationale |
|-----------------|---------------------|-------------------|
| **Image Acquisition** | Sample Collection & Storage | Both track physical specimens with metadata |
| **OCR Execution** | DNA Sequencing (Illumina/PacBio) | Expensive automated data generation with quality scores |
| **Field Extraction** | Read Alignment & Assembly | Converting raw data to structured format |
| **Quality Control** | QC Metrics (FastQC, MultiQC) | Confidence scoring, completeness checks |
| **Human Review** | Variant Review & Clinical Interpretation | Expert validation of high-impact findings |
| **Publication** | NCBI SRA/GEO Submission | Standardized public data repository |

### Agent Roles Adaptation

#### Role 1: Bioinformatician (Domain Expert)

**Herbarium Equivalent**: Human Curator

**Responsibilities**:

- Validate variant calls against population databases
- Interpret clinical significance of variants
- Review QC metrics for sample quality
- Approve sequencing runs for analysis
- Flag samples for wet-lab re-processing

**Automation Boundary**: Tier 3 (requires approval)

- Clinical variant interpretation
- Sample rejection decisions
- Protocol modifications
- IRB/ethics communications

#### Role 2: Pipeline Agent (Technical Implementation)

**Herbarium Equivalent**: Code Agent

**Responsibilities**:

- Execute alignment pipelines (BWA, STAR)
- Run variant callers (GATK, FreeBayes)
- Generate QC reports (FastQC, Picard)
- Track computational provenance
- Commit pipeline configs to version control

**Automation Boundary**: Tier 1 (fully automated)

- Pipeline execution logging
- Git commits with run IDs
- File organization (FASTQ, BAM, VCF)
- Automated quality checks

**Pre-Execution Checks**:

```bash
# Validate environment before pipeline run
check_reference_genome_indexed && \
check_adapter_sequences_available && \
validate_sample_metadata && \
test_disk_space_sufficient
```

#### Role 3: Resource Scheduler Agent (Orchestration)

**Herbarium Equivalent**: Pipeline Composer Agent

**Responsibilities**:

- Allocate compute resources (CPU, memory, GPU)
- Select sequencing depth based on budget
- Choose variant callers based on application
- Optimize cost vs coverage tradeoffs
- Route samples to appropriate pipelines

**Decision Logic**:

```python
def compose_genomics_pipeline(budget: float, application: str, urgency: str):
    if application == "population_genomics":
        return {
            "sequencing": "illumina_30x",
            "aligner": "bwa-mem2",
            "caller": "gatk_haplotypecaller",
            "cost": 800.00  # per sample
        }

    if application == "clinical_diagnostic" and urgency == "stat":
        return {
            "sequencing": "illumina_100x",
            "aligner": "dragen",  # FPGA-accelerated
            "caller": "gatk_haplotypecaller",
            "validation": "sanger_confirmation",
            "cost": 2500.00
        }

    if budget < 500:
        return {
            "sequencing": "illumina_10x",  # Low coverage
            "aligner": "bwa-mem",
            "caller": "freebayes",  # Free, less accurate
            "cost": 400.00
        }
```

### Quality Gates Adaptation

#### Gate 1: Sample QC (Pre-Sequencing)

**Herbarium Equivalent**: Dependency Check

**Validation**:

- DNA concentration ≥ 10 ng/µL
- 260/280 ratio: 1.8-2.0 (purity)
- Fragment size distribution acceptable
- Sample metadata complete

**Action on Failure**: Reject sample, request re-extraction

```python
def validate_sample_qc(sample: dict) -> dict:
    issues = []

    if sample["concentration_ng_ul"] < 10:
        issues.append("Insufficient DNA concentration")

    if not (1.8 <= sample["260_280_ratio"] <= 2.0):
        issues.append("DNA purity out of range")

    if sample["fragment_size_bp"] < 200:
        issues.append("Fragmented DNA")

    return {
        "pass": len(issues) == 0,
        "priority": "CRITICAL" if issues else "MINIMAL",
        "issues": issues
    }
```

#### Gate 2: Sequencing QC (Post-Sequencing)

**Herbarium Equivalent**: Confidence Threshold

**Validation**:

- Q30 score ≥ 80% (base quality)
- Total reads ≥ target coverage
- Adapter contamination < 5%
- Duplicate rate < 20%

**Action on Failure**: Flag for re-sequencing or proceed with low-confidence flag

```python
def validate_sequencing_qc(fastq_file: str) -> dict:
    qc_metrics = run_fastqc(fastq_file)

    return {
        "pass": (qc_metrics["q30_percent"] >= 80 and
                 qc_metrics["adapter_content"] < 5 and
                 qc_metrics["duplicate_rate"] < 20),
        "priority": "HIGH" if qc_metrics["q30_percent"] < 80 else "LOW",
        "metrics": qc_metrics
    }
```

#### Gate 3: Alignment QC (Post-Alignment)

**Herbarium Equivalent**: Completeness Check

**Validation**:

- Mapping rate ≥ 95%
- On-target rate ≥ 80% (for exome/panel)
- Mean coverage ≥ target depth
- Coverage uniformity (min/max ratio)

**Action on Failure**: Assign HIGH priority for expert review

```python
def validate_alignment_qc(bam_file: str) -> dict:
    metrics = run_picard_metrics(bam_file)

    required_coverage = 30  # 30x depth

    return {
        "pass": (metrics["mapping_rate"] >= 0.95 and
                 metrics["mean_coverage"] >= required_coverage),
        "priority": "MEDIUM" if metrics["mean_coverage"] < required_coverage else "LOW",
        "metrics": metrics
    }
```

#### Gate 4: Variant Validation (Clinical Applications)

**Herbarium Equivalent**: GBIF Validation

**Validation**:

- Variant present in population databases (gnomAD, ClinVar)
- Allele frequency consistency
- Mendelian inheritance patterns (trio sequencing)
- Clinical significance classification

**Action on Failure**: Flag for clinical geneticist review

```python
def validate_variant_clinical(variant: dict) -> dict:
    # Query ClinVar database
    clinvar_entry = query_clinvar(variant["rsid"])

    return {
        "verified": clinvar_entry is not None,
        "clinical_significance": clinvar_entry.get("significance", "uncertain"),
        "review_status": clinvar_entry.get("review_status", "no_assertion"),
        "requires_expert": clinvar_entry.get("significance") in ["pathogenic", "likely_pathogenic"]
    }
```

### Validation Rules Adaptation

#### Category 1: Sample Metadata Validation

**Herbarium Equivalent**: Field Format Validation

```python
# Sample ID format validation
sample_id_pattern = r'^[A-Z]{2}\d{6}$'  # e.g., SM123456

# Date validation (ISO 8601)
collection_date_pattern = r'^\d{4}-\d{2}-\d{2}$'

# Tissue type controlled vocabulary
allowed_tissue_types = ["blood", "saliva", "tissue_ffpe", "tissue_fresh_frozen"]
```

#### Category 2: Sequencing Parameter Validation

**Herbarium Equivalent**: Controlled Vocabulary

```toml
[sequencing]
allowed_platforms = ["illumina_novaseq", "illumina_hiseq", "pacbio_sequel", "oxford_nanopore"]
allowed_strategies = ["wgs", "wes", "targeted_panel", "rna_seq"]

[coverage_requirements]
wgs_minimum = 30
wes_minimum = 50
targeted_panel_minimum = 100
```

#### Category 3: Variant Annotation Validation

**Herbarium Equivalent**: Taxonomic Validation

```python
# Variant Effect Predictor (VEP) annotation
def annotate_variant(variant: dict) -> dict:
    vep_result = run_vep(variant)

    return {
        "gene": vep_result["gene_symbol"],
        "consequence": vep_result["most_severe_consequence"],
        "impact": vep_result["impact"],  # HIGH, MODERATE, LOW, MODIFIER
        "sift_score": vep_result["sift"],
        "polyphen_score": vep_result["polyphen"],
        "population_frequency": vep_result["gnomad_af"]
    }
```

#### Category 4: Cross-Sample Consistency

**Herbarium Equivalent**: Cross-Field Consistency

```python
def validate_family_consistency(family: list[dict]) -> list[str]:
    issues = []

    # Mendelian inheritance check for trios
    if len(family) == 3:  # proband, mother, father
        for variant in family[0]["variants"]:
            if not follows_mendelian_pattern(variant, family[1], family[2]):
                issues.append(f"Non-Mendelian inheritance: {variant['id']}")

    # Contamination check (unexpected sample similarity)
    for i, sample1 in enumerate(family):
        for sample2 in family[i+1:]:
            similarity = calculate_genotype_similarity(sample1, sample2)
            if similarity > 0.95 and sample1["id"] != sample2["id"]:
                issues.append(f"Possible sample swap: {sample1['id']} vs {sample2['id']}")

    return issues
```

#### Category 5: Duplicate Detection

**Herbarium Equivalent**: Duplicate Detection

```python
# PCR duplicate detection (same start/end coordinates)
def detect_pcr_duplicates(bam_file: str) -> dict:
    duplicates = run_picard_markduplicates(bam_file)

    return {
        "duplicate_rate": duplicates["percent"],
        "pass": duplicates["percent"] < 20,  # Threshold
        "total_reads": duplicates["total"],
        "duplicate_reads": duplicates["duplicates"]
    }
```

### Configuration Example: Genomics Pipeline

```toml
# config/genomics_pipeline.toml

[sequencing]
platform = "illumina_novaseq"
strategy = "wgs"
target_coverage = 30
read_length = 150
paired_end = true

[alignment]
reference_genome = "GRCh38"
aligner = "bwa-mem2"
threads = 32
memory_gb = 64

[variant_calling]
caller = "gatk_haplotypecaller"
confidence_threshold = 30.0  # Phred-scaled quality
min_coverage = 10
max_coverage = 500

[quality_gates]
# Gate 1: Sample QC
min_dna_concentration_ng_ul = 10.0
min_260_280_ratio = 1.8
max_260_280_ratio = 2.0

# Gate 2: Sequencing QC
min_q30_percent = 80.0
max_adapter_content = 5.0
max_duplicate_rate = 20.0

# Gate 3: Alignment QC
min_mapping_rate = 0.95
min_on_target_rate = 0.80
min_mean_coverage = 30.0

# Gate 4: Variant QC
min_variant_quality = 30.0
min_genotype_quality = 20.0
max_fisher_strand_bias = 60.0

[validation]
# External database validation
clinvar_api = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
gnomad_api = "https://gnomad.broadinstitute.org/api/"
population_frequency_threshold = 0.01  # Flag if AF > 1%

[export]
output_format = "vcf"  # Variant Call Format
include_provenance = true
bundle_with_bam = false  # BAM files too large for routine bundling
export_to_ncbi_sra = true

[agent_roles]
# Role 1: Bioinformatician
bioinformatician_review_priority = ["CRITICAL", "HIGH"]
bioinformatician_approval_required = ["pathogenic", "likely_pathogenic"]

# Role 2: Pipeline Agent
pipeline_agent_automation = ["alignment", "variant_calling", "annotation"]
pipeline_agent_commit_frequency_minutes = 30

# Role 3: Resource Scheduler
scheduler_cost_budget_per_sample = 800.00
scheduler_turnaround_time_hours = 48
scheduler_compute_resources = "slurm_cluster"
```

### Concrete Workflow Example

**Scenario**: Whole genome sequencing for rare disease diagnosis (clinical application)

**Input**: Blood sample from patient + family trio (proband, mother, father)

**Stage 1: Sample Collection & QC**

```yaml
sample_metadata:
  sample_id: SM123456
  patient_id: PT789012
  family_id: FAM345678
  relationship: proband
  tissue_type: blood
  collection_date: 2025-10-15
  dna_concentration_ng_ul: 45.2
  260_280_ratio: 1.92
  fragment_size_bp: 15000

validation_result:
  gate: sample_qc
  pass: true
  priority: MINIMAL
```

**Stage 2: Sequencing Execution**

```yaml
sequencing_run:
  run_id: RUN20251020_001
  platform: illumina_novaseq
  strategy: wgs
  target_coverage: 30x
  read_length: 150
  paired_end: true

  qc_metrics:
    total_reads: 450000000
    q30_percent: 92.3
    adapter_content: 1.2
    duplicate_rate: 8.5

  validation_result:
    gate: sequencing_qc
    pass: true
    priority: LOW
```

**Stage 3: Alignment & Assembly**

```yaml
alignment_run:
  aligner: bwa-mem2
  reference: GRCh38
  threads: 32
  runtime_hours: 6.5

  qc_metrics:
    mapping_rate: 98.2
    mean_coverage: 32.4
    coverage_uniformity: 0.85
    properly_paired: 96.8

  validation_result:
    gate: alignment_qc
    pass: true
    priority: LOW
```

**Stage 4: Variant Calling & QC**

```yaml
variant_calling:
  caller: gatk_haplotypecaller
  total_variants: 4235678
  novel_variants: 23456  # Not in dbSNP

  qc_metrics:
    ti_tv_ratio: 2.05  # Expected ~2.0 for WGS
    het_hom_ratio: 1.58  # Expected ~1.5
    mendelian_error_rate: 0.2  # < 1% acceptable

  validation_result:
    gate: variant_qc
    pass: true
    priority: LOW
```

**Stage 5: Clinical Variant Review**

```yaml
clinically_significant_variants:
  - variant_id: chr1:12345678_A_G
    gene: BRCA1
    consequence: missense_variant
    clinical_significance: pathogenic
    clinvar_id: RCV000123456
    review_status: expert_panel
    inheritance: de_novo  # Not in parents

    validation_result:
      gate: clinical_validation
      verified: true
      requires_expert: true
      priority: CRITICAL

  - variant_id: chr7:87654321_C_T
    gene: CFTR
    consequence: synonymous_variant
    clinical_significance: benign
    population_frequency: 0.15

    validation_result:
      verified: true
      requires_expert: false
      priority: MINIMAL
```

**Stage 6: Report Generation & Publication**

```yaml
clinical_report:
  report_id: RPT20251025_SM123456
  patient_id: PT789012
  report_date: 2025-10-25

  key_findings:
    - De novo BRCA1 pathogenic variant identified
    - Consistent with clinical presentation
    - Recommends genetic counseling

  data_publication:
    ncbi_sra_accession: SRR123456789
    dbgap_study: phs001234
    consent_code: GRU  # General Research Use

  provenance:
    git_commit: abc123def
    pipeline_version: 2.1.0
    reference_genome: GRCh38
    bioinformatician: Dr. Jane Smith
    approval_date: 2025-10-26
```

---

## Domain 2: Software Development

### Domain Overview

**Context**: Feature development lifecycle from requirements to production deployment

**Data Pipeline**: Requirements → Design → Implementation → Testing → Code review → CI/CD → Production deployment

**Similar Complexity**: Multi-stage validation, quality gates, expensive failures, regulatory compliance (SOC2, HIPAA)

### Stage Mapping from Herbarium

| Herbarium Stage | Software Development Equivalent | Mapping Rationale |
|-----------------|--------------------------------|-------------------|
| **Image Acquisition** | Requirements Gathering | Collecting input data for processing |
| **OCR Execution** | Code Implementation | Automated transformation with error potential |
| **Field Extraction** | Feature Extraction & Testing | Converting implementation to validated functionality |
| **Quality Control** | Static Analysis & Unit Tests | Confidence scoring, completeness checks |
| **Human Review** | Code Review & Security Audit | Expert validation of high-risk changes |
| **Publication** | Production Deployment | Standardized release to end users |

### Agent Roles Adaptation

#### Role 1: Senior Engineer (Domain Expert)

**Herbarium Equivalent**: Human Curator

**Responsibilities**:

- Review architecture decisions
- Validate security implications
- Approve production deployments
- Design system scalability
- Mentor junior developers

**Automation Boundary**: Tier 3 (requires approval)

- Production configuration changes
- Database schema migrations
- Security policy modifications
- Customer-facing communications

#### Role 2: Dev Agent (Technical Implementation)

**Herbarium Equivalent**: Code Agent

**Responsibilities**:

- Implement features from specifications
- Write unit and integration tests
- Run linters and formatters
- Generate documentation
- Commit code with descriptive messages

**Automation Boundary**: Tier 1 (fully automated)

- Code formatting (Prettier, Black, Ruff)
- Dependency updates (Dependabot)
- Documentation generation (JSDoc, Sphinx)
- Test execution (Jest, pytest)

**Pre-Commit Checks**:

```bash
# Pre-commit hook (runs automatically)
npm run lint && \
npm run format && \
npm test -- --coverage && \
git diff --check
```

#### Role 3: CI/CD Orchestrator Agent (Orchestration)

**Herbarium Equivalent**: Pipeline Composer Agent

**Responsibilities**:

- Select deployment strategy (blue/green, canary, rolling)
- Allocate CI/CD resources
- Route builds to appropriate runners
- Optimize cost vs speed tradeoffs
- Monitor deployment success rates

**Decision Logic**:

```python
def compose_deployment_pipeline(change_risk: str, user_impact: str, urgency: str):
    if change_risk == "high" and user_impact == "critical":
        return {
            "strategy": "canary",
            "rollout_percentage": [5, 10, 25, 50, 100],
            "validation_per_stage": "manual_approval",
            "rollback_automatic": True,
            "cost": "premium"
        }

    if urgency == "hotfix":
        return {
            "strategy": "blue_green",
            "validation": "smoke_tests_only",
            "rollback_automatic": True,
            "cost": "standard"
        }

    # Standard feature deployment
    return {
        "strategy": "rolling",
        "rollout_percentage": [25, 50, 100],
        "validation": "integration_tests",
        "cost": "economy"
    }
```

### Quality Gates Adaptation

#### Gate 1: Requirements Validation (Pre-Implementation)

**Herbarium Equivalent**: Dependency Check

**Validation**:

- User story acceptance criteria defined
- API contracts documented
- Database schema reviewed
- Security requirements identified

**Action on Failure**: Block implementation, request requirements clarification

```python
def validate_requirements(user_story: dict) -> dict:
    issues = []

    if not user_story.get("acceptance_criteria"):
        issues.append("Missing acceptance criteria")

    if user_story.get("requires_database") and not user_story.get("schema_design"):
        issues.append("Database changes require schema review")

    if user_story.get("handles_pii") and not user_story.get("privacy_review"):
        issues.append("PII handling requires privacy review")

    return {
        "pass": len(issues) == 0,
        "priority": "CRITICAL" if issues else "MINIMAL",
        "issues": issues
    }
```

#### Gate 2: Static Analysis (Post-Implementation)

**Herbarium Equivalent**: Confidence Threshold

**Validation**:

- Linter score ≥ 8/10
- Code coverage ≥ 80%
- Complexity score ≤ 10 (cyclomatic complexity)
- No critical security vulnerabilities

**Action on Failure**: Block merge, assign back to developer

```python
def validate_code_quality(pr: dict) -> dict:
    metrics = run_static_analysis(pr["files"])

    return {
        "pass": (metrics["lint_score"] >= 8.0 and
                 metrics["coverage_percent"] >= 80 and
                 metrics["max_complexity"] <= 10 and
                 metrics["critical_vulnerabilities"] == 0),
        "priority": "HIGH" if metrics["critical_vulnerabilities"] > 0 else "LOW",
        "metrics": metrics
    }
```

#### Gate 3: Integration Testing (Pre-Review)

**Herbarium Equivalent**: Completeness Check

**Validation**:

- All integration tests passing
- API endpoints responding correctly
- Database migrations tested
- Feature flags configured

**Action on Failure**: Assign MEDIUM priority for fixing

```python
def validate_integration(pr: dict) -> dict:
    test_results = run_integration_tests(pr["branch"])

    return {
        "pass": test_results["failed"] == 0,
        "priority": "MEDIUM" if test_results["failed"] > 0 else "LOW",
        "metrics": {
            "passed": test_results["passed"],
            "failed": test_results["failed"],
            "skipped": test_results["skipped"]
        }
    }
```

#### Gate 4: Security Audit (Production Deployment)

**Herbarium Equivalent**: GBIF Validation

**Validation**:

- OWASP Top 10 vulnerabilities checked
- Dependency vulnerabilities scanned
- Secrets not committed to repository
- Authentication/authorization tested

**Action on Failure**: Block deployment, escalate to security team

```python
def validate_security(pr: dict) -> dict:
    # OWASP ZAP scan
    owasp_results = run_owasp_zap(pr["staging_url"])

    # Dependency scan
    dep_results = run_snyk_scan(pr["files"])

    # Secret detection
    secret_results = run_trufflehog(pr["commits"])

    return {
        "pass": (owasp_results["high_severity"] == 0 and
                 dep_results["critical_vulnerabilities"] == 0 and
                 secret_results["secrets_found"] == 0),
        "priority": "CRITICAL" if secret_results["secrets_found"] > 0 else "HIGH",
        "issues": owasp_results["issues"] + dep_results["issues"] + secret_results["issues"]
    }
```

### Validation Rules Adaptation

#### Category 1: Code Style Validation

**Herbarium Equivalent**: Field Format Validation

```javascript
// ESLint configuration
module.exports = {
  rules: {
    'max-len': ['error', { code: 100 }],
    'complexity': ['error', 10],
    'no-console': 'error',
    'no-unused-vars': 'error',
    'prefer-const': 'error'
  }
}
```

#### Category 2: Controlled Vocabulary (Naming Conventions)

**Herbarium Equivalent**: Controlled Vocabulary

```toml
[naming_conventions]
# Function names: camelCase
function_pattern = "^[a-z][a-zA-Z0-9]*$"

# Class names: PascalCase
class_pattern = "^[A-Z][a-zA-Z0-9]*$"

# Constants: UPPER_SNAKE_CASE
constant_pattern = "^[A-Z][A-Z0-9_]*$"

# File names: kebab-case.ts
file_pattern = "^[a-z0-9-]+\\.(ts|js|tsx|jsx)$"
```

#### Category 3: API Contract Validation

**Herbarium Equivalent**: Taxonomic Validation

```python
# OpenAPI schema validation
def validate_api_response(endpoint: str, response: dict) -> dict:
    schema = load_openapi_schema(endpoint)

    validator = OpenAPIValidator(schema)
    validation_result = validator.validate(response)

    return {
        "valid": validation_result.is_valid,
        "errors": validation_result.errors,
        "schema_version": schema["info"]["version"]
    }
```

#### Category 4: Cross-Module Dependency Validation

**Herbarium Equivalent**: Cross-Field Consistency

```python
def validate_dependencies(module: str) -> list[str]:
    issues = []

    # Circular dependency check
    circular = detect_circular_dependencies(module)
    if circular:
        issues.append(f"Circular dependency: {' -> '.join(circular)}")

    # Version consistency
    for dep in get_dependencies(module):
        if not is_version_compatible(dep["name"], dep["version"]):
            issues.append(f"Incompatible version: {dep['name']}@{dep['version']}")

    # Unused dependencies
    unused = find_unused_dependencies(module)
    if unused:
        issues.append(f"Unused dependencies: {', '.join(unused)}")

    return issues
```

#### Category 5: Duplicate Code Detection

**Herbarium Equivalent**: Duplicate Detection

```python
# Copy-paste detection (Moss, PMD-CPD)
def detect_code_duplication(codebase: str) -> dict:
    duplicates = run_cpd_analysis(codebase)

    return {
        "duplicate_lines": duplicates["total_lines"],
        "duplicate_percentage": duplicates["percentage"],
        "pass": duplicates["percentage"] < 5,  # Threshold
        "largest_duplicate": duplicates["largest_block"]
    }
```

### Configuration Example: Feature Development Pipeline

```toml
# config/feature_pipeline.toml

[development]
branch_naming = "feature/TICKET-123-description"
commit_message_format = "type(scope): subject"  # Conventional Commits
max_files_per_pr = 15
max_lines_per_pr = 500

[code_quality]
# Static analysis thresholds
min_lint_score = 8.0
min_code_coverage = 80.0
max_complexity = 10
max_function_length = 50

[testing]
# Test types required
unit_tests_required = true
integration_tests_required = true
e2e_tests_optional = true

# Test execution
parallel_execution = true
max_test_runtime_minutes = 15
retry_flaky_tests = 2

[quality_gates]
# Gate 1: Requirements validation
require_acceptance_criteria = true
require_api_docs = true
require_schema_review_for_db_changes = true

# Gate 2: Static analysis
block_on_critical_vulnerabilities = true
block_on_low_coverage = true
block_on_lint_failures = true

# Gate 3: Integration testing
require_all_tests_passing = true
allow_skip_with_justification = false

# Gate 4: Security audit
require_owasp_scan = true
require_dependency_scan = true
require_secret_scan = true
block_on_high_severity = true

[code_review]
# Review requirements
min_approvals = 2
require_security_review_for = ["auth", "payment", "pii"]
require_architect_review_for = ["database", "api_contract"]

# Automated review
auto_assign_reviewers = true
notify_on_stale_pr_days = 3

[deployment]
# CI/CD strategy
default_strategy = "rolling"
environments = ["dev", "staging", "production"]
require_manual_approval_for = ["production"]

# Rollback configuration
auto_rollback_on_error_rate = 5.0  # percent
monitor_duration_minutes = 30

[agent_roles]
# Role 1: Senior Engineer
senior_review_priority = ["CRITICAL", "HIGH"]
senior_approval_required_for = ["production_deploy", "schema_migration"]

# Role 2: Dev Agent
dev_agent_automation = ["format", "lint", "test", "docs"]
dev_agent_commit_frequency_minutes = 30

# Role 3: CI/CD Orchestrator
orchestrator_cost_budget_per_build = 5.00
orchestrator_max_runtime_minutes = 60
orchestrator_compute_tier = "standard"
```

### Concrete Workflow Example

**Scenario**: Implementing user authentication feature for SaaS application

**Input**: User story US-456 "As a user, I want to log in with OAuth2 so I can access my account securely"

**Stage 1: Requirements Gathering**

```yaml
user_story:
  ticket_id: US-456
  title: OAuth2 Authentication
  priority: HIGH

  acceptance_criteria:
    - Users can log in with Google OAuth2
    - Users can log in with GitHub OAuth2
    - Session tokens expire after 24 hours
    - Failed login attempts are rate-limited

  api_contract:
    endpoint: POST /auth/login
    request_body:
      provider: ["google", "github"]
      redirect_uri: string
    response:
      access_token: string
      refresh_token: string
      expires_in: number

  security_requirements:
    - OWASP A01: Broken Access Control mitigation
    - PKCE flow for OAuth2
    - Secure token storage (httpOnly cookies)

  validation_result:
    gate: requirements_validation
    pass: true
    priority: MINIMAL
```

**Stage 2: Code Implementation**

```yaml
implementation:
  branch: feature/US-456-oauth2-authentication
  files_changed: 12
  lines_added: 450
  lines_deleted: 20

  static_analysis:
    lint_score: 9.2
    code_coverage: 87.5
    max_complexity: 7
    critical_vulnerabilities: 0

  validation_result:
    gate: static_analysis
    pass: true
    priority: LOW
```

**Stage 3: Testing**

```yaml
test_execution:
  unit_tests:
    total: 45
    passed: 45
    failed: 0
    coverage: 92.3

  integration_tests:
    total: 12
    passed: 12
    failed: 0
    scenarios:
      - Google OAuth2 login success
      - GitHub OAuth2 login success
      - Token refresh flow
      - Rate limiting enforcement

  validation_result:
    gate: integration_testing
    pass: true
    priority: LOW
```

**Stage 4: Code Review**

```yaml
code_review:
  reviewers:
    - senior_engineer_alice
    - security_specialist_bob

  review_comments:
    - file: src/auth/oauth2.ts
      line: 45
      comment: "Consider adding CSRF token validation"
      severity: medium
      resolved: true

    - file: src/auth/session.ts
      line: 78
      comment: "Token expiration should be configurable"
      severity: low
      resolved: true

  approvals:
    - reviewer: senior_engineer_alice
      status: approved
      timestamp: 2025-10-25T14:30:00Z

    - reviewer: security_specialist_bob
      status: approved
      timestamp: 2025-10-25T15:15:00Z

  validation_result:
    gate: code_review
    pass: true
    priority: MINIMAL
```

**Stage 5: Security Audit**

```yaml
security_audit:
  owasp_scan:
    high_severity: 0
    medium_severity: 1  # CORS configuration warning
    low_severity: 2

  dependency_scan:
    critical_vulnerabilities: 0
    total_dependencies: 87
    outdated: 3  # Non-security updates

  secret_scan:
    secrets_found: 0
    files_scanned: 156

  penetration_testing:
    brute_force_resistant: true
    session_hijacking_protected: true
    csrf_protected: true

  validation_result:
    gate: security_audit
    pass: true
    priority: LOW
    action: "Address medium-severity CORS warning before production"
```

**Stage 6: Production Deployment**

```yaml
deployment:
  strategy: canary
  rollout_plan:
    - percentage: 5
      duration_minutes: 30
      validation: smoke_tests
      status: success

    - percentage: 25
      duration_minutes: 60
      validation: integration_tests
      status: success

    - percentage: 100
      duration_minutes: 120
      validation: full_suite
      status: success

  monitoring:
    error_rate: 0.02  # 0.02% (within threshold)
    latency_p99_ms: 45  # Acceptable
    login_success_rate: 99.8

  provenance:
    git_commit: def456abc
    pipeline_version: 3.2.1
    build_id: BUILD-20251026-001
    deployed_by: ci_cd_orchestrator
    approval_by: senior_engineer_alice
    deployment_date: 2025-10-26T18:00:00Z
```

---

## Domain 3: Clinical Trials

### Domain Overview

**Context**: Patient data collection and validation for clinical research studies

**Data Pipeline**: Patient enrollment → Informed consent → Data collection → Quality validation → Safety monitoring → Regulatory submission

**Similar Complexity**: Multi-stage validation, strict regulatory compliance (FDA, HIPAA), high stakes for errors

### Stage Mapping from Herbarium

| Herbarium Stage | Clinical Trials Equivalent | Mapping Rationale |
|-----------------|----------------------------|-------------------|
| **Image Acquisition** | Patient Enrollment & Consent | Collecting source data with strict protocols |
| **OCR Execution** | Electronic Data Capture (EDC) | Automated data entry with validation |
| **Field Extraction** | Case Report Form (CRF) Completion | Structured data fields with controlled vocabularies |
| **Quality Control** | Data Validation & Query Resolution | Completeness, consistency, range checks |
| **Human Review** | Medical Monitor Review & Source Verification | Expert clinical validation |
| **Publication** | Regulatory Submission (FDA, EMA) | Standardized CDISC/SDTM format |

### Agent Roles Adaptation

#### Role 1: Medical Monitor (Domain Expert)

**Herbarium Equivalent**: Human Curator

**Responsibilities**:

- Review adverse event reports
- Validate clinical endpoint assessments
- Adjudicate protocol deviations
- Approve safety data submissions
- Ensure regulatory compliance

**Automation Boundary**: Tier 3 (requires approval)

- Serious Adverse Event (SAE) reporting
- Protocol amendment decisions
- Regulatory communication
- Data Safety Monitoring Board (DSMB) presentations

#### Role 2: Data Management Agent (Technical Implementation)

**Herbarium Equivalent**: Code Agent

**Responsibilities**:

- Execute validation rules on EDC data
- Generate data clarification forms (DCFs)
- Run database lock procedures
- Track query resolution status
- Maintain audit trails

**Automation Boundary**: Tier 1 (fully automated)

- Data validation rule execution
- Automatic query generation
- Database exports (SDTM, ADaM)
- Audit trail logging

**Pre-Lock Checks**:

```bash
# Clinical database lock validation
validate_all_queries_resolved && \
check_protocol_deviations_documented && \
verify_sae_reporting_complete && \
test_sdtm_export_valid
```

#### Role 3: Study Coordinator Agent (Orchestration)

**Herbarium Equivalent**: Pipeline Composer Agent

**Responsibilities**:

- Allocate data review resources
- Prioritize query resolution by urgency
- Route safety signals to medical monitor
- Optimize cost vs timeline tradeoffs
- Schedule monitoring visits

**Decision Logic**:

```python
def compose_monitoring_plan(study_phase: str, site_risk: str, budget: float):
    if study_phase == "phase_1" and site_risk == "high":
        return {
            "monitoring_frequency": "100_percent_sdv",  # Source Data Verification
            "on_site_visits": "monthly",
            "remote_monitoring": "weekly",
            "cost_per_patient": 5000.00
        }

    if study_phase == "phase_3" and budget < 2000:
        return {
            "monitoring_frequency": "risk_based",
            "on_site_visits": "quarterly",
            "remote_monitoring": "bi_weekly",
            "centralized_monitoring": "daily",
            "cost_per_patient": 1500.00
        }

    # Standard Phase 2 monitoring
    return {
        "monitoring_frequency": "targeted_sdv",
        "on_site_visits": "quarterly",
        "remote_monitoring": "weekly",
        "cost_per_patient": 2500.00
    }
```

### Quality Gates Adaptation

#### Gate 1: Informed Consent Validation (Pre-Enrollment)

**Herbarium Equivalent**: Dependency Check

**Validation**:

- Consent form signed and dated
- Patient age ≥ 18 years (or legal guardian signature)
- All required sections initialed
- Consent version matches current IRB-approved version

**Action on Failure**: Block enrollment, patient ineligible

```python
def validate_informed_consent(consent_form: dict) -> dict:
    issues = []

    if not consent_form.get("signature_date"):
        issues.append("Missing signature date")

    if consent_form.get("patient_age") < 18 and not consent_form.get("guardian_signature"):
        issues.append("Minor without legal guardian consent")

    if consent_form.get("version") != get_current_irb_version():
        issues.append("Outdated consent form version")

    required_sections = ["study_procedures", "risks", "benefits", "privacy"]
    for section in required_sections:
        if not consent_form.get(f"{section}_initialed"):
            issues.append(f"Missing initial on {section}")

    return {
        "pass": len(issues) == 0,
        "priority": "CRITICAL" if issues else "MINIMAL",
        "issues": issues
    }
```

#### Gate 2: EDC Data Validation (Post-Entry)

**Herbarium Equivalent**: Confidence Threshold

**Validation**:

- Range checks (e.g., blood pressure 60-250 mmHg)
- Logical consistency (end date ≥ start date)
- Required fields completed
- Medical coding consistent (MedDRA, WHO Drug)

**Action on Failure**: Generate Data Clarification Form (DCF)

```python
def validate_edc_entry(case_report_form: dict) -> dict:
    issues = []

    # Range validation
    if "systolic_bp" in case_report_form:
        sbp = case_report_form["systolic_bp"]
        if not (60 <= sbp <= 250):
            issues.append(f"Systolic BP out of range: {sbp}")

    # Logical consistency
    if "adverse_event_start" in case_report_form and "adverse_event_end" in case_report_form:
        if case_report_form["adverse_event_end"] < case_report_form["adverse_event_start"]:
            issues.append("AE end date before start date")

    # Required fields
    required = ["visit_date", "investigator_signature", "patient_initials"]
    for field in required:
        if not case_report_form.get(field):
            issues.append(f"Missing required field: {field}")

    # Medical coding consistency
    if "adverse_event" in case_report_form:
        meddra_code = case_report_form.get("meddra_code")
        if not validate_meddra_code(meddra_code):
            issues.append(f"Invalid MedDRA code: {meddra_code}")

    return {
        "pass": len(issues) == 0,
        "priority": "HIGH" if any("required field" in i for i in issues) else "MEDIUM",
        "issues": issues,
        "dcf_required": len(issues) > 0
    }
```

#### Gate 3: Safety Signal Detection (Continuous)

**Herbarium Equivalent**: Completeness Check

**Validation**:

- SAE reported within 24 hours
- Death/hospitalization flagged immediately
- Suspected Unexpected Serious Adverse Reaction (SUSAR) identified
- Aggregate safety threshold not exceeded

**Action on Failure**: Escalate to medical monitor, notify sponsor

```python
def validate_safety_signals(patient_data: dict) -> dict:
    issues = []
    priority = "LOW"

    # SAE reporting timeline
    if "serious_adverse_event" in patient_data:
        sae_date = patient_data["sae_date"]
        report_date = patient_data["sae_report_date"]

        if (report_date - sae_date).total_seconds() > 86400:  # 24 hours
            issues.append("SAE reported >24 hours after occurrence")
            priority = "CRITICAL"

    # Death/hospitalization immediate flag
    if patient_data.get("outcome") in ["death", "hospitalization"]:
        if not patient_data.get("immediate_notification_sent"):
            issues.append("Death/hospitalization not immediately reported")
            priority = "CRITICAL"

    # SUSAR detection (unexpected + serious + suspected causality)
    if (patient_data.get("serious") and
        patient_data.get("causality") in ["probable", "definite"] and
        not is_listed_in_brochure(patient_data.get("adverse_event"))):
        issues.append("Suspected SUSAR - requires expedited reporting")
        priority = "CRITICAL"

    return {
        "pass": len(issues) == 0,
        "priority": priority,
        "issues": issues,
        "requires_immediate_action": priority == "CRITICAL"
    }
```

#### Gate 4: Regulatory Compliance Audit (Pre-Submission)

**Herbarium Equivalent**: GBIF Validation

**Validation**:

- CDISC SDTM format compliance
- 21 CFR Part 11 audit trail complete
- Protocol deviations documented
- Informed consent on file for all patients

**Action on Failure**: Block regulatory submission, remediate findings

```python
def validate_regulatory_compliance(study_database: dict) -> dict:
    issues = []

    # CDISC SDTM validation
    sdtm_validation = validate_cdisc_sdtm(study_database["export"])
    if not sdtm_validation["conformant"]:
        issues.extend(sdtm_validation["errors"])

    # 21 CFR Part 11 audit trail
    audit_trail = study_database["audit_log"]
    if not verify_audit_trail_integrity(audit_trail):
        issues.append("Audit trail integrity check failed")

    # Protocol deviations
    for deviation in study_database["protocol_deviations"]:
        if not deviation.get("documented"):
            issues.append(f"Undocumented protocol deviation: {deviation['id']}")

    # Informed consent completeness
    enrolled_patients = len(study_database["patients"])
    consents_on_file = len(study_database["informed_consents"])
    if enrolled_patients != consents_on_file:
        issues.append(f"Consent mismatch: {enrolled_patients} patients, {consents_on_file} consents")

    return {
        "pass": len(issues) == 0,
        "priority": "CRITICAL" if issues else "MINIMAL",
        "issues": issues,
        "submission_ready": len(issues) == 0
    }
```

### Validation Rules Adaptation

#### Category 1: Patient Eligibility Criteria

**Herbarium Equivalent**: Field Format Validation

```python
# Inclusion/exclusion criteria validation
def validate_eligibility(patient: dict, protocol: dict) -> dict:
    issues = []

    # Age criteria
    if not (protocol["min_age"] <= patient["age"] <= protocol["max_age"]):
        issues.append(f"Age out of range: {patient['age']}")

    # Lab values
    for lab_test in protocol["required_lab_values"]:
        if lab_test["name"] not in patient["labs"]:
            issues.append(f"Missing required lab: {lab_test['name']}")
        else:
            value = patient["labs"][lab_test["name"]]
            if not (lab_test["min"] <= value <= lab_test["max"]):
                issues.append(f"{lab_test['name']} out of range: {value}")

    # Exclusion criteria
    for exclusion in protocol["exclusion_criteria"]:
        if patient.get(exclusion["field"]) == exclusion["value"]:
            issues.append(f"Exclusion criterion met: {exclusion['description']}")

    return {
        "eligible": len(issues) == 0,
        "issues": issues
    }
```

#### Category 2: Controlled Medical Terminology

**Herbarium Equivalent**: Controlled Vocabulary

```toml
[medical_terminology]
# MedDRA for adverse events
adverse_event_dictionary = "MedDRA_v26.0"
preferred_term_level = "PT"

# WHO Drug Dictionary for medications
medication_dictionary = "WHO_Drug_Global_2025_1"

# LOINC for lab tests
lab_test_dictionary = "LOINC_v2.76"

# SNOMED CT for diagnoses
diagnosis_dictionary = "SNOMED_CT_US_2025_03_01"
```

#### Category 3: Cross-Visit Consistency

**Herbarium Equivalent**: Cross-Field Consistency

```python
def validate_cross_visit_consistency(patient_visits: list[dict]) -> list[str]:
    issues = []

    # Baseline vs follow-up consistency
    baseline = patient_visits[0]
    for visit in patient_visits[1:]:
        # Weight change validation (>10 kg change unusual)
        if abs(visit["weight_kg"] - baseline["weight_kg"]) > 10:
            issues.append(f"Visit {visit['number']}: Large weight change from baseline")

        # Concomitant medication consistency
        baseline_meds = set(baseline["concomitant_medications"])
        current_meds = set(visit["concomitant_medications"])

        new_meds = current_meds - baseline_meds
        for med in new_meds:
            if not visit.get(f"{med}_start_date"):
                issues.append(f"Visit {visit['number']}: New medication without start date")

    # Visit window compliance
    protocol_days = [0, 7, 14, 28, 56, 84]  # Protocol-defined visit days
    for i, visit in enumerate(patient_visits):
        actual_day = (visit["visit_date"] - patient_visits[0]["visit_date"]).days
        expected_day = protocol_days[i]

        if abs(actual_day - expected_day) > 3:  # ±3 day window
            issues.append(f"Visit {visit['number']}: Out of protocol window ({actual_day} vs {expected_day} days)")

    return issues
```

#### Category 4: Safety Monitoring Thresholds

**Herbarium Equivalent**: Taxonomic Validation (external database checks)

```python
def validate_safety_thresholds(study_data: dict) -> dict:
    # Aggregate safety analysis
    total_patients = len(study_data["patients"])

    # AE incidence thresholds
    ae_counts = {}
    for patient in study_data["patients"]:
        for ae in patient.get("adverse_events", []):
            ae_term = ae["preferred_term"]
            ae_counts[ae_term] = ae_counts.get(ae_term, 0) + 1

    safety_signals = []
    for ae_term, count in ae_counts.items():
        incidence = count / total_patients

        # Compare to investigator brochure expected rate
        expected_rate = get_expected_ae_rate(ae_term)

        if incidence > expected_rate * 1.5:  # 50% higher than expected
            safety_signals.append({
                "ae_term": ae_term,
                "observed_incidence": incidence,
                "expected_incidence": expected_rate,
                "requires_dsmb_review": True
            })

    return {
        "safety_signals": safety_signals,
        "dsmb_notification_required": len(safety_signals) > 0
    }
```

#### Category 5: Source Data Verification

**Herbarium Equivalent**: Duplicate Detection

```python
def perform_source_data_verification(edc_data: dict, source_documents: dict) -> dict:
    discrepancies = []

    # Compare EDC data to hospital medical records
    for patient_id in edc_data.keys():
        edc_record = edc_data[patient_id]
        source_record = source_documents.get(patient_id)

        if not source_record:
            discrepancies.append({
                "patient_id": patient_id,
                "issue": "No source documents on file",
                "severity": "CRITICAL"
            })
            continue

        # Key data point verification
        critical_fields = ["date_of_birth", "adverse_events", "lab_values", "informed_consent_date"]

        for field in critical_fields:
            if edc_record.get(field) != source_record.get(field):
                discrepancies.append({
                    "patient_id": patient_id,
                    "field": field,
                    "edc_value": edc_record.get(field),
                    "source_value": source_record.get(field),
                    "severity": "HIGH"
                })

    return {
        "total_discrepancies": len(discrepancies),
        "critical_discrepancies": len([d for d in discrepancies if d["severity"] == "CRITICAL"]),
        "discrepancies": discrepancies,
        "sdv_pass": len([d for d in discrepancies if d["severity"] == "CRITICAL"]) == 0
    }
```

### Configuration Example: Clinical Trial Data Management

```toml
# config/clinical_trial.toml

[study]
protocol_number = "ABC-123-2025"
phase = "phase_2"
indication = "Type 2 Diabetes"
primary_endpoint = "HbA1c reduction from baseline"

[enrollment]
target_enrollment = 150
min_age = 18
max_age = 75
consent_version = "v3.2_IRB_approved_2025-06-15"

[data_collection]
# Electronic Data Capture system
edc_system = "Medidata Rave"
visit_schedule_days = [0, 7, 14, 28, 56, 84]
visit_window_days = 3  # ±3 days acceptable

[quality_gates]
# Gate 1: Informed consent validation
require_signed_consent = true
require_version_match = true
require_all_sections_initialed = true

# Gate 2: EDC data validation
required_fields = ["visit_date", "investigator_signature", "patient_initials"]
range_checks_enabled = true
logical_consistency_checks = true

# Gate 3: Safety signal detection
sae_reporting_deadline_hours = 24
susar_expedited_reporting = true
aggregate_safety_monitoring = "continuous"

# Gate 4: Regulatory compliance
cdisc_sdtm_validation = true
cfr_part_11_compliance = true
protocol_deviation_documentation = "required"

[validation_rules]
# Patient eligibility
[validation_rules.eligibility]
hba1c_min = 7.0
hba1c_max = 11.0
egfr_min = 60  # mL/min (kidney function)

# Lab value ranges
[validation_rules.lab_ranges]
glucose_fasting_min = 70
glucose_fasting_max = 400  # mg/dL
systolic_bp_min = 60
systolic_bp_max = 250  # mmHg
diastolic_bp_min = 40
diastolic_bp_max = 150  # mmHg

# Safety thresholds
[validation_rules.safety]
hypoglycemia_glucose_threshold = 70  # mg/dL
sae_incidence_alert_threshold = 0.05  # 5% of patients

[medical_terminology]
adverse_events = "MedDRA_v26.0"
medications = "WHO_Drug_Global_2025_1"
lab_tests = "LOINC_v2.76"
diagnoses = "SNOMED_CT_US_2025_03_01"

[monitoring]
# Source Data Verification strategy
sdv_percentage = 100  # 100% SDV for Phase 2
on_site_monitoring_frequency = "quarterly"
remote_monitoring_frequency = "bi_weekly"
centralized_monitoring = "daily"

[agent_roles]
# Role 1: Medical Monitor
medical_monitor_review_priority = ["CRITICAL", "HIGH"]
medical_monitor_approval_required = ["sae", "susar", "protocol_deviation"]

# Role 2: Data Management Agent
data_mgmt_automation = ["validation", "query_generation", "exports"]
data_mgmt_commit_frequency_hours = 4  # Log every 4 hours

# Role 3: Study Coordinator
coordinator_cost_budget_per_patient = 2500.00
coordinator_monitoring_optimization = "risk_based"
```

### Concrete Workflow Example

**Scenario**: Phase 2 clinical trial for Type 2 Diabetes medication

**Input**: Patient PT-045 enrolled at investigative site

**Stage 1: Patient Enrollment & Consent**

```yaml
patient_enrollment:
  patient_id: PT-045
  site_id: SITE-007
  enrollment_date: 2025-10-15

  informed_consent:
    form_version: v3.2_IRB_approved_2025-06-15
    signature_date: 2025-10-15
    patient_age: 52
    guardian_signature: null  # Not applicable (adult)
    sections_initialed:
      - study_procedures
      - risks
      - benefits
      - privacy
      - genetic_testing  # Optional substudy

  eligibility_screening:
    hba1c: 8.5  # %
    egfr: 75  # mL/min
    age: 52
    exclusions_met: []

  validation_result:
    gate: informed_consent_validation
    pass: true
    priority: MINIMAL
    enrolled: true
```

**Stage 2: Baseline Visit (Visit 1, Day 0)**

```yaml
baseline_visit:
  visit_number: 1
  visit_date: 2025-10-20
  protocol_day: 0

  case_report_form:
    demographics:
      sex: male
      race: caucasian
      ethnicity: non_hispanic
      weight_kg: 92.5
      height_cm: 178

    vital_signs:
      systolic_bp: 132
      diastolic_bp: 84
      heart_rate: 72
      temperature_c: 36.8

    lab_values:
      hba1c: 8.5
      glucose_fasting: 145  # mg/dL
      egfr: 75
      alt: 28  # Liver function
      ast: 32

    concomitant_medications:
      - metformin_1000mg_bid
      - lisinopril_10mg_qd

    investigator_signature: Dr. Sarah Johnson
    signature_date: 2025-10-20

  validation_result:
    gate: edc_validation
    pass: true
    priority: LOW
    dcf_required: false
```

**Stage 3: Follow-Up Visit with Adverse Event (Visit 3, Day 28)**

```yaml
followup_visit:
  visit_number: 3
  visit_date: 2025-11-17
  protocol_day: 28
  actual_day: 28  # Within ±3 day window

  case_report_form:
    vital_signs:
      systolic_bp: 128
      diastolic_bp: 80
      heart_rate: 68
      weight_kg: 90.2  # 2.3 kg decrease (expected for diabetes drug)

    lab_values:
      hba1c: 7.8  # Improvement from 8.5
      glucose_fasting: 118  # Improvement
      egfr: 76  # Stable

    adverse_events:
      - event_term: Nausea
        meddra_code: 10028813  # PT: Nausea
        severity: mild
        start_date: 2025-11-10
        end_date: 2025-11-14
        outcome: resolved
        causality: probable  # Related to study drug
        serious: false
        action_taken: none

  validation_result:
    gate: edc_validation
    pass: true
    priority: LOW

  safety_validation:
    gate: safety_signal_detection
    pass: true
    priority: LOW
    sae_reporting_required: false
    susar_detected: false
```

**Stage 4: Serious Adverse Event (Between Visits)**

```yaml
serious_adverse_event:
  patient_id: PT-045
  event_date: 2025-12-05

  sae_details:
    event_term: Hypoglycemia
    meddra_code: 10020993  # PT: Hypoglycemia
    severity: severe
    outcome: recovered
    hospitalization_required: true
    admission_date: 2025-12-05
    discharge_date: 2025-12-06

    causality: definite  # Clearly related to study drug
    expectedness: expected  # Listed in investigator brochure

    description: "Patient experienced severe hypoglycemia (glucose 45 mg/dL) requiring hospitalization. Treated with IV dextrose, discharged after 24h observation."

  reporting:
    initial_report_date: 2025-12-05  # Same day
    report_to_sponsor: 2025-12-05_10:30  # Within 24 hours
    report_to_irb: 2025-12-06
    report_to_fda: null  # Not required (expected AE)

  validation_result:
    gate: safety_signal_detection
    pass: false  # SAE requires action
    priority: CRITICAL
    requires_immediate_action: true
    medical_monitor_notified: true

  medical_monitor_review:
    reviewer: Dr. Michael Chen
    review_date: 2025-12-05
    assessment: "Expected AE, consistent with known drug profile. No action required beyond standard AE management. Patient counseled on hypoglycemia symptoms."
    continue_study_participation: true
```

**Stage 5: Database Lock & Regulatory Submission**

```yaml
database_lock:
  lock_date: 2026-03-01
  total_patients_enrolled: 150
  total_patients_completed: 142

  data_quality:
    total_queries_opened: 458
    total_queries_resolved: 458
    total_protocol_deviations: 23
    protocol_deviations_documented: 23

  safety_summary:
    total_adverse_events: 312
    serious_adverse_events: 8
    deaths: 0
    discontinuations_due_to_ae: 4

    most_common_aes:
      - term: Nausea
        incidence: 0.32  # 32%
        expected: true
      - term: Hypoglycemia
        incidence: 0.15  # 15%
        expected: true
      - term: Headache
        incidence: 0.12  # 12%
        expected: true

  efficacy_summary:
    primary_endpoint_met: true
    hba1c_reduction_mean: -1.2  # % points
    hba1c_reduction_p_value: 0.0003  # Highly significant

  regulatory_compliance_audit:
    cdisc_sdtm_conformant: true
    cfr_part_11_compliant: true
    informed_consents_complete: 150/150
    protocol_deviations_documented: 23/23
    source_data_verification_complete: 100%

  validation_result:
    gate: regulatory_compliance
    pass: true
    priority: MINIMAL
    submission_ready: true

  submission:
    submission_type: FDA_IND_annual_report
    submission_date: 2026-03-15
    submission_format: eCTD

    provenance:
      database_version: 2.1.0
      lock_id: LOCK-20260301-001
      locked_by: data_mgmt_agent
      approved_by: medical_monitor_dr_chen
      regulatory_contact: Jane Smith, Regulatory Affairs
```

---

## Cross-Domain Pattern Library

### Pattern 1: Progressive Quality Filtering

**Herbarium**: CRITICAL → HIGH → MEDIUM → LOW → MINIMAL priority queue

**Genomics**: Sample QC → Sequencing QC → Alignment QC → Variant QC (cascading filters)

**Software**: Requirements → Static Analysis → Integration Tests → Security Audit

**Clinical Trials**: Consent → EDC Validation → Safety Monitoring → Regulatory Compliance

**Transferable Principle**: **Filter early, filter often** - catch issues at each stage before expensive downstream processing

### Pattern 2: Confidence-Weighted Aggregation

**Herbarium**: Multi-extraction runs aggregated by field confidence scores

**Genomics**: Multi-caller variant ensemble voting (GATK + FreeBayes + Strelka)

**Software**: Multi-tool static analysis consensus (ESLint + SonarQube + CodeClimate)

**Clinical Trials**: Multi-monitor adverse event adjudication (independent reviewers)

**Transferable Principle**: **Ensemble methods reduce error** - combine multiple independent assessments weighted by confidence

### Pattern 3: Content-Addressed Provenance

**Herbarium**: (image_sha256, extraction_params) → deduplication key

**Genomics**: (fastq_md5, pipeline_version) → reproducible analysis key

**Software**: (commit_sha, build_config) → reproducible build key

**Clinical Trials**: (patient_id, visit_date, form_version) → audit trail key

**Transferable Principle**: **Cryptographic hashing ensures reproducibility** - content addressing prevents silent data corruption

### Pattern 4: Cost-Aware Routing

**Herbarium**: Apple Vision ($0) → GPT-4o-mini ($3.70/1000) → GPT-4 Vision ($50/1000)

**Genomics**: Low coverage ($400) → Standard coverage ($800) → Deep coverage ($2500)

**Software**: Economy CI runners ($0.008/min) → Standard ($0.016/min) → Premium GPU ($0.50/min)

**Clinical Trials**: Centralized monitoring ($1500/patient) → Targeted SDV ($2500) → 100% SDV ($5000)

**Transferable Principle**: **Budget constraints drive tiered strategies** - allocate expensive resources only where quality demands it

### Pattern 5: Human-in-the-Loop Escalation

**Herbarium**: Automated validation → Flag for expert → Manual curator review

**Genomics**: Automated variant calling → Flag high-impact variants → Clinical geneticist interpretation

**Software**: Automated linting → Flag complex functions → Senior engineer review

**Clinical Trials**: Automated safety monitoring → Flag SUSARs → Medical monitor adjudication

**Transferable Principle**: **Reserve expert time for high-value decisions** - automate routine validation, escalate edge cases

---

## Configuration Examples

### Universal Configuration Template

```toml
# config/universal_workflow.toml
# Adaptable to any domain (herbarium, genomics, software, clinical)

[workflow]
domain = "herbarium"  # Options: "herbarium", "genomics", "software", "clinical"
workflow_version = "2.0.0"

[stages]
# Define workflow stages (domain-specific)
stage_1 = "acquisition"
stage_2 = "processing"
stage_3 = "extraction"
stage_4 = "validation"
stage_5 = "review"
stage_6 = "publication"

[quality_gates]
# Gate configuration (applies to all domains)
[quality_gates.gate_1]
name = "input_validation"
required = true
blocking = true
automation_tier = 1

[quality_gates.gate_2]
name = "processing_qc"
required = true
blocking = true
automation_tier = 1

[quality_gates.gate_3]
name = "completeness_check"
required = true
blocking = false  # Allows progression with warnings
automation_tier = 2

[quality_gates.gate_4]
name = "expert_validation"
required = false  # Optional for low-priority items
blocking = true
automation_tier = 3

[agent_roles]
# Role 1: Domain Expert (Human)
[agent_roles.expert]
authority = "domain_validation"
automation_boundary = "tier_3"
review_priority = ["CRITICAL", "HIGH"]
approval_required_for = ["production", "publication", "regulatory"]

# Role 2: Technical Agent (AI/Automation)
[agent_roles.technical]
authority = "implementation"
automation_boundary = "tier_1"
commit_frequency_minutes = 30
pre_execution_checks = true

# Role 3: Orchestrator Agent (Resource Management)
[agent_roles.orchestrator]
authority = "resource_allocation"
cost_optimization = true
quality_tradeoff_strategy = "pareto_optimal"

[validation_rules]
# Rule categories (customize per domain)
[validation_rules.format]
enabled = true
blocking_severity = "error"

[validation_rules.controlled_vocabulary]
enabled = true
blocking_severity = "warning"

[validation_rules.cross_field_consistency]
enabled = true
blocking_severity = "error"

[validation_rules.external_database]
enabled = true  # GBIF, ClinVar, npm registry, etc.
blocking_severity = "warning"

[validation_rules.duplicate_detection]
enabled = true
blocking_severity = "warning"

[priority_calculation]
# Priority formula (customize weights per domain)
quality_weight = 0.6
completeness_weight = 0.4
confidence_weight = 0.3
urgency_weight = 0.1

# Priority thresholds
critical_threshold = 30.0
high_threshold = 50.0
medium_threshold = 75.0
low_threshold = 90.0

[provenance]
# Scientific provenance tracking
track_git_commit = true
track_processing_metadata = true
track_agent_identity = true
track_human_operator = true
export_format = "json"

[export]
# Publication/deployment configuration
enable_versioning = true
include_checksums = true
include_audit_trail = true
retention_days = 365
```

### Domain-Specific Overrides

#### Herbarium Domain Override

```toml
# config/herbarium_override.toml
[workflow]
domain = "herbarium"

[stages]
stage_1 = "image_acquisition"
stage_2 = "ocr_execution"
stage_3 = "field_extraction"
stage_4 = "quality_control"
stage_5 = "human_review"
stage_6 = "darwin_core_export"

[validation_rules.external_database]
database = "gbif"
api_endpoint = "https://api.gbif.org/v1/species/match"

[export]
format = "darwin_core_archive"
standard = "GBIF"
```

#### Genomics Domain Override

```toml
# config/genomics_override.toml
[workflow]
domain = "genomics"

[stages]
stage_1 = "sample_collection"
stage_2 = "sequencing"
stage_3 = "alignment"
stage_4 = "variant_calling"
stage_5 = "clinical_interpretation"
stage_6 = "ncbi_submission"

[validation_rules.external_database]
database = "clinvar"
api_endpoint = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"

[export]
format = "vcf"
standard = "CDISC_SDTM"
```

#### Software Development Domain Override

```toml
# config/software_override.toml
[workflow]
domain = "software"

[stages]
stage_1 = "requirements"
stage_2 = "implementation"
stage_3 = "testing"
stage_4 = "code_review"
stage_5 = "security_audit"
stage_6 = "deployment"

[validation_rules.external_database]
database = "npm_registry"
api_endpoint = "https://registry.npmjs.org/"

[export]
format = "docker_image"
standard = "OCI"
```

#### Clinical Trials Domain Override

```toml
# config/clinical_override.toml
[workflow]
domain = "clinical_trials"

[stages]
stage_1 = "enrollment"
stage_2 = "edc_entry"
stage_3 = "validation"
stage_4 = "safety_monitoring"
stage_5 = "medical_review"
stage_6 = "regulatory_submission"

[validation_rules.external_database]
database = "meddra"
version = "26.0"

[export]
format = "cdisc_sdtm"
standard = "FDA_eCTD"
```

---

## Summary: Key Transferable Insights

### What Transfers Universally

1. **Multi-Stage Quality Gates**: Every domain benefits from progressive filtering
2. **Confidence-Weighted Aggregation**: Ensemble methods reduce errors across domains
3. **Content-Addressed Provenance**: Reproducibility requires cryptographic integrity
4. **Cost-Aware Routing**: Budget constraints demand tiered processing strategies
5. **Human-in-the-Loop Escalation**: Expert time is precious - automate routine, escalate edge cases

### What Requires Domain Customization

1. **Field Definitions**: Darwin Core vs CDISC SDTM vs API schemas vs lab values
2. **Controlled Vocabularies**: MedDRA vs scientific names vs function naming conventions
3. **External Validation**: GBIF vs ClinVar vs npm registry vs none
4. **Regulatory Requirements**: GBIF compliance vs FDA 21 CFR Part 11 vs SOC2 vs none
5. **Review Expertise**: Taxonomist vs clinical geneticist vs senior engineer vs medical monitor

### Configuration Strategy

- **Start with universal template** (`config/universal_workflow.toml`)
- **Apply domain override** (add domain-specific stages, validators, export formats)
- **Customize quality gates** (adjust thresholds, priorities, escalation rules)
- **Configure agent roles** (define authority boundaries, automation tiers)
- **Test incrementally** (validate each stage before proceeding)

### Implementation Roadmap

1. **Week 1**: Implement universal configuration parser
2. **Week 2**: Build domain-specific validators (one domain as proof-of-concept)
3. **Week 3**: Test quality gates and priority calculation
4. **Week 4**: Deploy agent orchestration layer
5. **Week 5**: Validate provenance tracking and export formats
6. **Week 6**: Documentation and cookbook publication

---

## References

**Primary Source System**:

- `/Users/devvynmurphy/Documents/GitHub/aafc-herbarium-dwc-extraction-2025/`

**Key Documentation**:

- `README.md` - System overview, workflow description
- `docs/architecture/ARCHITECTURE.md` - Dual-layer architecture philosophy
- `docs/review_workflow.md` - Human review interface and quality metrics
- `agents/README.md` - Agent orchestration framework
- `config/config.default.toml` - Full configuration schema
- `config/rules/dwc_rules.toml` - Field validation rules

**Pattern Library**:

- `/Users/devvynmurphy/devvyn-meta-project/knowledge-base/patterns/scientific-provenance-pattern.md`
- `/Users/devvynmurphy/devvyn-meta-project/knowledge-base/patterns/work-session-accountability.md`
- `/Users/devvynmurphy/devvyn-meta-project/knowledge-base/patterns/aafc-infrastructure-contribution-asset.md`

---

**Research Completed**: 2025-10-30 15:55 MST
**Researcher**: Claude Code Agent
**Next Step**: Use these notes to write the Domain Transfer Cookbook
