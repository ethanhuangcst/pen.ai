import Cocoa
import Carbon

class GeneralTabView: NSView, NSTextFieldDelegate {
    // MARK: - Properties
    private weak var parentWindow: NSWindow?
    
    // UI Elements
    private var generalForm: NSView!
    private var historyCountPopup: NSPopUpButton!
    private var languagePopup: NSPopUpButton!
    
    // Appearance section properties
    private var autoSwitchButton: NSSwitch!
    private var appearancePopup: NSPopUpButton!
    
    // Labels for language change updates
    private var shortcutLabel: NSTextField!
    private var historyLabel: NSTextField!
    private var languageLabel: NSTextField!
    private var saveButton: FocusableButton!
    
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
    
    // MARK: - Language Change
    @objc func languageDidChange() {
        // Update all UI elements with localized strings
        shortcutLabel?.stringValue = LocalizationService.shared.localizedString(for: "toggle_pen_shortcut_title")
        historyLabel?.stringValue = LocalizationService.shared.localizedString(for: "history_settings_title")
        languageLabel?.stringValue = LocalizationService.shared.localizedString(for: "language_title")
        saveButton?.title = LocalizationService.shared.localizedString(for: "save_button")
        
        // Update language popup items
        languagePopup?.item(at: 0)?.title = LocalizationService.shared.localizedString(for: "english_language")
        languagePopup?.item(at: 1)?.title = LocalizationService.shared.localizedString(for: "chinese_language")
        
        needsDisplay = true
        print("GeneralTabView: Language changed, UI updated")
    }
    
    // MARK: - Private Methods
    
