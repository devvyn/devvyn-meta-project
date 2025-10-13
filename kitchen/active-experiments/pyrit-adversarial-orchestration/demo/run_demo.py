#!/usr/bin/env python3
"""
Standalone demo of PyRIT Bridge Adapter
Shows adversarial testing workflow without external dependencies
"""

import asyncio
import sys
from pathlib import Path

# Add bridge-adapter to path
sys.path.insert(0, str(Path(__file__).parent.parent / "bridge-adapter"))

from pyrit_bridge_adapter import PyRITBridgeAdapter


async def main():
    print("=" * 80)
    print("PyRIT Bridge Adapter - Adversarial Orchestration Demo")
    print("=" * 80)
    print()
    print("This demonstrates how PyRIT can challenge agent proposals")
    print("via your existing bridge message-passing system.")
    print()

    # Initialize adapter
    adapter = PyRITBridgeAdapter(
        bridge_root=Path("~/infrastructure/agent-bridge/bridge").expanduser(),
        agent_name="redteam",
    )

    # Load mock proposal
    mock_file = Path(__file__).parent / "mock-proposal.md"

    print(f"📥 Loading proposal: {mock_file.name}")
    proposal = adapter.parse_bridge_message(mock_file)

    print(f"   Title: {proposal.title}")
    print(f"   From: {proposal.from_agent}")
    print(f"   Priority: {proposal.priority}")
    print()

    # Run adversarial challenge
    print("🔴 RED TEAM: Initiating multi-turn adversarial challenge...")
    print("   Strategy: Multi-turn Crescendo")
    print("   Turns: 5")
    print()

    challenge = await adapter.run_adversarial_challenge(
        proposal=proposal.content, strategy="multi_turn_crescendo"
    )

    # Display results
    print("✅ Challenge Complete!")
    print()
    print("=" * 80)
    print("ADVERSARIAL FINDINGS")
    print("=" * 80)
    print()
    print(f"Challenge ID: {challenge.challenge_id}")
    print(f"Risk Score: {challenge.overall_score:.2f}/1.0")
    print(f"Vulnerabilities Found: {len(challenge.vulnerabilities_found)}")
    print()

    # Show vulnerabilities
    for i, vuln in enumerate(challenge.vulnerabilities_found, 1):
        print(f"{i}. [{vuln['severity']}] {vuln['attack_type']}")
        print(f"   Attack: {vuln['adversarial_prompt']}")
        print(f"   Finding: {vuln['finding']}")
        print()

    # Show recommendations
    print("=" * 80)
    print("RECOMMENDATIONS")
    print("=" * 80)
    print()
    for i, rec in enumerate(challenge.recommendations, 1):
        print(f"{i}. {rec}")
    print()

    # Generate bridge message response
    print("=" * 80)
    print("BRIDGE MESSAGE GENERATION")
    print("=" * 80)
    print()

    response = adapter.format_challenge_as_bridge_message(challenge, proposal)

    # Save to demo results
    demo_results = Path(__file__).parent / "adversarial-response.md"
    demo_results.write_text(response)

    print(f"✅ Challenge response saved to: {demo_results}")
    print()
    print("This message would be routed back to the 'chat' agent via bridge")
    print("for review and incorporation into the revised proposal.")
    print()

    # Show snippet
    print("=" * 80)
    print("MESSAGE PREVIEW (first 20 lines)")
    print("=" * 80)
    print()
    print("\n".join(response.split("\n")[:20]))
    print("...")
    print()

    # Save detailed JSON results
    import json
    from dataclasses import asdict

    results_json = Path(__file__).parent / "challenge-results.json"
    results_json.write_text(json.dumps(asdict(challenge), indent=2))

    print(f"📊 Detailed results (JSON): {results_json}")
    print()

    # Summary
    print("=" * 80)
    print("INTEGRATION SUMMARY")
    print("=" * 80)
    print()
    print("✅ Demonstrated capabilities:")
    print("  - Parse bridge message format")
    print("  - Run multi-turn adversarial challenge")
    print("  - Identify 5 vulnerabilities across security/performance/assumptions")
    print("  - Generate actionable recommendations")
    print("  - Format results as bridge-compatible message")
    print()
    print("🎯 Next steps for production:")
    print("  1. Replace simulation with actual PyRIT orchestrators")
    print("  2. Add RED TEAM agent to bridge registry")
    print("  3. Create routing rules for HIGH/CRITICAL decisions")
    print("  4. Set up LaunchAgent for automated adversarial reviews")
    print("  5. Integrate with event sourcing for audit trail")
    print()
    print("📁 Demo files created:")
    print(f"  - {demo_results}")
    print(f"  - {results_json}")
    print()


if __name__ == "__main__":
    asyncio.run(main())
