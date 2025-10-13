#!/usr/bin/env python3
"""
MCP Server: Click Elimination
Purpose: Provide tools to eliminate repetitive mouse clicking
Medical Context: MS-related low dexterity, energy conservation

Tools provided:
1. download_suno_library - Bulk download from Suno (eliminates 200+ clicks)
2. organize_downloads - Sort Downloads folder by type (eliminates dragging)
3. batch_rename_files - Rename multiple files by pattern (eliminates right-click × N)
"""

import asyncio
import json
import subprocess
import os
from pathlib import Path
from typing import Optional
from datetime import datetime
import shutil
import re

from mcp.server import Server
from mcp.types import Tool, TextContent
import mcp.server.stdio


# Initialize MCP server
server = Server("click-elimination")


# ============================================================================
# Tool 1: Suno Library Download (eliminates 200+ clicks)
# ============================================================================

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available click-elimination tools"""
    return [
        Tool(
            name="download_suno_library",
            description=(
                "Download all songs from Suno library. Eliminates 200+ manual clicks. "
                "Accessibility: Reduces repetitive mousing for MS-related low dexterity. "
                "Uses existing rate-limited, respectful automation."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "output_dir": {
                        "type": "string",
                        "description": "Directory to save songs (default: ~/Music/Suno)",
                        "default": "~/Music/Suno"
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="organize_downloads",
            description=(
                "Organize Downloads folder by file type. Eliminates manual dragging/clicking. "
                "Creates folders: PDFs, Images, Videos, Documents, Archives, Other. "
                "Accessibility: Batch operation replaces repetitive GUI actions."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "source_dir": {
                        "type": "string",
                        "description": "Directory to organize (default: ~/Downloads)",
                        "default": "~/Downloads"
                    },
                    "dry_run": {
                        "type": "boolean",
                        "description": "Preview changes without moving files",
                        "default": False
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="batch_rename_files",
            description=(
                "Rename multiple files using a pattern. Eliminates right-click → rename × N. "
                "Supports patterns like: 'photo_{index:03d}.jpg' or 'document_{date}_{original}.pdf'. "
                "Accessibility: Automates repetitive renaming tasks."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "directory": {
                        "type": "string",
                        "description": "Directory containing files to rename"
                    },
                    "pattern": {
                        "type": "string",
                        "description": "Rename pattern. Variables: {index}, {index:03d}, {original}, {date}, {ext}"
                    },
                    "file_extension": {
                        "type": "string",
                        "description": "Filter by extension (e.g., 'jpg', 'pdf'). Leave empty for all files.",
                        "default": ""
                    },
                    "dry_run": {
                        "type": "boolean",
                        "description": "Preview changes without renaming",
                        "default": False
                    }
                },
                "required": ["directory", "pattern"]
            }
        )
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute requested tool"""

    if name == "download_suno_library":
        return await download_suno_library(arguments.get("output_dir", "~/Music/Suno"))

    elif name == "organize_downloads":
        return await organize_downloads(
            arguments.get("source_dir", "~/Downloads"),
            arguments.get("dry_run", False)
        )

    elif name == "batch_rename_files":
        return await batch_rename_files(
            arguments["directory"],
            arguments["pattern"],
            arguments.get("file_extension", ""),
            arguments.get("dry_run", False)
        )

    else:
        return [TextContent(
            type="text",
            text=f"Unknown tool: {name}"
        )]


# ============================================================================
# Tool Implementations
# ============================================================================

