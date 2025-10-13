#!/usr/bin/env python3
"""
PyRIT Bridge Adapter - Connects PyRIT adversarial testing to devvyn-meta-project bridge

This adapter translates bridge messages into PyRIT orchestration sessions,
enabling automated adversarial testing of agent decisions.

Status: Experimental (Green Zone - Autonomous Exploration Framework)
"""

import asyncio
import json
import uuid
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path

# PyRIT imports


@dataclass
class BridgeMessage:
    """Bridge message structure matching your COORDINATION_PROTOCOL.md format"""

    message_id: str
    priority: str  # CRITICAL, HIGH, NORMAL, INFO
    from_agent: str
    to_agent: str
    title: str
    context: str
    content: str
    expected_action: str
    timestamp: str = None

    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()


@dataclass
class AdversarialChallenge:
    """Result of PyRIT adversarial testing"""

    challenge_id: str
    target_proposal: str
    attack_strategy: str
    turns_executed: int
    vulnerabilities_found: list[dict[str, str]]
    overall_score: float
    recommendations: list[str]
    timestamp: str = None

    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()


class PyRITBridgeAdapter:
    """
    Adapter between devvyn-meta-project bridge and PyRIT adversarial testing

    Workflow:
    1. Receive bridge message (decision/proposal)
    2. Configure PyRIT orchestrator with adversarial strategy
    3. Run multi-turn challenge session
    4. Generate findings report
    5. Send results back via bridge message
    """

    def __init__(self, bridge_root: Path, agent_name: str = "redteam"):
        self.bridge_root = Path(bridge_root)
        self.agent_name = agent_name
        self.inbox = self.bridge_root / "inbox" / agent_name
        self.outbox = self.bridge_root / "outbox" / agent_name
        self.results_dir = Path(
            "~/devvyn-meta-project/kitchen/active-experiments/pyrit-adversarial-orchestration/results"
        ).expanduser()

        # Ensure directories exist
        self.inbox.mkdir(parents=True, exist_ok=True)
        self.outbox.mkdir(parents=True, exist_ok=True)
        self.results_dir.mkdir(parents=True, exist_ok=True)

    def parse_bridge_message(self, msg_file: Path) -> BridgeMessage:
        """Parse bridge message markdown format"""
        content = msg_file.read_text()

        # Simple parser for demo - production would be more robust
        lines = content.split("\n")
        title = lines[0].replace("#", "").strip()

        metadata = {}
        sections = {"context": "", "content": "", "expected_action": ""}
        current_section = None

        for line in lines[1:]:
            if line.startswith("**Message-ID**:"):
                metadata["message_id"] = line.split(":", 1)[1].strip()
            elif line.startswith("**From**:"):
                metadata["from_agent"] = line.split(":", 1)[1].strip()
            elif line.startswith("**To**:"):
                metadata["to_agent"] = line.split(":", 1)[1].strip()
            elif line.startswith("## Context"):
                current_section = "context"
            elif line.startswith("## Content"):
                current_section = "content"
            elif line.startswith("## Expected Action"):
                current_section = "expected_action"
            elif current_section and line.strip():
                sections[current_section] += line + "\n"

        # Extract priority from title
        priority = "NORMAL"
        for p in ["CRITICAL", "HIGH", "NORMAL", "INFO"]:
            if p in title:
                priority = p
                title = title.replace(f"[PRIORITY: {p}]", "").strip()

        return BridgeMessage(
            message_id=metadata.get("message_id", str(uuid.uuid4())),
            priority=priority,
            from_agent=metadata.get("from_agent", "unknown"),
            to_agent=metadata.get("to_agent", "redteam"),
            title=title,
            context=sections["context"].strip(),
            content=sections["content"].strip(),
            expected_action=sections["expected_action"].strip(),
        )

    async def run_adversarial_challenge(
        self, proposal: str, strategy: str = "multi_turn_crescendo"
    ) -> AdversarialChallenge:
        """
        Run PyRIT adversarial testing on a proposal

        Args:
            proposal: The decision/proposal to challenge
            strategy: Attack strategy (crescendo, tap, pair)

        Returns:
            AdversarialChallenge with findings
        """
        challenge_id = f"challenge-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:8]}"

        # For demo: simulate PyRIT orchestration
        # Production would use actual PyRIT orchestrator
        vulnerabilities = await self._simulate_adversarial_session(proposal, strategy)

        return AdversarialChallenge(
            challenge_id=challenge_id,
            target_proposal=proposal,
            attack_strategy=strategy,
            turns_executed=5,
            vulnerabilities_found=vulnerabilities,
            overall_score=len(vulnerabilities)
            / 10.0,  # Score: vulnerabilities found / max possible
            recommendations=self._generate_recommendations(vulnerabilities),
        )

    async def _simulate_adversarial_session(
        self, proposal: str, strategy: str
    ) -> list[dict[str, str]]:
        """
        Simulate PyRIT multi-turn adversarial testing

        In production, this would use:
        - pyrit.orchestrator.RedTeamingOrchestrator
        - Actual LLM calls for attacker/target/scorer
        - Real adversarial prompts

        For demo: generate plausible challenges based on patterns
        """

        # Common adversarial patterns to check
        attack_patterns = [
            {
                "attack": "Edge Case Analysis",
                "prompt": "What happens when this proposal encounters: empty inputs, null values, missing dependencies?",
                "finding": "Proposal lacks explicit error handling for edge cases",
            },
            {
                "attack": "Scalability Stress Test",
                "prompt": "How does this proposal perform under: 10x load, concurrent access, resource constraints?",
                "finding": "No performance benchmarks or scaling strategy defined",
            },
            {
                "attack": "Assumption Challenge",
                "prompt": "What untested assumptions underlie this proposal? What if the opposite is true?",
                "finding": "Assumes synchronous processing; async edge cases not addressed",
            },
            {
                "attack": "Security Boundary Probe",
                "prompt": "Can this proposal be exploited via: injection, privilege escalation, data leakage?",
                "finding": "Input sanitization not specified in implementation plan",
            },
            {
                "attack": "Failure Mode Exploration",
                "prompt": "What are all the ways this could fail? What's the blast radius?",
                "finding": "Recovery mechanisms not documented; failure could cascade",
            },
        ]

        # Simulate multi-turn session
        vulnerabilities = []
        for i, pattern in enumerate(attack_patterns[:5], 1):  # 5 turns
            # In production: actual LLM calls to attacker -> target -> scorer
            # For demo: return pattern-based findings
            vulnerabilities.append(
                {
                    "turn": i,
                    "attack_type": pattern["attack"],
                    "adversarial_prompt": pattern["prompt"],
                    "finding": pattern["finding"],
                    "severity": self._assess_severity(pattern["finding"]),
                }
            )

            await asyncio.sleep(0.1)  # Simulate processing time

        return vulnerabilities

    def _assess_severity(self, finding: str) -> str:
        """Assess finding severity"""
        critical_keywords = ["security", "data leakage", "privilege escalation"]
        high_keywords = ["failure", "cascade", "error handling"]

        finding_lower = finding.lower()
        if any(kw in finding_lower for kw in critical_keywords):
            return "CRITICAL"
        if any(kw in finding_lower for kw in high_keywords):
            return "HIGH"
        return "MEDIUM"

    def _generate_recommendations(self, vulnerabilities: list[dict]) -> list[str]:
        """Generate actionable recommendations from findings"""
        recommendations = []

        for vuln in vulnerabilities:
            severity = vuln.get("severity", "MEDIUM")
            finding = vuln.get("finding", "")

            if "edge case" in finding.lower():
                recommendations.append(
                    f"[{severity}] Add comprehensive edge case handling and input validation"
                )
            if "performance" in finding.lower() or "scaling" in finding.lower():
                recommendations.append(
                    f"[{severity}] Define performance benchmarks and scaling strategy"
                )
            if "assumption" in finding.lower():
                recommendations.append(
                    f"[{severity}] Document and test critical assumptions"
                )
            if "security" in finding.lower():
                recommendations.append(
                    f"[{severity}] Implement security review and input sanitization"
                )
            if "failure" in finding.lower():
                recommendations.append(
                    f"[{severity}] Design failure recovery mechanisms and circuit breakers"
                )

        return list(set(recommendations))  # Deduplicate

    def format_challenge_as_bridge_message(
        self, challenge: AdversarialChallenge, original_msg: BridgeMessage
    ) -> str:
        """Format challenge results as bridge message markdown"""

        return f"""# [PRIORITY: NORMAL] Adversarial Review: {original_msg.title}

**Message-ID**: {challenge.challenge_id}
**From**: {self.agent_name}
**To**: {original_msg.from_agent}
**Timestamp**: {challenge.timestamp}
**In-Reply-To**: {original_msg.message_id}

## Context
This is an automated adversarial review of your proposal using PyRIT multi-turn challenge framework.

**Original Proposal**: {original_msg.title}
**Attack Strategy**: {challenge.attack_strategy}
**Turns Executed**: {challenge.turns_executed}
**Vulnerabilities Found**: {len(challenge.vulnerabilities_found)}
**Risk Score**: {challenge.overall_score:.2f}/1.0

## Findings

{self._format_vulnerabilities(challenge.vulnerabilities_found)}

## Recommendations

{self._format_recommendations(challenge.recommendations)}

## Expected Action

Please review these adversarial findings and either:
1. Address the vulnerabilities in your revised proposal
2. Provide evidence that these concerns are mitigated
3. Escalate to CHAT agent for strategic validation
4. Defer to HUMAN for final decision if risks remain

---
*Generated by PyRIT Bridge Adapter - Experimental*
*Strategy: {challenge.attack_strategy}*
*Challenge ID: {challenge.challenge_id}*
"""

    def _format_vulnerabilities(self, vulnerabilities: list[dict]) -> str:
        """Format vulnerabilities as markdown"""
        output = []
        for vuln in vulnerabilities:
            output.append(
                f"### Turn {vuln['turn']}: {vuln['attack_type']} [{vuln['severity']}]"
            )
            output.append(f"**Adversarial Prompt**: {vuln['adversarial_prompt']}")
            output.append(f"**Finding**: {vuln['finding']}")
            output.append("")
        return "\n".join(output)

    def _format_recommendations(self, recommendations: list[str]) -> str:
        """Format recommendations as markdown checklist"""
        return "\n".join([f"- [ ] {rec}" for rec in recommendations])

    async def process_message(self, msg_file: Path) -> Path:
        """
        Main workflow: Process incoming bridge message with adversarial testing

        Returns: Path to generated challenge message file
        """
        # Parse incoming message
        msg = self.parse_bridge_message(msg_file)

        print(f"🔴 RED TEAM: Processing message: {msg.title}")
        print(f"   From: {msg.from_agent}, Priority: {msg.priority}")

        # Run adversarial challenge
        print(f"🎯 Running {5}-turn adversarial challenge...")
        challenge = await self.run_adversarial_challenge(
            proposal=msg.content, strategy="multi_turn_crescendo"
        )

        print(
            f"✅ Challenge complete: {len(challenge.vulnerabilities_found)} vulnerabilities found"
        )
        print(f"   Risk Score: {challenge.overall_score:.2f}/1.0")

        # Format as bridge message
        response_content = self.format_challenge_as_bridge_message(challenge, msg)

        # Save to outbox
        response_file = self.outbox / f"{challenge.challenge_id}.md"
        response_file.write_text(response_content)

        # Save detailed results
        results_file = self.results_dir / f"{challenge.challenge_id}.json"
        results_file.write_text(json.dumps(asdict(challenge), indent=2))

        print(f"📤 Challenge message saved: {response_file}")
        print(f"📊 Detailed results: {results_file}")

        return response_file


