import Cocoa

class ForgotPasswordWindow: BaseWindow {
    // MARK: - Properties
    private let windowWidth: CGFloat = 258
    private let windowHeight: CGFloat = 130
    private weak var penDelegate: PenDelegate?
    
    // UI Elements
    private var emailField: NSTextField!
    private var sendResetLinkButton: NSButton!
    private var cancelButton: NSButton!
    
    // MARK: - Initialization
    init(penDelegate: PenDelegate, loginWindow: NSWindow) {
        self.penDelegate = penDelegate
        
        // Calculate login window center
        let loginWindowFrame = loginWindow.frame
        let loginWindowCenterX = loginWindowFrame.origin.x + loginWindowFrame.size.width / 2
        let loginWindowCenterY = loginWindowFrame.origin.y + loginWindowFrame.size.height / 2
        
        // Calculate forgot password window origin to center it on login window
        let originX = loginWindowCenterX - windowWidth / 2
        let originY = loginWindowCenterY - windowHeight / 2
        
        super.init(
            contentRect: NSRect(x: originX, y: originY, width: windowWidth, height: windowHeight),
            styleMask: [.borderless]
        )
        
        // Create content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = ColorService.shared.backgroundColorCGColor
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
        
        // Add border
        contentView.layer?.borderWidth = 1.0
        contentView.layer?.borderColor = NSColor.separatorColor.cgColor
        
        // Add shadow (matching delete confirmation dialog style)
        let shadow = NSShadow()
        shadow.shadowColor = ColorService.shared.shadowColor.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -3)
        shadow.shadowBlurRadius = 8
        
        // Apply shadow to window
        hasShadow = true
        
        // Add UI elements
        setupUI(in: contentView)
        
        // Set content view
        self.contentView = contentView
        
        // Get mouse location for positioning
        let currentMouseLocation = NSEvent.mouseLocation
        
        // Clamp window to screen bounds
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(currentMouseLocation) }) ?? NSScreen.main {
            let visibleFrame = screen.visibleFrame
            var frame = self.frame
            
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
            setFrame(frame, display: false)
        }
        
        // Set initial first responder to email field
        self.customInitialFirstResponder = emailField
        
        // Recalculate key view loop for proper tab navigation
        recalculateKeyViewLoop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI(in contentView: NSView) {
        // Add title label
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: windowHeight - 30, width: windowWidth - 40, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "forgot_password_window_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)
        
        // Add email field
        emailField = NSTextField(frame: NSRect(x: 20, y: windowHeight - 75, width: windowWidth - 40, height: 25))
        emailField.placeholderString = LocalizationService.shared.localizedString(for: "enter_email_placeholder")
        emailField.backgroundColor = NSColor.textBackgroundColor
        contentView.addSubview(emailField)
        
        // Add send button (now on the left)
        sendResetLinkButton = NSButton(frame: NSRect(x: 26, y: 10, width: 90, height: 32))
        sendResetLinkButton.title = LocalizationService.shared.localizedString(for: "send_button")
        sendResetLinkButton.bezelStyle = .rounded
        sendResetLinkButton.layer?.borderWidth = 1.0
        sendResetLinkButton.layer?.borderColor = NSColor.systemGreen.cgColor
        sendResetLinkButton.layer?.cornerRadius = 6.0
        sendResetLinkButton.target = self
        sendResetLinkButton.action = #selector(sendResetLink)
        contentView.addSubview(sendResetLinkButton)
        
        // Add cancel button
        cancelButton = NSButton(frame: NSRect(x: 142, y: 10, width: 90, height: 32))
        cancelButton.title = LocalizationService.shared.localizedString(for: "cancel_button")
        cancelButton.bezelStyle = .rounded
        cancelButton.layer?.borderWidth = 1.0
        cancelButton.layer?.borderColor = NSColor.systemGray.cgColor
        cancelButton.layer?.cornerRadius = 6.0
        cancelButton.target = self
        cancelButton.action = #selector(cancel)
        contentView.addSubview(cancelButton)
        
        // Set tab order
        emailField.nextKeyView = sendResetLinkButton
        sendResetLinkButton.nextKeyView = cancelButton
        cancelButton.nextKeyView = emailField
    }
    
    // MARK: - Actions
    @objc private func sendResetLink() {
        let email = emailField.stringValue
        
        // Validate email
        if !isValidEmail(email) {
            showErrorMessage(LocalizationService.shared.localizedString(for: "invalid_email_error"))
            return
        }
        
        // Disable buttons and show sending state
        DispatchQueue.main.async {
            self.sendResetLinkButton.isEnabled = false
            self.sendResetLinkButton.title = LocalizationService.shared.localizedString(for: "sending_button")
            self.cancelButton.isEnabled = false
        }
        
        // Send reset link
        let authService = AuthenticationService.shared
        
        Task {
            let (result, errorType) = await authService.sendPasswordResetEmail(email: email)
            
            // Re-enable buttons
            DispatchQueue.main.async {
                self.sendResetLinkButton.isEnabled = true
                self.sendResetLinkButton.title = LocalizationService.shared.localizedString(for: "send_button")
                self.cancelButton.isEnabled = true
                
                if result {
                    // Show success message using standard pop-up
                    self.displayPopupMessage(LocalizationService.shared.localizedString(for: "reset_password_email_sent"))
                    
                    // Close forgot password window after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.orderOut(nil)
                    }
                } else {
                    // Show specific error message based on error type
                    var errorMessage: String
                    if let errorType = errorType {
                        switch errorType {
                        case "user_not_found":
                            errorMessage = LocalizationService.shared.localizedString(for: "user_not_found_error")
                        case "password_update_failed":
                            errorMessage = LocalizationService.shared.localizedString(for: "password_update_failed_error")
                        case "email_send_failed":
                            errorMessage = LocalizationService.shared.localizedString(for: "email_send_failed_error")
                        default:
                            errorMessage = LocalizationService.shared.localizedString(for: "failed_to_send_reset_password_email")
                        }
                    } else {
                        errorMessage = LocalizationService.shared.localizedString(for: "failed_to_send_reset_password_email")
                    }
                    self.displayPopupMessage(errorMessage)
                }
            }
        }
    }
    
    @objc private func cancel() {
        orderOut(nil)
    }
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func showErrorMessage(_ message: String) {
        let alert = NSAlert()
        alert.messageText = LocalizationService.shared.localizedString(for: "error_title")
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: LocalizationService.shared.localizedString(for: "ok_button"))
        alert.beginSheetModal(for: self) { _ in }
    }
    
    private func showSuccessMessage(_ message: String) {
        let alert = NSAlert()
        alert.messageText = LocalizationService.shared.localizedString(for: "success_title")
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: LocalizationService.shared.localizedString(for: "ok_button"))
        alert.beginSheetModal(for: self) { _ in }
    }
    

}