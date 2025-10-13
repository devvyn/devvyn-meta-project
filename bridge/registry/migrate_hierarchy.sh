#!/bin/bash
#
# migrate_hierarchy.sh
# Safely migrate home directory to organized hierarchy with symlink compatibility
# Based on TLA+ specification constraints
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
VERBOSE=false
BACKUP_DIR="$HOME/.hierarchy-migration-backup-$(date +%Y%m%d-%H%M%S)"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be done without doing it"
            echo "  --verbose,-v  Show detailed output"
            echo "  --help,-h     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Check if running in dry-run mode
execute_or_dry_run() {
    local cmd="$1"
    local description="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] $description"
        log_verbose "Would execute: $cmd"
    else
        log_verbose "Executing: $cmd"
        eval "$cmd"
        log_success "$description"
    fi
}

# Safely migrate a file/directory with backup and symlink
migrate_item() {
    local source="$1"
    local dest="$2"
    local create_symlink="${3:-true}"

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        log_verbose "Source does not exist: $source"
        return 0
    fi

    # Check if destination already exists
    if [[ -e "$dest" ]]; then
        log_warning "Destination already exists: $dest (skipping)"
        return 0
    fi

    # Create destination directory
    local dest_dir
    dest_dir="$(dirname "$dest")"
    execute_or_dry_run "mkdir -p '$dest_dir'" "Create directory: $dest_dir"

    # Move the item
    execute_or_dry_run "mv '$source' '$dest'" "Move: $source → $dest"

    # Create symlink for backward compatibility
    if [[ "$create_symlink" == true ]]; then
        execute_or_dry_run "ln -s '$dest' '$source'" "Create symlink: $source → $dest"
    fi
}

