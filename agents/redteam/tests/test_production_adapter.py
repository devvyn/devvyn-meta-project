#!/usr/bin/env python3
"""
Test suite for PyRIT Production Adapter

Tests:
- API configuration
- Error handling and retries
- Fallback to simulation
- Bridge message parsing
- Vulnerability detection
- Recommendation generation
"""

import os
import sys
from pathlib import Path
from typing import Any

import pytest

# Add paths
project_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(project_root / "agents" / "redteam"))

from pyrit_production_adapter import PyRITProductionAdapter


class TestAPIConfiguration:
    """Test API key loading and configuration"""

    def test_load_openai_config(self, tmp_path: Any) -> None:
        """Test OpenAI API key loading"""
        # Create mock .env.pyrit file
        env_file = tmp_path / ".env.pyrit"
        env_file.write_text('export OPENAI_API_KEY="test-key-123"\n')

        # Set environment to point to test file
        os.environ["OPENAI_API_KEY"] = "test-key-123"

        adapter = PyRITProductionAdapter(
            bridge_root=tmp_path / "bridge", fallback_on_error=True
        )

        assert adapter.has_openai == True

    def test_missing_api_keys_with_fallback(self, tmp_path: Any) -> None:
        """Test graceful handling of missing API keys when fallback enabled"""
        # Clear API keys
        os.environ.pop("OPENAI_API_KEY", None)
        os.environ.pop("AZURE_OPENAI_ENDPOINT", None)

        # Should not raise with fallback enabled
        adapter = PyRITProductionAdapter(
            bridge_root=tmp_path / "bridge", fallback_on_error=True
        )

        assert adapter.has_openai == False
        assert adapter.has_azure == False

    def test_missing_api_keys_without_fallback(self, tmp_path: Any) -> None:
        """Test error when API keys missing and fallback disabled"""
        os.environ.pop("OPENAI_API_KEY", None)
        os.environ.pop("AZURE_OPENAI_ENDPOINT", None)

        # Should raise ValueError
        with pytest.raises(ValueError, match="API keys required"):
            adapter = PyRITProductionAdapter(
                bridge_root=tmp_path / "bridge", fallback_on_error=False
            )


class TestAdversarialChallenge:
    """Test adversarial challenge execution"""

    @pytest.mark.asyncio
    async def test_simulated_challenge(self, tmp_path: Any) -> None:
        """Test simulated adversarial challenge"""
        adapter = PyRITProductionAdapter(
            bridge_root=tmp_path / "bridge", fallback_on_error=True
        )

        proposal = "Implement automated testing for all API endpoints"

        challenge = await adapter.run_adversarial_challenge_simulated(
            proposal=proposal, strategy="crescendo", max_turns=5
        )

        assert challenge.challenge_id.startswith("challenge-sim-")
        assert challenge.turns_executed == 5
        assert len(challenge.vulnerabilities_found) == 5
        assert challenge.fallback_used == True
        assert 0.0 <= challenge.overall_score <= 1.0

    @pytest.mark.asyncio
    async def test_simulated_challenge_limited_turns(self, tmp_path: Any) -> None:
        """Test simulated challenge with limited turns"""
        adapter = PyRITProductionAdapter(bridge_root=tmp_path / "bridge")

        challenge = await adapter.run_adversarial_challenge_simulated(
            proposal="Test proposal", strategy="crescendo", max_turns=3
        )

        assert challenge.turns_executed == 3
        assert len(challenge.vulnerabilities_found) == 3


class TestErrorHandling:
    """Test error handling and retry logic"""

    @pytest.mark.asyncio
    async def test_retry_logic_success_on_second_attempt(self, tmp_path: Any) -> None:
        """Test successful retry after initial failure"""
        adapter = PyRITProductionAdapter(
            bridge_root=tmp_path / "bridge",
            max_retries=3,
            retry_delay=0.1,  # Fast retry for testing
        )

        # Mock PyRIT to fail once then succeed
        call_count = 0

        async def mock_run_real(proposal, strategy, max_turns):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                raise ConnectionError("API temporarily unavailable")
            return await adapter.run_adversarial_challenge_simulated(
                proposal, strategy, max_turns
            )

        adapter.run_adversarial_challenge_real = mock_run_real

        challenge = await adapter.run_adversarial_challenge_with_retry(
            proposal="Test", strategy="crescendo"
        )

        assert call_count == 2  # Failed once, succeeded on retry
        assert challenge is not None

    @pytest.mark.asyncio
    async def test_retry_exhaustion_falls_back(self, tmp_path: Any) -> None:
        """Test fallback after all retries exhausted"""
        adapter = PyRITProductionAdapter(
            bridge_root=tmp_path / "bridge",
            max_retries=2,
            retry_delay=0.05,
            fallback_on_error=True,
        )

        # Mock PyRIT to always fail
        async def mock_run_real(proposal, strategy, max_turns):
            raise ConnectionError("API down")

        adapter.run_adversarial_challenge_real = mock_run_real

        challenge = await adapter.run_adversarial_challenge_with_retry(
            proposal="Test", strategy="crescendo"
        )

        assert challenge.fallback_used == True
        assert challenge.challenge_id.startswith("challenge-sim-")


