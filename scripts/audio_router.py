#!/usr/bin/env python3
"""
Audio Content Router with Budget Management

Intelligently routes documents to appropriate TTS providers based on:
- Content type (public vs draft)
- Budget quotas (daily/monthly limits)
- Fallback strategies (immediate draft + queued premium)

Usage:
    from audio_router import AudioRouter

    router = AudioRouter()
    result = router.route_and_generate(doc_path, allow_fallback=True)
"""

import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Literal, Optional, Union

# Import budget manager
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

# Import budget manager classes directly from file
try:
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "audio_budget_manager",
        SCRIPT_DIR / "audio-budget-manager.py"
    )
    if spec and spec.loader:
        audio_budget_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(audio_budget_module)
        AudioBudgetManager = audio_budget_module.AudioBudgetManager
    else:
        AudioBudgetManager = None
except Exception as e:
    print(f"Warning: Could not load budget manager: {e}")
    AudioBudgetManager = None


@dataclass
class RoutingDecision:
    """Result of routing logic"""

    provider: Literal["elevenlabs", "macos", "openai"]
    reason: str
    fallback_used: bool = False
    queued_for_later: bool = False
    estimated_chars: int = 0


class AudioRouter:
    """Smart content router with budget awareness"""

    def __init__(self, budget_manager: Optional[AudioBudgetManager] = None):
        self.budget_manager = budget_manager or (
            AudioBudgetManager() if AudioBudgetManager else None
        )

        # Content routing rules
        self.premium_patterns = [
            "knowledge-base/patterns/**/*.md",  # Public patterns
            "docs/phase-summaries/**/*.md",  # Key documentation
            "examples/simulacrum-stories/**/*.md",  # Narrative quality
            "**/CHANGELOG.md",  # Public-facing changelogs
            "**/README.md",  # Public documentation
        ]

        self.draft_patterns = [
            "**/.drafts/**/*.md",  # Explicit drafts folder
            "**/scratch/**/*.md",  # Scratch notes
            "**/notes/**/*.md",  # Personal notes
            "**/tmp/**/*.md",  # Temporary files
        ]

    def detect_content_type(
        self, doc_path: Path
    ) -> Literal["premium", "draft", "auto"]:
        """Detect if document should use premium or draft voice"""

        doc_str = str(doc_path)

        # Check premium patterns
        for pattern in self.premium_patterns:
            if doc_path.match(pattern):
                return "premium"

        # Check draft patterns
        for pattern in self.draft_patterns:
            if doc_path.match(pattern):
                return "draft"

        # Default: auto-detect based on size/location
        # Large files (>5KB) or in docs/ are premium
        if doc_path.stat().st_size > 5000 or "docs/" in doc_str:
            return "premium"

        return "draft"

    def estimate_characters(self, doc_path: Path) -> int:
        """Estimate character count for budget planning"""
        try:
            content = doc_path.read_text()
            # Rough estimate: actual chars minus code blocks (which get described)
            # This is conservative - actual usage may be less
            return len(content)
        except Exception:
            # Fallback: file size in bytes (overestimate)
            return doc_path.stat().st_size

    def route(
        self,
        doc_path: Path,
        allow_fallback: bool = True,
        force_provider: Optional[str] = None,
    ) -> RoutingDecision:
        """
        Route document to appropriate provider

        Args:
            doc_path: Path to markdown document
            allow_fallback: If True, fallback to macOS when quota exceeded
            force_provider: Override routing logic with specific provider

        Returns:
            RoutingDecision with provider and reasoning
        """

        estimated_chars = self.estimate_characters(doc_path)

        # Forced provider (skip routing logic)
        if force_provider:
            if force_provider == "macos":
                return RoutingDecision(
                    provider="macos",
                    reason="Forced provider: macOS (free)",
                    estimated_chars=estimated_chars,
                )
            elif force_provider in ["elevenlabs", "openai"]:
                # Check budget
                if self.budget_manager:
                    can_use, reason = self.budget_manager.can_use(
                        f"{force_provider}_starter", estimated_chars
                    )
                    if not can_use:
                        if allow_fallback:
                            return RoutingDecision(
                                provider="macos",
                                reason=f"Quota exceeded, fallback to macOS: {reason}",
                                fallback_used=True,
                                queued_for_later=True,
                                estimated_chars=estimated_chars,
                            )
                        else:
                            raise ValueError(f"Cannot use {force_provider}: {reason}")

                return RoutingDecision(
                    provider=force_provider,
                    reason=f"Forced provider: {force_provider}",
                    estimated_chars=estimated_chars,
                )

        # Smart routing based on content type
        content_type = self.detect_content_type(doc_path)

        if content_type == "draft":
            # Always use free macOS for drafts
            return RoutingDecision(
                provider="macos",
                reason="Draft content → macOS (free)",
                estimated_chars=estimated_chars,
            )

        # Premium content - check budget
        if self.budget_manager:
            active_provider = self.budget_manager.active_provider

            # Skip budget check for free macOS
            if active_provider == "macos_native":
                return RoutingDecision(
                    provider="macos",
                    reason="Premium content, free macOS provider active",
                    estimated_chars=estimated_chars,
                )

            can_use, reason = self.budget_manager.can_use(
                active_provider, estimated_chars
            )

            if can_use:
                # Use premium provider
                provider_name = active_provider.split("_")[0]  # elevenlabs_starter → elevenlabs
                return RoutingDecision(
                    provider=provider_name,
                    reason=f"Premium content, quota available: {reason}",
                    estimated_chars=estimated_chars,
                )
            else:
                # Quota exceeded
                if allow_fallback:
                    return RoutingDecision(
                        provider="macos",
                        reason=f"Premium content, quota exceeded, fallback: {reason}",
                        fallback_used=True,
                        queued_for_later=True,
                        estimated_chars=estimated_chars,
                    )
                else:
                    raise ValueError(f"Premium quota exceeded: {reason}")

        # No budget manager - default to macOS
        return RoutingDecision(
            provider="macos",
            reason="No budget manager, using free macOS",
            estimated_chars=estimated_chars,
        )

    def generate_audio(
        self,
        doc_path: Path,
        decision: RoutingDecision,
        output_dir: Path,
        **kwargs,
    ) -> Path:
        """
        Generate audio using routed provider

        Args:
            doc_path: Source document
            decision: Routing decision from route()
            output_dir: Output directory
            **kwargs: Additional args for doc-to-audio.py

        Returns:
            Path to generated audio file
        """

        # Build doc-to-audio.py command
        cmd = [
            sys.executable,
            str(SCRIPT_DIR / "doc-to-audio.py"),
            "--input",
            str(doc_path),
            "--output",
            str(output_dir),
            "--provider",
            decision.provider,
        ]

        # Add optional kwargs
        if kwargs.get("multi_voice"):
            cmd.append("--multi-voice")
        if kwargs.get("advanced_mixing"):
            cmd.append("--advanced-mixing")
        if kwargs.get("narrator"):
            cmd.extend(["--narrator", kwargs["narrator"]])

        # Run generation
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        # Record usage if premium provider
        if decision.provider in ["elevenlabs", "openai"] and self.budget_manager:
            provider_key = f"{decision.provider}_{self.budget_manager.active_provider.split('_')[1]}"
            self.budget_manager.record_usage(
                provider_key, decision.estimated_chars, str(doc_path)
            )

        # Queue premium version if fallback was used
        if decision.fallback_used and decision.queued_for_later and self.budget_manager:
            active_provider = self.budget_manager.active_provider
            self.budget_manager.add_to_queue(
                str(doc_path),
                active_provider,
                "high",  # Premium content gets high priority
                decision.estimated_chars,
            )

        # Return output path (extract from doc-to-audio.py output)
        output_file = output_dir / f"{doc_path.stem}_part001.mp3"
        return output_file

    def route_and_generate(
        self,
        doc_path: Path,
        output_dir: Path = Path("audio"),
        allow_fallback: bool = True,
        force_provider: str | None = None,
        **kwargs,
    ) -> dict:
        """
        One-shot: route and generate audio

        Returns:
            dict with:
                - audio_file: Path to generated audio
                - provider: Provider used
                - reason: Routing reason
                - fallback_used: Whether fallback was used
                - queued_for_later: Whether premium version queued
        """

        decision = self.route(doc_path, allow_fallback, force_provider)

        print(f"📍 Routing: {decision.provider.upper()}")
        print(f"   Reason: {decision.reason}")
        print(f"   Estimated: {decision.estimated_chars:,} chars")

        if decision.fallback_used:
            print(f"   ⚠️  Fallback used - draft quality")
            print(f"   ✅ Premium version queued for tomorrow")

        audio_file = self.generate_audio(doc_path, decision, output_dir, **kwargs)

        return {
            "audio_file": audio_file,
            "provider": decision.provider,
            "reason": decision.reason,
            "fallback_used": decision.fallback_used,
            "queued_for_later": decision.queued_for_later,
            "estimated_chars": decision.estimated_chars,
        }


def main():
    """CLI for testing routing logic"""
    import argparse

    parser = argparse.ArgumentParser(description="Test audio routing logic")
    parser.add_argument("doc_path", help="Path to document")
    parser.add_argument("--allow-fallback", action="store_true", default=True)
    parser.add_argument("--force-provider", choices=["elevenlabs", "macos", "openai"])
    parser.add_argument("--dry-run", action="store_true", help="Show routing only")

    args = parser.parse_args()

    router = AudioRouter()
    decision = router.route(
        Path(args.doc_path), args.allow_fallback, args.force_provider
    )

    print(f"Provider: {decision.provider}")
    print(f"Reason: {decision.reason}")
    print(f"Estimated: {decision.estimated_chars:,} chars")
    print(f"Fallback: {decision.fallback_used}")
    print(f"Queued: {decision.queued_for_later}")

    if not args.dry_run:
        result = router.route_and_generate(Path(args.doc_path))
        print(f"\nGenerated: {result['audio_file']}")


if __name__ == "__main__":
    main()
