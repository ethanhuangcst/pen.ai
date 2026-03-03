import Cocoa
import Carbon

class GeneralTabView: NSView, NSTextFieldDelegate {
    // MARK: - Properties
    private weak var parentWindow: NSWindow?
    
    // UI Elements
    
    private var historyCountLow: FocusableButton!
    private var historyCountMedium: FocusableButton!
    private var historyCountHigh: FocusableButton!
    
    private var languagePopup: NSPopUpButton!
    
    // Appearance section properties
    private var autoSwitchButton: NSSwitch!
    private var appearancePopup: NSPopUpButton!
    
    // MARK: - Initialization
    init(frame: CGRect, parentWindow: NSWindow) {
        self.parentWindow = parentWindow
        super.init(frame: frame)
        
        wantsLayer = true
        layer?.backgroundColor = ColorService.shared.backgroundColorCGColor
        
        // Load saved shortcut from UserDefaults
        loadSavedShortcut()
        
        // Load user's saved history count
        loadSavedHistoryCount()
        
        setupGeneralTab()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    /// Sets up the General tab with all three features
    private func setupGeneralTab() {
        let contentWidth = frame.width
        let contentHeight = frame.height
        
        // Section spacing
        let sectionHeight: CGFloat = 100
        let sectionSpacing: CGFloat = 20
        
        // Shortcut key section
        let shortcutSection = createSectionView(x: 20, y: contentHeight - sectionHeight - 70, width: contentWidth - 40, height: sectionHeight)
        setupShortcutKeySection(shortcutSection)
        addSubview(shortcutSection)
        
        // History count section - fixed top edge and increased height by 10px
        let historySection = createSectionView(x: 20, y: contentHeight - (sectionHeight * 2) - sectionSpacing - 32, width: contentWidth - 40, height: sectionHeight - 28)
        setupHistoryCountSection(historySection)
        addSubview(historySection)
        
        // Language section - moved 18px down
        let languageSection = createSectionView(x: 20, y: contentHeight - 342, width: contentWidth - 40, height: sectionHeight - 20)
        setupLanguageSection(languageSection)
        addSubview(languageSection)
        
        // Appearance section - DISABLED for now, always use light mode
        // let appearanceSection = createSectionView(x: 20, y: contentHeight - 442, width: contentWidth - 40, height: sectionHeight + 10)
        // setupAppearanceSection(appearanceSection)
        // addSubview(appearanceSection)
        
        // Set tab order explicitly
        historyCountLow.nextKeyView = historyCountMedium
        historyCountMedium.nextKeyView = historyCountHigh
        historyCountHigh.nextKeyView = languagePopup
        // languagePopup.nextKeyView = autoSwitchButton
        // autoSwitchButton.nextKeyView = appearancePopup
        // appearancePopup.nextKeyView = historyCountLow
        languagePopup.nextKeyView = historyCountLow
        
        // Add save button at the bottom right
        addSaveButton()
    }
    
    /// Adds a save button at the bottom right of the view
    private func addSaveButton() {
        let saveButton = FocusableButton(frame: NSRect(x: 20, y: 15, width: 80, height: 32))
        saveButton.title = LocalizationService.shared.localizedString(for: "save_button")
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveButtonClicked)
        addSubview(saveButton)
    }
    
