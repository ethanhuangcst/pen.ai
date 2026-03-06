import Cocoa
import ObjectiveC

class HistoryTabView: NSView {
    // Associated object key for storing row index
    private static var rowKey = "rowKey"
    // MARK: - Properties
    private let parentWindow: NSWindow
    private var historyItems: [ContentHistoryModel] = []
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let emptyStateLabel = NSTextField()
    private let statusIndicatorLabel = NSTextField()
    private let clickToCopyLabel = NSTextField()
    private let tableContainer = NSView()
    
    // MARK: - Initialization
    init(frame: CGRect, parentWindow: NSWindow) {
        self.parentWindow = parentWindow
        super.init(frame: frame)
        setupView()
        loadHistory()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Language Change
    @objc func languageDidChange() {
        // Update all labels with localized strings
        emptyStateLabel.stringValue = LocalizationService.shared.localizedString(for: "no_history_available")
        clickToCopyLabel.stringValue = LocalizationService.shared.localizedString(for: "click_to_copy")
        
        // Update table column headers
        if let tableColumns = tableView.tableColumns as? [NSTableColumn] {
            for column in tableColumns {
                switch column.identifier.rawValue {
                case "number":
                    column.title = LocalizationService.shared.localizedString(for: "column_number")
                case "content":
                    column.title = LocalizationService.shared.localizedString(for: "column_content_enhanced")
                case "date":
                    column.title = LocalizationService.shared.localizedString(for: "column_enhanced_at")
                case "copy":
                    column.title = LocalizationService.shared.localizedString(for: "column_copy")
                default:
                    break
                }
            }
        }
        
        tableView.reloadData()
        needsDisplay = true
        print("HistoryTabView: Language changed, UI updated")
    }
    
    // MARK: - Setup
    private func setupView() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Add table container with border and corner radius to match Prompts tab
        let windowWidth = frame.width
        let windowHeight = frame.height
        tableContainer.frame = NSRect(x: 20, y: 50, width: windowWidth - 40, height: windowHeight - 136)
        tableContainer.wantsLayer = true
        tableContainer.layer?.backgroundColor = ColorService.shared.backgroundColorCGColor
        tableContainer.layer?.borderWidth = 1.0
        tableContainer.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor
        tableContainer.layer?.cornerRadius = 8.0
        self.addSubview(tableContainer)
        
        // Add visible border inside the table to match Prompts tab
        tableView.wantsLayer = true
        tableView.layer?.borderWidth = 1.0
        tableView.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.3).cgColor
        
        // Add scroll view for history items
        scrollView.frame = tableContainer.bounds
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        tableContainer.addSubview(scrollView)
        
