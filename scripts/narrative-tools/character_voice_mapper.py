#!/usr/bin/env python3
"""
Character Voice Mapper for Dramatic Audio Readings

Extends doc-to-audio.py VoiceMapper to support:
- Dynamic character-to-voice allocation
- CHARACTER_<name> tags beyond fixed NARRATOR/CODE/QUOTE
- Flexible voice palette management
- Character metadata (gender, age, role) → voice selection

Usage:
    from character_voice_mapper import CharacterVoiceMapper

    mapper = CharacterVoiceMapper(
        characters=['Sheriff', 'Sarah', 'Jack'],
        narrator_voice='Aman'
    )

    voice = mapper.get_voice('CHARACTER_Sheriff')  # → 'Jamie'
    voice = mapper.get_voice('NARRATOR')  # → 'Aman'
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Set


@dataclass
class CharacterProfile:
    """Character metadata for voice selection"""

    name: str
    gender: Optional[str] = None  # 'male', 'female', 'neutral'
    age: Optional[str] = None  # 'young', 'middle', 'old'
    role: Optional[str] = None  # 'authority', 'educator', 'service', etc.
    personality: Optional[List[str]] = None  # ['cautious', 'direct', ...]
    voice_characteristics: Optional[str] = None  # Free-form description


class VoicePalette:
    """Manages available TTS voices and their characteristics"""

    def __init__(self, provider: str = "macos"):
        """Initialize voice palette for specified provider"""
        self.provider = provider
        self.voices = self._init_voice_catalog()

    def _init_voice_catalog(self) -> Dict[str, Dict]:
        """Initialize voice catalog with metadata"""

        if self.provider == "macos":
            return {
                # Premium UK/AU voices
                "Jamie": {
                    "type": "Premium",
                    "gender": "male",
                    "accent": "UK",
                    "age": "middle",
                    "characteristics": "warm, professional, authoritative",
                },
                "Lee": {
                    "type": "Premium",
                    "gender": "male",
                    "accent": "AU",
                    "age": "middle",
                    "characteristics": "clear, engaging, casual",
                },
                "Serena": {
                    "type": "Premium",
                    "gender": "female",
                    "accent": "UK",
                    "age": "middle",
                    "characteristics": "elegant, articulate, precise",
                },
                # Siri voices (India)
                "Aman": {
                    "type": "Siri",
                    "gender": "male",
                    "accent": "India",
                    "age": "middle",
                    "characteristics": "clear, distinctive, neutral",
                },
                "Tara": {
                    "type": "Siri",
                    "gender": "female",
                    "accent": "India",
                    "age": "middle",
                    "characteristics": "calm, educational, warm",
                },
                # US voices
                "Alex": {
                    "type": "Enhanced",
                    "gender": "male",
                    "accent": "US",
                    "age": "middle",
                    "characteristics": "neutral, versatile",
                },
                "Samantha": {
                    "type": "Enhanced",
                    "gender": "female",
                    "accent": "US",
                    "age": "middle",
                    "characteristics": "friendly, clear",
                },
                # Specialized
                "Fred": {
                    "type": "Basic",
                    "gender": "male",
                    "accent": "US",
                    "age": "neutral",
                    "characteristics": "robotic, technical, monotone",
                },
            }
        else:
            # For ElevenLabs/OpenAI, voices are IDs, not names
            # Would need different structure
            return {}

    def get_voices_by_criteria(
        self,
        gender: Optional[str] = None,
        age: Optional[str] = None,
        accent: Optional[str] = None,
        exclude: Optional[Set[str]] = None,
    ) -> List[str]:
        """Get voices matching criteria"""

        exclude = exclude or set()
        matching = []

        for voice_name, metadata in self.voices.items():
            if voice_name in exclude:
                continue

            # Check criteria
            if gender and metadata.get("gender") != gender:
                continue
            if age and metadata.get("age") != age:
                continue
            if accent and metadata.get("accent") != accent:
                continue

            matching.append(voice_name)

        return matching

    def get_best_match(
        self,
        character: CharacterProfile,
        exclude: Optional[Set[str]] = None,
        prefer_accent: Optional[str] = None,
    ) -> Optional[str]:
        """Get best voice match for character"""

        # Try exact match first
        candidates = self.get_voices_by_criteria(
            gender=character.gender, age=character.age, exclude=exclude
        )

        if not candidates:
            # Relax age constraint
            candidates = self.get_voices_by_criteria(
                gender=character.gender, exclude=exclude
            )

        if not candidates:
            # Relax all constraints
            candidates = [
                v for v in self.voices.keys() if v not in (exclude or set())
            ]

        if not candidates:
            return None

        # Prefer specific accents if requested
        if prefer_accent:
            preferred = [
                c for c in candidates if self.voices[c].get("accent") == prefer_accent
            ]
            if preferred:
                return preferred[0]

        # Return first match
        return candidates[0]


class CharacterVoiceMapper:
    """Maps characters to TTS voices for dramatic readings"""

    def __init__(
        self,
        characters: List[str] | List[CharacterProfile] | None = None,
        narrator_voice: str = "Aman",
        provider: str = "macos",
        voice_palette: Optional[VoicePalette] = None,
        prefer_accent_diversity: bool = True,
    ):
        """
        Initialize character voice mapper

        Args:
            characters: List of character names or CharacterProfile objects
            narrator_voice: Voice to use for narrator
            provider: TTS provider ('macos', 'elevenlabs', 'openai')
            voice_palette: Custom voice palette (auto-created if None)
            prefer_accent_diversity: Try to use different accents for variety
        """
        self.provider = provider
        self.narrator_voice = narrator_voice
        self.prefer_accent_diversity = prefer_accent_diversity

        # Initialize voice palette
        self.palette = voice_palette or VoicePalette(provider)

        # Initialize character mapping
        self.voice_map: Dict[str, str] = {
            "NARRATOR": narrator_voice,
            "HEADER": narrator_voice,  # Headers use narrator voice
            "CODE": "Fred",  # Code blocks use robotic voice
            "QUOTE": narrator_voice,  # Quotes use narrator by default
        }

        # Track used voices to ensure diversity
        self.used_voices: Set[str] = {narrator_voice, "Fred"}

        # Allocate voices for characters
        if characters:
            self._allocate_character_voices(characters)

    def _allocate_character_voices(
        self, characters: List[str] | List[CharacterProfile]
    ) -> None:
        """Allocate voices to characters"""

        for char in characters:
            # Convert string to CharacterProfile if needed
            if isinstance(char, str):
                char_profile = CharacterProfile(name=char)
            else:
                char_profile = char

            # Get best voice match
            voice = self.palette.get_best_match(char_profile, exclude=self.used_voices)

            if voice is None:
                # No unused voices left, reuse from palette
                # Prefer voices not used as narrator
                available = [
                    v
                    for v in self.palette.voices.keys()
                    if v != self.narrator_voice
                ]
                voice = available[0] if available else "Alex"

            # Map CHARACTER_<name> → voice
            char_tag = f"CHARACTER_{char_profile.name}"
            self.voice_map[char_tag] = voice
            self.used_voices.add(voice)

    def get_voice(self, content_type: str) -> str:
        """Get voice for content type (NARRATOR, CHARACTER_<name>, etc.)"""

        # Direct lookup
        if content_type in self.voice_map:
            return self.voice_map[content_type]

        # Fallback to narrator
        return self.narrator_voice

    def add_character(
        self, character: str | CharacterProfile, voice: Optional[str] = None
    ) -> str:
        """
        Add character after initialization

        Args:
            character: Character name or profile
            voice: Specific voice to use (auto-allocated if None)

        Returns:
            Allocated voice name
        """

        # Convert to profile if string
        if isinstance(character, str):
            char_profile = CharacterProfile(name=character)
        else:
            char_profile = character

        char_tag = f"CHARACTER_{char_profile.name}"

        # Check if already mapped
        if char_tag in self.voice_map:
            return self.voice_map[char_tag]

        # Use specified voice or auto-allocate
        if voice:
            allocated_voice = voice
        else:
            allocated_voice = self.palette.get_best_match(
                char_profile, exclude=self.used_voices
            )
            if not allocated_voice:
                # Reuse voices if necessary
                available = [
                    v
                    for v in self.palette.voices.keys()
                    if v != self.narrator_voice
                ]
                allocated_voice = available[0] if available else "Alex"

        # Add mapping
        self.voice_map[char_tag] = allocated_voice
        self.used_voices.add(allocated_voice)

        return allocated_voice

    def get_character_mapping(self) -> Dict[str, str]:
        """Get all character-to-voice mappings (excludes NARRATOR, etc.)"""

        return {
            tag: voice
            for tag, voice in self.voice_map.items()
            if tag.startswith("CHARACTER_")
        }

    def print_mapping(self) -> None:
        """Print voice mapping (for debugging)"""

        print("\n=== Voice Mapping ===")
        print(f"Narrator: {self.voice_map['NARRATOR']}")
        print("\nCharacters:")

        char_mappings = self.get_character_mapping()
        for char_tag, voice in sorted(char_mappings.items()):
            char_name = char_tag.replace("CHARACTER_", "")
            voice_info = self.palette.voices.get(voice, {})
            print(
                f"  {char_name:20s} → {voice:12s} ({voice_info.get('accent', '?')}, {voice_info.get('characteristics', '?')})"
            )

        print("\nSpecial:")
        print(f"  Code Blocks: {self.voice_map['CODE']}")


# Example usage
if __name__ == "__main__":
    # Example 1: Simple character names
    print("=== Example 1: Simple Names ===")
    mapper = CharacterVoiceMapper(
        characters=["Sheriff", "Sarah", "Jack"], narrator_voice="Aman"
    )
    mapper.print_mapping()

    # Example 2: Character profiles with metadata
    print("\n=== Example 2: Character Profiles ===")
    characters = [
        CharacterProfile(
            name="Sheriff",
            gender="male",
            age="middle",
            role="authority",
            personality=["authoritative", "suspicious"],
        ),
        CharacterProfile(
            name="Sarah",
            gender="female",
            age="middle",
            role="educator",
            personality=["cautious", "precise"],
        ),
        CharacterProfile(
            name="Jack", gender="male", age="middle", role="service", personality=["casual", "nervous"]
        ),
    ]

    mapper2 = CharacterVoiceMapper(characters=characters, narrator_voice="Aman")
    mapper2.print_mapping()

    # Example 3: Dynamic character addition
    print("\n=== Example 3: Dynamic Addition ===")
    mapper3 = CharacterVoiceMapper(narrator_voice="Aman")
    mapper3.add_character("Deputy")
    mapper3.add_character(
        CharacterProfile(name="Stranger", gender="male", age="old")
    )
    mapper3.print_mapping()

    # Test voice retrieval
    print("\n=== Voice Retrieval ===")
    print(f"Sheriff speaks with: {mapper2.get_voice('CHARACTER_Sheriff')}")
    print(f"Sarah speaks with: {mapper2.get_voice('CHARACTER_Sarah')}")
    print(f"Narrator uses: {mapper2.get_voice('NARRATOR')}")
    print(f"Unknown character defaults to: {mapper2.get_voice('CHARACTER_Unknown')}")
