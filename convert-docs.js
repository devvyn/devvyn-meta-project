#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const { marked } = require('marked');
const chokidar = require('chokidar');

class DocsConverter {
    constructor() {
        this.baseDir = __dirname;
        this.sourceDir = path.join(this.baseDir, 'agents');
        this.outputDir = path.join(this.baseDir, 'docs-html');
        this.templatesDir = path.join(this.baseDir, 'doc-templates');
        this.isWatching = process.argv.includes('--watch');

        // Document type detection patterns
        this.docTypes = {
            'strategic': /strategic|framework|compass/i,
            'playbook': /playbook|quick-reference/i,
            'template': /template/i,
            'protocol': /protocol|meeting|handoff/i,
            'rules': /rules|standards/i,
            'default': /.*/
        };

        this.init();
    }

    async init() {
        console.log('🚀 Initializing Documentation Converter...');

        // Ensure output directory exists
        await fs.ensureDir(this.outputDir);
        await fs.ensureDir(this.templatesDir);

        // Extract CSS from existing visual playbook
        await this.extractBaseCSS();

        // Create templates
        await this.createTemplates();

        // Convert all existing docs
        await this.convertAllDocs();

        // Generate index
        await this.generateIndex();

        if (this.isWatching) {
            this.startWatcher();
        } else {
            console.log('✅ Conversion complete! Check the docs-html directory.');
        }
    }

    async extractBaseCSS() {
        const visualPlaybookPath = path.join(this.sourceDir, 'collaboration-playbook-visual.html');

        if (await fs.pathExists(visualPlaybookPath)) {
            const content = await fs.readFile(visualPlaybookPath, 'utf8');
            const cssMatch = content.match(/<style>([\s\S]*?)<\/style>/);

            if (cssMatch) {
                this.baseCSS = cssMatch[1];
                console.log('📝 Extracted CSS from visual playbook');
            } else {
                console.warn('⚠️ Could not extract CSS from visual playbook');
                this.baseCSS = this.getDefaultCSS();
            }
        } else {
            console.warn('⚠️ Visual playbook not found, using default CSS');
            this.baseCSS = this.getDefaultCSS();
        }
    }

    getDefaultCSS() {
        return `
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: #f8f9fa;
            color: #2c3e50;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            padding: 32px;
        }
        h1, h2, h3 { color: #2c3e50; }
        .header { text-align: center; border-bottom: 3px solid #3498db; padding-bottom: 20px; margin-bottom: 30px; }
        `;
    }

    async createTemplates() {
        const templates = {
            strategic: this.createStrategicTemplate(),
            playbook: this.createPlaybookTemplate(),
            protocol: this.createProtocolTemplate(),
            rules: this.createRulesTemplate(),
            default: this.createDefaultTemplate()
        };

        for (const [type, template] of Object.entries(templates)) {
            await fs.writeFile(
                path.join(this.templatesDir, `${type}.html`),
                template
            );
        }

        console.log('📋 Created document templates');
    }

    createStrategicTemplate() {
        return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
        ${this.baseCSS}

        .strategic-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 30px;
        }

        .principle-card {
            background: #f8f9fa;
            border-left: 4px solid #3498db;
            padding: 20px;
            margin: 20px 0;
            border-radius: 0 8px 8px 0;
        }

        .advantage-highlight {
            background: #e8f5e8;
            border: 1px solid #27ae60;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }

        .failure-warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="strategic-header">
            <h1>{{title}}</h1>
            <p>Strategic Framework for Competitive Advantage</p>
        </div>
        {{content}}
        <div class="navigation">
            <a href="index.html">← Back to Documentation Index</a>
        </div>
    </div>
</body>
</html>`;
    }

    createPlaybookTemplate() {
        return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
        ${this.baseCSS}

        .playbook-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 25px;
        }

        .decision-tree {
            background: #f8f9fa;
            border-left: 4px solid #3498db;
            padding: 15px 20px;
            margin-bottom: 15px;
            border-radius: 0 8px 8px 0;
        }

        .red-flag {
            background: #fff5f5;
            border: 2px solid #e74c3c;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
        }

        .emergency-protocol {
            background: #fff3cd;
            border: 2px solid #f39c12;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
        }

        .quick-ref {
            background: #e8f4f8;
            border: 1px solid #3498db;
            padding: 10px;
            border-radius: 6px;
            font-size: 14px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="playbook-header">
            <h1>{{title}}</h1>
            <p>Quick Reference for Daily Operations</p>
        </div>
        {{content}}
        <div class="navigation">
            <a href="index.html">← Back to Documentation Index</a>
        </div>
    </div>
</body>
</html>`;
    }

