# Light and Dark Mode Support Design

## 1. UI Design Principles

### 1.1 Core Principles
- **Consistency**: Maintain visual consistency across light and dark modes
- **Accessibility**: Ensure proper contrast and readability in both modes
- **Platform Alignment**: Follow macOS design guidelines for appearance adaptation
- **User Control**: Provide users with control over appearance settings
- **Performance**: Ensure smooth transitions between modes

### 1.2 Design Philosophy
- **Adaptive Design**: UI elements should automatically adjust to the current appearance mode
- **System Integration**: Default to system appearance settings but allow user overrides
- **Visual Harmony**: Colors should work well together in both light and dark environments
- **Minimal Disruption**: Mode changes should not disrupt user workflow

## 2. UI Design Changes

### 2.1 Color System

#### Light Mode Color Palette
| Color | Hex Code | Usage |
|-------|----------|-------|
| Primary | #007AFF | Buttons, links, primary actions |
| Secondary | #5AC8FA | Secondary buttons, accents |
| Background | #F2F2F7 | Window backgrounds |
| Surface | #FFFFFF | Cards, panels, input fields |
| Text | #000000 | Primary text |
| Text Secondary | #8E8E93 | Secondary text, placeholders |
| Border | #C6C6C8 | Dividers, borders |
| Success | #34C759 | Success messages, indicators |
| Warning | #FF9500 | Warnings, alerts |
| Error | #FF3B30 | Errors, destructive actions |

#### Dark Mode Color Palette
| Color | Hex Code | Usage |
|-------|----------|-------|
| Primary | #0A84FF | Buttons, links, primary actions |
| Secondary | #30B0C7 | Secondary buttons, accents |
| Background | #1C1C1E | Window backgrounds |
| Surface | #2C2C2E | Cards, panels, input fields |
| Text | #FFFFFF | Primary text |
| Text Secondary | #8E8E93 | Secondary text, placeholders |
| Border | #3A3A3C | Dividers, borders |
| Success | #30D158 | Success messages, indicators |
| Warning | #FF9F0A | Warnings, alerts |
| Error | #FF453A | Errors, destructive actions |

### 2.2 UI Elements Adaptation

#### Windows and Panels
- **Background Color**: Use system dynamic colors for window backgrounds
- **Borders**: Adjust border colors based on current mode
- **Shadows**: Modify shadow intensity for better visibility in each mode

#### Text Elements
- **Primary Text**: Use `NSColor.labelColor` for automatic adaptation
- **Secondary Text**: Use `NSColor.secondaryLabelColor`
- **Placeholder Text**: Use `NSColor.placeholderTextColor`

#### Buttons
- **Primary Buttons**: Use system accent color for consistent appearance
- **Secondary Buttons**: Adapt background and text colors based on mode
- **Hover States**: Adjust hover effects for each mode

#### Text Fields
- **Background**: Use `NSColor.textBackgroundColor` for automatic adaptation
- **Border**: Use system gray colors that adapt to mode
- **Focus State**: Use system accent color for focus indicators

#### Icons and Images
- **System Icons**: Use SF Symbols with automatic tinting
- **Custom Icons**: Provide light and dark mode versions
- **Logo**: Create adaptive logo that works well in both modes

### 2.3 Auto-Switch Control

#### UI Component
- **Location**: General tab in Preferences window
- **Control Type**: ON/OFF switch (NSSwitch)
- **Label**: "Auto-switch appearance"
- **Description**: "Automatically switch between light and dark mode based on system settings"

#### Behavior
- **ON**: App follows system appearance settings
- **OFF**: App uses the manually selected appearance mode
- **Default**: ON

## 3. Color Themes and Changeable UI Elements

### 3.1 Color Theme Management
- **System**: Use macOS system color APIs for automatic adaptation
- **Customization**: Allow users to override specific colors if needed
- **Accessibility**: Support high contrast modes

### 3.2 Logo Adaptation
- **Light Mode Logo**: Dark text on light background (`Resources/Assets/logo.png`)
- **Dark Mode Logo**: Light text on dark background (`Resources/Assets/logo_dark.png`)
- **Implementation**: Use conditional logic to load appropriate logo based on current appearance mode
- **Status**: Dark mode logo already created and available at `../mac-app/Pen/Resources/Assets/logo_dark.png`

