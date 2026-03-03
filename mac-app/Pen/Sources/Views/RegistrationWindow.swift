import Cocoa

// Registration window that uses AccountTabView for user registration
class RegistrationWindow: BaseWindow {
    // MARK: - Properties
    private let windowWidth: CGFloat = 500
    private let windowHeight: CGFloat = 400
    private weak var penDelegate: PenDelegate?
    private var accountTabView: AccountTabView!
    
    // MARK: - Initialization
    init(penDelegate: PenDelegate? = nil) {
        let windowSize = NSSize(width: windowWidth, height: windowHeight)
        print("RegistrationWindow: Opening with size: \(windowSize)")
        
        // Create window with borderless style
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
    
    /// Sets up the content view with AccountTabView
    private func setupContentView() {
        // Create standard content view with consistent styling
        let contentView = createStandardContentView(size: NSSize(width: windowWidth, height: windowHeight))
        
        // Add PenAI logo
        addPenAILogo(to: contentView, windowHeight: windowHeight)
        
        // Add title
        let titleLabel = NSTextField(frame: NSRect(x: 70, y: windowHeight - 55, width: 200, height: 30))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "register_new_account")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        contentView.addSubview(titleLabel)
        
        // Create AccountTabView with nil user (new user)
        let accountTabFrame = NSRect(x: 0, y: 20, width: windowWidth, height: windowHeight - 80)
        accountTabView = AccountTabView(frame: accountTabFrame, user: nil, parentWindow: self)
        contentView.addSubview(accountTabView)
        
        // Replace save button with register button
        replaceSaveButton()
        
        // Remove logout button
        removeLogoutButton()
        
        // Remove password instruction label
        removePasswordInstructionLabel()
        
        // Add standard close button
        addStandardCloseButton(to: contentView, windowWidth: windowWidth, windowHeight: windowHeight)
        
        // Set content view
        self.contentView = contentView
        
        // Recalculate key view loop for proper tab navigation
        self.recalculateKeyViewLoop()
    }
    
    /// Replaces the save button with a register button
    private func replaceSaveButton() {
        // Find and replace the save button
        print("RegistrationWindow: Looking for save button")
        for subview in accountTabView.subviews {
            if let button = subview as? NSButton {
                print("RegistrationWindow: Found button with title: \(button.title)")
                if button.title == LocalizationService.shared.localizedString(for: "save_changes") {
                    print("RegistrationWindow: Found save button, replacing with register button")
                    button.title = LocalizationService.shared.localizedString(for: "register")
                    button.action = #selector(register)
                    button.target = self
                    print("RegistrationWindow: Set register button action to \(#selector(register))")
                    break
                }
            }
        }
    }
    
    /// Removes the logout button
    private func removeLogoutButton() {
        // Find and remove the logout button
        for subview in accountTabView.subviews {
            if let button = subview as? NSButton, button.title == LocalizationService.shared.localizedString(for: "logout") {
                button.removeFromSuperview()
                break
            }
        }
    }
    
