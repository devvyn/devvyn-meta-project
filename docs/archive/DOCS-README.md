# 📚 Documentation Generation System

This system automatically converts your markdown documentation into beautifully styled HTML versions using the same visual design as your collaboration playbook.

## ✨ Features

- **Automatic conversion** of markdown to styled HTML
- **Template-based styling** with different designs for different document types
- **Document type detection** (strategic, playbook, protocol, rules, default)
- **Cross-linking** between documents
- **Auto-generated index** with document catalog
- **Watch mode** for live updates during editing
- **GitHub Pages integration** for public documentation hosting

## 🚀 Quick Start

1. **Setup** (one time):

   ```bash
   ./setup-docs.sh
   ```

2. **Convert all docs**:

   ```bash
   npm run convert
   ```

3. **Watch for changes** (during active editing):

   ```bash
   npm run watch
   ```

4. **View results**: Open `docs-html/index.html` in your browser

## 📁 Document Types & Styling

The system automatically detects document types based on filename patterns:

- **Strategic** (`*strategic*`, `*framework*`, `*compass*`) → Purple gradient header, principle cards
- **Playbook** (`*playbook*`, `*quick-reference*`) → Blue theme, decision trees, red flags
- **Protocol** (`*protocol*`, `*meeting*`, `*handoff*`) → Dark theme, numbered process steps
- **Rules** (`*rules*`, `*standards*`) → Green theme, rule sections, standards boxes
- **Default** (everything else) → Gray theme, general document styling

## 🔄 Automation

### GitHub Actions

Automatically converts docs on every push to markdown files. Generated HTML files are:

- Committed back to the repository
- Deployed to GitHub Pages (if configured)

### Local Development

Use watch mode during active editing:

```bash
npm run watch
```

Files are reconverted automatically when you save changes.

## 🎨 Customization

### CSS Styling

The base CSS is extracted from `agents/collaboration-playbook-visual.html`. To modify styling:

1. Edit the visual playbook HTML file
2. Rerun the converter to apply changes

### Templates

Document templates are in `doc-templates/`. Modify these to change the structure or styling for different document types.

### Document Type Detection

Modify the `docTypes` patterns in `convert-docs.js` to change how documents are categorized.

## 📊 Output Structure

```
docs-html/
├── index.html                          # Main documentation index
├── human-agent-strategic-collaboration.html
├── collaboration-playbook-quick-reference.html
├── ai-collaboration-framework.html
└── ... (all other converted documents)
```

## 🔧 Technical Details

- **Built with**: Node.js, marked (markdown parser), fs-extra, chokidar (file watching)
- **Templates**: HTML with CSS and placeholder substitution
- **Dependencies**: Minimal, production-ready
- **Performance**: Fast conversion, incremental updates in watch mode

## 🚨 Troubleshooting

### "npm command not found"

Install Node.js from [nodejs.org](https://nodejs.org/)

### "Permission denied"

Make scripts executable:

```bash
chmod +x setup-docs.sh convert-docs.js
```

### Missing templates

Run setup again to regenerate templates:

```bash
./setup-docs.sh
```

---

**This documentation system ensures your strategic frameworks and playbooks are as beautiful and accessible as your original visual designs.**
