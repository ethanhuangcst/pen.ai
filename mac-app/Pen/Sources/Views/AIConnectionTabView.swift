import Cocoa

// Import LocalizationService for i18n support
import Foundation

class AIConnectionTabView: NSView {
    // MARK: - Properties
    private let userLabel = NSTextField()
    private let connectionsTable = NSTableView()
    private let addButton = FocusableButton()
    private let saveButton = FocusableButton()
    private let tableContainer = NSView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func createAIConnectionTab() -> AIConnectionTabView {
        let frame = CGRect(x: 0, y: 0, width: 680, height: 520)
        return AIConnectionTabView(frame: frame)
    }
    
    private func setupUI() {
        let windowWidth = frame.width
        let windowHeight = frame.height
        
        // Setup UI components
        setupUserLabel(windowWidth: windowWidth, windowHeight: windowHeight)
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
    
    private func setupTableContainer(windowWidth: CGFloat, windowHeight: CGFloat) {
        tableContainer.frame = NSRect(x: 20, y: 50, width: windowWidth - 40, height: windowHeight - 142)
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
        providerColumn.title = LocalizationService.shared.localizedString(for: "ai_model_provider")
        providerColumn.width = 180
        connectionsTable.addTableColumn(providerColumn)
        
        let apiKeyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("apiKey"))
        apiKeyColumn.title = LocalizationService.shared.localizedString(for: "api_key")
        apiKeyColumn.width = 280
        connectionsTable.addTableColumn(apiKeyColumn)
        
        let deleteColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("delete"))
        deleteColumn.title = ""
        deleteColumn.width = 80
        connectionsTable.addTableColumn(deleteColumn)
        
        let testColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("test"))
        testColumn.title = ""
        testColumn.width = 80
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
        addButton.frame = NSRect(x: 20, y: 2, width: 88, height: 32)
        addButton.title = LocalizationService.shared.localizedString(for: "new_button")
        addButton.bezelStyle = .rounded
        addButton.layer?.borderWidth = 1.0
        addButton.layer?.borderColor = NSColor.systemGreen.cgColor
        addButton.layer?.cornerRadius = 6.0
        addSubview(addButton)
        
        // Save button
        saveButton.frame = NSRect(x: windowWidth - 108, y: 2, width: 88, height: 32)
        saveButton.bezelStyle = .rounded
        saveButton.layer?.backgroundColor = NSColor.systemBlue.cgColor
        saveButton.layer?.cornerRadius = 6.0
        
        // Set button title with white text
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 13, weight: .medium)
        ]
        let attributedTitle = NSAttributedString(string: LocalizationService.shared.localizedString(for: "save_button"), attributes: attributes)
        saveButton.attributedTitle = attributedTitle
        addSubview(saveButton)
    }
    
    // MARK: - Public Methods
    func setUserName(_ name: String) {
        userLabel.stringValue = LocalizationService.shared.localizedString(for: "ai_connections_for", withFormat: name)
    }
}