### 3.3 Other Changeable UI Elements
- **App Icons**: Provide light and dark mode app icons
- **Toolbars**: Adjust toolbar colors and icons based on mode
- **Menus**: Adapt menu item colors and highlights
- **Status Bar Items**: Ensure visibility in both modes

## 4. Code Changes and Impact

### 4.1 Core Changes

#### 1. Replace Hardcoded Colors
- **File**: All view files
- **Change**: Replace hardcoded colors with system dynamic colors
- **Example**: `NSColor.white.cgColor` → `NSColor.systemBackground.cgColor`

#### 2. Appearance Change Observer
- **File**: `AppDelegate.swift` or `Pen.swift`
- **Change**: Add observer for `NSApplication.effectiveAppearance` changes
- **Impact**: Allows app to respond to system appearance changes

#### 3. User Defaults for Appearance Settings
- **File**: `SystemConfigService.swift`
- **Change**: Add preference for auto-switch and manual appearance selection
- **Impact**: Persists user's appearance preferences

#### 4. Dynamic Color Extension
- **File**: `Sources/Services/ColorService.swift` (new)
- **Change**: Create helper methods for dynamic colors
- **Impact**: Simplifies color management across the app

### 4.2 File-Specific Changes

#### BaseWindow.swift
- **Change**: Update background color to use system dynamic color
- **Impact**: All windows inherit proper background color

#### AccountTabView.swift
- **Change**: Replace white background with system dynamic color
- **Change**: Update text field backgrounds to use system dynamic color
- **Impact**: Fixes invisible text issue in dark mode

#### All View Files
- **Change**: Replace hardcoded colors with system dynamic colors
- **Change**: Ensure text colors use system label colors
- **Impact**: All UI elements adapt to current appearance mode

### 4.3 Performance Impact
- **Memory**: Minimal impact, uses system color APIs
- **CPU**: Negligible impact, appearance changes are handled by the system
- **Storage**: Slight increase for additional assets (light/dark logos)

## 5. Implementation Details

### 5.1 Technical Approach
- **Use System APIs**: Leverage macOS built-in appearance APIs
- **Asset Catalog**: Use asset catalog for images with light/dark variants
- **Notification Center**: Listen for appearance change notifications
- **User Defaults**: Store user preferences for appearance settings

### 5.2 Testing Strategy
- **Manual Testing**: Test in both light and dark modes
- **Automated Testing**: Add tests for appearance adaptation
- **Accessibility Testing**: Ensure proper contrast in both modes
- **Performance Testing**: Verify smooth transitions between modes

### 5.3 Migration Plan
- **Phase 1**: Replace hardcoded colors with system dynamic colors
- **Phase 2**: Add appearance change observer
- **Phase 3**: Implement auto-switch control in Preferences
- **Phase 4**: Update assets with light/dark variants
- **Phase 5**: Test and refine

## 6. Implementation Plan

### 6.1 Phase 1: Replace Hardcoded Colors (Priority: High, Estimated: 2-3 days)

#### Task 1.1: Create ColorService.swift
- **File**: `Sources/Services/ColorService.swift`
- **Description**: Create a new service to manage dynamic colors
- **Implementation**:
  ```swift
  class ColorService {
      static let shared = ColorService()
      
      // Dynamic colors that adapt to appearance
      var backgroundColor: NSColor { NSColor.systemBackground }
      var surfaceColor: NSColor { NSColor.underPageBackgroundColor }
      var textColor: NSColor { NSColor.labelColor }
      var secondaryTextColor: NSColor { NSColor.secondaryLabelColor }
      var borderColor: NSColor { NSColor.separatorColor }
      
      // Helper method to get CGColor
      func cgColor(_ color: NSColor) -> CGColor {
          return color.cgColor
      }
  }
  ```
- **Acceptance Criteria**: Service compiles and provides dynamic colors