    @objc private func saveButtonClicked() {
        print("Save button clicked")
        
        // Get current user
        guard let user = UserService.shared.currentUser else {
            print("No user logged in")
            statusLabel.stringValue = LocalizationService.shared.localizedString(for: "settings_save_error")
            statusLabel.textColor = .systemRed
            return
        }
        
        // Update user with selected history count
        Task {
            let success = await AuthenticationService.shared.updateUser(
                id: user.id,
                name: user.name,
                email: user.email,
                penContentHistory: selectedHistoryCount
            )
            
            if success {
                print("User updated successfully")
                statusLabel.stringValue = LocalizationService.shared.localizedString(for: "settings_saved_successfully")
                statusLabel.textColor = .systemGreen
                
                // Update the global user object with the new history count
                let updatedUser = User(id: user.id, name: user.name, email: user.email, profileImage: user.profileImage, createdAt: user.createdAt, systemFlag: user.systemFlag, penContentHistory: selectedHistoryCount)
                UserService.shared.currentUser = updatedUser
                
                // Update the local selectedHistoryCount and radio buttons
                self.selectedHistoryCount = selectedHistoryCount
                self.updateRadioButtons()
                
                // Show pop-up message "General settings saved"
                if let parentWindow = self.parentWindow as? BaseWindow {
                    parentWindow.displayPopupMessage(LocalizationService.shared.localizedString(for: "general_settings_saved"))
                }
            } else {
                print("Failed to update user")
                statusLabel.stringValue = LocalizationService.shared.localizedString(for: "settings_save_error")
                statusLabel.textColor = .systemRed
            }
        }
    }
    
    /// Called when the view is about to be displayed
    override func viewWillDraw() {
        super.viewWillDraw()
        // Reload the saved history count every time the view is drawn
        loadSavedHistoryCount()
        // Update the radio buttons based on the loaded value
        updateRadioButtons()
    }
    
    /// Updates the radio buttons based on the selectedHistoryCount
    private func updateRadioButtons() {
        // Get history count values from config service
        let configService = SystemConfigService.shared
        let lowValue = configService.CONTENT_HISTORY_LOW
        let mediumValue = configService.CONTENT_HISTORY_MEDIUM
        let highValue = configService.CONTENT_HISTORY_HIGH
        
        // Set the correct radio button based on the user's saved history count
        if selectedHistoryCount == lowValue {
            historyCountLow.state = .on
        } else if selectedHistoryCount == mediumValue {
            historyCountMedium.state = .on
        } else if selectedHistoryCount == highValue {
            historyCountHigh.state = .on
        }
    }
    
    /// Creates a section view with consistent styling
    private func createSectionView(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSView {
        let section = NSView(frame: NSRect(x: x, y: y, width: width, height: height))
        section.wantsLayer = true
        section.layer?.backgroundColor = NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0).cgColor
        section.layer?.cornerRadius = 8
        return section
    }
    
    // UI Elements
    private var shortcutKeyField: ClickableTextField!
    private var keyCaptureView: KeyCaptureView!
    private var statusLabel: NSTextField!
    private var isRecording: Bool = false
    private var mouseEventMonitor: Any? = nil
    private var previousShortcut: String = "Command+Option+P" // Default shortcut
    private var selectedHistoryCount: Int = 10 // Default value
    
    /// Loads the user's saved history count
    private func loadSavedHistoryCount() {
        if let user = UserService.shared.currentUser {
            selectedHistoryCount = user.penContentHistory
            print("GeneralTabView: Loaded saved history count: \(selectedHistoryCount) from user: \(user.name)")
            print("GeneralTabView: User penContentHistory: \(user.penContentHistory)")
        } else {
            print("GeneralTabView: No user logged in, using default history count: \(selectedHistoryCount)")
        }
    }
    
    // UserDefaults key for shortcut storage
    private let shortcutKeyDefaultsKey = "pen.shortcutKey"
    
    /// Loads the saved shortcut from UserDefaults
    private func loadSavedShortcut() {
        let defaults = UserDefaults.standard
        if let savedShortcut = defaults.string(forKey: shortcutKeyDefaultsKey) {
            previousShortcut = savedShortcut
        }
    }
    
    /// Saves the shortcut to UserDefaults
    private func saveShortcut(_ shortcut: String) {
        let defaults = UserDefaults.standard
        defaults.set(shortcut, forKey: shortcutKeyDefaultsKey)
        print("[GeneralTabView] Saved shortcut: \(shortcut)")
    }
    