        // Configure table view
        tableView.frame = scrollView.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 20 // Height for each history item
        tableView.allowsColumnResizing = false
        tableView.allowsColumnReordering = false
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        
        let numberColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("number"))
        numberColumn.title = LocalizationService.shared.localizedString(for: "column_number")
        numberColumn.width = 26
        numberColumn.minWidth = 26
        numberColumn.maxWidth = 26
        tableView.addTableColumn(numberColumn)
        
        let contentColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        contentColumn.title = LocalizationService.shared.localizedString(for: "column_content_enhanced")
        contentColumn.width = 294
        contentColumn.minWidth = 294
        contentColumn.maxWidth = 294
        tableView.addTableColumn(contentColumn)
        
        let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("date"))
        dateColumn.title = LocalizationService.shared.localizedString(for: "column_enhanced_at")
        dateColumn.width = 100
        dateColumn.minWidth = 100
        dateColumn.maxWidth = 100
        tableView.addTableColumn(dateColumn)
        
        let copyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("copy"))
        copyColumn.title = LocalizationService.shared.localizedString(for: "column_copy")
        copyColumn.width = 30
        copyColumn.minWidth = 30
        copyColumn.maxWidth = 30
        tableView.addTableColumn(copyColumn)
        
        scrollView.documentView = tableView
        
        emptyStateLabel.stringValue = LocalizationService.shared.localizedString(for: "no_history_available")
        emptyStateLabel.isBezeled = false
        emptyStateLabel.drawsBackground = false
        emptyStateLabel.isEditable = false
        emptyStateLabel.isSelectable = false
        emptyStateLabel.alignment = .center
        emptyStateLabel.font = NSFont.systemFont(ofSize: 14)
        emptyStateLabel.textColor = NSColor.secondaryLabelColor
        emptyStateLabel.isHidden = true
        tableContainer.addSubview(emptyStateLabel)
        
        // Add status indicator label
        statusIndicatorLabel.isBezeled = false
        statusIndicatorLabel.drawsBackground = false
        statusIndicatorLabel.isEditable = false
        statusIndicatorLabel.isSelectable = false
        statusIndicatorLabel.alignment = .right
        statusIndicatorLabel.font = NSFont.systemFont(ofSize: 11)
        statusIndicatorLabel.textColor = NSColor.secondaryLabelColor
        statusIndicatorLabel.stringValue = LocalizationService.shared.localizedString(for: "loading_history")
        self.addSubview(statusIndicatorLabel)
        
        // Add "Click to copy" label
        clickToCopyLabel.isBezeled = false
        clickToCopyLabel.drawsBackground = false
        clickToCopyLabel.isEditable = false
        clickToCopyLabel.isSelectable = false
        clickToCopyLabel.alignment = .left
        clickToCopyLabel.font = NSFont.systemFont(ofSize: 11)
        clickToCopyLabel.textColor = NSColor.secondaryLabelColor
        clickToCopyLabel.stringValue = LocalizationService.shared.localizedString(for: "click_to_copy")
        self.addSubview(clickToCopyLabel)
        
        // Update frames
        updateFrames()
    }
    
    // MARK: - Layout
    override func layout() {
        super.layout()
        updateFrames()
    }
    
    // MARK: - Update Frames
    private func updateFrames() {
        let windowWidth = frame.width
        let windowHeight = frame.height
        
        // Table container size and position to match Prompts tab
        tableContainer.frame = NSRect(x: 20, y: 50, width: windowWidth - 40, height: windowHeight - 136)
        
        // Update scroll view frame
        scrollView.frame = tableContainer.bounds
        
        // Update table view frame
        tableView.frame = scrollView.bounds
        
        // Fix column widths to specified values
        if let numberColumn = tableView.tableColumns.first(where: { $0.identifier.rawValue == "number" }) {
            numberColumn.width = 26
            numberColumn.minWidth = 26
            numberColumn.maxWidth = 26
        }
        if let contentColumn = tableView.tableColumns.first(where: { $0.identifier.rawValue == "content" }) {
            contentColumn.width = 294
            contentColumn.minWidth = 294
            contentColumn.maxWidth = 294
        }
        if let dateColumn = tableView.tableColumns.first(where: { $0.identifier.rawValue == "date" }) {
            dateColumn.width = 100
            dateColumn.minWidth = 100
            dateColumn.maxWidth = 100
        }
        if let copyColumn = tableView.tableColumns.first(where: { $0.identifier.rawValue == "copy" }) {
            copyColumn.width = 30
            copyColumn.minWidth = 30
            copyColumn.maxWidth = 30
        }
        
        // Update empty state label frame
        emptyStateLabel.frame = NSRect(x: 0, y: tableContainer.frame.height / 2 - 50, width: tableContainer.frame.width, height: 100)
        
        // Update status indicator label frame
        statusIndicatorLabel.frame = NSRect(x: 20, y: 10, width: windowWidth - 40, height: 20)
        
        // Update "Click to copy" label frame
        clickToCopyLabel.frame = NSRect(x: 20, y: tableContainer.frame.maxY + 10, width: 100, height: 20)
    }
    
    // MARK: - Load History
    private func loadHistory() {
        print("HistoryTabView: loadHistory called")
        guard let user = UserService.shared.currentUser else { 
            print("HistoryTabView: No user available")
            updateStatusIndicator(count: 0, limit: 0)
            return 
        }
        let userID = user.id
        
        print("HistoryTabView: Loading history for user ID: \(userID)")
        
        Task {
            do {
                // Get history limit first
                print("HistoryTabView: Getting history limit")
                let limit = try await ContentHistoryService.shared.getUserHistoryLimit(userID: userID)
                print("HistoryTabView: History limit: \(limit)")
                
                // Load history items with the limit
                print("HistoryTabView: Calling ContentHistoryService.loadHistoryByUserID with limit: \(limit)")
                let historyResult = await ContentHistoryService.shared.loadHistoryByUserID(userID: userID, count: limit) // Load exactly the limit number of items
                
                // Get history count
                print("HistoryTabView: Getting history count")
                let countResult = await ContentHistoryService.shared.readHistoryCount(userID: userID)
                let count = try countResult.get()
                print("HistoryTabView: History count: \(count), limit: \(limit)")
                
                await MainActor.run {
                    switch historyResult {
                    case .success(let items):
                        print("HistoryTabView: Loaded \(items.count) history items")
                        historyItems = items
                        // Debug: Print history items
                        for (index, item) in items.enumerated() {
                            print("HistoryTabView: Item \(index + 1):")
                            print("  UUID: \(item.uuid)")
                            print("  User ID: \(item.userID)")
                            print("  Enhance DateTime: \(item.enhanceDateTime)")
                            print("  Enhanced content length: \(item.enhancedContent.count)")
                            print("  Enhanced content: \(item.enhancedContent.isEmpty ? "[EMPTY]" : item.enhancedContent.prefix(100) + "...")")
                            print("  Original content length: \(item.originalContent.count)")
                            print("  Original content: \(item.originalContent.isEmpty ? "[EMPTY]" : item.originalContent.prefix(100) + "...")")
                            print("  Prompt text length: \(item.promptText.count)")
                            print("  Prompt text: \(item.promptText.isEmpty ? "[EMPTY]" : item.promptText.prefix(100) + "...")")
                            print("  AI provider: \(item.aiProvider)")
                        }
                        print("HistoryTabView: Reloading table view")
                        tableView.reloadData()
                        print("HistoryTabView: Updating empty state")
                        updateEmptyState()
                    case .failure(let error):
                        print("HistoryTabView: Error loading history: \(error)")
                    }
                    
                    // Update status indicator
                    print("HistoryTabView: Updating status indicator with count: \(count), limit: \(limit)")
                    updateStatusIndicator(count: count, limit: limit)
                }
            } catch {
                print("HistoryTabView: Error loading history data: \(error)")
                await MainActor.run {
                    updateStatusIndicator(count: 0, limit: 40) // Default limit
                }
            }
        }
    }
    
    /// Called when the view is about to be displayed
    override func viewWillDraw() {
        super.viewWillDraw()
        // Reload history every time the view is drawn to get the latest limit
        loadHistory()
    }
    
    private func updateStatusIndicator(count: Int, limit: Int) {
        statusIndicatorLabel.stringValue = LocalizationService.shared.localizedString(for: "max_history_record_number", withFormat: limit)
    }
    
    // MARK: - Update Empty State
    private func updateEmptyState() {
        if historyItems.isEmpty {
            emptyStateLabel.isHidden = false
            scrollView.isHidden = true
        } else {
            emptyStateLabel.isHidden = true
            scrollView.isHidden = false
        }
    }
    

    
    // MARK: - Copy Content to Clipboard
    private func copyContentToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(content, forType: .string)
        
        // Show appropriate message based on success
        if success {
            let successMessage = LocalizationService.shared.localizedString(for: "content_copied_to_clipboard")
            WindowManager.shared.displayPopupMessage(successMessage)
        } else {
            let errorMessage = LocalizationService.shared.localizedString(for: "failed_to_copy_to_clipboard")
            WindowManager.shared.displayPopupMessage(errorMessage)
        }
    }
}