    createProtocolTemplate() {
        return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
        ${this.baseCSS}

        .protocol-header {
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 25px;
        }

        .process-step {
            background: #f8f9fa;
            border-left: 4px solid #34495e;
            padding: 20px;
            margin: 15px 0;
            border-radius: 0 8px 8px 0;
            position: relative;
        }

        .process-step::before {
            content: counter(step-counter);
            counter-increment: step-counter;
            position: absolute;
            left: -15px;
            top: 15px;
            background: #34495e;
            color: white;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 14px;
        }

        .container { counter-reset: step-counter; }
    </style>
</head>
<body>
    <div class="container">
        <div class="protocol-header">
            <h1>{{title}}</h1>
            <p>Process Protocol & Guidelines</p>
        </div>
        {{content}}
        <div class="navigation">
            <a href="index.html">← Back to Documentation Index</a>
        </div>
    </div>
</body>
</html>`;
    }

    createRulesTemplate() {
        return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
        ${this.baseCSS}

        .rules-header {
            background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 25px;
        }

        .rule-section {
            background: #f8f9fa;
            border-left: 4px solid #27ae60;
            padding: 20px;
            margin: 15px 0;
            border-radius: 0 8px 8px 0;
        }

        .standard {
            background: #e8f5e8;
            border: 1px solid #27ae60;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="rules-header">
            <h1>{{title}}</h1>
            <p>Standards & Guidelines</p>
        </div>
        {{content}}
        <div class="navigation">
            <a href="index.html">← Back to Documentation Index</a>
        </div>
    </div>
</body>
</html>`;
    }

