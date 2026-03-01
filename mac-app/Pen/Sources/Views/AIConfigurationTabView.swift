import Cocoa

// Import LocalizationService for i18n support
import Foundation

// Import models and services
import Pen

class AIConfigurationTabView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    // MARK: - Properties
    private let userLabel = NSTextField()
    private let defaultLabel = NSTextField()
    private let configurationsTable = NSTableView()
    private let addButton = FocusableButton()
    private let tableContainer = NSView()
    
    // Data properties
    private var configurations: [AIManager.PublicAIConfiguration] = []
    private var providers: [AIManager.PublicAIModelProvider] = []
    private var user: User?
    private weak var parentWindow: NSWindow?
    
    // Services
    private let databasePool: DatabaseConnectivityPool
    private var aiManager: AIManager? {
        return UserService.shared.aiManager
    }
    
    // MARK: - Initialization
    init(frame: CGRect, user: User?, databasePool: DatabaseConnectivityPool, parentWindow: NSWindow? = nil) {
        self.user = user
        self.databasePool = databasePool
        self.parentWindow = parentWindow
        
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
    
    static func createAIConfigurationTab(user: User?, databasePool: DatabaseConnectivityPool, parentWindow: NSWindow? = nil) -> AIConfigurationTabView {
        let frame = CGRect(x: 0, y: 0, width: 680, height: 520)
        return AIConfigurationTabView(frame: frame, user: user, databasePool: databasePool, parentWindow: parentWindow)
    }
    
    private func setupTableView() {
        // Set data source and delegate
        configurationsTable.dataSource = self
        configurationsTable.delegate = self
        
        // Add scroll view
        let scrollView = NSScrollView(frame: tableContainer.bounds)
        scrollView.documentView = configurationsTable
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        tableContainer.addSubview(scrollView)
    }
    
    private func loadData() {
        // Load AI providers and configurations asynchronously
        Task {
            await loadProviders()
            await loadConfigurations()
        }
    }
    
    private func loadProviders() async {
        guard let aiManager = aiManager else {
            print("AIManager not initialized")
            return
        }
        
        do {
            providers = try await aiManager.loadAllProviders()
            print("Loaded \(providers.count) AI providers")
        } catch {
            print("Error loading AI providers: \(error)")
        }
    }
    
    private func loadConfigurations() async {
        guard let userId = user?.id, let aiManager = aiManager else { return }
        
        do {
            let databaseConfigurations = try await aiManager.getConnections(for: userId)
            print("Loaded \(databaseConfigurations.count) AI configurations from database")
            
            // Preserve unsaved configurations (id == 0)
            let unsavedConfigurations = configurations.filter { $0.id == 0 }
            
            // Combine database configurations with unsaved configurations
            var updatedConfigurations = databaseConfigurations
            updatedConfigurations.append(contentsOf: unsavedConfigurations)
            
            configurations = updatedConfigurations
            print("Total configurations: \(configurations.count) (\(databaseConfigurations.count) from database, \(unsavedConfigurations.count) unsaved)")
            
            // Reload table view on main thread
            DispatchQueue.main.async {
                self.configurationsTable.reloadData()
            }
        } catch {
            print("Error loading AI configurations: \(error)")
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
        
        setupConfigurationsTable()
    }
    
    private func setupConfigurationsTable() {
        // Create table view
        configurationsTable.frame = NSRect(x: 0, y: 0, width: tableContainer.frame.width, height: tableContainer.frame.height)
        configurationsTable.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        // Create columns
        let providerColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("provider"))
        providerColumn.title = LocalizationService.shared.localizedString(for: "provider_column")
        providerColumn.width = 68
        providerColumn.minWidth = 68
        providerColumn.maxWidth = 68
        configurationsTable.addTableColumn(providerColumn)
        
        let apiKeyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("apiKey"))
        apiKeyColumn.title = LocalizationService.shared.localizedString(for: "api_key")
        apiKeyColumn.width = 318
        apiKeyColumn.minWidth = 318
        apiKeyColumn.maxWidth = 318
        configurationsTable.addTableColumn(apiKeyColumn)
        
        let deleteColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("delete"))
        deleteColumn.title = LocalizationService.shared.localizedString(for: "delete_column")
        deleteColumn.width = 33
        deleteColumn.minWidth = 33
        deleteColumn.maxWidth = 33
        configurationsTable.addTableColumn(deleteColumn)
        
        let testColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("test"))
        testColumn.title = LocalizationService.shared.localizedString(for: "test_column")
        testColumn.width = 33
        testColumn.minWidth = 33
        testColumn.maxWidth = 33
        configurationsTable.addTableColumn(testColumn)
        
        // Add header view
        let headerView = NSTableHeaderView()
        headerView.frame = NSRect(x: 0, y: configurationsTable.frame.height - 22, width: configurationsTable.frame.width, height: 22)
        configurationsTable.headerView = headerView
        
        // Add sample rows for UI demonstration
        addSampleRows()
        
        tableContainer.addSubview(configurationsTable)
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
        addButton.action = #selector(addNewConfiguration)
        addSubview(addButton)
    }
    
    // MARK: - Public Methods
    func setUserName(_ name: String) {
        userLabel.stringValue = LocalizationService.shared.localizedString(for: "ai_connections_for", withFormat: name)
    }
    
    // MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return configurations.count
    }
    
    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, row < configurations.count else { return nil }
        
        let configuration = configurations[row]
        
        switch tableColumn.identifier.rawValue {
        case "provider":
            return createProviderPopup(for: configuration, row: row)
        case "apiKey":
            return createAPIKeyTextField(for: configuration, row: row)
        case "delete":
            return createDeleteButton(row: row)
        case "test":
            return createTestButton(configuration: configuration, row: row)
        default:
            return nil
        }
    }
    
    // Disable row reordering
    func tableView(_ tableView: NSTableView, canDragRowsWithIndexes rowIndexes: IndexSet, at point: NSPoint) -> Bool {
        return false
    }
    
    private func createProviderPopup(for configuration: AIManager.PublicAIConfiguration, row: Int) -> NSPopUpButton {
        let popupButton = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 180, height: 24))
        
        // Add provider options
        for provider in providers {
            popupButton.addItem(withTitle: provider.name)
        }
        
        // Select the current provider
        if let index = providers.firstIndex(where: { $0.name == configuration.apiProvider }) {
            popupButton.selectItem(at: index)
        }
        
        // Set action
        popupButton.target = self
        popupButton.action = #selector(providerChanged(_:))
        popupButton.tag = row
        
        return popupButton
    }
    
    private func createAPIKeyTextField(for configuration: AIManager.PublicAIConfiguration, row: Int) -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 308, height: 24))
        textField.stringValue = configuration.apiKey
        textField.placeholderString = LocalizationService.shared.localizedString(for: "api_key")
        
        // Enable text truncation
        if let cell = textField.cell as? NSTextFieldCell {
            cell.truncatesLastVisibleLine = true
        }
        
        // Set delegate to handle changes
        textField.delegate = self
        textField.tag = row
        
        // Add tooltip for API key field
        textField.toolTip = LocalizationService.shared.localizedString(for: "api_key_required")
        
        return textField
    }
    
    private func createDeleteButton(row: Int) -> NSButton {
        let button = NSButton(frame: NSRect(x: 9, y: 2, width: 20, height: 20))
        button.bezelStyle = .texturedRounded
        button.setButtonType(.momentaryPushIn)
        button.isBordered = false
        let image = NSImage(contentsOf: URL(fileURLWithPath: "/Users/ethanhuang/code/pen.ai/pen/mac-app/Pen/Resources/Assets/delete.svg"))
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.target = self
        button.action = #selector(deleteConfiguration(_:))
        button.tag = row
        button.contentTintColor = NSColor.systemRed
        return button
    }
    
    private func createTestButton(configuration: AIManager.PublicAIConfiguration, row: Int) -> NSButton {
        let button = NSButton(frame: NSRect(x: 9, y: 2, width: 20, height: 20))
        button.bezelStyle = .texturedRounded
        button.setButtonType(.momentaryPushIn)
        button.isBordered = false
        let image = NSImage(contentsOf: URL(fileURLWithPath: "/Users/ethanhuang/code/pen.ai/pen/mac-app/Pen/Resources/Assets/save.svg"))
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.target = self
        button.action = #selector(testConfiguration(_:))
        button.tag = row
        button.contentTintColor = NSColor.systemBlue
        // Disable button if API key is empty
        button.isEnabled = !configuration.apiKey.isEmpty
        return button
    }
    
    // MARK: - Actions
    @objc private func providerChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        if row < configurations.count, let selectedItem = sender.selectedItem {
            configurations[row].apiProvider = selectedItem.title
        }
    }
    
    @objc private func deleteConfiguration(_ sender: NSButton) {
        let row = sender.tag
        if row < configurations.count {
            let configuration = configurations[row]
            
            // Show custom confirmation dialog
            showDeleteConfirmationDialog(configuration: configuration, row: row)
        }
    }
    
    private func deleteAIConfiguration(configuration: AIManager.PublicAIConfiguration, row: Int) {
        Task {
            do {
                if configuration.id != 0, let aiManager = aiManager {
                    // Delete from database
                    try await aiManager.deleteConnection(configuration.id)
                }
                
                // Remove from local array
                DispatchQueue.main.async {
                    self.configurations.remove(at: row)
                    self.configurationsTable.reloadData()
                    // Show popup message
                    WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "ai_connection_deleted_successfully"))
                }
                
                print(" $$$$$$$$$$$$$$$$$$$$ AI Configuration \(configuration.apiProvider) deleted! $$$$$$$$$$$$$$$$$$$$")
            } catch {
                print("Error deleting AI configuration: \(error)")
                DispatchQueue.main.async {
                    WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "failed_to_delete_ai_configuration"))
                }
            }
        }
    }
    
    @objc private func testConfiguration(_ sender: NSButton) {
        let row = sender.tag
        if row < configurations.count {
            let configuration = configurations[row]
            print("Testing configuration: \(configuration.apiProvider)")
            
            // Test the configuration
            testAIConfiguration(configuration: configuration, row: row)
        }
    }
    
    private func testAIConfiguration(configuration: AIManager.PublicAIConfiguration, row: Int) {
        // Check for duplicate configurations
        let duplicateRows = checkForDuplicates(configuration: configuration, currentRow: row)
        if !duplicateRows.isEmpty {
            // Highlight duplicate rows
            highlightDuplicateRows(duplicateRows)
            
            // Show popup message
            WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "duplicated_api_key_or_provider"))
            return
        }
        
        // Show testing message
        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "testing_provider", withFormat: configuration.apiProvider))
        
        // Make actual API call to test the configuration
        Task {
            await testAIConfigurationAsync(configuration, row: row)
        }
    }
    
    private func testAIConfigurationAsync(_ configuration: AIManager.PublicAIConfiguration, row: Int) async {
        do {
            guard let aiManager = UserService.shared.aiManager else {
                print("AIManager not initialized")
                return
            }
            
            // Test the configuration using AIManager
            try await aiManager.testConnection(
                apiKey: configuration.apiKey,
                providerName: configuration.apiProvider
            )
            
            // Test successful
            let isNewConnection = configuration.id == 0
            
            if isNewConnection, let userId = user?.id {
                // Create new connection
                try await aiManager.createConnection(
                    userId: userId,
                    apiKey: configuration.apiKey,
                    providerName: configuration.apiProvider
                )
                print(" $$$$$$$$$$$$$$$$$$$$ AI Connection \(configuration.apiProvider) is added $$$$$$$$$$$$$$$$$$$$")
                
                // Remove the unsaved configuration from local array
                if let index = configurations.firstIndex(where: { $0.id == 0 && $0.apiKey == configuration.apiKey && $0.apiProvider == configuration.apiProvider }) {
                    configurations.remove(at: index)
                }
            } else {
                // Update existing connection
                try await aiManager.updateConnection(
                    id: configuration.id,
                    apiKey: configuration.apiKey,
                    providerName: configuration.apiProvider
                )
                print(" $$$$$$$$$$$$$$$$$$$$ AI Connection \(configuration.apiProvider) is updated $$$$$$$$$$$$$$$$$$$$")
            }
            
            // Reload configurations to get the updated list
            await self.loadConfigurations()
            
            DispatchQueue.main.async {
                // Check if the row still exists
                if row < self.configurations.count {
                    // Highlight the API key field in red for 2 seconds
                    if let textField = self.configurationsTable.view(atColumn: 1, row: row, makeIfNecessary: false) as? NSTextField {
                        textField.layer?.borderWidth = 1.0
                        textField.layer?.borderColor = NSColor.systemRed.cgColor
                        textField.layer?.cornerRadius = 4.0
                        textField.toolTip = LocalizationService.shared.localizedString(for: "ai_connection_test_passed")
                        
                        // Reset highlight after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            textField.layer?.borderWidth = 0.0
                            textField.toolTip = LocalizationService.shared.localizedString(for: "api_key_required")
                        }
                    }
                }
                
                // Show popup message with user's name
                if let username = self.user?.name {
                    if isNewConnection {
                        let message = LocalizationService.shared.localizedString(for: "ai_connection_test_passed_new", withFormat: configuration.apiProvider, username)
                        WindowManager.shared.displayPopupMessage(message)
                    } else {
                        let message = LocalizationService.shared.localizedString(for: "ai_connection_test_passed_updated", withFormat: configuration.apiProvider, username)
                        WindowManager.shared.displayPopupMessage(message)
                    }
                } else {
                    if isNewConnection {
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "ai_connection_test_passed_new_no_user", withFormat: configuration.apiProvider))
                    } else {
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "ai_connection_test_passed_updated_no_user"))
                    }
                }
            }
        } catch {
            // Test failed
            print(" $$$$$$$$$$$$$$$$$$$$ AI Connection test failed $$$$$$$$$$$$$$$$$$$$")
            print("Error testing configuration: \(error)")
            
            DispatchQueue.main.async {
                // Check if the row still exists
                if row < self.configurations.count {
                    // Highlight the API key field in red for 2 seconds
                    if let textField = self.configurationsTable.view(atColumn: 1, row: row, makeIfNecessary: false) as? NSTextField {
                        textField.layer?.borderWidth = 1.0
                        textField.layer?.borderColor = NSColor.systemRed.cgColor
                        textField.layer?.cornerRadius = 4.0
                        textField.toolTip = LocalizationService.shared.localizedString(for: "ai_connection_test_failed")
                        
                        // Reset highlight after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            textField.layer?.borderWidth = 0.0
                            textField.toolTip = LocalizationService.shared.localizedString(for: "api_key_required")
                        }
                    }
                }
                
                // Show popup message with user's name
                if let username = self.user?.name {
                    let isNewConnection = configuration.id == 0
                    if isNewConnection {
                        let message = LocalizationService.shared.localizedString(for: "ai_connection_test_failed_new", withFormat: configuration.apiProvider, username)
                        WindowManager.shared.displayPopupMessage(message)
                    } else {
                        let message = LocalizationService.shared.localizedString(for: "ai_connection_test_failed_updated", withFormat: configuration.apiProvider, username)
                        WindowManager.shared.displayPopupMessage(message)
                    }
                } else {
                    let isNewConnection = configuration.id == 0
                    if isNewConnection {
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "ai_connection_test_failed_new_no_user", withFormat: configuration.apiProvider))
                    } else {
                        WindowManager.shared.displayPopupMessage(LocalizationService.shared.localizedString(for: "ai_connection_test_failed_updated_no_user"))
                    }
                }
            }
        }
    }
    
    @objc private func addNewConfiguration() {
        guard let userId = user?.id else { return }
        
        // Create a new configuration with default values
        let newConfiguration = AIManager.PublicAIConfiguration(
            id: 0, // Temporary ID, will be replaced by database
            userId: userId,
            apiKey: "",
            apiProvider: providers.first?.name ?? "",
            createdAt: Date(),
            updatedAt: nil
        )
        
        configurations.append(newConfiguration)
        configurationsTable.reloadData()
    }

    private func checkForDuplicates(configuration: AIManager.PublicAIConfiguration, currentRow: Int) -> [Int] {
        var duplicateRows: [Int] = []
        
        for (index, config) in configurations.enumerated() {
            if index != currentRow && config.apiProvider == configuration.apiProvider && config.apiKey == configuration.apiKey {
                duplicateRows.append(index)
            }
        }
        
        return duplicateRows
    }

    private func highlightDuplicateRows(_ rows: [Int]) {
        for row in rows {
            if let textField = configurationsTable.view(atColumn: 1, row: row, makeIfNecessary: false) as? NSTextField {
                textField.layer?.borderWidth = 1.0
                textField.layer?.borderColor = NSColor.systemRed.cgColor
                textField.layer?.cornerRadius = 4.0
                textField.toolTip = LocalizationService.shared.localizedString(for: "duplicated_configuration")
            }
        }
        
        // Reset highlights after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            for row in rows {
                if let textField = self.configurationsTable.view(atColumn: 1, row: row, makeIfNecessary: false) as? NSTextField {
                    textField.layer?.borderWidth = 0.0
                    textField.toolTip = LocalizationService.shared.localizedString(for: "api_key_required")
                }
            }
        }
    }



    private func highlightInvalidFields(invalidRows: [Int], duplicateRows: [Int]) {
        // Loop through all rows and highlight fields
        for row in 0..<configurations.count {
            // Get the API key text field for this row
            let view = configurationsTable.view(atColumn: 1, row: row, makeIfNecessary: false)
            if let textField = view as? NSTextField {
                if invalidRows.contains(row) {
                    // Highlight empty API key fields in red
                    textField.layer?.borderWidth = 1.0
                    textField.layer?.borderColor = NSColor.systemRed.cgColor
                    textField.layer?.cornerRadius = 4.0
                    textField.toolTip = LocalizationService.shared.localizedString(for: "api_key_required")
                } else if duplicateRows.contains(row) {
                    // Highlight duplicate configurations in red
                    textField.layer?.borderWidth = 1.0
                    textField.layer?.borderColor = NSColor.systemRed.cgColor
                    textField.layer?.cornerRadius = 4.0
                    textField.toolTip = LocalizationService.shared.localizedString(for: "duplicated_configuration")
                } else {
                    // Reset border for valid fields
                    textField.layer?.borderWidth = 0.0
                    textField.toolTip = LocalizationService.shared.localizedString(for: "api_key_required")
                }
            }
        }
    }
    
    // Store configurations temporarily for delete confirmation
    private var configurationsForDelete: [AIManager.PublicAIConfiguration] = []
    
    private func showDeleteConfirmationDialog(configuration: AIManager.PublicAIConfiguration, row: Int) {
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
        
        // Store the configuration for later use
        configurationsForDelete = [configuration]
        
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
            configurationsForDelete = []
        }
    }
    
    @objc private func confirmDeleteDialog(_ sender: Any) {
        if let button = sender as? NSButton, let dialogWindow = button.window, !configurationsForDelete.isEmpty {
            let configuration = configurationsForDelete[0]
            let row = button.tag
            dialogWindow.orderOut(nil)
            configurationsForDelete = []
            deleteAIConfiguration(configuration: configuration, row: row)
        }
    }
    

}

// MARK: - NSTextFieldDelegate
 extension AIConfigurationTabView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, let row = textField.tag as? Int {
            if row < configurations.count {
                configurations[row].apiKey = textField.stringValue
                // Reset border when text is entered
                textField.layer?.borderWidth = 0.0
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, let row = textField.tag as? Int {
            if row < configurations.count {
                // Reset border as soon as user starts typing
                textField.layer?.borderWidth = 0.0
                // Enable/disable Save button based on API key
                let apiKey = textField.stringValue
                if let saveButton = configurationsTable.view(atColumn: 3, row: row, makeIfNecessary: false) as? NSButton {
                    saveButton.isEnabled = !apiKey.isEmpty
                }
            }
        }
    }
}