#### Task 1.2: Update BaseWindow.swift
- **File**: `Sources/Views/BaseWindow.swift`
- **Changes**:
  - Line 102: Replace `NSColor.white.cgColor` with `ColorService.shared.cgColor(.systemBackground)`
  - Line 111: Replace `NSColor.black.withAlphaComponent(0.3)` with `NSColor.shadowColor`
  - Line 427: Replace `NSColor.black.withAlphaComponent(0.3)` with `NSColor.shadowColor`
  - Line 439: Replace `.white` with `.labelColor` for message text
- **Testing**: Verify window background adapts to light/dark mode
- **Acceptance Criteria**: Window background changes correctly in both modes

#### Task 1.3: Update AccountTabView.swift
- **File**: `Sources/Views/AccountTabView.swift`
- **Changes**:
  - Line 29: Replace `NSColor.white.cgColor` with `ColorService.shared.cgColor(.systemBackground)`
  - Line 180: Replace hardcoded light gray with `NSColor.textBackgroundColor`
  - Line 188: Replace hardcoded light gray with `NSColor.textBackgroundColor`
  - Line 224: Replace hardcoded light gray with `NSColor.textBackgroundColor`
  - Line 232: Replace hardcoded light gray with `NSColor.textBackgroundColor`
- **Testing**: Verify all text fields are visible in both modes
- **Acceptance Criteria**: Text fields show proper colors in both modes

#### Task 1.4: Update All View Files
- **Files**: All view files in `Sources/Views/`
- **Changes**:
  - Replace all `NSColor.white.cgColor` with `ColorService.shared.cgColor(.systemBackground)`
  - Replace all `NSColor.black` references with system dynamic colors
  - Ensure all text colors use `NSColor.labelColor` or `NSColor.secondaryLabelColor`
- **Files to Update**:
  - `HistoryTabView.swift` (Line 39)
  - `ForgotPasswordWindow.swift` (Line 35, 45)
  - `PreferencesWindow.swift` (Line 79, 106)
  - `GeneralTabView.swift` (Line 22)
  - `PromptsTabView.swift` (Line 43, 145, 207, 495, 501)
  - `AIConfigurationTabView.swift` (Line 38, 153, 644, 650)
  - `WindowManager.swift` (Line 120, 132)
- **Testing**: Verify all views adapt to both modes
- **Acceptance Criteria**: All UI elements visible and properly colored in both modes

### 6.2 Phase 2: Add Appearance Change Observer (Priority: High, Estimated: 1 day)

#### Task 2.1: Add Observer in Pen.swift
- **File**: `Sources/App/Pen.swift`
- **Description**: Add observer for system appearance changes
- **Implementation**:
  ```swift
  // In applicationDidFinishLaunching
  NotificationCenter.default.addObserver(
      self,
      selector: #selector(appearanceChanged(_:)),
      name: NSApplication.effectiveAppearanceChangedNotification,
      object: nil
  )
  
  @objc func appearanceChanged(_ notification: Notification) {
      // Only respond if auto-switch is enabled
      guard SystemConfigService.shared.autoSwitchAppearance else { return }
      
      // Update all windows
      DispatchQueue.main.async {
          NSApplication.shared.windows.forEach { window in
              window.contentView?.needsDisplay = true
          }
      }
  }
  ```
- **Testing**: Switch system appearance and verify app responds
- **Acceptance Criteria**: App updates immediately when system appearance changes

#### Task 2.2: Add User Preferences
- **File**: `Sources/Services/SystemConfigService.swift`
- **Changes**: Add properties for appearance settings
- **Implementation**:
  ```swift
  private let autoSwitchAppearanceKey = "autoSwitchAppearance"
  private let manualAppearanceKey = "manualAppearance"
  
  var autoSwitchAppearance: Bool {
      get {
          return UserDefaults.standard.bool(forKey: autoSwitchAppearanceKey)
      }
      set {
          UserDefaults.standard.set(newValue, forKey: autoSwitchAppearanceKey)
      }
  }
  
  var manualAppearance: NSAppearance.Appearance? {
      get {
          let rawValue = UserDefaults.standard.string(forKey: manualAppearanceKey)
          switch rawValue {
          case "dark":
              return NSAppearance(named: .darkAqua)
          case "light":
              return NSAppearance(named: .aqua)
          default:
              return nil
          }
      }
      set {
          let rawValue: String?
          switch newValue {
          case NSAppearance(named: .darkAqua):
              rawValue = "dark"
          case NSAppearance(named: .aqua):
              rawValue = "light"
          default:
              rawValue = nil
          }
          UserDefaults.standard.set(rawValue, forKey: manualAppearanceKey)
      }
  }
  ```
