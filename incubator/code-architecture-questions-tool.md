# Code Architecture Questions Tool (CAQT)

**Status**: Incubator - Raw Concept
**Category**: Developer Tools, Code Understanding, Educational Frameworks
**Created**: 2025-11-09
**Session**: claude/code-architecture-questions-tool-011CUwYqbMq8n75WUTP187qp

---

## Market Gap Identified

**Observation**: No specialized tools exist for automatically generating architectural/design questions from code, despite extensive frameworks for educational assessment, code analysis, and documentation generation.

**Gap Details**:
- ✅ **Exists**: Static analyzers (linters, type checkers, security scanners)
- ✅ **Exists**: Documentation generators (JSDoc, Sphinx, Doxygen)
- ✅ **Exists**: Educational question banks (LeetCode, CodeSignal, interview prep)
- ✅ **Exists**: Code review tools (GitHub, GitLab, Review Board)
- ❌ **Missing**: Automatic generation of architectural understanding questions from codebases
- ❌ **Missing**: Design decision interrogation frameworks
- ❌ **Missing**: Implicit assumption surfacing tools
- ❌ **Missing**: Question-driven code exploration aids

---

## Core Concept

A tool that **analyzes source code and automatically generates thoughtful questions** about:

1. **Architectural Decisions**: "Why is X implemented as a singleton?"
2. **Design Patterns**: "What pattern is being used here, and why?"
3. **Coupling & Dependencies**: "Why does module A depend on module B?"
4. **Implicit Assumptions**: "What happens if this array is empty?"
5. **Trade-offs**: "What's the space/time complexity trade-off here?"
6. **Alternative Approaches**: "Could this be implemented differently?"
7. **Context Requirements**: "What external systems does this assume exist?"

**Philosophy**: Questions reveal understanding gaps better than documentation ever could.

---

## Use Cases

### 1. Code Review Enhancement
**Before**: Reviewer manually identifies concerns
**After**: Tool generates 20 architectural questions, reviewer selects most relevant

### 2. Onboarding Acceleration
**Before**: New developer spends weeks understanding codebase
**After**: Structured question set guides exploration of critical design decisions

### 3. Documentation Generation
**Before**: "Write the docs" → blank page syndrome
**After**: Answer these 15 questions about your module → documentation emerges

### 4. Educational Assessment
**Before**: Generic programming questions disconnected from real code
**After**: Context-specific questions from actual production systems

### 5. Technical Debt Identification
**Before**: Implicit technical debt buried in code
**After**: "Why does this need a 500ms sleep?" surfaces problems

### 6. Design Decision Recording
**Before**: Architecture decisions lost to time
**After**: Questions capture decision rationale through Socratic dialogue

---

## Relationship to Existing Frameworks

### Code Analysis (Different Domain)
- **Static Analysis**: Detects bugs, security issues, type errors
- **CAQT**: Generates understanding questions, not error reports
- **Intersection**: Both parse AST, but different output goals

### Educational Frameworks (Different Input)
- **Bloom's Taxonomy**: Levels of cognitive understanding (remember → create)
- **CAQT**: Applied to real codebases, not generic problems
- **Intersection**: Question classification by cognitive level

### Documentation Tools (Inverse Process)
- **Doxygen/JSDoc**: Code → Documentation (declarative)
- **CAQT**: Code → Questions → Answers → Documentation (interrogative)
- **Synergy**: Questions can seed better documentation

---

## Technical Approach

### Input: Source Code
```python
# Example: Code to analyze
class CachingStrategy:
    def __init__(self, max_size=100, ttl=3600):
        self._cache = {}
        self._max_size = max_size
        self._ttl = ttl

    def get(self, key):
        if key in self._cache:
            entry = self._cache[key]
            if time.time() - entry['timestamp'] < self._ttl:
                return entry['value']
            else:
                del self._cache[key]
        return None
```

