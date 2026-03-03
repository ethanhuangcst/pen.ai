#!/bin/bash

# Build script for creating Pen.app bundle

set -e

echo "Building Pen.app..."

# Configuration
APP_NAME="Pen"
VERSION="1.0.0"
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
