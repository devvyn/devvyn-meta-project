# Content-Addressed DAG Pattern

**Design wisdom from IPFS without infrastructure baggage**

## Problem

Digital dissociation: fragmented async data workflows lose provenance over time.

- Which batch contained this artifact?
- Was this output from the retry or the original run?
- Are these two files duplicates or convergently similar?
- When did we learn this fact about this specimen?
- What inputs produced this result?

Traditional approaches (timestamps, file paths, batch IDs, naming conventions) fail when:
- Operations are async and fragmented
- Data gets duplicated across workflows
- Processing happens in stages with branches
- Totality of information is never guaranteed upfront
- Provenance must be reconstructed forensically after the fact

## Solution

**Content-Addressed Artifacts + Explicit DAG Links = Reconstructable Provenance**

Three primitives solve the dissociation problem:

1. **Content-addressing**: Artifact identity IS its content (SHA256 hash)
2. **DAG references**: Every output explicitly links to its inputs
3. **Fragment preservation**: Metadata accumulates progressively, never overwrites

## Architecture

### Storage

```
.dag/
  objects/
    ab/
      abcd1234...  # Content-addressed blobs
  nodes/
    xyz789.json  # DAG metadata nodes
    message-2024-10-08-code-abc123.json  # Symbolic links for lookup
```

**Note**: Uses `.dag/` prefix (dotfile convention) to avoid namespace collision with git repos (`.git/objects/`)

### DAG Node Format

```json
{
  "hash": "abcd1234...",           // Content hash this node describes
  "inputs": ["def456...", "..."],  // Input hashes (empty for root nodes)
  "metadata": {                     // Domain-specific metadata
    "type": "bridge_message",
    "sender": "code",
    "message_id": "2024-10-08..."
  },
  "timestamp": "2024-10-08T12:00:00Z"
}
```

## Core Primitives

See `lib/content-dag.sh`:

- `hash_content(file)` → hash
- `store_object(file)` → hash
- `create_dag_node(hash, inputs[], metadata)` → node_hash
- `merge_fragments(output, fragment_hashes...)` → merged_node_hash
- `trace_provenance(node_hash)` → tree visualization

## Design Principles

### 1. Identity = Content

```bash
# Traditional: "Is this a duplicate?"
ls batch_a/ batch_b_retry/ | grep IMG_2847

# Content-addressed: Hash tells you definitively
hash_content batch_a/IMG_2847.jpg  # abc123...
hash_content batch_b_retry/IMG_2847.jpg  # abc123... → identical
hash_content batch_b_retry/IMG_2848.jpg  # def456... → different
```

### 2. References = Explicit

```bash
# Traditional: Implicit dependency (hope your paths/timestamps are right)
process_stage2.sh --input batch_a_processed/

# DAG: Explicit input tracking
create_dag_node $output_hash "[\"$input1_hash\", \"$input2_hash\"]" '{...}'
```

### 3. Fragments = Preserved

```bash
# Traditional: Metadata overwrites/updates (loses history)
echo "location: corrected" > specimen_metadata.txt

# DAG: Fragments accumulate
fragment1_hash=$(store_object field_notes.json)
fragment2_hash=$(store_object georef_correction.json)
merged_hash=$(merge_fragments merged.json $fragment1_hash $fragment2_hash)
# Can still query: "What did we know before the correction?"
```

### 4. Totality = Emergent

You never claim "this is complete" - the DAG shows what you have:

```
specimen_image → hash_A
├─ field_notes → fragment_1
├─ geolocation → fragment_2
└─ taxonomy → fragment_3
    └─ merged_metadata → references [1, 2, 3]
```

Missing fragment_4 (DNA analysis)? DAG shows it's not there. When it arrives, merge it in, creating a new node.

## Cross-Domain Applications

**Implementation Status**:
- ✅ **Agent Bridge**: Fully implemented with provenance tracking
- 📋 **AAFC Herbarium**: Conceptual examples (not yet implemented)
- 📋 **Build Artifacts**: Pattern applicable (not yet implemented)
- 📋 **Research Datasets**: Pattern applicable (not yet implemented)

### Agent Bridge Messages (✅ Implemented)

