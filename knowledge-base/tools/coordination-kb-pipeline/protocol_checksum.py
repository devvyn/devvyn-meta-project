#!/usr/bin/env python3
"""
Calculate checksum of coordination protocol corpus
Provides grounding reference for self-referential claims
"""

import hashlib
from pathlib import Path

def calculate_corpus_checksum(doc_list_file):
    """
    Calculate SHA256 hash of entire coordination document corpus

    Args:
        doc_list_file: Path to coordination_docs.txt

    Returns:
        tuple: (checksum_hex, file_count, total_bytes)
    """
    hasher = hashlib.sha256()
    file_count = 0
    total_bytes = 0

    # Read document list
    with open(doc_list_file, 'r') as f:
        doc_paths = [line.strip() for line in f if line.strip() and not line.startswith('#')]

    # Sort for deterministic order
    doc_paths.sort()

    # Hash each document in order
    for doc_path in doc_paths:
        try:
            with open(doc_path, 'rb') as f:
                content = f.read()
                hasher.update(content)
                total_bytes += len(content)
                file_count += 1
        except Exception as e:
            print(f"Warning: Could not read {doc_path}: {e}")

    return hasher.hexdigest(), file_count, total_bytes

def main():
    import sys

    script_dir = Path(__file__).parent
    doc_list_file = script_dir / "coordination_docs.txt"

    if not doc_list_file.exists():
        print(f"Error: {doc_list_file} not found", file=sys.stderr)
        sys.exit(1)

    checksum, file_count, total_bytes = calculate_corpus_checksum(doc_list_file)

    print(f"Coordination Protocol Corpus Checksum")
    print(f"=====================================")
    print(f"SHA256: {checksum}")
    print(f"Files:  {file_count}")
    print(f"Bytes:  {total_bytes:,}")
    print()
    print(f"Short form: sha256:{checksum[:16]}...")

if __name__ == '__main__':
    main()
