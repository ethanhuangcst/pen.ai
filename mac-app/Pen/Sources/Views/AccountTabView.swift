import Cocoa

class AccountTabView: NSView, NSOpenSavePanelDelegate, NSTextFieldDelegate {
    // MARK: - Properties
    private weak var parentWindow: NSWindow?
    private var user: User?
    
    // UI Elements
    private var nameField: NSTextField!
    private var emailField: NSTextField!
    private var passwordField: NSSecureTextField!
    private var plainPasswordField: NSTextField!
    private var confirmField: NSSecureTextField!
    private var plainConfirmField: NSTextField!
    private var passwordToggleButton: FocusableButton!
    private var confirmPasswordToggleButton: FocusableButton!
    private var passwordMismatchLabel: NSTextField!
    private var profileImageView: NSImageView!
    private var isPasswordSecure: Bool = true
    private var isConfirmPasswordSecure: Bool = true
    
    // MARK: - Initialization
    init(frame: CGRect, user: User?, parentWindow: NSWindow) {
        self.user = user
        self.parentWindow = parentWindow
        super.init(frame: frame)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        
        setupAccountTab()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    /// Sets up the Account tab with user information fields
    private func setupAccountTab() {
        let contentWidth = frame.width
        let contentHeight = frame.height
        
        // Profile section (image + user info)
        let profileSection = NSView(frame: NSRect(x: 20, y: contentHeight - 200, width: contentWidth - 40, height: 120))
        
        // Profile image
        let profileImageSize: CGFloat = 80
        
        // Create a container view for the profile image (moved up 20px)
        let profileImageContainer = NSView(frame: NSRect(x: 0, y: 50, width: profileImageSize, height: profileImageSize))
        profileImageContainer.wantsLayer = true
        profileImageContainer.layer?.cornerRadius = profileImageSize / 2
        profileImageContainer.layer?.masksToBounds = true
        profileImageContainer.layer?.backgroundColor = NSColor.systemGray.cgColor
        
        // Create the image view
        profileImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: profileImageSize, height: profileImageSize))
        
        // Try to load profile image from user data
        if let user = user, let profileImageData = user.profileImage, !profileImageData.isEmpty {
            // Check if it's a base64-encoded image
            if profileImageData.hasPrefix("data:image") {
                // Handle base64-encoded image
                // Extract base64 data from the string
                if let base64String = profileImageData.components(separatedBy: ",").last {
                    if let imageData = Data(base64Encoded: base64String) {
                        if let image = NSImage(data: imageData) {
                            profileImageView.image = image
                        } else {
                            // Use placeholder if image fails to load
                            profileImageView.image = NSImage(systemSymbolName: "person", accessibilityDescription: "Profile image")
                            profileImageView.contentTintColor = .systemGray
                        }
                    } else {
                        // Use placeholder if base64 data is invalid
                        profileImageView.image = NSImage(systemSymbolName: "person", accessibilityDescription: "Profile image")
                        profileImageView.contentTintColor = .systemGray
                    }
                } else {
                    // Use placeholder if base64 data is invalid
                    profileImageView.image = NSImage(systemSymbolName: "person", accessibilityDescription: "Profile image")
                    profileImageView.contentTintColor = .systemGray
                }
            } else {
                // Try to load as file path (backward compatibility)
                if let image = NSImage(contentsOfFile: profileImageData) {
                    profileImageView.image = image
                } else {
                    // Use placeholder if image fails to load
                    profileImageView.image = NSImage(systemSymbolName: "person", accessibilityDescription: "Profile image")
                    profileImageView.contentTintColor = .systemGray
                }
            }
        } else {
            // Use placeholder image
            profileImageView.image = NSImage(systemSymbolName: "person", accessibilityDescription: "Profile image")
            profileImageView.contentTintColor = .systemGray
        }
        
        profileImageContainer.addSubview(profileImageView)
        profileSection.addSubview(profileImageContainer)
        
        // Upload image button (original position)
        let uploadButton = FocusableButton(frame: NSRect(x: 0, y: 0, width: profileImageSize, height: 20))
        uploadButton.title = "Update"
        uploadButton.bezelStyle = .rounded
        uploadButton.target = self
        uploadButton.action = #selector(uploadProfileImage)
        uploadButton.toolTip = LocalizationService.shared.localizedString(for: "leave_blank_current_image")
        profileSection.addSubview(uploadButton)
        
