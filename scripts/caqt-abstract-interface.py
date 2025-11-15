#!/usr/bin/env python3
"""
Abstract Question Generation Interface
Abstraction layer for applying questioning pattern to any domain

Philosophy: "Perhaps abstraction can help"
- Generic interface for question generation
- Domain-specific implementations
- Extensible to code, data, systems, documents, etc.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List, Any, Optional
from enum import Enum


class CognitiveLevel(Enum):
    """Bloom's Taxonomy levels"""
    REMEMBER = "Remember"      # What is X?
    UNDERSTAND = "Understand"  # Why is X?
    APPLY = "Apply"           # How to use X?
    ANALYZE = "Analyze"       # What are X's parts?
    EVALUATE = "Evaluate"     # What are tradeoffs of X?
    CREATE = "Create"         # How else could X work?


class QuestionCategory(Enum):
    """Abstract question categories (domain-independent)"""
    STRUCTURE = "Structure"           # How is it organized?
    PURPOSE = "Purpose"               # Why does it exist?
    DEPENDENCY = "Dependency"         # What does it need?
    BOUNDARY = "Boundary"             # What are limits/constraints?
    PERFORMANCE = "Performance"       # How efficient?
    QUALITY = "Quality"               # How good?
    EVOLUTION = "Evolution"           # How did it change?
    ALTERNATIVE = "Alternative"       # What else could work?


@dataclass
class Question:
    """Universal question representation"""
    text: str                           # The question itself
    category: QuestionCategory          # Abstract category
    tier: int                           # 1=Critical, 2=Important, 3=Detailed, 4=Historical
    cognitive_level: CognitiveLevel     # Bloom's taxonomy
    source_location: str                # Where in target this applies
    rationale: str                      # Why this question was generated
    priority: int = 0                   # Higher = more critical
    context: Optional[str] = None       # Additional context
    metadata: dict = None               # Domain-specific data

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


@dataclass
class TargetContext:
    """Universal context about analyzed target"""
    target_type: str                    # "codebase", "dataset", "system", etc.
    target_identifier: str              # Path, URL, name, etc.
    summary_stats: dict                 # Domain-specific statistics
    entry_points: List[str]             # Starting points for exploration
    patterns: List[str]                 # Detected patterns/structures
    critical_questions: List[Question]  # Top-priority questions


class QuestionGenerator(ABC):
    """Abstract base class for question generation"""

    @abstractmethod
    def analyze(self, target: Any) -> List[Question]:
        """
        Analyze target and generate questions

        Args:
            target: The thing to analyze (file, URL, object, etc.)

        Returns:
            List of questions ordered by priority
        """
        pass

    @abstractmethod
    def generate_context(self, target: Any) -> TargetContext:
        """
        Generate high-level context about target

        Args:
            target: The thing to analyze

        Returns:
            Context object with overview and critical questions
        """
        pass

    def filter_by_tier(self, questions: List[Question], tier: int) -> List[Question]:
        """Filter questions to specific tier"""
        return [q for q in questions if q.tier == tier]

    def filter_by_category(self, questions: List[Question], category: QuestionCategory) -> List[Question]:
        """Filter questions by category"""
        return [q for q in questions if q.category == category]

    def top_n(self, questions: List[Question], n: int) -> List[Question]:
        """Get top N questions by priority"""
        sorted_questions = sorted(questions, key=lambda q: q.priority, reverse=True)
        return sorted_questions[:n]


