import Cocoa

// Import LocalizationService for i18n support
import Foundation

// Import models and services
import Pen

class AIConnectionTabView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    // MARK: - Properties
    private let userLabel = NSTextField()
    private let defaultLabel = NSTextField()
    private let connectionsTable = NSTableView()
    private let addButton = FocusableButton()
    private let saveButton = FocusableButton()
    private let tableContainer = NSView()
    
    // Data properties
    private var connections: [AIConnection] = []
    private var providers: [AIModelProvider] = []
    private var user: User?
    private weak var parentWindow: NSWindow?
    
    // Services
    private let aiConnectionService: AIConnectionService
    private let databasePool: DatabaseConnectivityPool
    
    // MARK: - Initialization
    init(frame: CGRect, user: User?, databasePool: DatabaseConnectivityPool, parentWindow: NSWindow? = nil) {
        self.user = user
        self.databasePool = databasePool
        self.parentWindow = parentWindow
        self.aiConnectionService = AIConnectionService(databasePool: databasePool)
        
        super.init(frame: frame)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        
        setupUI()
        setupTableView()
        loadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func createAIConnectionTab(user: User?, databasePool: DatabaseConnectivityPool, parentWindow: NSWindow? = nil) -> AIConnectionTabView {
        let frame = CGRect(x: 0, y: 0, width: 680, height: 520)
        return AIConnectionTabView(frame: frame, user: user, databasePool: databasePool, parentWindow: parentWindow)
    }
    
    private func setupTableView() {
        // Set data source and delegate
        connectionsTable.dataSource = self
        connectionsTable.delegate = self
        
        // Add scroll view
        let scrollView = NSScrollView(frame: tableContainer.bounds)
        scrollView.documentView = connectionsTable
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        tableContainer.addSubview(scrollView)
    }
    
    private func loadData() {
        // Load AI providers and connections asynchronously
        Task {
            await loadProviders()
            await loadConnections()
        }
    }
    
    private func loadProviders() async {
        do {
            providers = try await aiConnectionService.loadAllProviders()
            print("Loaded \(providers.count) AI providers")
        } catch {
            print("Error loading AI providers: \(error)")
        }
    }
    
    private func loadConnections() async {
        guard let userId = user?.id else { return }
        
        do {
            let connectionData = try await aiConnectionService.getConnections(for: userId)
            connections = connectionData.compactMap { AIConnection.fromDatabaseRow($0) }
            print("Loaded \(connections.count) AI connections")
            
            // Reload table view on main thread
            DispatchQueue.main.async {
                self.connectionsTable.reloadData()
            }
        } catch {
            print("Error loading AI connections: \(error)")
        }
    }
    
    private func setupUI() {
        let windowWidth = frame.width
        let windowHeight = frame.height
        
        // Setup UI components
        setupUserLabel(windowWidth: windowWidth, windowHeight: windowHeight)
        setupDefaultLabel(windowWidth: windowWidth, windowHeight: windowHeight)
        setupTableContainer(windowWidth: windowWidth, windowHeight: windowHeight)
        setupActionButtons(windowWidth: windowWidth)
    }
    
    // MARK: - UI Setup
    private func setupUserLabel(windowWidth: CGFloat, windowHeight: CGFloat) {
        userLabel.frame = NSRect(x: 20, y: windowHeight - 92, width: windowWidth - 40, height: 24)
        userLabel.stringValue = LocalizationService.shared.localizedString(for: "ai_connections_for", withFormat: "[User Name]")
        userLabel.isBezeled = false
        userLabel.drawsBackground = false
        userLabel.isEditable = false
        userLabel.isSelectable = false
        userLabel.font = NSFont.boldSystemFont(ofSize: 16)
        addSubview(userLabel)
    }
    
    private func setupDefaultLabel(windowWidth: CGFloat, windowHeight: CGFloat) {
        defaultLabel.frame = NSRect(x: 20, y: windowHeight - 108, width: windowWidth - 40, height: 16)
        defaultLabel.stringValue = LocalizationService.shared.localizedString(for: "first_connection_default")
        defaultLabel.isBezeled = false
        defaultLabel.drawsBackground = false
        defaultLabel.isEditable = false
        defaultLabel.isSelectable = false
        defaultLabel.font = NSFont.systemFont(ofSize: 12)
        defaultLabel.textColor = NSColor.secondaryLabelColor
        addSubview(defaultLabel)
    }
    
    private func setupTableContainer(windowWidth: CGFloat, windowHeight: CGFloat) {
        tableContainer.frame = NSRect(x: 20, y: 50, width: windowWidth - 40, height: windowHeight - 166)
        tableContainer.wantsLayer = true
        tableContainer.layer?.backgroundColor = NSColor.white.cgColor
        tableContainer.layer?.borderWidth = 1.0
        tableContainer.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor
        tableContainer.layer?.cornerRadius = 8.0
        addSubview(tableContainer)
        
        setupConnectionsTable()
    }
    
    private func setupConnectionsTable() {
        // Create table view
        connectionsTable.frame = NSRect(x: 0, y: 0, width: tableContainer.frame.width, height: tableContainer.frame.height)
        connectionsTable.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        // Create columns
        let providerColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("provider"))
        providerColumn.title = LocalizationService.shared.localizedString(for: "provider_column")
        providerColumn.width = 68
        providerColumn.minWidth = 68
        providerColumn.maxWidth = 68
        connectionsTable.addTableColumn(providerColumn)
        
        let apiKeyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("apiKey"))
        apiKeyColumn.title = LocalizationService.shared.localizedString(for: "api_key")
        apiKeyColumn.width = 308
        apiKeyColumn.minWidth = 308
        apiKeyColumn.maxWidth = 308
        connectionsTable.addTableColumn(apiKeyColumn)
        
        let deleteColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("delete"))
        deleteColumn.title = LocalizationService.shared.localizedString(for: "delete_column")
        deleteColumn.width = 38
        deleteColumn.minWidth = 38
        deleteColumn.maxWidth = 38
        connectionsTable.addTableColumn(deleteColumn)
        
        let testColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("test"))
        testColumn.title = LocalizationService.shared.localizedString(for: "test_column")
        testColumn.width = 38
        testColumn.minWidth = 38
        testColumn.maxWidth = 38
        connectionsTable.addTableColumn(testColumn)
        
        // Add header view
        let headerView = NSTableHeaderView()
        headerView.frame = NSRect(x: 0, y: connectionsTable.frame.height - 22, width: connectionsTable.frame.width, height: 22)
        connectionsTable.headerView = headerView
        
        // Add sample rows for UI demonstration
        addSampleRows()
        
        tableContainer.addSubview(connectionsTable)
    }
    
    private func addSampleRows() {
        // Add sample rows for UI demonstration
        // In a real implementation, we would use a data source
        // For UI demonstration, we'll just leave the table structure
    }
    
    private func setupActionButtons(windowWidth: CGFloat) {
        // New button
        addButton.frame = NSRect(x: 20, y: 10, width: 88, height: 32)
        addButton.title = LocalizationService.shared.localizedString(for: "new_button")
        addButton.bezelStyle = .rounded
        addButton.layer?.borderWidth = 1.0
        addButton.layer?.borderColor = NSColor.systemGreen.cgColor
        addButton.layer?.cornerRadius = 6.0
        addButton.target = self
        addButton.action = #selector(addNewConnection)
        addSubview(addButton)
        
        // Save button
        saveButton.frame = NSRect(x: windowWidth - 108, y: 10, width: 88, height: 32)
        saveButton.title = LocalizationService.shared.localizedString(for: "save_button")
        saveButton.bezelStyle = .rounded
        saveButton.layer?.borderWidth = 1.0
        saveButton.layer?.borderColor = NSColor.systemBlue.cgColor
        saveButton.layer?.cornerRadius = 6.0
        saveButton.target = self
        saveButton.action = #selector(saveConnections)
        addSubview(saveButton)
    }
    
    // MARK: - Public Methods
    func setUserName(_ name: String) {
        userLabel.stringValue = LocalizationService.shared.localizedString(for: "ai_connections_for", withFormat: name)
    }
    
    // MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return connections.count
    }
    
    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, row < connections.count else { return nil }
        
        let connection = connections[row]
        
        switch tableColumn.identifier.rawValue {
        case "provider":
            return createProviderPopup(for: connection, row: row)
        case "apiKey":
            return createAPIKeyTextField(for: connection, row: row)
        case "delete":
            return createDeleteButton(row: row)
        case "test":
            return createTestButton(row: row)
        default:
            return nil
        }
    }
    
    private func createProviderPopup(for connection: AIConnection, row: Int) -> NSPopUpButton {
        let popupButton = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 180, height: 24))
        
        // Add provider options
        for provider in providers {
            popupButton.addItem(withTitle: provider.name)
        }
        
        // Select the current provider
        if let index = providers.firstIndex(where: { $0.name == connection.apiProvider }) {
            popupButton.selectItem(at: index)
        }
        
        // Set action
        popupButton.target = self
        popupButton.action = #selector(providerChanged(_:))
        popupButton.tag = row
        
        return popupButton
    }
    
    private func createAPIKeyTextField(for connection: AIConnection, row: Int) -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 308, height: 24))
        textField.stringValue = connection.apiKey
        textField.placeholderString = LocalizationService.shared.localizedString(for: "api_key")
        
        // Enable text truncation
        if let cell = textField.cell as? NSTextFieldCell {
            cell.truncatesLastVisibleLine = true
        }
        
        // Set delegate to handle changes
        textField.delegate = self
        textField.tag = row
        
        // Add tooltip for API key field
        textField.toolTip = "API Key is required"
        
        return textField
    }
    
    private func createDeleteButton(row: Int) -> NSButton {
        let button = NSButton(frame: NSRect(x: 9, y: 2, width: 20, height: 20))
        button.bezelStyle = .circular
        button.setButtonType(.momentaryPushIn)
        button.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")
        button.target = self
        button.action = #selector(deleteConnection(_:))
        button.tag = row
        button.contentTintColor = NSColor.systemRed
        return button
    }
    
    private func createTestButton(row: Int) -> NSButton {
        let button = NSButton(frame: NSRect(x: 9, y: 2, width: 20, height: 20))
        button.bezelStyle = .circular
        button.setButtonType(.momentaryPushIn)
        button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Test")
        button.target = self
        button.action = #selector(testConnection(_:))
        button.tag = row
        button.contentTintColor = NSColor.systemBlue
        return button
    }
    
    // MARK: - Actions
    @objc private func providerChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        if row < connections.count, let selectedItem = sender.selectedItem {
            connections[row].apiProvider = selectedItem.title
        }
    }
    
    @objc private func deleteConnection(_ sender: NSButton) {
        let row = sender.tag
        if row < connections.count {
            let connection = connections[row]
            
            // Show custom confirmation dialog
            showDeleteConfirmationDialog(connection: connection, row: row)
        }
    }
    
    private func deleteAIConnection(connection: AIConnection, row: Int) {
        Task {
            do {
                if connection.id != 0 {
                    // Delete from database
                    try await aiConnectionService.deleteConnection(connection.id)
                }
                
                // Remove from local array
                DispatchQueue.main.async {
                    self.connections.remove(at: row)
                    self.connectionsTable.reloadData()
                }
                
                print(" $$$$$$$$$$$$$$$$$$$$ AI Connection \(connection.apiProvider) deleted! $$$$$$$$$$$$$$$$$$$$")
            } catch {
                print("Error deleting AI connection: \(error)")
                DispatchQueue.main.async {
                    WindowManager.displayPopupMessage("Failed to delete AI Connection!")
                }
            }
        }
    }
    
    @objc private func testConnection(_ sender: NSButton) {
        let row = sender.tag
        if row < connections.count {
            let connection = connections[row]
            print("Testing connection: \(connection.apiProvider)")
            
            // Test the connection
            testAIConnection(connection: connection)
        }
    }
    
    private func testAIConnection(connection: AIConnection) {
        // Make actual API call to test the connection
        Task {
            do {
                // Test the connection using AIConnectionService
                try await aiConnectionService.testConnection(
                    apiKey: connection.apiKey,
                    providerName: connection.apiProvider
                )
                
                // Test successful
                print(" $$$$$$$$$$$$$$$$$$$$ AI Connection \(connection.apiProvider) is established $$$$$$$$$$$$$$$$$$$$")
                
                DispatchQueue.main.async {
                    WindowManager.displayPopupMessage("AI Connection \(connection.apiProvider) is established successfully!")
                }
            } catch {
                // Test failed
                print(" $$$$$$$$$$$$$$$$$$$$ AI Connection \(connection.apiProvider) is failed $$$$$$$$$$$$$$$$$$$$")
                print("Error testing connection: \(error)")
                
                DispatchQueue.main.async {
                    WindowManager.displayPopupMessage("Failed to establish AI Connection \(connection.apiProvider)!")
                }
            }
        }
    }
    
    @objc private func addNewConnection() {
        guard let userId = user?.id else { return }
        
        // Create a new connection with default values
        let newConnection = AIConnection(
            id: 0, // Temporary ID, will be replaced by database
            userId: userId,
            apiKey: "",
            apiProvider: providers.first?.name ?? "",
            createdAt: Date(),
            updatedAt: nil
        )
        
        connections.append(newConnection)
        connectionsTable.reloadData()
    }
    
    @objc private func saveConnections() {
        guard let userId = user?.id else { return }
        
        // Validate connections
        var validConnections: [AIConnection] = []
        var hasInvalidConnections = false
        var hasDuplicateConnections = false
        var invalidRows: [Int] = []
        var duplicateRows: [Int] = []
        
        // Check for duplicates
        var seenConnections: Set<String> = []
        
        for (index, connection) in connections.enumerated() {
            if connection.apiKey.isEmpty {
                hasInvalidConnections = true
                invalidRows.append(index)
            } else {
                // Check for duplicates based on provider and API key
                let connectionKey = "\(connection.apiProvider)-\(connection.apiKey)"
                if seenConnections.contains(connectionKey) {
                    hasDuplicateConnections = true
                    duplicateRows.append(index)
                } else {
                    seenConnections.insert(connectionKey)
                    validConnections.append(connection)
                }
            }
        }
        
        // Highlight invalid and duplicate fields
        highlightInvalidFields(invalidRows: invalidRows, duplicateRows: duplicateRows)
        
        Task {
            var saveSuccess = true
            var newlyCreatedConnections: [AIConnection] = []
            
            for connection in validConnections {
                do {
                    // For new connections (id == 0), create them
                    if connection.id == 0 {
                        try await aiConnectionService.createConnection(
                            userId: userId,
                            apiKey: connection.apiKey,
                            providerName: connection.apiProvider
                        )
                        print(" $$$$$$$$$$$$$$$$$$$$ AI Connection \(connection.apiProvider) saved! $$$$$$$$$$$$$$$$$$$$")
                        newlyCreatedConnections.append(connection)
                    } else {
                        // TODO: Implement update functionality
                        print("Updating connection: \(connection.id)")
                    }
                } catch {
                    print(" $$$$$$$$$$$$$$$$$$$$ Failed to save AI Connection \(connection.apiProvider) !!!  $$$$$$$$$$$$$$$$$$$$")
                    print("Error saving connection: \(error)")
                    saveSuccess = false
                }
            }
            
            // Only reload connections if all connections were saved successfully
            if saveSuccess && !hasInvalidConnections && !hasDuplicateConnections {
                await loadConnections()
            } else if saveSuccess && (hasInvalidConnections || hasDuplicateConnections) {
                // Combine duplicate and invalid rows, ensuring no duplicates
                var rowsToRemove = Set<Int>()
                rowsToRemove.formUnion(duplicateRows)
                rowsToRemove.formUnion(invalidRows)
                
                DispatchQueue.main.async {
                    self.connectionsTable.reloadData()
                    
                    // Remove invalid and duplicate connections after 1 second
                    if !rowsToRemove.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // Sort rows in reverse order to avoid index shifting issues
                            let sortedRows = Array(rowsToRemove).sorted(by: >)
                            for row in sortedRows {
                                if row < self.connections.count {
                                    self.connections.remove(at: row)
                                }
                            }
                            self.connectionsTable.reloadData()
                        }
                    }
                }
            }
            
            // Show appropriate message
            DispatchQueue.main.async {
                if !saveSuccess {
                    WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "failed_to_save_connections"))
                } else if hasInvalidConnections && hasDuplicateConnections {
                    WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "only_valid_no_duplicate_connections_saved"))
                } else if hasInvalidConnections {
                    WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "only_valid_api_key_connections_saved"))
                } else if hasDuplicateConnections {
                    WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "only_non_duplicate_connections_saved"))
                    print(" $$$$$$$$$$$$$$$$$$$$ AI Connections saved! $$$$$$$$$$$$$$$$$$$$")
                } else {
                    WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "connections_saved_successfully"))
                }
            }
        }
    }
    
    private func highlightInvalidFields(invalidRows: [Int], duplicateRows: [Int]) {
        // Loop through all rows and highlight fields
        for row in 0..<connections.count {
            // Get the API key text field for this row
            let view = connectionsTable.view(atColumn: 1, row: row, makeIfNecessary: false)
            if let textField = view as? NSTextField {
                if invalidRows.contains(row) {
                    // Highlight empty API key fields in red
                    textField.layer?.borderWidth = 1.0
                    textField.layer?.borderColor = NSColor.systemRed.cgColor
                    textField.layer?.cornerRadius = 4.0
                    textField.toolTip = "API Key is required"
                } else if duplicateRows.contains(row) {
                    // Highlight duplicate connections in red
                    textField.layer?.borderWidth = 1.0
                    textField.layer?.borderColor = NSColor.systemRed.cgColor
                    textField.layer?.cornerRadius = 4.0
                    textField.toolTip = "Duplicated connection.."
                } else {
                    // Reset border for valid fields
                    textField.layer?.borderWidth = 0.0
                    textField.toolTip = "API Key is required"
                }
            }
        }
    }
    
    // Store connections temporarily for delete confirmation
    private var connectionsForDelete: [AIConnection] = []
    
    private func showDeleteConfirmationDialog(connection: AIConnection, row: Int) {
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
        
        // Store the connection for later use
        connectionsForDelete = [connection]
        
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
            connectionsForDelete = []
        }
    }
    
    @objc private func confirmDeleteDialog(_ sender: Any) {
        if let button = sender as? NSButton, let dialogWindow = button.window, !connectionsForDelete.isEmpty {
            let connection = connectionsForDelete[0]
            let row = button.tag
            dialogWindow.orderOut(nil)
            connectionsForDelete = []
            deleteAIConnection(connection: connection, row: row)
        }
    }
    

}

// MARK: - NSTextFieldDelegate
 extension AIConnectionTabView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, let row = textField.tag as? Int {
            if row < connections.count {
                connections[row].apiKey = textField.stringValue
                // Reset border when text is entered
                textField.layer?.borderWidth = 0.0
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, let row = textField.tag as? Int {
            if row < connections.count {
                // Reset border as soon as user starts typing
                textField.layer?.borderWidth = 0.0
            }
        }
    }
}