        // Maximum file size label (right side of update button, under Email)
        let sizeLabel = NSTextField(frame: NSRect(x: profileImageSize + 40, y: -3, width: 250, height: 20))
        sizeLabel.stringValue = "Maximum file size: 1M, recommended 1:1 ratio"
        sizeLabel.isBezeled = false
        sizeLabel.drawsBackground = false
        sizeLabel.isEditable = false
        sizeLabel.isSelectable = false
        sizeLabel.font = NSFont.systemFont(ofSize: 10)
        sizeLabel.alignment = .left
        sizeLabel.textColor = .systemGray
        sizeLabel.lineBreakMode = .byWordWrapping
        sizeLabel.preferredMaxLayoutWidth = 250
        profileSection.addSubview(sizeLabel)
        
        // User info fields (moved up 20px and right 20px)
        let infoContainer = NSView(frame: NSRect(x: profileImageSize + 40, y: 40, width: contentWidth - profileImageSize - 80, height: 100))
        
        // Name field
        let nameLabel = NSTextField(frame: NSRect(x: 0, y: 60, width: 100, height: 20))
        nameLabel.stringValue = LocalizationService.shared.localizedString(for: "name")
        nameLabel.isBezeled = false
        nameLabel.drawsBackground = false
        nameLabel.isEditable = false
        nameLabel.isSelectable = false
        infoContainer.addSubview(nameLabel)
        
        nameField = NSTextField(frame: NSRect(x: 80, y: 60, width: 200, height: 24))
        nameField.stringValue = user?.name ?? "Ethan Huang" // Use user data or sample
        infoContainer.addSubview(nameField)
        
        // Email field
        let emailLabel = NSTextField(frame: NSRect(x: 0, y: 20, width: 100, height: 20))
        emailLabel.stringValue = LocalizationService.shared.localizedString(for: "email")
        emailLabel.isBezeled = false
        emailLabel.drawsBackground = false
        emailLabel.isEditable = false
        emailLabel.isSelectable = false
        infoContainer.addSubview(emailLabel)
        
        emailField = NSTextField(frame: NSRect(x: 80, y: 20, width: 200, height: 24))
        emailField.stringValue = user?.email ?? "me@ethanhuang.com" // Use user data or sample
        infoContainer.addSubview(emailField)
        
        profileSection.addSubview(infoContainer)
        addSubview(profileSection)
        
        // Password section
        let passwordSection = NSView(frame: NSRect(x: 20, y: contentHeight - 350, width: contentWidth - 40, height: 120))
        
        // New password field
        let passwordLabel = NSTextField(frame: NSRect(x: 0, y: 80, width: 120, height: 20))
        passwordLabel.stringValue = LocalizationService.shared.localizedString(for: "new_password")
        passwordLabel.isBezeled = false
        passwordLabel.drawsBackground = false
        passwordLabel.isEditable = false
        passwordLabel.isSelectable = false
        passwordSection.addSubview(passwordLabel)
        
        passwordField = NSSecureTextField(frame: NSRect(x: 120, y: 80, width: 200, height: 24))
        passwordField.toolTip = LocalizationService.shared.localizedString(for: "leave_blank_current_password")
        passwordField.backgroundColor = NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        passwordSection.addSubview(passwordField)
        
        // Plain password field (initially hidden)
        plainPasswordField = NSTextField(frame: NSRect(x: 120, y: 80, width: 200, height: 24))
        plainPasswordField.placeholderString = LocalizationService.shared.localizedString(for: "new_password")
        plainPasswordField.toolTip = LocalizationService.shared.localizedString(for: "leave_blank_current_password")
        plainPasswordField.backgroundColor = NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        plainPasswordField.isHidden = true
        passwordSection.addSubview(plainPasswordField)
        
        // Password toggle button
        passwordToggleButton = FocusableButton(frame: NSRect(x: 325, y: 80, width: 18, height: 18))
        passwordToggleButton.title = ""
        passwordToggleButton.bezelStyle = .smallSquare
        passwordToggleButton.isBordered = false
        