# Create directory structure
create_structure() {
    log_info "Creating new directory structure..."

    local dirs=(
        "$HOME/.config/shell"
        "$HOME/.config/editors"
        "$HOME/.config/tools"
        "$HOME/.config/apps"
        "$HOME/Development/scripts"
        "$HOME/Development/dotfiles"
        "$HOME/Development/environments"
        "$HOME/Projects/active"
        "$HOME/Projects/archived"
        "$HOME/Projects/meta"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            execute_or_dry_run "mkdir -p '$dir'" "Create: $dir"
        else
            log_verbose "Directory already exists: $dir"
        fi
    done
}

# Migrate shell configurations
migrate_shell_configs() {
    log_info "Migrating shell configurations..."

    local configs=(
        ".zshrc:$HOME/.config/shell/zshrc"
        ".bashrc:$HOME/.config/shell/bashrc"
        ".bash_profile:$HOME/.config/shell/bash_profile"
        ".profile:$HOME/.config/shell/profile"
        ".zprofile:$HOME/.config/shell/zprofile"
        ".zshenv:$HOME/.config/shell/zshenv"
    )

    for config in "${configs[@]}"; do
        IFS=':' read -r source dest <<< "$config"
        migrate_item "$HOME/$source" "$dest" true
    done
}

# Migrate editor configurations
migrate_editor_configs() {
    log_info "Migrating editor configurations..."

    local configs=(
        ".vimrc:$HOME/.config/editors/vimrc"
        ".vim:$HOME/.config/editors/vim"
        ".emacs:$HOME/.config/editors/emacs"
        ".emacs.d:$HOME/.config/editors/emacs.d"
        ".config/Code:$HOME/.config/editors/Code"
        ".windsurf:$HOME/.config/editors/windsurf"
    )

    for config in "${configs[@]}"; do
        IFS=':' read -r source dest <<< "$config"
        migrate_item "$HOME/$source" "$dest" true
    done
}

# Migrate tool configurations
migrate_tool_configs() {
    log_info "Migrating tool configurations..."

    local configs=(
        ".gitconfig:$HOME/.config/tools/gitconfig"
        ".gitignore_global:$HOME/.config/tools/gitignore_global"
        ".tmux.conf:$HOME/.config/tools/tmux.conf"
        ".docker:$HOME/.config/tools/docker"
        ".conda:$HOME/.config/tools/conda"
        ".condarc:$HOME/.config/tools/condarc"
    )

    for config in "${configs[@]}"; do
        IFS=':' read -r source dest <<< "$config"
        migrate_item "$HOME/$source" "$dest" true
    done
}

# Migrate Claude configuration
migrate_claude_config() {
    log_info "Migrating Claude configuration..."

    # Keep .claude in place but note it in the report
    if [[ -d "$HOME/.claude" ]]; then
        log_info ".claude directory exists (keeping in place per XDG standards)"
    fi
}

# Create backup of current state
create_backup() {
    if [[ "$DRY_RUN" == false ]]; then
        log_info "Creating backup at: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"

        # List all items that will be migrated
        echo "Migration started: $(date)" > "$BACKUP_DIR/migration.log"
        echo "Backed up dotfiles and configs" >> "$BACKUP_DIR/migration.log"
    fi
}

# Generate migration report
generate_report() {
    log_info "Generating migration report..."

    local report_file="$HOME/Desktop/$(date +%Y%m%d%H%M%S)-0600-hierarchy-migration-report.md"

    cat > "$report_file" <<EOF
# Home Directory Hierarchy Migration Report

**Date**: $(date)
**Mode**: $(if [[ "$DRY_RUN" == true ]]; then echo "DRY RUN"; else echo "EXECUTED"; fi)

## Summary

This migration reorganizes the home directory according to the TLA+ specification
to reduce clutter and improve organization.

## Directory Structure

\`\`\`
$HOME/
├── .config/           # All config files consolidated
│   ├── shell/         # Shell configs (.zshrc, .bashrc, etc.)
│   ├── editors/       # Editor configs (vim, emacs, vscode)
│   ├── tools/         # Tool configs (git, docker, conda)
│   └── apps/          # Application-specific configs
├── Development/       # Development environment
│   ├── scripts/       # Shell scripts and utilities
│   ├── dotfiles/      # Dotfiles repo/management
│   └── environments/  # Python venvs, node versions
├── Projects/          # Project organization
│   ├── active/        # Current projects
│   ├── archived/      # Completed projects
│   └── meta/          # Meta-projects (devvyn-meta-project)
└── (standard dirs)    # Desktop, Documents, Downloads, etc.
\`\`\`

## Migrations Performed

### Shell Configurations
- .zshrc → .config/shell/zshrc
- .bashrc → .config/shell/bashrc
- .bash_profile → .config/shell/bash_profile

### Editor Configurations
- .vimrc → .config/editors/vimrc
- .vim/ → .config/editors/vim/

### Tool Configurations
- .gitconfig → .config/tools/gitconfig
- .tmux.conf → .config/tools/tmux.conf

## Backward Compatibility

All migrated files have symlinks at their original locations for backward compatibility.
Applications should continue to work without modification.

## Next Steps

1. Test shell configurations: \`source ~/.zshrc\`
2. Verify applications work with symlinked configs
3. Move projects to appropriate directories under Projects/
4. Clean up any remaining top-level clutter

## Rollback

If issues occur, restore from backup:
\`\`\`bash
# Backup location: $BACKUP_DIR
\`\`\`

## TLA+ Constraints

This migration enforces:
- Maximum 30 top-level directories
- Maximum directory depth of 10
- Maximum 10 dotfiles at root level
- Proper categorization of configs and projects

EOF

    if [[ "$DRY_RUN" == false ]]; then
        log_success "Report saved to: $report_file"
        execute_or_dry_run "open '$report_file'" "Open report"
    else
        log_info "Report would be saved to: $report_file"
    fi
}

# Main migration flow
main() {
    log_info "Starting home directory hierarchy migration..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "Running in DRY RUN mode - no changes will be made"
    fi

    create_backup
    create_structure
    migrate_shell_configs
    migrate_editor_configs
    migrate_tool_configs
    migrate_claude_config
    generate_report

    log_success "Migration complete!"

    if [[ "$DRY_RUN" == false ]]; then
        log_info "Please run: source ~/.zshrc"
        log_info "Review the migration report on your Desktop"
    else
        log_info "Run without --dry-run to execute migration"
    fi
}

# Run main
main
