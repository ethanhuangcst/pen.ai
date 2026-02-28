import Cocoa
import Carbon

extension NSFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.bold)
    }
}

class PenDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private var window: BaseWindow?
    private var loginWindow: LoginWindow?
    private var preferencesWindow: PreferencesWindow?
    private var newOrEditPromptWindow: NewOrEditPrompt?

    private let windowWidth: CGFloat = 378
    private let windowHeight: CGFloat = 388
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
        createMainWindow()
        
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
            print("PenDelegate: Setting online mode")
            self.internetFailure = false
            databaseFailure = false
        } else {
            print("PenDelegate: Setting offline mode")
            if failureType == "internet" {
                self.internetFailure = internetFailure
                print("PenDelegate: Setting 'Internet Failure' flag to \(internetFailure)")
            } else if failureType == "database" {
                databaseFailure = true
                print("PenDelegate: Setting 'Database Failure' flag to true")
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
        
        print("PenDelegate: Using icon: \(iconName)")
        
        // Get the current directory path
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        
        // Construct the full path to the icon
        let iconPath = "\(currentDirectory)/Resources/Assets/\(iconName)"
        
        print("PenDelegate: Icon path: \(iconPath)")
        
        if let icon = NSImage(contentsOfFile: iconPath) {
            print("PenDelegate: Loaded icon from path: \(iconPath)")
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
            print("PenDelegate: Icon updated successfully with template mode enabled")
        } else {
            print("PenDelegate: Error: Could not load icon from path: \(iconPath)")
            // Fallback: set a simple text in the menu bar
            button.title = online ? LocalizationService.shared.localizedString(for: "pen_menu_title") : LocalizationService.shared.localizedString(for: "pen_menu_title_offline")
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
    
    private func createMainWindow() {
        print("SimpleAppDelegate: Creating main window")
        
        // Create window using BaseWindow with standard UI behaviors but without logo and title
        let windowSize = NSSize(width: windowWidth, height: windowHeight)
        window = BaseWindow.createStandardWindow(size: windowSize, showLogo: false, showTitle: false)
        
        // Add footer container to main window
        if let window = window, let contentView = window.contentView {
            addFooterContainer(to: contentView, size: windowSize)
        }
        
        // Don't show window automatically on app launch
        
        print("PenDelegate: Main window created but not shown")
        print("PenDelegate: Window size: \(windowWidth)x\(windowHeight)")
        print("PenDelegate: Window will be shown when shortcut key is pressed")
    }
    
    /// Adds a footer container with text label and logo
    private func addFooterContainer(to contentView: NSView, size: NSSize) {
        // Create footer container with fixed width of 378px
        let footerHeight: CGFloat = 30
        let footerContainer = NSView(frame: NSRect(x: 0, y: 0, width: 378, height: footerHeight))
        footerContainer.wantsLayer = true
        footerContainer.layer?.backgroundColor = NSColor.clear.cgColor
        footerContainer.identifier = NSUserInterfaceItemIdentifier("pen_footer")
        
        // Add text label
        let textLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: 180, height: footerHeight))
        textLabel.stringValue = "Pen - AI writing assistent"
        textLabel.isBezeled = false
        textLabel.drawsBackground = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.font = NSFont.systemFont(ofSize: 12)
        textLabel.textColor = NSColor.secondaryLabelColor
        textLabel.alignment = .right
        
        // Add small logo
        let logoPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/logo.png"
        if let logo = NSImage(contentsOfFile: logoPath) {
            let logoSize: CGFloat = 26
            let logoView = NSImageView(frame: NSRect(x: 0, y: 2, width: logoSize, height: logoSize))
            logoView.image = logo
            
            // Set text position to 148, 3 absolute
            let textX: CGFloat = 148
            let textY: CGFloat = -3 // 6 (footer Y) + (-3) = 3
            // Set logo position to 336, 6
            let logoX: CGFloat = 336
            let logoY: CGFloat = 6
            
            textLabel.frame.origin.x = textX
            textLabel.frame.origin.y = textY
            logoView.frame.origin.x = logoX
            logoView.frame.origin.y = logoY
            
            footerContainer.addSubview(textLabel)
            footerContainer.addSubview(logoView)
        }
        
        // Position at the specified coordinates (0, 6)
        footerContainer.frame.origin = NSPoint(x: 0, y: 6)
        print("PenDelegate: Footer position set to (0, 6)")
        
        // Add footer container to content view
        contentView.addSubview(footerContainer)
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
        print("PenDelegate: Updating status icon with online status: \(isOnline)")
        updateStatusIcon(online: isOnline)
        
        // Set the button's action to handle both left and right clicks
        button.action = #selector(handleMenuBarClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Log the exact frame of the menu bar button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if let button = self?.statusItem?.button {
                let frame = button.frame
                let screenFrame = button.window?.frame ?? CGRect.zero
                print("PenDelegate: Menu bar button frame: \(frame)")
                print("PenDelegate: Menu bar window frame: \(screenFrame)")
                
                // Get the screen
                if let screen = NSScreen.main {
                    print("PenDelegate: Main screen frame: \(screen.frame)")
                    print("PenDelegate: Main screen visible frame: \(screen.visibleFrame)")
                    let menuBarHeight = screen.frame.height - screen.visibleFrame.height
                    print("PenDelegate: Menu bar height: \(menuBarHeight)")
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
                print("PenDelegate: Left-click detected on menu bar icon")
                
                // Handle left-click based on app mode
                if !isOnline {
                    // Offline mode: Show reload option
                    print("PenDelegate: Offline mode - displaying reload option")
                    displayReloadOption()
                    // Restart initialization process
                    performInitialization()
                } else if isLoggedIn {
                    // Online-login mode: Check if NewOrEditPrompt window is open
                    if NewOrEditPrompt.isWindowOpen, let newOrEditWindow = NewOrEditPrompt.currentInstance {
                        // If NewOrEditPrompt is open, bring it to front
                        print("PenDelegate: NewOrEditPrompt window is open, bringing it to front")
                        newOrEditWindow.bringToFront()
                    } else {
                        // Open PenAI window
                        print("PenDelegate: Online-login mode - opening PenAI window")
                        openWindow()
                    }
                } else {
                    // Online-logout mode: Open Login window
                    print("PenDelegate: Online-logout mode - opening Login window")
                    openLoginWindow()
                }
            } else if event.type == .rightMouseUp {
                print("PenDelegate: Right-click detected on menu bar icon")
                
                // Create menu for right-click
                let menu = NSMenu()
                
                // Add menu items based on app mode
                if isOnline && isLoggedIn {
                    // Online-login mode: Show preferences, logout and exit
                    menu.addItem(NSMenuItem(title: LocalizationService.shared.localizedString(for: "preferences"), action: #selector(openPreferences), keyEquivalent: "p"))
                    menu.addItem(NSMenuItem(title: LocalizationService.shared.localizedString(for: "logout"), action: #selector(logout), keyEquivalent: "l"))
                    menu.addItem(NSMenuItem.separator())
                } else if isOnline && !isLoggedIn {
                    // Online-logout mode: Show login and exit
                    menu.addItem(NSMenuItem(title: LocalizationService.shared.localizedString(for: "login"), action: #selector(openLoginWindow), keyEquivalent: "l"))
                    menu.addItem(NSMenuItem.separator())
                } else {
                    // Offline mode: Show reload and exit
                    menu.addItem(NSMenuItem(title: LocalizationService.shared.localizedString(for: "reload"), action: #selector(performInitialization), keyEquivalent: "r"))
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Always show exit option
                menu.addItem(NSMenuItem(title: LocalizationService.shared.localizedString(for: "exit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
                
                // Show the menu at the current mouse position
                if let button = statusItem?.button {
                    NSMenu.popUpContextMenu(menu, with: event, for: button)
                }
            }
        }
    }
    
    @objc private func logout() {
        print("PenDelegate: User logged out")
        setLoginStatus(false)
        setAppMode(.onlineLogout)
    }
    

    
    /// Positions a window relative to the Pen menu bar icon
    private func positionWindowRelativeToMenuBarIcon(_ window: NSWindow) {
        guard let button = statusItem?.button, let buttonWindow = button.window else {
            print("PenDelegate: Error: Could not get status item button frame")
            // Fallback to default position if status item isn't available
            guard let screen = NSScreen.main else {
                print("PenDelegate: Error: Could not get main screen")
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
            print("PenDelegate: Error: Could not get button screen")
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
            print("PenDelegate: Button screen frame invalid: \(buttonScreenFrame), using fallback position")
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
        
        print("PenDelegate: Menu bar icon screen frame: \(buttonScreenFrame)")
        print("PenDelegate: Calculated window position: x=\(x), y=\(y)")
        print("PenDelegate: Screen height: \(screenHeight), Menu bar height: \(menuBarHeight)")
        
        // Set window position
        window.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Clamp window to screen bounds
        clampWindowToScreen(window, screen: screen)
        
        // Ensure window is on the same screen as the menu bar icon
        window.setFrame(window.frame, display: false, animate: false)
    }
    

    
    @objc private func openPreferences() {
        print("PenDelegate: Opening preferences")
        print("PenDelegate: Current user: \(currentUser?.name ?? "nil")")
        print("PenDelegate: Current user profileImage: \(currentUser?.profileImage != nil ? "[BASE64 ENCODED IMAGE]" : "nil")")
        
        // Check if preferences window already exists
        if let window = preferencesWindow {
            // If it exists, just show it
            print("PenDelegate: Preferences window already exists, showing existing window")
            window.showAndFocus()
        } else {
            // If it doesn't exist, create a new one
            print("PenDelegate: Creating new PreferencesWindow with user: \(currentUser?.name ?? "nil")")
            preferencesWindow = PreferencesWindow(user: currentUser)
            
            if let window = preferencesWindow {
                // Use the showAndFocus method to ensure keyboard input works
                window.showAndFocus()
                print("PenDelegate: Preferences window shown")
            }
        }
    }
    
    @objc private func openTestWindow() {
        print("PenDelegate: Opening test window")
        
        // Create and show the test window with UI controls
        let testWindow = BaseWindow.createTestWindow()
        
        // Position window relative to menu bar icon
        positionWindowRelativeToMenuBarIcon(testWindow)
        
        // Show the window
        testWindow.showAndFocus()
        
        print("PenDelegate: Test window opened with UI controls")
    }
    
    @objc private func openWindow() {
        print("PenDelegate: Opening window from menubar icon")
        
        if let window = window {
            if window.isVisible {
                print("PenDelegate: Window is already open, closing it")
                window.orderOut(nil)
            } else {
                // Position window relative to menu bar icon
                window.positionRelativeToMenuBarIcon()
                
                print("PenDelegate: Opening window at specified position")
                window.showAndFocus()
            }
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
            print("PenDelegate: Error: Could not get screen for mouse location")
            return
        }
        
        // Calculate window position: mouse cursor + offset
        // Note: NSEvent.mouseLocation returns coordinates in global screen space with origin at bottom-left
        // NSWindow.setFrameOrigin expects the bottom-left corner of the window
        let windowX = mouseLocation.x + mouseOffset
        let windowY = mouseLocation.y - mouseOffset - window.frame.height
        
        print("PenDelegate: Mouse cursor position: x=\(mouseLocation.x), y=\(mouseLocation.y)")
        print("PenDelegate: Screen frame: \(screen.frame)")
        print("PenDelegate: Calculated window position: x=\(windowX), y=\(windowY)")
        print("PenDelegate: Mouse offset: \(mouseOffset)px")
        
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
        
        print("PenDelegate: Window clamped to screen bounds: \(frame)")
    }
    
    @objc private func openPenAI() {
        print("PenDelegate: Handling shortcut key press")
        
        // Check if app is in online login mode
        if !isOnline || !isLoggedIn {
            print("PenDelegate: Not in online login mode, cannot open window")
            return
        }
        
        if let window = window {
            if window.isVisible {
                print("PenDelegate: Window is already open, repositioning to mouse cursor")
                
                // Position window relative to mouse cursor
                positionWindowRelativeToMouseCursor(window)
                
                print("PenDelegate: Window repositioned, app remains running with menubar icon available")
                window.makeKeyAndOrderFront(nil)
            } else {
                print("PenDelegate: Window is closed, opening relative to mouse cursor")
                
                // Position window relative to mouse cursor
                positionWindowRelativeToMouseCursor(window)
                
                print("PenDelegate: Opening PenAI window at new position, app is ready for interaction")
                window.showAndFocus()
            }
        }
    }
    
    /// Toggles the main window visibility
    func toggleMainWindow() {
        print("PenDelegate: Toggling main window")
        
        if let window = window {
            if window.isVisible {
                print("PenDelegate: Hiding window")
                window.orderOut(nil)
            } else {
                print("PenDelegate: Showing window relative to mouse cursor")
                positionWindowRelativeToMouseCursor(window)
                window.showAndFocus()
            }
        }
    }
    
    @objc private func closeWindow() {
        print("PenDelegate: Closing PenAI window via close button")
        window?.orderOut(nil)
        print("PenDelegate: Window closed, app remains running with menubar icon available")
        print("PenDelegate: Shortcut key functionality still works")
    }
    
    @objc func openLoginWindow() {
        print("PenDelegate: Opening login window")
        
        // Create or show login window
        if loginWindow == nil {
            // Create login window with nil menuBarIconFrame (position will be calculated externally)
            // Pass self as the penDelegate
            print("PenDelegate: Creating new LoginWindow")
            loginWindow = LoginWindow(menuBarIconFrame: nil, penDelegate: self)
        }
        
        if let window = loginWindow {
            // Position window relative to menu bar icon
            positionWindowRelativeToMenuBarIcon(window)
            
            // Use the showAndFocus method to ensure keyboard input works
            window.showAndFocus()
            print("PenDelegate: Login window shown")
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
                
                print("PenDelegate: Loaded \(configurations.count) AI configurations for user \(user.name)")
                
                if configurations.isEmpty {
                    // No AI configurations found
                    print("PenDelegate: No AI configurations found for user \(user.name)")
                    // Wait until previous popup messages fade out (3 seconds + 0.3 seconds fade out)
                    try await Task.sleep(nanoseconds: 3_300_000_000) // 3.3 seconds
                    // Show shorter popup message
                    WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "no_ai_configuration"))
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
                                print("PenDelegate: AI Configuration \(configuration.apiProvider) test successful")
                            } else {
                                print("PenDelegate: AI Configuration \(configuration.apiProvider) test failed")
                            }
                        } catch {
                            print("PenDelegate: Error testing AI Configuration \(configuration.apiProvider): \(error)")
                        }
                    }
                }
            } catch {
                print("PenDelegate: Error loading AI configurations: \(error)")
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
        } else if !loggedIn {
            // Clear user information when logging out
            self.userName = ""
            self.currentUser = nil
        }
        
        // Update the menu bar icon based on login status
        updateStatusIcon(online: isOnline)
        
        // Update window title with username
        updateWindowTitle()
        
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
    
    /// Updates the window title with the username
    private func updateWindowTitle() {
        guard let window = window, let contentView = window.contentView else { return }
        
        // Perform UI operations on the main thread
        DispatchQueue.main.async {
            // Remove existing title label
            for subview in contentView.subviews {
                if let label = subview as? NSTextField, label.font?.isBold == true {
                    label.removeFromSuperview()
                }
            }
            
            // No title label added - title has been removed as requested
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
        
        print("PenDelegate: Displayed reload option")
    }

}

// Main function is handled by @main attribute
