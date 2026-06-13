#!/bin/bash
set -e

# First ensure the app is built and bundled
./scripts/bundle.sh

APP_NAME="LocalStat"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR=".build/dmg_staging"

echo "Preparing DMG staging area..."
rm -rf "$STAGING_DIR"
rm -f "$DMG_NAME"
mkdir -p "$STAGING_DIR"

echo "Copying app to staging area..."
cp -R ".build/${APP_NAME}.app" "$STAGING_DIR/"

echo "Creating Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

echo "Building DMG image..."
hdiutil create -volname "${APP_NAME}" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

echo "Cleaning up..."
rm -rf "$STAGING_DIR"

echo "✅ Successfully created $DMG_NAME!"
