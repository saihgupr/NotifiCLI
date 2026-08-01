#!/bin/bash
# package.sh - Build and package NotifiCLI for release using DMGMaker
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${DIR}/build"
DMG_MAKER_DIR="${DIR}/../DMGMaker"
VERSION="1.4.2"
OUTPUT_NAME="NotifiCLI"

echo "🔨 Starting clean build for v${VERSION}..."
./build.sh
cp "Fix Security.command" "${BUILD_DIR}/"

echo "🔍 Verifying build contents..."
APPS_COUNT=$(ls -1 "${BUILD_DIR}/NotifiCLI.app/Contents/Apps" 2>/dev/null | wc -l)

if [ "$APPS_COUNT" -eq 0 ]; then
    echo "❌ Error: NotifiCLI.app/Contents/Apps/ is empty!"
    echo "   The build failed to embed variant apps. Aborting packaging."
    exit 1
fi

echo "✅ Verified: $APPS_COUNT items found in Contents/Apps/"

echo "📀 Creating DMG using DMGMaker..."
# Run DMGMaker in CLI mode
cd "$DMG_MAKER_DIR"
swift run "DMG Maker" --app "${BUILD_DIR}/NotifiCLI.app" --name "$OUTPUT_NAME"
cd "$DIR"

# Move the DMG from build/ to project root for easy access
if [ -f "${BUILD_DIR}/${OUTPUT_NAME}.dmg" ]; then
    mv "${BUILD_DIR}/${OUTPUT_NAME}.dmg" "${DIR}/"
    echo "✨ DMG created: ${DIR}/${OUTPUT_NAME}.dmg"
    echo "📊 Size: $(du -sh "${DIR}/${OUTPUT_NAME}.dmg" | cut -f1)"
    echo "🔐 SHA256: $(shasum -a 256 "${DIR}/${OUTPUT_NAME}.dmg" | cut -d' ' -f1)"
else
    echo "❌ Error: DMG was not created at ${BUILD_DIR}/${OUTPUT_NAME}.dmg"
    exit 1
fi

echo ""
echo "🚀 Ready for release v${VERSION}!"
