import Cocoa

class InitializationService {
    // MARK: - Properties
    private weak var delegate: PenAIDelegate?
    private var isOnline: Bool = false
    private var internetFailure: Bool = false
    private var databaseFailure: Bool = false
    private var needsOnlineLogoutMode: Bool = false
    
    // MARK: - Initialization
    init(delegate: PenAIDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - Public Methods
    
    /// Performs the initialization process
    func performInitialization() {
        print("InitializationService: Starting initialization process")
        
        // Step 1: Internet connectivity test
        print("InitializationService: Step 1 - Internet connectivity test")
        if !testInternetConnectivity() {
            print("InitializationService: Initialization process stopped due to internet failure")
            return
        }
        
        // Step 2: Database connectivity pool initialization
        print("InitializationService: Step 2 - Database connectivity pool initialization")
        if !testDatabaseConnectivity() {
            print("InitializationService: Initialization process stopped due to database failure")
            return
        }
        
        // Step 3: Automatic login and load user data
        print("InitializationService: Step 3 - Automatic login and load user data")
        automaticLogin()
        
        print("InitializationService: Initialization process completed successfully")
        print("InitializationService: App is ready for use")
        
        // Load menu bar icon and its behaviors as online-logout mode if needed
        if needsOnlineLogoutMode {
            print("InitializationService: Loading menu bar icon as online-logout mode")
            delegate?.setAppMode(.onlineLogout)
        }
    }
    
    // MARK: - Private Methods
    
    /// Tests internet connectivity
    private func testInternetConnectivity() -> Bool {
        print("InitializationService: Testing internet connectivity...")
        
        // Use the actual InternetConnectivityServiceTest
        let connectivityService = InternetConnectivityServiceTest.shared
        let isInternetAvailable = connectivityService.isInternetAvailable()
        
        if isInternetAvailable {
            print("InitializationService: Internet connection is available")
            print(" ********************************** PenAI Initialization Step 1: Internet Connectivity Test: PASS! **********************************")
            internetFailure = false
            setOnlineMode(true)
            return true
        } else {
            print("InitializationService: Internet connection is unavailable")
            print(" ********************************** PenAI Initialization Step 1: Internet Connectivity Test: FAIL! **********************************")
            print(" ********************************** OFFLINE-Internet-FAILURE MODE **********************************")
            internetFailure = true
            setOnlineMode(false, failureType: "internet")
            // Load menu bar icon for offline-internet-failure mode
            delegate?.setOnlineMode(false, failureType: "internet", internetFailure: true)
            return false
        }
    }
    
    /// Tests database connectivity and initializes pool
    private func testDatabaseConnectivity() -> Bool {
        print("InitializationService: Testing database connectivity...")
        
        // Get the shared DatabaseConnectivityPool instance
        let pool = DatabaseConnectivityPool.shared
        
        // Test database connectivity
        let isConnected = pool.testConnectivitySync()
        
        if isConnected {
            print("InitializationService: Database connection pool is ready")
            print("InitializationService: Pool size: \(pool.poolSize)")
            print(" ********************************** PenAI Initialization Step 2: Database Connectivity Test: PASS! **********************************")
            databaseFailure = false
            return true
        } else {
            print("InitializationService: Database connection pool initialization failed")
            print(" ********************************** PenAI Initialization Step 2: Database Connectivity Test: FAIL! **********************************")
            print(" ********************************** OFFLINE-DB-FAILURE MODE **********************************")
            databaseFailure = true
            setOnlineMode(false, failureType: "database")
            // Load menu bar icon for offline-db-failure mode
            delegate?.setOnlineMode(false, failureType: "database")
            return false
        }
    }
    
    /// Sets online mode and updates status icon
    private func setOnlineMode(_ online: Bool, failureType: String? = nil) {
        isOnline = online
        
        if online {
            print("InitializationService: Setting online mode")
            delegate?.setOnlineMode(true)
        } else {
            print("InitializationService: Setting offline mode")
            if failureType == "internet" {
                delegate?.setOnlineMode(false, failureType: "internet", internetFailure: true)
            } else if failureType == "database" {
                delegate?.setOnlineMode(false, failureType: "database")
            }
        }
    }
    
    /// Performs automatic login
    private func automaticLogin() {
        print("InitializationService: Attempting automatic login...")
        
        // Use AuthenticationService to attempt login
        let authService = AuthenticationService.shared
        
        // Check if credentials are stored
        if authService.hasStoredCredentials() {
            print(" ********************************** Pre-stored Credentials Found *********************************")
            print("InitializationService: Found stored credentials")
            print("InitializationService: Logging in automatically...")
            
            // Run async login in a task
            Task {
                let (user, success) = await authService.login()
                
                if success, let user = user {
                    print("InitializationService: Login successful")
                    print("InitializationService: User: \(user.name) (\(user.email))")
                    print("InitializationService: Retrieving personal data...")
                    print("InitializationService: Personal data retrieved successfully")
                    print(" ********************************** PenAI Initialization Step 3: Load User Data: PASS! **********************************")
                    print(" ********************************** Hello, \(user.name) **********************************")
                    // Set login status with user object
                    delegate?.setLoginStatus(true, user: user)
                    // Set online-login mode
                    delegate?.setOnlineMode(true)
                    
                    // Load and test AI configurations for the user
                    loadAndTestAIConfigurations(user: user)
                } else {
                    print(" ********************************** Auto Login Failed **********************************")
                    print(" ********************************** ONLINE-LOGOUT MODE **********************************")
                    print("InitializationService: Login failed with stored credentials")
                    print("InitializationService: Opening LoginWindow for manual login")
                    delegate?.setLoginStatus(false)
                    delegate?.setOnlineMode(true)
                    delegate?.openLoginWindow()
                }
            }
        } else {
            print(" ********************************** No Pre-stored Credentials Found **********************************")
            print("InitializationService: No stored credentials found")
            print("InitializationService: Setting online-logout mode")
            // End initialization process first, then load menu bar icon
            needsOnlineLogoutMode = true
        }
    }
    
    /// Loads and tests AI configurations for the user
    private func loadAndTestAIConfigurations(user: User) {
        Task {
            do {
                // Load all AI configurations for the user
                let configurations = try await AIManager.shared.getConnections(for: user.id)
                
                print("InitializationService: Loaded \(configurations.count) AI configurations for user \(user.name)")
                
                if configurations.isEmpty {
                    // No AI configurations found
                    print("InitializationService: No AI configurations found for user \(user.name)")
                    // Wait until previous popup messages fade out (3 seconds + 0.3 seconds fade out)
                    try await Task.sleep(nanoseconds: 3_300_000_000) // 3.3 seconds
                    // Show shorter popup message
                    WindowManager.displayPopupMessage("No AI Configuration set up yet.\nGo to Preference → AI Configuration to set up.")
                } else {
                    // Test each AI configuration
                    for (index, configuration) in configurations.enumerated() {
                        print("\n********************************** Test AI Configuration for \(user.name) : Provider \(index + 1): \(configuration.apiProvider) **********************************")
                        
                        do {
                            // Test the connection
                            let success = try await AIManager.shared.testConnection(
                                apiKey: configuration.apiKey,
                                providerName: configuration.apiProvider
                            )
                            
                            if success {
                                print("InitializationService: AI Configuration \(configuration.apiProvider) test successful")
                            } else {
                                print("InitializationService: AI Configuration \(configuration.apiProvider) test failed")
                            }
                        } catch {
                            print("InitializationService: Error testing AI Configuration \(configuration.apiProvider): \(error)")
                        }
                    }
                }
            } catch {
                print("InitializationService: Error loading AI configurations: \(error)")
            }
        }
    }
}
