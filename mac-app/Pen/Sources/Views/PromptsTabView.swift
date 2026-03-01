import Cocoa
import Foundation

class PromptsTabView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    // MARK: - Properties
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let defaultLabel = NSTextField()
    private let userLabel = NSTextField()
    private let addButton = FocusableButton()
    private let emptyStateView = NSView()
    private let emptyStateLabel = NSTextField()
    private var prompts: [Prompt] = []
    private var user: User?
    private weak var parentWindow: NSWindow?
    private let promptsService = PromptsService()
    
    // MARK: - Initialization
    init(frame: CGRect, user: User?, parentWindow: NSWindow? = nil) {
        self.user = user
        self.parentWindow = parentWindow
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
        setupActionButtons()
        
        // Load prompts from database
        loadPromptsFromDatabase()
    }
    
    private func loadPromptsFromDatabase() {
        guard let userId = user?.id else {
            print("[PromptsTabView] No user ID available")
            return
        }
        
        Task {
            do {
                let loadedPrompts = try await promptsService.getPromptsByUserId(userId: userId)
                DispatchQueue.main.async {
                    self.prompts = loadedPrompts
                    self.tableView.reloadData()
                    self.updateEmptyStateView()
                }
            } catch {
                print("[PromptsTabView] Failed to load prompts: \(error)")
                WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "failed_to_load_prompts"))
                // Show empty state view on error
                DispatchQueue.main.async {
                    self.updateEmptyStateView()
                }
            }
        }
    }
    
    private func updateEmptyStateView() {
        if prompts.isEmpty {
            emptyStateView.isHidden = false
            scrollView.isHidden = true
        } else {
            emptyStateView.isHidden = true
            scrollView.isHidden = false
        }
    }
    
    private func setupActionButtons() {
        // New button
        addButton.frame = NSRect(x: 20, y: 10, width: 88, height: 32)
        addButton.title = LocalizationService.shared.localizedString(for: "new_button")
        addButton.bezelStyle = .rounded
        addButton.layer?.borderWidth = 1.0
        addButton.layer?.borderColor = NSColor.systemGreen.cgColor
        addButton.layer?.cornerRadius = 6.0
        addButton.target = self
        addButton.action = #selector(addNewPrompt)
        addSubview(addButton)
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
        promptColumn.width = 298
        promptColumn.minWidth = 298
        promptColumn.maxWidth = 298
        tableView.addTableColumn(promptColumn)
        
        let editColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("edit"))
        editColumn.title = LocalizationService.shared.localizedString(for: "edit_button")
        editColumn.width = 33
        editColumn.minWidth = 33
        editColumn.maxWidth = 33
        tableView.addTableColumn(editColumn)
        
        let deleteColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("delete"))
        deleteColumn.title = LocalizationService.shared.localizedString(for: "delete_button")
        deleteColumn.width = 33
        deleteColumn.minWidth = 33
        deleteColumn.maxWidth = 33
        tableView.addTableColumn(deleteColumn)
        
        // Add visible border inside the table
        tableView.wantsLayer = true
        tableView.layer?.borderWidth = 1.0
        tableView.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.3).cgColor
        
        // Add table view to scroll view
        scrollView.documentView = tableView
        
        // Setup empty state view
        setupEmptyStateView(tableContainer: tableContainer)
    }
    
    private func setupEmptyStateView(tableContainer: NSView) {
        // Create empty state view
        emptyStateView.frame = tableContainer.bounds
        emptyStateView.wantsLayer = true
        emptyStateView.layer?.backgroundColor = NSColor.white.cgColor
        
        // Add empty state label
        emptyStateLabel.frame = NSRect(x: 0, y: emptyStateView.frame.height / 2 - 15, width: emptyStateView.frame.width, height: 30)
        emptyStateLabel.stringValue = LocalizationService.shared.localizedString(for: "no_prompts_saved_yet")
        emptyStateLabel.isBezeled = false
        emptyStateLabel.drawsBackground = false
        emptyStateLabel.isEditable = false
        emptyStateLabel.isSelectable = false
        emptyStateLabel.font = NSFont.systemFont(ofSize: 16)
        emptyStateLabel.alignment = .center
        emptyStateView.addSubview(emptyStateLabel)
        
        // Add empty state view to table container
        tableContainer.addSubview(emptyStateView)
        
        // Initially hide empty state view
        emptyStateView.isHidden = true
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
        prompts = [prompt1, prompt2] // Oldest first
        
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
            let textField = createReadonlyTextField(text: prompt.promptName)
            // Add "(Default)" suffix to default prompt
            if prompt.id == Prompt.DEFAULT_PROMPT_ID {
                textField.stringValue = "\(prompt.promptName) (Default)"
            }
            return textField
        case "prompt":
            return createPromptTextField(text: prompt.promptText)
        case "edit":
            return createEditButton(tag: row)
        case "delete":
            let deleteButton = createDeleteButton(tag: row)
            // Disable delete button for default prompt
            if prompt.id == Prompt.DEFAULT_PROMPT_ID {
                deleteButton.isEnabled = false
                deleteButton.contentTintColor = NSColor.secondaryLabelColor
                deleteButton.toolTip = "Default prompt cannot be deleted"
            }
            return deleteButton
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
        let button = NSButton(frame: NSRect(x: 9, y: 5, width: 20, height: 20))
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
        let button = NSButton(frame: NSRect(x: 9, y: 5, width: 20, height: 20))
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
            // Open edit window using the new NewOrEditPrompt class
            let editWindow = NewOrEditPrompt(prompt: prompt, originatingWindow: parentWindow)
            editWindow.showAndFocus()
        }
    }
    
    // Store prompts temporarily for delete confirmation
    private var promptsForDelete: [Prompt] = []
    
    @objc private func deleteButtonClicked(_ sender: NSButton) {
        let row = sender.tag
        if row < prompts.count {
            let prompt = prompts[row]
            
            // Safety check: prevent deletion of default prompt
            if prompt.id == Prompt.DEFAULT_PROMPT_ID {
                WindowManager.shared.displayPopupMessage("Default prompt cannot be deleted")
                return
            }
            
            showDeleteConfirmationDialog(prompt: prompt, row: row)
        }
    }
    
    private func showDeleteConfirmationDialog(prompt: Prompt, row: Int) {
        // Get mouse location for positioning
        let mouseLocation = NSEvent.mouseLocation
        
        // Create custom dialog window
        let dialogWidth: CGFloat = 238
        let dialogHeight: CGFloat = 100
        
        // Calculate window position: bottom-right corner at mouse cursor + 6px
        let originX = mouseLocation.x + 6 - dialogWidth
        let originY = mouseLocation.y + 6 - dialogHeight
        
        let dialogWindow = NSWindow(
            contentRect: NSRect(x: originX, y: originY, width: dialogWidth, height: dialogHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window
        dialogWindow.isMovable = true
        dialogWindow.isMovableByWindowBackground = true
        dialogWindow.isOpaque = false
        dialogWindow.backgroundColor = .clear
        dialogWindow.level = .floating
        dialogWindow.hasShadow = true
        
        // Create content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: dialogWidth, height: dialogHeight))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.white.cgColor
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
        
        // Add shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -3)
        shadow.shadowBlurRadius = 8
        
        // Add title label
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: dialogHeight - 40, width: dialogWidth - 40, height: 20))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "are_you_sure")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)
        
        // Add cancel button
        let cancelButton = NSButton(frame: NSRect(x: 41, y: 20, width: 68, height: 32))
        cancelButton.title = LocalizationService.shared.localizedString(for: "cancel_button")
        cancelButton.bezelStyle = .rounded
        cancelButton.layer?.borderWidth = 1.0
        cancelButton.layer?.borderColor = NSColor.systemGray.cgColor
        cancelButton.layer?.cornerRadius = 6.0
        cancelButton.target = self
        cancelButton.action = #selector(cancelDeleteDialog(_:))
        contentView.addSubview(cancelButton)
        
        // Store the prompt for later use
        promptsForDelete = [prompt]
        
        // Add delete button
        let deleteButton = NSButton(frame: NSRect(x: 129, y: 20, width: 68, height: 32))
        deleteButton.title = LocalizationService.shared.localizedString(for: "delete_button")
        deleteButton.bezelStyle = .rounded
        deleteButton.layer?.borderWidth = 1.0
        deleteButton.layer?.borderColor = NSColor.systemRed.cgColor
        deleteButton.layer?.cornerRadius = 6.0
        deleteButton.contentTintColor = NSColor.systemRed
        deleteButton.target = self
        deleteButton.action = #selector(confirmDeleteDialog(_:))
        deleteButton.tag = row
        contentView.addSubview(deleteButton)
        
        // Set content view
        dialogWindow.contentView = contentView
        
        // Clamp window to screen bounds
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main {
            let visibleFrame = screen.visibleFrame
            var frame = dialogWindow.frame
            
            // Clamp horizontally
            if frame.maxX > visibleFrame.maxX {
                frame.origin.x = visibleFrame.maxX - frame.width
            }
            if frame.minX < visibleFrame.minX {
                frame.origin.x = visibleFrame.minX
            }
            
            // Clamp vertically
            if frame.minY < visibleFrame.minY {
                frame.origin.y = visibleFrame.minY
            }
            if frame.maxY > visibleFrame.maxY {
                frame.origin.y = visibleFrame.maxY - frame.height
            }
            
            // Apply the clamped position
            dialogWindow.setFrame(frame, display: false)
        }
        
        // Show the dialog
        dialogWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc private func cancelDeleteDialog(_ sender: Any) {
        if let window = sender as? NSButton, let dialogWindow = window.window {
            dialogWindow.orderOut(nil)
            promptsForDelete = []
        }
    }
    
    @objc private func confirmDeleteDialog(_ sender: Any) {
        if let button = sender as? NSButton, let dialogWindow = button.window, !promptsForDelete.isEmpty {
            let prompt = promptsForDelete[0]
            let row = button.tag
            dialogWindow.orderOut(nil)
            promptsForDelete = []
            
            Task {
                do {
                    // Delete prompt from database
                    try await promptsService.deletePrompt(id: prompt.id)
                    
                    DispatchQueue.main.async {
                        // Delete the prompt from the array
                        self.prompts.remove(at: row)
                        self.tableView.reloadData()
                        self.updateEmptyStateView()
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "prompt_deleted_successfully"))
                    }
                } catch {
                    print("[PromptsTabView] Failed to delete prompt: \(error)")
                    DispatchQueue.main.async {
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "failed_to_delete_prompt"))
                    }
                }
            }
        }
    }
    
    @objc private func addNewPrompt() {
        // Open NewOrEditPrompt window with empty fields
        let newPromptWindow = NewOrEditPrompt(prompt: nil, originatingWindow: parentWindow)
        newPromptWindow.onSave = { newPrompt in
            guard let userId = self.user?.id else {
                print("[PromptsTabView] No user ID available")
                return
            }
            
            Task {
                do {
                    // Create prompt in database
                    let createdPrompt = try await self.promptsService.createPrompt(
                        userId: userId,
                        promptName: newPrompt.promptName,
                        promptText: newPrompt.promptText
                    )
                    
                    DispatchQueue.main.async {
                        // Add the new prompt to the array
                        self.prompts.append(createdPrompt) // Add to the end (newest last)
                        self.tableView.reloadData()
                        self.updateEmptyStateView()
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "prompt_created_successfully"))
                    }
                } catch {
                    print("[PromptsTabView] Failed to create prompt: \(error)")
                    DispatchQueue.main.async {
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "failed_to_create_prompt"))
                    }
                }
            }
        }
        newPromptWindow.showAndFocus()
    }
}
