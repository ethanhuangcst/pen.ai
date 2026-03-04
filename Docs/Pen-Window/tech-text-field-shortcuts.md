# Text Field System Shortcuts

This document describes the solution for enabling system shortcuts (Command+C, V, A, X, Z, etc.) in text fields for macOS menu bar applications.

## Problem Statement

System shortcuts (Command+C, Command+V, Command+A, Command+X, Command+Z, etc.) were not working in text fields throughout the application.

### Symptoms
- Typing works normally
- System shortcuts are completely ignored
- No response to standard editing shortcuts

## Root Cause Analysis

### Why This Happens

System shortcuts in macOS are **not** handled directly by `NSTextField` or `NSTextView` components. Instead, they are managed through the AppKit responder chain via:
- The **Edit menu** in the main menu bar
- **NSMenuItem key equivalents**

### The Problem with Menu Bar Apps

Pen is a menu bar app with the following characteristics:
1. Launched from an `NSStatusItem`
2. No standard main menu installed
3. No Edit menu exists
4. No menu items with standard selectors

Without a main menu containing the Edit menu, AppKit has nowhere to route shortcut commands.

**This is expected macOS behavior**, not a bug in the application.

### Diagnosis Checklist

If ALL of these are true, shortcuts will fail:
- [ ] App is launched from NSStatusItem
- [ ] No main menu is installed
- [ ] No Edit menu exists
- [ ] No menu items with standard selectors exist

## Solution

### The Correct Fix (Apple-Approved Method)

The only correct solution is to **install a minimal main menu with standard Edit actions**.

### Implementation

#### Step 1: Create MainMenu.swift

```swift
import AppKit

func installMainMenu() {
    let mainMenu = NSMenu()  
    
    // App Menu (required for macOS)
    let appMenuItem = NSMenuItem()  
    let appMenu = NSMenu()  
    
    appMenu.addItem(  
        withTitle: "Quit",  
        action: #selector(NSApplication.terminate(_:)),  
        keyEquivalent: "q"  
    )  
    
    appMenuItem.submenu = appMenu  
    mainMenu.addItem(appMenuItem)  
    
    // Edit Menu (required for shortcuts)
    let editMenuItem = NSMenuItem()  
    let editMenu = NSMenu(title: "Edit")  
    
    editMenu.addItem(  
        withTitle: "Undo",  
        action: Selector(("undo:")),  
        keyEquivalent: "z"  
    )  
    
    editMenu.addItem(  
        withTitle: "Redo",  
        action: Selector(("redo:")),  
        keyEquivalent: "Z"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: "Cut",  
        action: #selector(NSText.cut(_:)),  
        keyEquivalent: "x"  
    )  
    
    editMenu.addItem(  
        withTitle: "Copy",  
        action: #selector(NSText.copy(_:)),  
        keyEquivalent: "c"  
    )  
    
    editMenu.addItem(  
        withTitle: "Paste",  
        action: #selector(NSText.paste(_:)),  
        keyEquivalent: "v"  
    )  
    
    editMenu.addItem(  
        withTitle: "Select All",  
        action: #selector(NSText.selectAll(_:)),  
        keyEquivalent: "a"  
    )  
    
    editMenuItem.submenu = editMenu  
    mainMenu.addItem(editMenuItem)  
    
    // Set the menu as the application's main menu
    NSApp.mainMenu = mainMenu  
}
```

#### Step 2: Install the Menu at App Launch

In `Pen.swift` (AppDelegate):

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // Setup menu bar icon first
    setupMenuBarIcon()
    
    // Install main menu for system shortcut support
    installMainMenu()
    
    // Perform initialization and other setup
    performInitialization()
    createMainWindow()
    setupShortcutKey()
}
```

**Important**: Install the menu AFTER `NSApp.setActivationPolicy(.regular)` and BEFORE showing any windows.

#### Step 3: Remove Conflicting Code

Remove any custom key handling that might intercept shortcuts:
- `NSEvent.addLocalMonitorForEvents` returning `nil`
- `override keyDown` without calling `super.keyDown(with: event)`
- `override performKeyEquivalent` returning `true`

These will swallow shortcuts and prevent them from reaching the menu system.

#### Step 4: Verify Text Field Configuration

Ensure text fields are properly configured:

```swift
textField.isEditable = true
textField.isSelectable = true
// Do NOT disable field editor
```

## Expected Results After Fix

### Basic Editing Shortcuts
| Shortcut | Action |
|----------|--------|
| Command+C | Copy |
| Command+V | Paste |
| Command+A | Select All |
| Command+X | Cut |
| Command+Z | Undo |
| Shift+Command+Z | Redo |

### Text Navigation Shortcuts
| Shortcut | Action |
|----------|--------|
| Shift+Command+Left Arrow | Select to beginning of line |
| Shift+Command+Right Arrow | Select to end of line |
| Shift+Command+Up Arrow | Select to beginning of document |
| Shift+Command+Down Arrow | Select to end of document |
| Option+Left Arrow | Move to beginning of word |
| Option+Right Arrow | Move to end of word |
| Option+Up Arrow | Move to beginning of paragraph |
| Option+Down Arrow | Move to end of paragraph |

### All Native macOS Text Behaviors
- ✅ All standard macOS text editing behaviors are restored
- ✅ Consistent shortcut behavior across all text fields
- ✅ Familiar user experience for macOS users

## Why This Is the Only Correct Solution

macOS shortcuts are **menu-driven** by design. The operating system expects to route shortcut commands through menu items with specific selectors. Without a menu system in place, there's no mechanism for AppKit to handle these shortcuts.

This is not a bug in the application, but rather a fundamental aspect of macOS architecture.

## Troubleshooting

### If Shortcuts Still Don't Work

1. **Check menu installation**: Ensure `installMainMenu()` is called
2. **Verify menu structure**: Confirm the Edit menu contains all required items
3. **Check for conflicts**: Look for any custom key handling that might be intercepting shortcuts
4. **Test with a simple text field**: Create a test window with a basic NSTextField to isolate the issue
5. **Check application activation**: Ensure the app is properly activated with `NSApp.setActivationPolicy(.regular)`

### Common Pitfalls

- **Forgetting to call `installMainMenu()`**: The menu won't exist if not explicitly installed
- **Installing menu too late**: Menu must be present before windows are shown
- **Custom key handling**: Any custom key event handling can break the menu-based shortcut system
- **Incorrect text field configuration**: Text fields must be editable and selectable

## Best Practices

1. **Install the menu early**: Install the main menu as early as possible in the application lifecycle
2. **Keep it minimal**: The menu only needs the essential Edit actions for shortcuts to work
3. **Avoid custom key handling**: Let the menu system handle standard shortcuts
4. **Test thoroughly**: Verify all standard shortcuts work across different text fields
5. **Document the solution**: Include this documentation in the codebase for future reference
