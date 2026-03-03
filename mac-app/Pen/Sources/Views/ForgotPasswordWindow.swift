import Cocoa

class ForgotPasswordWindow: BaseWindow {
    // MARK: - Properties
    private let windowWidth: CGFloat = 300
    private let windowHeight: CGFloat = 180
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
        contentView.layer?.backgroundColor = NSColor.white.cgColor
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
        
        // Add shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -3)
        shadow.shadowBlurRadius = 8
        
        // Add UI elements
        setupUI(in: contentView)
        
        // Set content view
        self.contentView = contentView
        
        // No need for screen clamping since we're centering on the login window
        
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
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: windowHeight - 40, width: windowWidth - 40, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "forgot_password_window_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)
        
        // Add email label
        let emailLabel = NSTextField(frame: NSRect(x: 20, y: windowHeight - 80, width: 80, height: 20))
        emailLabel.stringValue = LocalizationService.shared.localizedString(for: "email_label")
        emailLabel.isBezeled = false
        emailLabel.drawsBackground = false
        emailLabel.isEditable = false
        emailLabel.isSelectable = false
        contentView.addSubview(emailLabel)
        
        // Add email field
        emailField = NSTextField(frame: NSRect(x: 100, y: windowHeight - 80, width: 180, height: 25))
        emailField.placeholderString = LocalizationService.shared.localizedString(for: "enter_email_placeholder")
        emailField.backgroundColor = NSColor.textBackgroundColor
        contentView.addSubview(emailField)
        
        // Add send reset link button
        sendResetLinkButton = NSButton(frame: NSRect(x: 40, y: 30, width: 100, height: 32))
        sendResetLinkButton.title = LocalizationService.shared.localizedString(for: "send_reset_link_button")
        sendResetLinkButton.bezelStyle = .rounded
        sendResetLinkButton.layer?.borderWidth = 1.0
        sendResetLinkButton.layer?.borderColor = NSColor.systemGreen.cgColor
        sendResetLinkButton.layer?.cornerRadius = 6.0
        sendResetLinkButton.target = self
        sendResetLinkButton.action = #selector(sendResetLink)
        contentView.addSubview(sendResetLinkButton)
        
        // Add cancel button
        cancelButton = NSButton(frame: NSRect(x: 160, y: 30, width: 100, height: 32))
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
        
        // Send reset link
        let authService = AuthenticationService.shared
        
        Task {
            if await authService.sendPasswordResetEmail(email: email) {
                // Show success message
                DispatchQueue.main.async {
                    self.showSuccessMessage(LocalizationService.shared.localizedString(for: "reset_link_sent_success"))
                    
                    // Close forgot password window
                    self.orderOut(nil)
                }
            } else {
                // Show error message
                DispatchQueue.main.async {
                    self.showErrorMessage(LocalizationService.shared.localizedString(for: "reset_link_failed_error"))
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