- **Testing**: Verify preferences persist across app restarts
- **Acceptance Criteria**: Settings saved and loaded correctly

### 6.3 Phase 3: Implement Auto-Switch Control (Priority: Medium, Estimated: 1-2 days)

#### Task 3.1: Add UI Control to GeneralTabView
- **File**: `Sources/Views/GeneralTabView.swift`
- **Description**: Add ON/OFF switch for auto-switch appearance
- **Implementation**:
  ```swift
  // Add property
  private var autoSwitchButton: NSSwitch!
  
  // In setupView()
  let autoSwitchLabel = NSTextField(frame: NSRect(x: 20, y: yPosition, width: 200, height: 20))
  autoSwitchLabel.stringValue = "Auto-switch appearance"
  autoSwitchLabel.isBezeled = false
  autoSwitchLabel.drawsBackground = false
  autoSwitchLabel.isEditable = false
  autoSwitchLabel.isSelectable = false
  addSubview(autoSwitchLabel)
  
  autoSwitchButton = NSSwitch(frame: NSRect(x: 230, y: yPosition, width: 50, height: 20))
  autoSwitchButton.state = SystemConfigService.shared.autoSwitchAppearance ? .on : .off
  autoSwitchButton.target = self
  autoSwitchButton.action = #selector(autoSwitchChanged(_:))
  addSubview(autoSwitchButton)
  
  let descriptionLabel = NSTextField(frame: NSRect(x: 20, y: yPosition - 20, width: 400, height: 20))
  descriptionLabel.stringValue = "Automatically switch between light and dark mode based on system settings"
  descriptionLabel.isBezeled = false
  descriptionLabel.drawsBackground = false
  descriptionLabel.isEditable = false
  descriptionLabel.isSelectable = false
  descriptionLabel.textColor = .secondaryLabelColor
  descriptionLabel.font = NSFont.systemFont(ofSize: 11)
  addSubview(descriptionLabel)
  
  @objc func autoSwitchChanged(_ sender: NSSwitch) {
      SystemConfigService.shared.autoSwitchAppearance = sender.state == .on
  }
  ```
- **Testing**: Verify switch toggles and saves preference
- **Acceptance Criteria**: Switch works and persists setting

#### Task 3.2: Add Manual Appearance Selector
- **File**: `Sources/Views/GeneralTabView.swift`
- **Description**: Add dropdown for manual appearance selection (shown when auto-switch is OFF)
- **Implementation**:
  ```swift
  private var appearanceSelector: NSPopUpButton!
  
  // In setupView()
  appearanceSelector = NSPopUpButton(frame: NSRect(x: 230, y: yPosition, width: 150, height: 25))
  appearanceSelector.addItem(withTitle: "Light")
  appearanceSelector.addItem(withTitle: "Dark")
  appearanceSelector.selectItem(at: SystemConfigService.shared.manualAppearance == .darkAqua ? 1 : 0)
  appearanceSelector.target = self
  appearanceSelector.action = #selector(appearanceSelected(_:))
  appearanceSelector.isEnabled = !SystemConfigService.shared.autoSwitchAppearance
  addSubview(appearanceSelector)
  
  @objc func appearanceSelected(_ sender: NSPopUpButton) {
      let appearance: NSAppearance.Appearance? = sender.indexOfSelectedItem == 1 ? .darkAqua : .aqua
      SystemConfigService.shared.manualAppearance = appearance
      
      // Apply appearance to all windows
      NSApplication.shared.windows.forEach { window in
          window.appearance = appearance
      }
  }
  
  // Update autoSwitchChanged to enable/disable selector
  @objc func autoSwitchChanged(_ sender: NSSwitch) {
      SystemConfigService.shared.autoSwitchAppearance = sender.state == .on
      appearanceSelector.isEnabled = sender.state == .off
      
      if sender.state == .on {
          // Reset to system appearance
          NSApplication.shared.windows.forEach { window in
              window.appearance = nil
          }
      } else {
          // Apply manual appearance
          appearanceSelected(appearanceSelector)
      }
  }
  ```
