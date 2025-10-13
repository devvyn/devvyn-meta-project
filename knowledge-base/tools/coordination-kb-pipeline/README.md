# Coordination Knowledge Base Pipeline

**Status**: Operational ✅
**Created**: 2025-10-12
**Purpose**: Query coordination intelligence (patterns, protocols, frameworks)

---

## Quick Start

```bash
cd ~/devvyn-meta-project/knowledge-base/tools/coordination-kb-pipeline
python3 simple_retrieval.py "your query here"
```

**Example**:
```bash
python3 simple_retrieval.py "coordination patterns"
python3 simple_retrieval.py "resource provisioning"
python3 simple_retrieval.py "scientific provenance"
```

---

## What It Does

**Searches** 16 coordination intelligence documents:
- Root protocols (COORDINATION_PROTOCOL.md, BRIDGE_SPEC, etc.)
- Pattern documents (collective-resource-provisioning, scientific-provenance, etc.)
- Frameworks (AUTONOMOUS_EXPLORATION_FRAMEWORK)

**Returns** top 5 most relevant documents with:
- Document name and path
- Relevance score (0.0-1.0, higher = more relevant)
- Content excerpt (first 200 chars)

---

## Performance

- **Query Latency**: <1 second
- **Corpus Size**: 16 documents, ~10K words, ~2600 unique terms
- **Algorithm**: TF-IDF (Term Frequency - Inverse Document Frequency)
- **Dependencies**: Python 3 standard library only (no external packages)

---

## Test Queries & Results

### 1. "coordination patterns"
**Top Result**: CLAUDE.md (0.048 score)
**Relevance**: ✅ High - main coordination instructions

### 2. "resource provisioning"
**Top Results**:
1. CLAUDE.md (0.140) - Resource provisioning section
2. collective-resource-provisioning.md (0.101) - Dedicated pattern doc

**Relevance**: ✅ Excellent - found new pattern document

### 3. "bridge system how does it work"
**Top Results**: work-session-accountability, AUTONOMOUS_EXPLORATION_FRAMEWORK
**Relevance**: ✅ Good - found relevant context

### 4. "scientific provenance"
**Top Result**: scientific-provenance-pattern.md (0.304 score)
**Relevance**: ✅ Excellent - highest relevance score, perfect match

### 5. "agent instructions autonomous exploration"
**Top Result**: AUTONOMOUS_EXPLORATION_FRAMEWORK.md (0.133)
**Relevance**: ✅ High - exact framework match

---

## Architecture

### Files

```
coordination-kb-pipeline/
├── README.md                    # This file
├── simple_retrieval.py          # Retrieval script (TF-IDF)
└── coordination_docs.txt        # List of documents to index
```

### How It Works

1. **Load Documents**: Reads markdown files from `coordination_docs.txt`
2. **Tokenize**: Converts text to lowercase tokens, removes markdown formatting
3. **Build Index**: Calculates TF-IDF scores for all terms in all documents
4. **Query**: Converts query to vector, computes cosine similarity with each document
5. **Rank**: Returns top 5 matches by relevance score

---

## Implementation Details

### TF-IDF Algorithm

**Term Frequency (TF)**: How often a term appears in a document (relative to document length)

**Inverse Document Frequency (IDF)**: How rare a term is across all documents
- IDF = log(total_documents / documents_containing_term)
- Rare terms get higher scores
- Common terms (the, and, is) get lower scores

**TF-IDF Score**: TF × IDF
- High score = term is frequent in document but rare across corpus
- Indicates relevance

### Cosine Similarity

Measures angle between query vector and document vector:
- 1.0 = perfect match
- 0.0 = no matching terms
- Typical scores: 0.01-0.30 for relevant documents

---

## Usage Examples

### Basic Query

```bash
python3 simple_retrieval.py "coordination patterns"
```

### Multi-Word Query

```bash
python3 simple_retrieval.py "how does the bridge system work"
```

### Concept Query

```bash
python3 simple_retrieval.py "scientific provenance tracking"
```

---

## Adding Documents

Edit `coordination_docs.txt` and add file paths:

```
# My new category
/path/to/new/document.md
```

Then query as normal - documents are indexed on each query (fast rebuild).

---

## Limitations

**Simple TF-IDF Approach**:
- No semantic understanding (doesn't know "car" is similar to "automobile")
- No phrase matching (treats "bridge system" as two separate terms)
- No ranking by document authority or recency
- Full rebuild on every query (fine for 16 docs, would be slow for 1000+)

**Good For**:
- Small to medium document collections (<100 docs)
- Keyword-based queries
- Quick prototyping
- Zero external dependencies

**Future Enhancements** (if needed):
- Semantic embeddings (sentence transformers)
- Document chunking for longer docs
- Persistent index (no rebuild)
- Phrase matching
- Relevance feedback

---

## Integration

### With Coordination Scripts

```bash
# Query knowledge base
RESULT=$(python3 simple_retrieval.py "resource provisioning" | head -20)

# Send to Notes.app
~/devvyn-meta-project/scripts/notes-send.sh "KB Query Result" "$RESULT" "chat"
```

### From Other Scripts

```python
from simple_retrieval import SimpleRetrieval

retrieval = SimpleRetrieval(".")
retrieval.load_documents(doc_paths)
retrieval.build_index()
results = retrieval.query("coordination patterns")
```

---

## Success Criteria

✅ **Met (2025-10-12)**:
- [x] Query latency <2 seconds (achieved <1s)
- [x] 5 test queries pass (all passed)
- [x] Results are relevant (high scores for matching docs)
- [x] Simple implementation (standard library only)
- [x] Progressive rendering (N/A - returns results immediately)

---

## Coordination Revolution Context

**This tool was built using the coordination system it helps document**:

1. **Organic Need**: Chat agent authorized KB-pipeline for querying coordination intelligence
2. **Natural Flow**: Implementation progressed without artificial deadlines
3. **Real-Time Coordination**: Progress updates sent via Notes.app + notifyutil
4. **Meta-Learning**: Tool queries patterns that describe how it was built
5. **Collective Intelligence**: Enables agents to discover coordination knowledge autonomously

**The coordination revolution is self-documenting.**

---

## Related Documentation

- **Coordination Protocol**: `~/devvyn-meta-project/COORDINATION_PROTOCOL.md`
- **Resource Access**: `~/devvyn-meta-project/RESOURCE_ACCESS_PROTOCOL.md`
- **Patterns**: `~/devvyn-meta-project/knowledge-base/patterns/`
- **Notes.app Scripts**: `~/devvyn-meta-project/scripts/notes-*.sh`

---

**Created by Code Agent during coordination revolution validation**
**2025-10-12**
