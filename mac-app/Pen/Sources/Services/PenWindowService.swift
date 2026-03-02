import Foundation
import Cocoa

// Import AIProvider from AIManager
typealias AIProvider = AIManager.AIProvider

class PenWindowService {
    private var window: BaseWindow?
    private var userService: UserService
    private var promptsService: PromptsService
    private var currentClipboardContent: String?
    private var isWindowOpen: Bool = false
    
    init() {
        self.userService = UserService.shared
        self.promptsService = PromptsService()
        print("[PenWindowService] Initializer called, currentUser: \(userService.currentUser?.name ?? "nil")")
    }
    
    // MARK: - Window Lifecycle Methods
    
    func createWindow() -> BaseWindow {
        let windowSize = NSSize(width: 378, height: 388)
        window = BaseWindow.createStandardWindow(size: windowSize, showLogo: false, showTitle: false)
        return window!
    }
    
    func setWindow(_ window: BaseWindow) {
        self.window = window
    }
    
    func showWindow() {
        window?.showAndFocus()
        isWindowOpen = true
        startClipboardMonitoring()
    }
    
    func hideWindow() {
        window?.orderOut(nil)
        isWindowOpen = false
        stopClipboardMonitoring()
    }
    
    func toggleWindow() {
        if let window = window {
            if window.isVisible {
                hideWindow()
            } else {
                showWindow()
            }
        }
    }
    
    // MARK: - Clipboard Monitoring
    
    private var clipboardPollingTask: Task<Void, Never>?
    
    private func startClipboardMonitoring() {
        // Stop any existing polling task
        stopClipboardMonitoring()
        
        // Start a new polling task
        clipboardPollingTask = Task {
            while true {
                do {
                    try await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1 second
                } catch {
                    // Task was canceled, exit the loop
                    break
                }
                
                guard isWindowOpen else { break }
                
                // Load clipboard content and trigger enhancement if changed
                if loadClipboardContent() != nil {
                    await enhanceText()
                }
            }
        }
        
        print("[PenWindowService] Clipboard monitoring started")
    }
    
    private func stopClipboardMonitoring() {
        // Cancel the polling task
        clipboardPollingTask?.cancel()
        clipboardPollingTask = nil
        print("[PenWindowService] Clipboard monitoring stopped")
    }
    
    func closeWindow() {
        window?.orderOut(nil)
        isWindowOpen = false
        stopClipboardMonitoring()
    }
    
    // MARK: - Positioning Methods
    
    func positionWindowRelativeToMenuBarIcon() {
        window?.positionRelativeToMenuBarIcon()
    }
    
    // MARK: - Initialization Method
    
    func initiatePen() async {
        guard let window = window else {
            print("[PenWindowService] Window not initialized")
            return
        }
        
        // 1. Load User Information
        await loadUserInformation()
        
        // 2. Initialize UI Components on main thread
        await MainActor.run {
            initializeUIComponents()
        }
        
        // 3. Load AI Configurations
        await loadAIConfigurations()
        
        // 4. Load Clipboard Content - Always load regardless of AI configuration status
        await MainActor.run {
            if let clipboardText = loadClipboardContent() {
                // Trigger text enhancement if clipboard content is loaded successfully
                Task {
                    await enhanceText()
                }
            } else {
                // Clipboard content is unchanged, skip enhancement
                print("[PenWindowService] Clipboard content unchanged, skipping enhancement in initiatePen")
            }
        }
    }
    
    // MARK: - User Information Loading
    
