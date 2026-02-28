import Cocoa
import Foundation

class PromptsTabView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    // MARK: - Properties
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let defaultLabel = NSTextField()
    private let userLabel = NSTextField()
    private var prompts: [Prompt] = []
    private var user: User?
    
    // MARK: - Initialization
    init(frame: CGRect, user: User?) {
        self.user = user
        super.init(frame: frame)
        
        // Setup view
        setupView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        // Setup view
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Set background color
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        
        // Setup UI components
        setupUserLabel()
        setupDefaultLabel()
        setupTableView()
        
        // Load mock data
        loadMockData()
    }
    
    private func setupUserLabel() {
        let windowWidth = frame.width
        let windowHeight = frame.height
        
        userLabel.frame = NSRect(x: 20, y: windowHeight - 92, width: windowWidth - 40, height: 24)
        userLabel.stringValue = "Predefined prompts for \(user?.name ?? "[User Name]")"
        userLabel.isBezeled = false
        userLabel.drawsBackground = false
        userLabel.isEditable = false
        userLabel.isSelectable = false
        userLabel.font = NSFont.boldSystemFont(ofSize: 16)
        addSubview(userLabel)
    }
    
    // MARK: - Setup Methods
    private func setupDefaultLabel() {
        let windowWidth = frame.width
        let windowHeight = frame.height
        
        defaultLabel.frame = NSRect(x: 20, y: windowHeight - 108, width: windowWidth - 40, height: 16)
        defaultLabel.stringValue = LocalizationService.shared.localizedString(for: "first_prompt_default")
        defaultLabel.isBezeled = false
        defaultLabel.drawsBackground = false
        defaultLabel.isEditable = false
        defaultLabel.isSelectable = false
        defaultLabel.font = NSFont.systemFont(ofSize: 12)
        defaultLabel.textColor = NSColor.secondaryLabelColor
        addSubview(defaultLabel)
    }
    
    private func setupTableView() {
        let windowWidth = frame.width
        let windowHeight = frame.height
        
        // Create table container with border and corner radius
        let tableContainer = NSView(frame: NSRect(x: 20, y: 50, width: windowWidth - 40, height: windowHeight - 166))
        tableContainer.wantsLayer = true
        tableContainer.layer?.backgroundColor = NSColor.white.cgColor
        tableContainer.layer?.borderWidth = 1.0
        tableContainer.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor
        tableContainer.layer?.cornerRadius = 8.0
        addSubview(tableContainer)
        
        // Create scroll view
        scrollView.frame = tableContainer.bounds
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        tableContainer.addSubview(scrollView)
        
        // Create table view
        tableView.frame = scrollView.bounds
        tableView.dataSource = self
        tableView.delegate = self
        
        // Add columns with fixed widths
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = LocalizationService.shared.localizedString(for: "prompt_name_column")
        nameColumn.width = 88
        nameColumn.minWidth = 88
        nameColumn.maxWidth = 88
        tableView.addTableColumn(nameColumn)
        
        let promptColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("prompt"))
        promptColumn.title = LocalizationService.shared.localizedString(for: "prompt_text_column")
        promptColumn.width = 288
        promptColumn.minWidth = 288
        promptColumn.maxWidth = 288
        tableView.addTableColumn(promptColumn)
        
        let editColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("edit"))
        editColumn.title = LocalizationService.shared.localizedString(for: "edit_button")
        editColumn.width = 38
        editColumn.minWidth = 38
        editColumn.maxWidth = 38
        tableView.addTableColumn(editColumn)
        
        let deleteColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("delete"))
        deleteColumn.title = LocalizationService.shared.localizedString(for: "delete_button")
        deleteColumn.width = 38
        deleteColumn.minWidth = 38
        deleteColumn.maxWidth = 38
        tableView.addTableColumn(deleteColumn)
        
        // Add visible border inside the table
        tableView.wantsLayer = true
        tableView.layer?.borderWidth = 1.0
        tableView.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.3).cgColor
        
        // Add table view to scroll view
        scrollView.documentView = tableView
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        // Create mock prompts based on prompts_sample.md
        let prompt1 = Prompt(
            id: "prompt-1",
            userId: 1,
            promptName: "Five Language Translator",
            promptText: "# Situation\n- I am located in Shanghai, China.\n- I often collaborate with people who write in multiple languages\n- I need an assistant to help me translate between languages\n\n# Task\n- Act as an expert translator\n- Follow the rules specified\n- Provide translations in multiple languages\n\n# Action Role\n- You are an expert translator\n- You speak multiple languages\n\n# Rule\n- Translate input into multiple languages\n- Add language prefixes\n- Output as plain text",
            createdDatetime: Date().addingTimeInterval(-86400), // 1 day ago
            updatedDatetime: nil,
            systemFlag: "PEN"
        )
        
        let prompt2 = Prompt(
            id: "prompt-2",
            userId: 1,
            promptName: "English Content Enhancer",
            promptText: "# Situation\n- I am a non-native English speaker\n- I need help enhancing my written English\n- My target audience is native English speakers\n\n# Task\n- Act as a professional translator\n- Enhance the English content\n- Keep the original meaning\n\n# Action Role\n- You are a professional translator\n- You are a native English speaker\n\n# Rule\n- Enhance English content\n- Follow specific scenarios like email, formal, casual\n- Output as plain text",
            createdDatetime: Date().addingTimeInterval(-43200), // 12 hours ago
            updatedDatetime: nil,
            systemFlag: "PEN"
        )
        
        // Add more mock prompts if needed
        prompts = [prompt2, prompt1] // Newest first
        
        // Reload table view
        tableView.reloadData()
    }
    
    // MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return prompts.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let prompt = prompts[row]
        
        guard let columnIdentifier = tableColumn?.identifier else { return nil }
        
        switch columnIdentifier.rawValue {
        case "name":
            return prompt.promptName
        case "prompt":
            return prompt.promptText
        default:
            return nil
        }
    }
    
    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnIdentifier = tableColumn?.identifier else { return nil }
        let prompt = prompts[row]
        
        switch columnIdentifier.rawValue {
        case "name":
            return createReadonlyTextField(text: prompt.promptName)
        case "prompt":
            return createPromptTextField(text: prompt.promptText)
        case "edit":
            return createEditButton(tag: row)
        case "delete":
            return createDeleteButton(tag: row)
        default:
            return nil
        }
    }
    
    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, canDragRowsWithIndexes rowIndexes: IndexSet, at point: NSPoint) -> Bool {
        return false
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        // Set row height to accommodate 4 rows of text
        return 70.0
    }
    
    // MARK: - UI Helper Methods
    private func createReadonlyTextField(text: String) -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 0, y: 5, width: 150, height: 60))
        textField.stringValue = trimText(text, maxLines: 1)
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.cell?.wraps = true
        textField.cell?.usesSingleLineMode = false
        
        // Add tooltip for full text
        textField.toolTip = text
        
        return textField
    }
    
    private func createPromptTextField(text: String) -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 0, y: 5, width: 400, height: 60))
        textField.stringValue = trimPromptText(text)
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: 12) // Reduced font size
        textField.cell?.wraps = true
        textField.cell?.usesSingleLineMode = false
        
        // Add tooltip for full prompt
        textField.toolTip = text
        
        return textField
    }
    
    private func createEditButton(tag: Int) -> NSButton {
        let button = NSButton(frame: NSRect(x: 9, y: 2, width: 20, height: 20))
        button.bezelStyle = .texturedRounded
        button.setButtonType(.momentaryPushIn)
        button.isBordered = false
        let image = NSImage(contentsOf: URL(fileURLWithPath: "/Users/ethanhuang/code/pen.ai/pen/mac-app/Pen/Resources/Assets/edit.svg"))
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.tag = tag
        button.target = self
        button.action = #selector(editButtonClicked)
        button.contentTintColor = NSColor.systemBlue
        return button
    }
    
    private func createDeleteButton(tag: Int) -> NSButton {
        let button = NSButton(frame: NSRect(x: 9, y: 2, width: 20, height: 20))
        button.bezelStyle = .texturedRounded
        button.setButtonType(.momentaryPushIn)
        button.isBordered = false
        let image = NSImage(contentsOf: URL(fileURLWithPath: "/Users/ethanhuang/code/pen.ai/pen/mac-app/Pen/Resources/Assets/delete.svg"))
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.tag = tag
        button.target = self
        button.action = #selector(deleteButtonClicked)
        button.contentTintColor = NSColor.systemRed
        return button
    }
    
    // MARK: - Helper Methods
    private func trimText(_ text: String, maxLines: Int) -> String {
        let lines = text.components(separatedBy: "\n")
        if lines.count <= maxLines {
            return text
        } else {
            return lines.prefix(maxLines).joined(separator: "\n") + "..."
        }
    }
    
    private func trimPromptText(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        if lines.count <= 3 {
            return text
        } else {
            return lines.prefix(3).joined(separator: "\n") + "\n..."
        }
    }
    

    
    // MARK: - Button Actions
    @objc private func editButtonClicked(_ sender: NSButton) {
        let row = sender.tag
        if row < prompts.count {
            let prompt = prompts[row]
            // Open edit window
            let editWindow = createEditWindow(for: prompt)
            editWindow.showAndFocus()
        }
    }
    
    @objc private func deleteButtonClicked(_ sender: NSButton) {
        let row = sender.tag
        if row < prompts.count {
            // Show confirmation dialog
            let alert = NSAlert()
            alert.messageText = LocalizationService.shared.localizedString(for: "delete_prompt_title")
            alert.informativeText = LocalizationService.shared.localizedString(for: "delete_prompt_confirmation")
            alert.addButton(withTitle: LocalizationService.shared.localizedString(for: "delete_button"))
            alert.addButton(withTitle: LocalizationService.shared.localizedString(for: "cancel_button"))
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Delete the prompt
                prompts.remove(at: row)
                tableView.reloadData()
                WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "prompt_deleted_successfully"))
            }
        }
    }
    
    // MARK: - Edit Window
    private func createEditWindow(for prompt: Prompt) -> BaseWindow {
        let windowSize = NSSize(width: 600, height: 500)
        let window = BaseWindow(size: windowSize, styleMask: [.titled, .closable, .resizable])
        window.title = LocalizationService.shared.localizedString(for: "edit_prompt_title")
        
        let contentView = window.createStandardContentView(size: windowSize)
        
        // Name field
        let nameLabel = NSTextField(frame: NSRect(x: 20, y: windowSize.height - 100, width: 100, height: 24))
        nameLabel.stringValue = LocalizationService.shared.localizedString(for: "name_label")
        nameLabel.isBezeled = false
        nameLabel.drawsBackground = false
        nameLabel.isEditable = false
        nameLabel.isSelectable = false
        contentView.addSubview(nameLabel)
        
        let nameField = NSTextField(frame: NSRect(x: 120, y: windowSize.height - 100, width: 460, height: 24))
        nameField.stringValue = prompt.promptName
        contentView.addSubview(nameField)
        
        // Prompt field
        let promptLabel = NSTextField(frame: NSRect(x: 20, y: windowSize.height - 140, width: 100, height: 24))
        promptLabel.stringValue = LocalizationService.shared.localizedString(for: "prompt_label")
        promptLabel.isBezeled = false
        promptLabel.drawsBackground = false
        promptLabel.isEditable = false
        promptLabel.isSelectable = false
        contentView.addSubview(promptLabel)
        
        let promptField = NSTextView(frame: NSRect(x: 120, y: 100, width: 460, height: 280))
        promptField.string = prompt.promptText
        promptField.font = NSFont.systemFont(ofSize: 14)
        
        let promptScrollView = NSScrollView(frame: NSRect(x: 120, y: 100, width: 460, height: 280))
        promptScrollView.documentView = promptField
        promptScrollView.hasVerticalScroller = true
        contentView.addSubview(promptScrollView)
        
        // Save button
        let saveButton = FocusableButton(frame: NSRect(x: 200, y: 40, width: 100, height: 32))
        saveButton.title = LocalizationService.shared.localizedString(for: "save_button")
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveButtonClicked)
        contentView.addSubview(saveButton)
        
        // Cancel button
        let cancelButton = FocusableButton(frame: NSRect(x: 320, y: 40, width: 100, height: 32))
        cancelButton.title = LocalizationService.shared.localizedString(for: "cancel_button")
        cancelButton.bezelStyle = .rounded
        cancelButton.target = window
        cancelButton.action = #selector(BaseWindow.closeWindow)
        contentView.addSubview(cancelButton)
        
        window.contentView = contentView
        return window
    }
    
    @objc private func saveButtonClicked(_ sender: NSButton) {
        // Handle save logic
        WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "prompt_updated_successfully"))
        // Close the window
        if let window = sender.window as? BaseWindow {
            window.closeWindow()
        }
        // Reload table view
        tableView.reloadData()
    }
}