    /// Sets up the General tab with all three features
    private func setupGeneralTab() {
        let contentWidth = frame.width
        let contentHeight = frame.height
        
        // Create container view for form elements
        generalForm = NSView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight))
        addSubview(generalForm)
        
        // "Toggle Pen with shortcut:" label
        shortcutLabel = NSTextField(frame: NSRect(x: 40, y: 290, width: 250, height: 25))
        shortcutLabel.stringValue = LocalizationService.shared.localizedString(for: "toggle_pen_shortcut_title")
        shortcutLabel.isBezeled = false
        shortcutLabel.drawsBackground = false
        shortcutLabel.isEditable = false
        shortcutLabel.isSelectable = false
        shortcutLabel.font = NSFont.boldSystemFont(ofSize: 14)
        generalForm.addSubview(shortcutLabel)
        
        // Shortcut recording field
        shortcutKeyField = ClickableTextField(frame: NSRect(x: 240, y: 292, width: 200, height: 25))
        shortcutKeyField.stringValue = previousShortcut
        shortcutKeyField.isEditable = false
        shortcutKeyField.isSelectable = true
        shortcutKeyField.isBezeled = true
        shortcutKeyField.delegate = self
        shortcutKeyField.clickAction = {
            [weak self] in
            print("[GeneralTabView] Click action called")
            self?.startRecording()
        }
        generalForm.addSubview(shortcutKeyField)
        
        // Create key capture view
        keyCaptureView = KeyCaptureView(frame: shortcutKeyField.bounds)
        keyCaptureView.autoresizingMask = [.width, .height]
        keyCaptureView.wantsLayer = true
        keyCaptureView.layer?.backgroundColor = NSColor.clear.cgColor
        keyCaptureView.onKeyDown = { [weak self] event in
            self?.handleKeyEvent(event)
        }
        shortcutKeyField.addSubview(keyCaptureView)
        
        // "Maximum content history:" label
        historyLabel = NSTextField(frame: NSRect(x: 40, y: 235, width: 250, height: 25))
        historyLabel.stringValue = LocalizationService.shared.localizedString(for: "history_settings_title")
        historyLabel.isBezeled = false
        historyLabel.drawsBackground = false
        historyLabel.isEditable = false
        historyLabel.isSelectable = false
        historyLabel.font = NSFont.boldSystemFont(ofSize: 14)
        generalForm.addSubview(historyLabel)
        
        // History count dropdown
        let configService = SystemConfigService.shared
        let lowValue = configService.CONTENT_HISTORY_LOW
        let mediumValue = configService.CONTENT_HISTORY_MEDIUM
        let highValue = configService.CONTENT_HISTORY_HIGH
        
        historyCountPopup = NSPopUpButton(frame: NSRect(x: 240, y: 237, width: 80, height: 25))
        historyCountPopup.addItem(withTitle: "\(lowValue)")
        historyCountPopup.addItem(withTitle: "\(mediumValue)")
        historyCountPopup.addItem(withTitle: "\(highValue)")
        
        if selectedHistoryCount == lowValue {
            historyCountPopup.selectItem(at: 0)
        } else if selectedHistoryCount == mediumValue {
            historyCountPopup.selectItem(at: 1)
        } else if selectedHistoryCount == highValue {
            historyCountPopup.selectItem(at: 2)
        }
        
        historyCountPopup.target = self
        historyCountPopup.action = #selector(historyCountSelected)
        generalForm.addSubview(historyCountPopup)
        
        // "Select language" label
        languageLabel = NSTextField(frame: NSRect(x: 40, y: 180, width: 250, height: 25))
        languageLabel.stringValue = LocalizationService.shared.localizedString(for: "language_title")
        languageLabel.isBezeled = false
        languageLabel.drawsBackground = false
        languageLabel.isEditable = false
        languageLabel.isSelectable = false
        languageLabel.font = NSFont.boldSystemFont(ofSize: 14)
        generalForm.addSubview(languageLabel)
        
        // Language dropdown
        languagePopup = NSPopUpButton(frame: NSRect(x: 240, y: 182, width: 200, height: 25))
        languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "english_language"))
        languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "chinese_language"))
        
        let currentLanguage = LocalizationService.shared.language
        languagePopup.selectItem(at: currentLanguage == .english ? 0 : 1)
        
        languagePopup.target = self
        languagePopup.action = #selector(languageSelected)
        generalForm.addSubview(languagePopup)
        
        // Set tab order explicitly
        shortcutKeyField.nextKeyView = historyCountPopup
        historyCountPopup.nextKeyView = languagePopup
        languagePopup.nextKeyView = shortcutKeyField
        
        // Add save button
        addSaveButton()
    }
    
    /// Adds a save button at the bottom right of the view
    private func addSaveButton() {
        saveButton = FocusableButton(frame: NSRect(x: 40, y: 40, width: 80, height: 32))
        saveButton.title = LocalizationService.shared.localizedString(for: "save_button")
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveButtonClicked)
        generalForm.addSubview(saveButton)
    }
    
    @objc private func saveButtonClicked() {
        print("Save button clicked")
        
        // Get current user
        guard let user = UserService.shared.currentUser else {
            print("No user logged in")
            return
        }
        
        // Get selected language
        let selectedLanguageIndex = languagePopup.indexOfSelectedItem
        let selectedLanguage: AppLanguage = selectedLanguageIndex == 0 ? .english : .chineseSimplified
        
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
                
                // Switch language if changed
                if LocalizationService.shared.language != selectedLanguage {
                    LocalizationService.shared.setLanguage(selectedLanguage)
                    print("Language switched to: \(selectedLanguage.displayName)")
                }
                
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
        
        // Set initial selection based on the user's saved history count
        if selectedHistoryCount == lowValue {
            historyCountPopup.selectItem(at: 0)
        } else if selectedHistoryCount == mediumValue {
            historyCountPopup.selectItem(at: 1)
        } else if selectedHistoryCount == highValue {
            historyCountPopup.selectItem(at: 2)
        }
    }
    
    /// Creates a section view with consistent styling
    private func createSectionView(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSView {
        let section = NSView(frame: NSRect(x: x, y: y, width: width, height: height))
        section.wantsLayer = true
        section.layer?.backgroundColor = NSColor.clear.cgColor
        return section
    }
    
    // UI Elements
    private var shortcutKeyField: ClickableTextField!
    private var keyCaptureView: KeyCaptureView!
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
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 36, width: 250, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "toggle_pen_shortcut_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        section.addSubview(titleLabel)
        
        // Shortcut key display field
        shortcutKeyField = ClickableTextField(frame: NSRect(x: 280, y: sectionHeight - 38, width: 250, height: 25))
        shortcutKeyField.stringValue = previousShortcut // Use the loaded shortcut
        shortcutKeyField.isEditable = false
        shortcutKeyField.isSelectable = true
        shortcutKeyField.backgroundColor = NSColor.textBackgroundColor
        shortcutKeyField.isBezeled = true
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
    }
    
    /// Sets up the history count section
    private func setupHistoryCountSection(_ section: NSView) {
        let sectionWidth = section.frame.width
        let sectionHeight = section.frame.height
        
        // Section title
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 30, width: 250, height: 25))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "history_settings_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        section.addSubview(titleLabel)
        
        // Get history count values from config service
        let configService = SystemConfigService.shared
        let lowValue = configService.CONTENT_HISTORY_LOW
        let mediumValue = configService.CONTENT_HISTORY_MEDIUM
        let highValue = configService.CONTENT_HISTORY_HIGH
        
        // History count dropdown
        historyCountPopup = NSPopUpButton(frame: NSRect(x: 280, y: sectionHeight - 32, width: 80, height: 25))
        historyCountPopup.addItem(withTitle: "\(lowValue)")
        historyCountPopup.addItem(withTitle: "\(mediumValue)")
        historyCountPopup.addItem(withTitle: "\(highValue)")
        
        // Set initial selection based on the user's saved history count
        if selectedHistoryCount == lowValue {
            historyCountPopup.selectItem(at: 0)
        } else if selectedHistoryCount == mediumValue {
            historyCountPopup.selectItem(at: 1)
        } else if selectedHistoryCount == highValue {
            historyCountPopup.selectItem(at: 2)
        }
        
        historyCountPopup.target = self
        historyCountPopup.action = #selector(historyCountSelected)
        section.addSubview(historyCountPopup)
    }
    
    /// Sets up the language section
    private func setupLanguageSection(_ section: NSView) {
        let sectionWidth = section.frame.width
        let sectionHeight = section.frame.height
        
        // Section title
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: sectionHeight - 28, width: 250, height: 25))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "language_title")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        section.addSubview(titleLabel)
        
        // Language popup button
        languagePopup = NSPopUpButton(frame: NSRect(x: 280, y: sectionHeight - 30, width: 250, height: 25))
        languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "english_language"))
        languagePopup.addItem(withTitle: LocalizationService.shared.localizedString(for: "chinese_language"))
        
        // Set initial selection based on current language
        let currentLanguage = LocalizationService.shared.language
        languagePopup.selectItem(at: currentLanguage == .english ? 0 : 1)
        
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
        guard let appDelegate = NSApplication.shared.delegate as? PenDelegate,
              let shortcutService = appDelegate.shortcutService else {
            print("[GeneralTabView] Failed to get ShortcutService from app delegate")
            return
        }
        
        let hasPermission = shortcutService.checkPermissions()
        
        if !hasPermission {
            print("[GeneralTabView] No accessibility permissions")
            return
        }
        
        // Store the current shortcut as the previous shortcut
        previousShortcut = shortcutKeyField.stringValue
        
        isRecording = true
        shortcutKeyField.stringValue = LocalizationService.shared.localizedString(for: "press_key_combination")
        shortcutKeyField.textColor = .systemBlue
        
        // Keep text field non-editable but make it selectable to receive events
        shortcutKeyField.isEditable = false
        shortcutKeyField.isSelectable = true
        
        // Make the key capture view the first responder
        parentWindow?.makeFirstResponder(keyCaptureView)
        
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
        print("[GeneralTabView] stopRecording called. resetStatus=\(resetStatus)")
        isRecording = false
        
        // Reset shortcut field only if requested
        if resetStatus {
            // Restore the previous shortcut
            shortcutKeyField.stringValue = previousShortcut
            shortcutKeyField.textColor = .textColor
        }
        
        // Reset text field to non-editable but keep it selectable to receive mouse events
        shortcutKeyField.isEditable = false
        shortcutKeyField.isSelectable = true
        
        // Make the shortcut field the first responder so it can receive clicks again
        parentWindow?.makeFirstResponder(shortcutKeyField)
        
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
        guard let appDelegate = NSApplication.shared.delegate as? PenDelegate,
              let shortcutService = appDelegate.shortcutService else {
            print("[GeneralTabView] Failed to get ShortcutService from app delegate for registration")
            return
        }
        shortcutService.registerShortcut(keyCode: UInt32(keyCode), modifiers: carbonModifiers)
    }

    @objc private func historyCountSelected(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        let configService = SystemConfigService.shared
        
        switch selectedIndex {
        case 0:
            selectedHistoryCount = configService.CONTENT_HISTORY_LOW
        case 1:
            selectedHistoryCount = configService.CONTENT_HISTORY_MEDIUM
        case 2:
            selectedHistoryCount = configService.CONTENT_HISTORY_HIGH
        default:
            selectedHistoryCount = configService.CONTENT_HISTORY_LOW
        }
        
        print("History count selected: \(selectedHistoryCount)")
    }
    
    @objc private func languageSelected(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        let selectedLanguage: AppLanguage = selectedIndex == 0 ? .english : .chineseSimplified
        print("Language selected: \(selectedLanguage.displayName)")
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