async def download_suno_library(output_dir: str) -> list[TextContent]:
    """
    Download all Suno songs using existing automation toolkit
    Eliminates 200+ manual clicks (50 downloads × 4 clicks each)
    """
    try:
        # Expand home directory
        output_dir = os.path.expanduser(output_dir)

        # Check if Suno toolkit exists
        toolkit_dir = Path.home() / "Desktop" / "suno-download-toolkit"
        if not toolkit_dir.exists():
            return [TextContent(
                type="text",
                text=f"❌ Suno toolkit not found at {toolkit_dir}\n"
                     f"Expected location: ~/Desktop/suno-download-toolkit/\n"
                     f"This tool wraps the existing Suno automation scripts."
            )]

        # Create output directory
        os.makedirs(output_dir, exist_ok=True)

        # Check for URLs file (user should have run extraction first)
        urls_file = toolkit_dir / "urls.txt"
        if not urls_file.exists():
            return [TextContent(
                type="text",
                text=f"⚠️  URLs file not found: {urls_file}\n\n"
                     f"NEXT STEPS:\n"
                     f"1. Open https://suno.com → Log in → Your library\n"
                     f"2. Open browser console (F12)\n"
                     f"3. Paste contents of: {toolkit_dir}/01-extract-urls.js\n"
                     f"4. Press Enter (URLs will be copied to clipboard)\n"
                     f"5. Save URLs: pbpaste > {urls_file}\n"
                     f"6. Run this tool again\n\n"
                     f"This one-time setup extracts download URLs from your browser session."
            )]

        # Run download script
        download_script = toolkit_dir / "02-download.sh"
        result = subprocess.run(
            [str(download_script), str(urls_file), output_dir],
            capture_output=True,
            text=True,
            timeout=600  # 10 minute timeout
        )

        if result.returncode == 0:
            # Count downloaded files
            output_path = Path(output_dir)
            song_count = len(list(output_path.glob("*.mp3")))

            return [TextContent(
                type="text",
                text=f"✅ Suno library download complete!\n\n"
                     f"📂 Location: {output_dir}\n"
                     f"🎵 Songs: {song_count}\n"
                     f"🖱️ Clicks eliminated: ~{song_count * 4}\n\n"
                     f"Accessibility: Energy conservation via automation\n"
                     f"Medical justification: Reduces repetitive strain (MS-related)"
            )]
        else:
            return [TextContent(
                type="text",
                text=f"❌ Download failed\n\n"
                     f"Error output:\n{result.stderr}\n\n"
                     f"Check log: {toolkit_dir}/download_log_*.txt"
            )]

    except subprocess.TimeoutExpired:
        return [TextContent(
            type="text",
            text="❌ Download timeout (>10 minutes). Check if download is still running."
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=f"❌ Error: {str(e)}"
        )]


async def organize_downloads(source_dir: str, dry_run: bool = False) -> list[TextContent]:
    """
    Organize Downloads folder by file type
    Eliminates manual dragging/clicking for each file
    """
    try:
        source_dir = os.path.expanduser(source_dir)
        source_path = Path(source_dir)

        if not source_path.exists():
            return [TextContent(
                type="text",
                text=f"❌ Directory not found: {source_dir}"
            )]

        # File type categories
        categories = {
            'PDFs': ['.pdf'],
            'Images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp', '.heic'],
            'Videos': ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'],
            'Documents': ['.doc', '.docx', '.txt', '.rtf', '.pages', '.odt'],
            'Spreadsheets': ['.xls', '.xlsx', '.csv', '.numbers', '.ods'],
            'Archives': ['.zip', '.tar', '.gz', '.rar', '.7z', '.dmg'],
            'Audio': ['.mp3', '.wav', '.aac', '.flac', '.m4a', '.ogg'],
            'Code': ['.py', '.js', '.java', '.cpp', '.c', '.h', '.sh', '.html', '.css'],
        }

        # Stats
        stats = {category: [] for category in categories}
        stats['Other'] = []

        # Scan files
        for item in source_path.iterdir():
            if item.is_file() and not item.name.startswith('.'):
                ext = item.suffix.lower()
                categorized = False

                for category, extensions in categories.items():
                    if ext in extensions:
                        stats[category].append(item)
                        categorized = True
                        break

                if not categorized:
                    stats['Other'].append(item)

        # Count total files
        total_files = sum(len(files) for files in stats.values())

        if total_files == 0:
            return [TextContent(
                type="text",
                text=f"✓ Directory is already organized (or empty): {source_dir}"
            )]

        # Generate preview/action report
        report_lines = [
            f"{'📋 PREVIEW' if dry_run else '✅ ORGANIZED'}: {source_dir}",
            f"",
            f"Total files: {total_files}",
            f""
        ]

        moves_performed = 0

        for category, files in stats.items():
            if not files:
                continue

            report_lines.append(f"{category}: {len(files)} files")

            if not dry_run:
                # Create category folder
                category_dir = source_path / category
                category_dir.mkdir(exist_ok=True)

                # Move files
                for file in files:
                    try:
                        dest = category_dir / file.name
                        # Handle name conflicts
                        counter = 1
                        while dest.exists():
                            stem = file.stem
                            ext = file.suffix
                            dest = category_dir / f"{stem}_{counter}{ext}"
                            counter += 1

                        shutil.move(str(file), str(dest))
                        moves_performed += 1
                    except Exception as e:
                        report_lines.append(f"  ⚠️  Failed to move {file.name}: {e}")

        report_lines.extend([
            "",
            f"{'Would move' if dry_run else 'Moved'}: {moves_performed} files",
            f"🖱️ Clicks eliminated: ~{moves_performed * 3}",
            "",
            "Accessibility: Batch operation replaces manual dragging",
        ])

        if dry_run:
            report_lines.append("(Run without dry_run to execute)")

        return [TextContent(
            type="text",
            text="\n".join(report_lines)
        )]

    except Exception as e:
        return [TextContent(
            type="text",
            text=f"❌ Error: {str(e)}"
        )]