```bash
# Send message with provenance tracking
./scripts/bridge-send-dag.sh code chat HIGH "Analysis Complete" \
  analysis.md --reply-to 2024-10-08-chat-abc123

# Query provenance
./scripts/bridge-query-provenance.sh 2024-10-08-code-def456 --full
```

**Benefits:**
- Every response cryptographically linked to input messages
- Decision chains are explorable DAGs
- Duplicate messages detected automatically (same hash)
- Lost messages visible in DAG (missing input reference)

### Herbarium Digitization (AAFC) (📋 Conceptual - Not Yet Implemented)

**Note**: This example demonstrates how the pattern *could* be applied to herbarium workflows. Python library and AAFC-specific tools do not currently exist.

```python
# Conceptual example - library not yet implemented
from content_dag import hash_content, create_dag_node

# Stage 1: Capture
raw_hash = hash_content("specimen_raw.tif")
metadata = {"type": "raw_image", "specimen_id": "AAFC-12345"}
node1 = create_dag_node(raw_hash, [], metadata)

# Stage 2: Preprocessing
processed_hash = hash_content("specimen_processed.jpg")
metadata = {"type": "preprocessed", "color_profile": "corrected"}
node2 = create_dag_node(processed_hash, [node1], metadata)

# Stage 3: Feature extraction
features_hash = hash_content("features.json")
metadata = {"type": "features", "model": "v2.1"}
node3 = create_dag_node(features_hash, [node2], metadata)

# Can query: Which raw image produced these features?
# Traverse: node3 → node2 → node1 → raw_hash
```

**Benefits:**
- Failed batches vs retries: compare input hashes
- Duplicate specimens: same raw_hash across batches
- Pipeline verification: trace any output back to raw input
- Metadata fragments: accumulate over decades without overwriting

### Build Artifacts (📋 Conceptual)

```bash
# Conceptual example using bash primitives
src_hash=$(hash_content main.c)

# Compiled output
bin_hash=$(hash_content main.o)
create_dag_node $bin_hash "[\"$src_hash\"]" \
  '{"type": "compile", "compiler": "gcc-11", "flags": "-O2"}'

# Deterministic builds: same src_hash + metadata → same bin_hash
# Non-deterministic: different bin_hash reveals toolchain drift
```

## Implementation Patterns

### Minimal (Shell scripts)

```bash
source lib/content-dag.sh  # Creates .dag/ in current directory
hash=$(store_object data.jpg)
node=$(create_dag_node $hash '[]' '{"type": "raw"}')

# Or configure custom location
export CONTENT_DAG_OBJECTS=/path/to/objects
export CONTENT_DAG_DAG=/path/to/nodes
```

### Mid-tier (SQLite index)

```sql
CREATE TABLE dag_nodes (
  hash TEXT PRIMARY KEY,
  content_hash TEXT,
  inputs TEXT,  -- JSON array
  metadata TEXT,  -- JSON object
  timestamp TEXT
);
CREATE INDEX idx_content ON dag_nodes(content_hash);
```

### Advanced (Custom tooling)

- Query language for DAG traversal
- Garbage collection (prune unreferenced nodes)
- Replication (sync DAG across systems)
- Visualization (render provenance trees)

## Anti-Patterns

### ❌ Premature unification

Don't build "one true DAG library" for all systems. Let each domain implement locally, converge later if needed.

### ❌ Mutable metadata

Don't update DAG nodes. Create new nodes that reference old ones.

### ❌ Hash collisions ignored

SHA256 collisions are astronomically unlikely, but check `verify_object()` periodically.

### ❌ Forgetting to link

Every transformation must create a DAG node with input references. Missing links break provenance.

## Migration Strategy

### For existing systems

1. **Retroactive DAG construction**: Hash existing files, reconstruct relationships from timestamps/metadata
2. **Accept uncertainty**: Some relationships may be "probably" not "definitely"
3. **Going forward**: New artifacts use DAG from creation

### For new systems

1. **Content-address from day 1**: Hash on creation
2. **Track inputs explicitly**: Every transform references its sources
3. **Preserve fragments**: Never overwrite, always append/merge

## Comparison to IPFS

