#!/bin/bash

# Build Linux executable and copy to dist folder
# Run this script on a Linux machine

set -e

echo "Building Linux executable..."
flutter build linux --release

echo "Creating dist folder..."
mkdir -p dist

echo "Copying executable to dist..."
cp -r build/linux/x64/release/bundle/* dist/

echo "Build complete! Executable is in dist folder."
echo "To run: cd dist && ./tkubectl"
