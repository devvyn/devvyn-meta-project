# MkDocs Site Setup

**Quick setup guide for building and serving the documentation site**

---

## Prerequisites

- Python 3.8+
- pip

---

## Installation

### Option 1: pip (Recommended)

```bash
# Install MkDocs and dependencies
pip install mkdocs-material
pip install mkdocs-git-revision-date-localized-plugin
pip install mkdocs-minify-plugin

# Verify installation
mkdocs --version
```

### Option 2: uv (Faster)

```bash
# Install with uv (if you have it)
uv pip install mkdocs-material
uv pip install mkdocs-git-revision-date-localized-plugin
uv pip install mkdocs-minify-plugin
```

---

## Build & Serve

### Development Server

```bash
# From project root
cd ~/devvyn-meta-project

# Serve locally (hot reload)
mkdocs serve

# Open browser to http://127.0.0.1:8000
```

### Build Static Site

```bash
# Build HTML site
mkdocs build

# Output: site/ directory
ls site/

# Serve static files (optional)
cd site && python -m http.server 8000
```

---

## Testing

### Check for Errors

```bash
# Strict mode will catch broken links, missing pages
mkdocs build --strict

# Should see:
# INFO    -  Building documentation...
# INFO    -  Cleaning site directory
# INFO    -  Documentation built in X.XX seconds
```

### Preview Tools Page

```bash
mkdocs serve

# Navigate to:
# http://127.0.0.1:8000/tools/
# http://127.0.0.1:8000/tools/coord-init/
# http://127.0.0.1:8000/tools/coord-migrate/
```

---

## Deployment

### GitHub Pages

```bash
# Deploy to gh-pages branch
mkdocs gh-deploy

# Site will be live at:
# https://devvyn.github.io/coordination-system/
```

### Local GitLab

```bash
# Build site
mkdocs build

# Copy to GitLab Pages
cp -r site/* /path/to/gitlab/public/
```

### Self-Hosted

```bash
# Build
mkdocs build

# Serve with nginx/apache
# Point to site/ directory
```

---

## Troubleshooting

### Issue: "No module named 'material'"

**Solution**: Install mkdocs-material
```bash
pip install mkdocs-material
```

### Issue: "Plugin 'git-revision-date-localized' not found"

**Solution**: Install plugin
```bash
pip install mkdocs-git-revision-date-localized-plugin
```

### Issue: "Navigation item not found"

**Solution**: Check file paths in `mkdocs.yml`
```bash
# Verify files exist
ls docs/tools/index.md
ls docs/tools/coord-init.md
ls docs/tools/coord-migrate.md
```

---

## Configuration

### Site: `mkdocs.yml`

Key settings:
```yaml
site_name: Coordination System
theme:
  name: material
  features:
    - navigation.tabs
    - search.highlight
    - content.code.copy

plugins:
  - search
  - git-revision-date-localized
  - minify
```

### Extra CSS: `docs/stylesheets/extra.css`

Custom styling (create if needed):
```css
/* Custom styles */
:root {
  --md-primary-fg-color: #3f51b5;
}
```

### Extra JS: `docs/javascripts/extra.js`

Custom scripts (create if needed):
```javascript
// Custom functionality
```

---

## Next Steps

1. Install MkDocs: `pip install mkdocs-material ...`
2. Test locally: `mkdocs serve`
3. Build site: `mkdocs build`
4. Deploy (when ready): `mkdocs gh-deploy`

---

**Last Updated**: 2025-10-30
