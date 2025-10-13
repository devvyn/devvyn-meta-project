# Content-DAG Examples

## Available Examples

### `content-dag-demo.sh`

Interactive demonstration of the content-addressed DAG pattern.

**Run it:**
```bash
./examples/content-dag-demo.sh
```

**Shows:**
- Content-addressing (identity = hash)
- DAG node creation with metadata
- Fragment merging (progressive metadata accumulation)
- Provenance tree visualization
- Duplicate detection via hash comparison
- Content integrity verification

**Scenario:** Herbarium specimen metadata fragments accumulating over decades (1987 → 2023 → 2024)

## Pattern Overview

See `docs/CONTENT_DAG_PATTERN.md` for complete documentation.

**Core insight:** Fragmented async data workflows + content-addressing + DAG = reconstructable provenance

**Cross-domain applications:**
- Agent bridge messages
- Herbarium digitization (AAFC)
- Build pipelines
- Research datasets

## Quick Start

```bash
# Source the library (creates .dag/ in current directory)
source lib/content-dag.sh

# Store content
hash=$(store_object data.jpg)

# Create DAG node
node=$(create_dag_node "$hash" '["input1", "input2"]' '{"type": "processed"}')

# Query provenance
trace_provenance "$node"
```

**Storage**: Creates `.dag/objects/` and `.dag/nodes/` - dotfile convention avoids git namespace collision

## Integration Examples

### Agent Bridge

```bash
# Send with provenance
./scripts/bridge-send-dag.sh code chat HIGH "Title" content.md

# Query provenance
./scripts/bridge-query-provenance.sh <message-id> --full
```

### AAFC Workflows (Future)

```python
from content_dag import hash_content, create_dag_node

# Process specimen
raw_hash = hash_content("specimen.tif")
node = create_dag_node(raw_hash, [], {"type": "raw", "specimen_id": "12345"})
```