- **Testing**: Verify manual selection works and persists
- **Acceptance Criteria**: Manual appearance selection works correctly

### 6.4 Phase 4: Update Assets (Priority: Low, Estimated: 1 day)

#### Task 4.1: Implement Logo Loading Logic
- **File**: All files using logo images
- **Description**: Add logic to load appropriate logo based on current appearance mode
- **Current Assets**:
  - Light mode logo: `Resources/Assets/logo.png`
  - Dark mode logo: `Resources/Assets/logo_dark.png` (already created)
- **Implementation**:
  ```swift
  // Helper function to get appropriate logo
  func getLogo() -> NSImage? {
      let isDarkMode = NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
      let logoName = isDarkMode ? "logo_dark" : "logo"
      
      // Try loading from Assets directory
      let logoPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/\(logoName).png"
      return NSImage(contentsOfFile: logoPath)
  }
  
  // Usage
  if let logo = getLogo() {
      logoImageView.image = logo
  }
  ```
- **Testing**: Verify correct logo loads in both light and dark modes
- **Acceptance Criteria**: Logo switches automatically when appearance changes

#### Task 4.2: Create Asset Catalog (Optional Enhancement)
- **File**: `Resources/Assets.xcassets` (new)
- **Description**: Create asset catalog for better asset management (optional)
- **Implementation**:
  - Create asset catalog in Xcode
  - Add logo images with light and dark variants in single image set
  - Add custom icons with light and dark variants
- **Benefits**: 
  - Automatic appearance-based loading
  - Better organization
  - Easier maintenance
- **Testing**: Verify assets load correctly in both modes
- **Acceptance Criteria**: Assets display correctly in both modes

#### Task 4.3: Update Logo Usage in All Files
- **Files**: All files using logo images
- **Changes**: Replace direct file paths with dynamic logo loading
- **Implementation**:
  ```swift
  // Replace
  let logo = NSImage(contentsOfFile: "path/to/logo.png")
  
  // With
  let logo = getLogo() // Using helper function from Task 4.1
  
  // Or if using asset catalog (Task 4.2)
  let logo = NSImage(named: "logo") // Automatically selects correct variant
  ```
- **Testing**: Verify logo displays correctly in both modes
- **Acceptance Criteria**: Logo adapts to current mode

### 6.5 Phase 5: Testing and Refinement (Priority: High, Estimated: 2 days)

#### Task 5.1: Manual Testing Checklist
- [ ] Test all windows in light mode
- [ ] Test all windows in dark mode
- [ ] Test auto-switch toggle
- [ ] Test manual appearance selection
- [ ] Test appearance persistence across restarts
- [ ] Test all text fields for visibility
- [ ] Test all buttons for proper appearance
- [ ] Test all icons and images
- [ ] Test transitions between modes
- [ ] Test with VoiceOver enabled
- [ ] Test with high contrast mode
- [ ] Test with reduce motion enabled

#### Task 5.2: Accessibility Testing
- **Contrast Testing**: Use contrast checker tool
- **VoiceOver Testing**: Test with VoiceOver enabled
- **Color Blindness**: Test with color blindness simulation
- **Acceptance Criteria**: All accessibility requirements met

#### Task 5.3: Performance Testing
- **Memory Usage**: Monitor memory during mode switches
- **CPU Usage**: Monitor CPU during transitions
- **Animation Smoothness**: Ensure smooth transitions
- **Acceptance Criteria**: No performance degradation

#### Task 5.4: Bug Fixes and Refinement
- Fix any issues found during testing
- Optimize performance if needed
- Refine UI elements for better appearance
- **Acceptance Criteria**: All tests pass, no critical bugs

### 6.6 Documentation and Training

#### Task 6.1: Update Developer Documentation
- Document new ColorService usage
- Document appearance management approach
- Add code examples for dynamic colors
- Update coding guidelines