// MARK: - NSTableViewDataSource
extension HistoryTabView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return historyItems.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil
    }
}

// MARK: - Trimming Methods
private func trimTextToFitLines(_ text: String, in textField: NSTextField, maxLines: Int) -> String {
    let font = textField.font ?? NSFont.systemFont(ofSize: 13)
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
    
// MARK: - NSTableViewDelegate
extension HistoryTabView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let historyItem = historyItems[row]
        
        guard let columnIdentifier = tableColumn?.identifier else { return nil }
        
        switch columnIdentifier.rawValue {
        case "number":
            return createNumberTextField(row: row)
        case "content":
            return createContentTextField(historyItem: historyItem)
        case "date":
            return createDateTextField(historyItem: historyItem)
        case "copy":
            return createCopyButton(historyItem: historyItem)
        default:
            return nil
        }
    }
    
    private func createNumberTextField(row: Int) -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 5, y: 2, width: 20, height: 16))
        textField.stringValue = "\(row + 1)"
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: 12)
        textField.alignment = .center
        return textField
    }
    
    private func createContentTextField(historyItem: ContentHistoryModel) -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 5, y: 2, width: 284, height: 16))
        textField.stringValue = historyItem.enhancedContent
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: 12)
        // NSTextField doesn't have numberOfLines, use cell's wraps property
        if let cell = textField.cell as? NSTextFieldCell {
            cell.wraps = false
        }
        textField.lineBreakMode = .byTruncatingTail
        
        // Set full text with truncation
        textField.stringValue = historyItem.enhancedContent
        
        // Add tooltip for full text on hover
        textField.toolTip = historyItem.enhancedContent
        
        return textField
    }
    
    private func createCopyButton(historyItem: ContentHistoryModel) -> NSButton {
        let button = NSButton(frame: NSRect(x: 5, y: 0, width: 20, height: 20))
        button.setButtonType(.momentaryPushIn)
        button.isBordered = false
        button.title = "" // Explicitly set empty title to ensure no text is displayed
        
        // Load the copy.svg icon
        let iconPath = "\(FileManager.default.currentDirectoryPath)/Resources/Assets/copy.svg"
        print("HistoryTabView: Loading copy.svg from path: \(iconPath)")
        if let image = NSImage(contentsOfFile: iconPath) {
            print("HistoryTabView: Image loaded successfully: \(image)")
            image.size = NSSize(width: 20, height: 20)
            button.image = image
            print("HistoryTabView: Button image set successfully")
        } else {
            print("HistoryTabView: Error: Could not load copy.svg")
        }
        
        // Set action
        button.target = self
        button.action = #selector(copyButtonClicked(_:))
        
        // Store the content using associated object
        objc_setAssociatedObject(button, &Self.rowKey, historyItem.enhancedContent, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return button
    }
    
    private func createDateTextField(historyItem: ContentHistoryModel) -> NSTextField {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        print("[HistoryTabView] enhanceDateTime: \(historyItem.enhanceDateTime)")
        print("[HistoryTabView] createdAt: \(historyItem.createdAt)")
        let dateString = dateFormatter.string(from: historyItem.enhanceDateTime)
        print("[HistoryTabView] Date string: \(dateString)")
        
        let textField = NSTextField(frame: NSRect(x: 5, y: 2, width: 90, height: 16))
        textField.stringValue = dateString
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: 11)
        textField.textColor = NSColor.secondaryLabelColor
        textField.alignment = .center
        return textField
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        return rowView
    }
    
    @objc private func copyButtonClicked(_ sender: NSButton) {
        if let content = objc_getAssociatedObject(sender, &Self.rowKey) as? String {
            copyContentToClipboard(content)
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false // Disable row selection
    }
}