class TestVulnerabilityDetection:
    """Test vulnerability detection and severity assessment"""

    def test_severity_assessment_critical(self, tmp_path: Any) -> None:
        """Test CRITICAL severity detection"""
        adapter = PyRITProductionAdapter(bridge_root=tmp_path / "bridge")

        finding = "SQL injection vulnerability allows data leakage"
        severity = adapter._assess_severity(finding)

        assert severity == "CRITICAL"

    def test_severity_assessment_high(self, tmp_path: Any) -> None:
        """Test HIGH severity detection"""
        adapter = PyRITProductionAdapter(bridge_root=tmp_path / "bridge")

        finding = "Missing error handling could cause cascade failure"
        severity = adapter._assess_severity(finding)

        assert severity == "HIGH"

    def test_severity_assessment_medium(self, tmp_path: Any) -> None:
        """Test MEDIUM severity detection"""
        adapter = PyRITProductionAdapter(bridge_root=tmp_path / "bridge")

        finding = "Performance benchmarks not defined for scaling"
        severity = adapter._assess_severity(finding)

        assert severity == "MEDIUM"

    def test_severity_assessment_low(self, tmp_path: Any) -> None:
        """Test LOW severity (default)"""
        adapter = PyRITProductionAdapter(bridge_root=tmp_path / "bridge")

        finding = "Documentation could be improved"
        severity = adapter._assess_severity(finding)

        assert severity == "LOW"


class TestRecommendationGeneration:
    """Test recommendation generation"""

    def test_generate_recommendations_from_vulnerabilities(self, tmp_path: Any) -> None:
        """Test recommendation generation"""
        adapter = PyRITProductionAdapter(bridge_root=tmp_path / "bridge")

        vulnerabilities = [
            {"severity": "HIGH", "finding": "Missing error handling for edge cases"},
            {"severity": "MEDIUM", "finding": "No performance benchmarks defined"},
            {
                "severity": "CRITICAL",
                "finding": "Security review needed for input sanitization",
            },
        ]

        recommendations = adapter._generate_recommendations(vulnerabilities)

        assert len(recommendations) > 0
        assert any("edge case" in rec.lower() for rec in recommendations)
        assert any("performance" in rec.lower() for rec in recommendations)
        assert any("security" in rec.lower() for rec in recommendations)

    def test_recommendations_deduplicated(self, tmp_path: Any) -> None:
        """Test that duplicate recommendations are removed"""
        adapter = PyRITProductionAdapter(bridge_root=tmp_path / "bridge")

        vulnerabilities = [
            {"severity": "HIGH", "finding": "Edge case not handled"},
            {"severity": "HIGH", "finding": "Edge cases missing"},
            {"severity": "MEDIUM", "finding": "Edge case validation needed"},
        ]

        recommendations = adapter._generate_recommendations(vulnerabilities)

        # Should deduplicate similar recommendations
        edge_case_recs = [r for r in recommendations if "edge case" in r.lower()]
        assert len(edge_case_recs) <= 2  # At most 2 variations


class TestBridgeIntegration:
    """Test bridge message integration"""

    @pytest.mark.asyncio
    async def test_inbox_directory_creation(self, tmp_path: Any) -> None:
        """Test that adapter creates necessary directories"""
        bridge_root = tmp_path / "bridge"

        adapter = PyRITProductionAdapter(bridge_root=bridge_root, agent_name="redteam")

        assert adapter.inbox.exists()
        assert adapter.outbox.exists()
        assert adapter.results_dir.exists()

    def test_agent_namespace(self, tmp_path: Any) -> None:
        """Test agent namespace configuration"""
        adapter = PyRITProductionAdapter(
            bridge_root=tmp_path / "bridge", agent_name="redteam-test"
        )

        assert adapter.agent_name == "redteam-test"
        assert "redteam-test" in str(adapter.inbox)
        assert "redteam-test" in str(adapter.outbox)


# Test fixtures
@pytest.fixture
def tmp_path(tmp_path_factory: Any) -> Any:
    """Create temporary directory for tests"""
    return tmp_path_factory.mktemp("test_pyrit")


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
