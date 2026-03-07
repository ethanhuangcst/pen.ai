#!/bin/bash

# Build script for creating Pen.app bundle

set -e

echo "Building Pen.app..."

# Configuration
APP_NAME="Pen"
VERSION="1.1.2"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
RESOURCES_DIR="Resources"

# Clean previous build
echo "Cleaning previous build..."
rm -rf "${APP_BUNDLE}"
rm -rf "Pen-${VERSION}.dmg"

# Build the release version
echo "Building release version..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
echo "Copying executable..."
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
echo "Copying Info.plist..."
cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"

# Update Info.plist with actual values
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName ${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.penai.${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"

# Copy resources
echo "Copying resources..."
cp -R "${RESOURCES_DIR}/Assets" "${APP_BUNDLE}/Contents/Resources/"
cp -R "${RESOURCES_DIR}/config" "${APP_BUNDLE}/Contents/Resources/"
cp -R "${RESOURCES_DIR}/en.lproj" "${APP_BUNDLE}/Contents/Resources/"
cp -R "${RESOURCES_DIR}/zh-Hans.lproj" "${APP_BUNDLE}/Contents/Resources/"

# Copy app icon
if [ -f "${RESOURCES_DIR}/Assets/AppIcon.icns" ]; then
    cp "${RESOURCES_DIR}/Assets/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
    echo "  App icon: AppIcon.icns"
elif [ -f "${RESOURCES_DIR}/Assets/logo.png" ]; then
    echo "  Generating AppIcon.icns from logo.png..."
    mkdir -p Pen.iconset
    sips -z 16 16 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_16x16.png 2>/dev/null
    sips -z 32 32 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_16x16@2x.png 2>/dev/null
    sips -z 32 32 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_32x32.png 2>/dev/null
    sips -z 64 64 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_32x32@2x.png 2>/dev/null
    sips -z 128 128 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_128x128.png 2>/dev/null
    sips -z 256 256 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_128x128@2x.png 2>/dev/null
    sips -z 256 256 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_256x256.png 2>/dev/null
    sips -z 512 512 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_256x256@2x.png 2>/dev/null
    sips -z 512 512 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_512x512.png 2>/dev/null
    sips -z 1024 1024 "${RESOURCES_DIR}/Assets/logo.png" --out Pen.iconset/icon_512x512@2x.png 2>/dev/null
    iconutil -c icns Pen.iconset -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    rm -rf Pen.iconset
    echo "  App icon: AppIcon.icns (generated from logo.png)"
elif [ -f "${RESOURCES_DIR}/Assets/icon.png" ]; then
    echo "  Generating AppIcon.icns from icon.png..."
    mkdir -p Pen.iconset
    sips -z 16 16 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_16x16.png 2>/dev/null
    sips -z 32 32 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_16x16@2x.png 2>/dev/null
    sips -z 32 32 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_32x32.png 2>/dev/null
    sips -z 64 64 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_32x32@2x.png 2>/dev/null
    sips -z 128 128 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_128x128.png 2>/dev/null
    sips -z 256 256 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_128x128@2x.png 2>/dev/null
    sips -z 256 256 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_256x256.png 2>/dev/null
    sips -z 512 512 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_256x256@2x.png 2>/dev/null
    sips -z 512 512 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_512x512.png 2>/dev/null
    sips -z 1024 1024 "${RESOURCES_DIR}/Assets/icon.png" --out Pen.iconset/icon_512x512@2x.png 2>/dev/null
    iconutil -c icns Pen.iconset -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    rm -rf Pen.iconset
    echo "  App icon: AppIcon.icns (generated from icon.png)"
fi

# Set permissions
echo "Setting permissions..."
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod -R 755 "${APP_BUNDLE}"

# Create DMG
echo "Creating DMG installer..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${APP_BUNDLE}" \
    -ov -format UDZO \
    "${APP_NAME}-${VERSION}.dmg"

echo ""
echo "✅ Build complete!"
echo "   App bundle: ${APP_BUNDLE}"
echo "   DMG installer: ${APP_NAME}-${VERSION}.dmg"
echo ""
echo "To install on another Mac:"
echo "1. Copy ${APP_NAME}-${VERSION}.dmg to the target Mac"
echo "2. Open the DMG file"
echo "3. Drag ${APP_NAME}.app to the Applications folder"