# Example concrete implementation for code
class CodeQuestionGenerator(QuestionGenerator):
    """
    Generate questions about source code
    See: scripts/caqt-generate.py for full implementation
    """

    def analyze(self, target: Any) -> List[Question]:
        """Analyze code file/directory"""
        # Implementation in caqt-generate.py
        questions = []

        # Example pattern: Detect long functions
        if self._is_function_too_long(target):
            questions.append(Question(
                text="Why is this function so long? Could it be decomposed?",
                category=QuestionCategory.STRUCTURE,
                tier=2,
                cognitive_level=CognitiveLevel.EVALUATE,
                source_location=str(target),
                rationale="Function length exceeds maintainability threshold",
                priority=8
            ))

        return questions

    def generate_context(self, target: Any) -> TargetContext:
        """Generate code context"""
        # Implementation in caqt-generate.py
        return TargetContext(
            target_type="codebase",
            target_identifier=str(target),
            summary_stats={"files": 0, "lines": 0},
            entry_points=[],
            patterns=[],
            critical_questions=[]
        )

    def _is_function_too_long(self, target) -> bool:
        """Example pattern detector"""
        return False  # Simplified


# Example concrete implementation for datasets
class DatasetQuestionGenerator(QuestionGenerator):
    """Generate questions about datasets (CSV, JSON, database, etc.)"""

    def analyze(self, target: Any) -> List[Question]:
        """Analyze dataset"""
        questions = []

        # Pattern 1: Missing data
        missing_pct = self._calculate_missing_percentage(target)
        if missing_pct > 0.1:  # >10% missing
            questions.append(Question(
                text=f"Why are {missing_pct*100:.1f}% of values missing? Is this expected?",
                category=QuestionCategory.QUALITY,
                tier=1,
                cognitive_level=CognitiveLevel.ANALYZE,
                source_location=str(target),
                rationale=f"High missing data percentage ({missing_pct*100:.1f}%)",
                priority=9
            ))

        # Pattern 2: Suspicious distributions
        if self._has_suspicious_distribution(target):
            questions.append(Question(
                text="Why is the data distribution skewed? Is this natural or a collection bias?",
                category=QuestionCategory.QUALITY,
                tier=2,
                cognitive_level=CognitiveLevel.EVALUATE,
                source_location=str(target),
                rationale="Non-normal distribution detected",
                priority=7
            ))

        # Pattern 3: Temporal gaps
        if self._has_temporal_gaps(target):
            questions.append(Question(
                text="Why are there gaps in the date range? Were certain periods not collected?",
                category=QuestionCategory.BOUNDARY,
                tier=2,
                cognitive_level=CognitiveLevel.UNDERSTAND,
                source_location=str(target),
                rationale="Temporal discontinuities detected",
                priority=8
            ))

        return questions

    def generate_context(self, target: Any) -> TargetContext:
        """Generate dataset context"""
        return TargetContext(
            target_type="dataset",
            target_identifier=str(target),
            summary_stats={
                "rows": self._count_rows(target),
                "columns": self._count_columns(target),
                "missing_pct": self._calculate_missing_percentage(target),
                "date_range": self._get_date_range(target)
            },
            entry_points=["First row", "Summary statistics", "Schema"],
            patterns=self._detect_patterns(target),
            critical_questions=self.top_n(self.analyze(target), 20)
        )

    def _calculate_missing_percentage(self, target) -> float:
        """Calculate % of missing values"""
        return 0.0  # Simplified

    def _has_suspicious_distribution(self, target) -> bool:
        """Detect unusual distributions"""
        return False  # Simplified

    def _has_temporal_gaps(self, target) -> bool:
        """Detect gaps in time series"""
        return False  # Simplified

    def _count_rows(self, target) -> int:
        return 0

    def _count_columns(self, target) -> int:
        return 0

    def _get_date_range(self, target) -> str:
        return ""

    def _detect_patterns(self, target) -> List[str]:
        return []


