import Cocoa
import Foundation

class NewOrEditPrompt: BaseWindow {
    // MARK: - Static Properties
    public static var isWindowOpen = false
    public static var currentInstance: NewOrEditPrompt? = nil
    
    // MARK: - Properties
    private let promptNameLabel = NSTextField()
    private let promptNameField = NSTextField()
    private let promptLabel = NSTextField()
    private let promptTextField = NSTextView()
    private let saveButton = FocusableButton()
    private let cancelButton = FocusableButton()
    
    private var prompt: Prompt?
    private var isNewPrompt: Bool
    private weak var originatingWindow: NSWindow?
    
    // Callback for save action
    var onSave: ((Prompt) -> Void)?
    
    // MARK: - Initialization
    init(prompt: Prompt? = nil, originatingWindow: NSWindow? = nil) {
        self.prompt = prompt
        self.isNewPrompt = prompt == nil
        self.originatingWindow = originatingWindow
        
        // Use the same size as Preferences window
        let windowSize = NSSize(width: 600, height: 518)
        super.init(size: windowSize)
        
        // Create content view
        let contentView = createStandardContentView(size: windowSize)
        
        // Add UI components
        setupUI(contentView: contentView, windowSize: windowSize)
        
        // Set content view
        self.contentView = contentView
        
        // Recalculate key view loop
        recalculateKeyViewLoop()
        
        // Position the window relative to the originating window
        positionRelativeToOriginatingWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI(contentView: NSView, windowSize: NSSize) {
        // Add PenAI logo
        addPenAILogo(to: contentView, windowHeight: windowSize.height)
        
        // Add standard close button
        addStandardCloseButton(to: contentView, windowWidth: windowSize.width, windowHeight: windowSize.height)
        
        // Add title label
        let titleLabel = NSTextField(frame: NSRect(x: 70, y: windowSize.height - 55, width: windowSize.width - 90, height: 30))
        let title = isNewPrompt ? localizedString(for: "new_prompt_title") : localizedString(for: "edit_prompt_title")
        titleLabel.stringValue = title
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        contentView.addSubview(titleLabel)
        
        // Prompt Name input field (1st row)
        promptNameField.frame = NSRect(x: 40, y: windowSize.height - 102, width: windowSize.width - 80, height: 24)
        promptNameField.wantsLayer = true
        promptNameField.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.1).cgColor
        promptNameField.layer?.borderWidth = 1.0
        promptNameField.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        promptNameField.layer?.cornerRadius = 4.0
        contentView.addSubview(promptNameField)
        
        // Prompt text field with scroll view
        let promptScrollView = NSScrollView(frame: NSRect(x: 40, y: 44 + 20, width: 520, height: 338))
        promptScrollView.hasVerticalScroller = true
        promptTextField.frame = NSRect(x: 0, y: 0, width: promptScrollView.frame.width - 20, height: 338)
        promptTextField.font = NSFont.systemFont(ofSize: 14)
        promptTextField.wantsLayer = true
        promptTextField.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.1).cgColor
        promptTextField.layer?.borderWidth = 1.0
        promptTextField.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        promptTextField.layer?.cornerRadius = 4.0
        promptScrollView.documentView = promptTextField
        contentView.addSubview(promptScrollView)
        
