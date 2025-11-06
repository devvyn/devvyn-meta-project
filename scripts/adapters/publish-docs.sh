#!/bin/bash
# publish-docs.sh - Publish documentation to public web hosting
# Usage: publish-docs.sh <target> [source-dir]

set -euo pipefail

CONFIG_FILE="${HOME}/infrastructure/agent-bridge/bridge/config/docs-publish.json"

# Color codes
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
DIM="\033[2m"
RESET="\033[0m"

show_help() {
    echo "Usage: publish-docs.sh <target> [source-dir]"
    echo ""
    echo "Targets:"
    echo "  github-pages    - Deploy to GitHub Pages via gh-pages branch"
    echo "  netlify         - Deploy to Netlify"
    echo "  local           - Build to local directory (for testing)"
    echo ""
    echo "Examples:"
    echo "  publish-docs.sh github-pages ~/devvyn-meta-project/docs"
    echo "  publish-docs.sh netlify ~/devvyn-meta-project/knowledge-base"
    echo "  publish-docs.sh local"
    echo ""
    echo "Configuration: $CONFIG_FILE"
}

if [[ $# -lt 1 ]]; then
    show_help
    exit 1
fi

TARGET="$1"
SOURCE_DIR="${2:-$(pwd)}"

# Create config directory if it doesn't exist
mkdir -p "$(dirname "$CONFIG_FILE")"

# Create default config if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "mkdocs": {
    "enabled": true,
    "config_file": "mkdocs.yml",
    "theme": "material"
  },
  "github_pages": {
    "enabled": false,
    "repo": "",
    "branch": "gh-pages",
    "custom_domain": ""
  },
  "netlify": {
    "enabled": false,
    "site_id": "",
    "auth_token": ""
  },
  "local": {
    "enabled": true,
    "output_dir": "~/Desktop/docs-build"
  }
}
EOF
    echo -e "${YELLOW}Created default config at: $CONFIG_FILE${RESET}"
fi

# Expand tilde in source dir
SOURCE_DIR="${SOURCE_DIR/#\~/$HOME}"

# Check if source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo -e "${RED}Error: Source directory not found: $SOURCE_DIR${RESET}"
    exit 1
fi

# Check if MkDocs is available
MKDOCS_ENABLED=$(jq -r '.mkdocs.enabled // true' "$CONFIG_FILE")

if [[ "$MKDOCS_ENABLED" == "true" ]]; then
    if ! command -v mkdocs &> /dev/null; then
        echo -e "${YELLOW}Warning: MkDocs not installed${RESET}"
        echo "Install with: pip install mkdocs mkdocs-material"
    fi
fi

# Function to build MkDocs site
build_mkdocs() {
    local output_dir="$1"

    echo -e "${BLUE}Building MkDocs site...${RESET}"

    # Check for mkdocs.yml
    if [[ -f "$SOURCE_DIR/mkdocs.yml" ]]; then
        MKDOCS_CONFIG="$SOURCE_DIR/mkdocs.yml"
    elif [[ -f "$SOURCE_DIR/../mkdocs.yml" ]]; then
        MKDOCS_CONFIG="$SOURCE_DIR/../mkdocs.yml"
    else
        echo -e "${RED}Error: mkdocs.yml not found${RESET}"
        return 1
    fi

    # Build
    cd "$(dirname "$MKDOCS_CONFIG")"
    mkdocs build --clean --site-dir "$output_dir"

    echo -e "${GREEN}✓ Build complete: $output_dir${RESET}"
}