#### Task 6.2: Create User Guide
- Document auto-switch feature
- Document manual appearance selection
- Add screenshots for both modes
- Add troubleshooting section

### 6.7 Rollout Plan

#### Stage 1: Internal Testing (1 week)
- Deploy to development team
- Collect feedback and bug reports
- Fix critical issues

#### Stage 2: Beta Testing (1 week)
- Deploy to beta testers
- Collect user feedback
- Fix remaining issues

#### Stage 3: Production Release
- Deploy to all users
- Monitor for issues
- Provide support for users

### 6.8 Success Metrics
- **User Satisfaction**: Positive feedback on appearance adaptation
- **Bug Reports**: No critical bugs related to appearance
- **Performance**: No measurable performance impact
- **Accessibility**: All accessibility tests pass
- **Adoption**: High usage of auto-switch feature

## 7. Language Switching Design (i18n)

### 7.1 Overview

The General tab in Preferences window provides a dropdown list for users to switch between supported languages. This section describes the implementation design for runtime language switching based on the existing i18n infrastructure.

### 7.2 Current Implementation Status

#### Existing Components
- **LocalizationService.swift**: Loads localized strings from `.lproj/Localizable.strings` files
- **Localization Files**: 
  - `Resources/en.lproj/Localizable.strings` (English)
  - `Resources/zh-Hans.lproj/Localizable.strings` (Chinese Simplified)
- **GeneralTabView.swift**: Contains language dropdown UI (partially implemented)
- **All UI Files**: Already use `LocalizationService.shared.localizedString(for: "key")` for i18n

#### Current Limitations
- Language is determined by system preference at app launch
- No runtime language switching support
- User language preference is not persisted
- UI does not refresh when language changes

### 7.3 Design Requirements

#### Functional Requirements
1. User can select language from dropdown in General tab
2. Language preference is persisted across app restarts
3. All UI text updates immediately when language changes
4. Supported languages: English (en), Chinese Simplified (zh-Hans)

#### Non-Functional Requirements
1. Language switch should be instantaneous (< 100ms)
2. No app restart required
3. All windows and views should update consistently
4. Memory efficient (no duplicate string loading)

### 7.4 Technical Design

#### 7.4.1 Data Model

**Language Enumeration**
```swift
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chineseSimplified = "zh-Hans"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        }
    }
    
    var lprojName: String {
        switch self {
        case .english: return "en.lproj"
        case .chineseSimplified: return "zh-Hans.lproj"
        }
    }
}
```

**User Preferences Storage**
- Storage: `UserDefaults`
- Key: `pen.userLanguage`
- Value: Language raw value (e.g., "en", "zh-Hans")
- Default: System preferred language or English

#### 7.4.2 LocalizationService Enhancement

**New Properties and Methods**
```swift
class LocalizationService {
    static let shared = LocalizationService()
    private var strings: [String: String] = [:]
    private var currentLanguage: AppLanguage = .english
    
    // Notification name for language change
    static let languageDidChangeNotification = Notification.Name("LanguageDidChangeNotification")
    
    // Current language property
    var language: AppLanguage {
        return currentLanguage
    }
    
    // Initialize with saved preference or system language
    private init() {
        loadSavedLanguagePreference()
        loadStrings()
    }
    
    // Load saved language from UserDefaults
    private func loadSavedLanguagePreference() {
        if let savedCode = UserDefaults.standard.string(forKey: "pen.userLanguage"),
           let language = AppLanguage(rawValue: savedCode) {
            currentLanguage = language
        } else {
            // Fallback to system preference
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.hasPrefix("zh") {
                currentLanguage = .chineseSimplified
            } else {
                currentLanguage = .english
            }
        }
    }
    
    // Switch to a new language
    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        
        currentLanguage = language
        
        // Save preference
        UserDefaults.standard.set(language.rawValue, forKey: "pen.userLanguage")
        
        // Reload strings
        reloadStrings()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: nil)
    }
    
    // Modified loadStrings to use currentLanguage
    private func loadStrings() {
        let lprojName = currentLanguage.lprojName
        
        let possiblePaths = [
            // Development path
            "\(FileManager.default.currentDirectoryPath)/Resources/\(lprojName)/Localizable.strings",
            // Build path
            Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: lprojName),
            // Alternative build path
            Bundle.main.path(forResource: "Localizable", ofType: "strings")
        ]
        
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                if let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                    strings = dict
                    return
                }
            }
        }
        
        print("LocalizationService: Failed to load Localizable.strings for \(lprojName)")
    }
}
```