        // Load and resize the hidden.svg icon
        let iconPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/hidden.svg"
        if let originalImage = NSImage(contentsOfFile: iconPath) {
            let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
            resizedImage.lockFocus()
            originalImage.draw(in: NSRect(origin: .zero, size: NSSize(width: 18, height: 18)), from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
            resizedImage.unlockFocus()
            passwordToggleButton.image = resizedImage
        }
        
        passwordToggleButton.target = self
        passwordToggleButton.action = #selector(togglePasswordVisibility)
        passwordSection.addSubview(passwordToggleButton)
        
        // Confirm password field
        let confirmLabel = NSTextField(frame: NSRect(x: 0, y: 40, width: 120, height: 20))
        confirmLabel.stringValue = LocalizationService.shared.localizedString(for: "confirm_password")
        confirmLabel.isBezeled = false
        confirmLabel.drawsBackground = false
        confirmLabel.isEditable = false
        confirmLabel.isSelectable = false
        passwordSection.addSubview(confirmLabel)
        
        confirmField = NSSecureTextField(frame: NSRect(x: 120, y: 40, width: 200, height: 24))
        confirmField.toolTip = LocalizationService.shared.localizedString(for: "leave_blank_current_password")
        confirmField.backgroundColor = NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        passwordSection.addSubview(confirmField)
        
        // Plain confirm password field (initially hidden)
        plainConfirmField = NSTextField(frame: NSRect(x: 120, y: 40, width: 200, height: 24))
        plainConfirmField.placeholderString = LocalizationService.shared.localizedString(for: "confirm_password")
        plainConfirmField.toolTip = LocalizationService.shared.localizedString(for: "leave_blank_current_password")
        plainConfirmField.backgroundColor = NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        plainConfirmField.isHidden = true
        passwordSection.addSubview(plainConfirmField)
        
        // Confirm password toggle button
        confirmPasswordToggleButton = FocusableButton(frame: NSRect(x: 325, y: 40, width: 18, height: 18))
        confirmPasswordToggleButton.title = ""
        confirmPasswordToggleButton.bezelStyle = .smallSquare
        confirmPasswordToggleButton.isBordered = false
        
        // Load and resize the hidden.svg icon
        if let originalImage = NSImage(contentsOfFile: iconPath) {
            let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
            resizedImage.lockFocus()
            originalImage.draw(in: NSRect(origin: .zero, size: NSSize(width: 18, height: 18)), from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
            resizedImage.unlockFocus()
            confirmPasswordToggleButton.image = resizedImage
        }
        
        confirmPasswordToggleButton.target = self
        confirmPasswordToggleButton.action = #selector(toggleConfirmPasswordVisibility)
        passwordSection.addSubview(confirmPasswordToggleButton)
        
        // Password mismatch label
        passwordMismatchLabel = NSTextField(frame: NSRect(x: 120, y: 25, width: 220, height: 12))
        passwordMismatchLabel.stringValue = "Passwords don't match"
        passwordMismatchLabel.isBezeled = false
        passwordMismatchLabel.drawsBackground = false
        passwordMismatchLabel.isEditable = false
        passwordMismatchLabel.isSelectable = false
        passwordMismatchLabel.font = NSFont.systemFont(ofSize: 10)
        passwordMismatchLabel.alignment = .left
        passwordMismatchLabel.textColor = .systemRed
        passwordMismatchLabel.isHidden = true
        passwordSection.addSubview(passwordMismatchLabel)
        
        // Password instruction label
        let passwordInstructionLabel = NSTextField(frame: NSRect(x: 120, y: 10, width: 220, height: 12))
        passwordInstructionLabel.stringValue = "Leave password fields empty to keep your current password"
        passwordInstructionLabel.isBezeled = false
        passwordInstructionLabel.drawsBackground = false
        passwordInstructionLabel.isEditable = false
        passwordInstructionLabel.isSelectable = false
        passwordInstructionLabel.font = NSFont.systemFont(ofSize: 10)
        passwordInstructionLabel.alignment = .left
        passwordInstructionLabel.textColor = .systemGray
        passwordSection.addSubview(passwordInstructionLabel)
        
        // Set delegates for real-time validation
        passwordField.delegate = self
        confirmField.delegate = self
        plainPasswordField.delegate = self
        plainConfirmField.delegate = self
        
        addSubview(passwordSection)
        
        // Action buttons
        let saveButton = FocusableButton(frame: NSRect(x: contentWidth - 220, y: 20, width: 100, height: 32))
        saveButton.title = LocalizationService.shared.localizedString(for: "save_changes")
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveChanges)
        addSubview(saveButton)
        
        let logoutButton = FocusableButton(frame: NSRect(x: contentWidth - 110, y: 20, width: 90, height: 32))
        logoutButton.title = LocalizationService.shared.localizedString(for: "logout")
        logoutButton.bezelStyle = .rounded
        logoutButton.target = self
        logoutButton.action = #selector(logout)
        logoutButton.contentTintColor = .systemRed
        addSubview(logoutButton)
        
        // Set tab order explicitly
        nameField.nextKeyView = emailField
        emailField.nextKeyView = passwordField
        passwordField.nextKeyView = plainPasswordField
        plainPasswordField.nextKeyView = confirmField
        confirmField.nextKeyView = plainConfirmField
        plainConfirmField.nextKeyView = uploadButton
        uploadButton.nextKeyView = saveButton
        saveButton.nextKeyView = logoutButton
        logoutButton.nextKeyView = nameField
    }
    
