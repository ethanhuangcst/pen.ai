import Cocoa

// Import LocalizationService for i18n support
import Foundation



class BaseWindow: NSWindow {
    // MARK: - Properties
    private let defaultMainWindowWidth: CGFloat = 600
    
    // MARK: - Initialization
    init(contentRect: NSRect, styleMask: NSWindow.StyleMask = .borderless) {
        // Use the provided style mask or default to borderless
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties for keyboard input
        configureWindowProperties()
    }
    
    /// Convenience initializer to create a window with a specific size
    init(size: NSSize, styleMask: NSWindow.StyleMask = .borderless) {
        let contentRect = NSRect(origin: .zero, size: size)
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties for keyboard input
        configureWindowProperties()
    }
    
    /// Creates a standard window with all common UI behaviors
    static func createStandardWindow(size: NSSize, title: String? = nil) -> BaseWindow {
        let window = BaseWindow(size: size)
        
        // Create standard content view
        let contentView = window.createStandardContentView(size: size)
        
        // Add title if provided
        if let title = title {
            let titleLabel = NSTextField(frame: NSRect(x: 70, y: size.height - 55, width: size.width - 90, height: 30))
            titleLabel.stringValue = title
            titleLabel.isBezeled = false
            titleLabel.drawsBackground = false
            titleLabel.isEditable = false
            titleLabel.isSelectable = false
            titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
            contentView.addSubview(titleLabel)
        }
        
        // Add PenAI logo
        window.addPenAILogo(to: contentView, windowHeight: size.height)
        
        // Add standard close button
        window.addStandardCloseButton(to: contentView, windowWidth: size.width, windowHeight: size.height)
        
        // Set content view
        window.contentView = contentView
        
        // Recalculate key view loop for borderless window
        window.recalculateKeyViewLoop()
        
        return window
    }
    
    // MARK: - Private Methods
    private func configureWindowProperties() {
        // Ensure the window can become key and main for keyboard input
        isMovable = true
        isMovableByWindowBackground = true
        isOpaque = false
        backgroundColor = .clear
        level = .floating // Ensure window is always in front
        collectionBehavior = .canJoinAllSpaces
        
        // Ensure window can receive events
        isReleasedWhenClosed = false
        canBecomeVisibleWithoutLogin = true
        
        // Disable toolbar
        toolbar = nil
        showsToolbarButton = false
    }
    
    /// Creates a standard content view with consistent visual styling
    func createStandardContentView(size: NSSize) -> NSView {
        let contentView = NSView(frame: NSRect(origin: .zero, size: size))
        contentView.wantsLayer = true
        
        // Set light mode background color
        if let layer = contentView.layer {
            layer.backgroundColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor // Light background (white)
        }
        
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
        
        // Add shadow effect
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -3)
        shadow.shadowBlurRadius = 8
        
        // Apply shadow to window
        hasShadow = true
        
        // Add hover effects to interactive elements
        addHoverEffects(to: contentView)
        