        // Save button
        saveButton.frame = NSRect(x: windowSize.width - 68 - 20 - 20, y: 6 + 20, width: 68, height: 32)
        saveButton.title = localizedString(for: "save_button")
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveButtonClicked)
        contentView.addSubview(saveButton)
        
        // Cancel button
        cancelButton.frame = NSRect(x: windowSize.width - 68 - 20 - 68 - 20 - 20, y: 6 + 20, width: 68, height: 32)
        cancelButton.title = localizedString(for: "cancel_button")
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelButtonClicked)
        contentView.addSubview(cancelButton)
        
        // Set up fields based on whether it's a new prompt or edit prompt
        if let prompt = prompt {
            // Edit prompt: pre-fill with existing values
            promptNameField.stringValue = prompt.promptName
            promptTextField.string = prompt.promptText
            // Display in Markdown format (preserving Markdown syntax)
        } else {
            // New prompt: set placeholder text
            promptNameField.placeholderString = "Enter your prompt name"
            // Set placeholder text for NSTextView (since it doesn't have placeholderString property)
            promptTextField.string = "Enter the prompt - Mark down formatting highly recommended"
        }
        
        // Tooltips are not needed as we use placeholder text for new prompts
        
        // Set up tab order
        promptNameField.nextKeyView = promptTextField
        promptTextField.nextKeyView = saveButton
        saveButton.nextKeyView = cancelButton
        cancelButton.nextKeyView = promptNameField
        
        // Set initial first responder
        initialFirstResponder = promptNameField
    }
    
    // MARK: - Button Actions
    @objc private func saveButtonClicked() {
        let promptName = promptNameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let promptText = promptTextField.string
        
        guard !promptName.isEmpty,
              !promptText.isEmpty else {
            displayPopupMessage(localizedString(for: "all_fields_required"))
            return
        }
        
        if let existingPrompt = prompt {
            // Update existing prompt
            let updatedPrompt = Prompt(
                id: existingPrompt.id,
                userId: existingPrompt.userId,
                promptName: promptName,
                promptText: promptText,
                createdDatetime: existingPrompt.createdDatetime,
                updatedDatetime: Date(),
                systemFlag: existingPrompt.systemFlag
            )
            onSave?(updatedPrompt)
        } else {
            // Create new prompt
            let newPrompt = Prompt(
                id: "prompt-\(UUID().uuidString)",
                userId: 0, // Will be set by the caller
                promptName: promptName,
                promptText: promptText,
                createdDatetime: Date(),
                updatedDatetime: nil,
                systemFlag: "PEN"
            )
            onSave?(newPrompt)
        }
        
        actuallyCloseWindow()
    }
    
    @objc private func cancelButtonClicked() {
        closeWindow()
    }
    
    // MARK: - Positioning
    private func positionRelativeToOriginatingWindow() {
        if let originatingWindow = originatingWindow {
            let parentFrame = originatingWindow.frame
            let newOrigin = NSPoint(x: parentFrame.origin.x + 28, y: parentFrame.origin.y - 28)
            setFrameOrigin(newOrigin)
        } else {
            // Fallback to default positioning if no originating window
            positionRelativeToMenuBarIcon()
        }
    }
    
    // MARK: - Overrides
    override func showAndFocus() {
        // Check if a window is already open
        if NewOrEditPrompt.isWindowOpen {
            return // Prevent multiple instances
        }
        
        // Set window as open
        NewOrEditPrompt.isWindowOpen = true
        
        // Set current instance
        NewOrEditPrompt.currentInstance = self
        
        // Set activation policy and install main menu for system shortcuts
        NSApp.setActivationPolicy(.regular)
        WindowManager.installMainMenu()
        
        // Set window properties to ensure it stays in front
        self.level = .modalPanel // Highest window level, stays above all others
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        
        // Make the window modal (blocks interaction with other windows)
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        
        // Ensure the window stays in front even if other windows are clicked
        self.makeKey()
        self.orderFrontRegardless()
        
        // Add observer for app activation to ensure window stays in front
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        
        // Set first responder to the first text field
        if let contentView = self.contentView {
            for subview in contentView.subviews {
                if let textField = subview as? NSTextField, textField.isEditable {
                    self.makeFirstResponder(textField)
                    break
                }
                // Check subviews recursively
                if let firstResponder = self.findFirstFocusableElement(in: subview) {
                    self.makeFirstResponder(firstResponder)
                    break
                }
            }
        }
        
        // Make the window modal
        NSApp.runModal(for: self)
    }
    
    /// Ensures the window stays in front when the app becomes active
    @objc private func appDidBecomeActive() {
        // Force the window to the front and make it key
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        self.makeKey()
    }
    
    /// Brings the window to the front and makes it key
    public func bringToFront() {
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        self.makeKey()
    }
    
    override func closeWindow() {
        // Show popup message
        let message = isNewPrompt ? 
            LocalizationService.shared.localizedString(for: "create_new_prompt_canceled") : 
            LocalizationService.shared.localizedString(for: "edit_prompt_canceled")
        WindowManager.displayPopupMessage(message)
        
        // Close the window
        actuallyCloseWindow()
    }
    
    private func actuallyCloseWindow() {
        // Reset window open status
        NewOrEditPrompt.isWindowOpen = false
        
        // Clear current instance
        NewOrEditPrompt.currentInstance = nil
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
        
        // Stop modal and close window
        NSApp.stopModal()
        orderOut(nil)
    }
    
    /// Recursively finds the first focusable UI element in a view hierarchy
    private func findFirstFocusableElement(in view: NSView?) -> NSView? {
        guard let view = view else { return nil }
        
        // First pass: find only text fields
        for subview in view.subviews {
            if let textField = subview as? NSTextField, textField.isEditable, textField.acceptsFirstResponder {
                return textField
            }
            if let focusableElement = findFirstFocusableElement(in: subview) {
                return focusableElement
            }
        }
        
        // Second pass: if no text fields found, look for other focusable elements except close buttons
        for subview in view.subviews {
            if subview.acceptsFirstResponder, !(subview is NSButton) {
                return subview
            }
            if let focusableElement = findFirstFocusableElement(in: subview) {
                return focusableElement
            }
        }
        
        return nil
    }
}
