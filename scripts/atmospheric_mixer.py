#!/usr/bin/env python3
"""
Atmospheric Audio Mixer - Option C Implementation
Radiolab-inspired atmospheric sound layering for documentation audio

Inspired by Jad Abumrad's "plurps and staccato bursts" philosophy
"""

from pathlib import Path
from typing import Dict, List, Tuple
import yaml

try:
    from pydub import AudioSegment
    HAS_PYDUB = True
except ImportError:
    HAS_PYDUB = False


class SoundLibrary:
    """Manages the Radiolab-inspired sound effects library"""

    def __init__(self, library_path: Path):
        """
        Load sound library from disk

        Args:
            library_path: Path to ~/devvyn-meta-project/audio-assets/atmosphere/
        """
        self.library_path = Path(library_path)
        self.sounds: Dict[str, Dict[str, AudioSegment]] = {}

        if not self.library_path.exists():
            raise FileNotFoundError(
                f"Sound library not found at {library_path}. "
                "Run generate-sound-library.py first."
            )

        self._load_library()

    def _load_library(self):
        """Load all MP3 files from the library directory structure"""
        categories = [
            "structural",
            "content_markers",
            "atmosphere",
            "emotional",
            "phase_markers"
        ]

        for category in categories:
            category_dir = self.library_path / category
            if not category_dir.exists():
                print(f"⚠️  Category not found: {category}")
                continue

            self.sounds[category] = {}
            for sound_file in category_dir.glob("*.mp3"):
                sound_name = sound_file.stem  # filename without extension
                self.sounds[category][sound_name] = AudioSegment.from_mp3(sound_file)

        print(f"✅ Loaded sound library from {self.library_path}")
        for category, sounds in self.sounds.items():
            print(f"   {category}: {len(sounds)} sounds")

    def get(self, category: str, sound_name: str) -> AudioSegment:
        """Get a sound effect from the library"""
        if category not in self.sounds:
            raise KeyError(f"Category '{category}' not found in sound library")
        if sound_name not in self.sounds[category]:
            raise KeyError(f"Sound '{sound_name}' not found in category '{category}'")
        return self.sounds[category][sound_name]


class DocumentStructure:
    """Tracks markdown document structure for atmospheric placement"""

    def __init__(self):
        self.events: List[Tuple[str, int, str]] = []
        # Format: (event_type, timestamp_ms, metadata)

    def add_event(self, event_type: str, timestamp_ms: int, metadata: str = ""):
        """Add a structural event at a specific timestamp"""
        self.events.append((event_type, timestamp_ms, metadata))

    def add_section_start(self, timestamp_ms: int, level: int):
        """Mark the start of a section (## header)"""
        self.add_event("section_start", timestamp_ms, f"level_{level}")

    def add_code_block(self, start_ms: int, end_ms: int):
        """Mark a code block region"""
        self.add_event("code_start", start_ms)
        self.add_event("code_end", end_ms)

    def add_quote(self, timestamp_ms: int):
        """Mark a blockquote"""
        self.add_event("quote_start", timestamp_ms)

    def add_important_concept(self, timestamp_ms: int):
        """Mark an important concept (e.g., callouts, key insights)"""
        self.add_event("important_concept", timestamp_ms)


