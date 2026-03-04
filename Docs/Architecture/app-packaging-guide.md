# Step-by-Step Guide: Creating Pen Distribution Package

This guide walks you through creating a distributable Pen app package from start to finish.

---

## Prerequisites Check

Before starting, verify you have:

| Prerequisite | How to Check | Status |
|--------------|--------------|--------|
| Apple Developer Account | developer.apple.com | ⬜ |
| Xcode installed | `xcode-select -p` | ⬜ |
| Swift installed | `swift --version` | ⬜ |
| Developer ID Certificate | Keychain Access | ⬜ |

---

## Phase 1: Apple Developer Account Setup

### Step 1.1: Register for Apple Developer Account

1. Go to [developer.apple.com](https://developer.apple.com)
2. Click "Account" → "Sign In"
3. If you don't have an account, click "Create Apple ID"
4. Complete enrollment ($99/year)

### Step 1.2: Create Developer ID Certificates

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Certificates** → **+** (Create)
4. Select **Developer ID Application** → Continue
5. Follow instructions to create a Certificate Signing Request (CSR):
   ```bash
   # Open Keychain Access
   open -a "Keychain Access"
   
   # In Keychain Access menu:
   # Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority...
   
   # Fill in:
   # - User Email Address: your@email.com
   # - Common Name: Your Name (Developer ID Application)
   # - Request is: Saved to disk
   ```
6. Upload the CSR file to Apple
7. Download the certificate
8. Double-click to install in Keychain

### Step 1.3: Verify Certificate Installation

```bash
# List your certificates
security find-identity -v -p codesigning

# You should see something like:
# 1) ABC123DEF456 "Developer ID Application: Your Name (TEAM_ID)"
```

**Note your TEAM_ID** (the 10-character code in parentheses).

---

## Phase 2: Create App Icon

### Step 2.1: Design Your Icon

Create a 1024x1024 PNG icon for Pen. The icon should:
- Be simple and recognizable at small sizes
- Work on both light and dark backgrounds
- Follow macOS design guidelines

Save it as `icon_1024x1024.png` in `Resources/Assets/`

### Step 2.2: Create .icns File

```bash
# Navigate to your project
cd /Users/ethanhuang/code/pen.ai/pen/mac-app/Pen

# Create iconset directory
mkdir -p Pen.iconset

# Generate all required sizes from your 1024x1024 icon
sips -z 16 16     Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_16x16.png
sips -z 32 32     Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_16x16@2x.png
sips -z 32 32     Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_32x32.png
sips -z 64 64     Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_32x32@2x.png
sips -z 128 128   Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_128x128.png
sips -z 256 256   Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_128x128@2x.png
sips -z 256 256   Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_256x256.png
sips -z 512 512   Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_256x256@2x.png
sips -z 512 512   Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_512x512.png
sips -z 1024 1024 Resources/Assets/icon_1024x1024.png --out Pen.iconset/icon_512x512@2x.png

# Create .icns file
iconutil -c icns Pen.iconset -o Resources/Assets/AppIcon.icns

# Clean up
rm -rf Pen.iconset

# Verify
ls -la Resources/Assets/AppIcon.icns
```

---

## Phase 3: Create Entitlements File

### Step 3.1: Create Pen.entitlements

Create the file `Pen.entitlements` in your project root:

```bash
cat > Pen.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Network access for API calls -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- User selected files (read-only) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    
    <!-- Allow JIT compilation (needed for Swift) -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    
    <!-- Allow unsigned executable memory (needed for some frameworks) -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    
    <!-- Disable library validation (needed for Swift packages) -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
EOF
```

### Step 3.2: Verify Entitlements

```bash
# Check the file was created
cat Pen.entitlements
```

---

## Phase 4: Update Info.plist

### Step 4.1: Update Info.plist with Icon

```bash
# Add icon reference to Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" Info.plist

# Verify
grep CFBundleIconFile Info.plist
```

### Step 4.2: Update Info.plist with Human-Readable Values

Edit `Info.plist` to have proper values:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Pen</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.penai.Pen</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Pen</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>zh-Hans</string>
    </array>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Pen AI. All rights reserved.</string>
</dict>
</plist>
```

---

## Phase 5: Build Release Version

### Step 5.1: Build the App

```bash
# Navigate to project
cd /Users/ethanhuang/code/pen.ai/pen/mac-app/Pen

# Build release version
swift build -c release

# Verify build
ls -la .build/release/Pen
```

### Step 5.2: Create App Bundle Structure

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

# Copy resources
cp -R Resources/Assets "${APP_BUNDLE}/Contents/Resources/"
cp -R Resources/en.lproj "${APP_BUNDLE}/Contents/Resources/"
cp -R Resources/zh-Hans.lproj "${APP_BUNDLE}/Contents/Resources/"

# Copy app icon
cp Resources/Assets/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/"

# Set permissions
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod -R 755 "${APP_BUNDLE}"

# Verify structure
ls -la "${APP_BUNDLE}/Contents/"
```

---

## Phase 6: Code Signing

### Step 6.1: Find Your Certificate

```bash
# List available signing certificates
security find-identity -v -p codesigning

# Note the full certificate name, e.g.:
# "Developer ID Application: Your Name (TEAM_ID)"
```

### Step 6.2: Sign the App

```bash
# Replace with your certificate name
CERTIFICATE_NAME="Developer ID Application: Your Name (TEAM_ID)"

# Sign the app
codesign --deep --force --verify --verbose \
    --sign "${CERTIFICATE_NAME}" \
    --options runtime \
    --entitlements Pen.entitlements \
    --timestamp \
    Pen.app

# Verify signature
codesign --verify --deep --strict --verbose=2 Pen.app
```

### Step 6.3: Verify Gatekeeper Acceptance

```bash
# Check if Gatekeeper will accept the app
spctl --assess --verbose --type execute Pen.app

# Expected output:
# Pen.app: accepted
# source=Developer ID
```

---

## Phase 7: Notarization

### Step 7.1: Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to **Security** → **App-Specific Passwords**
4. Click **Generate Password**
5. Name it "Pen Notarization"
6. Copy the password (you won't see it again)

### Step 7.2: Store Credentials for Notarytool

```bash
# Store credentials (replace with your values)
xcrun notarytool store-credentials "pen-notary" \
    --apple-id "your@email.com" \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --team-id "TEAM_ID"

# Verify
xcrun notarytool history --keychain-profile "pen-notary"
```

### Step 7.3: Create ZIP for Notarization

```bash
# Create ZIP archive
ditto -c -k --keepParent Pen.app Pen.zip

# Verify
ls -la Pen.zip
```

### Step 7.4: Submit for Notarization

```bash
# Submit for notarization (this takes 5-15 minutes)
xcrun notarytool submit Pen.zip \
    --keychain-profile "pen-notary" \
    --wait

# If successful, you'll see:
#   status: Accepted
```

### Step 7.5: Staple the Ticket

```bash
# Staple the notarization ticket to the app
xcrun stapler staple Pen.app

# Verify
spctl --assess --verbose --type execute Pen.app
```

---

## Phase 8: Create DMG Installer

### Step 8.1: Create DMG Folder Structure

```bash
# Create temporary DMG folder
mkdir -p dmg_temp

# Copy app
cp -R Pen.app dmg_temp/

# Create Applications symlink
ln -s /Applications dmg_temp/Applications

# Verify
ls -la dmg_temp/
```

### Step 8.2: Create DMG

```bash
# Create DMG
hdiutil create -volname "Pen" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    Pen-1.0.0.dmg

# Clean up
rm -rf dmg_temp
```

### Step 8.3: Sign the DMG

```bash
# Sign the DMG
CERTIFICATE_NAME="Developer ID Application: Your Name (TEAM_ID)"

codesign --sign "${CERTIFICATE_NAME}" \
    --timestamp \
    Pen-1.0.0.dmg

# Verify
codesign --verify --verbose Pen-1.0.0.dmg
```

### Step 8.4: Notarize the DMG (Optional but Recommended)

```bash
# Submit DMG for notarization
xcrun notarytool submit Pen-1.0.0.dmg \
    --keychain-profile "pen-notary" \
    --wait

# Staple
xcrun stapler staple Pen-1.0.0.dmg
```

---

## Phase 9: Final Verification

### Step 9.1: Test on Your Mac

```bash
# Mount DMG
hdiutil attach Pen-1.0.0.dmg

# Copy to Applications
cp -R /Volumes/Pen/Pen.app /Applications/

# Unmount
hdiutil detach /Volumes/Pen

# Launch
open /Applications/Pen.app
```

### Step 9.2: Test on Another Mac

1. Copy `Pen-1.0.0.dmg` to a USB drive or upload to cloud
2. On another Mac, download the DMG
3. Open the DMG
4. Drag Pen.app to Applications
5. Launch Pen from Applications
6. Verify it opens without warnings

---

## Phase 10: Distribution

### Step 10.1: Upload for Distribution

Upload the DMG to your distribution channel:
- Your website
- GitHub Releases
- AWS S3
- Cloud storage

### Step 10.2: Create Download Page

Create a simple download page with:
- Download button
- System requirements (macOS 12+)
- Installation instructions
- SHA256 checksum

```bash
# Generate checksum
shasum -a 256 Pen-1.0.0.dmg
```

---

## Quick Reference: Complete Build Script

Create `build-distribution.sh`:

```bash
#!/bin/bash
set -e

# Configuration
APP_NAME="Pen"
VERSION="1.0.0"
CERTIFICATE_NAME="Developer ID Application: Your Name (TEAM_ID)"
NOTARY_PROFILE="pen-notary"

echo "=========================================="
echo "Building ${APP_NAME} v${VERSION} for Distribution"
echo "=========================================="

# Phase 5: Build
echo "[1/6] Building release version..."
swift build -c release

# Create app bundle
echo "[2/6] Creating app bundle..."
rm -rf "${APP_NAME}.app"
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"

cp ".build/release/${APP_NAME}" "${APP_NAME}.app/Contents/MacOS/"
cp Info.plist "${APP_NAME}.app/Contents/"
cp -R Resources/Assets "${APP_NAME}.app/Contents/Resources/"
cp -R Resources/en.lproj "${APP_NAME}.app/Contents/Resources/"
cp -R Resources/zh-Hans.lproj "${APP_NAME}.app/Contents/Resources/"

chmod +x "${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

# Phase 6: Code Sign
echo "[3/6] Code signing..."
codesign --deep --force --verify --verbose \
    --sign "${CERTIFICATE_NAME}" \
    --options runtime \
    --entitlements Pen.entitlements \
    --timestamp \
    "${APP_NAME}.app"

# Phase 7: Notarize
echo "[4/6] Notarizing..."
ditto -c -k --keepParent "${APP_NAME}.app" "${APP_NAME}.zip"
xcrun notarytool submit "${APP_NAME}.zip" \
    --keychain-profile "${NOTARY_PROFILE}" \
    --wait
xcrun stapler staple "${APP_NAME}.app"
rm "${APP_NAME}.zip"

# Phase 8: Create DMG
echo "[5/6] Creating DMG..."
mkdir -p dmg_temp
cp -R "${APP_NAME}.app" dmg_temp/
ln -s /Applications dmg_temp/Applications
hdiutil create -volname "${APP_NAME}" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    "${APP_NAME}-${VERSION}.dmg"
rm -rf dmg_temp

# Sign DMG
echo "[6/6] Signing DMG..."
codesign --sign "${CERTIFICATE_NAME}" --timestamp "${APP_NAME}-${VERSION}.dmg"

# Optional: Notarize DMG
# xcrun notarytool submit "${APP_NAME}-${VERSION}.dmg" \
#     --keychain-profile "${NOTARY_PROFILE}" \
#     --wait
# xcrun stapler staple "${APP_NAME}-${VERSION}.dmg"

echo ""
echo "✅ Build complete!"
echo "   DMG: ${APP_NAME}-${VERSION}.dmg"
echo ""
echo "Checksums:"
shasum -a 256 "${APP_NAME}-${VERSION}.dmg"
```

---

## Troubleshooting

### Issue: "codesign failed with exit code 1"

**Solution**: Check your certificate name:
```bash
security find-identity -v -p codesigning
```

### Issue: "notarytool failed: The signature of the binary is invalid"

**Solution**: Ensure you're using `--options runtime` and have proper entitlements.

### Issue: "App is damaged and can't be opened"

**Solution**: The app isn't properly notarized. Re-run notarization and stapling.

### Issue: "Accessibility permission not working"

**Solution**: This is expected - users must grant Accessibility permission manually. The onboarding wizard should guide them through this.

---

## Checklist Before Distribution

- [ ] App icon displays in Finder
- [ ] App icon displays in Dock
- [ ] App launches without warnings
- [ ] Code signature is valid
- [ ] Gatekeeper accepts the app
- [ ] Notarization succeeded
- [ ] DMG mounts correctly
- [ ] App works on another Mac
- [ ] Checksum generated
