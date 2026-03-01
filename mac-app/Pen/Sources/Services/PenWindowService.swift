import Foundation
import Cocoa

// Import AIProvider from AIManager
typealias AIProvider = AIManager.AIProvider

class PenWindowService {
    private var window: BaseWindow?
    private var userService: UserService
    private var promptsService: PromptsService
    
    init() {
        self.userService = UserService.shared
        self.promptsService = PromptsService()
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
    }
    
    func hideWindow() {
        window?.orderOut(nil)
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
    
    func closeWindow() {
        window?.orderOut(nil)
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
        
        // 1. Initialize UI Components on main thread
        await MainActor.run {
            initializeUIComponents()
        }
        
        // 2. Load User Information
        await loadUserInformation()
        
        // 3. Load AI Configurations
        await loadAIConfigurations()
        
        // 4. Load Clipboard Content - Always load regardless of AI configuration status
        await MainActor.run {
            loadClipboardContent()
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
    }
    
    private func addFooterContainer(to contentView: NSView) {
        let footerHeight: CGFloat = 30
        let footerContainer = NSView(frame: NSRect(x: 0, y: 0, width: 378, height: footerHeight))
        footerContainer.wantsLayer = true
        footerContainer.layer?.backgroundColor = NSColor.clear.cgColor
        footerContainer.identifier = NSUserInterfaceItemIdentifier("pen_footer")
        
        // Add instruction label
        let instructionLabel = NSTextField(frame: NSRect(x: 30, y: -6, width: 250, height: footerHeight))
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
        
        enhancedTextContainer.addSubview(enhancedTextField)
        contentView.addSubview(enhancedTextContainer)
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
        
        originalTextContainer.addSubview(originalTextField)
        contentView.addSubview(originalTextContainer)
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
    

    
    func loadClipboardContent() -> String? {
        do {
            if isClipboardTextType() {
                if let clipboardText = readClipboardText() {
                    if !clipboardText.isEmpty {
                        // Scenario: Paste valid text from clipboard on window launch
                        updateOriginalText(clipboardText)
                        return clipboardText
                    } else {
                        // Scenario: Handle empty clipboard
                        displayEmptyClipboardMessage()
                        return nil
                    }
                } else {
                    // Scenario: Handle clipboard read failure
                    displayClipboardErrorMessage()
                    return nil
                }
            } else {
                // Scenario: Handle non-text clipboard content
                displayNonTextClipboardMessage()
                return nil
            }
        } catch {
            // Scenario: Handle clipboard read failure
            print("[PenWindowService] Error reading clipboard: \(error)")
            displayClipboardErrorMessage()
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
    
    // MARK: - Event Handling Methods
    
    @objc private func handlePasteButton() {
        print("[PenWindowService] Paste button clicked")
        loadClipboardContent()
    }
    

    

}
