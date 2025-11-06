#!/usr/bin/env bash
#
# validate-boundaries.sh - Validate workspace boundary compliance
#
# Usage:
#   ./validate-boundaries.sh                      # Validate all sub-projects
#   ./validate-boundaries.sh --project herbarium  # Validate specific project
#   ./validate-boundaries.sh --fix                # Auto-fix violations where possible
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_PROJECT="$(cd "$SCRIPT_DIR/.." && pwd)"
GITHUB_DIR="$HOME/Documents/GitHub"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Options
FIX_MODE=false
SPECIFIC_PROJECT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX_MODE=true
            shift
            ;;
        --project)
            SPECIFIC_PROJECT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--fix] [--project NAME]"
            exit 1
            ;;
    esac
done

echo "=== Workspace Boundary Validation ==="
echo ""

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check() {
    ((CHECKS++))
}

#------------------------------------------------------------------------------
# Check 1: File Ownership Exclusivity
#------------------------------------------------------------------------------

check_file_ownership() {
    local project_path="$1"
    local project_name=$(basename "$project_path")

    info "Checking file ownership exclusivity for $project_name..."
    check

    # Get list of files in meta-project (excluding .git, node_modules, etc.)
    local meta_files=$(cd "$META_PROJECT" && find . -type f \
        -not -path './.git/*' \
        -not -path './node_modules/*' \
        -not -path './.venv/*' \
        -not -path './htmlcov/*' \
        -not -path './.pytest_cache/*' \
        | sed 's|^\./||' | sort)

    # Get list of files in sub-project
    local sub_files=$(cd "$project_path" && find . -type f \
        -not -path './.git/*' \
        -not -path './node_modules/*' \
        -not -path './.venv/*' \
        -not -path './htmlcov/*' \
        -not -path './.pytest_cache/*' \
        | sed 's|^\./||' | sort)

    # Find overlaps (excluding WORKSPACE_BOUNDARIES.md which is mirrored by design)
    local overlaps=$(comm -12 <(echo "$meta_files") <(echo "$sub_files") | grep -v "^WORKSPACE_BOUNDARIES.md$" || true)

    if [ -n "$overlaps" ]; then
        error "File path overlaps detected in $project_name:"
        echo "$overlaps" | while read -r file; do
            echo "  - $file"
        done

        if $FIX_MODE; then
            warning "Auto-fix not available for file overlaps (requires manual resolution)"
        fi
    else
        success "No file path overlaps in $project_name"
    fi
}

#------------------------------------------------------------------------------
# Check 2: Security Boundaries (No Credentials in Sub-Projects)
#------------------------------------------------------------------------------