    // MARK: - Actions
    
    @objc private func uploadProfileImage() {
        // Create an open panel for file selection
        let openPanel = NSOpenPanel()
        openPanel.title = LocalizationService.shared.localizedString(for: "select_profile_image")
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        
        // Set allowed file types to image files
        openPanel.allowedFileTypes = ["public.image"]
        
        // Set delegate to handle file size validation
        openPanel.delegate = self
        
        // Ensure the panel opens in front of the preferences window
        openPanel.level = .floating
        
        // Run the open panel
        openPanel.begin { [weak self] (result) in
            guard let self = self else { return }
            
            if result == .OK, let url = openPanel.url {
                // Check file size
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    if let fileSize = attributes[.size] as? Int64 {
                        let fileSizeMB = Double(fileSize) / (1024 * 1024)
                        
                        if fileSizeMB > 1.0 {
                            // Show error message for large file using global popup message
                            if let appDelegate = NSApplication.shared.delegate as? PenDelegate {
                                appDelegate.displayPopupMessage(LocalizationService.shared.localizedString(for: "file_too_large"))
                            }
                        } else {
                            // File is valid, update profile image directly
                            self.updateProfileImage(from: url)
                        }
                    }
                } catch {
                    // Handle error silently
                }
            }
        }
    }
    
    /// Updates the profile image directly without cropping
    private func updateProfileImage(from imageURL: URL) {
        if let image = NSImage(contentsOf: imageURL) {
            // Update profile image immediately
            profileImageView.image = image
        } else {
            // Show error message if image fails to load
            if let appDelegate = NSApplication.shared.delegate as? PenDelegate {
                appDelegate.displayPopupMessage("Failed to load image")
            }
        }
    }
    
    @objc private func saveChanges() {
        print("AccountTabView: Save changes button clicked")
        
        // Validate passwords if they're not empty
        if !passwordField.stringValue.isEmpty || !confirmField.stringValue.isEmpty {
            if passwordField.stringValue != confirmField.stringValue {
                // Show password mismatch error
                if let appDelegate = NSApplication.shared.delegate as? PenDelegate {
                    appDelegate.displayPopupMessage("Passwords don't match. Please try again.")
                }
                return
            }
        }
        
        // Get app delegate and current user
        guard let appDelegate = NSApplication.shared.delegate as? PenDelegate, let currentUser = appDelegate.currentUser else {
            print("AccountTabView: No current user found")
            return
        }
        
        // Prepare update parameters
        let name = nameField.stringValue
        let email = emailField.stringValue
        let password = passwordField.stringValue.isEmpty ? nil : passwordField.stringValue
        
        // Update user in database
        Task {
            let success = await AuthenticationService.shared.updateUser(
                id: currentUser.id,
                name: name,
                email: email,
                password: password,
                profileImage: currentUser.profileImage
            )
            
            if success {
                // Update local user object
                let updatedUser = User(
                    id: currentUser.id,
                    name: name,
                    email: email,
                    password: password ?? currentUser.password,
                    profileImage: currentUser.profileImage,
                    createdAt: currentUser.createdAt
                )
                
                // Update the user in the app delegate
                appDelegate.currentUser = updatedUser
                
                // Clear password fields
                DispatchQueue.main.async {
                    self.passwordField.stringValue = ""
                    self.confirmField.stringValue = ""
                    self.plainPasswordField.stringValue = ""
                    self.plainConfirmField.stringValue = ""
                }
                
                // Show success message
                DispatchQueue.main.async {
                    appDelegate.displayPopupMessage("Changes saved successfully!")
                }
            } else {
                // Show error message
                DispatchQueue.main.async {
                    appDelegate.displayPopupMessage("Failed to save changes. Please try again.")
                }
            }
        }
    }
    
    @objc private func logout() {
        print("AccountTabView: Logout button clicked")
        
        // Clear stored credentials
        AuthenticationService.shared.clearCredentials()
        
        // Close the preferences window
        parentWindow?.orderOut(nil)
        
        // Call PenDelegate's logout method for consistent behavior
        print("AccountTabView: Getting application delegate")
        if let appDelegate = NSApplication.shared.delegate {
            print("AccountTabView: App delegate found: \(appDelegate)")
            if let penDelegate = appDelegate as? PenDelegate {
                print("AccountTabView: Cast to PenDelegate successful")
                penDelegate.logout()
                print("AccountTabView: logout() called on PenDelegate")
            } else {
                print("AccountTabView: Failed to cast to PenDelegate")
                print("AccountTabView: Delegate type: \(type(of: appDelegate))")
            }
        } else {
            print("AccountTabView: No app delegate found")
        }
        
        print("AccountTabView: Logout completed successfully")
    }
    
    @objc private func togglePasswordVisibility() {
        isPasswordSecure = !isPasswordSecure
        
        // Swap visibility of password fields
        passwordField.isHidden = !isPasswordSecure
        plainPasswordField.isHidden = isPasswordSecure
        
        // Sync text between fields
        if isPasswordSecure {
            passwordField.stringValue = plainPasswordField.stringValue
        } else {
            plainPasswordField.stringValue = passwordField.stringValue
        }
        
        // Update button icon
        let iconName = isPasswordSecure ? "hidden" : "show"
        let iconPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/\(iconName).svg"
        if let originalImage = NSImage(contentsOfFile: iconPath) {
            let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
            resizedImage.lockFocus()
            originalImage.draw(in: NSRect(origin: .zero, size: NSSize(width: 18, height: 18)), from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
            resizedImage.unlockFocus()
            passwordToggleButton.image = resizedImage
        }
    }
    
    @objc private func toggleConfirmPasswordVisibility() {
        isConfirmPasswordSecure = !isConfirmPasswordSecure
        
        // Swap visibility of password fields
        confirmField.isHidden = !isConfirmPasswordSecure
        plainConfirmField.isHidden = isConfirmPasswordSecure
        
        // Sync text between fields
        if isConfirmPasswordSecure {
            confirmField.stringValue = plainConfirmField.stringValue
        } else {
            plainConfirmField.stringValue = confirmField.stringValue
        }
        
        // Update button icon
        let iconName = isConfirmPasswordSecure ? "hidden" : "show"
        let iconPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/\(iconName).svg"
        if let originalImage = NSImage(contentsOfFile: iconPath) {
            let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
            resizedImage.lockFocus()
            originalImage.draw(in: NSRect(origin: .zero, size: NSSize(width: 18, height: 18)), from: NSRect(origin: .zero, size: originalImage.size), operation: .sourceOver, fraction: 1.0)
            resizedImage.unlockFocus()
            confirmPasswordToggleButton.image = resizedImage
        }
    }
    
    // MARK: - NSTextFieldDelegate
    
    func controlTextDidChange(_ obj: Notification) {
        // Get the current password values
        let password = isPasswordSecure ? passwordField.stringValue : plainPasswordField.stringValue
        let confirmPassword = isConfirmPasswordSecure ? confirmField.stringValue : plainConfirmField.stringValue
        
        // Check if both fields are non-empty and passwords don't match
        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
            // Show password mismatch error
            passwordMismatchLabel.isHidden = false
        } else {
            // Hide error if passwords match or fields are empty
            passwordMismatchLabel.isHidden = true
        }
    }
}