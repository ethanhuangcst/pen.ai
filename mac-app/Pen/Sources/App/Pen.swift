import Cocoa
import Carbon

// Import MainMenu for shortcut support
import AppKit

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
    private var penWindowService: PenWindowService?
    var shortcutService: ShortcutService?
    private var windowManager: WindowManager = WindowManager.shared

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
        
        // Set activation policy to accessory to prevent Dock icon
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Force app to always use light mode (disable dark mode for now)
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        
        // Initialize system config service
        print("Initializing SystemConfigService...")
        _ = SystemConfigService.shared
        print("SystemConfigService initialized")
        
        // Setup menu bar icon first so it's available for login window positioning
        setupMenuBarIcon()
        
        // Install main menu for system shortcut support
        installMainMenu()
        
        // Create a simple window
        createMainWindow()
        
        // Perform 3-step initialization process
        performInitialization()
        
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
        
        let iconName = online ? "icon" : "icon_offline"
        let iconPath = ResourceService.shared.getResourcePath(relativePath: "Assets/\(iconName).png")
        
        if let icon = NSImage(contentsOfFile: iconPath) {
            let desiredSize = NSSize(width: 22, height: 22)
            let resizedIcon = NSImage(size: desiredSize)
            
            resizedIcon.lockFocus()
            icon.draw(in: NSRect(origin: .zero, size: desiredSize), from: NSRect(origin: .zero, size: icon.size), operation: .sourceOver, fraction: 1.0)
            resizedIcon.unlockFocus()
            
            resizedIcon.isTemplate = true
            button.image = resizedIcon
            
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
        } else {
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
        
        penWindowService = PenWindowService()
        window = penWindowService?.createWindow()
    }
    
    /// Adds a footer container with text label and logo
    private func addFooterContainer(to contentView: NSView, size: NSSize) {
        let footerHeight: CGFloat = 30
        let footerContainer = NSView(frame: NSRect(x: 0, y: 0, width: 378, height: footerHeight))
        footerContainer.wantsLayer = true
        footerContainer.layer?.backgroundColor = NSColor.clear.cgColor
        footerContainer.identifier = NSUserInterfaceItemIdentifier("pen_footer")
        
        // Add instruction label
        let instructionLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: 180, height: footerHeight))
        // Load saved shortcut from UserDefaults
        let defaults = UserDefaults.standard
        let shortcutKeyDefaultsKey = "pen.shortcutKey"
        let defaultShortcut = "Command+Option+P"
        let savedShortcut = defaults.string(forKey: shortcutKeyDefaultsKey) ?? defaultShortcut
        let displayShortcut = LocalizationService.shared.formatShortcutForDisplay(savedShortcut)
        instructionLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_footer_instruction", withFormat: displayShortcut)
        instructionLabel.isBezeled = false
        instructionLabel.drawsBackground = false
        instructionLabel.isEditable = false
        instructionLabel.isSelectable = false
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.textColor = NSColor.secondaryLabelColor
        instructionLabel.alignment = .left
        instructionLabel.identifier = NSUserInterfaceItemIdentifier("pen_footer_instruction")
        
        // Add auto label
        let autoLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: 40, height: footerHeight))
        autoLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_footer_auto")
        autoLabel.isBezeled = false
        autoLabel.drawsBackground = false
        autoLabel.isEditable = false
        autoLabel.isSelectable = false
        autoLabel.font = NSFont.systemFont(ofSize: 12)
        autoLabel.textColor = NSColor.secondaryLabelColor
        autoLabel.alignment = .left
        autoLabel.identifier = NSUserInterfaceItemIdentifier("pen_footer_auto_label")
        
        // Add auto switch button
        let autoSwitch = NSSwitch(frame: NSRect(x: 0, y: 0, width: 40, height: footerHeight))
        autoSwitch.identifier = NSUserInterfaceItemIdentifier("pen_footer_auto_switch_button")
        autoSwitch.state = .on
        
        // Add text label
        let textLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: 250, height: footerHeight))
        textLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_footer_label")
        textLabel.isBezeled = false
        textLabel.drawsBackground = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.font = NSFont.systemFont(ofSize: 14)
        textLabel.textColor = NSColor.secondaryLabelColor
        textLabel.alignment = .right
        textLabel.identifier = NSUserInterfaceItemIdentifier("pen_footer_lable")
        
        // Add small logo
        if let logo = ColorService.shared.getLogo() {
            let logoSize: CGFloat = 26
            let logoView = NSImageView(frame: NSRect(x: 0, y: 0, width: logoSize, height: logoSize))
            logoView.image = logo
            
            // Set instruction label position to 46, -7
            let instructionX: CGFloat = 46
            let instructionY: CGFloat = -7
            // Set auto label position to 270, -7
            let autoLabelX: CGFloat = 270
            let autoLabelY: CGFloat = -7
            // Set auto switch position to 310, 0
            let autoSwitchX: CGFloat = 310
            let autoSwitchY: CGFloat = 0
            // Set text label position to 330, -6
            let textX: CGFloat = 330
            let textY: CGFloat = -6
            // Set logo position to 19, 2
            let logoX: CGFloat = 19
            let logoY: CGFloat = 2
            
            instructionLabel.frame.origin.x = instructionX
            instructionLabel.frame.origin.y = instructionY
            autoLabel.frame.origin.x = autoLabelX
            autoLabel.frame.origin.y = autoLabelY
            autoSwitch.frame.origin.x = autoSwitchX
            autoSwitch.frame.origin.y = autoSwitchY
            textLabel.frame.origin.x = textX
            textLabel.frame.origin.y = textY
            logoView.frame.origin.x = logoX
            logoView.frame.origin.y = logoY
            
            footerContainer.addSubview(instructionLabel)
            footerContainer.addSubview(autoLabel)
            footerContainer.addSubview(autoSwitch)
            footerContainer.addSubview(textLabel)
            footerContainer.addSubview(logoView)
        }
        
        footerContainer.frame.origin = NSPoint(x: 0, y: 0)
        contentView.addSubview(footerContainer)
    }
    
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else {
            print("SimpleAppDelegate: Error: Could not create status item button")
            return
        }
        
        button.isBordered = false
        button.focusRingType = .none
        button.showsBorderOnlyWhileMouseInside = false
        
        updateStatusIcon(online: isOnline)
        
        button.action = #selector(handleMenuBarClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    @objc private func handleMenuBarClick(_ sender: Any) {
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp {
                if !isOnline {
                    displayReloadOption()
                    performInitialization()
                } else if isLoggedIn {
                    openWindow()
                } else {
                    openLoginWindow()
                }
            } else if event.type == .rightMouseUp {
                let menu = NSMenu()
                
                if isOnline && isLoggedIn {
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
    
    @objc internal func logout() {
        print("PenDelegate: User logged out")
        
        // 1. Close all app windows
        closeOtherWindows()
        
        // 2. Reset window references
        preferencesWindow = nil
        newOrEditPromptWindow = nil
        
        // 3. Clean up user information, including AI configurations and prompts
        // Reset AIManager to remove all configurations
        UserService.shared.aiManager?.reset()
        print("PenDelegate: Reset AIManager instance")
        
        // 4. Remove the local global user object and clean up other system resources
        setLoginStatus(false)
        
        // 5. Set Pen as online-logout mode without showing the hello_guest popup
        setAppMode(.onlineLogout, showPopup: false)
        
        // 6. Display i18n logout message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.displayPopupMessage("User logged out. Please log in again to use Pen.")
        }
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
        window.setFrameOrigin(NSPoint(x: x, y: y))
        clampWindowToScreen(window, screen: screen)
        window.setFrame(window.frame, display: false, animate: false)
    }
    

    
    @objc private func openPreferences() {
        closeOtherWindows()
        
        if let window = preferencesWindow {
            window.showAndFocus()
        } else {
            preferencesWindow = PreferencesWindow(user: currentUser)
            
            if let window = preferencesWindow {
                window.showAndFocus()
            }
        }
    }
    
    @objc private func openTestWindow() {
        let testWindow = BaseWindow.createTestWindow()
        positionWindowRelativeToMenuBarIcon(testWindow)
        testWindow.showAndFocus()
    }
    
    @objc private func openWindow() {
        if !isOnline || !isLoggedIn {
            return
        }
        
        if window == nil {
            createMainWindow()
        }
        
        if let window = window {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                closeOtherWindows()
                
                if self.window == nil {
                    createMainWindow()
                }
                
                if let window = self.window {
                    window.positionRelativeToMenuBarIcon()
                    
                    Task {
                        await penWindowService?.initiatePen()
                    }
                    
                    window.showAndFocus()
                }
            }
        }
    }
    
    private func closeOtherWindows() {
        for window in NSApplication.shared.windows {
            window.orderOut(nil)
        }
        
        window = nil
        loginWindow = nil
        preferencesWindow = nil
        newOrEditPromptWindow = nil
    }
    
    private func setupShortcutKey() {
        print("SimpleAppDelegate: Setting up shortcut key")
        
        checkAccessibilityPermissions()
        
        let defaults = UserDefaults.standard
        let shortcutKeyDefaultsKey = "pen.shortcutKey"
        let defaultShortcut = "Command+Option+P"
        let savedShortcut = defaults.string(forKey: shortcutKeyDefaultsKey) ?? defaultShortcut
        
        if let (keyCode, modifiers) = shortcutStringToKeyCodeAndModifiers(shortcut: savedShortcut) {
            shortcutService = ShortcutService()
            shortcutService?.registerShortcut(keyCode: keyCode, modifiers: modifiers)
        } else {
            shortcutService = ShortcutService()
            shortcutService?.registerShortcut(keyCode: 35, modifiers: UInt32(cmdKey | optionKey))
        }
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
    
    private func positionWindowRelativeToMouseCursor(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else {
            return
        }
        
        let windowX = mouseLocation.x + mouseOffset
        let windowY = mouseLocation.y - mouseOffset - window.frame.height
        
        window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        clampWindowToScreen(window, screen: screen)
    }
    
    private func clampWindowToScreen(_ window: NSWindow, screen: NSScreen) {
        let visibleFrame = screen.visibleFrame
        var frame = window.frame
        
        if frame.maxX > visibleFrame.maxX {
            frame.origin.x = visibleFrame.maxX - frame.width
        }
        if frame.minX < visibleFrame.minX {
            frame.origin.x = visibleFrame.minX
        }
        
        if frame.minY < visibleFrame.minY {
            frame.origin.y = visibleFrame.minY
        }
        if frame.maxY > visibleFrame.maxY {
            frame.origin.y = visibleFrame.maxY - frame.height
        }
        
        window.setFrame(frame, display: false)
    }
    
    @objc private func openPenAI() {
        if !isOnline || !isLoggedIn {
            return
        }
        
        if let window = window {
            if window.isVisible {
                positionWindowRelativeToMouseCursor(window)
                
                Task {
                    await penWindowService?.initiatePen()
                }
                
                window.makeKeyAndOrderFront(nil)
            } else {
                closeOtherWindows()
                
                positionWindowRelativeToMouseCursor(window)
                
                Task {
                    await penWindowService?.initiatePen()
                }
                
                window.showAndFocus()
            }
        }
    }
    
    func toggleMainWindow() {
        if !isOnline || !isLoggedIn {
            return
        }
        
        if window == nil {
            createMainWindow()
        }
        
        if let window = window {
            if window.isVisible {
                positionWindowRelativeToMouseCursor(window)
                
                Task {
                    await penWindowService?.initiatePen()
                }
                
                window.makeKeyAndOrderFront(nil)
            } else {
                closeOtherWindows()
                
                positionWindowRelativeToMouseCursor(window)
                
                Task {
                    await penWindowService?.initiatePen()
                }
                
                window.showAndFocus()
            }
        }
    }
    
    @objc private func closeWindow() {
        window?.orderOut(nil)
    }
    
    @objc func openLoginWindow() {
        closeOtherWindows()
        
        if loginWindow == nil {
            loginWindow = LoginWindow(menuBarIconFrame: nil, penDelegate: self)
        }
        
        if let window = loginWindow {
            positionWindowRelativeToMenuBarIcon(window)
            window.showAndFocus()
        }
    }
    
    /// Sets the app mode and updates the UI accordingly
    func setAppMode(_ mode: AppMode, showPopup: Bool = true) {
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
        if mode == .onlineLogout && showPopup {
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
        print("PenDelegate: loadAndTestAIConfigurations called for user \(user.name) with email \(user.email)")
        Task.detached {
            do {
                // Load all AI configurations for the user
                guard let aiManager = UserService.shared.aiManager else {
                    print("PenDelegate: AIManager not initialized")
                    return
                }
                let configurations = try await aiManager.getConnections(for: user.id)
                
                if configurations.isEmpty {
                    try await Task.sleep(nanoseconds: 3_300_000_000)
                    WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "no_ai_configuration"))
                } else {
                    for (index, configuration) in configurations.enumerated() {
                        do {
                            let _ = try await aiManager.testConnection(
                                apiKey: configuration.apiKey,
                                providerName: configuration.apiProvider
                            )
                        } catch {
                        }
                    }
                }
            } catch {
            }
        }
    }
    
    /// Sets the login status and updates the menu bar icon
    func setLoginStatus(_ loggedIn: Bool, user: User? = nil, userName: String = "") {
        isLoggedIn = loggedIn
        if let user = user {
            self.userName = user.name
            self.currentUser = user
            UserService.shared.login(user: user)
        } else if !userName.isEmpty {
            self.userName = userName
        } else if !loggedIn {
            self.userName = ""
            self.currentUser = nil
            UserService.shared.logout()
        }
        
        updateStatusIcon(online: isOnline)
        updateWindowTitle()
        
        // Wait until menu bar icon is fully loaded before displaying popup message
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                // Display appropriate popup message
                if loggedIn {
                    let greeting = LocalizationService.shared.localizedString(for: "hello_user", withFormat: self?.userName ?? "")
                    self?.displayPopupMessage(greeting)
                    
                    // Update user label in Pen window to show profile image
                    self?.penWindowService?.updateUserLabel()
                } else {
                    // Don't display hello_guest message here, as we'll show the logout message in the logout() method
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
        windowManager.displayPopupMessage(message)
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
    
    /// Handles paste button click
    @objc private func handlePasteButton() {
        print("PenDelegate: Paste button clicked")
        // Implement paste functionality here
        // For now, we'll just print a message
    }

}

// Main function is handled by @main attribute
