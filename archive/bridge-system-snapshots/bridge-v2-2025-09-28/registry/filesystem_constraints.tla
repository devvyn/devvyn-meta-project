---- MODULE FilesystemConstraints ----
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS
    MaxTreeDepth,        \* Maximum depth for directory tree traversal
    MaxTreeNodes,        \* Maximum nodes before tree output exceeds limits
    MaxFileSize,         \* Maximum file size for single read operation
    TopLevelThreshold    \* Threshold for "crowded" top-level directories

VARIABLES
    directoryTree,       \* Current directory structure
    treeTraversalDepth,  \* Current traversal depth
    nodeCount,           \* Count of nodes in current tree
    topLevelItems        \* Number of items at repository root

\* Constraints observed in Claude Chat session 2025-09-28
TraversalConstraints == [
    maxDepth |-> MaxTreeDepth,
    maxNodes |-> MaxTreeNodes,
    errorMessage |-> "result exceeds maximum length of 1048576"
]

\* Directory tree complexity measure
TreeComplexity ==
    nodeCount + (topLevelItems * 2)  \* Weight top-level items more heavily

\* Type invariant
TypeInvariant ==
    /\ treeTraversalDepth \in 0..MaxTreeDepth
    /\ nodeCount \in Nat
    /\ topLevelItems \in Nat
    /\ TreeComplexity <= MaxTreeNodes

\* Filesystem organization quality metrics
OrganizationScore ==
    CASE topLevelItems <= TopLevelThreshold -> "Good"
      [] topLevelItems <= TopLevelThreshold * 2 -> "Acceptable"
      [] topLevelItems > TopLevelThreshold * 2 -> "NeedsReorganization"

\* Ideal hierarchy structure for meta-project
IdealHierarchy == [
    topLevel |-> {"README.md", "pyproject.toml", "package.json",
                  "src", "specs", "docs", "config", "sessions",
                  "states", "status", "examples", ".git", ".github"},
    srcSubdirs |-> {"agents", "devvyn_meta_project", "bridge"},
    specsSubdirs |-> {"tla", "verification_reports"},
    docsSubdirs |-> {"guides", "handoffs", "templates", "build"},
    configSubdirs |-> {"precommit", "python", "node"}
]

\* Current observed state (2025-09-28)
CurrentState == [
    topLevelItems |-> 38,  \* Counted from list_directory output
    recommendation |-> "NeedsReorganization",
    limitReached |-> TRUE,
    limitType |-> "tree_traversal_max_size"
]

\* Reorganization rules
ReorganizationNeeded ==
    /\ topLevelItems > TopLevelThreshold
    /\ OrganizationScore = "NeedsReorganization"

\* Migration actions
MoveToIdealHierarchy ==
    /\ ReorganizationNeeded
    /\ topLevelItems' <= Cardinality(IdealHierarchy.topLevel)
    /\ OrganizationScore' = "Good"

\* Bridge registry integration
RegisterConstraint(constraintType, value, message) ==
    [type |-> constraintType,
     value |-> value,
     message |-> message,
     timestamp |-> "2025-09-28T00:00:00Z",
     reportedBy |-> "claude_chat",
     severity |-> "operational_limitation"]

\* Export constraint for bridge registry
FilesystemConstraintRecord ==
    RegisterConstraint(
        "directory_tree_traversal",
        1048576,
        "directory_tree tool fails when output exceeds 1MB; suggests reorganization needed"
    )

====