    createDefaultTemplate() {
        return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
        ${this.baseCSS}

        .doc-header {
            background: linear-gradient(135deg, #7f8c8d 0%, #95a5a6 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 25px;
        }

        .content-section {
            background: #f8f9fa;
            border-left: 4px solid #7f8c8d;
            padding: 20px;
            margin: 15px 0;
            border-radius: 0 8px 8px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="doc-header">
            <h1>{{title}}</h1>
            <p>Documentation</p>
        </div>
        {{content}}
        <div class="navigation">
            <a href="index.html">← Back to Documentation Index</a>
        </div>
    </div>
</body>
</html>`;
    }

    detectDocumentType(filename) {
        for (const [type, pattern] of Object.entries(this.docTypes)) {
            if (type !== 'default' && pattern.test(filename)) {
                return type;
            }
        }
        return 'default';
    }

    async convertMarkdownFile(filePath) {
        const filename = path.basename(filePath, '.md');
        const relativePath = path.relative(this.sourceDir, filePath);
        const docType = this.detectDocumentType(filename);

        console.log(`📄 Converting ${relativePath} (${docType})`);

        // Read markdown content
        const markdownContent = await fs.readFile(filePath, 'utf8');

        // Convert to HTML
        const htmlContent = marked(markdownContent, {
            breaks: true,
            gfm: true
        });

        // Load template
        const templatePath = path.join(this.templatesDir, `${docType}.html`);
        let template = await fs.readFile(templatePath, 'utf8');

        // Extract title from markdown (first h1 or use filename)
        const titleMatch = markdownContent.match(/^#\s+(.+)$/m);
        const title = titleMatch ? titleMatch[1] : filename.replace(/-/g, ' ');

        // Replace template placeholders
        template = template.replace(/\{\{title\}\}/g, title);
        template = template.replace(/\{\{content\}\}/g, htmlContent);

        // Create output path
        const outputPath = path.join(this.outputDir, `${filename}.html`);

        // Write HTML file
        await fs.writeFile(outputPath, template);

        return {
            filename,
            title,
            docType,
            relativePath: `${filename}.html`
        };
    }

    async convertAllDocs() {
        const markdownFiles = await this.findMarkdownFiles();
        const convertedDocs = [];

        for (const filePath of markdownFiles) {
            try {
                const docInfo = await this.convertMarkdownFile(filePath);
                convertedDocs.push(docInfo);
            } catch (error) {
                console.error(`❌ Error converting ${filePath}:`, error.message);
            }
        }

        this.convertedDocs = convertedDocs;
        console.log(`✅ Converted ${convertedDocs.length} documents`);
    }

    async findMarkdownFiles() {
        const files = [];

        const scanDir = async (dir) => {
            const items = await fs.readdir(dir);

            for (const item of items) {
                const fullPath = path.join(dir, item);
                const stat = await fs.stat(fullPath);

                if (stat.isDirectory() && !item.startsWith('.')) {
                    await scanDir(fullPath);
                } else if (stat.isFile() && item.endsWith('.md')) {
                    files.push(fullPath);
                }
            }
        };

        await scanDir(this.sourceDir);

        // Also scan other relevant directories
        const otherDirs = ['rules', 'templates'];
        for (const dir of otherDirs) {
            const dirPath = path.join(this.baseDir, dir);
            if (await fs.pathExists(dirPath)) {
                await scanDir(dirPath);
            }
        }

        return files;
    }

    async generateIndex() {
        const indexHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevvynMurphy Meta-Project Documentation</title>
    <style>
        ${this.baseCSS}

        .index-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 30px;
        }

        .doc-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }

        .doc-card {
            background: white;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 20px;
            transition: all 0.3s ease;
            text-decoration: none;
            color: inherit;
        }

        .doc-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            text-decoration: none;
            color: inherit;
        }

        .doc-type-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 10px;
        }

        .strategic { background: #667eea; color: white; }
        .playbook { background: #27ae60; color: white; }
        .protocol { background: #34495e; color: white; }
        .rules { background: #e67e22; color: white; }
        .default { background: #95a5a6; color: white; }

        .stats {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
        }

        .stat-item {
            display: inline-block;
            margin: 0 20px;
            text-align: center;
        }

        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: #3498db;
        }

        .stat-label {
            font-size: 14px;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="index-header">
            <h1>📚 Meta-Project Documentation</h1>
            <p>Strategic frameworks, collaboration playbooks, and operational protocols</p>
        </div>

        <div class="stats">
            <div class="stat-item">
                <div class="stat-number">${this.convertedDocs.length}</div>
                <div class="stat-label">Documents</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">${new Set(this.convertedDocs.map(d => d.docType)).size}</div>
                <div class="stat-label">Categories</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">${new Date().toLocaleDateString()}</div>
                <div class="stat-label">Last Updated</div>
            </div>
        </div>

        <div class="doc-grid">
            ${this.convertedDocs.map(doc => `
                <a href="${doc.relativePath}" class="doc-card">
                    <div class="doc-type-badge ${doc.docType}">${doc.docType.toUpperCase()}</div>
                    <h3>${doc.title}</h3>
                    <p class="text-gray-600">${this.getDocDescription(doc.docType)}</p>
                </a>
            `).join('')}
        </div>

        <div style="text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
            <p style="color: #7f8c8d;">Generated automatically from markdown sources</p>
            <p style="color: #7f8c8d; font-size: 14px;">Last conversion: ${new Date().toLocaleString()}</p>
        </div>
    </div>
</body>
</html>`;

        await fs.writeFile(path.join(this.outputDir, 'index.html'), indexHTML);
        console.log('📚 Generated documentation index');
    }

    getDocDescription(docType) {
        const descriptions = {
            strategic: 'High-level principles and competitive frameworks',
            playbook: 'Quick reference guides for daily operations',
            protocol: 'Process workflows and procedural guidelines',
            rules: 'Standards, conventions, and requirements',
            default: 'General documentation and reference material'
        };
        return descriptions[docType] || descriptions.default;
    }

    startWatcher() {
        console.log('👀 Watching for changes...');

        const watcher = chokidar.watch([
            path.join(this.sourceDir, '**/*.md'),
            path.join(this.baseDir, 'rules', '**/*.md'),
            path.join(this.baseDir, 'templates', '**/*.md')
        ], {
            ignoreInitial: true
        });

        watcher.on('change', async (filePath) => {
            console.log(`🔄 File changed: ${path.relative(this.baseDir, filePath)}`);
            await this.convertMarkdownFile(filePath);
            await this.generateIndex();
            console.log('✅ Conversion updated');
        });

        watcher.on('add', async (filePath) => {
            console.log(`➕ File added: ${path.relative(this.baseDir, filePath)}`);
            await this.convertAllDocs();
            await this.generateIndex();
            console.log('✅ Documentation regenerated');
        });

        watcher.on('unlink', async (filePath) => {
            console.log(`➖ File removed: ${path.relative(this.baseDir, filePath)}`);
            await this.convertAllDocs();
            await this.generateIndex();
            console.log('✅ Documentation regenerated');
        });
    }
}

// Run the converter
new DocsConverter();
