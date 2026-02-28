import Cocoa
import Carbon

class PenAIDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private var window: NSWindow?
    private var loginWindow: LoginWindow?
    private var preferencesWindow: PreferencesWindow?
    private let windowWidth: CGFloat = 518
    private let windowHeight: CGFloat = 600
    private let mouseOffset: CGFloat = 6
    private var isOnline: Bool = false
    private var internetFailure: Bool = false
    private var databaseFailure: Bool = false
    private var isLoggedIn: Bool = false
    private var userName: String = ""
    var currentUser: User? = nil
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("SimpleAppDelegate: Application launched")
        
        // Setup menu bar icon first so it's available for login window positioning
        setupMenuBarIcon()
        
        // Perform 3-step initialization process
        performInitialization()
        
        // Create a simple window
        createHelloWorldWindow()
        
        // Setup shortcut key functionality
        setupShortcutKey()
    }
    
    @objc private func performInitialization() {
        let initializationService = InitializationService(delegate: self)
        initializationService.performInitialization()
    }
    
    func setOnlineMode(_ online: Bool, failureType: String? = nil, internetFailure: Bool = false) {
        isOnline = online
        
        if online {
            print("PenAIDelegate: Setting online mode")
            self.internetFailure = false
            databaseFailure = false
        } else {
            print("PenAIDelegate: Setting offline mode")
            if failureType == "internet" {
                self.internetFailure = internetFailure
                print("PenAIDelegate: Setting 'Internet Failure' flag to \(internetFailure)")
            } else if failureType == "database" {
                databaseFailure = true
                print("PenAIDelegate: Setting 'Database Failure' flag to true")
            }
        }
        
        // Only update status icon if statusItem is initialized
        updateStatusIcon(online: online)
        
        // Wait until menu bar icon is fully loaded before displaying popup messages
        if !online {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                if let self = self {
                    if failureType == "internet" && internetFailure {
                        // Display internet failure message
                        self.displayPopupMessage(LocalizationService.shared.localizedString(for: "internet_failure"))
                    } else if failureType == "database" {
                        // Display database failure message
                        self.displayPopupMessage(LocalizationService.shared.localizedString(for: "database_failure"))
                    }
                }
            }
        }
    }
    

    
    func updateStatusIcon(online: Bool) {
        guard let button = statusItem?.button else { return }
        
        let iconName = online ? "icon.png" : "icon_offline.png"
        
        print("PenAIDelegate: Using icon: \(iconName)")
        
        // Get the current directory path
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        
        // Construct the full path to the icon
        let iconPath = "\(currentDirectory)/Resources/Assets/\(iconName)"
        
        print("PenAIDelegate: Icon path: \(iconPath)")
        
        if let icon = NSImage(contentsOfFile: iconPath) {
            print("PenAIDelegate: Loaded icon from path: \(iconPath)")
            // Resize icon to appropriate menu bar size (22x22 pixels)
            let desiredSize = NSSize(width: 22, height: 22)
            let resizedIcon = NSImage(size: desiredSize)
            
            resizedIcon.lockFocus()
            icon.draw(in: NSRect(origin: .zero, size: desiredSize), from: NSRect(origin: .zero, size: icon.size), operation: .sourceOver, fraction: 1.0)
            resizedIcon.unlockFocus()
            
            // Set isTemplate to true for automatic dark/light mode adaptation
            resizedIcon.isTemplate = true
            
            // Set the resized icon
            button.image = resizedIcon
            
            // Set tooltip based on app mode
            var tooltip: String
            if online {
                if isLoggedIn {
                    tooltip = LocalizationService.shared.localizedString(for: "hello_user", withFormat: userName)
                } else {
                    tooltip = LocalizationService.shared.localizedString(for: "hello_guest")
                }
            } else {
                if internetFailure {
                    tooltip = LocalizationService.shared.localizedString(for: "internet_failure")
                } else if databaseFailure {
                    tooltip = LocalizationService.shared.localizedString(for: "database_failure")
                } else {
                    tooltip = LocalizationService.shared.localizedString(for: "pen_ai_offline")
                }
            }
            
            button.toolTip = tooltip
            print("PenAIDelegate: Icon updated successfully with template mode enabled")
        } else {
            print("PenAIDelegate: Error: Could not load icon from path: \(iconPath)")
            // Fallback: set a simple text in the menu bar
            button.title = online ? "Pen" : "Pen (Offline)"
            button.toolTip = online ? LocalizationService.shared.localizedString(for: "pen_ai") : LocalizationService.shared.localizedString(for: "pen_ai_offline")
        }
    }
    
    private func checkAccessibilityPermissions() {
        print("SimpleAppDelegate: Checking accessibility permissions...")
        
        // Check if accessibility is enabled
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        if isTrusted {
            print("SimpleAppDelegate: Accessibility permissions are enabled")
        } else {
            print("SimpleAppDelegate: Accessibility permissions are not enabled")
            print("SimpleAppDelegate: Please enable accessibility permissions in System Preferences")
            print("SimpleAppDelegate: System Preferences > Security & Privacy > Privacy > Accessibility")
        }
    }
    
    private func createHelloWorldWindow() {
        print("SimpleAppDelegate: Creating hello world window")
        
        // Calculate window position based on mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        
        // Get the screen that contains the mouse cursor
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else {
            print("PenAIDelegate: Error: Could not get screen for mouse location")
            return
        }
        let fullScreenFrame = screen.frame
        
        // Calculate window position: mouse cursor + offset
        // Note: NSEvent.mouseLocation returns coordinates in global screen space with origin at bottom-left
        let windowX = mouseLocation.x + mouseOffset
        let windowY = mouseLocation.y - mouseOffset - windowHeight
        
        let windowRect = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        
        // Create window with transparent background and rounded corners
        window = NSWindow(contentRect: windowRect, styleMask: [.borderless], backing: .buffered, defer: false)
        window?.title = "Pen AI"
        window?.isMovable = true
        window?.isMovableByWindowBackground = true
        
        // Set window to be transparent for rounded corners
        window?.isOpaque = false
        window?.backgroundColor = .clear
        
        // Set window level to be in front of all other windows
        window?.level = .floating
        
        // New requirement: Window should be displayed in all Mac desktops
        window?.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient
        ]
        
        // Create content view with rounded corners and shadow
        let contentView = NSView(frame: NSRect(origin: .zero, size: windowRect.size))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.white.cgColor
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
        
        // Create shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -3)
        shadow.shadowBlurRadius = 8
        
        // Apply shadow to window
        window?.contentView = contentView
        window?.hasShadow = true
        
        // Create close button
        let closeButton = NSButton(frame: NSRect(x: windowWidth - 30, y: windowHeight - 30, width: 20, height: 20))
        closeButton.title = ""
        closeButton.bezelStyle = .smallSquare
        closeButton.isBordered = false
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        contentView.addSubview(closeButton)
        
        // Create label
        let label = NSTextField(frame: NSRect(x: 50, y: windowHeight - 100, width: windowWidth - 100, height: 60))
        label.stringValue = "Hello World!"
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 24)
        
        // Add label to content view
        contentView.addSubview(label)
        
        // Don't show window automatically on app launch
        // window?.makeKeyAndOrderFront(nil)
        
        print("PenAIDelegate: Hello world window created but not shown")
        print("PenAIDelegate: Window size: \(windowWidth)x\(windowHeight)")
        print("PenAIDelegate: Mouse cursor position: x=\(mouseLocation.x), y=\(mouseLocation.y)")
        print("PenAIDelegate: Window position: x=\(windowX), y=\(windowY)")
        print("PenAIDelegate: Mouse offset: \(mouseOffset)px")
        print("PenAIDelegate: Window collection behavior: .canJoinAllSpaces (displayed in all desktops)")
        print("PenAIDelegate: Window will be shown when shortcut key is pressed")
    }
    
    private func setupMenuBarIcon() {
        print("SimpleAppDelegate: Setting up menu bar icon")
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else {
            print("SimpleAppDelegate: Error: Could not create status item button")
            return
        }
        
        // Configure button to have no background or border
        button.isBordered = false
        button.focusRingType = .none
        button.showsBorderOnlyWhileMouseInside = false
        
        // Set initial icon based on online status that was set during initialization
        print("PenAIDelegate: Updating status icon with online status: \(isOnline)")
        updateStatusIcon(online: isOnline)
        
        // Set the button's action to handle both left and right clicks
        button.action = #selector(handleMenuBarClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Log the exact frame of the menu bar button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if let button = self?.statusItem?.button {
                let frame = button.frame
                let screenFrame = button.window?.frame ?? CGRect.zero
                print("PenAIDelegate: Menu bar button frame: \(frame)")
                print("PenAIDelegate: Menu bar window frame: \(screenFrame)")
                
                // Get the screen
                if let screen = NSScreen.main {
                    print("PenAIDelegate: Main screen frame: \(screen.frame)")
                    print("PenAIDelegate: Main screen visible frame: \(screen.visibleFrame)")
                    let menuBarHeight = screen.frame.height - screen.visibleFrame.height
                    print("PenAIDelegate: Menu bar height: \(menuBarHeight)")
                }
            }
        }
        
        print("SimpleAppDelegate: Menu created with debug options")
        print("SimpleAppDelegate: Left-click opens window, right-click shows menu")
    }
    
    @objc private func handleMenuBarClick(_ sender: Any) {
        // Get the current event to determine which mouse button was clicked
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp {
                print("PenAIDelegate: Left-click detected on menu bar icon")
                
                // Handle left-click based on app mode
                if !isOnline {
                    // Offline mode: Show reload option
                    print("PenAIDelegate: Offline mode - displaying reload option")
                    displayReloadOption()
                    // Restart initialization process
                    performInitialization()
                } else if isLoggedIn {
                    // Online-login mode: Open PenAI window
                    print("PenAIDelegate: Online-login mode - opening PenAI window")
                    openWindow()
                } else {
                    // Online-logout mode: Open Login window
                    print("PenAIDelegate: Online-logout mode - opening Login window")
                    openLoginWindow()
                }
            } else if event.type == .rightMouseUp {
                print("PenAIDelegate: Right-click detected on menu bar icon")
                
                // Create menu for right-click
                let menu = NSMenu()
                
                // Add menu items based on app mode
                if isOnline && isLoggedIn {
                    // Online-login mode: Show preferences, logout and exit
                    menu.addItem(NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: "p"))
                    menu.addItem(NSMenuItem(title: "Logout", action: #selector(logout), keyEquivalent: "l"))
                    menu.addItem(NSMenuItem.separator())
                } else if isOnline && !isLoggedIn {
                    // Online-logout mode: Show login and exit
                    menu.addItem(NSMenuItem(title: "Login", action: #selector(openLoginWindow), keyEquivalent: "l"))
                    menu.addItem(NSMenuItem.separator())
                } else {
                    // Offline mode: Show reload and exit
                    menu.addItem(NSMenuItem(title: "Reload", action: #selector(performInitialization), keyEquivalent: "r"))
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Always show exit option
                menu.addItem(NSMenuItem(title: "Exit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
                
                // Show the menu at the current mouse position
                if let button = statusItem?.button {
                    NSMenu.popUpContextMenu(menu, with: event, for: button)
                }
            }
        }
    }
    
    @objc private func logout() {
        print("PenAIDelegate: User logged out")
        setLoginStatus(false)
        setAppMode(.onlineLogout)
    }
    

    
    /// Positions a window relative to the Pen menu bar icon
    private func positionWindowRelativeToMenuBarIcon(_ window: NSWindow) {
        guard let button = statusItem?.button, let buttonWindow = button.window else {
            print("PenAIDelegate: Error: Could not get status item button frame")
            // Fallback to default position if status item isn't available
            guard let screen = NSScreen.main else {
                print("PenAIDelegate: Error: Could not get main screen")
                return
            }
            let screenWidth = screen.frame.width
            let screenHeight = screen.frame.height
            let menuBarHeight = screen.frame.height - screen.visibleFrame.height
            
            let windowSize = window.frame.size
            let windowX = screenWidth - (screenWidth / 4) - windowSize.width
            let windowY = screenHeight - menuBarHeight - 6 - windowSize.height
            
            window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
            return
        }
        
        // Use the button's screen instead of NSScreen.main!
        guard let screen = buttonWindow.screen else {
            print("PenAIDelegate: Error: Could not get button screen")
            return
        }
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        let menuBarHeight = screen.frame.height - screen.visibleFrame.height
        let spacing: CGFloat = 6
        let windowSize = window.frame.size
        
        // Get the button's frame in screen coordinates
        let buttonFrame = button.convert(button.bounds, to: nil)
        let buttonScreenFrame = buttonWindow.convertToScreen(buttonFrame)
        
        // Check if button screen frame is valid (not negative or zero-sized)
        if buttonScreenFrame.minY < 0 || buttonScreenFrame.width == 0 || buttonScreenFrame.height == 0 {
            print("PenAIDelegate: Button screen frame invalid: \(buttonScreenFrame), using fallback position")
            // Use fallback position if button frame is invalid
            let windowX = screenWidth - (screenWidth / 4) - windowSize.width
            let windowY = screenHeight - menuBarHeight - 6 - windowSize.height
            window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
            return
        }
        
        // Calculate position relative to menu bar icon
        // X position: Pen icon X + 6px
        let x = buttonScreenFrame.minX + spacing
        // Y position: top of screen - menu bar height - spacing - window height
        let y = screenHeight - menuBarHeight - spacing - windowSize.height
        
        print("PenAIDelegate: Menu bar icon screen frame: \(buttonScreenFrame)")
        print("PenAIDelegate: Calculated window position: x=\(x), y=\(y)")
        print("PenAIDelegate: Screen height: \(screenHeight), Menu bar height: \(menuBarHeight)")
        
        // Set window position
        window.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Clamp window to screen bounds
        clampWindowToScreen(window, screen: screen)
        
        // Ensure window is on the same screen as the menu bar icon
        window.setFrame(window.frame, display: false, animate: false)
    }
    

    
    @objc private func openPreferences() {
        print("PenAIDelegate: Opening preferences")
        print("PenAIDelegate: Current user: \(currentUser?.name ?? "nil")")
        print("PenAIDelegate: Current user profileImage: \(currentUser?.profileImage != nil ? "[BASE64 ENCODED IMAGE]" : "nil")")
        
        // Create or show preferences window
        if preferencesWindow == nil {
            print("PenAIDelegate: Creating new PreferencesWindow with user: \(currentUser?.name ?? "nil")")
            preferencesWindow = PreferencesWindow(user: currentUser)
        }
        
        if let window = preferencesWindow {
            // Use the showAndFocus method to ensure keyboard input works
            window.showAndFocus()
            print("PenAIDelegate: Preferences window shown")
        }
    }
    
    @objc private func openTestWindow() {
        print("PenAIDelegate: Opening test window")
        
        // Create and show the test window with UI controls
        let testWindow = BaseWindow.createTestWindow()
        
        // Position window relative to menu bar icon
        positionWindowRelativeToMenuBarIcon(testWindow)
        
        // Show the window
        testWindow.showAndFocus()
        
        print("PenAIDelegate: Test window opened with UI controls")
    }
    
    @objc private func openWindow() {
        print("PenAIDelegate: Opening window from menubar icon")
        
        if let window = window {
            // Position window relative to menu bar icon
            positionWindowRelativeToMenuBarIcon(window)
            
            print("PenAIDelegate: Opening window at specified position")
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    private func setupShortcutKey() {
        print("SimpleAppDelegate: Setting up shortcut key")
        
        // Check accessibility permissions
        checkAccessibilityPermissions()
        
        // Load saved shortcut from UserDefaults
        let defaults = UserDefaults.standard
        let shortcutKeyDefaultsKey = "pen.shortcutKey"
        let defaultShortcut = "Command+Option+P"
        let savedShortcut = defaults.string(forKey: shortcutKeyDefaultsKey) ?? defaultShortcut
        
        print("SimpleAppDelegate: Loaded shortcut: \(savedShortcut)")
        
        // Convert shortcut string to key code and modifiers
        if let (keyCode, modifiers) = shortcutStringToKeyCodeAndModifiers(shortcut: savedShortcut) {
            // Register the shortcut using ShortcutService
            ShortcutService.shared.registerShortcut(keyCode: keyCode, modifiers: modifiers)
            print("SimpleAppDelegate: Shortcut registered using ShortcutService")
        } else {
            print("SimpleAppDelegate: Failed to parse shortcut: \(savedShortcut), using default")
            // Register default shortcut
            ShortcutService.shared.registerShortcut(keyCode: 35, modifiers: UInt32(cmdKey | optionKey))
        }
        
        // Dependencies analysis
        print("SimpleAppDelegate: Dependencies for global shortcut key:")
        print("1. Accessibility permissions: Required for global event monitoring")
        print("2. ShortcutService: Required for shortcut key management")
        print("3. UserDefaults: Required for shortcut persistence")
        
        // Current status
        print("SimpleAppDelegate: Current status:")
        print("- ✅ Shortcut key is registered")
        print("- ✅ Using shortcut: \(savedShortcut)")
        print("- ✅ Accessibility permissions are checked")
        
        // Note for real implementation
        print("SimpleAppDelegate: Note: Press the configured shortcut to open the PenAI window")
        print("SimpleAppDelegate: Note: This works from any application")
    }
    
    private func shortcutStringToKeyCodeAndModifiers(shortcut: String) -> (UInt32, UInt32)? {
        let components = shortcut.split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
        
        if components.count < 2 {
            return nil
        }
        
        // Extract modifiers
        var modifiers: UInt32 = 0
        for component in components.dropLast() {
            switch component {
            case "Command":
                modifiers |= UInt32(cmdKey)
            case "Option":
                modifiers |= UInt32(optionKey)
            case "Shift":
                modifiers |= UInt32(shiftKey)
            case "Control":
                modifiers |= UInt32(controlKey)
            default:
                return nil
            }
        }
        
        // Extract key
        let key = components.last!
        let keyCode = keyToKeyCode(key)
        if keyCode == 0 {
            return nil
        }
        
        return (keyCode, modifiers)
    }
    
    private func keyToKeyCode(_ key: String) -> UInt32 {
        // Map key strings to key codes
        let keyMap: [String: UInt32] = [
            "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3, "G": 5, "H": 4, "I": 34, "J": 38,
            "K": 40, "L": 37, "M": 46, "N": 45, "O": 31, "P": 35, "Q": 12, "R": 15, "S": 1, "T": 17,
            "U": 32, "V": 9, "W": 13, "X": 7, "Y": 16, "Z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25,
            "Space": 49, "Return": 36, "Tab": 48, "Delete": 51, "Escape": 53,
            "Left": 123, "Right": 124, "Down": 125, "Up": 126
        ]
        
        return keyMap[key] ?? 0
    }
    
    /// Positions a window relative to the mouse cursor
    private func positionWindowRelativeToMouseCursor(_ window: NSWindow) {
        // Get current mouse location
        let mouseLocation = NSEvent.mouseLocation
        
        // Get the screen that contains the mouse cursor
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else {
            print("PenAIDelegate: Error: Could not get screen for mouse location")
            return
        }
        
        // Calculate window position: mouse cursor + offset
        // Note: NSEvent.mouseLocation returns coordinates in global screen space with origin at bottom-left
        // NSWindow.setFrameOrigin expects the bottom-left corner of the window
        let windowX = mouseLocation.x + mouseOffset
        let windowY = mouseLocation.y - mouseOffset - window.frame.height
        
        print("PenAIDelegate: Mouse cursor position: x=\(mouseLocation.x), y=\(mouseLocation.y)")
        print("PenAIDelegate: Screen frame: \(screen.frame)")
        print("PenAIDelegate: Calculated window position: x=\(windowX), y=\(windowY)")
        print("PenAIDelegate: Mouse offset: \(mouseOffset)px")
        
        // Set window position
        window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        
        // Clamp window to screen bounds
        clampWindowToScreen(window, screen: screen)
    }
    
    /// Clamps a window to the screen bounds to prevent it from going off-screen
    private func clampWindowToScreen(_ window: NSWindow, screen: NSScreen) {
        let visibleFrame = screen.visibleFrame
        var frame = window.frame
        
        // Clamp horizontally
        if frame.maxX > visibleFrame.maxX {
            frame.origin.x = visibleFrame.maxX - frame.width
        }
        if frame.minX < visibleFrame.minX {
            frame.origin.x = visibleFrame.minX
        }
        
        // Clamp vertically
        if frame.minY < visibleFrame.minY {
            frame.origin.y = visibleFrame.minY
        }
        if frame.maxY > visibleFrame.maxY {
            frame.origin.y = visibleFrame.maxY - frame.height
        }
        
        // Apply the clamped position
        window.setFrame(frame, display: false)
        
        print("PenAIDelegate: Window clamped to screen bounds: \(frame)")
    }
    
    @objc private func openPenAI() {
        print("PenAIDelegate: Handling shortcut key press")
        
        if let window = window {
            // Activate the app to ensure it gets focus
            NSApp.activate(ignoringOtherApps: true)
            
            if window.isVisible {
                print("PenAIDelegate: Window is already open, repositioning to mouse cursor")
                
                // Position window relative to mouse cursor
                positionWindowRelativeToMouseCursor(window)
                
                print("PenAIDelegate: Window repositioned, app remains running with menubar icon available")
                window.makeKeyAndOrderFront(nil)
            } else {
                print("PenAIDelegate: Window is closed, opening relative to mouse cursor")
                
                // Position window relative to mouse cursor
                positionWindowRelativeToMouseCursor(window)
                
                print("PenAIDelegate: Opening PenAI window at new position, app is ready for interaction")
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    /// Toggles the main window visibility
    func toggleMainWindow() {
        print("PenAIDelegate: Toggling main window")
        
        if let window = window {
            if window.isVisible {
                print("PenAIDelegate: Hiding window")
                window.orderOut(nil)
            } else {
                print("PenAIDelegate: Showing window relative to mouse cursor")
                NSApp.activate(ignoringOtherApps: true)
                positionWindowRelativeToMouseCursor(window)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    @objc private func closeWindow() {
        print("PenAIDelegate: Closing PenAI window via close button")
        window?.orderOut(nil)
        print("PenAIDelegate: Window closed, app remains running with menubar icon available")
        print("PenAIDelegate: Shortcut key functionality still works")
    }
    
    @objc func openLoginWindow() {
        print("PenAIDelegate: Opening login window")
        
        // Create or show login window
        if loginWindow == nil {
            // Create login window with nil menuBarIconFrame (position will be calculated externally)
            // Pass self as the penDelegate
            loginWindow = LoginWindow(menuBarIconFrame: nil, penDelegate: self)
        }
        
        if let window = loginWindow {
            // Position window relative to menu bar icon
            positionWindowRelativeToMenuBarIcon(window)
            
            // Use the showAndFocus method to ensure keyboard input works
            window.showAndFocus()
        }
    }
    
    /// Sets the app mode and updates the UI accordingly
    func setAppMode(_ mode: AppMode) {
        switch mode {
        case .onlineLogin:
            isOnline = true
            isLoggedIn = true
        case .onlineLogout:
            isOnline = true
            isLoggedIn = false
        case .offline:
            isOnline = false
            isLoggedIn = false
        }
        
        // Update the menu bar icon
        updateStatusIcon(online: isOnline)
        
        // Display appropriate popup message based on mode
        if mode == .onlineLogout {
            // Delay popup to give menu bar icon time to position itself
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.displayPopupMessage(LocalizationService.shared.localizedString(for: "hello_guest"))
            }
        }
    }
    
    /// Updates the menu bar icon based on current state
    func updateMenuBarIcon() {
        updateStatusIcon(online: isOnline)
    }
    
    /// Creates a global user object
    func createGlobalUserObject(user: User) {
        // Store user information and trigger login status update
        setLoginStatus(true, user: user)
        
        // Load and test AI configurations for the user
        loadAndTestAIConfigurations(user: user)
    }
    
    /// Loads and tests AI configurations for the user
    private func loadAndTestAIConfigurations(user: User) {
        Task {
            do {
                // Load all AI configurations for the user
                let configurations = try await AIManager.shared.getConnections(for: user.id)
                
                print("PenAIDelegate: Loaded \(configurations.count) AI configurations for user \(user.name)")
                
                if configurations.isEmpty {
                    // No AI configurations found
                    print("PenAIDelegate: No AI configurations found for user \(user.name)")
                    // Wait until previous popup messages fade out (3 seconds + 0.3 seconds fade out)
                    try await Task.sleep(nanoseconds: 3_300_000_000) // 3.3 seconds
                    // Show shorter popup message
                    WindowManager.displayPopupMessage("No AI Configuration set up yet.\nGo to Preference → AI Configuration to set up.")
                } else {
                    // Test each AI configuration
                    for (index, configuration) in configurations.enumerated() {
                        print("\n********************************** Test AI Configuration for \(user.name) : Provider \(index + 1): \(configuration.apiProvider) *********************************")
                        
                        do {
                            // Test the connection
                            let success = try await AIManager.shared.testConnection(
                                apiKey: configuration.apiKey,
                                providerName: configuration.apiProvider
                            )
                            
                            if success {
                                print("PenAIDelegate: AI Configuration \(configuration.apiProvider) test successful")
                            } else {
                                print("PenAIDelegate: AI Configuration \(configuration.apiProvider) test failed")
                            }
                        } catch {
                            print("PenAIDelegate: Error testing AI Configuration \(configuration.apiProvider): \(error)")
                        }
                    }
                }
            } catch {
                print("PenAIDelegate: Error loading AI configurations: \(error)")
            }
        }
    }
    
    /// Sets the login status and updates the menu bar icon
    func setLoginStatus(_ loggedIn: Bool, user: User? = nil, userName: String = "") {
        isLoggedIn = loggedIn
        if let user = user {
            self.userName = user.name
            self.currentUser = user
        } else if !userName.isEmpty {
            self.userName = userName
        }
        
        // Update the menu bar icon based on login status
        updateStatusIcon(online: isOnline)
        
        // Wait until menu bar icon is fully loaded before displaying popup message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // Display appropriate popup message
            if loggedIn {
                let greeting = LocalizationService.shared.localizedString(for: "hello_user", withFormat: self?.userName ?? "")
                self?.displayPopupMessage(greeting)
            } else {
                self?.displayPopupMessage(LocalizationService.shared.localizedString(for: "hello_guest"))
            }
        }
    }
    
    // App mode enumeration
    enum AppMode {
        case onlineLogin
        case onlineLogout
        case offline
    }
    
    /// Displays a global popup message following the specified design guidelines
    func displayPopupMessage(_ message: String) {
        WindowManager.displayPopupMessage(message)
    }
    
    /// Displays a reload option when in offline mode
    private func displayReloadOption() {
        guard statusItem?.button != nil else { return }
        
        // Create a temporary label for the reload message
        let reloadLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 20))
        reloadLabel.stringValue = LocalizationService.shared.localizedString(for: "click_to_reload")
        reloadLabel.isBezeled = false
        reloadLabel.drawsBackground = false
        reloadLabel.isEditable = false
        reloadLabel.isSelectable = false
        reloadLabel.textColor = .systemGreen
        reloadLabel.font = NSFont.systemFont(ofSize: 12)
        
        // Create a window for the reload message
        let reloadWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 20), 
                                  styleMask: [.borderless], 
                                  backing: .buffered, 
                                  defer: false)
        reloadWindow.isOpaque = false
        reloadWindow.backgroundColor = .clear
        reloadWindow.level = .floating
        reloadWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient
        ]
        reloadWindow.contentView = reloadLabel
        
        // Position reload window relative to menu bar icon
        positionWindowRelativeToMenuBarIcon(reloadWindow)
        
        // Show the reload message without stealing focus
        reloadWindow.orderFrontRegardless()
        
        // Hide the reload message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            reloadWindow.orderOut(nil)
        }
        
        print("PenAIDelegate: Displayed reload option")
    }

}

// Main function is handled by @main attribute
