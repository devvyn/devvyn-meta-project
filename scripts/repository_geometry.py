#!/usr/bin/env python3
"""
Repository Geometry Analyzer - Marimo Notebook
Interactive exploration of repository spatial structure and governance

Usage:
    marimo edit repository_geometry.py

    # Or run as script
    python repository_geometry.py --repo . --output analysis.md
"""

import marimo

__generated_with = "0.9.0"
app = marimo.App()


@app.cell
def __():
    """Imports and configuration"""
    import marimo as mo
    import networkx as nx
    import json
    from pathlib import Path
    from collections import defaultdict
    from dataclasses import dataclass, asdict
    from typing import List, Dict, Set, Tuple
    import ast
    import re

    return mo, nx, json, Path, defaultdict, dataclass, asdict, List, Dict, Set, Tuple, ast, re


@app.cell
def __(mo):
    """Configuration controls"""
    repo_path_input = mo.ui.text(
        value=".",
        label="📁 Repository Path",
        placeholder="/path/to/repository"
    )

    analysis_depth = mo.ui.slider(
        start=1,
        stop=10,
        value=5,
        label="🔍 Analysis Depth (directory levels)"
    )

    language_filter = mo.ui.multiselect(
        [".py", ".js", ".ts", ".jsx", ".tsx", ".go", ".rs", ".md"],
        value=[".py", ".js", ".ts"],
        label="🗣️ Languages to Analyze"
    )

    mo.md(f"""
    # Repository Geometry Analysis

    Configure analysis parameters below:
    """)

    return repo_path_input, analysis_depth, language_filter


@app.cell
def __(mo, repo_path_input, analysis_depth, language_filter):
    """Display configuration"""
    mo.hstack([
        repo_path_input,
        analysis_depth,
        language_filter
    ])


@app.cell
def __(Path, repo_path_input, language_filter, analysis_depth, dataclass, List, Dict, Set):
    """Repository geometry analyzer class"""

    @dataclass
    class FileNode:
        path: Path
        language: str
        lines: int
        imports: List[str]
        exports: List[str]

    @dataclass
    class GeometryMetrics:
        total_files: int
        total_lines: int
        languages: Dict[str, int]
        diameter: int
        avg_clustering: float
        density: float
        central_hubs: List[str]
        communities: List[Set[str]]
        diffuse_features: Dict[str, float]
        authority_alignment: float

    class RepositoryGeometry:
        """Analyze spatial properties of repository"""

        def __init__(self, repo_path: Path, languages: List[str], max_depth: int = 10):
            self.repo = Path(repo_path).resolve()
            self.languages = languages
            self.max_depth = max_depth
            self.files: Dict[Path, FileNode] = {}
            self.graph = None

        def scan_repository(self):
            """Scan repository files"""
            for lang in self.languages:
                for file_path in self.repo.rglob(f"*{lang}"):
                    # Skip hidden, build, node_modules, etc.
                    if any(part.startswith('.') or part in ['node_modules', 'build', 'dist', '__pycache__']
                           for part in file_path.parts):
                        continue

                    # Check depth
                    rel_path = file_path.relative_to(self.repo)
                    if len(rel_path.parts) > self.max_depth:
                        continue

                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                            lines = len(content.split('\n'))

                        imports = self._extract_imports(file_path, content)

                        self.files[file_path] = FileNode(
                            path=file_path,
                            language=lang,
                            lines=lines,
                            imports=imports,
                            exports=[]  # TODO: extract exports
                        )
                    except:
                        pass

        def _extract_imports(self, file_path: Path, content: str) -> List[str]:
            """Extract import statements"""
            imports = []

            if file_path.suffix == '.py':
                try:
                    tree = ast.parse(content)
                    for node in ast.walk(tree):
                        if isinstance(node, ast.Import):
                            for alias in node.names:
                                imports.append(alias.name)
                        elif isinstance(node, ast.ImportFrom):
                            if node.module:
                                imports.append(node.module)
                except:
                    pass

            elif file_path.suffix in ['.js', '.ts', '.jsx', '.tsx']:
                # Regex for import statements
                import_pattern = r'import\s+.*?\s+from\s+[\'"]([^\'"]+)[\'"]'
                imports = re.findall(import_pattern, content)

            return imports

        def build_dependency_graph(self):
            """Build dependency graph from imports"""
            import networkx as nx
            G = nx.DiGraph()

            # Add nodes
            for file_path in self.files:
                G.add_node(str(file_path.relative_to(self.repo)))

            # Add edges (imports)
            for file_path, node in self.files.items():
                source = str(file_path.relative_to(self.repo))
                for imp in node.imports:
                    # Try to resolve import to actual file
                    # Simplified: just add edge if import looks local
                    if not imp.startswith('.') and not '/' in imp:
                        continue  # External package
                    # TODO: Better import resolution
                    G.add_edge(source, imp)

            self.graph = G
            return G

        def compute_metrics(self) -> GeometryMetrics:
            """Compute geometric metrics"""
            import networkx as nx

            if not self.graph:
                self.build_dependency_graph()

            # Basic stats
            total_files = len(self.files)
            total_lines = sum(node.lines for node in self.files.values())
            languages = defaultdict(int)
            for node in self.files.values():
                languages[node.language] += 1

            # Graph metrics
            try:
                if nx.is_strongly_connected(self.graph):
                    diameter = nx.diameter(self.graph)
                else:
                    # Use largest strongly connected component
                    largest_cc = max(nx.strongly_connected_components(self.graph), key=len)
                    subgraph = self.graph.subgraph(largest_cc)
                    diameter = nx.diameter(subgraph) if len(subgraph) > 1 else 0
            except:
                diameter = 0

            try:
                avg_clustering = nx.average_clustering(self.graph.to_undirected())
            except:
                avg_clustering = 0.0

            density = nx.density(self.graph)

            # Central hubs
            try:
                centrality = nx.betweenness_centrality(self.graph)
                central_hubs = sorted(centrality, key=centrality.get, reverse=True)[:10]
            except:
                central_hubs = []

            # Communities
            try:
                communities = list(nx.community.greedy_modularity_communities(self.graph.to_undirected()))
            except:
                communities = []

            return GeometryMetrics(
                total_files=total_files,
                total_lines=total_lines,
                languages=dict(languages),
                diameter=diameter,
                avg_clustering=avg_clustering,
                density=density,
                central_hubs=central_hubs,
                communities=communities,
                diffuse_features={},  # TODO
                authority_alignment=0.0  # TODO
            )

        def measure_feature_diffusion(self, feature_pattern: str) -> Dict:
            """Measure how diffuse a feature is across the repository"""
            matching_files = [
                f for f in self.files
                if feature_pattern.lower() in str(f).lower()
            ]

            if not matching_files:
                return {'error': 'No files match pattern'}

            directories = {f.parent for f in matching_files}

            return {
                'file_count': len(matching_files),
                'directory_count': len(directories),
                'diffusion_ratio': len(directories) / len(matching_files),
                'geometry': 'discrete' if len(directories) == 1 else 'diffuse',
                'files': [str(f.relative_to(self.repo)) for f in matching_files[:10]]
            }

    # Create analyzer instance
    analyzer = RepositoryGeometry(
        repo_path_input.value,
        language_filter.value,
        analysis_depth.value
    )

    return RepositoryGeometry, FileNode, GeometryMetrics, analyzer


