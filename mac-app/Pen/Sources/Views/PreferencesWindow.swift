import Cocoa

class PreferencesWindow: BaseWindow {
    // MARK: - Properties
    private let windowWidth: CGFloat = 600
    private let mouseOffset: CGFloat = 6
    private var user: User?
    

    
    // MARK: - Initialization
    init(user: User? = nil) {
        // Store user
        self.user = user
        print("PreferencesWindow: Initialized with user: \(user?.name ?? "nil")")
        
        // Calculate window size
        let windowHeight: CGFloat = 518 // Fixed height as specified in requirements
        let windowSize = NSSize(width: windowWidth, height: windowHeight)
        
        // Create window with borderless style (default from BaseWindow)
        super.init(size: windowSize)
        
        // Set up content view
        setupContentView()
        
        // Position the window relative to the menu bar icon
        positionRelativeToMenuBarIcon()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the content view with logo and tabs
    private func setupContentView() {
        // Use fixed height as specified in requirements (518px)
        let windowHeight: CGFloat = 518 // Fixed height as specified in requirements
        
        // Create standard content view with consistent styling
        let contentView = createStandardContentView(size: NSSize(width: windowWidth, height: windowHeight))
        
        // Debug: Print current directory
        let currentDirectory = FileManager.default.currentDirectoryPath
        print("PreferencesWindow: Current directory: \(currentDirectory)")
        
        // Add standard close button
        addStandardCloseButton(to: contentView, windowWidth: windowWidth, windowHeight: windowHeight)
        
        // Add PenAI logo
        addPenAILogo(to: contentView, windowHeight: windowHeight)
        
        // Add title
        let titleLabel = NSTextField(frame: NSRect(x: 70, y: windowHeight - 55, width: 200, height: 30))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_ai_preferences")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        contentView.addSubview(titleLabel)
        
        // Add user_settings frame
        let userSettingsFrame = NSView(frame: NSRect(x: 20, y: 20, width: windowWidth - 40, height: windowHeight - 120)) // Space from header
        userSettingsFrame.wantsLayer = true
        userSettingsFrame.layer?.backgroundColor = NSColor.white.cgColor
        
        // Add tab view to user_settings frame
        let tabView = NSTabView(frame: NSRect(x: 0, y: 0, width: userSettingsFrame.frame.width, height: userSettingsFrame.frame.height))
        
        // Create tabs
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "general"), iconPath: "\(FileManager.default.currentDirectoryPath)/Resources/Assets/settings.png")
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "account"), iconPath: "\(FileManager.default.currentDirectoryPath)/Resources/Assets/account.png")
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "ai_connections"), iconPath: "\(FileManager.default.currentDirectoryPath)/Resources/Assets/AI.png")
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "prompts"), iconPath: "\(FileManager.default.currentDirectoryPath)/Resources/Assets/prompts.png")
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "history"), iconPath: "\(FileManager.default.currentDirectoryPath)/Resources/Assets/account.png")
        
        userSettingsFrame.addSubview(tabView)
        contentView.addSubview(userSettingsFrame)
        
        // Set content view
        self.contentView = contentView
    }
    
    /// Adds a tab to the tab view
    private func addTab(to tabView: NSTabView, title: String, iconPath: String) {
        let tabItem = NSTabViewItem(identifier: title)
        tabItem.label = title
        
        // Create tab content view
        let tabContentView = NSView(frame: NSRect(origin: .zero, size: tabView.frame.size))
        tabContentView.wantsLayer = true
        tabContentView.layer?.backgroundColor = NSColor.white.cgColor
        
        // Add content based on tab title
        if title == LocalizationService.shared.localizedString(for: "account") {
            // Use the new AccountTabView
            let accountTabView = AccountTabView(frame: tabContentView.bounds, user: user, parentWindow: self)
            tabContentView.addSubview(accountTabView)
        } else if title == LocalizationService.shared.localizedString(for: "general") {
            // Use the new GeneralTabView
            let generalTabView = GeneralTabView(frame: tabContentView.bounds, parentWindow: self)
            tabContentView.addSubview(generalTabView)
        } else if title == LocalizationService.shared.localizedString(for: "ai_connections") {
            // Use the new AIConnectionTabView
            let databasePool = DatabaseConnectivityPool.shared
            
            let aiConnectionTabView = AIConnectionTabView(frame: tabContentView.bounds, user: user, databasePool: databasePool)
            if let userName = user?.name {
                aiConnectionTabView.setUserName(userName)
            }
            tabContentView.addSubview(aiConnectionTabView)
        }
        
        tabItem.view = tabContentView
        tabView.addTabViewItem(tabItem)
    }
    

    

}