class AtmosphericAudioMixer:
    """
    Mix narration with atmospheric sound effects

    Implements Option C: Conservative multi-voice + Radiolab-inspired atmosphere
    """

    def __init__(self, sound_library_path: Path, atmosphere_mode: str = "subtle"):
        """
        Args:
            sound_library_path: Path to sound library
            atmosphere_mode: "subtle", "moderate", or "bold"
        """
        if not HAS_PYDUB:
            raise ImportError("pydub is required for atmospheric mixing. Install: uv pip install pydub")

        self.library = SoundLibrary(sound_library_path)
        self.atmosphere_mode = atmosphere_mode

        # Volume levels by mode (in dB adjustment)
        self.volume_levels = {
            "subtle": {
                "structural": -15,  # 18% volume
                "markers": -10,     # 32% volume
                "atmosphere": -20,  # 10% volume
            },
            "moderate": {
                "structural": -10,  # 32% volume
                "markers": -6,      # 50% volume
                "atmosphere": -15,  # 18% volume
            },
            "bold": {
                "structural": -6,   # 50% volume
                "markers": -3,      # 71% volume
                "atmosphere": -12,  # 25% volume
            }
        }

    def add_document_bookends(self, audio: AudioSegment) -> AudioSegment:
        """Add cinematic opening and closing to document"""
        # Document start (3s opening swell)
        opening = self.library.get("structural", "document_start")
        opening = opening + self.volume_levels[self.atmosphere_mode]["structural"]

        # Document end (4s resolving closure)
        closing = self.library.get("structural", "document_end")
        closing = closing + self.volume_levels[self.atmosphere_mode]["structural"]

        # Combine: opening + fade-in narration + fade-out narration + closing
        narration = audio.fade_in(1000).fade_out(1000)
        result = opening + narration + closing

        return result

    def add_section_transitions(
        self,
        audio: AudioSegment,
        section_timestamps: List[int]
    ) -> AudioSegment:
        """
        Add section transition sounds before major headers

        Args:
            audio: Base narration audio
            section_timestamps: List of timestamps (ms) where sections start
        """
        result = audio
        transition = self.library.get("structural", "section_transition")
        transition = transition + self.volume_levels[self.atmosphere_mode]["structural"]

        for timestamp_ms in section_timestamps:
            # Insert 5s transition sound starting 2s before the section
            insert_pos = max(0, timestamp_ms - 2000)
            result = self._overlay_sound(result, transition, insert_pos)

        return result

    def add_code_atmosphere(
        self,
        audio: AudioSegment,
        code_regions: List[Tuple[int, int]]
    ) -> AudioSegment:
        """
        Layer subtle digital drone under code block narration

        Args:
            audio: Base narration audio
            code_regions: List of (start_ms, end_ms) tuples for code blocks
        """
        result = audio
        drone = self.library.get("atmosphere", "code_atmosphere")
        drone = drone + self.volume_levels[self.atmosphere_mode]["atmosphere"]

        for start_ms, end_ms in code_regions:
            duration_needed = end_ms - start_ms

            # Loop the 30s drone to cover the entire code block
            if duration_needed > len(drone):
                loops_needed = (duration_needed // len(drone)) + 1
                extended_drone = drone * loops_needed
            else:
                extended_drone = drone

            # Trim to exact duration and overlay
            extended_drone = extended_drone[:duration_needed]
            result = self._overlay_sound(result, extended_drone, start_ms)

        return result

    def add_concept_markers(
        self,
        audio: AudioSegment,
        marker_timestamps: List[int]
    ) -> AudioSegment:
        """
        Add percussive markers before important concepts

        Args:
            audio: Base narration audio
            marker_timestamps: List of timestamps (ms) for key insights
        """
        result = audio
        marker = self.library.get("content_markers", "important_concept")
        marker = marker + self.volume_levels[self.atmosphere_mode]["markers"]

        for timestamp_ms in marker_timestamps:
            # Place marker 500ms before the concept
            insert_pos = max(0, timestamp_ms - 500)
            result = self._overlay_sound(result, marker, insert_pos)

        return result

    def _overlay_sound(
        self,
        base: AudioSegment,
        sound: AudioSegment,
        position_ms: int
    ) -> AudioSegment:
        """
        Overlay a sound effect on base audio at a specific position

        Args:
            base: Base audio track
            sound: Sound effect to overlay
            position_ms: Position to start the overlay
        """
        return base.overlay(sound, position=position_ms)

    def mix_atmospheric_audio(
        self,
        narration_path: Path,
        structure: DocumentStructure,
        output_path: Path
    ) -> None:
        """
        Complete atmospheric mixing pipeline

        Args:
            narration_path: Path to base narration MP3
            structure: Document structure with event timestamps
            output_path: Where to save the final mixed audio
        """
        print(f"🎨 Atmospheric Mixing (Mode: {self.atmosphere_mode})")

        # Load base narration
        audio = AudioSegment.from_mp3(narration_path)
        print(f"   Loaded narration: {len(audio)/1000:.1f}s")

        # Extract events by type
        section_timestamps = [
            ts for event_type, ts, _ in structure.events
            if event_type == "section_start"
        ]

        code_regions = []
        code_starts = {ts: i for i, (et, ts, _) in enumerate(structure.events) if et == "code_start"}
        code_ends = {ts: i for i, (et, ts, _) in enumerate(structure.events) if et == "code_end"}
        for start_ts in sorted(code_starts.keys()):
            # Find matching end
            end_ts = min([e for e in code_ends.keys() if e > start_ts], default=start_ts + 5000)
            code_regions.append((start_ts, end_ts))

        marker_timestamps = [
            ts for event_type, ts, _ in structure.events
            if event_type == "important_concept"
        ]

        # Apply atmospheric layers
        print("   Adding document bookends...")
        audio = self.add_document_bookends(audio)

        if section_timestamps:
            print(f"   Adding {len(section_timestamps)} section transitions...")
            audio = self.add_section_transitions(audio, section_timestamps)

        if code_regions:
            print(f"   Layering code atmosphere ({len(code_regions)} regions)...")
            audio = self.add_code_atmosphere(audio, code_regions)

        if marker_timestamps:
            print(f"   Adding {len(marker_timestamps)} concept markers...")
            audio = self.add_concept_markers(audio, marker_timestamps)

        # Export final mix
        print(f"   Exporting to {output_path}...")
        audio.export(str(output_path), format="mp3", bitrate="192k")

        print(f"   ✅ Mixed audio: {len(audio)/1000:.1f}s")


# Example usage
if __name__ == "__main__":
    # Demo of how to use the atmospheric mixer
    library_path = Path.home() / "devvyn-meta-project" / "audio-assets" / "atmosphere"

    mixer = AtmosphericAudioMixer(library_path, atmosphere_mode="subtle")

    # Create example document structure
    structure = DocumentStructure()
    structure.add_section_start(5000, level=2)  # Section at 5s
    structure.add_code_block(10000, 20000)      # Code from 10s-20s
    structure.add_important_concept(25000)      # Key insight at 25s

    # Mix it
    narration = Path("/tmp/test-narration.mp3")
    output = Path("/tmp/test-atmospheric.mp3")

    if narration.exists():
        mixer.mix_atmospheric_audio(narration, structure, output)
        print(f"\n🎧 Listen: open {output}")
