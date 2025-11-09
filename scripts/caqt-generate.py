#!/usr/bin/env python3
"""
Code Architecture Question Tool (CAQT) - Generator
Automatically generates architectural/design questions from source code

Philosophy: Extract wisdom, leave baggage
- ✅ Local-first pattern detection
- ✅ Agent framework integration for rapid contextualization
- ✅ JITS-compliant output (tiered questions)
- ❌ No cloud dependencies (optional LLM enhancement)
- ❌ No complex IDE integration

Usage:
    # Generate questions for a single file
    ./caqt-generate.py path/to/file.py

    # Generate questions for entire directory (agent contextualization)
    ./caqt-generate.py path/to/project/ --output context.md

    # Integration with agent startup
    ./caqt-generate.py . --mode agent-context --top 20

    # JITS-compliant tiered output
    ./caqt-generate.py . --tier 1  # Critical architectural questions only
"""

import argparse
import ast
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Set, Optional, Tuple
import json


@dataclass
class Question:
    """A generated architectural question"""
    text: str
    category: str  # Architecture, Design, Dependency, Performance, etc.
    tier: int  # 1=Critical, 2=Important, 3=Detailed, 4=Historical
    cognitive_level: str  # Bloom's taxonomy: Remember, Understand, Apply, Analyze, Evaluate, Create
    file_path: str
    line_number: Optional[int] = None
    code_context: Optional[str] = None
    rationale: str = ""  # Why this question was generated
    priority: int = 0  # Higher = more important for agent contextualization


@dataclass
class CodebaseContext:
    """High-level codebase understanding for agent instantiation"""
    total_files: int = 0
    total_lines: int = 0
    languages: Set[str] = field(default_factory=set)
    top_level_modules: List[str] = field(default_factory=list)
    architectural_patterns: List[str] = field(default_factory=list)
    critical_questions: List[Question] = field(default_factory=list)
    dependency_graph: Dict[str, List[str]] = field(default_factory=dict)
    entry_points: List[str] = field(default_factory=list)