        return contentView
    }
    
    /// Adds hover effects to all interactive elements in the view hierarchy
    private func addHoverEffects(to view: NSView) {
        for subview in view.subviews {
            if let button = subview as? NSButton {
                // Add hover effect for buttons
                button.wantsLayer = true
                button.layer?.backgroundColor = NSColor.clear.cgColor
                
                // Make button accept first responder so it can be included in tab order
                button.setAccessibilityElement(true)
                button.setAccessibilityRole(.button)
                
                // Add tracking area for hover detection
                let trackingArea = NSTrackingArea(
                    rect: button.bounds,
                    options: [.mouseEnteredAndExited, .activeAlways],
                    owner: button,
                    userInfo: nil
                )
                button.addTrackingArea(trackingArea)
                
                // Set up hover behavior - don't override existing actions
                // Only add hover effects, not change the action
            } else if let textField = subview as? NSTextField, textField.isEditable {
                // Add hover effect for text fields
                textField.wantsLayer = true
                textField.layer?.borderWidth = 1.0
                textField.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
                textField.layer?.cornerRadius = 4.0
            }
            
            // Recursively add hover effects to subviews
            addHoverEffects(to: subview)
        }
    }
    
    /// Sets up a button to be focusable and included in tab order
    func makeButtonFocusable(_ button: NSButton) {
        button.setAccessibilityElement(true)
        button.setAccessibilityRole(.button)
    }
    
    /// Adds a standard close button to the window
    func addStandardCloseButton(to contentView: NSView, windowWidth: CGFloat, windowHeight: CGFloat) {
        let closeButton = FocusableButton(frame: NSRect(x: windowWidth - 30, y: windowHeight - 30, width: 20, height: 20))
        closeButton.title = ""
        closeButton.bezelStyle = .smallSquare
        closeButton.isBordered = false
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.isEnabled = true // Make close button enabled by default
        closeButton.state = .off // Ensure close button is not selected
        
        // Add hover effect to close button
        closeButton.wantsLayer = true
        closeButton.layer?.backgroundColor = NSColor.clear.cgColor
        let trackingArea = NSTrackingArea(
            rect: closeButton.bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: closeButton,
            userInfo: nil
        )
        closeButton.addTrackingArea(trackingArea)
        
        contentView.addSubview(closeButton)
    }
    
    /// Adds the PenAI logo to the window
    func addPenAILogo(to contentView: NSView, windowHeight: CGFloat) {
        let logoPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/logo.png"
        if let logo = NSImage(contentsOfFile: logoPath) {
            let logoSize: CGFloat = 38
            let logoView = NSImageView(frame: NSRect(x: 20, y: windowHeight - 55, width: logoSize, height: logoSize))
            logoView.image = logo
            contentView.addSubview(logoView)
        }
    }
    
    /// Closes the window
    @objc func closeWindow() {
        orderOut(nil)
    }
    
    // MARK: - Overrides
    // Override to ensure the window can become key
    override var canBecomeKey: Bool { true }
    
    // Override to ensure the window can become main
    override var canBecomeMain: Bool { true }
    
    // Override to handle Enter key press for active UI controls
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 { // Enter key
            if let firstResponder = self.firstResponder {
                // If it's a text field, let it handle the Enter key
                if firstResponder is NSTextField {
                    super.keyDown(with: event)
                    return
                }
                // If it's a control with an action, trigger it
                if let control = firstResponder as? NSControl, let action = control.action {
                    NSApp.sendAction(action, to: nil, from: control)
                    return
                }
            }
        }
        super.keyDown(with: event)
    }
    

    

    
    // MARK: - Public Methods
    /// Makes the window visible, brings it to front, and sets focus to the first input field
    func showAndFocus() {
        // Set activation policy and install main menu for system shortcuts
        NSApp.setActivationPolicy(.regular)
        WindowManager.installMainMenu()
        
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        
        // Delay setting first responder to ensure window is fully ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setFirstResponderToFirstFocusableElement()
        }
    }
    
    /// Sets the first responder to the first focusable UI element in the window
    private func setFirstResponderToFirstFocusableElement() {
        // Traverse the view hierarchy to find the first focusable UI element
        if let firstElement = findFirstFocusableElement(in: contentView) {
            self.makeFirstResponder(firstElement)
        }
    }
    
    /// Recursively finds the first focusable UI element in a view hierarchy
    private func findFirstFocusableElement(in view: NSView?) -> NSView? {
        guard let view = view else { return nil }
        
        // First pass: find only text fields
        for subview in view.subviews {
            if let textField = subview as? NSTextField, textField.isEditable, textField.acceptsFirstResponder {
                return textField
            }
            if let focusableElement = findFirstFocusableElement(in: subview) {
                return focusableElement
            }
        }
        
        // Second pass: if no text fields found, look for other focusable elements except close buttons
        for subview in view.subviews {
            if subview.acceptsFirstResponder, !(subview is NSButton) {
                return subview
            }
            if let focusableElement = findFirstFocusableElement(in: subview) {
                return focusableElement
            }
        }
        
        return nil
    }
    
    /// Positions the window relative to the menu bar icon
    func positionRelativeToMenuBarIcon() {
        WindowManager.positionWindowRelativeToMenuBarIcon(self)
    }
    
    /// Displays a popup message with the global design style
    func displayPopupMessage(_ message: String) {
        WindowManager.displayPopupMessage(message)
    }
    
    /// Finds the first active (enabled) button in the view hierarchy
    private func findFirstActiveButton(in view: NSView) -> NSButton? {
        for subview in view.subviews {
            if let button = subview as? NSButton, button.isEnabled {
                return button
            }
            if let foundButton = findFirstActiveButton(in: subview) {
                return foundButton
            }
        }
        return nil
    }
    
    /// Returns the default main window width
    func getDefaultMainWindowWidth() -> CGFloat {
        return defaultMainWindowWidth
    }
    
    /// Default action for buttons (can be overridden)
    @objc func buttonAction() {
        // Default implementation does nothing
    }
    
    /// Convenience method to get localized strings
    func localizedString(for key: String, comment: String = "") -> String {
        return LocalizationService.shared.localizedString(for: key, comment: comment)
    }
    
    /// Convenience method to get localized strings with format
    func localizedString(for key: String, withFormat arguments: CVarArg..., comment: String = "") -> String {
        return LocalizationService.shared.localizedString(for: key, withFormat: arguments, comment: comment)
    }
    
    /// Action for Button 1 to display a pop-up message
    @objc func button1Action() {
        displayPopupMessage(localizedString(for: "test_popup_message"))
    }
    
    /// Creates a test window with typical UI controls for testing
    static func createTestWindow() -> BaseWindow {
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 400
        let windowSize = NSSize(width: windowWidth, height: windowHeight)
        
        // Create standard window with common UI behaviors
        let window = BaseWindow.createStandardWindow(size: windowSize, title: "UI Controls Test")
        
        // Get the content view from the window
        guard let contentView = window.contentView else { return window }
        
        // Text Fields
        let textField1 = NSTextField(frame: NSRect(x: 80, y: windowHeight - 100, width: 240, height: 24))
        textField1.placeholderString = "Text Field 1"
        contentView.addSubview(textField1)
        
        let textField2 = NSTextField(frame: NSRect(x: 80, y: windowHeight - 140, width: 240, height: 24))
        textField2.placeholderString = "Text Field 2"
        contentView.addSubview(textField2)
        
        let textField3 = NSTextField(frame: NSRect(x: 80, y: windowHeight - 180, width: 240, height: 24))
        textField3.placeholderString = "Text Field 3"
        contentView.addSubview(textField3)
        
        // Labels for text fields
        let label1 = NSTextField(frame: NSRect(x: 20, y: windowHeight - 100, width: 60, height: 24))
        label1.stringValue = "Field 1:"
        label1.isBezeled = false
        label1.drawsBackground = false
        label1.isEditable = false
        label1.isSelectable = false
        contentView.addSubview(label1)
        
        let label2 = NSTextField(frame: NSRect(x: 20, y: windowHeight - 140, width: 60, height: 24))
        label2.stringValue = "Field 2:"
        label2.isBezeled = false
        label2.drawsBackground = false
        label2.isEditable = false
        label2.isSelectable = false
        contentView.addSubview(label2)
        
        let label3 = NSTextField(frame: NSRect(x: 20, y: windowHeight - 180, width: 60, height: 24))
        label3.stringValue = "Field 3:"
        label3.isBezeled = false
        label3.drawsBackground = false
        label3.isEditable = false
        label3.isSelectable = false
        contentView.addSubview(label3)
        
        // Check Boxes
        let checkbox1 = FocusableButton(frame: NSRect(x: 80, y: windowHeight - 230, width: 200, height: 24))
        checkbox1.setButtonType(.switch)
        checkbox1.title = "Check Box 1"
        contentView.addSubview(checkbox1)
        
        let checkbox2 = FocusableButton(frame: NSRect(x: 80, y: windowHeight - 260, width: 200, height: 24))
        checkbox2.setButtonType(.switch)
        checkbox2.title = "Check Box 2"
        contentView.addSubview(checkbox2)
        
        // Radio Buttons
        let radio1 = FocusableButton(frame: NSRect(x: 80, y: windowHeight - 310, width: 100, height: 24))
        radio1.setButtonType(.radio)
        radio1.title = "Radio 1"
        contentView.addSubview(radio1)
        
        let radio2 = FocusableButton(frame: NSRect(x: 200, y: windowHeight - 310, width: 100, height: 24))
        radio2.setButtonType(.radio)
        radio2.title = "Radio 2"
        contentView.addSubview(radio2)
        
        // Buttons
        let button1 = FocusableButton(frame: NSRect(x: 80, y: 40, width: 120, height: 32))
        button1.title = "Button 1"
        button1.bezelStyle = .rounded
        button1.target = window
        button1.action = #selector(BaseWindow.button1Action)
        contentView.addSubview(button1)
        
        let button2 = FocusableButton(frame: NSRect(x: 200, y: 40, width: 120, height: 32))
        button2.title = "Button 2"
        button2.bezelStyle = .rounded
        button2.target = window
        button2.action = #selector(BaseWindow.buttonAction)
        contentView.addSubview(button2)
        
        // Set up tab order
        textField1.nextKeyView = textField2
        textField2.nextKeyView = textField3
        textField3.nextKeyView = checkbox1
        checkbox1.nextKeyView = checkbox2
        checkbox2.nextKeyView = radio1
        radio1.nextKeyView = radio2
        radio2.nextKeyView = button1
        button1.nextKeyView = button2
        button2.nextKeyView = textField1
        
        // Set initial first responder for borderless window
        window.initialFirstResponder = textField1
        
        // Add standard close button
        window.addStandardCloseButton(to: contentView, windowWidth: windowWidth, windowHeight: windowHeight)
        
        // Set content view
        window.contentView = contentView
        
        // Recalculate key view loop for borderless window
        window.recalculateKeyViewLoop()
        
        return window
    }
}

