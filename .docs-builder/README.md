# Rich Documentation Generator

Automatically converts your markdown files to beautiful, rich HTML documentation with the same styling as your collaboration playbook.

## ✨ Features

- **Rich HTML conversion** with professional styling
- **Document type detection** (framework, playbook, template, rules)
- **Auto-generated navigation** and table of contents
- **Responsive design** optimized for desktop and mobile
- **Print-friendly** layouts for physical reference cards
- **GitHub Actions integration** for automatic deployment
- **Live preview server** for development

## 🚀 Quick Start

### Local Development

1. **Install dependencies:**

   npm install

   ```

2. **Generate documentation:**

   npm run convert

   ```

3. **Preview documentation:**

   ```bash
   npm run serve

   ```

4. **Watch for changes:**

   ```bash
   npm run watch
   # Auto-regenerates on file changes
   ```

### GitHub Actions (Automatic)

The system automatically:

- ✅ Generates HTML on every commit to markdown files
- ✅ Deploys to GitHub Pages (if enabled)
- ✅ Creates preview artifacts for pull requests

## 📁 File Structure

```
.docs-builder/
├── convert.js          # Main conversion script
├── package.json        # Dependencies and scripts
├── templates/          # HTML templates for different doc types
│   ├── default.html    # Standard document template
│   ├── playbook.html   # Quick reference playbooks
│   ├── framework.html  # Strategic frameworks
│   └── index.html      # Documentation index
└── styles/
    └── main.css        # Shared styling (based on playbook design)

docs-html/              # Generated output (auto-created)

├── index.html          # Main documentation index
├── assets/            # CSS and static files
└── *.html             # Generated documentation pages
```

## 🎨 Document Types

The system automatically detects and styles different document types:

### 📋 **Framework Documents**

- Strategic planning documents
- Competitive analysis frameworks

### 🎯 **Playbook Documents**

- Quick reference guides
- Decision trees and checklists
- Operational procedures

### 📄 **Template Documents**

- Project templates
- Boilerplate content
- Standardized formats

### ⚖️ **Rules Documents**

- Coding standards
- Collaboration rules
- Policy documents
- **Special features:** Compliance tracking, enforcement guidelines

### Adding New Templates

1. Create `templates/your-type.html`
2. Use templat variables: `{{TITLE}}`, `{{CONTENT}}`, `{{DOC_TYPE}}`

3. Add detection logic in `convert.js` → `detectDocumentType()`

### Styling Changes

- Edit `styls/main.css` for global styles

- Add template-specific styles in individual template files
- Use CSS custom properties (variables) for consistent theming

### Document Dtection

The system detects document types based on:

- **File name patterns** (e.g., "playbook", "framework")
- **Directory location** (e.g., `/templates/`, `/rules/`)
- **Content nalysis** (e.g., "Decision Trees", "Strategic")

## 📊 Integration with Existing Workflow

### Works With

- ✅ Existing project management framework v2.0
- ✅ AI collaboration proocols

- ✅ Session handoff templates
- ✅ Current file organization

### Enhances

- 📈 **Readability** - Professional formatting for all documentation
- 🔍 **Discoverability** - Auto-generated navigation and search
- 📱 **Accessibility** - Mobile-friendly and print-optimized
- 🔄 **Maintenance** - Automatic updates when source files change

## 🌐 GitHub Pages Seup

1. **Enable GitHub Pages:**
   - Go to Repository → Settings → Pages
   - Source: "GitHub Actions"

2. **The workflow automatically:**
   - Generates documentation on every commit
   - Deploys to `https://yourusername.github.io/repository-name/`
   - Creates preview artifacts for pul requests

## 📝 Usage Examples

### Development Workflow

```bash

# Edit markdown files normally
vim agents/new-framework.md

# Generate and preview
npm run serve

```

### CI/CD Integration

```yaml
# Workflow runs automatically on:
- push to main/master
- changes to *.md files
- manual trigger (workflow_dispatch)

## 🎯 Next Steps

### Evolution to VitePress (Option B)

```bash
# To upgrade to full static site generator:
npm create vitepress@latest docs
# Migrate existing content and styling
```

### Advanced Features

- 🔍 Full-text search integration
- 📊 Analytics and usage tracking
- 🔗 Automated link validation
- 📱 Progressive Web App features

---

**Status:** ✅ Ready for production use
**Compatibility:** GitHub Actions, any static host
**Maintenance:** Zero-config after initial setup