    private func loadUserInformation() async {
        guard let window = window else { return }
        
        // Check login status
        let isLoggedIn = userService.isLoggedIn
        let isOnline = userService.isOnline
        
        print("[PenWindowService] loadUserInformation called")
        print("[PenWindowService] isLoggedIn: \(isLoggedIn)")
        print("[PenWindowService] isOnline: \(isOnline)")
        
        if isOnline && isLoggedIn {
            // User is logged in, load user information
            do {
                let user = userService.currentUser
                print("[PenWindowService] userService.currentUser: \(user)")
                if let user = user {
                    print("[PenWindowService] User information loaded:")
                    print("  Name: \(user.name)")
                    print("  Email: \(user.email)")
                    print("  User ID: \(user.id)")
                } else {
                    print("[PenWindowService] userService.currentUser is nil even though isLoggedIn is true")
                    showDefaultUI()
                    WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "pen_load_login_error"))
                    return
                }
            } catch {
                // Handle user information load failure
                print("[PenWindowService] Failed to load user information: \(error)")
                showDefaultUI()
                WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "pen_load_login_error"))
                return
            }
        } else if isOnline && !isLoggedIn {
            // User is not logged in
            showDefaultUI()
            WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "pen_not_logged_in_error"))
            return
        }
    }
    
    // MARK: - AI Configurations Loading
    
    private func loadAIConfigurations() async {
        guard let window = window else { return }
        
        // Check if AIManager instance exists
        guard let aiManager = userService.aiManager else {
            print("^^^^^^^^^^^^^^^^^^$$$$$$$$$$$$$$$ AIManager NOT found, AI configuration not loaded. #################@@@@@@@@@@@@@@@")
            // Load prompts even if AIManager is not found
            if let user = userService.currentUser {
                await loadPrompts()
            }
            await handleNoAIProviders()
            return
        }
        
        if aiManager.isInitialized {
            print("^^^^^^^^^^^^^^^^^^$$$$$$$$$$$$$$$ AIManager found, AI configuration and Prompts loaded successfully. #################@@@@@@@@@@@@@@@")
        } else {
            // Initialize AIManager instance
            print("^^^^^^^^^^^^^^^^^^$$$$$$$$$$$$$$$ AIManager NOT initialized, initializing now. #################@@@@@@@@@@@@@@@")
            aiManager.initialize()
        }
        
        // Load AI configurations for the current user
        do {
            guard let user = userService.currentUser else {
                // No user logged in
                await handleNoAIProviders()
                return
            }
            
            // Load prompts regardless of AI configuration status
            await loadPrompts()
            
            // Get user's AI configurations
            let configurations = try await aiManager.getConnections(for: user.id)
            
            if configurations.isEmpty {
                // No AI configurations for this user
                await handleNoAIProviders()
            } else {
                // Get all available providers
                let allProviders = try await aiManager.getProviders()
                
                // Filter providers to only those the user has configured
                let userProviders = allProviders.filter { provider in
                    return configurations.contains { config in
                        config.apiProvider == provider.name
                    }
                }
                
                if userProviders.isEmpty {
                    // No matching providers found
                    await handleNoAIProviders()
                } else {
                    // Populate AI providers dropdown with user's configured providers
                    await populateProvidersDropdown(providers: userProviders)
                }
            }
        } catch {
            // Handle AI configuration load failure
            print("[PenWindowService] Failed to load AI configurations: \(error)")
            await handleAIConfigurationFailure()
        }
    }
    
    private func loadPrompts() async {
        guard let user = userService.currentUser else { return }
        
        do {
            let prompts = try await promptsService.getPromptsByUserId(userId: user.id)
            print("[PenWindowService] Loaded \(prompts.count) prompts for user \(user.id)")
            for (index, prompt) in prompts.enumerated() {
                print("[PenWindowService] Prompt \(index): \(prompt.promptName) (ID: \(prompt.id), UserID: \(prompt.userId))")
            }
            await populatePromptsDropdown(prompts: prompts)
        } catch {
            print("[PenWindowService] Failed to load prompts: \(error)")
            await handleAIConfigurationFailure()
        }
    }
    
    // MARK: - UI Initialization
    
    private func initializeUIComponents() {
        guard let window = window, let contentView = window.contentView else { return }
        
        // Store current text values before resetting UI
        var originalText: String? = nil
        var enhancedText: String? = nil
        var originalTextTooltip: String? = nil
        var enhancedTextTooltip: String? = nil
        
        // Find and store current text values
        for subview in contentView.subviews {
            if let container = subview as? NSView, container.identifier?.rawValue == "pen_original_text" {
                for subview in container.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_original_text_text" {
                        originalText = textField.stringValue
                        originalTextTooltip = textField.toolTip
                    }
                }
            } else if let container = subview as? NSView, container.identifier?.rawValue == "pen_enhanced_text" {
                for subview in container.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_enhanced_text_text" {
                        enhancedText = textField.stringValue
                        enhancedTextTooltip = textField.toolTip
                    }
                }
            }
        }
        
        // Clear existing views except for the close button
        var closeButton: NSButton? = nil
        for subview in contentView.subviews {
            // Check if this is the close button (by its position and size)
            if let button = subview as? NSButton, 
               button.frame.origin.x > contentView.frame.width - 40, 
               button.frame.origin.y > contentView.frame.height - 40, 
               button.frame.size.width == 20, 
               button.frame.size.height == 20 {
                closeButton = button
            } else {
                subview.removeFromSuperview()
            }
        }
        
        // Add footer container
        addFooterContainer(to: contentView)
        
        // Add enhanced text container
        addEnhancedTextContainer(to: contentView)
        
        // Add controller container
        addControllerContainer(to: contentView)
        
        // Add user label container
        addUserLabelContainer(to: contentView)
        
        // Add original text container
        addOriginalTextContainer(to: contentView)
        
        // Add manual paste container
        addManualPasteContainer(to: contentView)
        
        // Re-add the close button if it was found
        if let closeButton = closeButton {
            contentView.addSubview(closeButton)
            // Bring close button to front
            contentView.addSubview(closeButton, positioned: .above, relativeTo: nil)
        } else {
            // If no close button found, add a new one
            window.addStandardCloseButton(to: contentView, windowWidth: window.frame.width, windowHeight: window.frame.height)
        }
        
        // Restore text values if they exist (not placeholder text)
        if let originalText = originalText, !originalText.isEmpty, 
           originalText != LocalizationService.shared.localizedString(for: "pen_original_text_placeholder") {
            for subview in contentView.subviews {
                if let container = subview as? NSView, container.identifier?.rawValue == "pen_original_text" {
                    for subview in container.subviews {
                        if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_original_text_text" {
                            textField.stringValue = originalText
                            textField.toolTip = originalTextTooltip
                        }
                    }
                    break
                }
            }
        }
        
        if let enhancedText = enhancedText, !enhancedText.isEmpty, 
           enhancedText != LocalizationService.shared.localizedString(for: "pen_enhanced_text_placeholder") {
            for subview in contentView.subviews {
                if let container = subview as? NSView, container.identifier?.rawValue == "pen_enhanced_text" {
                    for subview in container.subviews {
                        if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_enhanced_text_text" {
                            textField.stringValue = enhancedText
                            textField.toolTip = enhancedTextTooltip
                        }
                    }
                    break
                }
            }
        }
    }
    
    private func addFooterContainer(to contentView: NSView) {
        let footerHeight: CGFloat = 30
        let footerContainer = NSView(frame: NSRect(x: 0, y: 0, width: 378, height: footerHeight))
        footerContainer.wantsLayer = true
        footerContainer.layer?.backgroundColor = NSColor.clear.cgColor
        footerContainer.identifier = NSUserInterfaceItemIdentifier("pen_footer")
        
        // Add instruction label
        let instructionLabel = NSTextField(frame: NSRect(x: 20, y: -6, width: 250, height: footerHeight))
        let defaults = UserDefaults.standard
        let shortcutKeyDefaultsKey = "pen.shortcutKey"
        let defaultShortcut = "Command+Option+P"
        let savedShortcut = defaults.string(forKey: shortcutKeyDefaultsKey) ?? defaultShortcut
        instructionLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_footer_instruction", withFormat: savedShortcut)
        instructionLabel.isBezeled = false
        instructionLabel.drawsBackground = false
        instructionLabel.isEditable = false
        instructionLabel.isSelectable = false
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.textColor = NSColor.secondaryLabelColor
        instructionLabel.alignment = .left
        instructionLabel.identifier = NSUserInterfaceItemIdentifier("pen_footer_instruction")
        
        // Add text label
        let textLabel = NSTextField(frame: NSRect(x: 330, y: -6, width: 250, height: footerHeight))
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
        let logoPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/logo.png"
        if let logo = NSImage(contentsOfFile: logoPath) {
            let logoSize: CGFloat = 26
            let logoView = NSImageView(frame: NSRect(x: 336, y: 2, width: logoSize, height: logoSize))
            logoView.image = logo
            
            footerContainer.addSubview(instructionLabel)
            footerContainer.addSubview(textLabel)
            footerContainer.addSubview(logoView)
        }
        
        contentView.addSubview(footerContainer)
    }
    
    private func addEnhancedTextContainer(to contentView: NSView) {
        let enhancedTextContainer = NSView(frame: NSRect(x: 20, y: 30, width: 338, height: 198))
        enhancedTextContainer.wantsLayer = true
        enhancedTextContainer.layer?.backgroundColor = NSColor.clear.cgColor
        enhancedTextContainer.identifier = NSUserInterfaceItemIdentifier("pen_enhanced_text")
        
        // Add text field
        let enhancedTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 338, height: 198))
        enhancedTextField.stringValue = LocalizationService.shared.localizedString(for: "pen_enhanced_text_placeholder")
        enhancedTextField.isBezeled = false
        enhancedTextField.drawsBackground = false
        enhancedTextField.isEditable = false
        enhancedTextField.isSelectable = true
        enhancedTextField.font = NSFont.systemFont(ofSize: 12)
        enhancedTextField.textColor = NSColor(red: 104.0/255.0, green: 153.0/255.0, blue: 210.0/255.0, alpha: 1.0)
        enhancedTextField.alignment = .left
        enhancedTextField.identifier = NSUserInterfaceItemIdentifier("pen_enhanced_text_text")
        
        // Add visible border
        enhancedTextField.wantsLayer = true
        enhancedTextField.layer?.backgroundColor = NSColor.clear.cgColor
        enhancedTextField.layer?.borderWidth = 1.0
        let borderColor = NSColor(red: 192.0/255.0, green: 192.0/255.0, blue: 192.0/255.0, alpha: 1.0)
        enhancedTextField.layer?.borderColor = borderColor.cgColor
        enhancedTextField.layer?.cornerRadius = 4.0
        
        // Make text field clickable
        let clickableTextField = ClickableTextField(frame: enhancedTextField.frame)
        clickableTextField.stringValue = enhancedTextField.stringValue
        clickableTextField.isBezeled = false
        clickableTextField.drawsBackground = false
        clickableTextField.isEditable = false
        clickableTextField.isSelectable = true
        clickableTextField.font = enhancedTextField.font
        clickableTextField.textColor = enhancedTextField.textColor
        clickableTextField.alignment = enhancedTextField.alignment
        clickableTextField.identifier = enhancedTextField.identifier
        clickableTextField.wantsLayer = true
        clickableTextField.layer?.backgroundColor = NSColor.clear.cgColor
        clickableTextField.layer?.borderWidth = 1.0
        clickableTextField.layer?.borderColor = borderColor.cgColor
        clickableTextField.layer?.cornerRadius = 4.0
        
        // Set action for click
        clickableTextField.target = self
        clickableTextField.action = #selector(handleEnhancedTextClick)
        
        enhancedTextContainer.addSubview(clickableTextField)
        contentView.addSubview(enhancedTextContainer)
    }
    
    @objc private func handleEnhancedTextClick() {
        // Get the enhanced text
        guard let enhancedText = getEnhancedText() else { return }
        
        // Copy to clipboard
        copyToClipboard(enhancedText)
        
        // Display popup message with completion handler
        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "text_copied_to_clipboard")) {
            // Close the window after message disappears
            self.closeWindow()
        }
    }
    
    private func getEnhancedText() -> String? {
        guard let contentView = window?.contentView else { return nil }
        
        for subview in contentView.subviews {
            if subview.identifier?.rawValue == "pen_enhanced_text" {
                for subview in subview.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_enhanced_text_text" {
                        return textField.stringValue
                    }
                }
            }
        }
        return nil
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("[PenWindowService] Text copied to clipboard: \(text)")
    }
    
    private func addControllerContainer(to contentView: NSView) {
        let controllerContainer = NSView(frame: NSRect(x: 20, y: 228, width: 338, height: 30))
        controllerContainer.wantsLayer = true
        controllerContainer.layer?.backgroundColor = NSColor.clear.cgColor
        controllerContainer.identifier = NSUserInterfaceItemIdentifier("pen_controller")
        
        // Add pen_controller_prompts drop-down box
        let promptsDropdown = NSPopUpButton(frame: NSRect(x: 0, y: 5, width: 222, height: 20))
        promptsDropdown.identifier = NSUserInterfaceItemIdentifier("pen_controller_prompts")
        promptsDropdown.addItem(withTitle: LocalizationService.shared.localizedString(for: "pen_select_prompt"))
        promptsDropdown.font = NSFont.systemFont(ofSize: 12)
        promptsDropdown.target = self
        promptsDropdown.action = #selector(handlePromptSelectionChanged)
        
        // Add visible border
        promptsDropdown.wantsLayer = true
        promptsDropdown.layer?.backgroundColor = NSColor.clear.cgColor
        promptsDropdown.layer?.borderWidth = 1.0
        let borderColor = NSColor(red: 192.0/255.0, green: 192.0/255.0, blue: 192.0/255.0, alpha: 1.0)
        promptsDropdown.layer?.borderColor = borderColor.cgColor
        promptsDropdown.layer?.cornerRadius = 4.0
        
        // Add pen_controller_provider drop-down box
        let providerDropdown = NSPopUpButton(frame: NSRect(x: 228, y: 5, width: 110, height: 20))
        providerDropdown.identifier = NSUserInterfaceItemIdentifier("pen_controller_provider")
        providerDropdown.addItem(withTitle: LocalizationService.shared.localizedString(for: "pen_select_provider"))
        providerDropdown.font = NSFont.systemFont(ofSize: 12)
        providerDropdown.target = self
        providerDropdown.action = #selector(handleProviderSelectionChanged)
        
        // Add visible border
        providerDropdown.wantsLayer = true
        providerDropdown.layer?.backgroundColor = NSColor.clear.cgColor
        providerDropdown.layer?.borderWidth = 1.0
        providerDropdown.layer?.borderColor = borderColor.cgColor
        providerDropdown.layer?.cornerRadius = 4.0
        
        controllerContainer.addSubview(promptsDropdown)
        controllerContainer.addSubview(providerDropdown)
        contentView.addSubview(controllerContainer)
    }
    
    private func addOriginalTextContainer(to contentView: NSView) {
        let originalTextContainer = NSView(frame: NSRect(x: 20, y: 258, width: 338, height: 88))
        originalTextContainer.wantsLayer = true
        originalTextContainer.layer?.backgroundColor = NSColor.clear.cgColor
        originalTextContainer.identifier = NSUserInterfaceItemIdentifier("pen_original_text")
        
        // Add text field
        let originalTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 338, height: 88))
        originalTextField.stringValue = LocalizationService.shared.localizedString(for: "pen_original_text_placeholder")
        originalTextField.isBezeled = false
        originalTextField.drawsBackground = false
        originalTextField.isEditable = false
        originalTextField.isSelectable = true
        originalTextField.font = NSFont.systemFont(ofSize: 12)
        originalTextField.textColor = NSColor.labelColor
        originalTextField.alignment = .left
        originalTextField.identifier = NSUserInterfaceItemIdentifier("pen_original_text_text")
        
        // Add visible border
        originalTextField.wantsLayer = true
        originalTextField.layer?.backgroundColor = NSColor.clear.cgColor
        originalTextField.layer?.borderWidth = 1.0
        let borderColor = NSColor(red: 192.0/255.0, green: 192.0/255.0, blue: 192.0/255.0, alpha: 1.0)
        originalTextField.layer?.borderColor = borderColor.cgColor
        originalTextField.layer?.cornerRadius = 4.0
        
        // Use ClickableTextField for arrow cursor
        let clickableTextField = ClickableTextField(frame: originalTextField.frame)
        clickableTextField.stringValue = originalTextField.stringValue
        clickableTextField.isBezeled = false
        clickableTextField.drawsBackground = false
        clickableTextField.isEditable = false
        clickableTextField.isSelectable = true
        clickableTextField.font = originalTextField.font
        clickableTextField.textColor = originalTextField.textColor
        clickableTextField.alignment = originalTextField.alignment
        clickableTextField.identifier = originalTextField.identifier
        clickableTextField.wantsLayer = true
        clickableTextField.layer?.backgroundColor = NSColor.clear.cgColor
        clickableTextField.layer?.borderWidth = 1.0
        clickableTextField.layer?.borderColor = borderColor.cgColor
        clickableTextField.layer?.cornerRadius = 4.0
        
        originalTextContainer.addSubview(clickableTextField)
        contentView.addSubview(originalTextContainer)
    }
    
    private func setPlaceholderImage(to imageView: NSImageView) {
        // Try multiple paths to find the logo.png file
        let possiblePaths = [
            // Absolute paths
            "/Users/ethanhuang/code/pen.ai/pen/mac-app/Pen/Resources/Assets/logo.png",
            "/Users/ethanhuang/code/pen.ai/pen/web-app/public/logo.png",
            // Relative paths
            "Resources/Assets/logo.png",
            "mac-app/Pen/Resources/Assets/logo.png",
            "pen/mac-app/Pen/Resources/Assets/logo.png"
        ]
        
        for path in possiblePaths {
            print("[PenWindowService] Trying placeholder image path: \(path)")
            if let image = NSImage(contentsOfFile: path) {
                imageView.image = image
                print("[PenWindowService] Using placeholder image from: \(path)")
                return
            }
        }
        
        print("[PenWindowService] Placeholder image not found at any path")
        // As a last resort, try to create a simple placeholder
        let placeholderImage = NSImage(size: NSSize(width: 20, height: 20))
        placeholderImage.lockFocus()
        NSColor.gray.setFill()
        NSRect(x: 0, y: 0, width: 20, height: 20).fill()
        placeholderImage.unlockFocus()
        imageView.image = placeholderImage
        print("[PenWindowService] Using generated placeholder image")
    }
    
    private func addUserLabelContainer(to contentView: NSView) {
        print("[PenWindowService] addUserLabelContainer called")
        let userLabelContainer = NSView(frame: NSRect(x: 232, y: 352, width: 120, height: 30))
        userLabelContainer.wantsLayer = true
        userLabelContainer.layer?.backgroundColor = NSColor.clear.cgColor
        userLabelContainer.identifier = NSUserInterfaceItemIdentifier("pen_userlabel")
        
        // Add user profile image
        let profileImage = NSImageView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
        profileImage.identifier = NSUserInterfaceItemIdentifier("pen_userlabel_img")
        
        // Set profile image if available
        if let user = userService.currentUser, let profileImageData = user.profileImage, !profileImageData.isEmpty {
            print("[PenWindowService] User has profile image")
            // Check if it's a base64-encoded image
            if profileImageData.hasPrefix("data:image") {
                // Handle base64-encoded image
                print("[PenWindowService] Profile image is base64-encoded")
                if let base64String = profileImageData.components(separatedBy: ",").last {
                    if let imageData = Data(base64Encoded: base64String) {
                        if let image = NSImage(data: imageData) {
                            profileImage.image = image
                            print("[PenWindowService] Loaded base64-encoded profile image")
                        } else {
                            // Use placeholder if image fails to load
                            print("[PenWindowService] Failed to load base64-encoded image")
                            self.setPlaceholderImage(to: profileImage)
                        }
                    } else {
                        // Use placeholder if base64 data is invalid
                        print("[PenWindowService] Invalid base64 data")
                        self.setPlaceholderImage(to: profileImage)
                    }
                } else {
                    // Use placeholder if base64 data is invalid
                    print("[PenWindowService] Invalid base64 format")
                    self.setPlaceholderImage(to: profileImage)
                }
            } else {
                // Try to load as file path
                print("[PenWindowService] Profile image is file path: \(profileImageData)")
                let possiblePaths = [
                    "Resources/ProfileImages/\(profileImageData)",
                    "mac-app/Pen/Resources/ProfileImages/\(profileImageData)",
                    "pen/mac-app/Pen/Resources/ProfileImages/\(profileImageData)"
                ]
                
                var foundImage = false
                for path in possiblePaths {
                    print("[PenWindowService] Trying profile image path: \(path)")
                    if let image = NSImage(contentsOfFile: path) {
                        profileImage.image = image
                        print("[PenWindowService] Loaded profile image from: \(path)")
                        foundImage = true
                        break
                    }
                }
                
                if !foundImage {
                    print("[PenWindowService] Profile image not found at any path")
                    // Add a placeholder image if no profile image found
                    self.setPlaceholderImage(to: profileImage)
                }
            }
        } else {
            print("[PenWindowService] No user or no profile image")
            // Add a placeholder image if no user or no profile image
            self.setPlaceholderImage(to: profileImage)
        }
        
        // Add user name text label
        let userNameLabel = NSTextField(frame: NSRect(x: 26, y: -13, width: 90, height: 30))
        userNameLabel.identifier = NSUserInterfaceItemIdentifier("pen_userlable_text")
        
        // Set user name
        if let user = userService.currentUser {
            let name = user.name
            // Trim name to fit width
            let font = NSFont.boldSystemFont(ofSize: 12)
            let trimmedName = trimTextToFitWidth(name, font: font, maxWidth: 90)
            userNameLabel.stringValue = trimmedName
            print("[PenWindowService] Set user name: \(name), trimmed to: \(trimmedName)")
        } else {
            userNameLabel.stringValue = LocalizationService.shared.localizedString(for: "no_user")
            print("[PenWindowService] Set user name to: no_user")
        }
        
        userNameLabel.isBezeled = false
        userNameLabel.drawsBackground = false
        userNameLabel.isEditable = false
        userNameLabel.isSelectable = false
        userNameLabel.font = NSFont.boldSystemFont(ofSize: 12)
        userNameLabel.textColor = NSColor.labelColor
        userNameLabel.alignment = .left
        
        userLabelContainer.addSubview(profileImage)
        userLabelContainer.addSubview(userNameLabel)
        contentView.addSubview(userLabelContainer)
        print("[PenWindowService] Added user label container to content view")
    }
    
    private func trimTextToFitWidth(_ text: String, font: NSFont, maxWidth: CGFloat) -> String {
        // Create a temporary text field to measure text width
        let tempTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: maxWidth, height: 30))
        tempTextField.font = font
        tempTextField.stringValue = text
        tempTextField.sizeToFit()
        
        // If text fits, return as is
        if tempTextField.frame.width <= maxWidth {
            return text
        }
        
        // If text doesn't fit, trim with ellipsis
        var trimmedText = text
        
        // Gradually trim characters until it fits
        while true {
            if trimmedText.count <= 3 {
                // Minimum text length reached
                return "..."
            }
            
            trimmedText = String(trimmedText.prefix(trimmedText.count - 1))
            tempTextField.stringValue = trimmedText + "..."
            tempTextField.sizeToFit()
            
            if tempTextField.frame.width <= maxWidth {
                return trimmedText + "..."
            }
        }
    }
    
    private func addManualPasteContainer(to contentView: NSView) {
        let manualPasteContainer = NSView(frame: NSRect(x: 20, y: 346, width: 300, height: 30))
        manualPasteContainer.wantsLayer = true
        manualPasteContainer.layer?.backgroundColor = NSColor.clear.cgColor
        manualPasteContainer.identifier = NSUserInterfaceItemIdentifier("pen_manual_paste")
        
        // Add paste button
        let pasteButton = NSButton(frame: NSRect(x: -1, y: 5, width: 20, height: 20))
        pasteButton.title = ""
        pasteButton.bezelStyle = .smallSquare
        pasteButton.isBordered = false
        pasteButton.image = NSImage(contentsOfFile: "\(FileManager.default.currentDirectoryPath)/Resources/Assets/paste.svg")
        pasteButton.target = self
        pasteButton.action = #selector(handlePasteButton)
        pasteButton.identifier = NSUserInterfaceItemIdentifier("pen_manual_paste_button")
        pasteButton.state = .off
        pasteButton.focusRingType = .none
        
        // Add text label
        let pasteLabel = NSTextField(frame: NSRect(x: 24, y: -8, width: 270, height: 30))
        pasteLabel.stringValue = LocalizationService.shared.localizedString(for: "paste_from_clipboard_simple")
        pasteLabel.isBezeled = false
        pasteLabel.drawsBackground = false
        pasteLabel.isEditable = false
        pasteLabel.isSelectable = false
        pasteLabel.font = NSFont.systemFont(ofSize: 12)
        pasteLabel.textColor = NSColor.labelColor
        pasteLabel.alignment = .left
        pasteLabel.identifier = NSUserInterfaceItemIdentifier("pen_manual_paste_text")
        
        manualPasteContainer.addSubview(pasteButton)
        manualPasteContainer.addSubview(pasteLabel)
        contentView.addSubview(manualPasteContainer)
    }
    
    // MARK: - UI Population Methods
    
    private func populateProvidersDropdown(providers: [AIProvider]) async {
        await MainActor.run {
            guard let contentView = window?.contentView else { return }
            
            for subview in contentView.subviews {
                if let container = subview as? NSView, container.identifier?.rawValue == "pen_controller" {
                    for subview in container.subviews {
                        if let dropdown = subview as? NSPopUpButton, dropdown.identifier?.rawValue == "pen_controller_provider" {
                            // Clear existing items
                            dropdown.removeAllItems()
                            
                            // Add providers
                            for provider in providers {
                                dropdown.addItem(withTitle: provider.name)
                            }
                            
                            // Select first provider as default
                            if !providers.isEmpty {
                                dropdown.selectItem(at: 0)
                            } else {
                                dropdown.addItem(withTitle: LocalizationService.shared.localizedString(for: "pen_no_providers_available"))
                            }
                            
                            break
                        }
                    }
                    break
                }
            }
        }
    }
    
    private func populatePromptsDropdown(prompts: [Prompt]) async {
        await MainActor.run {
            guard let contentView = window?.contentView else { return }
            
            for subview in contentView.subviews {
                if let container = subview as? NSView, container.identifier?.rawValue == "pen_controller" {
                    for subview in container.subviews {
                        if let dropdown = subview as? NSPopUpButton, dropdown.identifier?.rawValue == "pen_controller_prompts" {
                            // Clear existing items
                            dropdown.removeAllItems()
                            
                            // Add prompts
                            for prompt in prompts {
                                dropdown.addItem(withTitle: prompt.promptName)
                            }
                            
                            // Select first prompt as default
                            if !prompts.isEmpty {
                                dropdown.selectItem(at: 0)
                            } else {
                                dropdown.addItem(withTitle: LocalizationService.shared.localizedString(for: "pen_no_prompts_available"))
                            }
                            
                            break
                        }
                    }
                    break
                }
            }
        }
    }
    
    // MARK: - Error Handling Methods
    
    private func showDefaultUI() {
        // Already handled by initializeUIComponents
    }
    
    private func handleAIConfigurationFailure() async {
        await MainActor.run {
            guard let contentView = window?.contentView else { return }
            
            // Display popup message
            WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "pen_ai_configuration_failure"))
            
            // Remove any existing settings button if present
            for subview in contentView.subviews {
                if let button = subview as? NSButton, button.identifier?.rawValue == "pen_open_settings_button" {
                    button.removeFromSuperview()
                    break
                }
            }
        }
    }
    
    private func handleNoAIProviders() async {
        await MainActor.run {
            guard let contentView = window?.contentView else { return }
            
            // Display popup message
            let noAIConnectionsMessage = LocalizationService.shared.localizedString(for: "pen_no_ai_connections")
            WindowManager.shared.displayPopupMessage(noAIConnectionsMessage)
            
            // Update enhanced text field
            for subview in contentView.subviews {
                if let container = subview as? NSView, container.identifier?.rawValue == "pen_enhanced_text" {
                    for subview in container.subviews {
                        if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_enhanced_text_text" {
                            textField.stringValue = noAIConnectionsMessage
                        }
                    }
                    break
                }
            }
            
            // Remove any existing settings button if present
            for subview in contentView.subviews {
                if let button = subview as? NSButton, button.identifier?.rawValue == "pen_open_settings_button" {
                    button.removeFromSuperview()
                    break
                }
            }
        }
    }
    

    
    // MARK: - Clipboard Methods
    
    func readClipboardText() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    func isClipboardTextType() -> Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string) != nil
    }
    

    
    func loadClipboardContent(forceEnhance: Bool = false) -> String? {
        do {
            if isClipboardTextType() {
                if let clipboardText = readClipboardText() {
                    if !clipboardText.isEmpty {
                        // Check if clipboard content has changed
                        if !forceEnhance && clipboardText == currentClipboardContent {
                            // Clipboard content is the same, skip enhancement
                            print("[PenWindowService] Clipboard content unchanged, skipping enhancement")
                            return nil
                        }
                        
                        // Scenario: Paste valid text from clipboard on window launch
                        updateOriginalText(clipboardText)
                        currentClipboardContent = clipboardText
                        return clipboardText
                    } else {
                        // Scenario: Handle empty clipboard
                        displayEmptyClipboardMessage()
                        currentClipboardContent = nil
                        return nil
                    }
                } else {
                    // Scenario: Handle clipboard read failure
                    displayClipboardErrorMessage()
                    currentClipboardContent = nil
                    return nil
                }
            } else {
                // Scenario: Handle non-text clipboard content
                displayNonTextClipboardMessage()
                currentClipboardContent = nil
                return nil
            }
        } catch {
            // Scenario: Handle clipboard read failure
            print("[PenWindowService] Error reading clipboard: \(error)")
            displayClipboardErrorMessage()
            currentClipboardContent = nil
            return nil
        }
    }
    
    // MARK: - UI Update Methods
    
    private func updateOriginalText(_ text: String) {
        guard let contentView = window?.contentView else { return }
        
        for subview in contentView.subviews {
            if let container = subview as? NSView, container.identifier?.rawValue == "pen_original_text" {
                for subview in container.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_original_text_text" {
                        let maxVisibleLines = 5
                        
                        let lines = getVisibleLineCount(for: text, in: textField)
                        
                        if lines <= maxVisibleLines {
                            // Text fits, display as-is
                            textField.stringValue = text
                        } else {
                            // Text is too long, trim to 5 lines and replace last 3 characters with "..."
                            let trimmedText = trimTextToFitLines(text, in: textField, maxLines: 5)
                            textField.stringValue = trimmedText
                        }
                        
                        // Set tooltip to show full text on hover
                        textField.toolTip = text
                        break
                    }
                }
                break
            }
        }
    }
    
    private func getVisibleLineCount(for text: String, in textField: NSTextField) -> Int {
        let font = textField.font ?? NSFont.systemFont(ofSize: 12)
        let width = textField.frame.width - 10 // Account for padding
        let height = textField.frame.height
        
        // Replace newlines with spaces to treat them as normal characters
        let textWithoutNewlines = text.replacingOccurrences(of: "\n", with: " ")
        
        let textStorage = NSTextStorage(string: textWithoutNewlines, attributes: [.font: font])
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: width, height: height))
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        
        var lineCount = 0
        var glyphIndex = 0
        let textLength = textStorage.length
        
        while glyphIndex < textLength {
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)
            lineCount += 1
            glyphIndex = NSMaxRange(lineRange)
        }
        
        return lineCount
    }
    
    private func trimTextToFitLines(_ text: String, in textField: NSTextField, maxLines: Int) -> String {
        let font = textField.font ?? NSFont.systemFont(ofSize: 12)
        let width = textField.frame.width - 10 // Account for padding
        let height = textField.frame.height
        
        // Replace newlines with spaces to treat them as normal characters
        let textWithoutNewlines = text.replacingOccurrences(of: "\n", with: " ")
        
        let textStorage = NSTextStorage(string: textWithoutNewlines, attributes: [.font: font])
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: width, height: height))
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        
        // Calculate the range that fits within the text field
        let range = layoutManager.glyphRange(forBoundingRect: CGRect(x: 0, y: 0, width: width, height: height), in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: nil)
        
        // Get the trimmed text from the original text (preserving newlines)
        var trimmedText = (text as NSString).substring(to: characterRange.upperBound)
        
        // Replace last 3 characters with "..."
        if trimmedText.count >= 3 {
            trimmedText = String(trimmedText.prefix(trimmedText.count - 3)) + "..."
        } else {
            // If text is too short, just return it
            return trimmedText
        }
        
        return trimmedText
    }
    
    private func displayEmptyClipboardMessage() {
        guard let contentView = window?.contentView else { return }
        
        for subview in contentView.subviews {
            if let container = subview as? NSView, container.identifier?.rawValue == "pen_original_text" {
                for subview in container.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_original_text_text" {
                        let message = LocalizationService.shared.localizedString(for: "clipboard_empty_message")
                        textField.stringValue = message
                        textField.toolTip = message
                        break
                    }
                }
                break
            }
        }
    }
    
    private func displayClipboardErrorMessage() {
        guard let contentView = window?.contentView else { return }
        
        for subview in contentView.subviews {
            if let container = subview as? NSView, container.identifier?.rawValue == "pen_original_text" {
                for subview in container.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_original_text_text" {
                        let message = LocalizationService.shared.localizedString(for: "clipboard_access_error")
                        textField.stringValue = message
                        textField.toolTip = message
                        break
                    }
                }
                break
            }
        }
    }
    
    private func displayNonTextClipboardMessage() {
        guard let contentView = window?.contentView else { return }
        
        for subview in contentView.subviews {
            if let container = subview as? NSView, container.identifier?.rawValue == "pen_original_text" {
                for subview in container.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_original_text_text" {
                        let message = LocalizationService.shared.localizedString(for: "clipboard_non_text_message")
                        textField.stringValue = message
                        textField.toolTip = message
                        break
                    }
                }
                break
            }
        }
    }
    
    func updateEnhancedText(_ text: String) {
        guard let contentView = window?.contentView else { return }
        
        for subview in contentView.subviews {
            if let container = subview as? NSView, container.identifier?.rawValue == "pen_enhanced_text" {
                for subview in container.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_enhanced_text_text" {
                        textField.stringValue = text
                        // Set tooltip to show full text on hover
                        textField.toolTip = text
                        break
                    }
                }
                break
            }
        }
    }
    
    // MARK: - Text Enhancement Methods
    
    private func enhanceText() async {
        guard let window = window else { return }
        
        // Get selected prompt
        guard let selectedPrompt = await getSelectedPrompt() else {
            print("[PenWindowService] No prompt selected")
            return
        }
        
        // Get selected provider
        guard let selectedProvider = await getSelectedProvider() else {
            print("[PenWindowService] No provider selected")
            return
        }
        
        // Get original text
        guard let originalText = getOriginalText() else {
            print("[PenWindowService] No original text")
            return
        }
        
        // Generate prompt message
        let promptMessage = generatePromptMessage(prompt: selectedPrompt, text: originalText)
        
        // Show loading indicator
        await MainActor.run {
            showLoadingIndicator()
        }
        
        // Call AIManager.AITestCall()
        do {
            guard let aiManager = userService.aiManager else {
                print("[PenWindowService] AIManager not available")
                await MainActor.run {
                    hideLoadingIndicator()
                }
                return
            }
            
            // Configure AIManager with the selected provider
            guard let user = userService.currentUser else {
                print("[PenWindowService] No user logged in")
                await MainActor.run {
                    hideLoadingIndicator()
                }
                return
            }
            
            // Get user's AI connections
            let connections = try await aiManager.getConnections(for: user.id)
            let selectedConnection = connections.first { $0.apiProvider == selectedProvider.name }
            
            guard let connection = selectedConnection else {
                print("[PenWindowService] No connection found for selected provider")
                await MainActor.run {
                    hideLoadingIndicator()
                }
                return
            }
            
            // Configure AIManager with the selected connection
            aiManager.configure(apiKey: connection.apiKey, providerName: connection.apiProvider, userId: user.id)
            
            // Call AITestCall to get enhanced text
            let aiResponse = try await aiManager.AITestCall(
                prompt: promptMessage
            )
            
            // Update enhanced text field with trimmed response
            await MainActor.run {
                updateEnhancedText(aiResponse.content)
                hideLoadingIndicator()
            }
            
            // Save to content history
            let historyModel = ContentHistoryModel(
                userID: user.id,
                originalContent: originalText,
                enhancedContent: aiResponse.content,
                promptText: selectedPrompt.promptText,
                aiProvider: selectedProvider.name
            )
            
            Task {
                let result = await ContentHistoryService.shared.addToHistoryByUserID(history: historyModel, userID: user.id)
                switch result {
                case .success:
                    print("Content history saved successfully")
                case .failure(let error):
                    print("Error saving content history: \(error)")
                }
            }
        } catch {
            print("[PenWindowService] Failed to enhance text: \(error)")
            await MainActor.run {
                updateEnhancedText(LocalizationService.shared.localizedString(for: "pen_enhance_error"))
                hideLoadingIndicator()
            }
        }
    }
    
    private func generatePromptMessage(prompt: Prompt, text: String) -> String {
        return "PROMPT:\n\(prompt.promptText)\n\nTEXT:\n\(text)"
    }
    
    private func getSelectedPrompt() async -> Prompt? {
        // Get selected prompt title on main thread
        let selectedTitle: String? = await MainActor.run { () -> String? in
            guard let contentView = self.window?.contentView else { return nil }
            
            for subview in contentView.subviews {
                if subview.identifier?.rawValue == "pen_controller" {
                    for subview in subview.subviews {
                        if let dropdown = subview as? NSPopUpButton, dropdown.identifier?.rawValue == "pen_controller_prompts" {
                            if let selectedItem = dropdown.selectedItem {
                                return selectedItem.title
                            }
                        }
                    }
                }
            }
            return nil
        }
        
        // Find the prompt with the selected title
        guard let selectedTitle = selectedTitle, let user = userService.currentUser else { return nil }
        
        do {
            let prompts = try await promptsService.getPromptsByUserId(userId: user.id)
            return prompts.first { $0.promptName == selectedTitle }
        } catch {
            print("[PenWindowService] Failed to get prompts: \(error)")
            return nil
        }
    }
    
    private func getSelectedProvider() async -> AIProvider? {
        // Get selected provider title on main thread
        let selectedTitle: String? = await MainActor.run { () -> String? in
            guard let contentView = self.window?.contentView else { return nil }
            
            for subview in contentView.subviews {
                if subview.identifier?.rawValue == "pen_controller" {
                    for subview in subview.subviews {
                        if let dropdown = subview as? NSPopUpButton, dropdown.identifier?.rawValue == "pen_controller_provider" {
                            if let selectedItem = dropdown.selectedItem {
                                return selectedItem.title
                            }
                        }
                    }
                }
            }
            return nil
        }
        
        // Find the provider with the selected title
        guard let selectedTitle = selectedTitle, let aiManager = userService.aiManager else { return nil }
        
        do {
            let providers = try await aiManager.getProviders()
            return providers.first { $0.name == selectedTitle }
        } catch {
            print("[PenWindowService] Failed to get providers: \(error)")
            return nil
        }
    }
    
    private func getOriginalText() -> String? {
        guard let contentView = window?.contentView else { return nil }
        
        for subview in contentView.subviews {
            if subview.identifier?.rawValue == "pen_original_text" {
                for subview in subview.subviews {
                    if let textField = subview as? NSTextField, textField.identifier?.rawValue == "pen_original_text_text" {
                        return textField.toolTip ?? textField.stringValue
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - Event Handling Methods
    
    @objc private func handlePasteButton() {
        print("[PenWindowService] Paste button clicked")
        if loadClipboardContent(forceEnhance: true) != nil {
            // Trigger text enhancement if clipboard content is loaded successfully
            Task {
                await enhanceText()
            }
        }
    }
    
    @objc private func handlePromptSelectionChanged() {
        print("[PenWindowService] Prompt selection changed")
        // Trigger text enhancement when prompt selection changes
        Task {
            await enhanceText()
        }
    }
    
    @objc private func handleProviderSelectionChanged() {
        print("[PenWindowService] Provider selection changed")
        // Trigger text enhancement when provider selection changes
        Task {
            await enhanceText()
        }
    }
    
    // MARK: - UI Update Methods
    
    // MARK: - Loading Indicator Methods
    
    private func showLoadingIndicator() {
        guard let contentView = window?.contentView else { return }
        
        // Check if loading indicator already exists
        for subview in contentView.subviews {
            if subview.identifier?.rawValue == "pen_loading_indicator" {
                return
            }
        }
        
        // Find the enhanced text container to get its center
        guard let enhancedTextContainer = findEnhancedTextContainer() else { return }
        
        // Calculate center of the enhanced text container
        let containerFrame = enhancedTextContainer.frame
        let centerX = containerFrame.origin.x + containerFrame.width / 2
        let centerY = containerFrame.origin.y + containerFrame.height / 2
        
        // Create loading indicator overlay with specified size and centered position
        let loadingWidth: CGFloat = 120
        let loadingHeight: CGFloat = 45
        let loadingOverlay = NSView(frame: CGRect(
            x: centerX - loadingWidth / 2,
            y: centerY - loadingHeight / 2,
            width: loadingWidth,
            height: loadingHeight
        ))
        loadingOverlay.wantsLayer = true
        loadingOverlay.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        loadingOverlay.layer?.cornerRadius = 4.0
        loadingOverlay.identifier = NSUserInterfaceItemIdentifier("pen_loading_indicator")
        
        // Create a container for the label to ensure proper centering
        let labelContainer = NSView(frame: CGRect(x: 0, y: 0, width: loadingWidth, height: loadingHeight))
        labelContainer.autoresizesSubviews = true
        
        // Create loading text label
        let loadingLabel = NSTextField(frame: CGRect(x: 10, y: 0, width: loadingWidth - 20, height: loadingHeight))
        loadingLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_refining_content")
        loadingLabel.isBezeled = false
        loadingLabel.drawsBackground = false
        loadingLabel.isEditable = false
        loadingLabel.isSelectable = false
        loadingLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        loadingLabel.textColor = NSColor.white
        loadingLabel.alignment = .center
        loadingLabel.identifier = NSUserInterfaceItemIdentifier("pen_loading_text")
        
        // Center the label vertically by setting its frame properly
        let font = NSFont.systemFont(ofSize: 14, weight: .medium)
        let lineHeight = font.ascender - font.descender
        let labelY = (loadingHeight - lineHeight) / 2.0
        loadingLabel.frame = CGRect(x: 10, y: labelY, width: loadingWidth - 20, height: lineHeight)
        
        labelContainer.addSubview(loadingLabel)
        loadingOverlay.addSubview(labelContainer)
        contentView.addSubview(loadingOverlay, positioned: .above, relativeTo: enhancedTextContainer)
        
        // Animate fade in
        loadingOverlay.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            loadingOverlay.animator().alphaValue = 1.0
        }
        
        // Add pulse animation to the text
        animateLoadingText(loadingLabel)
    }
    
    private func hideLoadingIndicator() {
        guard let contentView = window?.contentView else { return }
        
        for subview in contentView.subviews {
            if subview.identifier?.rawValue == "pen_loading_indicator" {
                // Animate fade out
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    subview.animator().alphaValue = 0.0
                } completionHandler: {
                    subview.removeFromSuperview()
                }
                break
            }
        }
    }
    
    private func animateLoadingText(_ label: NSTextField) {
        // Create pulse animation
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.7
        animation.toValue = 1.0
        animation.duration = 1.0
        animation.repeatCount = .infinity
        animation.autoreverses = true
        
        label.layer?.add(animation, forKey: "pulseAnimation")
    }
    
    private func findEnhancedTextContainer() -> NSView? {
        guard let contentView = window?.contentView else { return nil }
        
        for subview in contentView.subviews {
            if subview.identifier?.rawValue == "pen_enhanced_text" {
                return subview
            }
        }
        return nil
    }
    
    func updateUserLabel() {
        DispatchQueue.main.async {
            if let window = self.window, let contentView = window.contentView {
                // Find the user label container
                for subview in contentView.subviews {
                    if subview.identifier == NSUserInterfaceItemIdentifier("pen_userlabel") {
                        // Find the user name label and profile image within the container
                        for labelSubview in subview.subviews {
                            if let userNameLabel = labelSubview as? NSTextField, userNameLabel.identifier == NSUserInterfaceItemIdentifier("pen_userlable_text") {
                                // Update the user name
                                if let user = self.userService.currentUser {
                                    let name = user.name
                                    // Trim name to fit width
                                    let font = NSFont.boldSystemFont(ofSize: 12)
                                    let trimmedName = self.trimTextToFitWidth(name, font: font, maxWidth: 90)
                                    userNameLabel.stringValue = trimmedName
                                } else {
                                    userNameLabel.stringValue = LocalizationService.shared.localizedString(for: "no_user")
                                }
                            } else if let profileImage = labelSubview as? NSImageView, profileImage.identifier == NSUserInterfaceItemIdentifier("pen_userlabel_img") {
                                // Update the profile image
                                if let user = self.userService.currentUser, let profileImageData = user.profileImage, !profileImageData.isEmpty {
                                    // Check if it's a base64-encoded image
                                    if profileImageData.hasPrefix("data:image") {
                                        // Handle base64-encoded image
                                        if let base64String = profileImageData.components(separatedBy: ",").last {
                                            if let imageData = Data(base64Encoded: base64String) {
                                                if let image = NSImage(data: imageData) {
                                                    profileImage.image = image
                                                } else {
                                                    // Use placeholder if image fails to load
                                                    self.setPlaceholderImage(to: profileImage)
                                                }
                                            } else {
                                                // Use placeholder if base64 data is invalid
                                                self.setPlaceholderImage(to: profileImage)
                                            }
                                        } else {
                                            // Use placeholder if base64 data is invalid
                                            self.setPlaceholderImage(to: profileImage)
                                        }
                                    } else {
                                        // Try to load as file path
                                        let possiblePaths = [
                                            "Resources/ProfileImages/\(profileImageData)",
                                            "mac-app/Pen/Resources/ProfileImages/\(profileImageData)",
                                            "pen/mac-app/Pen/Resources/ProfileImages/\(profileImageData)"
                                        ]
                                        
                                        var foundImage = false
                                        for path in possiblePaths {
                                            if let image = NSImage(contentsOfFile: path) {
                                                profileImage.image = image
                                                foundImage = true
                                                break
                                            }
                                        }
                                        
                                        if !foundImage {
                                            // Add a placeholder image if no profile image found
                                            self.setPlaceholderImage(to: profileImage)
                                        }
                                    }
                                } else {
                                    // Add a placeholder image if no user or no profile image
                                    self.setPlaceholderImage(to: profileImage)
                                }
                            }
                        }
                        break
                    }
                }
            }
        }
    }
}
