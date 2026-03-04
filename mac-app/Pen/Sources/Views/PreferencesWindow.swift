import Cocoa

class PreferencesWindow: BaseWindow {
    // MARK: - Properties
    private let windowWidth: CGFloat = 600
    private let mouseOffset: CGFloat = 6
    private var user: User?
    
    private var titleLabel: NSTextField!
    private var userNameLabel: NSTextField!
    private var tabView: NSTabView!
    
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
        
        // Set window level to floating (below modalPanel)
        self.level = .floating
    }
    
    // MARK: - Language Change
    override func languageDidChange() {
        super.languageDidChange()
        
        // Update title
        titleLabel?.stringValue = LocalizationService.shared.localizedString(for: "pen_ai_preferences")
        
        // Update user name label
        userNameLabel?.stringValue = user?.name ?? LocalizationService.shared.localizedString(for: "no_user")
        
        // Update tab labels
        updateTabLabels()
        
        // Refresh all tab views
        refreshTabViews()
        
        print("PreferencesWindow: Language changed, UI updated")
    }
    
    private func updateTabLabels() {
        guard let tabView = tabView else { return }
        
        let tabKeys = ["account", "general", "ai_connections", "prompts", "history"]
        for (index, key) in tabKeys.enumerated() {
            if index < tabView.numberOfTabViewItems {
                let tabItem = tabView.tabViewItem(at: index)
                tabItem.label = LocalizationService.shared.localizedString(for: key)
            }
        }
    }
    
    private func refreshTabViews() {
        guard let tabView = tabView else { return }
        
        for i in 0..<tabView.numberOfTabViewItems {
            if let tabItem = tabView.tabViewItem(at: i) as? NSTabViewItem,
               let tabContentView = tabItem.view {
                for subview in tabContentView.subviews {
                    if let accountTab = subview as? AccountTabView {
                        accountTab.languageDidChange()
                    } else if let generalTab = subview as? GeneralTabView {
                        generalTab.languageDidChange()
                    } else if let aiConfigTab = subview as? AIConfigurationTabView {
                        aiConfigTab.languageDidChange()
                    } else if let promptsTab = subview as? PromptsTabView {
                        promptsTab.languageDidChange()
                    } else if let historyTab = subview as? HistoryTabView {
                        historyTab.languageDidChange()
                    }
                }
            }
        }
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
        titleLabel = NSTextField(frame: NSRect(x: 70, y: windowHeight - 55, width: 200, height: 30))
        titleLabel.stringValue = LocalizationService.shared.localizedString(for: "pen_ai_preferences")
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        contentView.addSubview(titleLabel)
        
        // Add user name label
        userNameLabel = NSTextField(frame: NSRect(x: 370, y: windowHeight - 55, width: 180, height: 30))
        userNameLabel.identifier = NSUserInterfaceItemIdentifier("preference_user_name")
        userNameLabel.stringValue = user?.name ?? LocalizationService.shared.localizedString(for: "no_user")
        userNameLabel.isBezeled = false
        userNameLabel.drawsBackground = false
        userNameLabel.isEditable = false
        userNameLabel.isSelectable = false
        userNameLabel.font = NSFont.boldSystemFont(ofSize: 18)
        userNameLabel.alignment = .right
        contentView.addSubview(userNameLabel)
        
        // Add user_settings frame
        let userSettingsFrame = NSView(frame: NSRect(x: 20, y: 20, width: windowWidth - 40, height: windowHeight - 120)) // Space from header
        userSettingsFrame.wantsLayer = true
        userSettingsFrame.layer?.backgroundColor = ColorService.shared.backgroundColorCGColor
        
        // Add tab view to user_settings frame
        tabView = NSTabView(frame: NSRect(x: 0, y: 0, width: userSettingsFrame.frame.width, height: userSettingsFrame.frame.height))
        
        // Create tabs
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "account"), iconPath: ResourceService.shared.getResourcePath(relativePath: "Assets/account.png"))
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "general"), iconPath: ResourceService.shared.getResourcePath(relativePath: "Assets/settings.png"))
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "ai_connections"), iconPath: ResourceService.shared.getResourcePath(relativePath: "Assets/AI.png"))
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "prompts"), iconPath: ResourceService.shared.getResourcePath(relativePath: "Assets/prompts.png"))
        addTab(to: tabView, title: LocalizationService.shared.localizedString(for: "history"), iconPath: ResourceService.shared.getResourcePath(relativePath: "Assets/account.png"))
        
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
        tabContentView.layer?.backgroundColor = ColorService.shared.backgroundColorCGColor
        
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
            // Use the new AIConfigurationTabView
            let databasePool = DatabaseConnectivityPool.shared
            
            let aiConfigurationTabView = AIConfigurationTabView(frame: tabContentView.bounds, user: user, databasePool: databasePool, parentWindow: self)
            if let userName = user?.name {
                aiConfigurationTabView.setUserName(userName)
            }
            tabContentView.addSubview(aiConfigurationTabView)
        } else if title == LocalizationService.shared.localizedString(for: "prompts") {
            // Use the new PromptsTabView
            let promptsTabView = PromptsTabView(frame: tabContentView.bounds, user: user, parentWindow: self)
            tabContentView.addSubview(promptsTabView)
        } else if title == LocalizationService.shared.localizedString(for: "history") {
            // Use the new HistoryTabView
            let historyTabView = HistoryTabView(frame: tabContentView.bounds, parentWindow: self)
            tabContentView.addSubview(historyTabView)
        }
        
        tabItem.view = tabContentView
        tabView.addTabViewItem(tabItem)
    }
    

    

}
