import Cocoa

// Login window that inherits common behaviors from BaseWindow
class LoginWindow: BaseWindow, NSTextFieldDelegate {
    // MARK: - Properties
    private let windowWidth: CGFloat = 518
    private let windowHeight: CGFloat = 318
    private weak var penDelegate: PenDelegate?
    
    // UI Elements
    private var emailField: NSTextField!
    private var securePasswordField: NSSecureTextField!
    private var plainPasswordField: NSTextField!
    private var isPasswordSecure: Bool = true
    private var passwordToggleButton: FocusableButton!
    private var rememberMeCheckbox: FocusableButton!
    private var loginButton: FocusableButton!
    private var registerLink: FocusableButton!
    private var forgotPasswordLink: FocusableButton!
    
    // Public accessors for testing
    public var emailFieldPublic: NSTextField! { return emailField }
    public var securePasswordFieldPublic: NSSecureTextField! { return securePasswordField }
    public var plainPasswordFieldPublic: NSTextField! { return plainPasswordField }
    public var passwordToggleButtonPublic: FocusableButton! { return passwordToggleButton }
    public var rememberMeCheckboxPublic: FocusableButton! { return rememberMeCheckbox }
    public var loginButtonPublic: FocusableButton! { return loginButton }
    public var registerLinkPublic: FocusableButton! { return registerLink }
    public var forgotPasswordLinkPublic: FocusableButton! { return forgotPasswordLink }
    