check_security_boundaries() {
    local project_path="$1"
    local project_name=$(basename "$project_path")

    info "Checking security boundaries for $project_name..."
    check

    # Check for common credential files
    local credential_patterns=(
        ".env"
        ".env.local"
        ".env.production"
        "secrets/"
        "*.key"
        "*credentials*"
        "api_key*"
    )

    local violations=()
    for pattern in "${credential_patterns[@]}"; do
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                violations+=("$file")
            fi
        done < <(cd "$project_path" && find . -name "$pattern" -not -path './.git/*' 2>/dev/null || true)
    done

    # Check for API keys in code (basic scan)
    local api_key_matches=$(cd "$project_path" && grep -r "sk-or-v1\|sk-proj-\|AKIA" --include="*.py" --include="*.js" --include="*.ts" . 2>/dev/null || true)

    if [ ${#violations[@]} -gt 0 ]; then
        error "Potential credential files found in $project_name:"
        for violation in "${violations[@]}"; do
            echo "  - $violation"
        done

        if $FIX_MODE; then
            warning "Auto-fix not available for credential files (requires manual review)"
        fi
    elif [ -n "$api_key_matches" ]; then
        warning "Potential API keys detected in code for $project_name:"
        echo "$api_key_matches" | head -5
        echo "  (showing first 5 matches)"
    else
        success "No credential violations in $project_name"
    fi
}

#------------------------------------------------------------------------------
# Check 3: Service Registration
#------------------------------------------------------------------------------

check_service_registration() {
    local project_path="$1"
    local project_name=$(basename "$project_path")

    info "Checking service registration for $project_name..."
    check

    # Check if project has README indicating services
    local service_indicators=$(cd "$project_path" && grep -i "service\|api\|library\|module" README.md 2>/dev/null | head -3 || true)

    if [ -n "$service_indicators" ]; then
        # Check if SERVICE_REGISTRY.md exists and mentions this project
        if [ -f "$META_PROJECT/SERVICE_REGISTRY.md" ]; then
            if grep -q "$project_name" "$META_PROJECT/SERVICE_REGISTRY.md"; then
                success "Services from $project_name are registered"
            else
                warning "Project $project_name may offer services but not registered in SERVICE_REGISTRY.md"
                if $FIX_MODE; then
                    info "Run: Add entry to $META_PROJECT/SERVICE_REGISTRY.md"
                fi
            fi
        else
            warning "SERVICE_REGISTRY.md not found in meta-project"
            if $FIX_MODE; then
                info "Creating SERVICE_REGISTRY.md template..."
                cat > "$META_PROJECT/SERVICE_REGISTRY.md" <<EOF
# Service Registry

Services offered by sub-projects and available to the meta-project ecosystem.

## Services

<!-- Add service registrations here -->
EOF
                success "Created SERVICE_REGISTRY.md template"
            fi
        fi
    else
        success "No services detected in $project_name (or none to register)"
    fi
}

#------------------------------------------------------------------------------
# Check 4: Tool Namespace Uniqueness
#------------------------------------------------------------------------------

check_tool_namespace() {
    local project_path="$1"
    local project_name=$(basename "$project_path")

    info "Checking tool namespace uniqueness for $project_name..."
    check

    # Get script names from meta-project
    local meta_scripts=()
    if [ -d "$META_PROJECT/scripts" ]; then
        while IFS= read -r script; do
            meta_scripts+=("$(basename "$script")")
        done < <(find "$META_PROJECT/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -executable)
    fi

    # Get script names from sub-project
    local sub_scripts=()
    if [ -d "$project_path/scripts" ]; then
        while IFS= read -r script; do
            sub_scripts+=("$(basename "$script")")
        done < <(find "$project_path/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -executable)
    fi

    # Find collisions
    local collisions=()
    for sub_script in "${sub_scripts[@]}"; do
        for meta_script in "${meta_scripts[@]}"; do
            if [ "$sub_script" = "$meta_script" ]; then
                collisions+=("$sub_script")
            fi
        done
    done

    if [ ${#collisions[@]} -gt 0 ]; then
        error "Script name collisions detected in $project_name:"
        for collision in "${collisions[@]}"; do
            echo "  - $collision (exists in both meta-project and sub-project)"
        done

        if $FIX_MODE; then
            warning "Auto-fix not available for script name collisions (requires manual renaming)"
        fi
    else
        success "No script name collisions in $project_name"
    fi
}

#------------------------------------------------------------------------------
# Check 5: Boundary Doc Symmetry
#------------------------------------------------------------------------------

check_boundary_doc_symmetry() {
    local project_path="$1"
    local project_name=$(basename "$project_path")

    info "Checking boundary doc symmetry for $project_name..."
    check

    local meta_boundaries="$META_PROJECT/WORKSPACE_BOUNDARIES.md"
    local sub_boundaries="$project_path/WORKSPACE_BOUNDARIES.md"

    # Check if both exist
    if [ ! -f "$meta_boundaries" ]; then
        error "WORKSPACE_BOUNDARIES.md missing from meta-project"
        return
    fi

    if [ ! -f "$sub_boundaries" ]; then
        error "WORKSPACE_BOUNDARIES.md missing from $project_name"

        if $FIX_MODE; then
            info "Copying WORKSPACE_BOUNDARIES.md to $project_name..."
            cp "$meta_boundaries" "$sub_boundaries"
            success "Copied WORKSPACE_BOUNDARIES.md to $project_name"
        fi
        return
    fi

    # Check if CLAUDE.md references boundaries
    local sub_claude="$project_path/CLAUDE.md"
    if [ -f "$sub_claude" ]; then
        if grep -q "WORKSPACE_BOUNDARIES" "$sub_claude"; then
            success "CLAUDE.md in $project_name references boundaries"
        else
            warning "CLAUDE.md in $project_name does not reference WORKSPACE_BOUNDARIES.md"
            if $FIX_MODE; then
                info "Manual update required for CLAUDE.md"
            fi
        fi
    else
        warning "CLAUDE.md not found in $project_name"
    fi
}

#------------------------------------------------------------------------------
# Check 6: WORKSPACE_BOUNDARIES.md Mirroring
#------------------------------------------------------------------------------

check_boundaries_mirror() {
    local project_path="$1"
    local project_name=$(basename "$project_path")

    info "Checking WORKSPACE_BOUNDARIES.md mirroring for $project_name..."
    check

    local meta_boundaries="$META_PROJECT/WORKSPACE_BOUNDARIES.md"
    local sub_boundaries="$project_path/WORKSPACE_BOUNDARIES.md"

    if [ ! -f "$meta_boundaries" ] || [ ! -f "$sub_boundaries" ]; then
        # Already reported in check 5
        return
    fi

    # Compare checksums
    local meta_checksum=$(shasum -a 256 "$meta_boundaries" | awk '{print $1}')
    local sub_checksum=$(shasum -a 256 "$sub_boundaries" | awk '{print $1}')

    if [ "$meta_checksum" = "$sub_checksum" ]; then
        success "WORKSPACE_BOUNDARIES.md identical in $project_name"
    else
        error "WORKSPACE_BOUNDARIES.md differs between meta-project and $project_name"

        if $FIX_MODE; then
            info "Syncing WORKSPACE_BOUNDARIES.md to $project_name..."
            cp "$meta_boundaries" "$sub_boundaries"
            success "Synced WORKSPACE_BOUNDARIES.md to $project_name"
        fi
    fi
}

#------------------------------------------------------------------------------
# Main Validation
#------------------------------------------------------------------------------

# Find sub-projects
SUB_PROJECTS=()

if [ -n "$SPECIFIC_PROJECT" ]; then
    # Validate specific project
    PROJECT_PATH="$GITHUB_DIR/$SPECIFIC_PROJECT"
    if [ ! -d "$PROJECT_PATH" ]; then
        echo -e "${RED}Error: Project not found: $PROJECT_PATH${NC}"
        exit 1
    fi
    SUB_PROJECTS=("$PROJECT_PATH")
else
    # Find all sub-projects in GitHub directory
    if [ -d "$GITHUB_DIR" ]; then
        while IFS= read -r project_dir; do
            SUB_PROJECTS+=("$project_dir")
        done < <(find "$GITHUB_DIR" -maxdepth 1 -type d -not -name "." | sort)
    fi
fi

if [ ${#SUB_PROJECTS[@]} -eq 0 ]; then
    warning "No sub-projects found in $GITHUB_DIR"
    exit 0
fi

echo "Found ${#SUB_PROJECTS[@]} sub-project(s) to validate"
echo ""

# Run all checks for each project
for project in "${SUB_PROJECTS[@]}"; do
    PROJECT_NAME=$(basename "$project")
    echo "--- Validating: $PROJECT_NAME ---"
    echo ""

    check_file_ownership "$project"
    check_security_boundaries "$project"
    check_service_registration "$project"
    check_tool_namespace "$project"
    check_boundary_doc_symmetry "$project"
    check_boundaries_mirror "$project"

    echo ""
done

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

echo "=== Validation Summary ==="
echo "Checks run: $CHECKS"
echo -e "${GREEN}Passed${NC}: $((CHECKS - ERRORS - WARNINGS))"
echo -e "${YELLOW}Warnings${NC}: $WARNINGS"
echo -e "${RED}Errors${NC}: $ERRORS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}✗ Boundary validation FAILED${NC}"
    echo ""
    if ! $FIX_MODE; then
        echo "Run with --fix to attempt automatic remediation"
    fi
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ Boundary validation passed with warnings${NC}"
    exit 0
else
    echo -e "${GREEN}✓ Boundary validation PASSED${NC}"
    exit 0
fi
