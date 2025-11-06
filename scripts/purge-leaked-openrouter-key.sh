#!/bin/bash
# Purge leaked OpenRouter API key from git history
#
# WARNING: This script rewrites git history and requires force-push
#
# Usage: ./purge-leaked-openrouter-key.sh
#
# IMPORTANT:
# 1. This will rewrite ALL git history
# 2. Collaborators must re-clone after force-push
# 3. Creates backup before proceeding
# 4. Requires git-filter-repo tool

set -euo pipefail

REPO_PATH="$HOME/Documents/GitHub/aafc-herbarium-dwc-extraction-2025"
LEAKED_KEY_HASH="419e2e647f39834e1e8371c2fc54623c29c5e83bbd87a2b34334eb89cebca4cb"
LEAKED_KEY_FULL="sk-or-v1-${LEAKED_KEY_HASH}"
BACKUP_PATH="$HOME/Documents/GitHub/aafc-herbarium-BACKUP-$(date +%Y%m%d-%H%M%S)"

echo "=========================================="
echo "Git History Purge - Leaked OpenRouter Key"
echo "=========================================="
echo
echo "Repository: $REPO_PATH"
echo "Leaked key hash: ...${LEAKED_KEY_HASH: -4}"
echo "Backup location: $BACKUP_PATH"
echo
echo "⚠️  WARNING: This will rewrite git history!"
echo "⚠️  All collaborators must re-clone after this operation"
echo
read -p "Continue? (type 'yes' to proceed): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Check if git-filter-repo is installed
if ! command -v git-filter-repo &> /dev/null; then
    echo "❌ git-filter-repo not found"
    echo "Install with: brew install git-filter-repo"
    echo "Or: pip install git-filter-repo"
    exit 1
fi

# Create backup
echo
echo "📦 Creating backup..."
if [[ -d "$BACKUP_PATH" ]]; then
    echo "❌ Backup path already exists: $BACKUP_PATH"
    exit 1
fi
git clone "$REPO_PATH" "$BACKUP_PATH"
echo "✅ Backup created at: $BACKUP_PATH"

# Change to repo
cd "$REPO_PATH"

# Verify we're in the right repo
if [[ ! -d ".git" ]]; then
    echo "❌ Not a git repository: $REPO_PATH"
    exit 1
fi

# Create replacement file
SECRETS_FILE="/tmp/openrouter-secrets-to-remove-$(date +%s).txt"
cat > "$SECRETS_FILE" <<EOF
$LEAKED_KEY_HASH
$LEAKED_KEY_FULL
EOF

echo
echo "🔍 Scanning for leaked key in history..."
matches=$(git log --all -S "$LEAKED_KEY_HASH" --oneline | wc -l | tr -d ' ')
echo "Found $matches commits containing the leaked key"

if [[ "$matches" -eq 0 ]]; then
    echo "✅ No leaked key found in history (already cleaned?)"
    rm "$SECRETS_FILE"
    exit 0
fi

# Perform the purge
echo
echo "🧹 Purging leaked key from ALL git history..."
echo "This may take a few minutes..."
git filter-repo --replace-text "$SECRETS_FILE" --force

# Verify removal
echo
echo "🔍 Verifying removal..."
remaining=$(git log --all -S "$LEAKED_KEY_HASH" --oneline 2>/dev/null | wc -l | tr -d ' ')

if [[ "$remaining" -eq 0 ]]; then
    echo "✅ Leaked key successfully removed from history"
else
    echo "⚠️  Warning: $remaining commits still contain the key"
    echo "Manual review may be required"
fi

# Clean up
rm "$SECRETS_FILE"

echo
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo
echo "1. Review the cleaned history:"
echo "   git log --oneline --all | head -20"
echo
echo "2. Force-push to remote (THIS WILL REWRITE PUBLIC HISTORY):"
echo "   cd $REPO_PATH"
echo "   git push --force --all origin"
echo "   git push --force --tags origin"
echo
echo "3. Rebuild GitHub Pages:"
echo "   - Go to: https://github.com/devvyn/aafc-herbarium-dwc-extraction-2025/settings/pages"
echo "   - Disable and re-enable GitHub Pages"
echo "   - Or trigger a new deployment"
echo
echo "4. Notify collaborators to re-clone:"
echo "   git clone git@github.com:devvyn/aafc-herbarium-dwc-extraction-2025.git"
echo
echo "5. Generate new OpenRouter API key:"
echo "   https://openrouter.ai/keys"
echo
echo "Backup available at: $BACKUP_PATH"
echo