### Output: Generated Questions
```markdown
## Architectural Questions for CachingStrategy

### Design Pattern Recognition
1. What caching eviction strategy is being used? (Answer: TTL-based)
2. Why TTL instead of LRU/LFU? (Trade-off question)
3. Is this thread-safe? Why/why not? (Implicit assumption)

### Boundary Conditions
4. What happens when cache exceeds max_size? (Missing implementation)
5. What happens if ttl=0? (Edge case)
6. Can ttl be updated after initialization? (API design)

### Dependency Analysis
7. Why does this depend on `time.time()`? (Coupling)
8. Could this be tested without mocking time? (Testability)
9. What happens in distributed systems with clock skew? (Context assumption)

### Performance & Trade-offs
10. Why dictionary instead of OrderedDict? (Data structure choice)
11. What's the space complexity? (Big-O analysis)
12. At what cache size does memory become a concern? (Scaling)

### Alternative Approaches
13. Why not use functools.lru_cache? (Reinvention question)
14. Could this use weak references for memory pressure? (Advanced pattern)
15. Should this be async? (Concurrency consideration)
```

---

## Implementation Strategy (Wisdom Extraction)

Following the "Extract Wisdom, Leave Baggage" philosophy:

### Wisdom to Extract

**From Static Analyzers**:
- ✅ AST parsing (essential)
- ❌ Full type checking infrastructure (baggage)

**From LLMs**:
- ✅ Pattern recognition (essential)
- ❌ Cloud API dependency (baggage)

