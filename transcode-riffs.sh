cd '/Volumes/Applecat/Users/devvyn/Documents/Azureus Downloads/The Racoons'

# Create output directory
OUT_DIR="$HOME/Desktop/transcoded"
mkdir -p "$OUT_DIR"

# Transcode only files that start with RIFF
for f in *.avi; do
    if head -c 4 "$f" | xxd | grep -q "5249 4646"; then
        echo "Transcoding: $f"
        ffmpeg -i "$f" -c:v libx265 -crf 23 -preset medium -c:a aac -b:a 128k "$OUT_DIR/${f%.avi}.mkv"
    else
        echo "Skipping (empty): $f"
    fi
done