#### 7.4.3 UI Update Mechanism

**Notification-Based Updates**

Each view that displays localized text should observe the language change notification:

```swift
// In view initialization
NotificationCenter.default.addObserver(
    self,
    selector: #selector(languageDidChange),
    name: LocalizationService.languageDidChangeNotification,
    object: nil
)

// Handler method
@objc private func languageDidChange() {
    // Update all localized UI elements
    titleLabel.stringValue = LocalizationService.shared.localizedString(for: "title_key")
    button.title = LocalizationService.shared.localizedString(for: "button_key")
    // ... update other UI elements
}

// Clean up in deinit
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

**BaseWindow Enhancement**

Add a common method in `BaseWindow` to handle language changes:

```swift
class BaseWindow: NSWindow {
    // ... existing code ...
    
    func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: LocalizationService.languageDidChangeNotification,
            object: nil
        )
    }
    
    @objc func languageDidChange() {
        // Override in subclasses to update UI
    }
}
```

#### 7.4.4 GeneralTabView Implementation

**Language Dropdown Handler**
```swift
@objc private func languageSelected(_ sender: NSPopUpButton) {
    let selectedIndex = sender.indexOfSelectedItem
    
    let selectedLanguage: AppLanguage
    switch selectedIndex {
    case 0:
        selectedLanguage = .english
    case 1:
        selectedLanguage = .chineseSimplified
    default:
        selectedLanguage = .english
    }
    
    // Update localization service
    LocalizationService.shared.setLanguage(selectedLanguage)
    
    // Update dropdown items with new language
    updateLanguageDropdownItems()
    
    // Show confirmation message
    if let parentWindow = self.parentWindow as? BaseWindow {
        parentWindow.displayPopupMessage(
            LocalizationService.shared.localizedString(for: "language_changed_successfully")
        )
    }
}

