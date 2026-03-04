# Pen Distribution Guide (Free Apple ID)

This guide is for distributing Pen **without** a paid Apple Developer Program membership.

---

## Important Limitations

With a free Apple ID, your distributed app will:

| Limitation | Impact |
|------------|--------|
| **Not code signed** | Users see "Unidentified Developer" warning |
| **Not notarized** | macOS Gatekeeper will block the app |
| **No Developer ID** | Cannot create distribution certificates |

---

## Distribution Method: Unsigned App

### Step 1: Build Release Version

```bash
cd /Users/ethanhuang/code/pen.ai/pen/mac-app/Pen

# Build release version
swift build -c release
```

### Step 2: Create App Bundle

```bash
# Define variables
APP_NAME="Pen"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

# Clean previous build
rm -rf "${APP_BUNDLE}"

# Create app bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName ${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.penai.${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"

# Copy resources
cp -R Resources/Assets "${APP_BUNDLE}/Contents/Resources/"
cp -R Resources/en.lproj "${APP_BUNDLE}/Contents/Resources/"
cp -R Resources/zh-Hans.lproj "${APP_BUNDLE}/Contents/Resources/"

# Set permissions
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod -R 755 "${APP_BUNDLE}"
```

### Step 3: Create DMG (Optional)

```bash
# Create DMG folder
mkdir -p dmg_temp
cp -R Pen.app dmg_temp/
ln -s /Applications dmg_temp/Applications

# Create DMG
hdiutil create -volname "Pen" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    Pen-1.0.0-unsigned.dmg

# Clean up
rm -rf dmg_temp
```

### Step 4: Create ZIP (Alternative)

```bash
# Simple ZIP distribution
ditto -c -k --keepParent Pen.app Pen-1.0.0-unsigned.zip
```

---

## User Installation Instructions

Since the app is unsigned, users need to bypass macOS security:

### Method 1: Right-Click Open (Easiest)

1. Download `Pen-1.0.0-unsigned.dmg`
2. Open the DMG
3. Drag `Pen.app` to Applications
4. **Right-click** (or Control-click) on `Pen.app` in Applications
5. Select **Open** from the context menu
6. Click **Open** in the security dialog
7. The app will launch and be trusted for future opens

### Method 2: System Preferences

1. Try to open Pen.app normally
2. You'll see: "Pen cannot be opened because it is from an unidentified developer"
3. Go to **System Preferences** → **Privacy & Security**
4. Click **Open Anyway** next to the security warning
5. Click **Open** in the confirmation dialog

### Method 3: Terminal Command

```bash
# Remove quarantine attribute
xattr -cr /Applications/Pen.app

# Then open normally
open /Applications/Pen.app
```

---

## Create Installation Guide for Users

Create a `README.txt` to include with your distribution:

```
═══════════════════════════════════════════════════════════════
                    Pen - AI Writing Assistant
                         Installation Guide
═══════════════════════════════════════════════════════════════

INSTALLATION
───────────────────────────────────────────────────────────────

1. Open Pen-1.0.0-unsigned.dmg
2. Drag Pen.app to the Applications folder
3. IMPORTANT: Follow the security bypass steps below

SECURITY BYPASS (Required for unsigned apps)
───────────────────────────────────────────────────────────────

macOS will show a security warning because Pen is not code-signed.

Option A - Right-Click Method (Recommended):
  1. Go to Applications folder
  2. Right-click (or Control-click) on Pen.app
  3. Select "Open" from the menu
  4. Click "Open" in the security dialog

Option B - System Preferences:
  1. Try to open Pen.app normally
  2. When warned, go to System Preferences → Privacy & Security
  3. Click "Open Anyway" next to the security warning

Option C - Terminal:
  Open Terminal and run:
  xattr -cr /Applications/Pen.app

FIRST RUN SETUP
───────────────────────────────────────────────────────────────

1. Pen needs Accessibility permission for keyboard shortcuts
2. When prompted, open System Preferences → Privacy & Security
   → Accessibility
3. Enable Pen in the list

SYSTEM REQUIREMENTS
───────────────────────────────────────────────────────────────

• macOS 12.0 (Monterey) or later
• Internet connection

SUPPORT
───────────────────────────────────────────────────────────────

Website: https://pen.ai
Email: support@pen.ai

═══════════════════════════════════════════════════════════════
```

---

## Complete Build Script for Unsigned Distribution

Create `build-unsigned.sh`:

```bash
#!/bin/bash
set -e

APP_NAME="Pen"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "=========================================="
echo "Building ${APP_NAME} v${VERSION} (Unsigned)"
echo "=========================================="

# Build
echo "[1/4] Building release version..."
swift build -c release

# Create app bundle
echo "[2/4] Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
cp Info.plist "${APP_BUNDLE}/Contents/"

/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName ${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.penai.${APP_NAME}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"

cp -R Resources/Assets "${APP_BUNDLE}/Contents/Resources/"
cp -R Resources/en.lproj "${APP_BUNDLE}/Contents/Resources/"
cp -R Resources/zh-Hans.lproj "${APP_BUNDLE}/Contents/Resources/"

chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Create DMG
echo "[3/4] Creating DMG..."
rm -rf dmg_temp
mkdir -p dmg_temp
cp -R "${APP_BUNDLE}" dmg_temp/
ln -s /Applications dmg_temp/Applications
cp README.txt dmg_temp/ 2>/dev/null || true

hdiutil create -volname "${APP_NAME}" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    "${APP_NAME}-${VERSION}-unsigned.dmg"
rm -rf dmg_temp

# Create ZIP
echo "[4/4] Creating ZIP..."
ditto -c -k --keepParent "${APP_BUNDLE}" "${APP_NAME}-${VERSION}-unsigned.zip"

echo ""
echo "✅ Build complete!"
echo ""
echo "Files created:"
echo "  • ${APP_NAME}-${VERSION}-unsigned.dmg"
echo "  • ${APP_NAME}-${VERSION}-unsigned.zip"
echo ""
echo "⚠️  WARNING: App is UNSIGNED"
echo "   Users must bypass Gatekeeper to install"
echo "   See README.txt for instructions"
echo ""
echo "To distribute without warnings, consider joining"
echo "the Apple Developer Program (\$99/year)"
```

---

## Comparison: Free vs Paid Distribution

| Aspect | Free (Unsigned) | Paid (Signed & Notarized) |
|--------|-----------------|---------------------------|
| **Cost** | $0 | $99/year |
| **User Experience** | Extra steps to bypass security | Double-click to open |
| **Trust** | "Unidentified Developer" | Verified developer |
| **Gatekeeper** | Blocks app | Allows app |
| **Professional** | Less professional | Professional |
| **Support** | Users may be confused | Smooth experience |

---

## Recommendation

For **personal use** or **small team** (trusted users):
- Free distribution is fine
- Provide clear installation instructions

For **public distribution** or **commercial use**:
- Join Apple Developer Program ($99/year)
- Follow the full signed/notarized guide
- Professional user experience

---

## Next Steps

1. **If you want free distribution now**:
   ```bash
   cd /Users/ethanhuang/code/pen.ai/pen/mac-app/Pen
   chmod +x build-unsigned.sh
   ./build-unsigned.sh
   ```

2. **If you want professional distribution**:
   - Enroll in Apple Developer Program
   - Follow the full guide in `app-packaging-guide.md`