async def batch_rename_files(
    directory: str,
    pattern: str,
    file_extension: str = "",
    dry_run: bool = False
) -> list[TextContent]:
    """
    Batch rename files using pattern
    Eliminates right-click → rename for each file
    """
    try:
        directory = os.path.expanduser(directory)
        dir_path = Path(directory)

        if not dir_path.exists():
            return [TextContent(
                type="text",
                text=f"❌ Directory not found: {directory}"
            )]

        # Get files to rename
        if file_extension:
            ext = file_extension if file_extension.startswith('.') else f'.{file_extension}'
            files = sorted([f for f in dir_path.iterdir() if f.is_file() and f.suffix.lower() == ext.lower()])
        else:
            files = sorted([f for f in dir_path.iterdir() if f.is_file() and not f.name.startswith('.')])

        if not files:
            return [TextContent(
                type="text",
                text=f"❌ No files found in {directory}" +
                     (f" with extension {file_extension}" if file_extension else "")
            )]

        # Preview renames
        today = datetime.now().strftime("%Y%m%d")
        renames = []

        for index, file in enumerate(files, start=1):
            # Build new name from pattern
            new_name = pattern
            new_name = new_name.replace("{index}", str(index))
            new_name = re.sub(r'\{index:0(\d+)d\}', lambda m: str(index).zfill(int(m.group(1))), new_name)
            new_name = new_name.replace("{original}", file.stem)
            new_name = new_name.replace("{date}", today)
            new_name = new_name.replace("{ext}", file.suffix)

            # Ensure extension
            if not new_name.endswith(file.suffix):
                new_name += file.suffix

            new_path = dir_path / new_name

            # Check for conflicts
            if new_path.exists() and new_path != file:
                counter = 1
                stem = Path(new_name).stem
                ext = Path(new_name).suffix
                while new_path.exists():
                    new_path = dir_path / f"{stem}_{counter}{ext}"
                    counter += 1

            renames.append((file, new_path))

        # Generate report
        report_lines = [
            f"{'📋 PREVIEW' if dry_run else '✅ RENAMED'}: {len(files)} files in {directory}",
            f"Pattern: {pattern}",
            f"",
            "Changes:"
        ]

        # Show first 10 renames as examples
        for old_file, new_file in renames[:10]:
            report_lines.append(f"  {old_file.name} → {new_file.name}")

        if len(renames) > 10:
            report_lines.append(f"  ... and {len(renames) - 10} more")

        # Execute renames if not dry run
        if not dry_run:
            renamed_count = 0
            for old_file, new_file in renames:
                try:
                    old_file.rename(new_file)
                    renamed_count += 1
                except Exception as e:
                    report_lines.append(f"  ⚠️  Failed: {old_file.name} - {e}")

            report_lines.extend([
                "",
                f"Renamed: {renamed_count}/{len(files)} files",
                f"🖱️ Clicks eliminated: ~{renamed_count * 4}",
                "",
                "Accessibility: Automates repetitive renaming workflow"
            ])
        else:
            report_lines.extend([
                "",
                f"Would rename: {len(files)} files",
                "(Run without dry_run to execute)"
            ])

        return [TextContent(
            type="text",
            text="\n".join(report_lines)
        )]

    except Exception as e:
        return [TextContent(
            type="text",
            text=f"❌ Error: {str(e)}"
        )]


# ============================================================================
# Server Entry Point
# ============================================================================

async def main():
    """Run MCP server"""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
