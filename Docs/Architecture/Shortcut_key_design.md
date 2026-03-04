# Shortcut Key Architecture Design

## Overview

This document outlines the architecture design for implementing customizable shortcut key functionality in the Pen application. The design is based on the technical requirements specified in General.md and the recommended solution from diagnose.txt.

## Technical Requirements

The application should:
- Use macOS accessibility APIs for global keyboard monitoring
- Store shortcut key combinations in application preferences
- Handle permission requests gracefully
- Provide clear feedback during the recording process
- Check for conflicts with both system and application-level shortcuts

## Recommended Solution

Based on the diagnose.txt file, the recommended solution is to use the **KeyboardShortcuts** library by Sindre Sorhus. This library provides a production-ready implementation that:

- Offers a native shortcut recorder UI
- Works when the app is backgrounded
- Handles shortcut conflicts
- Provides a clean Swift API

## Architecture Design

### 1. Project Structure

```
mac-app/Pen/
├── Sources/
│   ├── Services/
│   │   └── ShortcutService.swift   # Shortcut management service
│   ├── Views/
│   │   └── GeneralTabView.swift     # Contains shortcut recorder UI
│   └── App/
│       └── PenAI.swift             # App delegate with shortcut listener
└── Package.swift                   # Add KeyboardShortcuts dependency
```

### 2. Key Components

#### 2.1 ShortcutService

A centralized service to manage shortcut key functionality:

- **Responsibilities:**
  - Define shortcut names
  - Handle shortcut registration
  - Store and retrieve shortcuts from preferences
  - Provide methods for shortcut management

- **Key Methods:**
  - `registerShortcut()` - Registers the shortcut with the system
  - `unregisterShortcut()` - Unregisters the shortcut
  - `getCurrentShortcut()` - Returns the current shortcut
  - `setShortcut()` - Updates the shortcut

#### 2.2 GeneralTabView

The UI component for shortcut configuration:

- **Responsibilities:**
  - Display shortcut recorder UI
  - Handle user input for shortcut recording
  - Provide visual feedback during recording
  - Display conflict warnings

#### 2.3 PenAI (App Delegate)

The application entry point:

- **Responsibilities:**
  - Initialize shortcut service
  - Set up shortcut listeners
  - Handle shortcut activation events
  - Toggle window visibility

### 3. Implementation Details

#### 3.1 Adding the KeyboardShortcuts Dependency

Add the following to Package.swift:

```swift
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.0.0")
```

#### 3.2 Defining Shortcut Names

Create a shortcut definition file:

```swift
// Sources/Services/ShortcutDefinitions.swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePen = Self("togglePen", default: .init(.command, .option, "P"))
}
```

#### 3.3 ShortcutService Implementation

```swift
// Sources/Services/ShortcutService.swift
import Foundation
import KeyboardShortcuts

class ShortcutService {
    static let shared = ShortcutService()
    
    private init() {
        setupShortcutListener()
    }
    
    func setupShortcutListener() {
        KeyboardShortcuts.onKeyUp(for: .togglePen) { [weak self] in
            self?.togglePenWindow()
        }
    }
    
    func togglePenWindow() {
        // Get the application delegate
        guard let appDelegate = NSApplication.shared.delegate as? PenAIDelegate else {
            return
        }
        
        // Toggle the main window
        appDelegate.toggleMainWindow()
    }
    
    func getCurrentShortcut() -> KeyboardShortcuts.Shortcut? {
        return KeyboardShortcuts.getShortcut(for: .togglePen)
    }
    
    func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut) {
        KeyboardShortcuts.setShortcut(shortcut, for: .togglePen)
    }
}
```

#### 3.4 Updating GeneralTabView

Integrate the shortcut recorder into the GeneralTabView:

```swift
// In GeneralTabView.swift
import KeyboardShortcuts

// Add to setupShortcutKeySection
let shortcutRecorder = KeyboardShortcuts.Recorder(
    "", // No label needed as we have section title
    name: .togglePen
)

// Add the recorder to the view hierarchy
let recorderView = NSHostingView(rootView: shortcutRecorder)
recorderView.frame = NSRect(x: 20, y: sectionHeight - 80, width: 300, height: 40)
section.addSubview(recorderView)
```

#### 3.5 Updating PenAI App Delegate

Add window toggling functionality:

```swift
// In PenAI.swift
func toggleMainWindow() {
    // Implement window toggling logic
    if let window = self.window {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            positionWindowRelativeToMenuBarIcon(window)
            window.makeKeyAndOrderFront(nil)
        }
    }
}
```

### 4. User Flow

1. **User opens Preferences > General tab**
2. **User clicks on the shortcut recorder**
3. **User presses a key combination**
4. **System checks for conflicts**
5. **Shortcut is saved to preferences**
6. **User presses the shortcut anywhere in macOS**
7. **Pen window toggles visibility**

### 5. Permission Handling

The KeyboardShortcuts library automatically handles accessibility permission requests:

- When the user first tries to set a shortcut, the system will prompt for accessibility permissions
- The library provides methods to check if permissions are granted
- The UI should display clear instructions if permissions are not granted

### 6. Conflict Detection

The KeyboardShortcuts library automatically handles conflict detection:

- It checks for conflicts with system shortcuts
- It checks for conflicts with other application shortcuts
- It provides visual feedback when a conflict is detected
- It allows the user to override conflicts if desired

### 7. Alternative Implementation (No Dependency)

If using a third-party library is not preferred, a native implementation using Carbon's `RegisterEventHotKey` API can be used. However, this requires:

- Manual keycode handling
- Building a custom shortcut recorder UI
- Implementing conflict detection
- Managing accessibility permissions

### 8. Performance Considerations

- The KeyboardShortcuts library is designed to be lightweight
- Shortcut registration is done once at app startup
- The library uses efficient event handling
- No significant performance impact is expected

### 9. Testing Strategy

- **Unit tests** for ShortcutService methods
- **UI tests** for shortcut recorder functionality
- **Integration tests** for end-to-end shortcut functionality
- **Manual testing** with various shortcut combinations

### 10. Future Enhancements

- Support for multiple shortcuts
- Shortcut presets
- Import/export of shortcut configurations
- Keyboard layout awareness