**From Educational Frameworks**:
- ✅ Question taxonomy (Bloom's) (essential)
- ❌ LMS integration (baggage)

**From Documentation Tools**:
- ✅ Code structure traversal (essential)
- ❌ Output formatting engine (baggage)

### Minimal Viable Implementation

**Phase 1: Pattern-Based (Local-First)**
```bash
#!/bin/bash
# caqt-generate.sh - Code Architecture Question Tool
# Input: Source file path
# Output: Markdown file with questions

FILE="$1"
OUTPUT="${FILE}.questions.md"

# Use tree-sitter or simple regex patterns
# Generate questions from detectable patterns:
# - Class without docstring → "What does this class do?"
# - Method > 50 lines → "Could this be decomposed?"
# - Magic numbers → "Why this specific value?"
# - Empty error handlers → "What errors are expected here?"

echo "# Architectural Questions: $FILE" > "$OUTPUT"
echo "" >> "$OUTPUT"

# Pattern 1: Detect classes without docstrings
grep -n "^class " "$FILE" | while read line; do
    echo "## Question: Class Purpose" >> "$OUTPUT"
    echo "- Line: $line" >> "$OUTPUT"
    echo "- What is the responsibility of this class?" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
done

# Pattern 2: Detect TODO/FIXME
grep -n "TODO\|FIXME" "$FILE" | while read line; do
    echo "## Question: Technical Debt" >> "$OUTPUT"
    echo "- $line" >> "$OUTPUT"
    echo "- Why hasn't this been addressed?" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
done

# ... more patterns ...
```

**Phase 2: LLM-Enhanced (Optional)**
- Use local models (llama.cpp, Ollama) for deeper analysis
- Fallback to pattern-based if LLM unavailable
- Privacy: never send code to cloud without explicit consent

**Phase 3: Integration**
- Git pre-commit hook: generate questions for changed files
- CI/CD: fail if critical questions unanswered
- Documentation pipeline: questions → answers → docs

---

## Question Taxonomy (Bloom's Applied)

| Cognitive Level | Question Type | Example |
|----------------|---------------|---------|
| **Remember** | Definition | "What design pattern is this?" |
| **Understand** | Explanation | "Why was this approach chosen?" |
| **Apply** | Usage | "How would you use this in scenario X?" |
| **Analyze** | Decomposition | "What are the dependencies?" |
| **Evaluate** | Trade-offs | "What are the pros/cons vs. approach Y?" |
| **Create** | Alternatives | "How else could this be implemented?" |

**Tool Output**: Questions classified by level, prioritized by relevance

---

## Integration with Ludarium Platform

### Fits Existing Patterns

**1. JITS (Just-In-Time Specificity)**
- TIER1: Critical architectural questions (always needed)
- TIER2: Module-level design questions (often needed)
- TIER3: Implementation detail questions (occasionally needed)
- TIER4: Historical context questions (rarely needed)

**2. Wisdom Extraction Philosophy**
- Extract: Question generation logic
- Leave: Complex IDE integration, cloud dependencies

**3. Publication Surfaces**
- Input: Code repositories
- Output: Question sets publishable to multiple formats (MD, HTML, audio)

**4. Knowledge Base Integration**
- Discovered patterns → knowledge-base/patterns/
- Question templates → reusable across projects
- Answers → documentation artifacts

### Workspace Boundaries Compliance

**Meta-Project Authority**:
- Tool implementation (scripts/caqt-generate.py)
- Question taxonomy patterns (knowledge-base/patterns/code-questioning.md)
- Integration with bridge system

**Sub-Project Authority**:
- Domain-specific question customization
- Answer documentation
- Code-specific configurations

---

## Comparison to Existing Tools

| Tool | Purpose | Output | CAQT Difference |
|------|---------|--------|-----------------|
| **SonarQube** | Code quality | Issues, metrics | Questions vs. errors |
| **Doxygen** | Documentation | API docs | Questions vs. declarations |
| **CodeScene** | Technical debt | Hotspots, complexity | Questions vs. visualizations |
| **GitHub Copilot** | Code generation | Code suggestions | Questions vs. answers |
| **Sourcegraph** | Code search | Search results | Questions vs. lookup |

**CAQT Uniqueness**: Only tool focused on **interrogation-driven understanding**

---

## Research Directions

### Academic Validation
1. Does question-driven onboarding reduce time-to-productivity?
2. Do generated questions improve code review quality?
3. Can architectural questions predict technical debt?

### Technical Enhancements
1. AST-based pattern detection (tree-sitter, LibCST)
2. Dependency graph analysis for coupling questions
3. Historical analysis (git blame → "Why was this changed?")
4. Cross-language support (Python, JavaScript, Go, Rust)

### Educational Applications
1. Generate problem sets from open-source projects
2. Create "treasure hunt" learning paths through codebases
3. Socratic teaching: Answer questions to build understanding

---

## Next Steps

### Incubator → Kitchen
- [ ] Build minimal prototype (pattern-based, single language)
- [ ] Test on 3 diverse codebases
- [ ] Validate: Does this generate useful questions?
- [ ] Document: Pattern extraction rules

### Kitchen → Production
- [ ] Refine question taxonomy based on feedback
- [ ] Add LLM enhancement (optional, local-first)
- [ ] Create integration hooks (pre-commit, CI/CD)
- [ ] Write comprehensive documentation

### Potential Collaborations
- **Sub-projects**: Test on aafc-herbarium codebase
- **Investigator Agent**: Use for codebase exploration tasks
- **Audio System**: Generate audiobook questions for code walkthroughs

---

## References

**Theoretical Foundation**:
- Bloom's Taxonomy (cognitive levels)
- Socratic Method (question-driven learning)
- Code Comprehension Research (von Mayrhauser & Vans, 1995)

**Tool Precedents**:
- Static analyzers (AST patterns)
- Documentation generators (structure traversal)
- Educational platforms (question generation)

**Ludarium Patterns**:
- [just-in-time-specificity.md](../knowledge-base/patterns/just-in-time-specificity.md)
- [wisdom-extraction-philosophy.md](../knowledge-base/patterns/wisdom-extraction-philosophy.md)
- [information-parity-design.md](../knowledge-base/patterns/information-parity-design.md)

---

## Hypothesis

**Claim**: A tool that generates architectural questions from code will:
1. Reduce onboarding time by 30-50% (structured exploration)
2. Improve code review depth (surface implicit assumptions)
3. Generate better documentation (question-answer format more useful)
4. Identify technical debt earlier (questions reveal gaps)

**Validation**: Build prototype, measure against control groups

---

## License & Contribution

**Status**: Open for development
**License**: TBD (likely MIT/Apache 2.0 for tool, CC-BY for taxonomy)
**Contributions**: Welcome after Kitchen-stage validation

---

**Summary**: This tool fills a genuine market gap by bringing interrogative methods to code understanding, complementing existing declarative/imperative tools.
