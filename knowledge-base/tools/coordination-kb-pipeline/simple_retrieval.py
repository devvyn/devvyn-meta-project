#!/usr/bin/env python3
"""
Simple coordination knowledge base retrieval system
Uses TF-IDF for document similarity (no heavy dependencies)
"""

import json
import re
from pathlib import Path
from collections import Counter
import math
import time
from datetime import datetime, timezone

class SimpleRetrieval:
    def __init__(self, docs_dir, enable_logging=True):
        self.docs_dir = Path(docs_dir)
        self.documents = {}
        self.idf = {}
        self.doc_vectors = {}
        self.enable_logging = enable_logging
        self.log_file = self.docs_dir / "coordination_queries.jsonl"

    def tokenize(self, text):
        """Simple tokenization"""
        text = text.lower()
        # Remove markdown formatting
        text = re.sub(r'[#*`\[\]()_-]', ' ', text)
        # Split on whitespace and punctuation
        tokens = re.findall(r'\b\w+\b', text)
        return tokens

    def load_documents(self, file_list):
        """Load documents from file paths"""
        print(f"Loading {len(file_list)} documents...")
        for file_path in file_list:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    doc_id = Path(file_path).stem
                    self.documents[doc_id] = {
                        'path': file_path,
                        'content': content,
                        'tokens': self.tokenize(content)
                    }
            except Exception as e:
                print(f"Error loading {file_path}: {e}")

        print(f"Loaded {len(self.documents)} documents")
        return len(self.documents)

    def build_index(self):
        """Build TF-IDF index"""
        print("Building TF-IDF index...")

        # Calculate IDF
        doc_count = len(self.documents)
        term_doc_count = Counter()

        for doc_id, doc in self.documents.items():
            unique_tokens = set(doc['tokens'])
            for token in unique_tokens:
                term_doc_count[token] += 1

        # Calculate IDF scores
        for term, count in term_doc_count.items():
            self.idf[term] = math.log(doc_count / count)

        # Calculate TF-IDF vectors for each document
        for doc_id, doc in self.documents.items():
            term_freq = Counter(doc['tokens'])
            total_terms = len(doc['tokens'])

            vector = {}
            for term, freq in term_freq.items():
                tf = freq / total_terms
                vector[term] = tf * self.idf.get(term, 0)

            self.doc_vectors[doc_id] = vector

        print(f"Index built with {len(self.idf)} unique terms")

    def query(self, query_text, top_k=5):
        """Query the knowledge base"""
        query_tokens = self.tokenize(query_text)
        query_freq = Counter(query_tokens)
        total_query_terms = len(query_tokens)

        # Build query vector
        query_vector = {}
        for term, freq in query_freq.items():
            tf = freq / total_query_terms
            query_vector[term] = tf * self.idf.get(term, 0)

        # Calculate cosine similarity with each document
        scores = {}
        for doc_id, doc_vector in self.doc_vectors.items():
            score = self.cosine_similarity(query_vector, doc_vector)
            if score > 0:
                scores[doc_id] = score

        # Sort by score
        ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:top_k]

        # Return results with excerpts
        results = []
        for doc_id, score in ranked:
            doc = self.documents[doc_id]
            # Get excerpt (first 200 chars)
            excerpt = doc['content'][:200].replace('\n', ' ')
            results.append({
                'doc_id': doc_id,
                'path': doc['path'],
                'score': score,
                'excerpt': excerpt
            })

        return results

    def cosine_similarity(self, vec1, vec2):
        """Calculate cosine similarity between two vectors"""
        # Get common terms
        common_terms = set(vec1.keys()) & set(vec2.keys())
        if not common_terms:
            return 0.0

        # Calculate dot product
        dot_product = sum(vec1[term] * vec2[term] for term in common_terms)

        # Calculate magnitudes
        mag1 = math.sqrt(sum(v**2 for v in vec1.values()))
        mag2 = math.sqrt(sum(v**2 for v in vec2.values()))

        if mag1 == 0 or mag2 == 0:
            return 0.0

        return dot_product / (mag1 * mag2)

    def get_version_info(self):
        """Get pipeline version and protocol checksum"""
        version = "unknown"
        version_file = self.docs_dir / "VERSION"
        if version_file.exists():
            version = version_file.read_text().strip()

        # Calculate protocol checksum
        checksum = "unknown"
        try:
            from protocol_checksum import calculate_corpus_checksum
            doc_list = self.docs_dir / "coordination_docs.txt"
            if doc_list.exists():
                checksum_hex, _, _ = calculate_corpus_checksum(doc_list)
                checksum = f"sha256:{checksum_hex[:16]}..."
        except Exception:
            pass

        return version, checksum

    def log_query(self, query_text, results, latency_ms, origin_agent="unknown"):
        """Log query event to JSONL file"""
        if not self.enable_logging:
            return

        version, checksum = self.get_version_info()

        event = {
            "event": "coordination_kb_query",
            "query": query_text,
            "top_results": [
                {
                    "doc_id": r["doc_id"],
                    "score": round(r["score"], 4),
                    "rank": i + 1
                }
                for i, r in enumerate(results[:5])
            ],
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "origin_agent": origin_agent,
            "pipeline_version": version,
            "protocol_checksum": checksum,
            "query_latency_ms": latency_ms,
            "result_count": len(results)
        }

        # Append to JSONL log
        try:
            with open(self.log_file, 'a') as f:
                f.write(json.dumps(event) + '\n')
        except Exception as e:
            print(f"Warning: Could not log query: {e}", file=sys.stderr)

def main():
    import sys

    if len(sys.argv) < 2:
        print("Usage: simple_retrieval.py <query>")
        print("Example: simple_retrieval.py 'coordination patterns'")
        sys.exit(1)

    query = ' '.join(sys.argv[1:])

    # Load document list
    docs_file = Path(__file__).parent / "coordination_docs.txt"
    if not docs_file.exists():
        print(f"Error: {docs_file} not found")
        sys.exit(1)

    with open(docs_file) as f:
        doc_paths = [line.strip() for line in f if line.strip() and not line.startswith('#')]

    # Initialize retrieval system
    retrieval = SimpleRetrieval(Path(__file__).parent)
    retrieval.load_documents(doc_paths)
    retrieval.build_index()

    # Query with timing
    print(f"\nQuery: {query}")
    print("=" * 80)

    start_time = time.time()
    results = retrieval.query(query)
    latency_ms = int((time.time() - start_time) * 1000)

    # Log query
    retrieval.log_query(query, results, latency_ms, origin_agent="code")

    if not results:
        print("No results found")
    else:
        for i, result in enumerate(results, 1):
            print(f"\n{i}. {result['doc_id']} (score: {result['score']:.4f})")
            print(f"   Path: {result['path']}")
            print(f"   Excerpt: {result['excerpt']}...")

    print(f"\n[Query logged to {retrieval.log_file}]")

if __name__ == '__main__':
    main()
