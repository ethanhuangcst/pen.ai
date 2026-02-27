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
    
    // Services
    private let aiConnectionService: AIConnectionService
    private let databasePool: DatabaseConnectivityPool
    
    // MARK: - Initialization
    init(frame: CGRect, user: User?, databasePool: DatabaseConnectivityPool) {
        self.user = user
        self.databasePool = databasePool
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
    
    static func createAIConnectionTab(user: User?, databasePool: DatabaseConnectivityPool) -> AIConnectionTabView {
        let frame = CGRect(x: 0, y: 0, width: 680, height: 520)
        return AIConnectionTabView(frame: frame, user: user, databasePool: databasePool)
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
            connections.remove(at: row)
            connectionsTable.reloadData()
        }
    }
    
    @objc private func testConnection(_ sender: NSButton) {
        let row = sender.tag
        if row < connections.count {
            let connection = connections[row]
            print("Testing connection: \(connection.apiProvider)")
            // TODO: Implement test functionality
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
        
        Task {
            for connection in connections {
                do {
                    // For new connections (id == 0), create them
                    if connection.id == 0 {
                        try await aiConnectionService.createConnection(
                            userId: userId,
                            apiKey: connection.apiKey,
                            providerName: connection.apiProvider
                        )
                    } else {
                        // TODO: Implement update functionality
                        print("Updating connection: \(connection.id)")
                    }
                } catch {
                    print("Error saving connection: \(error)")
                }
            }
            
            // Reload connections after saving
            await loadConnections()
            
            // Show success message
            DispatchQueue.main.async {
                WindowManager.displayPopupMessage(LocalizationService.shared.localizedString(for: "connections_saved_successfully"))
            }
        }
    }
}

// MARK: - NSTextFieldDelegate
 extension AIConnectionTabView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, let row = textField.tag as? Int {
            if row < connections.count {
                connections[row].apiKey = textField.stringValue
            }
        }
    }
}
