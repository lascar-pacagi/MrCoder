#!/bin/bash
# Script to install Hugo Extended on Linux

set -e

HUGO_VERSION="0.138.0"

echo "📦 Installing Hugo Extended v${HUGO_VERSION}..."
echo ""

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    TEMP_DEB=$(mktemp)
    wget -O "$TEMP_DEB" "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
    sudo dpkg -i "$TEMP_DEB"
    rm -f "$TEMP_DEB"
    echo "✅ Hugo installed successfully!"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
        brew install hugo
        echo "✅ Hugo installed successfully!"
    else
        echo "❌ Homebrew not found. Please install it from https://brew.sh/"
        exit 1
    fi
else
    echo "❌ Unsupported OS. Please install Hugo manually from:"
    echo "https://github.com/gohugoio/hugo/releases/tag/v${HUGO_VERSION}"
    exit 1
fi

echo ""
hugo version
