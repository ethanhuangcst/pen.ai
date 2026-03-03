import Cocoa

class ForgotPasswordWindow: BaseWindow {
    // MARK: - Properties
    private let windowWidth: CGFloat = 400
    private let windowHeight: CGFloat = 200
    private weak var penDelegate: PenDelegate?
    
    // UI Elements
    private var emailField: NSTextField!
    private var sendResetLinkButton: FocusableButton!
    private var cancelButton: FocusableButton!
    
    // MARK: - Initialization
    init(penDelegate: PenDelegate) {
        self.penDelegate = penDelegate
        super.init(contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), styleMask: [.titled, .closable])
        
        // Set window properties
        title = LocalizationService.shared.localizedString(for: "forgot_password_window_title")
        isReleasedWhenClosed = false
        center()
        setContentSize(NSSize(width: windowWidth, height: windowHeight))
        hasShadow = true
        
        // Create content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Add UI elements
        setupUI(in: contentView)
        
        // Set content view
        self.contentView = contentView
        
        // Recalculate key view loop for proper tab navigation
        recalculateKeyViewLoop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI(in contentView: NSView) {
        // Add email label
        let emailLabel = NSTextField(frame: NSRect(x: 40, y: windowHeight - 80, width: 100, height: 20))
        emailLabel.stringValue = LocalizationService.shared.localizedString(for: "email_label")
        emailLabel.isBezeled = false
        emailLabel.drawsBackground = false
        emailLabel.isEditable = false
        emailLabel.isSelectable = false
        contentView.addSubview(emailLabel)
        
        // Add email field
        emailField = NSTextField(frame: NSRect(x: 140, y: windowHeight - 80, width: 220, height: 25))
        emailField.placeholderString = LocalizationService.shared.localizedString(for: "enter_email_placeholder")
        emailField.backgroundColor = NSColor.textBackgroundColor
        contentView.addSubview(emailField)
        
        // Add send reset link button
        sendResetLinkButton = FocusableButton(frame: NSRect(x: 100, y: 40, width: 120, height: 30))
        sendResetLinkButton.title = LocalizationService.shared.localizedString(for: "send_reset_link_button")
        sendResetLinkButton.bezelStyle = .rounded
        sendResetLinkButton.target = self
        sendResetLinkButton.action = #selector(sendResetLink)
        contentView.addSubview(sendResetLinkButton)
        
        // Add cancel button
        cancelButton = FocusableButton(frame: NSRect(x: 220, y: 40, width: 80, height: 30))
        cancelButton.title = LocalizationService.shared.localizedString(for: "cancel_button")
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancel)
        contentView.addSubview(cancelButton)
        
        // Set tab order
        emailField.nextKeyView = sendResetLinkButton
        sendResetLinkButton.nextKeyView = cancelButton
        cancelButton.nextKeyView = emailField
        
        // Add standard close button
        addStandardCloseButton(to: contentView, windowWidth: windowWidth, windowHeight: windowHeight)
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
                    
                    // Open login window
                    if let penDelegate = self.penDelegate {
                        let loginWindow = LoginWindow(penDelegate: penDelegate)
                        loginWindow.showAndFocus()
                    }
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