#!/usr/bin/env python3
"""
Documentation to Audio Converter

Converts markdown documentation to spoken audio using TTS APIs.

Supported APIs:
- 11 Labs (recommended for quality)
- OpenAI TTS (good alternative)
- macOS 'say' (free, offline, built-in)

Usage:
    ./doc-to-audio.py --input docs/tools/coord-init.md --output audio/
    ./doc-to-audio.py --input docs/ --recursive --output audio/

Features:
- Markdown cleaning (removes code blocks, tables, etc.)
- Smart chunking (respects API limits)
- Chapter detection (splits on headers)
- Metadata embedding (title, description)
- Progress tracking
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Union

try:
    from rich.console import Console

    HAS_RICH = True
except ImportError:
    HAS_RICH = False

# TTS Provider imports (optional - install as needed)
try:
    from elevenlabs.client import ElevenLabs

    HAS_ELEVENLABS = True
except ImportError:
    HAS_ELEVENLABS = False

try:
    from openai import OpenAI

    HAS_OPENAI = True
except ImportError:
    HAS_OPENAI = False


class MarkdownCleaner:
    """Clean markdown for TTS conversion"""

    def __init__(self, multi_voice: bool = False):
        self.console = Console() if HAS_RICH else None
        self.multi_voice = multi_voice

    def clean(self, markdown: str) -> str:
        """Clean markdown text for speech"""

        # Remove YAML frontmatter
        markdown = re.sub(r"^---\n.*?\n---\n", "", markdown, flags=re.DOTALL)

        # Convert headers to natural speech
        markdown = self._convert_headers(markdown)

        # Handle code blocks (describe or remove)
        markdown = self._handle_code_blocks(markdown)

        # Handle tables (describe or remove)
        markdown = self._handle_tables(markdown)

        # Clean markdown syntax
        markdown = self._clean_markdown_syntax(markdown)

        # Normalize whitespace
        markdown = self._normalize_whitespace(markdown)

        # Add natural pauses
        markdown = self._add_pauses(markdown)

        return markdown

    def clean_with_tags(self, markdown: str) -> str:
        """Clean markdown and add voice tags for multi-voice narration"""

        # Remove YAML frontmatter
        markdown = re.sub(r"^---\n.*?\n---\n", "", markdown, flags=re.DOTALL)

        # Tag code blocks BEFORE cleaning
        markdown = self._tag_code_blocks(markdown)

        # Tag blockquotes BEFORE cleaning
        markdown = self._tag_blockquotes(markdown)

        # Tag headers BEFORE converting
        markdown = self._tag_headers(markdown)

        # Now clean the content (but preserve tags)
        markdown = self._handle_tables(markdown)
        markdown = self._clean_markdown_syntax(markdown)
        markdown = self._normalize_whitespace(markdown)

        return markdown

    def _tag_code_blocks(self, text: str) -> str:
        """Tag code blocks for voice switching - Hybrid approach (Options 2+4)"""

        def replace_code(match):
            lang = match.group(1) or "code"
            code_content = match.group(2)

            # Count lines (excluding empty)
            lines = [l for l in code_content.strip().split("\n") if l.strip()]
            line_count = len(lines)

            # Short code (≤5 lines): Read verbatim
            if line_count <= 5:
                # Clean code for speech (remove excessive whitespace)
                cleaned_code = "\n".join(lines)
                return f"<VOICE:CODE>{cleaned_code}</VOICE:CODE>"

            # Medium/Long code (>5 lines): Generate smart description
            first_line = lines[0].strip() if lines else ""

            # Try to extract meaningful context from first line
            description = self._describe_code(first_line, lang, line_count)

            return f"<VOICE:CODE>{description} Full implementation available in written documentation.</VOICE:CODE>"

        return re.sub(r"```([\w]*)\n(.*?)\n```", replace_code, text, flags=re.DOTALL)

    def _describe_code(self, first_line: str, lang: str, line_count: int) -> str:
        """Generate smart description for code blocks (Option 4 - AI-assisted)"""
        lang_display = lang.capitalize() if lang else "Code"

        # Pattern matching for common code structures
        if "def " in first_line or "function " in first_line:
            # Function definition
            func_name = (
                first_line.split("(")[0].split()[-1]
                if "(" in first_line
                else "a function"
            )
            return f"The following {lang_display} code defines {func_name} in {line_count} lines."

        if "class " in first_line:
            # Class definition
            class_name = (
                first_line.split(":")[0].split()[-1] if ":" in first_line else "a class"
            )
            return f"The following {lang_display} code defines {class_name} in {line_count} lines."

        if first_line.startswith("import ") or first_line.startswith("from "):
            # Imports section
            return f"The following {lang_display} code shows imports and setup in {line_count} lines."

        if "{" in first_line or "BEGIN" in first_line.upper():
            # Block structure
            return f"The following {lang_display} code block contains {line_count} lines of implementation."

        # Generic description
        snippet = first_line[:50] + "..." if len(first_line) > 50 else first_line
        return f"The following {lang_display} code, starting with {snippet}, contains {line_count} lines."

    def _tag_blockquotes(self, text: str) -> str:
        """Tag blockquotes for voice switching"""

        # Find blockquote sections
        def replace_quote(match):
            content = match.group(0)
            # Remove > markers
            content = re.sub(r"^> ", "", content, flags=re.MULTILINE)
            return f"<VOICE:QUOTE>{content}</VOICE:QUOTE>"

        return re.sub(r"(^> .+$\n?)+", replace_quote, text, flags=re.MULTILINE)

    def _tag_headers(self, text: str) -> str:
        """Tag headers for voice switching"""
        # H1: "Section: Title"
        text = re.sub(
            r"^# (.+)$",
            r"<VOICE:HEADER>Section: \1.</VOICE:HEADER>",
            text,
            flags=re.MULTILINE,
        )

        # H2: "Subsection: Title"
        text = re.sub(
            r"^## (.+)$",
            r"<VOICE:HEADER>Subsection: \1.</VOICE:HEADER>",
            text,
            flags=re.MULTILINE,
        )

        # H3: "Topic: Title"
        text = re.sub(
            r"^### (.+)$",
            r"<VOICE:HEADER>Topic: \1.</VOICE:HEADER>",
            text,
            flags=re.MULTILINE,
        )

        # H4+: Just the title with header voice
        text = re.sub(
            r"^#### (.+)$",
            r"<VOICE:HEADER>\1.</VOICE:HEADER>",
            text,
            flags=re.MULTILINE,
        )
        text = re.sub(
            r"^##### (.+)$",
            r"<VOICE:HEADER>\1.</VOICE:HEADER>",
            text,
            flags=re.MULTILINE,
        )
        text = re.sub(
            r"^###### (.+)$",
            r"<VOICE:HEADER>\1.</VOICE:HEADER>",
            text,
            flags=re.MULTILINE,
        )

        return text

    def _convert_headers(self, text: str) -> str:
        """Convert markdown headers to natural speech"""

        # H1: "Section: Title"
        text = re.sub(r"^# (.+)$", r"Section: \1.", text, flags=re.MULTILINE)

        # H2: "Subsection: Title"
        text = re.sub(r"^## (.+)$", r"Subsection: \1.", text, flags=re.MULTILINE)

        # H3: "Topic: Title"
        text = re.sub(r"^### (.+)$", r"Topic: \1.", text, flags=re.MULTILINE)

        # H4+: Just the title
        text = re.sub(r"^#### (.+)$", r"\1.", text, flags=re.MULTILINE)
        text = re.sub(r"^##### (.+)$", r"\1.", text, flags=re.MULTILINE)
        text = re.sub(r"^###### (.+)$", r"\1.", text, flags=re.MULTILINE)

        return text

    def _handle_code_blocks(self, text: str) -> str:
        """Handle code blocks - describe or remove"""

        # Option 1: Remove entirely (simplest)
        text = re.sub(
            r"```[\w]*\n.*?\n```", "[Code example omitted]", text, flags=re.DOTALL
        )

        # Option 2: Describe (more informative)
        # def replace_code(match):
        #     lang = match.group(1) or "code"
        #     return f"[{lang.capitalize()} code example]"
        # text = re.sub(r'```([\w]*)\n.*?\n```', replace_code, text, flags=re.DOTALL)

        return text

    def _handle_tables(self, text: str) -> str:
        """Handle markdown tables - describe or remove"""

        # Detect tables (look for | separators)
        def replace_table(match: Any) -> str:
            lines = match.group(0).strip().split("\n")
            # Count rows (minus separator line)
            rows = len(
                [line for line in lines if not re.match(r"^\|[\s\-:]+\|$", line)]
            )
            return f"[Table with {rows} rows]"

        text = re.sub(r"(\|.+\|\n)+", replace_table, text, flags=re.MULTILINE)

        return text

    def _clean_markdown_syntax(self, text: str) -> str:
        """Remove markdown syntax"""

        # Bold/italic
        text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)  # **bold**
        text = re.sub(r"\*(.+?)\*", r"\1", text)  # *italic*
        text = re.sub(r"__(.+?)__", r"\1", text)  # __bold__
        text = re.sub(r"_(.+?)_", r"\1", text)  # _italic_

        # Links: [text](url) → text
        text = re.sub(r"\[(.+?)\]\(.+?\)", r"\1", text)

        # Images: ![alt](url) → [Image: alt]
        text = re.sub(r"!\[(.+?)\]\(.+?\)", r"[Image: \1]", text)

        # Inline code: `code` → code
        text = re.sub(r"`(.+?)`", r"\1", text)

        # Lists: - item → item
        text = re.sub(r"^[\-\*\+] ", "", text, flags=re.MULTILINE)

        # Numbered lists: 1. item → item
        text = re.sub(r"^\d+\. ", "", text, flags=re.MULTILINE)

        # Blockquotes: > text → text
        text = re.sub(r"^> ", "", text, flags=re.MULTILINE)

        # Horizontal rules
        text = re.sub(r"^[\-\*_]{3,}$", "", text, flags=re.MULTILINE)

        return text

    def _normalize_whitespace(self, text: str) -> str:
        """Normalize whitespace"""

        # Remove multiple blank lines
        text = re.sub(r"\n{3,}", "\n\n", text)

        # Remove leading/trailing whitespace on lines
        text = "\n".join(line.strip() for line in text.split("\n"))

        # Remove multiple spaces
        text = re.sub(r" {2,}", " ", text)

        return text.strip()

    def _add_pauses(self, text: str) -> str:
        """Add natural pauses for better speech flow"""

        # Longer pause after sections
        text = re.sub(r"\.(Section:|Subsection:|Topic:)", r".\n\n\1", text)

        # Pause after paragraphs (double newline)
        # (Already handled by markdown structure)

        return text


class ChunkManager:
    """Manage text chunking for API limits"""

    def __init__(self, max_chunk_size: int = 5000):
        self.max_chunk_size = max_chunk_size

    def chunk(self, text: str, preserve_sentences: bool = True) -> list[str]:
        """Split text into chunks respecting API limits"""

        if len(text) <= self.max_chunk_size:
            return [text]

        chunks = []

        if preserve_sentences:
            # Split on sentence boundaries
            sentences = re.split(r"([.!?]\s+)", text)
            current_chunk = ""

            for i in range(0, len(sentences), 2):
                sentence = sentences[i]
                delimiter = sentences[i + 1] if i + 1 < len(sentences) else ""

                if (
                    len(current_chunk) + len(sentence) + len(delimiter)
                    <= self.max_chunk_size
                ):
                    current_chunk += sentence + delimiter
                else:
                    if current_chunk:
                        chunks.append(current_chunk.strip())
                    current_chunk = sentence + delimiter

            if current_chunk:
                chunks.append(current_chunk.strip())
        else:
            # Simple split at max_chunk_size
            chunks = [
                text[i : i + self.max_chunk_size]
                for i in range(0, len(text), self.max_chunk_size)
            ]

        return chunks


class ElevenLabsTTS:
    """11 Labs TTS provider"""

    def __init__(self, api_key: str, voice: str = "Adam"):
        if not HAS_ELEVENLABS:
            raise ImportError(
                "elevenlabs package not installed: pip install elevenlabs"
            )

        self.client = ElevenLabs(api_key=api_key)
        self.voice = voice

    def generate(self, text: str, output_path: str) -> None:
        """Generate audio from text"""

        # Generate audio using new client API
        audio = self.client.text_to_speech.convert(
            text=text, voice_id=self.voice, model_id="eleven_multilingual_v2"
        )

        # Save to file
        with open(output_path, "wb") as f:
            for chunk in audio:
                f.write(chunk)


class OpenAITTS:
    """OpenAI TTS provider"""

    def __init__(self, api_key: str, voice: str = "alloy", model: str = "tts-1-hd"):
        if not HAS_OPENAI:
            raise ImportError("openai package not installed: pip install openai")

        self.client = OpenAI(api_key=api_key)
        self.voice = voice
        self.model = model

    def generate(self, text: str, output_path: str) -> None:
        """Generate audio from text"""

        response = self.client.audio.speech.create(
            model=self.model, voice=self.voice, input=text
        )

        response.stream_to_file(output_path)


class MacOSTTS:
    """macOS native TTS provider using 'say' command"""

    def __init__(self, voice: str = "Daniel"):
        self.voice = voice

    def generate(self, text: str, output_path: str) -> None:
        """Generate audio from text using macOS say command"""
        # Generate AIFF file first (say command output format)
        aiff_path = str(Path(output_path).with_suffix(".aiff"))

        try:
            # Use say command to generate audio
            subprocess.run(
                ["say", "-v", self.voice, "-o", aiff_path, text],
                check=True,
                capture_output=True,
                text=True,
            )

            # Convert AIFF to MP3 using ffmpeg
            subprocess.run(
                [
                    "ffmpeg",
                    "-i",
                    aiff_path,
                    "-acodec",
                    "libmp3lame",
                    "-b:a",
                    "192k",
                    output_path,
                    "-y",  # Overwrite output file
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        finally:
            # Clean up temporary AIFF file
            if Path(aiff_path).exists():
                Path(aiff_path).unlink()


class VoiceMapper:
    """Maps content types to voices for multi-voice narration"""

    def __init__(
        self,
        provider: str = "macos",
        narrator_voice: str | None = None,
        conservative_mode: bool = False,
    ):
        """
        Initialize voice mapper with sensible defaults for non-US English voices

        Voice palette (Premium/Enhanced macOS):
        - Jamie (Premium) UK Male - warm, professional narration
        - Lee (Premium) AU Male - different accent for structure
        - Serena (Premium) UK Female - elegant quotes
        - Fred (Basic) - robotic technical voice

        Args:
            provider: TTS provider ("macos", "elevenlabs", etc.)
            narrator_voice: Custom voice for narration (default: Jamie)
            conservative_mode: If True, only switch voices for CODE blocks (Option A)
        """
        if provider == "macos":
            # Use custom narrator if specified, otherwise default to Jamie
            narrator = narrator_voice or "Jamie"

            if conservative_mode:
                # Option A: Conservative multi-voice - only switch for code blocks
                self.voice_map = {
                    "NARRATION": narrator,  # Primary voice
                    "HEADER": narrator,  # Same as narration (NO switch)
                    "CODE": "Fred",  # Only switch - robotic for code
                    "QUOTE": narrator,  # Same as narration (NO switch)
                }
            else:
                # Option B: Full multi-voice - switch for headers, code, quotes
                # Build voice palette ensuring narrator isn't reused for other roles
                available_premium = ["Jamie", "Lee", "Serena", "Aman", "Tara"]
                available_premium.remove(
                    narrator
                ) if narrator in available_premium else None

                self.voice_map = {
                    "NARRATION": narrator,  # Main narrator (customizable)
                    "HEADER": available_premium[0]
                    if available_premium
                    else "Lee",  # Different premium for structure
                    "CODE": "Fred",  # Basic - robotic technical
                    "QUOTE": available_premium[1]
                    if len(available_premium) > 1
                    else "Serena",  # Different premium for quotes
                }
        else:
            # For 11 Labs or OpenAI, use single voice (multi-voice needs voice IDs)
            self.voice_map = {
                "NARRATION": "default",
                "HEADER": "default",
                "CODE": "default",
                "QUOTE": "default",
            }

    def get_voice(self, content_type: str) -> str:
        """Get voice for content type"""
        return self.voice_map.get(content_type, self.voice_map["NARRATION"])


class AudioMixer:
    """Advanced audio mixing with crossfading and normalization (Option C)"""

    def __init__(
        self,
        crossfade_duration: float = 0.5,
        normalize: bool = True,
        background_music: str | None = None,
    ):
        """
        Initialize audio mixer

        Args:
            crossfade_duration: Duration of crossfade between segments (seconds)
            normalize: Apply volume normalization to all segments
            background_music: Path to background music file (optional)
        """
        self.crossfade_duration = crossfade_duration
        self.normalize = normalize
        self.background_music = background_music

    def normalize_audio(self, input_path: str, output_path: str) -> None:
        """Normalize audio volume using loudnorm filter"""
        subprocess.run(
            [
                "ffmpeg",
                "-i",
                input_path,
                "-af",
                "loudnorm=I=-16:TP=-1.5:LRA=11",
                "-ar",
                "44100",
                output_path,
                "-y",
            ],
            check=True,
            capture_output=True,
        )

    def crossfade_segments(self, segments: list[Path], output_path: str) -> None:
        """
        Crossfade audio segments together for smooth transitions

        Uses ffmpeg's acrossfade filter with adelay offsets to preserve full duration.
        Each segment is delayed so that crossfades overlap without losing content.

        The strategy:
        - Apply delays to position segments correctly in time
        - Use acrossfade to blend overlapping regions
        - Ensure final duration = sum(segments) - (N-1)*crossfade_duration
        """
        if len(segments) == 1:
            # Single segment - just copy (with normalization if enabled)
            if self.normalize:
                self.normalize_audio(str(segments[0]), output_path)
            else:
                import shutil

                shutil.copy(segments[0], output_path)
            return

        # Normalize all segments first if requested
        normalized_segments = []
        if self.normalize:
            for i, segment in enumerate(segments):
                norm_path = segment.parent / f"norm_{segment.name}"
                self.normalize_audio(str(segment), str(norm_path))
                normalized_segments.append(norm_path)
        else:
            normalized_segments = segments

        # Build complex ffmpeg filter for crossfading
        # Strategy: Chain acrossfade filters sequentially
        # The key insight: acrossfade INTENTIONALLY overlaps by crossfade_duration
        # This is NOT a bug - during crossfade, both audio streams are audible (fading)
        # Total duration = sum(segments) - (N-1)*crossfade_duration

        inputs = " ".join([f"-i {seg}" for seg in normalized_segments])

        # Build filter chain
        filter_parts = []
        for i in range(len(normalized_segments) - 1):
            if i == 0:
                # First crossfade: [0][1]acrossfade
                filter_parts.append(
                    f"[0][1]acrossfade=d={self.crossfade_duration}:c1=tri:c2=tri[a{i}]"
                )
            else:
                # Subsequent crossfades: [a{i-1}][{i+1}]acrossfade
                filter_parts.append(
                    f"[a{i-1}][{i+1}]acrossfade=d={self.crossfade_duration}:c1=tri:c2=tri[a{i}]"
                )

        filter_complex = ";".join(filter_parts)
        last_label = (
            f"a{len(normalized_segments) - 2}" if len(normalized_segments) > 2 else "a0"
        )

        # Execute ffmpeg with filter complex
        cmd = f'ffmpeg {inputs} -filter_complex "{filter_complex}" -map "[{last_label}]" {output_path} -y'

        subprocess.run(cmd, shell=True, check=True, capture_output=True)

        # Cleanup normalized temp files
        if self.normalize:
            for norm_seg in normalized_segments:
                if norm_seg.exists():
                    norm_seg.unlink()

    def mix_with_background(
        self, foreground: str, output_path: str, volume: float = 0.1
    ) -> None:
        """
        Mix foreground audio with background music

        Args:
            foreground: Path to main audio (narration)
            output_path: Output path
            volume: Background music volume (0.0-1.0, default 0.1 = 10%)
        """
        if not self.background_music or not Path(self.background_music).exists():
            # No background music - just copy
            import shutil

            shutil.copy(foreground, output_path)
            return

        # Get duration of foreground
        duration_result = subprocess.run(
            [
                "ffprobe",
                "-v",
                "error",
                "-show_entries",
                "format=duration",
                "-of",
                "default=noprint_wrappers=1:nokey=1",
                foreground,
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        duration = float(duration_result.stdout.strip())

        # Mix foreground with looped background music
        subprocess.run(
            [
                "ffmpeg",
                "-i",
                foreground,
                "-stream_loop",
                "-1",  # Loop background infinitely
                "-i",
                self.background_music,
                "-filter_complex",
                f"[1]volume={volume},aloop=loop=-1:size=2e9[bg];[0][bg]amix=inputs=2:duration=first",
                "-t",
                str(duration),  # Match foreground duration
                output_path,
                "-y",
            ],
            check=True,
            capture_output=True,
        )


class MultiVoiceTTS:
    """Multi-voice TTS generator using macOS voices"""

    def __init__(
        self, voice_mapper: VoiceMapper, audio_mixer: AudioMixer | None = None
    ):
        self.voice_mapper = voice_mapper
        self.audio_mixer = audio_mixer

    def parse_segments(self, text: str) -> list[tuple[str, str]]:
        """
        Parse tagged text into (voice, content) segments

        Returns: [(voice, text), ...]
        """
        segments = []
        current_pos = 0

        # Find all voice tags
        pattern = r"<VOICE:(\w+)>(.*?)</VOICE:\1>"

        for match in re.finditer(pattern, text, flags=re.DOTALL):
            # Add narration before this tag
            if match.start() > current_pos:
                narration = text[current_pos : match.start()].strip()
                if narration:
                    voice = self.voice_mapper.get_voice("NARRATION")
                    segments.append((voice, narration))

            # Add tagged content
            content_type = match.group(1)
            content = match.group(2).strip()
            if content:
                voice = self.voice_mapper.get_voice(content_type)
                segments.append((voice, content))

            current_pos = match.end()

        # Add any remaining narration
        if current_pos < len(text):
            narration = text[current_pos:].strip()
            if narration:
                voice = self.voice_mapper.get_voice("NARRATION")
                segments.append((voice, narration))

        return segments

    def generate_multivoice(
        self, text: str, output_path: str, conservative_pauses: bool = False
    ) -> None:
        """Generate multi-voice audio from tagged text

        Args:
            text: Tagged markdown text
            output_path: Output file path
            conservative_pauses: Use 2.5s pauses for voice changes (Option A)
        """
        segments = self.parse_segments(text)

        if not segments:
            return

        # Generate audio for each segment, tracking voices
        temp_files_with_voices = []  # List of (voice, Path) tuples
        temp_dir = Path(output_path).parent / "temp_segments"
        temp_dir.mkdir(exist_ok=True)

        try:
            for i, (voice, content) in enumerate(segments):
                segment_file = temp_dir / f"segment_{i:04d}.mp3"

                # Generate with macOS say
                tts = MacOSTTS(voice=voice)
                tts.generate(content, str(segment_file))
                temp_files_with_voices.append((voice, segment_file))

            # Use conservative pauses if requested (Option A)
            if conservative_pauses:
                self._stitch_audio_with_pauses(temp_files_with_voices, output_path)
            # Use advanced mixing if AudioMixer available (Option C)
            elif self.audio_mixer:
                temp_output = temp_dir / "mixed_output.mp3"
                files_only = [f for _, f in temp_files_with_voices]
                self.audio_mixer.crossfade_segments(files_only, str(temp_output))

                # Add background music if configured
                if self.audio_mixer.background_music:
                    self.audio_mixer.mix_with_background(str(temp_output), output_path)
                    temp_output.unlink()
                else:
                    import shutil

                    shutil.move(str(temp_output), output_path)
            else:
                # Option B: Basic concatenation with silence
                files_only = [f for _, f in temp_files_with_voices]
                self._stitch_audio(files_only, output_path)

        finally:
            # Cleanup temp files
            for _, temp_file in temp_files_with_voices:
                if temp_file.exists():
                    temp_file.unlink()
            if temp_dir.exists() and not any(temp_dir.iterdir()):
                temp_dir.rmdir()

    def _stitch_audio(self, input_files: list[Path], output_path: str) -> None:
        """Stitch audio segments together with silence between"""

        if len(input_files) == 1:
            # Just rename/copy single file
            import shutil

            shutil.copy(input_files[0], output_path)
            return

        # Create concat file for ffmpeg
        concat_file = Path(output_path).parent / "concat_list.txt"

        try:
            with open(concat_file, "w") as f:
                for i, audio_file in enumerate(input_files):
                    f.write(f"file '{audio_file.absolute()}'\n")
                    # Add 300ms silence between segments (except after last)
                    if i < len(input_files) - 1:
                        # Generate tiny silence file
                        silence_file = audio_file.parent / f"silence_{i:04d}.mp3"
                        subprocess.run(
                            [
                                "ffmpeg",
                                "-f",
                                "lavfi",
                                "-i",
                                "anullsrc=r=44100:cl=stereo",
                                "-t",
                                "0.3",
                                "-acodec",
                                "libmp3lame",
                                "-b:a",
                                "192k",
                                str(silence_file),
                                "-y",
                            ],
                            check=True,
                            capture_output=True,
                        )
                        f.write(f"file '{silence_file.absolute()}'\n")

            # Concatenate with ffmpeg
            subprocess.run(
                [
                    "ffmpeg",
                    "-f",
                    "concat",
                    "-safe",
                    "0",
                    "-i",
                    str(concat_file),
                    "-c",
                    "copy",
                    output_path,
                    "-y",
                ],
                check=True,
                capture_output=True,
            )

        finally:
            # Cleanup
            if concat_file.exists():
                concat_file.unlink()
            # Cleanup silence files
            for i in range(len(input_files) - 1):
                silence_file = input_files[0].parent / f"silence_{i:04d}.mp3"
                if silence_file.exists():
                    silence_file.unlink()

    def _stitch_audio_with_pauses(
        self, segments: list[tuple[str, Path]], output_path: str
    ) -> None:
        """
        Stitch audio with intelligent pause insertion (Option A)

        Args:
            segments: List of (voice, audio_file) tuples
            output_path: Output file path

        Pause strategy:
        - 2.5 seconds before voice changes (research-backed)
        - 0.3 seconds between same-voice segments
        """
        if len(segments) == 1:
            import shutil

            shutil.copy(segments[0][1], output_path)
            return

        concat_file = Path(output_path).parent / "concat_list.txt"

        try:
            with open(concat_file, "w") as f:
                for i, (voice, audio_file) in enumerate(segments):
                    f.write(f"file '{audio_file.absolute()}'\n")

                    # Add silence between segments (except after last)
                    if i < len(segments) - 1:
                        # Detect voice change
                        next_voice = segments[i + 1][0]
                        voice_changed = voice != next_voice

                        # 2.5s for voice changes (research-backed standard)
                        # 0.3s for same voice (existing behavior)
                        silence_duration = 2.5 if voice_changed else 0.3

                        # Debug output
                        print(
                            f"   Segment {i}: {voice} → {next_voice} | Change: {voice_changed} | Pause: {silence_duration}s"
                        )

                        # Generate silence using pydub (more reliable than ffmpeg)
                        try:
                            from pydub import AudioSegment
                            from pydub.generators import Sine

                            # Create silence of the specified duration
                            silence = AudioSegment.silent(
                                duration=int(silence_duration * 1000)
                            )  # pydub uses milliseconds
                            silence_file = audio_file.parent / f"silence_{i:04d}.mp3"
                            silence.export(
                                str(silence_file), format="mp3", bitrate="192k"
                            )
                            f.write(f"file '{silence_file.absolute()}'\n")
                        except ImportError:
                            # Fallback to ffmpeg if pydub not available
                            silence_file = audio_file.parent / f"silence_{i:04d}.mp3"
                            subprocess.run(
                                [
                                    "ffmpeg",
                                    "-f",
                                    "lavfi",
                                    "-i",
                                    "anullsrc=r=44100:cl=stereo",
                                    "-t",
                                    str(silence_duration),
                                    "-acodec",
                                    "libmp3lame",
                                    "-b:a",
                                    "192k",
                                    str(silence_file),
                                    "-y",
                                ],
                                check=True,
                                capture_output=True,
                            )
                            f.write(f"file '{silence_file.absolute()}'\n")

            # Concatenate with ffmpeg
            subprocess.run(
                [
                    "ffmpeg",
                    "-f",
                    "concat",
                    "-safe",
                    "0",
                    "-i",
                    str(concat_file),
                    "-c",
                    "copy",
                    output_path,
                    "-y",
                ],
                check=True,
                capture_output=True,
            )

        finally:
            # Cleanup
            if concat_file.exists():
                concat_file.unlink()
            # Cleanup silence files
            for i in range(len(segments) - 1):
                silence_file = segments[0][1].parent / f"silence_{i:04d}.mp3"
                if silence_file.exists():
                    silence_file.unlink()


class DocToAudioConverter:
    """Main converter orchestrator"""

    tts: Union["ElevenLabsTTS", "OpenAITTS", "MacOSTTS", "MultiVoiceTTS"]

    def __init__(
        self,
        provider: str = "elevenlabs",
        api_key: str | None = None,
        voice: str | None = None,
        output_dir: str = "audio",
        multi_voice: bool = False,
        advanced_mixing: bool = False,
        crossfade_duration: float = 0.5,
        normalize: bool = True,
        background_music: str | None = None,
        narrator_voice: str | None = None,
        conservative_multivoice: bool = False,
    ):
        self.console = Console() if HAS_RICH else None
        self.cleaner = MarkdownCleaner(multi_voice=multi_voice)
        self.chunker = ChunkManager(max_chunk_size=5000)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.multi_voice = multi_voice
        self.advanced_mixing = advanced_mixing
        self.narrator_voice = narrator_voice
        self.conservative_multivoice = conservative_multivoice

        # Initialize TTS provider
        if multi_voice:
            # Multi-voice currently only supported with macOS
            if provider != "macos":
                raise ValueError(
                    "Multi-voice currently only supported with macOS provider"
                )

            voice_mapper = VoiceMapper(
                provider="macos",
                narrator_voice=narrator_voice,
                conservative_mode=conservative_multivoice,
            )

            # Create AudioMixer if advanced mixing enabled
            audio_mixer = None
            if advanced_mixing:
                audio_mixer = AudioMixer(
                    crossfade_duration=crossfade_duration,
                    normalize=normalize,
                    background_music=background_music,
                )

            self.tts = MultiVoiceTTS(voice_mapper=voice_mapper, audio_mixer=audio_mixer)
        elif provider == "macos":
            # macOS doesn't need an API key
            self.tts = MacOSTTS(voice=voice or "Daniel")
        else:
            if api_key is None:
                api_key = self._get_api_key(provider)

            if provider == "elevenlabs":
                self.tts = ElevenLabsTTS(api_key=api_key, voice=voice or "Adam")
            elif provider == "openai":
                self.tts = OpenAITTS(api_key=api_key, voice=voice or "alloy")
            else:
                raise ValueError(f"Unsupported provider: {provider}")

    def _get_api_key(self, provider: str) -> str:
        """Get API key from environment"""

        env_vars = {
            "elevenlabs": "ELEVEN_LABS_API_KEY",
            "openai": "OPENAI_API_KEY",
        }

        env_var = env_vars.get(provider)
        if not env_var:
            raise ValueError(f"Unknown provider: {provider}")

        api_key = os.environ.get(env_var)
        if not api_key:
            raise ValueError(f"API key not found. Set {env_var} environment variable.")

        return api_key

    def convert_file(
        self, input_path: str, output_name: str | None = None
    ) -> list[Path]:
        """Convert single markdown file to audio"""

        input_path_obj = Path(input_path)
        if not input_path_obj.exists():
            raise FileNotFoundError(f"Input file not found: {input_path}")

        if output_name is None:
            output_name = input_path_obj.stem

        self.print_info(f"\n📄 Processing: {input_path_obj.name}")

        # Read markdown
        with open(input_path_obj) as f:
            markdown = f.read()

        # Clean for TTS (with or without voice tags)
        if self.multi_voice:
            cleaned = self.cleaner.clean_with_tags(markdown)
        else:
            cleaned = self.cleaner.clean(markdown)

        # Chunk if needed
        chunks = self.chunker.chunk(cleaned)

        self.print_info(f"   Chunks: {len(chunks)}")
        if self.multi_voice:
            narrator = self.narrator_voice or "Jamie"
            if self.advanced_mixing:
                self.print_info("   Mode: Multi-voice + Advanced Mixing (Option C)")
                self.print_info(f"   Narrator: {narrator}")
                self.print_info("   Features: Crossfading, Normalization")
            else:
                self.print_info("   Mode: Multi-voice (Option B)")
                self.print_info(f"   Narrator: {narrator}")

        # Generate audio for each chunk
        audio_files: list[Path] = []
        for i, chunk in enumerate(chunks):
            chunk_name = f"{output_name}_part{i+1:03d}.mp3"
            chunk_path = self.output_dir / chunk_name

            self.print_info(f"   Generating: {chunk_name}")

            try:
                if self.multi_voice:
                    # Use multi-voice generation
                    self.tts.generate_multivoice(
                        chunk,
                        str(chunk_path),
                        conservative_pauses=self.conservative_multivoice,
                    )
                else:
                    # Use single-voice generation
                    self.tts.generate(chunk, str(chunk_path))
                audio_files.append(chunk_path)
            except Exception as e:
                self.print_error(f"   Error: {e}")
                continue

        # Generate metadata
        metadata_path = self.output_dir / f"{output_name}_metadata.json"
        self._write_metadata(metadata_path, input_path_obj, audio_files)

        self.print_success(f"✅ Complete: {output_name} ({len(audio_files)} parts)")

        return audio_files

    def convert_directory(self, input_dir: str, recursive: bool = False) -> None:
        """Convert all markdown files in directory"""

        input_dir_obj = Path(input_dir)
        if not input_dir_obj.is_dir():
            raise NotADirectoryError(f"Not a directory: {input_dir}")

        pattern = "**/*.md" if recursive else "*.md"
        md_files = list(input_dir_obj.glob(pattern))

        self.print_info(f"\n📁 Found {len(md_files)} markdown files")

        for md_file in md_files:
            try:
                # Generate output name from relative path
                rel_path = md_file.relative_to(input_dir_obj)
                output_name = str(rel_path.with_suffix("")).replace("/", "_")

                self.convert_file(str(md_file), output_name)
            except Exception as e:
                self.print_error(f"Error processing {md_file}: {e}")
                continue

    def _write_metadata(
        self, metadata_path: Path, input_path: Path, audio_files: list[Path]
    ) -> None:
        """Write metadata file"""

        metadata = {
            "source": str(input_path),
            "audio_files": [str(f) for f in audio_files],
            "parts": len(audio_files),
            "generated": str(Path(audio_files[0]).parent),
        }

        with open(metadata_path, "w") as f:
            json.dump(metadata, f, indent=2)

    def print_info(self, text: str) -> None:
        """Print info message"""
        if HAS_RICH:
            self.console.print(f"[cyan]{text}[/cyan]")  # type: ignore[union-attr]
        else:
            print(text)

    def print_success(self, text: str) -> None:
        """Print success message"""
        if HAS_RICH:
            self.console.print(f"[green]{text}[/green]")  # type: ignore[union-attr]
        else:
            print(text)

    def print_error(self, text: str) -> None:
        """Print error message"""
        if HAS_RICH:
            self.console.print(f"[red]{text}[/red]")  # type: ignore[union-attr]
        else:
            print(f"ERROR: {text}")


def main() -> None:
    """Main entry point"""

    parser = argparse.ArgumentParser(
        description="Convert documentation to audio using TTS APIs"
    )

    parser.add_argument(
        "--input", required=True, help="Input markdown file or directory"
    )

    parser.add_argument(
        "--output", default="audio", help="Output directory for audio files"
    )

    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Recursively process directories",
    )

    parser.add_argument(
        "--provider",
        default="elevenlabs",
        choices=["elevenlabs", "openai", "macos"],
        help="TTS provider (default: elevenlabs)",
    )

    parser.add_argument(
        "--api-key",
        help="API key (or set ELEVEN_LABS_API_KEY / OPENAI_API_KEY env var). Not needed for macOS provider.",
    )

    parser.add_argument(
        "--voice",
        help="Voice to use (e.g., 'Adam' for 11 Labs, 'alloy' for OpenAI, 'Daniel' for macOS)",
    )

    parser.add_argument(
        "--multi-voice",
        action="store_true",
        help="Enable multi-voice narration (macOS only). Uses Jamie (narration), Lee (headers), Serena (quotes), Fred (code)",
    )

    parser.add_argument(
        "--conservative-multivoice",
        action="store_true",
        help="Conservative multi-voice mode (Option A): Only switch voices for code blocks, with 2.5s pauses. Requires --multi-voice.",
    )

    parser.add_argument(
        "--advanced-mixing",
        action="store_true",
        help="Enable advanced audio mixing (Option C): crossfading, normalization. Requires --multi-voice.",
    )

    parser.add_argument(
        "--crossfade",
        type=float,
        default=0.5,
        help="Crossfade duration in seconds (default: 0.5). Only with --advanced-mixing.",
    )

    parser.add_argument(
        "--no-normalize",
        action="store_true",
        help="Disable volume normalization. Only with --advanced-mixing.",
    )

    parser.add_argument(
        "--background-music",
        type=str,
        help="Path to background music file (loops, mixed at 10%% volume). Only with --advanced-mixing.",
    )

    parser.add_argument(
        "--narrator",
        type=str,
        help="Custom narrator voice for multi-voice mode (Jamie, Lee, Serena, Aman, Tara). Default: Jamie.",
    )

    args = parser.parse_args()

    try:
        converter = DocToAudioConverter(
            provider=args.provider,
            api_key=args.api_key,
            voice=args.voice,
            output_dir=args.output,
            multi_voice=args.multi_voice,
            advanced_mixing=args.advanced_mixing,
            crossfade_duration=args.crossfade,
            normalize=not args.no_normalize,
            background_music=args.background_music,
            narrator_voice=args.narrator,
            conservative_multivoice=args.conservative_multivoice,
        )

        input_path = Path(args.input)

        if input_path.is_file():
            converter.convert_file(input_path)
        elif input_path.is_dir():
            converter.convert_directory(input_path, recursive=args.recursive)
        else:
            print(f"Error: {input_path} is neither a file nor directory")
            sys.exit(1)

    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