class WindowManager {
    // MARK: - Static Methods
    
    /// Installs the main menu with Edit actions for system shortcuts
    static func installMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(
            withTitle: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")

        editMenu.addItem(withTitle: "Undo",
                         action: Selector(("undo:")),
                         keyEquivalent: "z")

        editMenu.addItem(withTitle: "Redo",
                         action: Selector(("redo:")),
                         keyEquivalent: "Z")

        editMenu.addItem(.separator())

        editMenu.addItem(withTitle: "Cut",
                         action: #selector(NSText.cut(_:)),
                         keyEquivalent: "x")

        editMenu.addItem(withTitle: "Copy",
                         action: #selector(NSText.copy(_:)),
                         keyEquivalent: "c")

        editMenu.addItem(withTitle: "Paste",
                         action: #selector(NSText.paste(_:)),
                         keyEquivalent: "v")

        editMenu.addItem(withTitle: "Select All",
                         action: #selector(NSText.selectAll(_:)),
                         keyEquivalent: "a")

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }
    
    /// Positions a window relative to the Pen menu bar icon
    static func positionWindowRelativeToMenuBarIcon(_ window: NSWindow) {
        // Get the status item from the app delegate
        guard let appDelegate = NSApplication.shared.delegate as? PenAIDelegate,
              let button = appDelegate.statusItem?.button,
              let buttonWindow = button.window else {
            // Fallback to default position if status item isn't available
            setDefaultWindowPosition(window)
            return
        }
        
        let screen = NSScreen.main!
        let screenHeight = screen.frame.height
        let menuBarHeight = screen.frame.height - screen.visibleFrame.height
        let spacing: CGFloat = 6
        let windowSize = window.frame.size
        
        // Get the button's frame in screen coordinates
        let buttonFrame = button.convert(button.bounds, to: nil)
        let buttonScreenFrame = buttonWindow.convertToScreen(buttonFrame)
        
        // Check if button screen frame is valid (not negative or zero-sized)
        if buttonScreenFrame.minY < 0 || buttonScreenFrame.width == 0 || buttonScreenFrame.height == 0 {
            // Use fallback position if button frame is invalid
            setDefaultWindowPosition(window)
            return
        }
        
        // Calculate position relative to menu bar icon
        // X position: Pen icon X + 6px
        let x = buttonScreenFrame.minX + spacing
        // Y position: top of screen - menu bar height - spacing - window height
        let y = screenHeight - menuBarHeight - spacing - windowSize.height
        
        // Set window position
        window.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Ensure window is on the same screen as the menu bar icon
        if buttonWindow.screen != nil {
            window.setFrame(window.frame, display: false, animate: false)
        }
    }
    
