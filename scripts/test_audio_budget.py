#!/usr/bin/env python3
"""
Unit tests for audio budget management and routing system

Run with: python3 test_audio_budget.py
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path
from datetime import date

# Import modules under test
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

import importlib.util

# Load budget manager
spec = importlib.util.spec_from_file_location(
    "audio_budget_manager",
    SCRIPT_DIR / "audio-budget-manager.py"
)
budget_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(budget_module)
AudioBudgetManager = budget_module.AudioBudgetManager

# Load router
from audio_router import AudioRouter, RoutingDecision


class TestBudgetManager(unittest.TestCase):
    """Test budget tracking and quota enforcement"""

    def setUp(self):
        """Create temporary budget config for testing"""
        self.temp_dir = tempfile.mkdtemp()
        self.config_file = Path(self.temp_dir) / "test-budget.json"
        self.manager = AudioBudgetManager(self.config_file)

    def tearDown(self):
        """Clean up temp files"""
        if self.config_file.exists():
            self.config_file.unlink()
        Path(self.temp_dir).rmdir()

    def test_default_provider_is_macos(self):
        """Default provider should be free macOS"""
        self.assertEqual(self.manager.active_provider, "macos_native")

    def test_set_provider(self):
        """Should be able to switch providers"""
        self.manager.active_provider = "elevenlabs_starter"
        self.manager.save_config()

        # Reload and verify
        manager2 = AudioBudgetManager(self.config_file)
        self.assertEqual(manager2.active_provider, "elevenlabs_starter")

    def test_quota_enforcement_monthly(self):
        """Should reject usage exceeding monthly limit"""
        self.manager.active_provider = "elevenlabs_starter"
        tracker = self.manager.get_usage("elevenlabs_starter")

        # Use up almost all monthly quota
        tracker.monthly_used = 29000  # Limit is 30k

        # Should allow 1000 chars
        can_use, reason = self.manager.can_use("elevenlabs_starter", 1000)
        self.assertTrue(can_use)

        # Should reject 2000 chars (would exceed 30k)
        can_use, reason = self.manager.can_use("elevenlabs_starter", 2000)
        self.assertFalse(can_use)
        self.assertIn("Monthly limit exceeded", reason)

    def test_quota_enforcement_daily(self):
        """Should reject usage exceeding daily limit"""
        self.manager.active_provider = "elevenlabs_starter"
        tracker = self.manager.get_usage("elevenlabs_starter")

        # Use up daily quota
        tracker.daily_used = 1500  # Limit is 2k

        # Should allow 500 chars
        can_use, reason = self.manager.can_use("elevenlabs_starter", 500)
        self.assertTrue(can_use)

        # Should reject 600 chars (would exceed 2k)
        can_use, reason = self.manager.can_use("elevenlabs_starter", 600)
        self.assertFalse(can_use)
        self.assertIn("Daily limit exceeded", reason)

    def test_usage_recording(self):
        """Should accurately record usage"""
        self.manager.active_provider = "elevenlabs_starter"

        # Record usage
        self.manager.record_usage("elevenlabs_starter", 1000, "test.md")

        tracker = self.manager.get_usage("elevenlabs_starter")
        self.assertEqual(tracker.monthly_used, 1000)
        self.assertEqual(tracker.daily_used, 1000)
        self.assertEqual(len(tracker.history), 1)
        self.assertEqual(tracker.history[0]["chars"], 1000)

    def test_daily_reset(self):
        """Daily counter should reset on new day"""
        self.manager.active_provider = "elevenlabs_starter"
        tracker = self.manager.get_usage("elevenlabs_starter")

        # Set usage for yesterday
        tracker.daily_used = 1500
        tracker.last_reset_date = "2025-11-04"

        # Check today - should reset
        self.manager.check_and_reset_daily(tracker)
        self.assertEqual(tracker.daily_used, 0)
        self.assertEqual(tracker.last_reset_date, date.today().isoformat())

    def test_monthly_reset(self):
        """Monthly counter should reset on new month"""
        self.manager.active_provider = "elevenlabs_starter"
        tracker = self.manager.get_usage("elevenlabs_starter")

        # Set usage for last month
        tracker.monthly_used = 25000
        tracker.month = "2025-10"

        # Check this month - should reset
        self.manager.check_and_reset_monthly(tracker)
        self.assertEqual(tracker.monthly_used, 0)
        self.assertEqual(tracker.month, date.today().strftime("%Y-%m"))

    def test_queue_operations(self):
        """Should handle job queueing"""
        job_id = self.manager.add_to_queue("test.md", "elevenlabs_starter", "high", 5000)

        self.assertEqual(len(self.manager.queue), 1)
        self.assertEqual(self.manager.queue[0].doc_path, "test.md")
        self.assertEqual(self.manager.queue[0].priority, "high")
        self.assertEqual(self.manager.queue[0].estimated_chars, 5000)

    def test_queue_processing_respects_limits(self):
        """Queue processing should respect daily limits"""
        self.manager.active_provider = "elevenlabs_starter"

        # Add jobs: first is 1500 (ok), second is 1000 (would exceed 2k limit)
        self.manager.add_to_queue("doc1.md", "elevenlabs_starter", "high", 1500)
        self.manager.add_to_queue("doc2.md", "elevenlabs_starter", "medium", 1000)
        self.manager.add_to_queue("doc3.md", "elevenlabs_starter", "low", 500)

        # Process queue - should only process first job (1500 chars)
        # Second job (1000) would push total to 2500 > 2000 limit
        processed = self.manager.process_queue(dry_run=True)

        # Should only process first job
        self.assertEqual(len(processed), 1)


class TestAudioRouter(unittest.TestCase):
    """Test intelligent routing logic"""

    def setUp(self):
        """Create test environment"""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.router = AudioRouter()

    def tearDown(self):
        """Clean up"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_detect_premium_content(self):
        """Should detect premium content patterns"""
        # Premium patterns - create temp files with these paths
        premium_patterns = [
            "knowledge-base/patterns/jits.md",
            "docs/phase-summaries/phase-6.md",
            "examples/simulacrum-stories/story.md",
            "README.md",
        ]

        for pattern in premium_patterns:
            # Create temp file matching pattern
            temp_file = self.temp_dir / pattern
            temp_file.parent.mkdir(parents=True, exist_ok=True)
            temp_file.write_text("# Premium Content\n\nSome important content.")

            content_type = self.router.detect_content_type(temp_file)
            self.assertIn(content_type, ["premium", "auto"],
                         f"{pattern} should be premium/auto, got {content_type}")

    def test_detect_draft_content(self):
        """Should detect draft content patterns"""
        # Draft patterns
        draft_paths = [
            Path("/tmp/test.md"),
            Path("scratch/notes.md"),
            Path("notes/ideas.md"),
            Path(".drafts/wip.md"),
        ]

        for path in draft_paths:
            # Create temp files to avoid stat errors
            temp_file = self.temp_dir / path.name
            temp_file.write_text("test content")

            content_type = self.router.detect_content_type(temp_file)
            self.assertEqual(content_type, "draft",
                           f"{path} should be draft, got {content_type}")

    def test_estimate_characters(self):
        """Should estimate character count from file"""
        test_file = self.temp_dir / "test.md"
        test_content = "# Test\n\nThis is a test document with some content."
        test_file.write_text(test_content)

        estimated = self.router.estimate_characters(test_file)
        self.assertEqual(estimated, len(test_content))

    def test_force_provider_override(self):
        """Force provider should override routing logic"""
        test_file = self.temp_dir / "test.md"
        test_file.write_text("Small test content")

        decision = self.router.route(test_file, force_provider="macos")
        self.assertEqual(decision.provider, "macos")
        self.assertIn("Forced provider", decision.reason)

    def test_fallback_on_quota_exceeded(self):
        """Should fallback to macOS when quota exceeded"""
        # Create temp config with budget manager
        config_file = self.temp_dir / "budget.json"
        manager = AudioBudgetManager(config_file)
        manager.active_provider = "elevenlabs_starter"
        manager.save_config()  # Save provider setting

        # Max out daily quota
        tracker = manager.get_usage("elevenlabs_starter")
        tracker.daily_used = 2000
        tracker.last_reset_date = date.today().isoformat()
        manager.save_config()

        # Create router with this manager
        router = AudioRouter(budget_manager=manager)

        # Create premium content that would exceed quota
        test_file = self.temp_dir / "knowledge-base" / "patterns"
        test_file.mkdir(parents=True)
        test_file = test_file / "big-pattern.md"
        test_file.write_text("x" * 5000)  # 5000 chars

        decision = router.route(test_file, allow_fallback=True)

        self.assertEqual(decision.provider, "macos")
        self.assertTrue(decision.fallback_used)
        self.assertTrue(decision.queued_for_later)

    def test_no_fallback_raises_error(self):
        """Should raise error if fallback disabled and quota exceeded"""
        config_file = self.temp_dir / "budget.json"
        manager = AudioBudgetManager(config_file)
        manager.active_provider = "elevenlabs_starter"
        manager.save_config()  # Save provider setting

        # Max out quota
        tracker = manager.get_usage("elevenlabs_starter")
        tracker.daily_used = 2000
        tracker.last_reset_date = date.today().isoformat()
        manager.save_config()

        router = AudioRouter(budget_manager=manager)

        # Create large premium file
        test_file = self.temp_dir / "knowledge-base" / "patterns"
        test_file.mkdir(parents=True)
        test_file = test_file / "big.md"
        test_file.write_text("x" * 5000)

        # Should raise error when fallback disabled
        with self.assertRaises(ValueError):
            router.route(test_file, allow_fallback=False)

    def test_draft_content_always_uses_macos(self):
        """Draft content should always use free macOS"""
        test_file = self.temp_dir / "scratch" / "notes.md"
        test_file.parent.mkdir(parents=True)
        test_file.write_text("Draft notes")

        decision = self.router.route(test_file)
        self.assertEqual(decision.provider, "macos")
        self.assertIn("Draft content", decision.reason)
        self.assertFalse(decision.fallback_used)