| Aspect | IPFS | This Pattern |
|--------|------|--------------|
| **Content addressing** | ✅ CID (multihash) | ✅ SHA256 |
| **DAG structure** | ✅ IPLD | ✅ JSON nodes |
| **Distribution** | ✅ P2P network | ❌ Local only |
| **Pinning required** | ✅ Critical | ✅ (implicit via storage) |
| **Gateway centralization** | ⚠️ Common issue | N/A |
| **Daemon overhead** | ⚠️ Required | ✅ None |
| **Mutable refs (IPNS)** | ⚠️ Latency issues | ✅ Symlinks/DB |
| **Adoption friction** | ⚠️ High (infrastructure) | ✅ Low (scripts/lib) |

**Wisdom extracted**: Content-addressing + Merkle DAG
**Baggage left behind**: P2P networking, daemon management, gateway infrastructure

## Examples

### Example 1: Message Thread Provenance

```bash
# Initial message
./scripts/bridge-send-dag.sh human code HIGH "Build new feature"

# Response
./scripts/bridge-send-dag.sh code human NORMAL "Feature complete" \
  feature.md --reply-to 2024-10-08-human-abc

# Follow-up
./scripts/bridge-send-dag.sh human code HIGH "Add tests" \
  --reply-to 2024-10-08-code-def

# Query full conversation DAG
./scripts/bridge-query-provenance.sh 2024-10-08-human-ghi --full
```

Output shows complete conversation tree with cryptographic provenance.

### Example 2: Specimen Metadata Accumulation

```python
# Field collection (fragment 1)
field_notes = {"collector": "J. Smith", "date": "1987-06-15"}
frag1 = create_dag_fragment(specimen_id, field_notes)

# Georeference correction (fragment 2) - 2023
georef = {"lat": 45.123, "lon": -75.456, "corrected": "2023-05-10"}
frag2 = create_dag_fragment(specimen_id, georef)

# Taxonomic redetermination (fragment 3) - 2024
taxonomy = {"species": "Carex updated", "determiner": "Dr. Lee"}
frag3 = create_dag_fragment(specimen_id, taxonomy)

# Merged view
merged = merge_fragments([frag1, frag2, frag3])

# Query: "What did we know in 2020?"
# Answer: traverse DAG, show only nodes before 2020-01-01
```

### Example 3: Build Pipeline

```bash
# Stage 1: Source
src_hash=$(store_object src/main.c)
node1=$(create_dag_node $src_hash '[]' '{"stage": "source"}')

# Stage 2: Compile
gcc -c src/main.c -o build/main.o
obj_hash=$(store_object build/main.o)
node2=$(create_dag_node $obj_hash "[\"$node1\"]" \
  '{"stage": "compile", "flags": "-O2"}')

# Stage 3: Link
gcc build/main.o -o bin/program
bin_hash=$(store_object bin/program)
node3=$(create_dag_node $bin_hash "[\"$node2\"]" \
  '{"stage": "link"}')

# Verify: "Did src/main.c produce bin/program?"
trace_provenance $node3  # Shows: node3 → node2 → node1 → src_hash
```

## Future Directions

**Next Implementation Priorities**:
- **Python library**: `lib/content_dag.py` - port primitives for Python workflows
- **AAFC tooling**: When actual herbarium research begins (requires data/requirements)
- **Replication**: Sync DAG across agent sessions
- **Queries**: SQL-like DAG traversal language
- **Visualization**: GraphViz rendering of provenance trees
- **Garbage collection**: Prune unreferenced objects
- **Signing**: Add cryptographic signatures to DAG nodes
- **Conflict resolution**: Merge divergent DAG branches

## References

- IPFS: https://ipfs.tech
- IPLD: https://ipld.io
- Git internals: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects
- Merkle DAGs: https://en.wikipedia.org/wiki/Merkle_tree

---

**Implementation Status**:
- ✅ **Core library**: `lib/content-dag.sh` (bash primitives)
- ✅ **Agent bridge integration**: `scripts/bridge-send-dag.sh` with provenance
- ✅ **Documentation**: Pattern design and examples
- 📋 **Python port**: Planned (not yet implemented)
- 📋 **AAFC tooling**: Conceptual (awaiting actual research requirements)

**Cross-domain potential**: Pattern validated via agent bridge, applicable to herbarium digitization, build systems, research datasets

**Philosophy**: Extract design wisdom, leave infrastructure baggage
