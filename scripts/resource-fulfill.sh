#!/bin/bash
# Fulfill a resource request by downloading via transmission
# Usage: ./resource-fulfill.sh --request-id <id> --source <url/magnet> [--torrent-file <path>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
REQUEST_ID=""
SOURCE=""
TORRENT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --request-id)
            REQUEST_ID="$2"
            shift 2
            ;;
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --torrent-file)
            TORRENT_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --request-id <id> --source <url/magnet> [--torrent-file <path>]"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$REQUEST_ID" ]] && [[ -z "$SOURCE" && -z "$TORRENT_FILE" ]]; then
    echo "Error: Either --request-id and --source, or --torrent-file is required"
    echo "Usage: $0 --request-id <id> --source <url/magnet> [--torrent-file <path>]"
    exit 1
fi

# Check if transmission-daemon is running
if ! pgrep -q transmission-daemon; then
    echo "Error: transmission-daemon is not running"
    echo "Start it with: transmission-daemon --config-dir ~/.config/transmission-daemon"
    exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Fulfill the request
if [[ -n "$TORRENT_FILE" ]]; then
    # Copy torrent file to watch folder
    WATCH_FOLDER="$HOME/Music/Music/Media.localized/Automatically Add to Music.localized"
    if [[ ! -d "$WATCH_FOLDER" ]]; then
        echo "Error: Watch folder not found: $WATCH_FOLDER"
        exit 1
    fi

    cp "$TORRENT_FILE" "$WATCH_FOLDER/"
    FILENAME=$(basename "$TORRENT_FILE")

    echo "Torrent file copied to watch folder"
    echo "File: $FILENAME"
    echo "Transmission will automatically begin download"

elif [[ "$SOURCE" =~ ^magnet: ]]; then
    # Add magnet link directly
    transmission-remote --add "$SOURCE"

    echo "Magnet link added to transmission"
    echo "Download started"

elif [[ "$SOURCE" =~ ^https?:// ]] && [[ "$SOURCE" =~ \.torrent$ ]]; then
    # Download torrent file and add to watch folder
    WATCH_FOLDER="$HOME/Music/Music/Media.localized/Automatically Add to Music.localized"
    FILENAME="$(basename "$SOURCE")"

    curl -L -o "$WATCH_FOLDER/$FILENAME" "$SOURCE"

    echo "Torrent file downloaded to watch folder"
    echo "File: $FILENAME"
    echo "Transmission will automatically begin download"

else
    echo "Error: Unsupported source format"
    echo "Supported: magnet links, .torrent HTTP URLs, or local .torrent files"
    exit 1
fi

# Log fulfillment
LOG_DIR="$HOME/devvyn-meta-project/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/resource-fulfillments.log"

cat >> "$LOG_FILE" <<EOF
---
Timestamp: $TIMESTAMP
Request ID: ${REQUEST_ID:-N/A}
Source: ${SOURCE:-$TORRENT_FILE}
Status: download-initiated
---
EOF

echo ""
echo "Resource fulfillment initiated"
echo "Request ID: ${REQUEST_ID:-N/A}"
echo "Timestamp: $TIMESTAMP"
echo ""
echo "Monitor progress with:"
echo "  transmission-remote -l"
echo "  open http://localhost:9091"
echo "  $SCRIPT_DIR/resource-status.sh"
echo ""
echo "Completion will trigger bridge notification automatically"

exit 0