@app.cell
def __(mo, analyzer):
    """Scan repository"""
    with mo.status.spinner(title="Scanning repository..."):
        analyzer.scan_repository()
        analyzer.build_dependency_graph()

    mo.md(f"""
    ## Repository Scan Complete

    Found **{len(analyzer.files)}** files to analyze
    """)


@app.cell
def __(mo, analyzer):
    """Compute metrics"""
    with mo.status.spinner(title="Computing geometric metrics..."):
        metrics = analyzer.compute_metrics()

    mo.md(f"""
    ## Geometric Metrics

    ### Basic Statistics
    - **Total Files**: {metrics.total_files:,}
    - **Total Lines**: {metrics.total_lines:,}
    - **Languages**: {', '.join(f"{lang} ({count})" for lang, count in metrics.languages.items())}

    ### Graph Topology
    - **Diameter**: {metrics.diameter} (longest dependency path)
    - **Clustering**: {metrics.avg_clustering:.3f} (local interconnectedness)
    - **Density**: {metrics.density:.3f} (how connected)

    ### Structural Features
    - **Central Hubs**: {len(metrics.central_hubs)} identified
    - **Communities**: {len(metrics.communities)} natural clusters
    """)

    return metrics,


@app.cell
def __(mo, metrics):
    """Display central hubs"""
    if metrics.central_hubs:
        mo.md(f"""
        ### 🏙️ Architectural "Downtowns" (Central Hubs)

        These files are critical connectors in the dependency graph:
        """)

        hub_table = mo.ui.table(
            [{"Rank": i+1, "File": hub, "Role": "Critical Hub"}
             for i, hub in enumerate(metrics.central_hubs[:10])]
        )

        hub_table
    else:
        mo.md("*No central hubs detected (disconnected graph)*")


@app.cell
def __(mo, analyzer, metrics):
    """Feature diffusion analysis"""
    feature_input = mo.ui.text(
        value="auth",
        label="🔍 Search for feature (e.g., 'auth', 'user', 'payment')"
    )

    mo.md("### Feature Diffusion Analysis")

    feature_input


@app.cell
def __(mo, analyzer, feature_input):
    """Display feature diffusion results"""
    if feature_input.value:
        diffusion = analyzer.measure_feature_diffusion(feature_input.value)

        if 'error' in diffusion:
            mo.callout(diffusion['error'], kind="warn")
        else:
            geometry_emoji = "🎯" if diffusion['geometry'] == 'discrete' else "🌊"

            mo.md(f"""
            ### {geometry_emoji} Feature: `{feature_input.value}`

            - **Geometry**: {diffusion['geometry'].upper()}
            - **Files**: {diffusion['file_count']}
            - **Directories**: {diffusion['directory_count']}
            - **Diffusion Ratio**: {diffusion['diffusion_ratio']:.2f}

            {'**Discrete feature** - Concentrated in one area (easy to isolate)' if diffusion['geometry'] == 'discrete'
             else '**Diffuse feature** - Spread across multiple areas (cross-cutting concern)'}

            #### Matching Files:
            """)

            mo.ui.table([{"File": f} for f in diffusion.get('files', [])])