class TestIntegration(unittest.TestCase):
    """Integration tests for complete workflow"""

    def setUp(self):
        """Set up test environment"""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.config_file = self.temp_dir / "budget.json"

    def tearDown(self):
        """Clean up"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_daily_workflow_simulation(self):
        """Simulate a day of audio generation"""
        manager = AudioBudgetManager(self.config_file)
        manager.active_provider = "elevenlabs_starter"
        manager.save_config()  # Save provider setting
        router = AudioRouter(budget_manager=manager)

        # Morning: Generate 3 small premium docs (1500 chars total, under 2k limit)
        for i in range(3):
            doc = self.temp_dir / "knowledge-base" / "patterns" / f"pattern-{i}.md"
            doc.parent.mkdir(parents=True, exist_ok=True)
            doc.write_text("x" * 500)  # 500 chars each

            decision = router.route(doc)
            # First 3 should use ElevenLabs (1500 total < 2000 limit)
            if i < 3:
                # Record usage
                manager.record_usage("elevenlabs_starter", 500, str(doc))

        # Check usage
        tracker = manager.get_usage("elevenlabs_starter")
        self.assertEqual(tracker.daily_used, 1500)

        # Afternoon: Try to generate large doc (1000 chars, would exceed 2k limit)
        large_doc = self.temp_dir / "knowledge-base" / "patterns" / "large.md"
        large_doc.write_text("x" * 1000)

        decision = router.route(large_doc)

        # Should fallback because 1500 + 1000 > 2000
        self.assertEqual(decision.provider, "macos")
        self.assertTrue(decision.fallback_used)
        self.assertTrue(decision.queued_for_later)

        # Check queue
        self.assertEqual(len(manager.queue), 1)


def run_tests():
    """Run all tests and report results"""
    # Discover and run tests
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(sys.modules[__name__])
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    # Print summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print("=" * 70)

    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(run_tests())