# Demo/testing functions


async def demo_adversarial_challenge():
    """Demo the adapter with a mock proposal"""
    adapter = PyRITBridgeAdapter(
        bridge_root=Path("~/infrastructure/agent-bridge/bridge").expanduser(),
        agent_name="redteam",
    )

    # Create mock proposal
    mock_proposal = BridgeMessage(
        message_id=f"chat-{datetime.now().isoformat()}-{uuid.uuid4().hex[:8]}",
        priority="HIGH",
        from_agent="chat",
        to_agent="redteam",
        title="Proposal: Auto-cleanup Desktop files older than 30 days",
        context="Reduce Desktop clutter and improve organization by automatically archiving old files",
        content="""
Implement automatic cleanup of Desktop files based on age:
- Scan ~/Desktop for files older than 30 days
- Move matching files to ~/Documents/Archive/YYYY-MM/
- Preserve directory structure
- Run weekly via LaunchAgent
- Log all operations to ~/devvyn-meta-project/logs/desktop-cleanup.log
        """,
        expected_action="Review proposal, implement if approved, or suggest refinements",
    )

    # Run challenge
    challenge = await adapter.run_adversarial_challenge(
        proposal=mock_proposal.content, strategy="multi_turn_crescendo"
    )

    return challenge


if __name__ == "__main__":
    # Run demo
    print("=" * 70)
    print("PyRIT Bridge Adapter - Adversarial Testing Demo")
    print("=" * 70)
    print()

    challenge = asyncio.run(demo_adversarial_challenge())

    print("\n" + "=" * 70)
    print("CHALLENGE RESULTS")
    print("=" * 70)
    print(f"Challenge ID: {challenge.challenge_id}")
    print(f"Strategy: {challenge.attack_strategy}")
    print(f"Turns: {challenge.turns_executed}")
    print(f"Vulnerabilities Found: {len(challenge.vulnerabilities_found)}")
    print(f"Risk Score: {challenge.overall_score:.2f}/1.0")
    print()
    print("Vulnerabilities:")
    for i, vuln in enumerate(challenge.vulnerabilities_found, 1):
        print(f"\n{i}. [{vuln['severity']}] {vuln['attack_type']}")
        print(f"   Finding: {vuln['finding']}")

    print("\n" + "=" * 70)
    print("RECOMMENDATIONS")
    print("=" * 70)
    for rec in challenge.recommendations:
        print(f"  {rec}")
    print()
