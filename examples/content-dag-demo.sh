#!/bin/bash
# Content-Addressed DAG Pattern - Live Demo
# Demonstrates progressive metadata accumulation with provenance

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source content-dag library
source "$PROJECT_ROOT/lib/content-dag.sh"

# Use temp directory for demo
DEMO_DIR=$(mktemp -d -t content-dag-demo.XXXXXX)
export CONTENT_DAG_OBJECTS="$DEMO_DIR/objects"
export CONTENT_DAG_DAG="$DEMO_DIR/dag"

echo "🎬 Content-Addressed DAG Pattern Demo"
echo "======================================"
echo ""
echo "📁 Demo directory: $DEMO_DIR"
echo ""

# Scenario: Herbarium specimen metadata accumulation over time
echo "📚 Scenario: Herbarium specimen metadata fragments"
echo ""

# Fragment 1: Field collection notes (1987)
echo "1️⃣  Field Collection (1987)"
cat > "$DEMO_DIR/field_notes.json" << 'EOF'
{
  "specimen_id": "AAFC-12345",
  "collector": "J. Smith",
  "collection_date": "1987-06-15",
  "location": "Ottawa, ON (approximate)",
  "habitat": "Wetland margin"
}
EOF

frag1_hash=$(store_object "$DEMO_DIR/field_notes.json")
node1=$(create_dag_node "$frag1_hash" "[]" '{"type": "field_notes", "year": 1987}')

echo "   Content hash: $frag1_hash"
echo "   DAG node: $node1"
echo ""

# Fragment 2: Georeference correction (2023)
echo "2️⃣  Georeference Correction (2023)"
cat > "$DEMO_DIR/georef_correction.json" << 'EOF'
{
  "specimen_id": "AAFC-12345",
  "latitude": 45.4215,
  "longitude": -75.6972,
  "datum": "WGS84",
  "georeference_notes": "Corrected using modern mapping",
  "georeferenced_by": "Dr. A. Lee",
  "georeference_date": "2023-05-10"
}
EOF

frag2_hash=$(store_object "$DEMO_DIR/georef_correction.json")
node2=$(create_dag_node "$frag2_hash" "[]" '{"type": "georeference", "year": 2023}')

echo "   Content hash: $frag2_hash"
echo "   DAG node: $node2"
echo ""

# Fragment 3: Taxonomic redetermination (2024)
echo "3️⃣  Taxonomic Redetermination (2024)"
cat > "$DEMO_DIR/taxonomy_update.json" << 'EOF'
{
  "specimen_id": "AAFC-12345",
  "family": "Cyperaceae",
  "genus": "Carex",
  "species": "stricta",
  "determiner": "Dr. M. Chen",
  "determination_date": "2024-03-15",
  "notes": "Updated from C. aquatilis based on molecular analysis"
}
EOF

frag3_hash=$(store_object "$DEMO_DIR/taxonomy_update.json")
node3=$(create_dag_node "$frag3_hash" "[]" '{"type": "taxonomy", "year": 2024}')

echo "   Content hash: $frag3_hash"
echo "   DAG node: $node3"
echo ""

# Merge fragments
echo "4️⃣  Merging Fragments → Progressive Totality"
merged_hash=$(merge_fragments "$DEMO_DIR/merged_metadata.json" "$node1" "$node2" "$node3")

echo "   Merged node: $merged_hash"
echo ""

# Show provenance
echo "🌳 Provenance Tree:"
echo ""
trace_provenance "$merged_hash"
echo ""

# Demonstrate query capabilities
echo "🔍 Query Capabilities:"
echo ""

echo "   Q: What metadata fragments exist for this specimen?"
echo "   A: Inputs of merged node:"
query_inputs "$merged_hash" | while read -r input; do
    echo "      - $input"
done
echo ""

echo "   Q: What did we know in 2020 (before georef correction)?"
echo "   A: Only fragment from 1987:"
echo "      - $node1 (field notes)"
echo ""

echo "   Q: Are there duplicate specimens?"
# Create a "duplicate" with same content
cp "$DEMO_DIR/field_notes.json" "$DEMO_DIR/field_notes_copy.json"
dup_hash=$(hash_content "$DEMO_DIR/field_notes_copy.json")
echo "   A: Hash comparison:"
echo "      Original: $frag1_hash"
echo "      Copy:     $dup_hash"
if [[ "$frag1_hash" == "$dup_hash" ]]; then
    echo "      ✅ Identical content (same hash)"
else
    echo "      ❌ Different content"
fi
echo ""

# Show object verification
echo "🔐 Content Integrity:"
verify_object "$frag1_hash"
verify_object "$frag2_hash"
verify_object "$frag3_hash"
verify_object "$merged_hash"
echo ""

# Show storage structure
echo "📦 Storage Structure:"
echo ""
echo "$DEMO_DIR/"
tree -L 3 "$DEMO_DIR" 2>/dev/null || find "$DEMO_DIR" -type f | head -20
echo ""

echo "✅ Demo Complete!"
echo ""
echo "💡 Key Insights:"
echo "   • Content addressing: Identity = content (eliminates 'is this a duplicate?')"
echo "   • DAG references: Explicit links (eliminates 'where did this come from?')"
echo "   • Fragment preservation: Temporal provenance (eliminates 'when did we know this?')"
echo "   • Progressive totality: Merge without overwrite (eliminates 'do we have everything?')"
echo ""
echo "🧹 Cleanup: rm -rf $DEMO_DIR"