    /// Sets a default window position when menu bar icon is not available
    private static func setDefaultWindowPosition(_ window: NSWindow) {
        let screen = NSScreen.main!
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        let menuBarHeight = screen.frame.height - screen.visibleFrame.height
        
        let windowSize = window.frame.size
        let windowX = screenWidth - (screenWidth / 4) - windowSize.width
        let windowY = screenHeight - menuBarHeight - 6 - windowSize.height
        
        window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
    }
    
    /// Displays a global popup message following the specified design guidelines
    static func displayPopupMessage(_ message: String) {
        // Ensure UI operations are on the main thread
        DispatchQueue.main.async {
            // Calculate message size
            let sizeLabel = NSTextField()
            sizeLabel.stringValue = message
            sizeLabel.font = NSFont.systemFont(ofSize: 14)
            sizeLabel.sizeToFit()
            
            // Calculate window size (minimum 240x40, auto adjusts to content)
            let minWidth: CGFloat = 240
            let minHeight: CGFloat = 40
            let contentWidth = max(minWidth, sizeLabel.frame.width + 32) // 16px padding on each side
            let contentHeight = max(minHeight, sizeLabel.frame.height + 16) // 8px padding on each side
            
            // Create a window for the popup
            let popupWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight), 
                                      styleMask: [.borderless], 
                                      backing: .buffered, 
                                      defer: false)
            popupWindow.isOpaque = false
            popupWindow.backgroundColor = .clear
            popupWindow.level = .floating
            