@app.cell
def __(mo):
    """Repository Geometry Questions (CAQT Integration)"""

    mo.md("""
    ## 🤔 Geometric Questions (CAQT)

    Questions generated based on repository structure:
    """)

    # Generate geometry-specific questions
    geometry_questions = [
        {
            "Question": "Why is the dependency graph diameter so large?",
            "Tier": 1,
            "Category": "Architecture",
            "Rationale": "Large diameter suggests deep dependency chains"
        },
        {
            "Question": "Which central hubs represent architectural bottlenecks?",
            "Tier": 1,
            "Category": "Design",
            "Rationale": "High centrality = single points of failure"
        },
        {
            "Question": "Why are some features diffuse vs. discrete?",
            "Tier": 2,
            "Category": "Structure",
            "Rationale": "Diffusion indicates cross-cutting concerns"
        },
        {
            "Question": "Do community boundaries align with authority domains?",
            "Tier": 1,
            "Category": "Governance",
            "Rationale": "Natural clusters should match organizational structure"
        }
    ]

    mo.ui.table(geometry_questions)


@app.cell
def __(mo):
    """LLM-augmented analysis (optional)"""

    llm_question = mo.ui.text_area(
        label="💬 Ask about repository geometry",
        placeholder="e.g., 'Why is the clustering coefficient so low?'"
    )

    mo.md("""
    ## 🤖 LLM-Augmented Analysis

    Ask questions about the repository structure:
    """)

    llm_question


@app.cell
def __(mo, llm_question, metrics, analyzer):
    """Process LLM query (placeholder)"""
    if llm_question.value:
        # TODO: Integrate with local Ollama/llama.cpp
        # For now, show structured context that would be sent to LLM

        context = f"""
        Repository: {analyzer.repo}
        Files: {metrics.total_files}
        Lines: {metrics.total_lines:,}
        Languages: {', '.join(metrics.languages.keys())}
        Diameter: {metrics.diameter}
        Clustering: {metrics.avg_clustering:.3f}
        Density: {metrics.density:.3f}
        Central Hubs: {len(metrics.central_hubs)}

        Question: {llm_question.value}

        [This would call local LLM here]
        """

        mo.md(f"""
        ### LLM Context (would be sent to local model):

        ```
        {context}
        ```

        *Integration with Ollama/llama.cpp coming soon*
        """)


@app.cell
def __(mo, metrics, json):
    """Export analysis"""

    export_button = mo.ui.button(label="📤 Export Analysis as JSON")

    mo.md("### Export Results")

    export_button

    if export_button.value:
        # Prepare export data
        export_data = {
            'total_files': metrics.total_files,
            'total_lines': metrics.total_lines,
            'languages': metrics.languages,
            'diameter': metrics.diameter,
            'clustering': metrics.avg_clustering,
            'density': metrics.density,
            'central_hubs': metrics.central_hubs,
            'communities': [list(c) for c in metrics.communities]
        }

        mo.download(
            data=json.dumps(export_data, indent=2).encode(),
            filename="repository_geometry.json",
            mimetype="application/json"
        )


@app.cell
def __(mo):
    """Footer"""
    mo.md("""
    ---

    ## About Repository Geometry Analysis

    This notebook analyzes the **spatial structure** of code repositories using:

    - **Graph Theory**: Dependency networks, centrality, clustering
    - **Spatial Metrics**: Discrete vs. diffuse features, community detection
    - **Governance**: Authority boundary alignment (WORKSPACE_BOUNDARIES.md)

    **Integration**:
    - CAQT (Code Architecture Question Tool): Generates geometric questions
    - JITS Pattern: Tiered analysis (quick scan → deep dive)
    - Workspace Boundaries: Validates authority domain alignment

    **Philosophy**: Repositories are governed territories with spatial structure,
    not just flat file trees. Understanding geometry reveals architectural patterns.
    """)


if __name__ == "__main__":
    # Allow running as script
    import argparse
    parser = argparse.ArgumentParser(description="Repository Geometry Analyzer")
    parser.add_argument('--repo', default='.', help='Repository path')
    parser.add_argument('--output', help='Output file for analysis')
    args = parser.parse_args()

    analyzer = RepositoryGeometry(args.repo, ['.py', '.js', '.ts'], max_depth=10)
    analyzer.scan_repository()
    analyzer.build_dependency_graph()
    metrics = analyzer.compute_metrics()

    print(f"Repository: {args.repo}")
    print(f"Files: {metrics.total_files}")
    print(f"Lines: {metrics.total_lines:,}")
    print(f"Diameter: {metrics.diameter}")
    print(f"Clustering: {metrics.avg_clustering:.3f}")

    if args.output:
        import json
        with open(args.output, 'w') as f:
            json.dump(asdict(metrics), f, indent=2, default=str)
        print(f"Analysis exported to: {args.output}")

    app.run()
