# Pen Mac App Distribution Plan

## Overview

This document outlines the detailed design and step-by-step plan for packaging and distributing the Pen Mac application to other Mac computers, similar to commercial macOS applications.

---

## Table of Contents

1. [Goals](#goals)
2. [Architecture Overview](#architecture-overview)
3. [Code Signing & Notarization](#code-signing--notarization)
4. [App Icon Design](#app-icon-design)
5. [Installation Wizard Design](#installation-wizard-design)
6. [Distribution Methods](#distribution-methods)
7. [Step-by-Step Implementation Plan](#step-by-step-implementation-plan)
8. [Testing Checklist](#testing-checklist)

---

## Goals

| Goal | Description |
|------|-------------|
| **Distribution** | Package app for distribution to other Macs |
| **Commercial Feel** | Run like other commercial macOS apps |
| **Branding** | Professional app icon/logo |
| **Smooth Onboarding** | Installation wizard for system permissions |
| **Key Feature** | Custom shortcut works out-of-the-box |

---

## Architecture Overview

### Current State
```
Pen.app (Development Build)
├── Compiled with Swift
├── Debug mode enabled
├── No code signature
├── No app icon (generic)
├── No entitlements configured
└── Requires Xcode to run
```

### Target State
```
Pen.app (Production Build)
├── Release build optimized
├── Code signed with Developer ID
├── Notarized by Apple
├── Custom app icon (.icns)
├── Proper entitlements
├── Hardened runtime enabled
└── Distributed via DMG/ZIP
```

---

## Code Signing & Notarization

### Prerequisites

| Item | Description | Cost |
|------|-------------|------|
| Apple Developer Account | Required for code signing | $99/year |
| Developer ID Application Certificate | For distribution outside App Store | Included |
| Developer ID Installer Certificate | For installer packages | Included |

### Entitlements Required

```xml
<!-- Pen.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Accessibility for global shortcut monitoring -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- Network access for API calls -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
    
    <!-- User Selected Files (if needed) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

### Code Signing Steps

```bash
# 1. Build release version
swift build -c release

# 2. Create app bundle structure
mkdir -p Pen.app/Contents/MacOS
mkdir -p Pen.app/Contents/Resources

# 3. Copy executable
cp .build/release/Pen Pen.app/Contents/MacOS/

# 4. Copy Info.plist
cp Info.plist Pen.app/Contents/

# 5. Copy resources
cp -r Resources/* Pen.app/Contents/Resources/

# 6. Sign the app
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --options runtime \
    --entitlements Pen.entitlements \
    Pen.app

# 7. Verify signature
codesign --verify --deep --strict --verbose=2 Pen.app
spctl --assess --verbose --type execute Pen.app
```

### Notarization Steps

```bash
# 1. Create ZIP archive
ditto -c -k --keepParent Pen.app Pen.zip

# 2. Submit for notarization
xcrun notarytool submit Pen.zip \
    --apple-id "your@email.com" \
    --password "app-specific-password" \
    --team-id "TEAM_ID" \
    --wait

# 3. Staple the ticket
xcrun stapler staple Pen.app

# 4. Verify notarization
spctl --assess --verbose --type execute Pen.app
```

---

## App Icon Design

### Icon Requirements

| Size | Usage | Filename |
|------|-------|----------|
| 16x16 | Menu bar / Small UI | icon_16x16.png |
| 32x32 | Menu bar @2x / Small UI @2x | icon_16x16@2x.png |
| 32x32 | Finder list view | icon_32x32.png |
| 64x64 | Finder list view @2x | icon_32x32@2x.png |
| 128x128 | Finder icon view | icon_128x128.png |
| 256x256 | Finder icon view @2x | icon_128x128@2x.png |
| 256x256 | Launchpad | icon_256x256.png |
| 512x512 | Launchpad @2x | icon_256x256@2x.png |
| 512x512 | App Store / About box | icon_512x512.png |
| 1024x1024 | App Store @2x | icon_512x512@2x.png |

### Icon Design Guidelines

```
┌─────────────────────────────────────┐
│                                     │
│    ┌─────────────────────────┐     │
│    │                         │     │
│    │      Pen Logo           │     │
│    │                         │     │
│    │   - Simple, memorable   │     │
│    │   - Works at small size │     │
│    │   - macOS style         │     │
│    │   - Rounded corners     │     │
│    │                         │     │
│    └─────────────────────────┘     │
│                                     │
│   Design Considerations:            │
│   • Pen/Fountain pen imagery       │
│   • AI/Writing assistant theme     │
│   • Works on light/dark mode       │
│   • Recognizable at 16x16          │
│                                     │
└─────────────────────────────────────┘
```

### Creating .icns File

```bash
# 1. Create iconset directory
mkdir Pen.iconset

# 2. Generate all required sizes from master icon
sips -z 16 16     icon_1024x1024.png --out Pen.iconset/icon_16x16.png
sips -z 32 32     icon_1024x1024.png --out Pen.iconset/icon_16x16@2x.png
sips -z 32 32     icon_1024x1024.png --out Pen.iconset/icon_32x32.png
sips -z 64 64     icon_1024x1024.png --out Pen.iconset/icon_32x32@2x.png
sips -z 128 128   icon_1024x1024.png --out Pen.iconset/icon_128x128.png
sips -z 256 256   icon_1024x1024.png --out Pen.iconset/icon_128x128@2x.png
sips -z 256 256   icon_1024x1024.png --out Pen.iconset/icon_256x256.png
sips -z 512 512   icon_1024x1024.png --out Pen.iconset/icon_256x256@2x.png
sips -z 512 512   icon_1024x1024.png --out Pen.iconset/icon_512x512.png
sips -z 1024 1024 icon_1024x1024.png --out Pen.iconset/icon_512x512@2x.png

# 3. Create .icns file
iconutil -c icns Pen.iconset -o Pen.app/Contents/Resources/AppIcon.icns
```

### Info.plist Configuration

```xml
<!-- Add to Info.plist -->
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```

---

## Installation Wizard Design

### Overview

The installation wizard guides users through the setup process, ensuring all required permissions are granted for the app to function properly.

### Permission Requirements

| Permission | Purpose | Required For |
|------------|---------|--------------|
| **Accessibility** | Global shortcut monitoring | Custom keyboard shortcut |
| **Notifications** | Update notifications | Optional |
| **Network** | API calls to AI providers | Core functionality |

### Wizard Flow

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │              Welcome to Pen                         │   │
│  │                                                     │   │
│  │   Pen is your AI writing assistant that helps      │   │
│  │   you write better, faster.                         │   │
│  │                                                     │   │
│  │   Let's set up a few things to get you started.    │   │
│  │                                                     │   │
│  │                    [ Continue ]                     │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                         Step 1/4                            │
└─────────────────────────────────────────────────────────────┘

                           │
                           ▼

┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │         Enable Keyboard Shortcut                    │   │
│  │                                                     │   │
│  │   Pen uses a global keyboard shortcut to open      │   │
│  │   the assistant from anywhere.                     │   │
│  │                                                     │   │
│  │   [Illustration of keyboard shortcut]              │   │
│  │                                                     │   │
│  │   ⚠️ Pen needs Accessibility permission            │   │
│  │                                                     │   │
│  │   [ Open System Preferences ]                      │   │
│  │                                                     │   │
│  │   Status: ○ Waiting for permission...              │   │
│  │          ● Permission granted ✓                    │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                         Step 2/4                            │
└─────────────────────────────────────────────────────────────┘

                           │
                           ▼

┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │         Choose Your Shortcut                        │   │
│  │                                                     │   │
│  │   Default: ⌘⌥P (Command + Option + P)              │   │
│  │                                                     │   │
│  │   [Record Custom Shortcut]                          │   │
│  │                                                     │   │
│  │   Current: ___________                              │   │
│  │                                                     │   │
│  │   [ Use Default ]     [ Continue ]                  │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                         Step 3/4                            │
└─────────────────────────────────────────────────────────────┘

                           │
                           ▼

┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │              Login to Pen                           │   │
│  │                                                     │   │
│  │   Email:    [________________________]              │   │
│  │                                                     │   │
│  │   Password: [________________________]              │   │
│  │                                                     │   │
│  │   ☐ Remember me                                    │   │
│  │                                                     │   │
│  │   [ Skip for Now ]     [ Login ]                    │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                         Step 4/4                            │
└─────────────────────────────────────────────────────────────┘

                           │
                           ▼

┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │              You're All Set!                        │   │
│  │                                                     │   │
│  │   ✓ Keyboard shortcut configured                   │   │
│  │   ✓ Logged in as user@example.com                  │   │
│  │                                                     │   │
│  │   Press ⌘⌥P anywhere to start using Pen!          │   │
│  │                                                     │   │
│  │   [ Start Using Pen ]                              │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation Components

#### 1. OnboardingWindow.swift

```swift
class OnboardingWindow: NSWindow {
    enum Step {
        case welcome
        case accessibility
        case shortcut
        case login
        case complete
    }
    
    var currentStep: Step = .welcome
    var onCompletion: (() -> Void)?
    
    func showStep(_ step: Step)
    func checkAccessibilityPermission() -> Bool
    func openSystemPreferences()
    func recordShortcut()
}
```

#### 2. PermissionManager.swift

```swift
class PermissionManager {
    static let shared = PermissionManager()
    
    func checkAccessibilityPermission() -> Bool
    func requestAccessibilityPermission()
    func openAccessibilitySettings()
    
    func checkNotificationPermission() -> Bool
    func requestNotificationPermission()
}
```

#### 3. FirstLaunchDetector.swift

```swift
class FirstLaunchDetector {
    static let shared = FirstLaunchDetector()
    
    var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
    }
    
    func markAsLaunched() {
        UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
    }
}
```

### Accessibility Permission Flow

```swift
// Check and request accessibility permission
func checkAndRequestAccessibility() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
    
    if !trusted {
        // Show instructions to user
        showAccessibilityInstructions()
    }
}

func showAccessibilityInstructions() {
    let alert = NSAlert()
    alert.messageText = "Enable Accessibility"
    alert.informativeText = """
    Pen needs Accessibility permission to monitor keyboard shortcuts.
    
    1. Open System Preferences > Security & Privacy > Privacy
    2. Select "Accessibility" from the list
    3. Check the box next to "Pen"
    4. Restart Pen
    """
    alert.addButton(withTitle: "Open System Preferences")
    alert.addButton(withTitle: "Later")
    
    if alert.runModal() == .alertFirstButtonReturn {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
```

---

## Distribution Methods

### Option 1: DMG with Drag-to-Install (Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌─────────────┐              ┌─────────────┐             │
│   │             │              │             │             │
│   │   Pen.app   │    ────►     │ Applications│             │
│   │             │              │    folder   │             │
│   │             │              │             │             │
│   └─────────────┘              └─────────────┘             │
│                                                             │
│   Drag Pen to the Applications folder to install           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Create DMG

```bash
# 1. Create temporary folder
mkdir -p dmg_temp

# 2. Copy app
cp -r Pen.app dmg_temp/

# 3. Create Applications symlink
ln -s /Applications dmg_temp/Applications

# 4. Create DMG
hdiutil create -volname "Pen" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    Pen-Installer.dmg

# 5. Sign the DMG
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
    Pen-Installer.dmg

# 6. Notarize the DMG
xcrun notarytool submit Pen-Installer.dmg \
    --apple-id "your@email.com" \
    --password "app-specific-password" \
    --team-id "TEAM_ID" \
    --wait

# 7. Staple
xcrun stapler staple Pen-Installer.dmg
```

### Option 2: ZIP Archive

```bash
# Simple distribution
ditto -c -k --keepParent Pen.app Pen-macOS.zip
```

### Option 3: PKG Installer

```bash
# Create installer package
pkgbuild --root Pen.app \
    --identifier com.yourcompany.pen \
    --version 1.0.0 \
    --install-location /Applications/Pen.app \
    Pen.pkg

# Sign the PKG
productsign --sign "Developer ID Installer: Your Name (TEAM_ID)" \
    Pen.pkg \
    Pen-Signed.pkg
```

### Option 4: Homebrew Cask (Future)

```ruby
# homebrew-cask/Casks/pen.rb
cask "pen" do
  version "1.0.0"
  sha256 "..."
  
  url "https://downloads.pen.ai/Pen-#{version}.dmg"
  name "Pen"
  desc "AI Writing Assistant"
  homepage "https://pen.ai"
  
  app "Pen.app"
  
  zap trash: [
    "~/Library/Application Support/Pen",
    "~/Library/Preferences/com.pen.ai.plist",
  ]
end
```

---

## Step-by-Step Implementation Plan

### Phase 1: Preparation (Week 1)

| Step | Task | Owner | Status |
|------|------|-------|--------|
| 1.1 | Register Apple Developer Account | Dev | ⬜ |
| 1.2 | Create Developer ID certificates | Dev | ⬜ |
| 1.3 | Design app icon (all sizes) | Designer | ⬜ |
| 1.4 | Create .icns file | Dev | ⬜ |
| 1.5 | Review current entitlements | Dev | ⬜ |

### Phase 2: Code Signing (Week 2)

| Step | Task | Owner | Status |
|------|------|-------|--------|
| 2.1 | Create Pen.entitlements file | Dev | ⬜ |
| 2.2 | Configure hardened runtime | Dev | ⬜ |
| 2.3 | Update Info.plist with icon | Dev | ⬜ |
| 2.4 | Create release build script | Dev | ⬜ |
| 2.5 | Test code signing locally | Dev | ⬜ |
| 2.6 | Submit for notarization | Dev | ⬜ |
| 2.7 | Verify notarization | Dev | ⬜ |

### Phase 3: Onboarding Wizard (Week 3-4)

| Step | Task | Owner | Status |
|------|------|-------|--------|
| 3.1 | Create OnboardingWindow.swift | Dev | ⬜ |
| 3.2 | Create PermissionManager.swift | Dev | ⬜ |
| 3.3 | Create FirstLaunchDetector.swift | Dev | ⬜ |
| 3.4 | Implement Welcome step UI | Dev | ⬜ |
| 3.5 | Implement Accessibility step UI | Dev | ⬜ |
| 3.6 | Implement Shortcut configuration UI | Dev | ⬜ |
| 3.7 | Implement Login step UI | Dev | ⬜ |
| 3.8 | Implement Complete step UI | Dev | ⬜ |
| 3.9 | Add first-launch detection | Dev | ⬜ |
| 3.10 | Test permission flow | Dev | ⬜ |

### Phase 4: Distribution Package (Week 5)

| Step | Task | Owner | Status |
|------|------|-------|--------|
| 4.1 | Create DMG background design | Designer | ⬜ |
| 4.2 | Create DMG build script | Dev | ⬜ |
| 4.3 | Sign and notarize DMG | Dev | ⬜ |
| 4.4 | Test DMG on clean Mac | Dev | ⬜ |
| 4.5 | Create download page | Dev | ⬜ |
| 4.6 | Set up download hosting | Dev | ⬜ |

### Phase 5: Testing & Launch (Week 6)

| Step | Task | Owner | Status |
|------|------|-------|--------|
| 5.1 | Test on multiple macOS versions | QA | ⬜ |
| 5.2 | Test on Intel Macs | QA | ⬜ |
| 5.3 | Test on Apple Silicon Macs | QA | ⬜ |
| 5.4 | Test fresh install flow | QA | ⬜ |
| 5.5 | Test upgrade from dev version | QA | ⬜ |
| 5.6 | Document installation guide | Dev | ⬜ |
| 5.7 | Launch! | Dev | ⬜ |

---

## Testing Checklist

### Pre-Distribution Testing

- [ ] App builds successfully in release mode
- [ ] App icon displays correctly in all contexts
- [ ] App launches without warnings
- [ ] All features work correctly
- [ ] No debug logs in console
- [ ] Memory usage is reasonable
- [ ] App quits cleanly

### Code Signing Testing

- [ ] Code signature is valid (`codesign --verify`)
- [ ] Gatekeeper allows the app (`spctl --assess`)
- [ ] Notarization succeeds
- [ ] Stapled ticket is valid

### Installation Testing

- [ ] DMG mounts correctly
- [ ] Drag-to-Applications works
- [ ] App launches from Applications folder
- [ ] App appears in Launchpad
- [ ] App appears in Spotlight search

### Permission Testing

- [ ] Onboarding wizard shows on first launch
- [ ] Accessibility permission request works
- [ ] System Preferences opens to correct pane
- [ ] Shortcut works after permission granted
- [ ] App remembers permission state

### Compatibility Testing

| macOS Version | Intel | Apple Silicon |
|---------------|-------|---------------|
| macOS 12 Monterey | ⬜ | ⬜ |
| macOS 13 Ventura | ⬜ | ⬜ |
| macOS 14 Sonoma | ⬜ | ⬜ |
| macOS 15 Sequoia | ⬜ | ⬜ |

---

## File Structure

### Final App Bundle Structure

```
Pen.app/
├── Contents/
│   ├── Info.plist
│   ├── PkgInfo
│   ├── MacOS/
│   │   └── Pen (executable)
│   ├── Resources/
│   │   ├── AppIcon.icns
│   │   ├── Assets/
│   │   │   ├── icon.png
│   │   │   ├── icon_offline.png
│   │   │   ├── hidden.svg
│   │   │   ├── show.svg
│   │   │   └── copy.svg
│   │   ├── ProfileImages/
│   │   └── Localizations/
│   │       ├── en.lproj/
│   │       └── zh.lproj/
│   ├── Frameworks/
│   │   └── (embedded frameworks if any)
│   └── _CodeSignature/
│       └── CodeResources
```

### Build Scripts Location

```
pen/
├── scripts/
│   ├── build-release.sh      # Build release version
│   ├── sign-app.sh           # Code sign the app
│   ├── notarize.sh           # Submit for notarization
│   ├── create-dmg.sh         # Create DMG installer
│   └── distribute.sh         # Full distribution pipeline
└── resources/
    └── dmg-background.png    # DMG background image
```

---

## Cost Estimate

| Item | Cost | Notes |
|------|------|-------|
| Apple Developer Account | $99/year | Required for code signing |
| Icon Design | $0-$500 | DIY or hire designer |
| Code Signing Certificate | $0 | Included with dev account |
| Hosting | $0-$20/month | GitHub Pages, AWS S3, etc. |
| **Total Year 1** | **$99-$620** | |

---

## Timeline

```
Week 1:  [████████] Preparation
Week 2:  [████████] Code Signing
Week 3:  [████████] Onboarding Wizard (Part 1)
Week 4:  [████████] Onboarding Wizard (Part 2)
Week 5:  [████████] Distribution Package
Week 6:  [████████] Testing & Launch
```

---

## References

- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Apple Notarization Guide](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution)
- [macOS App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/app-icon/)
- [Accessibility Permissions](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXTestingApps.html)