    /// Sets up the shortcut key customization section
    private func setupShortcutKeySection(_ section: NSView) {
        let sectionWidth = section.frame.width
        let sectionHeight = section.frame.height
        
        // Section title
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 30, width: 250, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "toggle_pen_shortcut_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        section.addSubview(titleLabel)
        
        // Shortcut key display field
        shortcutKeyField = ClickableTextField(frame: NSRect(x: 280, y: sectionHeight - 28, width: 238, height: 27))
        shortcutKeyField.stringValue = previousShortcut // Use the loaded shortcut
        shortcutKeyField.isEditable = false
        shortcutKeyField.isSelectable = true
        shortcutKeyField.backgroundColor = NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        shortcutKeyField.layer?.cornerRadius = 4
        shortcutKeyField.layer?.borderWidth = 1
        shortcutKeyField.layer?.borderColor = NSColor.separatorColor.cgColor
        shortcutKeyField.clickAction = {
            [weak self] in
            print("[GeneralTabView] Click action called")
            self?.startRecording()
        }
        section.addSubview(shortcutKeyField)
        
        // Create key capture view
        keyCaptureView = KeyCaptureView(frame: shortcutKeyField.bounds)
        keyCaptureView.autoresizingMask = [.width, .height]
        keyCaptureView.wantsLayer = true
        keyCaptureView.layer?.backgroundColor = NSColor.clear.cgColor
        keyCaptureView.onKeyDown = { [weak self] event in
            self?.handleKeyEvent(event)
        }
        shortcutKeyField.addSubview(keyCaptureView)
        
        // Status label - moved 30px down
        statusLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 168, width: 380, height: 20))
        statusLabel.stringValue = LocalizationService.shared.localizedString(for: "record_shortcut_prompt")
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = false
        statusLabel.isEditable = false
        statusLabel.isSelectable = false
        statusLabel.textColor = .systemGray
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        section.addSubview(statusLabel)
        
        // Permission info label - moved 30px down
        let permissionLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 188, width: 380, height: 20))
        permissionLabel.stringValue = LocalizationService.shared.localizedString(for: "accessibility_permission_note")
        permissionLabel.isBezeled = false
        permissionLabel.drawsBackground = false
        permissionLabel.isEditable = false
        permissionLabel.isSelectable = false
        permissionLabel.textColor = .systemGray
        permissionLabel.font = NSFont.systemFont(ofSize: 11)
        section.addSubview(permissionLabel)
    }
    
    /// Sets up the history count section
    private func setupHistoryCountSection(_ section: NSView) {
        let sectionWidth = section.frame.width
        let sectionHeight = section.frame.height
        
        // Section title
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 30, width: 200, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "history_settings_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        section.addSubview(titleLabel)
        
        // History count label
        let historyLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 60, width: 200, height: 20))
        historyLabel.stringValue = LocalizationService.shared.localizedString(for: "content_history_to_save")
        historyLabel.isBezeled = false
        historyLabel.drawsBackground = false
        historyLabel.isEditable = false
        historyLabel.isSelectable = false
        section.addSubview(historyLabel)
        
        // Get history count values from config service
        let configService = SystemConfigService.shared
        let lowValue = configService.CONTENT_HISTORY_LOW
        let mediumValue = configService.CONTENT_HISTORY_MEDIUM
        let highValue = configService.CONTENT_HISTORY_HIGH
        
        // History count options
        let optionWidth: CGFloat = 80
        let optionHeight: CGFloat = 28
        let optionSpacing: CGFloat = 10
        
        historyCountLow = createHistoryOptionButton(title: "\(lowValue)", x: 220, y: sectionHeight - 60, width: optionWidth, height: optionHeight)
        section.addSubview(historyCountLow)
        
        historyCountMedium = createHistoryOptionButton(title: "\(mediumValue)", x: 220 + optionWidth + optionSpacing, y: sectionHeight - 60, width: optionWidth, height: optionHeight)
        section.addSubview(historyCountMedium)
        
        historyCountHigh = createHistoryOptionButton(title: "\(highValue)", x: 220 + (optionWidth + optionSpacing) * 2, y: sectionHeight - 60, width: optionWidth, height: optionHeight)
        section.addSubview(historyCountHigh)
        
        // Group the radio buttons
        historyCountLow.setButtonType(.radio)
        historyCountMedium.setButtonType(.radio)
        historyCountHigh.setButtonType(.radio)
        
        // Set the correct radio button based on the user's saved history count
        if selectedHistoryCount == lowValue {
            historyCountLow.state = .on
        } else if selectedHistoryCount == mediumValue {
            historyCountMedium.state = .on
        } else if selectedHistoryCount == highValue {
            historyCountHigh.state = .on
        }
    }
    
    /// Creates a history option button
    private func createHistoryOptionButton(title: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> FocusableButton {
        let button = FocusableButton(frame: NSRect(x: x, y: y, width: width, height: height))
        button.title = title
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(historyCountSelected)
        return button
    }
    
    /// Sets up the language section
    private func setupLanguageSection(_ section: NSView) {
        let sectionWidth = section.frame.width
        let sectionHeight = section.frame.height
        
        // Section title
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 28, width: 200, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "language_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        section.addSubview(titleLabel)
        
        // Language label
        let languageLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 58, width: 150, height: 20))
        languageLabel.stringValue = LocalizationService.shared.localizedString(for: "select_language")
        languageLabel.isBezeled = false
        languageLabel.drawsBackground = false
        languageLabel.isEditable = false
        languageLabel.isSelectable = false
        section.addSubview(languageLabel)
        
        // Language popup button
        languagePopup = NSPopUpButton(frame: NSRect(x: 170, y: sectionHeight - 63, width: 200, height: 28))
        languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "english_language"))
        languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "chinese_language"))
        languagePopup.selectItem(at: 0) // Default to English
        languagePopup.target = self
        languagePopup.action = #selector(languageSelected)
        section.addSubview(languagePopup)
    }
    
    private func setupAppearanceSection(_ section: NSView) {
        let sectionHeight = section.bounds.height
        
        // Section title
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 28, width: 200, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "appearance_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        section.addSubview(titleLabel)
        
        // Auto-switch label
        let autoSwitchLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 58, width: 200, height: 20))
        autoSwitchLabel.stringValue = LocalizationService.shared.localizedString(for: "auto_switch_appearance")
        autoSwitchLabel.isBezeled = false
        autoSwitchLabel.drawsBackground = false
        autoSwitchLabel.isEditable = false
        autoSwitchLabel.isSelectable = false
        section.addSubview(autoSwitchLabel)
        
        // Auto-switch button
        autoSwitchButton = NSSwitch(frame: NSRect(x: 230, y: sectionHeight - 60, width: 50, height: 25))
        autoSwitchButton.state = SystemConfigService.shared.autoSwitchAppearance ? .on : .off
        autoSwitchButton.target = self
        autoSwitchButton.action = #selector(autoSwitchChanged)
        section.addSubview(autoSwitchButton)
        
        // Appearance label
        let appearanceLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 88, width: 150, height: 20))
        appearanceLabel.stringValue = LocalizationService.shared.localizedString(for: "appearance_mode")
        appearanceLabel.isBezeled = false
        appearanceLabel.drawsBackground = false
        appearanceLabel.isEditable = false
        appearanceLabel.isSelectable = false
        section.addSubview(appearanceLabel)
        
        // Appearance popup button
        appearancePopup = NSPopUpButton(frame: NSRect(x: 170, y: sectionHeight - 93, width: 200, height: 28))
        appearancePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "light_mode"))
        appearancePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "dark_mode"))
        
        // Set initial selection based on saved preference
        if let savedAppearance = SystemConfigService.shared.manualAppearance {
            if savedAppearance == .darkAqua {
                appearancePopup.selectItem(at: 1)
            } else {
                appearancePopup.selectItem(at: 0)
            }
        } else {
            appearancePopup.selectItem(at: 0) // Default to Light
        }
        
        appearancePopup.target = self
        appearancePopup.action = #selector(appearanceSelected)
        appearancePopup.isEnabled = !SystemConfigService.shared.autoSwitchAppearance
        section.addSubview(appearancePopup)
        
        // Description label
        let descriptionLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 115, width: 400, height: 20))
        descriptionLabel.stringValue = LocalizationService.shared.localizedString(for: "auto_switch_appearance_description")
        descriptionLabel.isBezeled = false
        descriptionLabel.drawsBackground = false
        descriptionLabel.isEditable = false
        descriptionLabel.isSelectable = false
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.font = NSFont.systemFont(ofSize: 11)
        section.addSubview(descriptionLabel)
    }
    
    // MARK: - Actions

    @objc func startRecording() {
        print("[GeneralTabView] startRecording called, isRecording=\(isRecording)")
        
        if isRecording {
            // Stop recording
            print("[GeneralTabView] Already recording, stopping")
            stopRecording()
            return
        }
        
        // Request permissions first
        let shortcutService = ShortcutService()
        let hasPermission = shortcutService.checkPermissions()
        
        if !hasPermission {
            statusLabel.stringValue = LocalizationService.shared.localizedString(for: "accessibility_permission_required")
            statusLabel.textColor = .systemRed
            print("[GeneralTabView] No accessibility permissions")
            return
        }
        
        // Store the current shortcut as the previous shortcut
        previousShortcut = shortcutKeyField.stringValue
        
        isRecording = true
        shortcutKeyField.stringValue = LocalizationService.shared.localizedString(for: "press_key_combination")
        shortcutKeyField.textColor = .systemBlue
        statusLabel.stringValue = LocalizationService.shared.localizedString(for: "press_key_combination_instruction")
        statusLabel.textColor = .systemBlue
        
        // Keep text field non-editable but make it selectable to receive events
        shortcutKeyField.isEditable = false
        shortcutKeyField.isSelectable = true
        
        // Add mouse down monitor to detect clicks outside the text field
        mouseEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] (event) in
            guard let self = self, self.isRecording else { return event }
            
            // Check if the click is outside the text field
            let mousePoint = self.convert(event.locationInWindow, from: nil)
            if !self.shortcutKeyField.frame.contains(mousePoint) {
                print("[GeneralTabView] Clicked outside text field, canceling recording")
                self.stopRecording()
            }
            
            return event
        }
        
        // Make the key capture view first responder to capture key events
        DispatchQueue.main.async {
            let becameResponder = self.parentWindow?.makeFirstResponder(self.keyCaptureView)
            print("[GeneralTabView] makeFirstResponder returned \(becameResponder ?? false)")
            print("[GeneralTabView] First responder:", self.parentWindow?.firstResponder ?? "nil")
            print("[GeneralTabView] Started recording shortcut")
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        print("[GeneralTabView] Key event received: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")
        
        // Process the key event to get the shortcut combination
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags
        
        // Convert key code and modifiers to readable string
        if let shortcutString = self.keyEventToShortcutString(event: event) {
            print("[GeneralTabView] Shortcut string: \(shortcutString)")
            
            // Check for shortcut conflicts
            if self.checkShortcutConflict(shortcutString) {
                // Stop recording first
                self.stopRecording(resetStatus: false)
                
                // Show pop-up message for conflict
                if let parentWindow = self.parentWindow as? BaseWindow {
                    let conflictMessage = String(format: LocalizationService.shared.localizedString(for: "shortcut_conflict"), shortcutString)
                    parentWindow.displayPopupMessage(conflictMessage)
                }
                
                // Restore the previous shortcut
                self.shortcutKeyField.stringValue = self.previousShortcut
                self.shortcutKeyField.textColor = .textColor
                
                // Print terminal message
                print(" *************************************** Shortcut conflict !! ***********************************")
                
                return
            }
            
            // Check if the shortcut is the same as the previous one
            if shortcutString == self.previousShortcut {
                // Stop recording first
                self.stopRecording(resetStatus: false)
                
                // Update the display
                self.shortcutKeyField.stringValue = shortcutString
                self.shortcutKeyField.textColor = .textColor
                self.statusLabel.stringValue = LocalizationService.shared.localizedString(for: "shortcut_recorded_successfully")
                self.statusLabel.textColor = .systemGreen
                
                // Show success message using generic pop-up
                if let parentWindow = self.parentWindow as? BaseWindow {
                    let successMessage = String(format: LocalizationService.shared.localizedString(for: "custom_shortcut_set"), shortcutString)
                    parentWindow.displayPopupMessage(successMessage)
                }
                
                // Save the shortcut to UserDefaults
                self.saveShortcut(shortcutString)
                
                // Print terminal message
                print(" ############################# Same shortcut !! ***********************************")
                
                return
            }
            
            // Update the previous shortcut to the new one
            self.previousShortcut = shortcutString
            
            // Stop recording
            self.stopRecording()
            
            // Update the display
            self.shortcutKeyField.stringValue = shortcutString
            self.shortcutKeyField.textColor = .textColor
            self.statusLabel.stringValue = LocalizationService.shared.localizedString(for: "shortcut_recorded_successfully")
            self.statusLabel.textColor = .systemGreen
            
            // Register the new shortcut
            self.registerNewShortcut(keyCode: keyCode, modifiers: modifiers)
            print("[GeneralTabView] Shortcut registered")
            
            // Show success message using generic pop-up
            if let parentWindow = self.parentWindow as? BaseWindow {
                let successMessage = String(format: LocalizationService.shared.localizedString(for: "custom_shortcut_set"), shortcutString)
                parentWindow.displayPopupMessage(successMessage)
            }
            
            // Save the shortcut to UserDefaults
            self.saveShortcut(shortcutString)
            
            // Print terminal message
            print(" ############################# New Shortcut Registered !! #############################")
        }
    }
    
    private func stopRecording(resetStatus: Bool = true) {
        print("[GeneralTabView] stopRecording called, resetStatus=\(resetStatus)")
        isRecording = false
        
        // Reset status label only if requested
        if resetStatus {
            statusLabel.stringValue = LocalizationService.shared.localizedString(for: "record_shortcut_prompt")
            statusLabel.textColor = .systemGray
            
            // Restore the previous shortcut
            shortcutKeyField.stringValue = previousShortcut
            shortcutKeyField.textColor = .textColor
        }
        
        // Resign first responder to allow the text field to receive mouse events again
        _ = shortcutKeyField.resignFirstResponder()
        
        // Reset text field to non-editable but keep it selectable to receive mouse events
        shortcutKeyField.isEditable = false
        shortcutKeyField.isSelectable = true
        
        // Remove the mouse event monitor
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
            print("[GeneralTabView] Mouse event monitor removed")
        }
        

        
        print("[GeneralTabView] stopRecording completed, isRecording=\(isRecording)")
    }
    
    private func keyEventToShortcutString(event: NSEvent) -> String? {
        var shortcutComponents: [String] = []
        
        // Check modifiers
        if event.modifierFlags.contains(.command) {
            shortcutComponents.append("Command")
        }
        if event.modifierFlags.contains(.option) {
            shortcutComponents.append("Option")
        }
        if event.modifierFlags.contains(.shift) {
            shortcutComponents.append("Shift")
        }
        if event.modifierFlags.contains(.control) {
            shortcutComponents.append("Control")
        }
        
        // Get the key character or special key
        let keyCode = event.keyCode
        
        // First try to get the character
        if let keyChar = event.charactersIgnoringModifiers?.uppercased(), !keyChar.isEmpty {
            // Skip modifier keys themselves
            if !isModifierKey(keyCode: keyCode) {
                shortcutComponents.append(keyChar)
            }
        } else {
            // Handle special keys
            let specialKey = specialKeyName(for: keyCode)
            if !specialKey.isEmpty {
                shortcutComponents.append(specialKey)
            } else {
                return nil // Skip if no valid key
            }
        }
        
        // Make sure we have at least one modifier and one key
        if shortcutComponents.count < 2 {
            return nil
        }
        
        return shortcutComponents.joined(separator: "+" )
    }
    
    private func isModifierKey(keyCode: UInt16) -> Bool {
        // Key codes for modifier keys
        switch keyCode {
        case 55: return true // Shift
        case 56: return true // Option
        case 59: return true // Control
        case 63: return true // Right Command
        case 61: return true // Right Option
        case 62: return true // Right Control
        default: return false
        }
    }
    
    private func specialKeyName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 123: return "Left"
        case 124: return "Right"
        case 125: return "Down"
        case 126: return "Up"
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 53: return "Escape"
        default: return ""
        }
    }
    
    private func registerNewShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        // Convert modifiers to Carbon modifiers
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        
        // Register the shortcut
        let shortcutService = ShortcutService()
        shortcutService.registerShortcut(keyCode: UInt32(keyCode), modifiers: carbonModifiers)
    }

    @objc private func historyCountSelected(_ sender: FocusableButton) {
        // Save selected history count
        if let count = Int(sender.title) {
            selectedHistoryCount = count
            print("History count selected: \(selectedHistoryCount)")
        }
    }
    
    @objc private func languageSelected(_ sender: NSPopUpButton) {
        // TODO: Save selected language to preferences
        if let selectedItem = sender.selectedItem {
            print("Language selected: \(selectedItem.title)")
        }
    }
    
    @objc private func autoSwitchChanged(_ sender: NSSwitch) {
        let isAutoSwitch = sender.state == .on
        SystemConfigService.shared.autoSwitchAppearance = isAutoSwitch
        
        // Enable/disable appearance popup based on auto-switch state
        appearancePopup.isEnabled = !isAutoSwitch
        
        if isAutoSwitch {
            // Reset to system appearance
            NSApplication.shared.windows.forEach { window in
                window.appearance = nil
            }
        } else {
            // Apply manual appearance
            appearanceSelected(appearancePopup)
        }
        
        print("Auto-switch appearance: \(isAutoSwitch)")
    }
    
    @objc private func appearanceSelected(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        let appearance: NSAppearance.Name? = selectedIndex == 1 ? .darkAqua : .aqua
        
        SystemConfigService.shared.manualAppearance = appearance
        
        // Apply appearance to all windows
        if let appearanceName = appearance {
            let nsAppearance = NSAppearance(named: appearanceName)
            NSApplication.shared.windows.forEach { window in
                window.appearance = nsAppearance
            }
        }
        
        print("Appearance selected: \(selectedIndex == 1 ? "Dark" : "Light")")
    }
    
    // MARK: - Private Methods
    
    /// Checks if the shortcut key combination conflicts with existing shortcuts
    private func checkShortcutConflict(_ shortcut: String) -> Bool {
        // Common system shortcuts that should be avoided
        let systemShortcuts = [
            "Command+Q",           // Quit application
            "Command+W",           // Close window
            "Command+S",           // Save
            "Command+O",           // Open
            "Command+N",           // New
            "Command+C",           // Copy
            "Command+V",           // Paste
            "Command+X",           // Cut
            "Command+Z",           // Undo
            "Command+Shift+Z",     // Redo
            "Command+A",           // Select all
            "Command+F",           // Find
            "Command+G",           // Find next
            "Command+H",           // Hide
            "Command+M",           // Minimize
            "Command+Option+M",    // Minimize all
            "Command+Space",       // Spotlight
            "Command+Tab",         // App switcher
            "Control+Command+Space", // Emoji picker
            "Command+Shift+3",     // Screenshot entire screen
            "Command+Shift+4",     // Screenshot selection
            "Command+Shift+5",     // Screenshot toolbar
        ]
        
        // Check if the shortcut is in the system shortcuts list
        if systemShortcuts.contains(shortcut) {
            return true
        }
        
        // TODO: Add additional conflict detection for application-specific shortcuts
        // This could include checking against other Pen shortcuts or third-party app shortcuts
        
        return false
    }
    

}
