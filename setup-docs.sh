#!/bin/bash

# Documentation Converter Setup Script

echo "🚀 Setting up Documentation Converter..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "📦 Installing dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
    echo ""
    echo "🎉 Setup complete! You can now:"
    echo "   • Run 'npm run convert' to convert all docs once"
    echo "   • Run 'npm run watch' to auto-convert on file changes"
    echo "   • Check the 'docs-html' folder for generated files"
    echo ""

    # Run initial conversion
    echo "🔄 Running initial conversion..."
    npm run convert

    if [ $? -eq 0 ]; then
        echo ""
        echo "🎊 Initial conversion complete!"
        echo "   Open docs-html/index.html in your browser to see the results"
    fi
else
    echo "❌ Installation failed. Please check the error messages above."
    exit 1
fi