    private func removePasswordInstructionLabel() {
        for subview in accountTabView.subviews {
            if let label = subview as? NSTextField, label.stringValue == LocalizationService.shared.localizedString(for: "leave_password_empty_current") {
                label.removeFromSuperview()
                break
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Shows the window and ensures it receives focus and keyboard events
    override func showAndFocus() {
        // Use the BaseWindow's showAndFocus method
        super.showAndFocus()
        
        // Print coordinates of registration_form and register button
        printCoordinates()
    }
    
    /// Prints the coordinates of registration_form and register button
    private func printCoordinates() {
        // Get registration_form container
        if let registrationForm = findViewWithIdentifier(accountTabView, identifier: "registration_form") {
            let formFrame = registrationForm.frame
            print("Registration Form Coordinates:")
            print("  X: \(formFrame.origin.x)")
            print("  Y: \(formFrame.origin.y)")
            print("  Width: \(formFrame.size.width)")
            print("  Height: \(formFrame.size.height)")
        } else {
            print("Registration Form not found")
        }
        
        // Get register button
        if let registerButton = findRegisterButton() {
            let buttonFrame = registerButton.frame
            print("Register Button Coordinates:")
            print("  X: \(buttonFrame.origin.x)")
            print("  Y: \(buttonFrame.origin.y)")
            print("  Width: \(buttonFrame.size.width)")
            print("  Height: \(buttonFrame.size.height)")
        } else {
            print("Register Button not found")
        }
    }
    
    /// Finds a view with the given identifier
    private func findViewWithIdentifier(_ view: NSView, identifier: String) -> NSView? {
        if view.identifier?.rawValue == identifier {
            return view
        }
        for subview in view.subviews {
            if let foundView = findViewWithIdentifier(subview, identifier: identifier) {
                return foundView
            }
        }
        return nil
    }
    
    /// Finds the register button
    private func findRegisterButton() -> NSButton? {
        for subview in accountTabView.subviews {
            if let button = subview as? NSButton, button.title == LocalizationService.shared.localizedString(for: "register") {
                return button
            }
        }
        return nil
    }
    
    // MARK: - Key Event Handling
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 { // Enter key
            register()
            return
        }
        super.keyDown(with: event)
    }
    
    // MARK: - Actions
    
    @objc private func register() {
        print("RegistrationWindow: Register button clicked")
        
        // Get UI elements from AccountTabView by searching view hierarchy
        guard let nameField = findTextField(in: accountTabView, tag: 100),
              let emailField = findTextField(in: accountTabView, tag: 101),
              let passwordField = findSecureTextField(in: accountTabView, tag: 102),
              let confirmField = findSecureTextField(in: accountTabView, tag: 103) else {
            print("RegistrationWindow: Failed to get UI elements")
            return
        }
        
        // Get values
        let name = nameField.stringValue
        let email = emailField.stringValue
        let password = passwordField.stringValue
        let confirmPassword = confirmField.stringValue
        
        if name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            displayPopupMessage(LocalizationService.shared.localizedString(for: "please_fill_in_all_fields"))
            return
        }
        
        if password != confirmPassword {
            displayPopupMessage(LocalizationService.shared.localizedString(for: "passwords_dont_match"))
            return
        }
        
        // Get profile image from AccountTabView
        let profileImage = accountTabView.getProfileImage()
        
        // Register user
        Task {
            let success = await AuthenticationService.shared.registerUser(
                name: name,
                email: email,
                password: password,
                profileImage: profileImage
            )
            
            DispatchQueue.main.async {
                if success {
                    // Show success message
                    self.displayPopupMessage(LocalizationService.shared.localizedString(for: "registration_success"))
                    
                    // Close registration window after a delay to allow the message to be seen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        self.orderOut(nil)
                        
                        // Open login window
                        if let penDelegate = self.penDelegate {
                            let loginWindow = LoginWindow(penDelegate: penDelegate)
                            loginWindow.showAndFocus()
                        }
                    }
                } else {
                    self.displayPopupMessage(LocalizationService.shared.localizedString(for: "registration_failed_email_exists"))
                }
            }
        }
    }
    
    /// Helper method to find a text field by tag
    private func findTextField(in view: NSView, tag: Int) -> NSTextField? {
        for subview in view.subviews {
            if let textField = subview as? NSTextField, textField.tag == tag {
                return textField
            }
            if let foundTextField = findTextField(in: subview, tag: tag) {
                return foundTextField
            }
        }
        return nil
    }
    
    /// Helper method to find a secure text field by tag
    private func findSecureTextField(in view: NSView, tag: Int) -> NSSecureTextField? {
        for subview in view.subviews {
            if let secureTextField = subview as? NSSecureTextField, secureTextField.tag == tag {
                return secureTextField
            }
            if let foundSecureTextField = findSecureTextField(in: subview, tag: tag) {
                return foundSecureTextField
            }
        }
        return nil
    }
}