class QuestionGenerator:
    """Generate architectural questions from code patterns"""

    def __init__(self, codebase_root: Path):
        self.root = codebase_root
        self.questions: List[Question] = []
        self.context = CodebaseContext()

    def analyze_file(self, file_path: Path) -> List[Question]:
        """Analyze a single file and generate questions"""
        questions = []

        # Determine language
        suffix = file_path.suffix.lower()
        if suffix == '.py':
            questions.extend(self._analyze_python(file_path))
        elif suffix in ['.js', '.ts', '.jsx', '.tsx']:
            questions.extend(self._analyze_javascript(file_path))
        elif suffix in ['.md', '.rst']:
            questions.extend(self._analyze_documentation(file_path))
        else:
            questions.extend(self._analyze_generic(file_path))

        return questions

    def _analyze_python(self, file_path: Path) -> List[Question]:
        """Python-specific analysis using AST"""
        questions = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                tree = ast.parse(content, filename=str(file_path))

            # Pattern 1: Classes without docstrings
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    if not ast.get_docstring(node):
                        questions.append(Question(
                            text=f"What is the responsibility of the '{node.name}' class?",
                            category="Architecture",
                            tier=2,
                            cognitive_level="Understand",
                            file_path=str(file_path),
                            line_number=node.lineno,
                            rationale="Class lacks docstring documentation",
                            priority=7
                        ))

                    # Pattern: Too many methods (God Object?)
                    methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]
                    if len(methods) > 15:
                        questions.append(Question(
                            text=f"Why does '{node.name}' have {len(methods)} methods? Is this a God Object anti-pattern?",
                            category="Design",
                            tier=1,
                            cognitive_level="Evaluate",
                            file_path=str(file_path),
                            line_number=node.lineno,
                            rationale=f"Class has {len(methods)} methods, potential SRP violation",
                            priority=9
                        ))

                # Pattern 2: Functions with too many parameters
                if isinstance(node, ast.FunctionDef):
                    params = len(node.args.args)
                    if params > 5:
                        questions.append(Question(
                            text=f"Why does '{node.name}' need {params} parameters? Could this use a config object?",
                            category="Design",
                            tier=2,
                            cognitive_level="Evaluate",
                            file_path=str(file_path),
                            line_number=node.lineno,
                            rationale=f"Function has {params} parameters, high coupling indicator",
                            priority=6
                        ))

                    # Pattern: Long functions
                    function_lines = self._count_function_lines(node)
                    if function_lines > 50:
                        questions.append(Question(
                            text=f"Why is '{node.name}' {function_lines} lines long? Could it be decomposed?",
                            category="Design",
                            tier=2,
                            cognitive_level="Create",
                            file_path=str(file_path),
                            line_number=node.lineno,
                            rationale=f"Function length ({function_lines} lines) suggests complexity",
                            priority=8
                        ))

                # Pattern 3: Magic numbers
                if isinstance(node, ast.Num):
                    if not self._is_obvious_constant(node.n):
                        questions.append(Question(
                            text=f"Why is the value {node.n} used here? Should this be a named constant?",
                            category="Design",
                            tier=3,
                            cognitive_level="Understand",
                            file_path=str(file_path),
                            line_number=node.lineno,
                            rationale="Magic number detected",
                            priority=4
                        ))

                # Pattern 4: Empty exception handlers
                if isinstance(node, ast.ExceptHandler):
                    if len(node.body) == 1 and isinstance(node.body[0], ast.Pass):
                        questions.append(Question(
                            text="Why is this exception silently caught? What errors are expected here?",
                            category="Architecture",
                            tier=1,
                            cognitive_level="Analyze",
                            file_path=str(file_path),
                            line_number=node.lineno,
                            rationale="Empty exception handler - potential error hiding",
                            priority=10
                        ))

                # Pattern 5: Imports (dependency analysis)
                if isinstance(node, ast.Import) or isinstance(node, ast.ImportFrom):
                    # Track for dependency graph
                    pass

        except SyntaxError as e:
            questions.append(Question(
                text=f"Why does this file have a syntax error? Is it generated code?",
                category="Architecture",
                tier=1,
                cognitive_level="Understand",
                file_path=str(file_path),
                line_number=e.lineno if hasattr(e, 'lineno') else None,
                rationale=f"Syntax error: {e}",
                priority=10
            ))

        # Pattern: File-level patterns
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')

            # TODO/FIXME comments
            for i, line in enumerate(lines, 1):
                if 'TODO' in line or 'FIXME' in line or 'HACK' in line:
                    questions.append(Question(
                        text=f"Why hasn't this TODO/FIXME been addressed? {line.strip()}",
                        category="Technical Debt",
                        tier=2,
                        cognitive_level="Evaluate",
                        file_path=str(file_path),
                        line_number=i,
                        code_context=line.strip(),
                        rationale="Explicit technical debt marker",
                        priority=7
                    ))

            # Very long files
            if len(lines) > 500:
                questions.append(Question(
                    text=f"Why is this file {len(lines)} lines long? Should it be split?",
                    category="Architecture",
                    tier=1,
                    cognitive_level="Evaluate",
                    file_path=str(file_path),
                    rationale=f"File length ({len(lines)} lines) suggests multiple responsibilities",
                    priority=8
                ))

        except Exception as e:
            pass

        return questions

    def _analyze_javascript(self, file_path: Path) -> List[Question]:
        """JavaScript/TypeScript analysis (pattern-based, no AST)"""
        questions = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')

            # Pattern: useState with many state variables
            use_state_count = content.count('useState')
            if use_state_count > 5:
                questions.append(Question(
                    text=f"Why does this component use {use_state_count} separate useState calls? Could useReducer be better?",
                    category="Design",
                    tier=2,
                    cognitive_level="Evaluate",
                    file_path=str(file_path),
                    rationale=f"{use_state_count} useState calls indicates complex state management",
                    priority=7
                ))

            # Pattern: useEffect without dependencies
            if re.search(r'useEffect\([^,]+\)', content):
                questions.append(Question(
                    text="Why is useEffect used without a dependency array? Is this intentional?",
                    category="Design",
                    tier=1,
                    cognitive_level="Analyze",
                    file_path=str(file_path),
                    rationale="useEffect without dependencies runs on every render",
                    priority=9
                ))

            # Pattern: Console.log in production code
            for i, line in enumerate(lines, 1):
                if 'console.log' in line and 'debug' not in line.lower():
                    questions.append(Question(
                        text="Why is console.log present? Should this use a logging framework?",
                        category="Design",
                        tier=3,
                        cognitive_level="Apply",
                        file_path=str(file_path),
                        line_number=i,
                        rationale="console.log in production code",
                        priority=5
                    ))

        except Exception as e:
            pass

        return questions

    def _analyze_documentation(self, file_path: Path) -> List[Question]:
        """Documentation file analysis"""
        questions = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Pattern: Missing sections
            has_quickstart = 'quickstart' in content.lower() or 'quick start' in content.lower()
            has_install = 'install' in content.lower() or 'setup' in content.lower()
            has_examples = 'example' in content.lower()

            if not has_quickstart:
                questions.append(Question(
                    text="Why doesn't this documentation include a quickstart section?",
                    category="Documentation",
                    tier=2,
                    cognitive_level="Apply",
                    file_path=str(file_path),
                    rationale="Missing quickstart guide reduces onboarding speed",
                    priority=6
                ))

        except Exception as e:
            pass

        return questions

    def _analyze_generic(self, file_path: Path) -> List[Question]:
        """Generic analysis for any text file"""
        questions = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Pattern: Very large files
            lines = content.split('\n')
            if len(lines) > 1000:
                questions.append(Question(
                    text=f"Why is this file {len(lines)} lines? Is it generated?",
                    category="Architecture",
                    tier=3,
                    cognitive_level="Understand",
                    file_path=str(file_path),
                    rationale=f"Very large file ({len(lines)} lines)",
                    priority=5
                ))

        except Exception:
            pass

        return questions

    def _count_function_lines(self, node: ast.FunctionDef) -> int:
        """Count lines in a function (excluding decorators)"""
        if hasattr(node, 'end_lineno'):
            return node.end_lineno - node.lineno
        return 0

    def _is_obvious_constant(self, value: float) -> bool:
        """Check if a number is an obvious constant (0, 1, 2, 10, 100, etc.)"""
        return value in [0, 1, 2, 10, 100, 1000]

    def analyze_codebase(self, max_files: int = 100) -> CodebaseContext:
        """Analyze entire codebase for agent contextualization"""

        # Collect all relevant files
        files_to_analyze = []
        for ext in ['.py', '.js', '.ts', '.jsx', '.tsx', '.md', '.rst']:
            files_to_analyze.extend(self.root.rglob(f'*{ext}'))

        # Limit for performance
        files_to_analyze = files_to_analyze[:max_files]

        # Update context
        self.context.total_files = len(files_to_analyze)
        self.context.languages = {f.suffix for f in files_to_analyze}

        # Analyze each file
        all_questions = []
        for file_path in files_to_analyze:
            questions = self.analyze_file(file_path)
            all_questions.extend(questions)

            # Update line count
            try:
                with open(file_path, 'r') as f:
                    self.context.total_lines += len(f.readlines())
            except:
                pass

        # Sort questions by priority
        all_questions.sort(key=lambda q: q.priority, reverse=True)

        # Extract top-tier questions for agent context
        self.context.critical_questions = [q for q in all_questions if q.tier == 1][:20]

        # Identify entry points (files with main, app, index in name)
        for file_path in files_to_analyze:
            if any(keyword in file_path.name.lower() for keyword in ['main', 'app', 'index', '__init__']):
                self.context.entry_points.append(str(file_path))

        # Detect architectural patterns (heuristic)
        all_content = ""
        for file_path in files_to_analyze[:20]:  # Sample first 20 files
            try:
                with open(file_path, 'r') as f:
                    all_content += f.read()
            except:
                pass

        # Pattern detection
        if 'class.*Model' in all_content or 'BaseModel' in all_content:
            self.context.architectural_patterns.append("MVC/Model-based architecture")
        if 'useState' in all_content or 'useEffect' in all_content:
            self.context.architectural_patterns.append("React Hooks pattern")
        if 'async def' in all_content or 'asyncio' in all_content:
            self.context.architectural_patterns.append("Async/Await pattern")
        if 'Bridge' in all_content or 'bridge/' in str(self.root):
            self.context.architectural_patterns.append("Bridge communication pattern")

        self.questions = all_questions
        return self.context

    def generate_agent_context(self, top_n: int = 20) -> str:
        """Generate agent contextualization output (JITS TIER1)"""

        output = []
        output.append("# Agent Contextualization: Architecture Questions")
        output.append("")
        output.append("## Codebase Overview")
        output.append("")
        output.append(f"- **Total Files**: {self.context.total_files}")
        output.append(f"- **Total Lines**: {self.context.total_lines:,}")
        output.append(f"- **Languages**: {', '.join(self.context.languages)}")
        output.append(f"- **Entry Points**: {len(self.context.entry_points)}")
        output.append("")

        if self.context.entry_points:
            output.append("### Entry Points")
            for ep in self.context.entry_points[:5]:
                output.append(f"- `{ep}`")
            output.append("")

        if self.context.architectural_patterns:
            output.append("### Detected Patterns")
            for pattern in self.context.architectural_patterns:
                output.append(f"- {pattern}")
            output.append("")

        output.append("## Critical Architectural Questions (TIER 1)")
        output.append("")
        output.append("**Purpose**: Rapidly understand key design decisions")
        output.append("")

        critical_questions = [q for q in self.questions if q.tier == 1][:top_n]

        for i, q in enumerate(critical_questions, 1):
            output.append(f"### Q{i}: {q.text}")
            output.append("")
            output.append(f"- **Category**: {q.category}")
            output.append(f"- **Location**: `{q.file_path}:{q.line_number or '?'}`")
            output.append(f"- **Rationale**: {q.rationale}")
            output.append(f"- **Cognitive Level**: {q.cognitive_level}")
            output.append("")

        output.append("---")
        output.append("")
        output.append("## Next Steps for Agent")
        output.append("")
        output.append("1. **Read entry points** to understand execution flow")
        output.append("2. **Answer TIER1 questions** through code exploration")
        output.append("3. **Generate TIER2 questions** for deeper modules")
        output.append("4. **Document findings** in knowledge base")
        output.append("")

        return '\n'.join(output)

    def generate_full_report(self, output_format: str = "markdown") -> str:
        """Generate comprehensive question report (TIER 2-4)"""

        output = []
        output.append("# Code Architecture Questions - Full Report")
        output.append("")
        output.append(f"**Generated for**: `{self.root}`")
        output.append(f"**Total Questions**: {len(self.questions)}")
        output.append("")

        # Group by tier
        by_tier = defaultdict(list)
        for q in self.questions:
            by_tier[q.tier].append(q)

        for tier in sorted(by_tier.keys()):
            tier_name = {
                1: "TIER 1: Critical Architecture",
                2: "TIER 2: Important Design",
                3: "TIER 3: Detailed Implementation",
                4: "TIER 4: Historical Context"
            }.get(tier, f"TIER {tier}")

            output.append(f"## {tier_name}")
            output.append("")
            output.append(f"**Count**: {len(by_tier[tier])}")
            output.append("")

            # Group by category
            by_category = defaultdict(list)
            for q in by_tier[tier]:
                by_category[q.category].append(q)

            for category in sorted(by_category.keys()):
                output.append(f"### {category}")
                output.append("")

                for q in by_category[category]:
                    output.append(f"**Q**: {q.text}")
                    output.append(f"- Location: `{q.file_path}:{q.line_number or '?'}`")
                    if q.code_context:
                        output.append(f"- Context: `{q.code_context}`")
                    output.append("")

        return '\n'.join(output)


