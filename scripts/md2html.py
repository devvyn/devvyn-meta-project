#!/usr/bin/env python3
"""Convert markdown to GitHub-style HTML"""

import sys
import re
from html import escape
from pathlib import Path

def markdown_to_html(md_text):
    """Basic markdown to HTML conversion"""
    html = md_text

    # Code blocks (triple backticks)
    html = re.sub(r'```(\w+)?\n(.*?)```', r'<pre><code class="language-\1">\2</code></pre>', html, flags=re.DOTALL)

    # Inline code
    html = re.sub(r'`([^`]+)`', r'<code>\1</code>', html)

    # Headers
    html = re.sub(r'^### (.*?)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.*?)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^# (.*?)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)

    # Bold
    html = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', html)

    # Italic
    html = re.sub(r'\*(.*?)\*', r'<em>\1</em>', html)

    # Horizontal rules
    html = re.sub(r'^---+$', r'<hr>', html, flags=re.MULTILINE)

    # Links
    html = re.sub(r'\[(.*?)\]\((.*?)\)', r'<a href="\2">\1</a>', html)

    # Unordered lists
    lines = html.split('\n')
    in_list = False
    result = []
    for line in lines:
        if line.startswith('- ') or line.startswith('* '):
            if not in_list:
                result.append('<ul>')
                in_list = True
            result.append(f'<li>{line[2:]}</li>')
        else:
            if in_list:
                result.append('</ul>')
                in_list = False
            result.append(line)
    if in_list:
        result.append('</ul>')
    html = '\n'.join(result)

    # Paragraphs (convert double newlines)
    html = re.sub(r'\n\n+', r'</p><p>', html)
    html = '<p>' + html + '</p>'

    # Clean up empty paragraphs and structural issues
    html = re.sub(r'<p>\s*</p>', '', html)
    html = re.sub(r'<p>(<h[1-6]>)', r'\1', html)
    html = re.sub(r'(</h[1-6]>)</p>', r'\1', html)
    html = re.sub(r'<p>(<hr>)</p>', r'\1', html)
    html = re.sub(r'<p>(</?ul>)', r'\1', html)
    html = re.sub(r'(</?ul>)</p>', r'\1', html)
    html = re.sub(r'<p>(</?pre>)', r'\1', html)
    html = re.sub(r'(</?pre>)</p>', r'\1', html)

    return html

def main():
    if len(sys.argv) < 3:
        print("Usage: md2html.py <input.md> <output.html> [title]", file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    title = sys.argv[3] if len(sys.argv) > 3 else Path(input_file).stem

    # Read markdown
    with open(input_file, 'r', encoding='utf-8') as f:
        md_content = f.read()

    # Convert to HTML
    html_body = markdown_to_html(md_content)

    # GitHub-style CSS
    css = """
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
        line-height: 1.6;
        color: #24292e;
        background-color: #ffffff;
        max-width: 980px;
        margin: 0 auto;
        padding: 45px;
    }
    h1, h2, h3, h4, h5, h6 {
        margin-top: 24px;
        margin-bottom: 16px;
        font-weight: 600;
        line-height: 1.25;
    }
    h1 { font-size: 2em; border-bottom: 1px solid #eaecef; padding-bottom: .3em; }
    h2 { font-size: 1.5em; border-bottom: 1px solid #eaecef; padding-bottom: .3em; }
    h3 { font-size: 1.25em; }
    code {
        background-color: rgba(27,31,35,.05);
        border-radius: 3px;
        font-size: 85%;
        margin: 0;
        padding: .2em .4em;
        font-family: 'SF Mono', Monaco, 'Courier New', monospace;
    }
    pre {
        background-color: #f6f8fa;
        border-radius: 3px;
        font-size: 85%;
        line-height: 1.45;
        overflow: auto;
        padding: 16px;
    }
    pre code {
        background-color: transparent;
        border: 0;
        display: inline;
        line-height: inherit;
        margin: 0;
        overflow: visible;
        padding: 0;
        word-wrap: normal;
    }
    a { color: #0366d6; text-decoration: none; }
    a:hover { text-decoration: underline; }
    ul, ol { padding-left: 2em; }
    hr {
        height: .25em;
        padding: 0;
        margin: 24px 0;
        background-color: #e1e4e8;
        border: 0;
    }
    strong { font-weight: 600; }
    table {
        border-collapse: collapse;
        width: 100%;
    }
    table th, table td {
        padding: 6px 13px;
        border: 1px solid #dfe2e5;
    }
    table tr:nth-child(2n) {
        background-color: #f6f8fa;
    }
    blockquote {
        margin: 0;
        padding: 0 1em;
        color: #6a737d;
        border-left: .25em solid #dfe2e5;
    }
    """

    # Generate HTML
    html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{escape(title)}</title>
    <style>{css}</style>
</head>
<body>
{html_body}
</body>
</html>"""

    # Write HTML file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_template)

    print(output_file)

if __name__ == '__main__':
    main()
