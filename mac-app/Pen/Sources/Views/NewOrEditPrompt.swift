import Cocoa
import Foundation

private final class ClickThroughLabel: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

class NewOrEditPrompt: BaseWindow, NSTextViewDelegate {
    
    // MARK: - Properties
    private let promptNameLabel = NSTextField()
    private let promptNameField = NSTextField()
    private let promptLabel = NSTextField()
    private let promptTextField = NSTextView()
    private let promptPlaceholderLabel = ClickThroughLabel()
    private let saveButton = FocusableButton()
    private let cancelButton = FocusableButton()
    private let defaultPromptCheckbox = NSButton()
    
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
        
        // Position at the same location as the originating window
        if let originatingWindow = originatingWindow {
            self.setFrameOrigin(originatingWindow.frame.origin)
        }
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
        promptScrollView.autohidesScrollers = false
        
        // Create placeholder label
        promptPlaceholderLabel.frame = NSRect(x: 8, y: 8, width: promptScrollView.frame.width - 32, height: 336 - 16)
        promptPlaceholderLabel.stringValue = localizedString(for: "markdown_format_recommended_tooltip")
        promptPlaceholderLabel.textColor = NSColor.lightGray
        promptPlaceholderLabel.isBezeled = false
        promptPlaceholderLabel.drawsBackground = false
        promptPlaceholderLabel.isEditable = false
        promptPlaceholderLabel.isSelectable = false
        promptPlaceholderLabel.font = NSFont.systemFont(ofSize: 14)
        promptPlaceholderLabel.autoresizingMask = [.width]
        
        // Set up text view
        promptTextField.frame = NSRect(x: 0, y: 0, width: promptScrollView.frame.width, height: 336)
        promptTextField.font = NSFont.systemFont(ofSize: 14)
        promptTextField.drawsBackground = false // This is key to make the text view transparent
        promptTextField.wantsLayer = true
        promptTextField.layer?.backgroundColor = NSColor.clear.cgColor
        promptTextField.layer?.borderWidth = 1.0
        promptTextField.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        promptTextField.layer?.cornerRadius = 4.0
        promptTextField.autoresizingMask = [.width]
        promptTextField.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        promptTextField.minSize = NSSize(width: 0, height: 336)
        promptTextField.isVerticallyResizable = true
        promptTextField.isHorizontallyResizable = false
        promptTextField.textContainerInset = NSSize(width: 8, height: 8)
        promptTextField.textContainer?.containerSize = NSSize(width: promptScrollView.contentSize.width - 16, height: CGFloat.greatestFiniteMagnitude)
        promptTextField.textContainer?.heightTracksTextView = false
        promptTextField.textContainer?.widthTracksTextView = true
        
        // Set text view as document view and overlay placeholder in clip view
        promptScrollView.documentView = promptTextField
        promptScrollView.contentView.addSubview(promptPlaceholderLabel)
        
        // Set up text view delegate to handle placeholder visibility
        promptTextField.delegate = self
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
        
        // Set as default prompt checkbox
        defaultPromptCheckbox.frame = NSRect(x: 40, y: 26, width: 200, height: 32)
        defaultPromptCheckbox.title = localizedString(for: "set_as_default_prompt")
        defaultPromptCheckbox.bezelStyle = .regularSquare
        defaultPromptCheckbox.setButtonType(.switch)
        defaultPromptCheckbox.state = .off
        contentView.addSubview(defaultPromptCheckbox)
        
        // Set up fields based on whether it's a new prompt or edit prompt
        if let prompt = prompt {
            // Edit prompt: pre-fill with existing values
            promptNameField.stringValue = prompt.promptName
            promptTextField.string = prompt.promptText
            // Set default prompt checkbox
            defaultPromptCheckbox.state = prompt.isDefault ? .on : .off
            // Hide checkbox if prompt is already default
            defaultPromptCheckbox.isHidden = prompt.isDefault
            // Hide placeholder since we have content
            promptPlaceholderLabel.isHidden = true
            // Display in Markdown format (preserving Markdown syntax)
        } else {
            // New prompt: set placeholder text
            promptNameField.placeholderString = localizedString(for: "enter_prompt_name_placeholder")
            // Set empty string for text view, placeholder will be shown
            promptTextField.string = ""
            // Set default prompt checkbox to off
            defaultPromptCheckbox.state = .off
            // Show checkbox for new prompts
            defaultPromptCheckbox.isHidden = false
            // Show placeholder
            promptPlaceholderLabel.isHidden = false
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
        
        let isDefault = defaultPromptCheckbox.state == .on
        
        if let existingPrompt = prompt {
            // Update existing prompt
            let updatedPrompt = Prompt(
                id: existingPrompt.id,
                userId: existingPrompt.userId,
                promptName: promptName,
                promptText: promptText,
                createdDatetime: existingPrompt.createdDatetime,
                updatedDatetime: Date(),
                systemFlag: existingPrompt.systemFlag,
                isDefault: isDefault
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
                systemFlag: "PEN",
                isDefault: isDefault
            )
            onSave?(newPrompt)
        }
        
        // Close the window and unhide the originating window
        closeAndUnhideOriginatingWindow()
    }
    
    @objc private func cancelButtonClicked() {
        // Show popup message
        let message = isNewPrompt ? 
            LocalizationService.shared.localizedString(for: "create_new_prompt_canceled") : 
            LocalizationService.shared.localizedString(for: "edit_prompt_canceled")
        WindowManager.shared.displayPopupMessage(message)
        
        // Close the window and unhide the originating window
        closeAndUnhideOriginatingWindow()
    }
    
    override func closeWindow() {
        // Close the window and unhide the originating window
        closeAndUnhideOriginatingWindow()
    }
    
    private func closeAndUnhideOriginatingWindow() {
        // Close this window
        self.orderOut(nil)
        
        // Unhide the originating window
        if let originatingWindow = originatingWindow {
            originatingWindow.orderFront(nil)
            originatingWindow.makeKeyAndOrderFront(nil)
        }
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
    
    // MARK: - NSTextDelegate Methods
    
    func textDidChange(_ notification: Notification) {
        // Update placeholder visibility based on text content
        promptPlaceholderLabel.isHidden = !promptTextField.string.isEmpty
    }
    
    func textDidBeginEditing(_ notification: Notification) {
        // Hide placeholder when text view gains focus
        if promptTextField.string.isEmpty {
            promptPlaceholderLabel.isHidden = true
        }
    }
    
    func textDidEndEditing(_ notification: Notification) {
        // Show placeholder if text view is empty when losing focus
        if promptTextField.string.isEmpty {
            promptPlaceholderLabel.isHidden = false
        }
    }
}