private func updateLanguageDropdownItems() {
    languagePopup.removeAllItems()
    languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "english_language"))
    languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "chinese_language"))
    languagePopup.selectItem(at: LocalizationService.shared.language == .english ? 0 : 1)
}
```

**Initialization with Saved Preference**
```swift
private func setupLanguageSection(_ section: NSView) {
    // ... existing UI setup code ...
    
    // Set initial selection based on current language
    languagePopup.selectItem(at: LocalizationService.shared.language == .english ? 0 : 1)
}
```

### 7.5 Implementation Plan

#### Phase 1: Core Infrastructure (1 day)
1. Create `AppLanguage` enum
2. Enhance `LocalizationService` with language switching
3. Add UserDefaults persistence
4. Add notification system

#### Phase 2: UI Updates (2 days)
1. Update `BaseWindow` with language observer
2. Update all view files to observe language changes:
   - `LoginWindow.swift`
   - `RegistrationWindow.swift`
   - `AccountTabView.swift`
   - `PreferencesWindow.swift`
   - `GeneralTabView.swift`
   - `PromptsTabView.swift`
   - `HistoryTabView.swift`
   - `AIConfigurationTabView.swift`
   - `ForgotPasswordWindow.swift`
   - `MainMenu.swift`
3. Implement `languageDidChange()` in each view

#### Phase 3: General Tab Integration (0.5 day)
1. Implement language dropdown handler
2. Add success message localization
3. Test language switching

#### Phase 4: Testing (1 day)
1. Test all views update correctly
2. Test persistence across app restarts
3. Test edge cases (no internet, corrupted preferences)
4. Test with both languages

### 7.6 Files to Modify

| File | Changes |
|------|---------|
| `LocalizationService.swift` | Add language switching support |
| `GeneralTabView.swift` | Implement dropdown handler |
| `BaseWindow.swift` | Add language change observer |
| `LoginWindow.swift` | Add `languageDidChange()` handler |
| `RegistrationWindow.swift` | Add `languageDidChange()` handler |
| `AccountTabView.swift` | Add `languageDidChange()` handler |
| `PreferencesWindow.swift` | Add `languageDidChange()` handler |
| `PromptsTabView.swift` | Add `languageDidChange()` handler |
| `HistoryTabView.swift` | Add `languageDidChange()` handler |
| `AIConfigurationTabView.swift` | Add `languageDidChange()` handler |
| `ForgotPasswordWindow.swift` | Add `languageDidChange()` handler |
| `MainMenu.swift` | Add `languageDidChange()` handler |
| `en.lproj/Localizable.strings` | Add `language_changed_successfully` |
| `zh-Hans.lproj/Localizable.strings` | Add `language_changed_successfully` |

### 7.7 New Localization Keys

**English (en.lproj/Localizable.strings)**
```
"language_changed_successfully" = "Language changed successfully. The interface has been updated.";
```

**Chinese (zh-Hans.lproj/Localizable.strings)**
```
"language_changed_successfully" = "语言已更改。界面已更新。";
```

### 7.8 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Selects Language                        │
│                    (GeneralTabView Dropdown)                     │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              GeneralTabView.languageSelected()                   │
│                           ↓                                      │
│         LocalizationService.shared.setLanguage()                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────────┐
│ Save to         │ │ Reload      │ │ Post            │
│ UserDefaults    │ │ Strings     │ │ Notification    │
└─────────────────┘ └─────────────┘ └────────┬────────┘
                                               │
                          ┌────────────────────┼────────────────────┐
                          ▼                    ▼                    ▼
                   ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
                   │ LoginWindow │      │ AccountTab  │      │ All Other   │
                   │             │      │ View        │      │ Views       │
                   └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
                          │                    │                    │
                          ▼                    ▼                    ▼
                   ┌─────────────────────────────────────────────────────┐
                   │          Update All Localized UI Elements           │
                   │   (labels, buttons, tooltips, placeholders, etc.)   │
                   └─────────────────────────────────────────────────────┘
```

### 7.9 Best Practices

1. **Always use LocalizationService**: Never hardcode UI strings
2. **Observe notifications**: All views with text should observe language changes
3. **Clean up observers**: Remove observers in `deinit` to prevent memory leaks
4. **Test both languages**: Verify all UI elements in both English and Chinese
5. **Handle missing keys**: Provide fallback keys for missing translations
6. **Keep keys organized**: Use consistent naming conventions for localization keys

### 7.10 Future Enhancements

1. **More Languages**: Add support for additional languages (Japanese, Korean, etc.)
2. **Language Pack Downloads**: Allow users to download additional language packs
3. **Custom Translations**: Allow users to customize translations
4. **Pluralization Support**: Add proper plural form handling
5. **RTL Support**: Add right-to-left language support for Arabic, Hebrew, etc.

## 8. Other Details

### 6.1 Accessibility Considerations
- **Contrast Ratios**: Ensure minimum 4.5:1 contrast for text
- **VoiceOver**: Test with VoiceOver in both modes
- **Reduce Motion**: Support reduce motion preferences during transitions

### 6.2 Localization
- **Strings**: Ensure all UI elements are properly localized
- **Layout**: Allow for text expansion in different languages

### 6.3 Future Enhancements
- **Themes**: Support for custom themes beyond light/dark
- **Schedule**: Allow users to schedule appearance changes
- **Per-App Settings**: Allow different appearance settings for different app windows

### 6.4 Compatibility
- **macOS Version**: Requires macOS 10.14+ for full dark mode support
- **Backward Compatibility**: Gracefully degrade on older macOS versions

## 7. Conclusion

Implementing light and dark mode support in the Pen app will significantly improve the user experience by providing a consistent, accessible, and visually appealing interface in all lighting conditions. By following macOS design guidelines and leveraging system APIs, we can create a seamless experience that adapts to the user's environment while giving them control over their appearance preferences.

The changes outlined in this design will resolve the current issue of invisible text in dark mode and provide a foundation for future UI enhancements.