            // Position popup relative to menu bar icon
            positionWindowRelativeToMenuBarIcon(popupWindow)
            
            // Create a container view with rounded corners and semi-transparent background
            let containerView = NSView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight))
            containerView.wantsLayer = true
            containerView.layer?.cornerRadius = 12
            // Use a different color from main window with 75% opacity
            containerView.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.75).cgColor
            
            // Add shadow effect
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
            shadow.shadowOffset = NSSize(width: 0, height: -2)
            shadow.shadowBlurRadius = 6
            containerView.shadow = shadow
            
            // Create a text field for the message
            let messageLabel = NSTextField(frame: NSRect(x: 16, y: 8, width: contentWidth - 32, height: contentHeight - 16))
            messageLabel.stringValue = message
            messageLabel.isBezeled = false
            messageLabel.drawsBackground = false
            messageLabel.isEditable = false
            messageLabel.isSelectable = false
            messageLabel.textColor = .white
            messageLabel.font = NSFont.systemFont(ofSize: 14)
            messageLabel.alignment = .center
            messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            // Add the label to the container
            containerView.addSubview(messageLabel)
            
            // Set the container as the window's content view
            popupWindow.contentView = containerView
            
            // Set initial alpha to 0 for fade-in effect
            popupWindow.alphaValue = 0.0
            
            // Show the popup
            popupWindow.makeKeyAndOrderFront(nil)
            
            // Fade in animation
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                popupWindow.animator().alphaValue = 1.0
            }
            
            // Hide the popup after 3 seconds with fade-out effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    popupWindow.animator().alphaValue = 0.0
                } completionHandler: {
                    popupWindow.orderOut(nil)
                }
            }
            
            print("WindowManager: Displayed popup message: \(message)")
        }
    }
}
