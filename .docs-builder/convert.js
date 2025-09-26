#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const { marked } = require('marked');
const chokidar = require('chokidar');
const chalk = require('chalk');

// Configuration
const CONFIG = {
  sourceDir: '..',
  outputDir: '../docs-html',
  templatesDir: './templates',
  stylesDir: './styles',
  watchMode: process.argv.includes('--watch')
};

// Document type detection based on file path and content
function detectDocumentType(filePath, content) {
  const fileName = path.basename(filePath, '.md').toLowerCase();
  const dirName = path.dirname(filePath).split('/').pop();

  // Playbook documents
  if (fileName.includes('playbook') || content.includes('Decision Trees')) {
    return 'playbook';
  }

  // Strategic/framework documents
  if (fileName.includes('strategic') || fileName.includes('framework') ||
      content.includes('Strategic') || content.includes('Framework')) {
    return 'framework';
  }

  // Templates
  if (dirName === 'templates' || fileName.includes('template')) {
    return 'template';
  }

  // Rules/standards
  if (dirName === 'rules' || fileName.includes('standards') || fileName.includes('rules')) {
    return 'rules';
  }

  // Default
  return 'standard';
}

// Enhanced markdown renderer with custom styling
function setupMarkdownRenderer() {
  const renderer = new marked.Renderer();

  // Custom heading renderer with anchors
  renderer.heading = function(text, level) {
    const escapedText = text.toLowerCase().replace(/[^\\w]+/g, '-');
    return `<h${level} id=\"${escapedText}\" class=\"heading-${level}\">${text}</h${level}>`;
  };

  // Enhanced list renderer with icons
  renderer.listitem = function(text) {
    // Detect emoji or checkbox patterns
    if (text.includes('✅') || text.includes('🔴') || text.includes('🟢')) {
      return `<li class=\"enhanced-list-item\">${text}</li>`;
    }
    return `<li>${text}</li>`;
  };

  // Code block styling
  renderer.code = function(code, language) {
    return `<pre class=\"code-block\"><code class=\"language-${language || 'text'}\">${code}</code></pre>`;
  };

  // Blockquote enhancement
  renderer.blockquote = function(quote) {
    return `<blockquote class=\"enhanced-quote\">${quote}</blockquote>`;
  };

  marked.setOptions({
    renderer: renderer,
    highlight: function(code, lang) {
      return code; // Simple highlighting - could integrate Prism.js here
    },
    pedantic: false,
    gfm: true,
    breaks: false,
    sanitize: false,
    smartLists: true,
    smartypants: false,
    xhtml: false
  });
}

// Load template for document type
async function loadTemplate(type) {
  const templatePath = path.join(CONFIG.templatesDir, `${type}.html`);

  try {
    return await fs.readFile(templatePath, 'utf8');
  } catch (error) {
    console.log(chalk.yellow(`Template ${type}.html not found, using default`));
    return await fs.readFile(path.join(CONFIG.templatesDir, 'default.html'), 'utf8');
  }
}

// Generate navigation data
async function generateNavigation(files) {
  const nav = {
    framework: [],
    playbooks: [],
    templates: [],
    rules: [],
    other: []
  };

  for (const file of files) {
    const content = await fs.readFile(file.sourcePath, 'utf8');
    const type = detectDocumentType(file.sourcePath, content);
    const title = extractTitle(content) || path.basename(file.sourcePath, '.md');

    const navItem = {
      title,
      url: file.outputPath.replace(CONFIG.outputDir, ''),
      type
    };

    switch (type) {
      case 'framework':
      case 'strategic':
        nav.framework.push(navItem);
        break;
      case 'playbook':
        nav.playbooks.push(navItem);
        break;
      case 'template':
        nav.templates.push(navItem);
        break;
      case 'rules':
        nav.rules.push(navItem);
        break;
      default:
        nav.other.push(navItem);
    }
  }

  return nav;
}

