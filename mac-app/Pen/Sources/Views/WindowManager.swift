import Cocoa

class WindowManager {
    static let shared = WindowManager()
    
    private var windows: [NSWindow: String] = [:]
    
    private init() {}
    
    // Register a window with a unique identifier
    func registerWindow(_ window: NSWindow, withIdentifier identifier: String) {
        windows[window] = identifier
    }
    
    // Unregister a window
    func unregisterWindow(_ window: NSWindow) {
        windows.removeValue(forKey: window)
    }
    
    // Get all windows with a specific identifier
    func getWindows(withIdentifier identifier: String) -> [NSWindow] {
        return windows.filter { $0.value == identifier }.map { $0.key }
    }
    
    // Check if a window with specific identifier is open
    func isWindowOpen(withIdentifier identifier: String) -> Bool {
        return !getWindows(withIdentifier: identifier).isEmpty
    }
    
    // Get the first window with specific identifier
    func getWindow(withIdentifier identifier: String) -> NSWindow? {
        return getWindows(withIdentifier: identifier).first
    }
    
    // Close all windows with specific identifier
    func closeWindows(withIdentifier identifier: String) {
        getWindows(withIdentifier: identifier).forEach { $0.close() }
    }
    
    // Close all windows
    func closeAllWindows() {
        windows.keys.forEach { $0.close() }
    }
    
    /// Displays a global popup message following the specified design guidelines
    func displayPopupMessage(_ message: String) {
        // Ensure all UI operations are on the main thread
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
            // Get the status item from the app delegate
            guard let appDelegate = NSApplication.shared.delegate as? PenDelegate,
                  let button = appDelegate.statusItem?.button,
                  let buttonWindow = button.window else {
                // Fallback to center position if status item isn't available
                popupWindow.center()
                return
            }
            
            let screen = NSScreen.main!
            let screenHeight = screen.frame.height
            let menuBarHeight = screen.frame.height - screen.visibleFrame.height
            let spacing: CGFloat = 6
            let windowSize = popupWindow.frame.size
            
            // Get the button's frame in screen coordinates
            let buttonFrame = button.convert(button.bounds, to: nil)
            let buttonScreenFrame = buttonWindow.convertToScreen(buttonFrame)
            
            // Check if button screen frame is valid (not negative or zero-sized)
            if buttonScreenFrame.minY < 0 || buttonScreenFrame.width == 0 || buttonScreenFrame.height == 0 {
                // Use center position if button frame is invalid
                popupWindow.center()
                return
            }
            
            // Calculate position relative to menu bar icon
            // X position: Pen icon X + 6px
            let x = buttonScreenFrame.minX + spacing
            // Y position: top of screen - menu bar height - spacing - window height
            let y = screenHeight - menuBarHeight - spacing - windowSize.height
            
            // Set window position
            popupWindow.setFrameOrigin(NSPoint(x: x, y: y))
            
            // Ensure window is on the same screen as the menu bar icon
            if buttonWindow.screen != nil {
                popupWindow.setFrame(popupWindow.frame, display: false, animate: false)
            }
            
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