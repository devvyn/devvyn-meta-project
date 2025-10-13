#!/usr/bin/env python3
"""
Query Audit Script - Analyzes coordination KB query logs
Measures: query drift, vocabulary entropy, temporal patterns

Part of: Coordination KB Pipeline (Recommendation #2)
"""

import json
import math
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any


def load_query_log(log_file: Path) -> list[dict[str, Any]]:
    """Load queries from JSONL log"""
    queries: list[dict[str, Any]] = []
    if not log_file.exists():
        return queries

    with log_file.open() as f:
        for line in f:
            try:
                queries.append(json.loads(line.strip()))
            except json.JSONDecodeError:
                pass

    return queries


def calculate_entropy(distribution: dict[str, int]) -> float:
    """Calculate Shannon entropy of a distribution"""
    total = sum(distribution.values())
    if total == 0:
        return 0.0

    entropy = 0.0
    for count in distribution.values():
        if count > 0:
            p = count / total
            entropy -= p * math.log2(p)

    return entropy


def tokenize_query(query: str) -> list[str]:
    """Simple tokenization for query analysis"""
    import re

    query = query.lower()
    return re.findall(r"\b\w+\b", query)


def analyze_queries(queries: list[dict[str, Any]]) -> dict[str, Any]:
    """Analyze query patterns and drift"""
    if not queries:
        return {"error": "No queries to analyze"}

    # Temporal analysis
    timestamps = [datetime.fromisoformat(q["timestamp"]) for q in queries]
    first_query = min(timestamps)
    last_query = max(timestamps)
    time_span_days = (last_query - first_query).total_seconds() / 86400

    # Vocabulary analysis
    all_tokens = []
    query_texts = []
    for q in queries:
        tokens = tokenize_query(q["query"])
        all_tokens.extend(tokens)
        query_texts.append(q["query"])

    # Calculate metrics
    vocabulary = set(all_tokens)
    token_freq = Counter(all_tokens)
    vocabulary_entropy = calculate_entropy(token_freq)

    # Agent distribution
    agent_dist = Counter(q.get("origin_agent", "unknown") for q in queries)

    # Latency stats
    latencies = [q["query_latency_ms"] for q in queries if "query_latency_ms" in q]
    avg_latency = sum(latencies) / len(latencies) if latencies else 0

    # Result quality (average score of top result)
    top_scores = []
    for q in queries:
        if q.get("top_results") and len(q["top_results"]) > 0:
            top_scores.append(q["top_results"][0]["score"])
    avg_top_score = sum(top_scores) / len(top_scores) if top_scores else 0

    # Query drift detection (change in vocabulary over time)
    # Split into early/late halves
    mid_point = len(queries) // 2
    early_tokens = []
    late_tokens = []
    for i, q in enumerate(queries):
        tokens = tokenize_query(q["query"])
        if i < mid_point:
            early_tokens.extend(tokens)
        else:
            late_tokens.extend(tokens)

    early_vocab = set(early_tokens)
    late_vocab = set(late_tokens)
    vocab_overlap = len(early_vocab & late_vocab)
    vocab_drift = 1.0 - (vocab_overlap / len(vocabulary)) if vocabulary else 0.0

    # Most common queries
    query_freq = Counter(query_texts)
    top_queries = query_freq.most_common(10)

    # Most common terms
    top_terms = token_freq.most_common(20)

    return {
        "summary": {
            "total_queries": len(queries),
            "time_span_days": round(time_span_days, 2),
            "unique_queries": len(set(query_texts)),
            "query_repetition_rate": round(
                1.0 - len(set(query_texts)) / len(queries), 3
            ),
            "vocabulary_size": len(vocabulary),
            "vocabulary_entropy": round(vocabulary_entropy, 3),
            "vocab_drift_score": round(vocab_drift, 3),
            "avg_latency_ms": round(avg_latency, 1),
            "avg_top_result_score": round(avg_top_score, 3),
        },
        "agent_distribution": dict(agent_dist),
        "top_queries": top_queries,
        "top_terms": top_terms[:10],  # Limit to 10 for display
        "first_query": first_query.isoformat(),
        "last_query": last_query.isoformat(),
    }


def main() -> None:
    import sys

    log_file = Path(__file__).parent / "coordination_queries.jsonl"

    if not log_file.exists():
        print(f"No query log found at {log_file}")
        print("Run some queries first to generate audit data")
        sys.exit(1)

    print(f"Analyzing query log: {log_file}")
    print("=" * 80)

    queries = load_query_log(log_file)
    analysis = analyze_queries(queries)

    if "error" in analysis:
        print(f"Error: {analysis['error']}")
        sys.exit(1)

    # Display results
    print("\n📊 QUERY AUDIT SUMMARY")
    print("-" * 80)
    for key, value in analysis["summary"].items():
        print(f"{key:30s}: {value}")

    print("\n🤖 AGENT DISTRIBUTION")
    print("-" * 80)
    for agent, count in sorted(
        analysis["agent_distribution"].items(), key=lambda x: -x[1]
    ):
        percentage = (count / analysis["summary"]["total_queries"]) * 100
        print(f"{agent:20s}: {count:4d} ({percentage:5.1f}%)")

    print("\n🔥 TOP QUERIES")
    print("-" * 80)
    for i, (query, count) in enumerate(analysis["top_queries"], 1):
        print(f"{i:2d}. [{count:2d}x] {query[:70]}")

    print("\n📚 TOP TERMS")
    print("-" * 80)
    for term, count in analysis["top_terms"]:
        print(f"{term:20s}: {count:4d}")

    print("\n⚠️  HEALTH INDICATORS")
    print("-" * 80)

    # Interpret metrics
    summary = analysis["summary"]

    if summary["query_repetition_rate"] > 0.5:
        print("⚠️  HIGH: Query repetition rate suggests caching opportunity")

    if summary["vocab_drift_score"] > 0.5:
        print("⚠️  HIGH: Vocabulary drift indicates evolving query patterns")
    elif summary["vocab_drift_score"] > 0.3:
        print("⚡ MODERATE: Vocabulary showing some drift")
    else:
        print("✓ LOW: Vocabulary is stable")

    if summary["avg_latency_ms"] > 1000:
        print("⚠️  HIGH: Average latency exceeds 1 second")
    elif summary["avg_latency_ms"] > 500:
        print("⚡ MODERATE: Latency acceptable but could be optimized")
    else:
        print("✓ GOOD: Latency is fast")

    if summary["avg_top_result_score"] < 0.3:
        print("⚠️  LOW: Average result scores suggest poor retrieval quality")
    elif summary["avg_top_result_score"] < 0.5:
        print("⚡ MODERATE: Result quality could be improved")
    else:
        print("✓ GOOD: Result quality is strong")

    print("\n" + "=" * 80)
    print(f"Audit complete: {analysis['summary']['total_queries']} queries analyzed")
    print(f"Time span: {analysis['first_query'][:10]} to {analysis['last_query'][:10]}")


if __name__ == "__main__":
    main()
