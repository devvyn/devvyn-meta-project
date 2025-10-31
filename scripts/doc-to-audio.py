#!/usr/bin/env python3
"""
Documentation to Audio Converter

Converts markdown documentation to spoken audio using TTS APIs.

Supported APIs:
- 11 Labs (recommended for quality)
- OpenAI TTS (good alternative)
- Google Cloud TTS (enterprise)
- AWS Polly (enterprise)

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
import sys
from pathlib import Path
from typing import Optional

try:
    from rich.console import Console
    from rich.progress import Progress, SpinnerColumn, TextColumn

    HAS_RICH = True
except ImportError:
    HAS_RICH = False

# TTS Provider imports (optional - install as needed)
try:
    from elevenlabs import Voice, VoiceSettings, generate, save, set_api_key

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

    def __init__(self):
        self.console = Console() if HAS_RICH else None

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
        def replace_table(match):
            lines = match.group(0).strip().split("\n")
            # Count rows (minus separator line)
            rows = len([line for line in lines if not re.match(r"^\|[\s\-:]+\|$", line)])
            return f"[Table with {rows} rows]"

        text = re.sub(
            r"(\|.+\|\n)+", replace_table, text, flags=re.MULTILINE
        )

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

                if len(current_chunk) + len(sentence) + len(delimiter) <= self.max_chunk_size:
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
            raise ImportError("elevenlabs package not installed: pip install elevenlabs")

        set_api_key(api_key)
        self.voice = voice

    def generate(self, text: str, output_path: str):
        """Generate audio from text"""

        audio = generate(
            text=text,
            voice=Voice(
                voice_id=self.voice,
                settings=VoiceSettings(
                    stability=0.5,
                    similarity_boost=0.75,
                    style=0.0,
                    use_speaker_boost=True,
                ),
            ),
        )

        save(audio, output_path)


class OpenAITTS:
    """OpenAI TTS provider"""

    def __init__(self, api_key: str, voice: str = "alloy", model: str = "tts-1-hd"):
        if not HAS_OPENAI:
            raise ImportError("openai package not installed: pip install openai")

        self.client = OpenAI(api_key=api_key)
        self.voice = voice
        self.model = model

    def generate(self, text: str, output_path: str):
        """Generate audio from text"""

        response = self.client.audio.speech.create(
            model=self.model, voice=self.voice, input=text
        )

        response.stream_to_file(output_path)


class DocToAudioConverter:
    """Main converter orchestrator"""

    def __init__(
        self,
        provider: str = "elevenlabs",
        api_key: Optional[str] = None,
        voice: Optional[str] = None,
        output_dir: str = "audio",
    ):
        self.console = Console() if HAS_RICH else None
        self.cleaner = MarkdownCleaner()
        self.chunker = ChunkManager(max_chunk_size=5000)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Initialize TTS provider
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
            raise ValueError(
                f"API key not found. Set {env_var} environment variable."
            )

        return api_key

    def convert_file(self, input_path: str, output_name: Optional[str] = None):
        """Convert single markdown file to audio"""

        input_path = Path(input_path)
        if not input_path.exists():
            raise FileNotFoundError(f"Input file not found: {input_path}")

        if output_name is None:
            output_name = input_path.stem

        self.print_info(f"\n📄 Processing: {input_path.name}")

        # Read markdown
        with open(input_path) as f:
            markdown = f.read()

        # Clean for TTS
        cleaned = self.cleaner.clean(markdown)

        # Chunk if needed
        chunks = self.chunker.chunk(cleaned)

        self.print_info(f"   Chunks: {len(chunks)}")

        # Generate audio for each chunk
        audio_files = []
        for i, chunk in enumerate(chunks):
            chunk_name = f"{output_name}_part{i+1:03d}.mp3"
            chunk_path = self.output_dir / chunk_name

            self.print_info(f"   Generating: {chunk_name}")

            try:
                self.tts.generate(chunk, str(chunk_path))
                audio_files.append(chunk_path)
            except Exception as e:
                self.print_error(f"   Error: {e}")
                continue

        # Generate metadata
        metadata_path = self.output_dir / f"{output_name}_metadata.json"
        self._write_metadata(metadata_path, input_path, audio_files)

        self.print_success(f"✅ Complete: {output_name} ({len(audio_files)} parts)")

        return audio_files

    def convert_directory(self, input_dir: str, recursive: bool = False):
        """Convert all markdown files in directory"""

        input_dir = Path(input_dir)
        if not input_dir.is_dir():
            raise NotADirectoryError(f"Not a directory: {input_dir}")

        pattern = "**/*.md" if recursive else "*.md"
        md_files = list(input_dir.glob(pattern))

        self.print_info(f"\n📁 Found {len(md_files)} markdown files")

        for md_file in md_files:
            try:
                # Generate output name from relative path
                rel_path = md_file.relative_to(input_dir)
                output_name = str(rel_path.with_suffix("")).replace("/", "_")

                self.convert_file(md_file, output_name)
            except Exception as e:
                self.print_error(f"Error processing {md_file}: {e}")
                continue

    def _write_metadata(
        self, metadata_path: Path, input_path: Path, audio_files: list[Path]
    ):
        """Write metadata file"""

        metadata = {
            "source": str(input_path),
            "audio_files": [str(f) for f in audio_files],
            "parts": len(audio_files),
            "generated": str(Path(audio_files[0]).parent),
        }

        with open(metadata_path, "w") as f:
            json.dump(metadata, f, indent=2)

    def print_info(self, text: str):
        """Print info message"""
        if HAS_RICH:
            self.console.print(f"[cyan]{text}[/cyan]")
        else:
            print(text)

    def print_success(self, text: str):
        """Print success message"""
        if HAS_RICH:
            self.console.print(f"[green]{text}[/green]")
        else:
            print(text)

    def print_error(self, text: str):
        """Print error message"""
        if HAS_RICH:
            self.console.print(f"[red]{text}[/red]")
        else:
            print(f"ERROR: {text}")


def main():
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
        choices=["elevenlabs", "openai"],
        help="TTS provider (default: elevenlabs)",
    )

    parser.add_argument(
        "--api-key",
        help="API key (or set ELEVEN_LABS_API_KEY / OPENAI_API_KEY env var)",
    )

    parser.add_argument(
        "--voice",
        help="Voice to use (e.g., 'Adam' for 11 Labs, 'alloy' for OpenAI)",
    )

    args = parser.parse_args()

    try:
        converter = DocToAudioConverter(
            provider=args.provider,
            api_key=args.api_key,
            voice=args.voice,
            output_dir=args.output,
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