def main():
    parser = argparse.ArgumentParser(
        description="Code Architecture Question Tool (CAQT)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Agent contextualization (quick startup)
  %(prog)s /path/to/project --mode agent-context

  # Full analysis
  %(prog)s /path/to/project --mode full-report

  # Specific tier
  %(prog)s /path/to/project --tier 1
        """
    )

    parser.add_argument('path', type=str, help='File or directory to analyze')
    parser.add_argument('--mode', choices=['agent-context', 'full-report', 'json'],
                        default='agent-context', help='Output mode')
    parser.add_argument('--tier', type=int, choices=[1, 2, 3, 4],
                        help='Filter by specificity tier')
    parser.add_argument('--top', type=int, default=20,
                        help='Number of top questions for agent context')
    parser.add_argument('--output', type=str, help='Output file (default: stdout)')

    args = parser.parse_args()

    # Validate path
    path = Path(args.path)
    if not path.exists():
        print(f"Error: Path does not exist: {path}", file=sys.stderr)
        sys.exit(1)

    # Determine if file or directory
    if path.is_file():
        # Single file analysis
        generator = QuestionGenerator(path.parent)
        questions = generator.analyze_file(path)
        generator.questions = questions
    else:
        # Directory analysis
        generator = QuestionGenerator(path)
        generator.analyze_codebase()

    # Filter by tier if specified
    if args.tier:
        generator.questions = [q for q in generator.questions if q.tier == args.tier]

    # Generate output
    if args.mode == 'agent-context':
        output_text = generator.generate_agent_context(top_n=args.top)
    elif args.mode == 'full-report':
        output_text = generator.generate_full_report()
    elif args.mode == 'json':
        questions_dict = [
            {
                'text': q.text,
                'category': q.category,
                'tier': q.tier,
                'cognitive_level': q.cognitive_level,
                'file_path': q.file_path,
                'line_number': q.line_number,
                'priority': q.priority,
                'rationale': q.rationale
            }
            for q in generator.questions
        ]
        output_text = json.dumps(questions_dict, indent=2)

    # Write output
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output_text)
        print(f"Output written to: {args.output}", file=sys.stderr)
    else:
        print(output_text)


if __name__ == '__main__':
    main()