# Target-specific publishing
case "$TARGET" in
    github-pages)
        ENABLED=$(jq -r '.github_pages.enabled // false' "$CONFIG_FILE")

        if [[ "$ENABLED" != "true" ]]; then
            echo -e "${RED}Error: GitHub Pages publishing not enabled${RESET}"
            echo "Edit $CONFIG_FILE to enable"
            exit 1
        fi

        REPO=$(jq -r '.github_pages.repo' "$CONFIG_FILE")
        BRANCH=$(jq -r '.github_pages.branch // "gh-pages"' "$CONFIG_FILE")
        CUSTOM_DOMAIN=$(jq -r '.github_pages.custom_domain // ""' "$CONFIG_FILE")

        if [[ -z "$REPO" ]] || [[ "$REPO" == "null" ]]; then
            echo -e "${RED}Error: GitHub repo not configured${RESET}"
            exit 1
        fi

        echo -e "${GREEN}Publishing to GitHub Pages...${RESET}"

        # Build to temp directory
        TEMP_DIR=$(mktemp -d)
        build_mkdocs "$TEMP_DIR"

        # Add CNAME if custom domain configured
        if [[ -n "$CUSTOM_DOMAIN" ]] && [[ "$CUSTOM_DOMAIN" != "null" ]]; then
            echo "$CUSTOM_DOMAIN" > "$TEMP_DIR/CNAME"
        fi

        # Deploy using ghp-import or manual git
        if command -v ghp-import &> /dev/null; then
            ghp-import -n -p -f -o -r origin -b "$BRANCH" "$TEMP_DIR"
            echo -e "${GREEN}✓ Published to GitHub Pages${RESET}"
        else
            echo -e "${YELLOW}Note: ghp-import not found, using manual git deployment${RESET}"

            # Manual deployment
            cd "$TEMP_DIR"
            git init
            git add .
            git commit -m "Deploy docs"
            git branch -M "$BRANCH"
            git remote add origin "https://github.com/${REPO}.git"
            git push -f origin "$BRANCH"

            echo -e "${GREEN}✓ Published to GitHub Pages${RESET}"
        fi

        # Cleanup
        rm -rf "$TEMP_DIR"

        echo -e "${GREEN}Site URL: https://$(echo $REPO | cut -d/ -f1).github.io/$(echo $REPO | cut -d/ -f2)/${RESET}"
        ;;

    netlify)
        ENABLED=$(jq -r '.netlify.enabled // false' "$CONFIG_FILE")

        if [[ "$ENABLED" != "true" ]]; then
            echo -e "${RED}Error: Netlify publishing not enabled${RESET}"
            exit 1
        fi

        SITE_ID=$(jq -r '.netlify.site_id' "$CONFIG_FILE")
        AUTH_TOKEN=$(jq -r '.netlify.auth_token' "$CONFIG_FILE")

        if [[ -z "$SITE_ID" ]] || [[ -z "$AUTH_TOKEN" ]]; then
            echo -e "${RED}Error: Netlify site_id or auth_token not configured${RESET}"
            exit 1
        fi

        echo -e "${GREEN}Publishing to Netlify...${RESET}"

        # Build to temp directory
        TEMP_DIR=$(mktemp -d)
        build_mkdocs "$TEMP_DIR"

        # Deploy using netlify-cli
        if ! command -v netlify &> /dev/null; then
            echo -e "${RED}Error: Netlify CLI not installed${RESET}"
            echo "Install with: npm install -g netlify-cli"
            exit 1
        fi

        NETLIFY_AUTH_TOKEN="$AUTH_TOKEN" netlify deploy \
            --site "$SITE_ID" \
            --dir "$TEMP_DIR" \
            --prod

        # Cleanup
        rm -rf "$TEMP_DIR"

        echo -e "${GREEN}✓ Published to Netlify${RESET}"
        ;;

    local)
        OUTPUT_DIR=$(jq -r '.local.output_dir // "~/Desktop/docs-build"' "$CONFIG_FILE")
        OUTPUT_DIR="${OUTPUT_DIR/#\~/$HOME}"

        echo -e "${GREEN}Building to local directory...${RESET}"

        mkdir -p "$OUTPUT_DIR"
        build_mkdocs "$OUTPUT_DIR"

        echo -e "${GREEN}✓ Build complete${RESET}"
        echo -e "${DIM}Open: file://$OUTPUT_DIR/index.html${RESET}"

        # Optionally open in browser
        if [[ -f "$OUTPUT_DIR/index.html" ]]; then
            open "$OUTPUT_DIR/index.html"
        fi
        ;;

    *)
        echo -e "${RED}Error: Unknown target '$TARGET'${RESET}"
        show_help
        exit 1
        ;;
esac