// Extract title from markdown content
function extractTitle(content) {
  const match = content.match(/^#\\s+(.+)$/m);
  return match ? match[1] : null;
}

// Convert single markdown file
async function convertFile(sourcePath, outputPath) {
  try {
    const content = await fs.readFile(sourcePath, 'utf8');
    const docType = detectDocumentType(sourcePath, content);

    // Convert markdown to HTML
    const htmlContent = marked(content);

    // Load appropriate template
    const template = await loadTemplate(docType);

    // Extract metadata
    const title = extractTitle(content) || path.basename(sourcePath, '.md');
    const lastModified = (await fs.stat(sourcePath)).mtime.toISOString().split('T')[0];

    // Replace template variables
    const finalHtml = template
      .replace(/{{TITLE}}/g, title)
      .replace(/{{CONTENT}}/g, htmlContent)
      .replace(/{{DOC_TYPE}}/g, docType)
      .replace(/{{LAST_MODIFIED}}/g, lastModified)
      .replace(/{{SOURCE_PATH}}/g, path.relative(CONFIG.sourceDir, sourcePath));

    // Ensure output directory exists
    await fs.ensureDir(path.dirname(outputPath));

    // Write HTML file
    await fs.writeFile(outputPath, finalHtml);

    console.log(chalk.green(`✓ Converted: ${sourcePath} → ${outputPath}`));
    return { sourcePath, outputPath, type: docType, title };

  } catch (error) {
    console.error(chalk.red(`✗ Error converting ${sourcePath}:`), error.message);
    return null;
  }
}

// Find all markdown files
async function findMarkdownFiles() {
  const files = [];

  async function scanDir(dir, relativePath = '') {
    const items = await fs.readdir(dir);

    for (const item of items) {
      const fullPath = path.join(dir, item);
      const relPath = path.join(relativePath, item);
      const stat = await fs.stat(fullPath);

      if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
        await scanDir(fullPath, relPath);
      } else if (item.endsWith('.md')) {
        const outputPath = path.join(CONFIG.outputDir, relPath.replace('.md', '.html'));
        files.push({ sourcePath: fullPath, outputPath, relativePath: relPath });
      }
    }
  }

  await scanDir(CONFIG.sourceDir);
  return files;
}

// Generate index page
async function generateIndex(files, navigation) {
  const indexTemplate = await loadTemplate('index');

  // Create navigation HTML
  const navHtml = Object.entries(navigation)
    .filter(([_, items]) => items.length > 0)
    .map(([category, items]) => {
      const categoryTitle = category.charAt(0).toUpperCase() + category.slice(1);
      const itemsHtml = items.map(item =>
        `<li><a href="${item.url}" class="nav-link" data-type="${item.type}">${item.title}</a></li>`
      ).join('');
      return `<div class="nav-section"><h3>${categoryTitle}</h3><ul>${itemsHtml}</ul></div>`;
    }).join('');

  const indexHtml = indexTemplate
    .replace(/{{TITLE}}/g, 'DevvynMurphy Meta-Project Documentation')
    .replace(/{{NAVIGATION}}/g, navHtml)
    .replace(/{{TOTAL_DOCS}}/g, files.length)
    .replace(/{{LAST_UPDATED}}/g, new Date().toISOString().split('T')[0]);

  await fs.writeFile(path.join(CONFIG.outputDir, 'index.html'), indexHtml);
  console.log(chalk.blue('✓ Generated index.html'));
}

// Copy static assets
async function copyAssets() {
  const assetsSource = path.join(CONFIG.stylesDir);
  const assetsTarget = path.join(CONFIG.outputDir, 'assets');

  try {
    await fs.copy(assetsSource, assetsTarget);
    console.log(chalk.blue('✓ Copied static assets'));
  } catch (error) {
    console.log(chalk.yellow('No static assets to copy'));
  }
}

// Main conversion process
async function convertAll() {
  console.log(chalk.blue('🚀 Starting documentation conversion...'));

  setupMarkdownRenderer();

  // Find all markdown files
  const files = await findMarkdownFiles();
  console.log(chalk.blue(`📄 Found ${files.length} markdown files`));

  // Convert all files
  const convertedFiles = [];
  for (const file of files) {
    const result = await convertFile(file.sourcePath, file.outputPath);
    if (result) convertedFiles.push(result);
  }

  // Generate navigation and index
  const navigation = await generateNavigation(convertedFiles);
  await generateIndex(convertedFiles, navigation);

  // Copy static assets
  await copyAssets();

  console.log(chalk.green(`\\n✅ Conversion complete! Generated ${convertedFiles.length} HTML files`));
  console.log(chalk.blue(`📂 Output directory: ${CONFIG.outputDir}`));
  console.log(chalk.blue(`🌐 Run 'npm run serve' to preview`));
}

// Watch mode
function startWatchMode() {
  console.log(chalk.blue('👀 Starting watch mode...'));

  const watcher = chokidar.watch(['../**/*.md'], {
    ignored: /(^|[\\/\\\\])\\./, // ignore dotfiles
    persistent: true
  });

  watcher
    .on('change', (path) => {
      console.log(chalk.yellow(`📝 File changed: ${path}`));
      convertAll();
    })
    .on('add', (path) => {
      console.log(chalk.green(`📄 File added: ${path}`));
      convertAll();
    })
    .on('unlink', (path) => {
      console.log(chalk.red(`🗑️  File removed: ${path}`));
      convertAll();
    });
}

// Main execution
async function main() {
  try {
    await convertAll();

    if (CONFIG.watchMode) {
      startWatchMode();
    }
  } catch (error) {
    console.error(chalk.red('💥 Conversion failed:'), error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { convertAll, convertFile };