    // MARK: - Initialization
    init(menuBarIconFrame: NSRect? = nil, penDelegate: PenDelegate? = nil) {
        let windowSize = NSSize(width: windowWidth, height: windowHeight)
        super.init(size: windowSize)
        
        // Disable toolbar
        toolbar = nil
        showsToolbarButton = false
        
        // Set pen delegate
        self.penDelegate = penDelegate
        
        // Position the window relative to the menu bar icon
        positionRelativeToMenuBarIcon()
        
        // Set up content view
        setupContentView()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the content view with all UI elements
    private func setupContentView() {
        // Create standard content view with consistent styling
        let contentView = createStandardContentView(size: NSSize(width: windowWidth, height: windowHeight))
        
        // Add PenAI logo
        addPenAILogo(to: contentView, windowHeight: windowHeight)
        
        // Add title
        let titleLabel = NSTextField(frame: NSRect(x: 70, y: windowHeight - 55, width: 200, height: 30))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_ai_login")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        contentView.addSubview(titleLabel)
        
        // Add email label
        let emailLabel = NSTextField(frame: NSRect(x: 40, y: windowHeight - 120, width: 100, height: 20))
        emailLabel.stringValue = LocalizationService.shared.localizedString(for: "email_label")
        emailLabel.isBezeled = false
        emailLabel.drawsBackground = false
        emailLabel.isEditable = false
        emailLabel.isSelectable = false
        contentView.addSubview(emailLabel)
        
        // Add email text field
        emailField = NSTextField(frame: NSRect(x: 140, y: windowHeight - 120, width: 260, height: 25))
        emailField.placeholderString = LocalizationService.shared.localizedString(for: "enter_email_placeholder")
        // Set background to system text background color
        emailField.backgroundColor = NSColor.textBackgroundColor
        emailField.delegate = self
        contentView.addSubview(emailField)
        
        // Add password label
        let passwordLabel = NSTextField(frame: NSRect(x: 40, y: windowHeight - 160, width: 100, height: 20))
        passwordLabel.stringValue = LocalizationService.shared.localizedString(for: "password_label")
        passwordLabel.isBezeled = false
        passwordLabel.drawsBackground = false
        passwordLabel.isEditable = false
        passwordLabel.isSelectable = false
        contentView.addSubview(passwordLabel)
        
        // Add secure password field
        securePasswordField = NSSecureTextField(frame: NSRect(x: 140, y: windowHeight - 160, width: 260, height: 25))
        securePasswordField.placeholderString = LocalizationService.shared.localizedString(for: "enter_password_placeholder")
        // Set background to system text background color
        securePasswordField.backgroundColor = NSColor.textBackgroundColor
        securePasswordField.delegate = self
        contentView.addSubview(securePasswordField)
        
        // Add plain password field (initially hidden)
        plainPasswordField = NSTextField(frame: NSRect(x: 140, y: windowHeight - 160, width: 260, height: 25))
        plainPasswordField.placeholderString = LocalizationService.shared.localizedString(for: "enter_password_placeholder")
        // Set background to system text background color
        plainPasswordField.backgroundColor = NSColor.textBackgroundColor
        plainPasswordField.delegate = self
        plainPasswordField.isHidden = true
        contentView.addSubview(plainPasswordField)
        
        // Add password toggle button (18px)
        passwordToggleButton = FocusableButton(frame: NSRect(x: 405, y: windowHeight - 160, width: 18, height: 18))
        passwordToggleButton.title = ""
        passwordToggleButton.bezelStyle = .smallSquare
        passwordToggleButton.isBordered = false
        
        let iconPath = ResourceService.shared.getResourcePath(relativePath: "Assets/hidden.svg")
        if let originalImage = NSImage(contentsOfFile: iconPath) {
            let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
            resizedImage.lockFocus()
            originalImage.draw(in: NSRect(origin: .zero, size: NSSize(width: 18, height: 18)), from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
            resizedImage.unlockFocus()
            passwordToggleButton.image = resizedImage
        }
        
        passwordToggleButton.target = self
        passwordToggleButton.action = #selector(togglePasswordVisibility)
        contentView.addSubview(passwordToggleButton)
        
        // Add remember me checkbox
        rememberMeCheckbox = FocusableButton(frame: NSRect(x: 140, y: windowHeight - 200, width: 200, height: 20))
        rememberMeCheckbox.setButtonType(.switch)
        rememberMeCheckbox.title = LocalizationService.shared.localizedString(for: "remember_me")
        rememberMeCheckbox.target = self
        rememberMeCheckbox.action = #selector(rememberMeToggled)
        contentView.addSubview(rememberMeCheckbox)
        
        // Add login button
        loginButton = FocusableButton(frame: NSRect(x: 190, y: windowHeight - 240, width: 140, height: 30))
        loginButton.title = LocalizationService.shared.localizedString(for: "login_button")
        loginButton.bezelStyle = .rounded
        loginButton.target = self
        loginButton.action = #selector(login)
        contentView.addSubview(loginButton)
        
        // Get localized strings
        let registerTitle = LocalizationService.shared.localizedString(for: "register_new_account")
        let forgotPasswordTitle = LocalizationService.shared.localizedString(for: "forgot_password")
        
        // Calculate text width for both buttons
        let font = NSFont.systemFont(ofSize: 13)
        let registerAttrString = NSAttributedString(string: registerTitle, attributes: [.font: font])
        let forgotPasswordAttrString = NSAttributedString(string: forgotPasswordTitle, attributes: [.font: font])
        
        let registerWidth = registerAttrString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20), options: .usesLineFragmentOrigin).width + 20 // Add padding
        let forgotPasswordWidth = forgotPasswordAttrString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20), options: .usesLineFragmentOrigin).width + 20 // Add padding
        
        // Set both buttons to the maximum width
        let buttonWidth = max(registerWidth, forgotPasswordWidth)
        let buttonHeight: CGFloat = 24
        let spacing: CGFloat = 20
        let totalWidth = buttonWidth * 2 + spacing
        
        // Calculate centered position
        let startX = (windowWidth - totalWidth) / 2
        
        // Add register button
        registerLink = FocusableButton(frame: NSRect(x: startX, y: 40, width: buttonWidth, height: buttonHeight))
        registerLink.title = registerTitle
        registerLink.bezelStyle = .rounded
        registerLink.isBordered = true
        registerLink.target = self
        registerLink.action = #selector(register)
        contentView.addSubview(registerLink)
        
        // Add forgot password button
        forgotPasswordLink = FocusableButton(frame: NSRect(x: startX + buttonWidth + spacing, y: 40, width: buttonWidth, height: buttonHeight))
        forgotPasswordLink.title = forgotPasswordTitle
        forgotPasswordLink.bezelStyle = .rounded
        forgotPasswordLink.isBordered = true
        forgotPasswordLink.target = self
        forgotPasswordLink.action = #selector(forgotPassword)
        contentView.addSubview(forgotPasswordLink)
        
        // Set tab order explicitly
        emailField.nextKeyView = securePasswordField
        securePasswordField.nextKeyView = rememberMeCheckbox
        rememberMeCheckbox.nextKeyView = loginButton
        loginButton.nextKeyView = registerLink
        registerLink.nextKeyView = forgotPasswordLink
        forgotPasswordLink.nextKeyView = emailField
        
        // Add standard close button
        addStandardCloseButton(to: contentView, windowWidth: windowWidth, windowHeight: windowHeight)
        
        // Set content view
        self.contentView = contentView
        
        // Set initial first responder to email field
        self.customInitialFirstResponder = emailField
        
        // Recalculate key view loop for proper tab navigation
        self.recalculateKeyViewLoop()
    }
    
    // MARK: - Public Methods
    
    /// Shows the window and ensures it receives focus and keyboard events
    override func showAndFocus() {
        // Use the BaseWindow's showAndFocus method
        super.showAndFocus()
    }
    
    // MARK: - Actions
    
    @objc private func togglePasswordVisibility() {
        // Toggle password visibility
        isPasswordSecure = !isPasswordSecure
        
        // Swap visibility of password fields
        securePasswordField.isHidden = !isPasswordSecure
        plainPasswordField.isHidden = isPasswordSecure
        
        // Sync text between fields
        if isPasswordSecure {
            securePasswordField.stringValue = plainPasswordField.stringValue
        } else {
            plainPasswordField.stringValue = securePasswordField.stringValue
        }
        
        // Update tab order based on which field is visible
        if isPasswordSecure {
            emailField.nextKeyView = securePasswordField
            securePasswordField.nextKeyView = rememberMeCheckbox
        } else {
            emailField.nextKeyView = plainPasswordField
            plainPasswordField.nextKeyView = rememberMeCheckbox
        }
        
        let iconName = isPasswordSecure ? "hidden" : "show"
        let iconPath = ResourceService.shared.getResourcePath(relativePath: "Assets/\(iconName).svg")
        if let originalImage = NSImage(contentsOfFile: iconPath) {
            let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
            resizedImage.lockFocus()
            originalImage.draw(in: NSRect(origin: .zero, size: NSSize(width: 18, height: 18)), from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
            resizedImage.unlockFocus()
            passwordToggleButton.image = resizedImage
        }
    }
    
    @objc private func login() {
        // Handle login logic
        let email = emailField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = isPasswordSecure ? securePasswordField.stringValue : plainPasswordField.stringValue
        let rememberMe = rememberMeCheckbox.state == .on
        
        Task {
            let authService = AuthenticationService.shared
            if let user = await authService.authenticate(email: email, password: password) {
                if rememberMe {
                    authService.storeCredentials(email: email, password: password)
                } else {
                    authService.clearCredentials()
                }

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.penDelegate?.setAppMode(.onlineLogin)
                    self.penDelegate?.updateMenuBarIcon()
                    self.penDelegate?.createGlobalUserObject(user: user)
                    self.orderOut(nil)
                }
                return
            }

            DispatchQueue.main.async {
                self.showErrorMessage(LocalizationService.shared.localizedString(for: "invalid_credentials"))
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        // Use BaseWindow's displayPopupMessage method
        displayPopupMessage(message)
    }
    
    @objc private func cancel() {
        closeWindow()
    }
    
    @objc private func register() {
        let registrationWindow = RegistrationWindow(penDelegate: penDelegate)
        registrationWindow.showAndFocus()
        self.orderOut(nil)
    }
    
    @objc private func forgotPassword() {
        let forgotPasswordWindow = ForgotPasswordWindow(penDelegate: penDelegate!, loginWindow: self)
        forgotPasswordWindow.showAndFocus()
    }
    
    @objc private func rememberMeToggled() {
        let _ = rememberMeCheckbox.state == .on
    }
    
    // MARK: - NSTextFieldDelegate
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            // Check if the return key was pressed
            if let reason = obj.userInfo?["NSTextMovement"] as? Int,
               reason == 1 { // 1 is the raw value for return key
                // Trigger login action when Enter is pressed
                login()
            }
        }
    }
}
