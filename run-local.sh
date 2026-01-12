#!/bin/bash
# Quick start script for running MrCoder locally

set -e

echo "🚀 MrCoder Local Development Setup"
echo "===================================="
echo ""

# Check if Hugo is installed
if ! command -v hugo &> /dev/null; then
    echo "❌ Hugo is not installed!"
    echo ""
    echo "Please install Hugo Extended first:"
    echo ""
    echo "On Ubuntu/Debian:"
    echo "  wget https://github.com/gohugoio/hugo/releases/download/v0.138.0/hugo_extended_0.138.0_linux-amd64.deb"
    echo "  sudo dpkg -i hugo_extended_0.138.0_linux-amd64.deb"
    echo ""
    echo "On macOS:"
    echo "  brew install hugo"
    echo ""
    echo "On Windows:"
    echo "  choco install hugo-extended"
    echo ""
    exit 1
fi

# Check Hugo version
HUGO_VERSION=$(hugo version)
echo "✅ Hugo found: $HUGO_VERSION"
echo ""

# Initialize submodules if needed
if [ ! "$(ls -A themes/hugo-theme-learn)" ]; then
    echo "📦 Initializing theme submodule..."
    git submodule update --init --recursive
    echo "✅ Theme installed"
    echo ""
else
    echo "✅ Theme already installed"
    echo ""
fi

# Start the server
echo "🌐 Starting Hugo development server..."
echo "📍 Site will be available at: http://localhost:1313/MrCoder/"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

hugo server --buildDrafts --watch
