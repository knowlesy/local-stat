#!/bin/bash
set -e

echo "Building LocalStat..."
swift build -c release

echo "Creating .app bundle structure..."
mkdir -p .build/LocalStat.app/Contents/MacOS
mkdir -p .build/LocalStat.app/Contents/Resources

echo "Copying binary..."
cp .build/release/LocalStat .build/LocalStat.app/Contents/MacOS/

echo "Copying Info.plist..."
cp Sources/LocalStat/Resources/Info.plist .build/LocalStat.app/Contents/

echo "Making executable..."
chmod +x .build/LocalStat.app/Contents/MacOS/LocalStat

echo "✅ App bundle created at .build/LocalStat.app"
echo "You can double click this file to run it, or drag it to Applications."
