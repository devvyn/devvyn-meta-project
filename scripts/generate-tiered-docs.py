#!/usr/bin/env python3
"""
generate-tiered-docs.py - Generate summary and full versions from tier-marked markdown

Usage:
    generate-tiered-docs.py <input.md>

Expects tier markers in markdown:
    ## Section Name [TIER1]
    ## Section Name [TIER2]
    ## Section Name [TIER3]

Generates:
    input.summary.md - TIER1 + TIER2 content only
    input.full.md - All content (TIER1 + TIER2 + TIER3)
"""

import sys
import re
from pathlib import Path

def parse_tiered_markdown(content: str):
    """
    Parse markdown content and extract sections by tier.
    Returns: {1: [...], 2: [...], 3: [...], None: [...]}
    """
    lines = content.split('\n')
    sections = {1: [], 2: [], 3: [], None: []}
    current_tier = None
    current_section = []

    tier_pattern = re.compile(r'^##\s+(.+?)\s+\[TIER([123])\]')
    section_pattern = re.compile(r'^##\s+')

    for line in lines:
        tier_match = tier_pattern.match(line)

        if tier_match:
            # Save previous section
            if current_section:
                sections[current_tier].extend(current_section)
                current_section = []

            # Start new tiered section
            section_name = tier_match.group(1)
            current_tier = int(tier_match.group(2))
            current_section.append(f"## {section_name}")

        elif section_pattern.match(line):
            # Save previous section
            if current_section:
                sections[current_tier].extend(current_section)
                current_section = []

            # Start new un-tiered section
            current_tier = None
            current_section.append(line)

        else:
            current_section.append(line)

    # Save last section
    if current_section:
        sections[current_tier].extend(current_section)

    return sections

def generate_summary(sections):
    """Generate summary (TIER1 + TIER2 only)"""
    summary = []

    # Add un-tiered content (usually header, orientation)
    if sections[None]:
        summary.extend(sections[None])

    # Add TIER1
    if sections[1]:
        summary.extend(sections[1])

    # Add TIER2
    if sections[2]:
        summary.extend(sections[2])

    # Add reference note if TIER3 exists
    if sections[3]:
        summary.append('')
        summary.append('---')
        summary.append('')
        summary.append('*For detailed examples, templates, and reference material, see the .full.md version of this document.*')

    return '\n'.join(summary)

def generate_full(sections):
    """Generate full document (all tiers)"""
    full = []

    # Add all content in order
    if sections[None]:
        full.extend(sections[None])

    if sections[1]:
        full.extend(sections[1])

    if sections[2]:
        full.extend(sections[2])

    if sections[3]:
        full.append('')
        full.append('---')
        full.append('')
        full.append('## Reference Material [TIER3]')
        full.append('')
        full.extend(sections[3])

    return '\n'.join(full)

def main():
    if len(sys.argv) < 2:
        print("Usage: generate-tiered-docs.py <input.md>")
        sys.exit(1)

    input_path = Path(sys.argv[1])

    if not input_path.exists():
        print(f"Error: File '{input_path}' not found")
        sys.exit(1)

    # Read input
    content = input_path.read_text()

    # Parse tiers
    sections = parse_tiered_markdown(content)

    # Calculate stats
    total_lines = sum(len(s) for s in sections.values())
    tier1_lines = len(sections[1])
    tier2_lines = len(sections[2])
    tier3_lines = len(sections[3])
    untier_lines = len(sections[None]) if sections[None] else 0
    summary_lines = untier_lines + tier1_lines + tier2_lines

    compression_pct = 100 * (1 - summary_lines / total_lines) if total_lines > 0 else 0

    # Generate outputs
    summary = generate_summary(sections)
    full = generate_full(sections)

    # Write files
    summary_path = input_path.with_suffix('.summary.md')
    full_path = input_path.with_suffix('.full.md')

    summary_path.write_text(summary)
    full_path.write_text(full)

    # Report
    print(f"✓ Generated tiered documents from {input_path.name}")
    print(f"")
    print(f"Content distribution:")
    print(f"  Un-tiered: {untier_lines} lines")
    print(f"  TIER1: {tier1_lines} lines")
    print(f"  TIER2: {tier2_lines} lines")
    print(f"  TIER3: {tier3_lines} lines")
    print(f"  Total: {total_lines} lines")
    print(f"")
    print(f"Generated files:")
    print(f"  Summary: {summary_path} ({summary_lines} lines, {compression_pct:.0f}% compression)")
    print(f"  Full: {full_path} ({total_lines} lines)")

    if tier3_lines == 0:
        print(f"")
        print(f"⚠️  No TIER3 markers found. Add [TIER3] to sections with examples/templates.")

if __name__ == '__main__':
    main()
