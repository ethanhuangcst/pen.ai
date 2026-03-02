import Cocoa
import ObjectiveC

class HistoryTabView: NSView {
    // Associated object key for storing row index
    private static var rowKey = "rowKey"
    // MARK: - Properties
    private let user: User?
    private let parentWindow: NSWindow
    private var historyItems: [ContentHistoryModel] = []
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let emptyStateLabel = NSTextField()
    
    // MARK: - Initialization
    init(frame: CGRect, user: User?, parentWindow: NSWindow) {
        self.user = user
        self.parentWindow = parentWindow
        super.init(frame: frame)
        setupView()
        loadHistory()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        // Add scroll view for history items
        scrollView.frame = NSRect(x: 20, y: 20, width: self.frame.width - 40, height: self.frame.height - 40)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        self.addSubview(scrollView)
        
        // Configure table view
        tableView.frame = scrollView.bounds
        tableView.autoresizingMask = [.width, .height]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80 // Height for each history item
        
        // Add column for history items
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("historyItem"))
        column.title = ""
        column.width = scrollView.frame.width
        tableView.addTableColumn(column)
        
        scrollView.documentView = tableView
        
        // Add empty state label
        emptyStateLabel.frame = NSRect(x: 20, y: self.frame.height / 2 - 50, width: self.frame.width - 40, height: 100)
        emptyStateLabel.stringValue = "No history available. Start enhancing content to build your history."
        emptyStateLabel.isBezeled = false
        emptyStateLabel.drawsBackground = false
        emptyStateLabel.isEditable = false
        emptyStateLabel.isSelectable = false
        emptyStateLabel.alignment = .center
        emptyStateLabel.font = NSFont.systemFont(ofSize: 14)
        emptyStateLabel.textColor = NSColor.gray
        emptyStateLabel.isHidden = true
        self.addSubview(emptyStateLabel)
    }
    
    // MARK: - Load History
    private func loadHistory() {
        guard let userID = user?.id else { return }
        
        Task {
            let result = await ContentHistoryService.shared.loadHistoryByUserID(userID: userID, count: 100) // Load up to 100 items
            
            await MainActor.run {
                switch result {
                case .success(let items):
                    historyItems = items
                    tableView.reloadData()
                    updateEmptyState()
                case .failure(let error):
                    print("Error loading history: \(error)")
                }
            }
        }
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
        pasteboard.setString(content, forType: .string)
        
        // Show confirmation message
        showConfirmationMessage()
    }
    
    // MARK: - Show Confirmation Message
    private func showConfirmationMessage() {
        let alert = NSAlert()
        alert.messageText = "Content copied to clipboard"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        // Show alert asynchronously and close after 1 second
        DispatchQueue.main.async { [weak self] in
            alert.beginSheetModal(for: self?.parentWindow ?? NSWindow()) { _ in }
            
            // Close alert after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { 
                let sheetWindow = alert.window
                sheetWindow.orderOut(nil)
            }
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

// MARK: - NSTableViewDelegate
extension HistoryTabView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let historyItem = historyItems[row]
        
        // Create a view for the history item
        let view = NSView(frame: NSRect(x: 0, y: 0, width: tableView.frame.width, height: 80))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.lightGray.cgColor
        view.layer?.cornerRadius = 4
        
        // Add history number label
        let numberLabel = NSTextField(frame: NSRect(x: 10, y: 50, width: 50, height: 20))
        numberLabel.stringValue = "#\(row + 1)"
        numberLabel.isBezeled = false
        numberLabel.drawsBackground = false
        numberLabel.isEditable = false
        numberLabel.isSelectable = false
        numberLabel.font = NSFont.boldSystemFont(ofSize: 14)
        view.addSubview(numberLabel)
        
        // Add date/time label
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: historyItem.enhanceDateTime)
        
        let dateLabel = NSTextField(frame: NSRect(x: 70, y: 50, width: 150, height: 20))
        dateLabel.stringValue = dateString
        dateLabel.isBezeled = false
        dateLabel.drawsBackground = false
        dateLabel.isEditable = false
        dateLabel.isSelectable = false
        dateLabel.font = NSFont.systemFont(ofSize: 12)
        dateLabel.textColor = NSColor.gray
        view.addSubview(dateLabel)
        
        // Add enhanced content label (trimmed to 3 lines)
        let contentLabel = NSTextField(frame: NSRect(x: 10, y: 10, width: tableView.frame.width - 20, height: 40))
        contentLabel.stringValue = historyItem.enhancedContent
        contentLabel.isBezeled = false
        contentLabel.drawsBackground = false
        contentLabel.isEditable = false
        contentLabel.isSelectable = false
        contentLabel.font = NSFont.systemFont(ofSize: 13)
        // NSTextField doesn't have numberOfLines, use cell's wraps property
        if let cell = contentLabel.cell as? NSTextFieldCell {
            cell.wraps = true
        }
        contentLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(contentLabel)
        
        // Add clickable area
        let clickableArea = NSView(frame: view.bounds)
        clickableArea.wantsLayer = true
        clickableArea.layer?.backgroundColor = NSColor.clear.cgColor
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(historyItemClicked(_:)))
        clickableArea.addGestureRecognizer(clickGesture)
        view.addSubview(clickableArea)
        
        // Store the row index using associated object
        objc_setAssociatedObject(clickGesture, &Self.rowKey, row, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return view
    }
    
    @objc private func historyItemClicked(_ gesture: NSClickGestureRecognizer) {
        if let row = objc_getAssociatedObject(gesture, &Self.rowKey) as? Int, row < historyItems.count {
            let historyItem = historyItems[row]
            copyContentToClipboard(historyItem.enhancedContent)
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false // Disable row selection
    }
}