# Example concrete implementation for systems
class SystemQuestionGenerator(QuestionGenerator):
    """Generate questions about deployed systems/infrastructure"""

    def analyze(self, target: Any) -> List[Question]:
        """Analyze system configuration/deployment"""
        questions = []

        # Pattern 1: Single point of failure
        if self._has_single_point_of_failure(target):
            questions.append(Question(
                text="Why is there no redundancy for this component? What happens if it fails?",
                category=QuestionCategory.BOUNDARY,
                tier=1,
                cognitive_level=CognitiveLevel.ANALYZE,
                source_location=str(target),
                rationale="Single point of failure detected",
                priority=10
            ))

        # Pattern 2: Resource limits
        if self._has_resource_constraints(target):
            questions.append(Question(
                text="Why these specific resource limits? What happens under peak load?",
                category=QuestionCategory.PERFORMANCE,
                tier=2,
                cognitive_level=CognitiveLevel.EVALUATE,
                source_location=str(target),
                rationale="Resource constraints may limit scalability",
                priority=8
            ))

        return questions

    def generate_context(self, target: Any) -> TargetContext:
        """Generate system context"""
        return TargetContext(
            target_type="system",
            target_identifier=str(target),
            summary_stats={
                "components": self._count_components(target),
                "dependencies": self._count_dependencies(target),
                "redundancy": self._has_redundancy(target)
            },
            entry_points=["Main service", "API gateway", "Load balancer"],
            patterns=["Microservices", "Event-driven", "REST API"],
            critical_questions=self.top_n(self.analyze(target), 20)
        )

    def _has_single_point_of_failure(self, target) -> bool:
        return False

    def _has_resource_constraints(self, target) -> bool:
        return False

    def _count_components(self, target) -> int:
        return 0

    def _count_dependencies(self, target) -> int:
        return 0

    def _has_redundancy(self, target) -> bool:
        return False


# Factory pattern for easy instantiation
class QuestionGeneratorFactory:
    """Factory for creating appropriate question generator"""

    _generators = {
        'code': CodeQuestionGenerator,
        'dataset': DatasetQuestionGenerator,
        'system': SystemQuestionGenerator,
    }

    @classmethod
    def create(cls, domain: str) -> QuestionGenerator:
        """
        Create question generator for domain

        Args:
            domain: One of 'code', 'dataset', 'system', etc.

        Returns:
            Appropriate QuestionGenerator instance
        """
        generator_class = cls._generators.get(domain)
        if not generator_class:
            raise ValueError(f"Unknown domain: {domain}. Available: {list(cls._generators.keys())}")
        return generator_class()

    @classmethod
    def register(cls, domain: str, generator_class: type):
        """Register custom generator for new domain"""
        cls._generators[domain] = generator_class


# Example: Extending to new domain
class DocumentQuestionGenerator(QuestionGenerator):
    """Generate questions about documentation/writing"""

    def analyze(self, target: Any) -> List[Question]:
        questions = []

        # Pattern: Missing sections
        if not self._has_quickstart(target):
            questions.append(Question(
                text="Why doesn't this document have a quickstart section?",
                category=QuestionCategory.STRUCTURE,
                tier=2,
                cognitive_level=CognitiveLevel.APPLY,
                source_location=str(target),
                rationale="Missing quickstart reduces onboarding speed",
                priority=7
            ))

        return questions

    def generate_context(self, target: Any) -> TargetContext:
        return TargetContext(
            target_type="document",
            target_identifier=str(target),
            summary_stats={"sections": 0, "words": 0},
            entry_points=["Table of contents"],
            patterns=["Tutorial", "Reference", "Explanation"],
            critical_questions=self.top_n(self.analyze(target), 10)
        )

    def _has_quickstart(self, target) -> bool:
        return False


# Register custom generator
QuestionGeneratorFactory.register('document', DocumentQuestionGenerator)


# Usage example
if __name__ == '__main__':
    # Use factory to create generator
    code_gen = QuestionGeneratorFactory.create('code')
    dataset_gen = QuestionGeneratorFactory.create('dataset')
    system_gen = QuestionGeneratorFactory.create('system')
    doc_gen = QuestionGeneratorFactory.create('document')

    # Generate questions for different domains
    print("Code questions:", code_gen.analyze("src/main.py"))
    print("Dataset questions:", dataset_gen.analyze("data/specimens.csv"))
    print("System questions:", system_gen.analyze("infrastructure/k8s/"))
    print("Document questions:", doc_gen.analyze("README.md"))
