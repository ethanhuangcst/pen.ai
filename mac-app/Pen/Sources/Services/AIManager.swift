import Foundation

public class AIManager {
    

    // MARK: - Private Nested Types
    
    private struct AIConfiguration {
        let id: Int
        let userId: Int
        var apiKey: String
        var apiProvider: String
        let createdAt: Date
        var updatedAt: Date?
        
        // Database parsing methods
        static func fromDatabaseRow(_ row: [String: Any]) -> AIConfiguration? {
            // Handle id as string or int
            let id: Int
            if let idInt = row["id"] as? Int {
                id = idInt
            } else if let idString = row["id"] as? String, let idInt = Int(idString) {
                id = idInt
            } else {
                print("[AIConfiguration] Missing or invalid id: \(row["id"] ?? "nil")")
                return nil
            }
            
            // Handle userId as string or int
            let userId: Int
            if let userIdInt = row["user_id"] as? Int {
                userId = userIdInt
            } else if let userIdString = row["user_id"] as? String, let userIdInt = Int(userIdString) {
                userId = userIdInt
            } else {
                print("[AIConfiguration] Missing or invalid user_id: \(row["user_id"] ?? "nil")")
                return nil
            }
            
            guard let apiKey = row["apiKey"] as? String,
                  let apiProvider = row["apiProvider"] as? String else {
                print("[AIConfiguration] Missing or invalid apiKey or apiProvider")
                return nil
            }
            
            // Parse timestamps
            let createdAt: Date
            if let createdAtString = row["createdAt"] as? String,
               let date = ISO8601DateFormatter().date(from: createdAtString) {
                createdAt = date
            } else {
                createdAt = Date()
            }
            
            var updatedAt: Date?
            if let updatedAtString = row["updatedAt"] as? String,
               let date = ISO8601DateFormatter().date(from: updatedAtString) {
                updatedAt = date
            }
            
            return AIConfiguration(id: id, userId: userId, apiKey: apiKey, apiProvider: apiProvider, createdAt: createdAt, updatedAt: updatedAt)
        }
    }
    
    private struct AIModelProvider {
        let id: Int
        let name: String
        let baseURLs: [String: String]
        let defaultModel: String
        let requiresAuth: Bool
        let authHeader: String
        let createdAt: Date
        let updatedAt: Date?
        
        // Database parsing and validation methods
        static func fromDatabaseRow(_ row: [String: Any]) -> AIModelProvider? {
            // Handle id as string or int
            let id: Int
            if let idInt = row["id"] as? Int {
                id = idInt
            } else if let idString = row["id"] as? String, let idInt = Int(idString) {
                id = idInt
            } else {
                // Generate a default id if not provided or invalid
                id = Int(Date.timeIntervalSinceReferenceDate * 1000)
            }
            
            guard let name = row["name"] as? String,
                  let defaultModel = row["default_model"] as? String,
                  let requiresAuth = row["requires_auth"] as? Int else {
                return nil
            }
            
            // Optional fields
            let authHeader = row["auth_header"] as? String ?? "Authorization"
            
            // Parse base_urls JSON (optional)
            var baseURLs: [String: String] = [:]
            if let baseURLsJSON = row["base_urls"] as? String,
               let data = baseURLsJSON.data(using: .utf8) {
                // Try to parse as dictionary first
                if let urls = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    baseURLs = urls
                } 
                // Try to parse as array of strings
                else if let urlArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                    // Map array to dictionary with default keys and construct full endpoints
                    if !urlArray.isEmpty {
                        // For each base URL, construct completion endpoints
                        for (index, baseURL) in urlArray.enumerated() {
                            // Remove any trailing slashes
                            let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                            
                            // Construct completion endpoint for each base URL
                            // This allows us to try all URLs in order
                            let completionKey = "completion_\(index)"
                            baseURLs[completionKey] = "\(cleanBaseURL)/chat/completions"
                        }
                    }
                }
            } else {
                // Set default base URLs based on provider name
                baseURLs = getDefaultBaseURLs(for: name)
            }
            
            // Parse timestamps
            let createdAt: Date
            if let createdAtString = row["created_at"] as? String,
               let date = ISO8601DateFormatter().date(from: createdAtString) {
                createdAt = date
            } else {
                createdAt = Date()
            }
            
            var updatedAt: Date?
            if let updatedAtString = row["updated_at"] as? String,
               let date = ISO8601DateFormatter().date(from: updatedAtString) {
                updatedAt = date
            }
            
            return AIModelProvider(
                id: id,
                name: name,
                baseURLs: baseURLs,
                defaultModel: defaultModel,
                requiresAuth: requiresAuth == 1,
                authHeader: authHeader,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
        
        /// Gets default base URLs for a provider
        private static func getDefaultBaseURLs(for providerName: String) -> [String: String] {
            // Try to load from configuration file
            if let configURLs = loadDefaultBaseURLsFromConfig() {
                let normalizedName = providerName.lowercased()
                if let providerURLs = configURLs[normalizedName] {
                    return providerURLs
                }
                if let defaultURLs = configURLs["default"] {
                    return defaultURLs
                }
            }
            
            // Fallback to hard-coded defaults if config fails
            switch providerName.lowercased() {
            case "deepseek3.2":
                return ["completion": "https://api.deepseek.com/v1/chat/completions"]
            case "gpt-4o-mini":
                return [
                    "completion": "https://api.openai.com/v1/chat/completions",
                    "embedding": "https://api.openai.com/v1/embeddings",
                    "image": "https://api.openai.com/v1/images/generations"
                ]
            case "qwen-plus":
                return ["completion": "https://api.baichuan-ai.com/v1/chat/completions"]
            default:
                return ["completion": "https://api.openai.com/v1/chat/completions"]
            }
        }
        
        /// Loads default base URLs from configuration file
        private static func loadDefaultBaseURLsFromConfig() -> [String: [String: String]]? {
            let configPath = Bundle.main.path(forResource: "default_base_urls", ofType: "json", inDirectory: "config")
            guard let configPath = configPath, let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)) else {
                print("[AIManager] Failed to load default_base_urls.json")
                return nil
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let defaultBaseURLs = json["defaultBaseURLs"] as? [String: [String: String]] {
                    return defaultBaseURLs
                }
            } catch {
                print("[AIManager] Error parsing default_base_urls.json: \(error)")
            }
            
            return nil
        }
        
        /// Validates the provider data
        func validate() throws {
            guard !name.isEmpty else {
                throw AIError.providerError("Missing provider name")
            }
            
            guard !baseURLs.isEmpty else {
                throw AIError.providerError("Missing base URLs")
            }
            
            guard !defaultModel.isEmpty else {
                throw AIError.providerError("Missing default model")
            }
        }
    }
    
    private enum AIError: Error {
        case invalidAPIKey
        case rateLimited
        case networkError
        case invalidResponse
        case providerError(String)
        case configurationError(String)
    }
    
    private protocol ProviderStrategy {
        func buildChatPayload(messages: [AIMessage]) -> [String: Any]
        func parseChatResponse(data: Data) throws -> AIResponse
        var chatEndpoint: String { get }
        var embeddingEndpoint: String { get }
        var imageEndpoint: String { get }
    }
    
    public struct AIMessage {
        public let role: String
        public let content: String
    }
    
    public struct AIResponse {
        public let id: String
        public let content: String
        public let model: String
        public let usage: AIUsage?
    }
    
    public struct AIUsage {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
    }
    
    public struct AIProvider {
        public let id: Int
        public let name: String
        public let baseURLs: [String: String]
        public let defaultModel: String
        public let requiresAuth: Bool
        public let authHeader: String
    }
    
    // MARK: - Private Properties
    
    private var strategies: [String: ProviderStrategy] = [:]
    private var cachedProviders: [AIModelProvider]?
    private var databasePool: DatabaseConnectivityPool
    private var currentConfiguration: AIConfiguration?
    private var _isInitialized: Bool = false
    
    // MARK: - Public Properties
    
    public var isInitialized: Bool {
        return _isInitialized
    }
    
    // MARK: - Initialization
    
    public init() {
        self.databasePool = DatabaseConnectivityPool.shared
    }
    
    // MARK: - Initialization Method
    
    public func initialize() {
        _isInitialized = true
    }
    
    // MARK: - Public Methods
    
    public func configure(apiKey: String, providerName: String, userId: Int) {
        let configuration = AIConfiguration(
            id: 0, // Temporary ID
            userId: userId,
            apiKey: apiKey,
            apiProvider: providerName,
            createdAt: Date(),
            updatedAt: nil
        )
        currentConfiguration = configuration
    }
    
    public func configure(with configuration: [String: Any]) {
        if let config = AIConfiguration.fromDatabaseRow(configuration) {
            currentConfiguration = config
        }
    }
    
    public func sendChat(
        messages: [AIMessage],
        model: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> AIResponse {
        guard let configuration = currentConfiguration else {
            throw AIError.configurationError("Not configured")
        }
        
        let provider = try await loadProviderByName(configuration.apiProvider)
        guard let provider = provider else {
            throw AIError.providerError("Provider not found")
        }
        
        let strategy = createStrategy(for: provider)
        var payload = strategy.buildChatPayload(messages: messages)
        
        // Override with custom parameters if provided
        if let model = model {
            payload["model"] = model
        }
        
        payload["temperature"] = temperature
        
        if let maxTokens = maxTokens {
            payload["max_tokens"] = maxTokens
        }
        
        let data = try await performRequest(
            endpoint: strategy.chatEndpoint,
            body: payload,
            apiKey: configuration.apiKey,
            authHeader: provider.authHeader,
            requiresAuth: provider.requiresAuth
        )
        
        return try strategy.parseChatResponse(data: data)
    }
    
    public func testConnection(apiKey: String, providerName: String) async throws -> Bool {
        let provider = try await loadProviderByName(providerName)
        guard let provider = provider else {
            throw AIError.providerError("Provider not found")
        }
        
        // Get all base URLs from the provider
        var baseURLs = Array(provider.baseURLs.values)
        
        // Filter to only test chat completion endpoints
        baseURLs = baseURLs.filter { $0.contains("chat/completions") }
        
        if baseURLs.isEmpty {
            throw AIError.providerError("No chat completion endpoints found")
        }
        
        // Test each base URL in order
        var totalAttempts = 0
        var lastError: String = ""
        
        for baseURL in baseURLs {
            totalAttempts += 1
            
            do {
                print("Attempt \(totalAttempts) for \(providerName) using URL: \(baseURL)")
                
                // Create URL object
                guard let url = URL(string: baseURL) else {
                    print("Invalid URL: \(baseURL)")
                    lastError = "Invalid URL: \(baseURL)"
                    continue
                }
                
                // Create URLRequest
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30.0 // 30 seconds timeout
                
                // Add authorization header
                if provider.requiresAuth {
                    // For providers like OpenAI that use Bearer token
                    if provider.authHeader == "Authorization" {
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: provider.authHeader)
                        print("[AIManager] Debug: Using Bearer token authentication")
                    } else {
                        // For providers like Anthropic that use direct API key
                        request.setValue(apiKey, forHTTPHeaderField: provider.authHeader)
                        print("[AIManager] Debug: Using direct API key authentication")
                    }
                }
                
                // Create test payload
                let testPayload: [String: Any] = [
                    "model": provider.defaultModel,
                    "messages": [
                        ["role": "user", "content": "Hello, this is a test to verify API connectivity. Please respond with 'API test successful'."]
                    ],
                    "max_tokens": 20,
                    "temperature": 0.7
                ]
                
                // Encode payload to JSON
                let jsonData = try JSONSerialization.data(withJSONObject: testPayload)
                request.httpBody = jsonData
                
                // Make API call
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Log raw response
                print("[AIManager] Debug: Raw response data:")
                print(String(data: data, encoding: .utf8) ?? "No response body")
                
                // Check response status code
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    let errorMessage = "API call failed with status code: \(statusCode)"
                    print(errorMessage)
                    lastError = errorMessage
                    continue
                }
                
                // Parse response
                do {
                    let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let choices = responseData?["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let _ = message["content"] as? String {
                        print("Successfully connected to \(providerName) using URL: \(baseURL)")
                        return true
                    } else {
                        let errorMessage = "Invalid API response format"
                        print(errorMessage)
                        lastError = errorMessage
                        continue
                    }
                } catch {
                    let errorMessage = "Failed to parse API response: \(error)"
                    print(errorMessage)
                    lastError = errorMessage
                    continue
                }
            } catch {
                let errorMessage = "Error connecting to \(baseURL): \(error)"
                print(errorMessage)
                lastError = errorMessage
                continue
            }
        }
        
        // All URLs failed
        print("All \(totalAttempts) attempts to connect to \(providerName) failed")
        throw AIError.networkError
    }
    
    // Test Call
    public func AITestCall(
        prompt: String,
        model: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int = 50
    ) async throws -> AIResponse {
        // Implementation for testing a complete AI call with custom parameters
        let testMessage = AIMessage(role: "user", content: prompt)
        return try await sendChat(
            messages: [testMessage],
            model: model,
            temperature: temperature,
            maxTokens: maxTokens
        )
    }
    
    // Get current configuration
    public func getCurrentConfiguration() -> [String: Any]? {
        guard let config = currentConfiguration else {
            return nil
        }
        
        var result: [String: Any] = [
            "id": config.id,
            "userId": config.userId,
            "apiKey": config.apiKey,
            "apiProvider": config.apiProvider,
            "createdAt": ISO8601DateFormatter().string(from: config.createdAt)
        ]
        
        if let updatedAt = config.updatedAt {
            result["updatedAt"] = ISO8601DateFormatter().string(from: updatedAt)
        }
        
        return result
    }
    
    // Clear configuration
    public func clearConfiguration() {
        currentConfiguration = nil
    }
    
    // Reset the entire AIManager instance
    public func reset() {
        strategies = [:]
        cachedProviders = nil
        currentConfiguration = nil
        _isInitialized = false
    }
    
    // Validate configuration
    public func validateConfiguration() -> Bool {
        return currentConfiguration != nil
    }
    
    // MARK: - Public Methods for UI
    
    // Public struct for UI use
    public struct PublicAIConfiguration {
        public let id: Int
        public let userId: Int
        public var apiKey: String
        public var apiProvider: String
        public let createdAt: Date
        public var updatedAt: Date?
    }
    
    // Public struct for UI use
    public struct PublicAIModelProvider {
        public let id: Int
        public let name: String
        public let baseURLs: [String: String]
        public let defaultModel: String
        public let requiresAuth: Bool
        public let authHeader: String
        public let createdAt: Date
        public let updatedAt: Date?
    }
    
    // Load all providers for UI
    public func loadAllProviders() async throws -> [PublicAIModelProvider] {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw AIError.configurationError("Failed to get database connection")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Try direct MySQLConnection access for JSON columns
            if let mysqlConnection = connection as? MySQLConnection, let internalConnection = mysqlConnection.getConnection() {
                print("[AIManager] Using direct MySQL connection for JSON columns")
                
                // Execute query directly with JSON column cast to string
                let query = "SELECT id, name, CAST(base_urls AS CHAR) as base_urls, default_model, requires_auth, auth_header, created_at, updated_at FROM ai_providers"
                print("[AIManager] Executing query: \(query)")
                let rows = try await internalConnection.query(query).get()
                
                var providers: [PublicAIModelProvider] = []
                
                for row in rows {
                    // Create a row dictionary manually
                    var rowData: [String: Any] = [:]
                    
                    // Debug: Try to access base_urls directly
                    print("[AIManager] Debug: Trying to access base_urls column")
                    if let baseURLsData = row.column("base_urls") {
                        print("[AIManager] Debug: base_urls column exists")
                        print("[AIManager] Debug: base_urls data type: \(type(of: baseURLsData))")
                        
                        // Try to get as string
                        if let baseURLs = baseURLsData.string {
                            rowData["base_urls"] = baseURLs
                            print("[AIManager] Debug: base_urls as string: \(baseURLs)")
                        } else {
                            print("[AIManager] Debug: base_urls is not a string")
                        }
                    } else {
                        print("[AIManager] Debug: base_urls column not found in row")
                    }
                    
                    // Access other columns
                    if let idData = row.column("id"), let id = idData.string {
                        rowData["id"] = id
                    }
                    if let nameData = row.column("name"), let name = nameData.string {
                        rowData["name"] = name
                        print("[AIManager] Debug: Provider name: \(name)")
                    }
                    if let defaultModelData = row.column("default_model"), let defaultModel = defaultModelData.string {
                        rowData["default_model"] = defaultModel
                        print("[AIManager] Debug: Default model: \(defaultModel)")
                    }
                    if let requiresAuthData = row.column("requires_auth"), let requiresAuth = requiresAuthData.int {
                        rowData["requires_auth"] = requiresAuth
                    }
                    if let authHeaderData = row.column("auth_header"), let authHeader = authHeaderData.string {
                        rowData["auth_header"] = authHeader
                        print("[AIManager] Debug: Auth header: \(authHeader)")
                    } else {
                        print("[AIManager] Debug: Auth header not found, using default")
                    }
                    if let createdAtData = row.column("created_at"), let createdAt = createdAtData.string {
                        rowData["created_at"] = createdAt
                    }
                    if let updatedAtData = row.column("updated_at"), let updatedAt = updatedAtData.string {
                        rowData["updated_at"] = updatedAt
                    }
                    
                    // Create provider from row data
                    if let provider = AIModelProvider.fromDatabaseRow(rowData) {
                        try provider.validate()
                        
                        // Convert to public provider
                        let publicProvider = PublicAIModelProvider(
                            id: provider.id,
                            name: provider.name,
                            baseURLs: provider.baseURLs,
                            defaultModel: provider.defaultModel,
                            requiresAuth: provider.requiresAuth,
                            authHeader: provider.authHeader,
                            createdAt: provider.createdAt,
                            updatedAt: provider.updatedAt
                        )
                        providers.append(publicProvider)
                    }
                }
                
                return providers
            } else {
                // Fallback to regular method
                print("[AIManager] Falling back to regular execute method")
                let query = "SELECT * FROM ai_providers"
                let results = try await connection.execute(query: query)
                
                var providers: [PublicAIModelProvider] = []
                
                for row in results {
                    if let provider = AIModelProvider.fromDatabaseRow(row) {
                        try provider.validate()
                        
                        // Convert to public provider
                        let publicProvider = PublicAIModelProvider(
                            id: provider.id,
                            name: provider.name,
                            baseURLs: provider.baseURLs,
                            defaultModel: provider.defaultModel,
                            requiresAuth: provider.requiresAuth,
                            authHeader: provider.authHeader,
                            createdAt: provider.createdAt,
                            updatedAt: provider.updatedAt
                        )
                        providers.append(publicProvider)
                    }
                }
                
                return providers
            }
        } catch {
            print("Error loading AI providers: \(error)")
            // Return default providers if database loading fails
            return getDefaultPublicProviders()
        }
    }
    
    // Get default public providers
    private func getDefaultPublicProviders() -> [PublicAIModelProvider] {
        let now = Date()
        
        // OpenAI
        let openAI = PublicAIModelProvider(
            id: 1,
            name: "OpenAI",
            baseURLs: ["completion": "https://api.openai.com/v1/chat/completions"],
            defaultModel: "gpt-4",
            requiresAuth: true,
            authHeader: "Authorization",
            createdAt: now,
            updatedAt: now
        )
        
        // Anthropic
        let anthropic = PublicAIModelProvider(
            id: 2,
            name: "Anthropic",
            baseURLs: ["completion": "https://api.anthropic.com/v1/messages"],
            defaultModel: "claude-3-opus-20240229",
            requiresAuth: true,
            authHeader: "x-api-key",
            createdAt: now,
            updatedAt: now
        )
        
        // Google AI
        let googleAI = PublicAIModelProvider(
            id: 3,
            name: "Google AI",
            baseURLs: ["completion": "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"],
            defaultModel: "gemini-pro",
            requiresAuth: true,
            authHeader: "x-goog-api-key",
            createdAt: now,
            updatedAt: now
        )
        
        // Azure OpenAI
        let azureOpenAI = PublicAIModelProvider(
            id: 4,
            name: "Azure OpenAI",
            baseURLs: ["completion": "https://{your-resource-name}.openai.azure.com/openai/deployments/{deployment-id}/chat/completions?api-version=2024-02-01"],
            defaultModel: "gpt-4",
            requiresAuth: true,
            authHeader: "api-key",
            createdAt: now,
            updatedAt: now
        )
        
        return [openAI, anthropic, googleAI, azureOpenAI]
    }
    
    // Get connections for a user
    public func getConnections(for userId: Int) async throws -> [PublicAIConfiguration] {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw AIError.configurationError("Failed to get database connection")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Execute the query
            let query = "SELECT * FROM ai_connections WHERE user_id = \(userId)"
            let results = try await connection.execute(query: query)
            
            var configurations: [PublicAIConfiguration] = []
            
            for row in results {
                if let config = AIConfiguration.fromDatabaseRow(row) {
                    let publicConfig = PublicAIConfiguration(
                        id: config.id,
                        userId: config.userId,
                        apiKey: config.apiKey,
                        apiProvider: config.apiProvider,
                        createdAt: config.createdAt,
                        updatedAt: config.updatedAt
                    )
                    configurations.append(publicConfig)
                }
            }
            
            return configurations
        } catch {
            print("Error getting AI connections: \(error)")
            throw error
        }
    }
    
    // MARK: - Provider Methods
    
    public func getProviders() async throws -> [AIProvider] {
        do {
            let publicProviders = try await loadAllProviders()
            return publicProviders.map { provider in
                AIProvider(
                    id: provider.id,
                    name: provider.name,
                    baseURLs: provider.baseURLs,
                    defaultModel: provider.defaultModel,
                    requiresAuth: provider.requiresAuth,
                    authHeader: provider.authHeader
                )
            }
        } catch {
            print("Error getting AI providers: \(error)")
            throw error
        }
    }
    
    // Create a new connection
    public func createConnection(userId: Int, apiKey: String, providerName: String) async throws -> Bool {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw AIError.configurationError("Failed to get database connection")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Execute the query
            let query = "INSERT INTO ai_connections (user_id, apiKey, apiProvider) VALUES (\(userId), '\(apiKey)', '\(providerName)')"
            try await connection.execute(query: query)
            return true
        } catch {
            print("Error creating AI connection: \(error)")
            throw error
        }
    }
    
    // Delete a connection
    public func deleteConnection(_ connectionId: Int) async throws -> Bool {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw AIError.configurationError("Failed to get database connection")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Execute the query
            let query = "DELETE FROM ai_connections WHERE id = \(connectionId)"
            try await connection.execute(query: query)
            return true
        } catch {
            print("Error deleting AI connection: \(error)")
            throw error
        }
    }
    
    // Update an existing connection
    public func updateConnection(id: Int, apiKey: String, providerName: String) async throws -> Bool {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw AIError.configurationError("Failed to get database connection")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Execute the query
            let query = "UPDATE ai_connections SET apiKey = '\(apiKey)', apiProvider = '\(providerName)', updatedAt = NOW() WHERE id = \(id)"
            try await connection.execute(query: query)
            return true
        } catch {
            print("Error updating AI connection: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func loadProviderByName(_ name: String) async throws -> AIModelProvider? {
        // Check cache first
        if let cached = cachedProviders?.first(where: { $0.name == name }) {
            return cached
        }
        
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw AIError.configurationError("Failed to get database connection")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Try direct MySQLConnection access for JSON columns
            if let mysqlConnection = connection as? MySQLConnection, let internalConnection = mysqlConnection.getConnection() {
                print("[AIManager] Using direct MySQL connection for JSON columns")
                
                // Execute query directly with JSON column cast to string
                let query = "SELECT id, name, CAST(base_urls AS CHAR) as base_urls, default_model, requires_auth, auth_header, created_at, updated_at FROM ai_providers WHERE name = '\(name)'"
                print("[AIManager] Executing query: \(query)")
                let rows = try await internalConnection.query(query).get()
                
                guard !rows.isEmpty else {
                    return nil
                }
                
                for row in rows {
                    // Create a row dictionary manually
                    var rowData: [String: Any] = [:]
                    
                    // Debug: Try to access base_urls directly
                    print("[AIManager] Debug: Trying to access base_urls column")
                    if let baseURLsData = row.column("base_urls") {
                        print("[AIManager] Debug: base_urls column exists")
                        print("[AIManager] Debug: base_urls data type: \(type(of: baseURLsData))")
                        
                        // Try to get as string
                        if let baseURLs = baseURLsData.string {
                            rowData["base_urls"] = baseURLs
                            print("[AIManager] Debug: base_urls as string: \(baseURLs)")
                        } else {
                            print("[AIManager] Debug: base_urls is not a string")
                        }
                    } else {
                        print("[AIManager] Debug: base_urls column not found in row")
                    }
                    
                    // Access other columns
                    if let idData = row.column("id"), let id = idData.string {
                        rowData["id"] = id
                    }
                    if let nameData = row.column("name"), let name = nameData.string {
                        rowData["name"] = name
                        print("[AIManager] Debug: Provider name: \(name)")
                    }
                    if let defaultModelData = row.column("default_model"), let defaultModel = defaultModelData.string {
                        rowData["default_model"] = defaultModel
                        print("[AIManager] Debug: Default model: \(defaultModel)")
                    }
                    if let requiresAuthData = row.column("requires_auth"), let requiresAuth = requiresAuthData.int {
                        rowData["requires_auth"] = requiresAuth
                    }
                    if let authHeaderData = row.column("auth_header"), let authHeader = authHeaderData.string {
                        rowData["auth_header"] = authHeader
                        print("[AIManager] Debug: Auth header: \(authHeader)")
                    } else {
                        print("[AIManager] Debug: Auth header not found, using default")
                    }
                    if let createdAtData = row.column("created_at"), let createdAt = createdAtData.string {
                        rowData["created_at"] = createdAt
                    }
                    if let updatedAtData = row.column("updated_at"), let updatedAt = updatedAtData.string {
                        rowData["updated_at"] = updatedAt
                    }
                    
                    // Create provider from row data
                    if let provider = AIModelProvider.fromDatabaseRow(rowData) {
                        try provider.validate()
                        
                        // Add to cache
                        if cachedProviders == nil {
                            cachedProviders = []
                        }
                        cachedProviders?.append(provider)
                        
                        return provider
                    }
                }
                
                return nil
            } else {
                // Fallback to regular method
                print("[AIManager] Falling back to regular execute method")
                let parameterizedQuery = "SELECT * FROM ai_providers WHERE name = '\(name)'"
                let results = try await connection.execute(query: parameterizedQuery)
                
                guard !results.isEmpty else {
                    return nil
                }
                
                if let provider = AIModelProvider.fromDatabaseRow(results[0]) {
                    try provider.validate()
                    
                    // Add to cache
                    if cachedProviders == nil {
                        cachedProviders = []
                    }
                    cachedProviders?.append(provider)
                    
                    return provider
                }
                
                return nil
            }
        } catch {
            print("Error loading AI provider by name: \(error)")
            // Return default provider if database loading fails
            return createDefaultProvider(for: name)
        }
    }
    
    private func createDefaultProvider(for name: String) -> AIModelProvider {
        // Create a default provider based on name
        let now = Date()
        var baseURLs: [String: String] = [:]
        var defaultModel: String = ""
        
        switch name.lowercased() {
        case "openai", "gpt-4o-mini":
            baseURLs = [
                "completion": "https://api.openai.com/v1/chat/completions",
                "embedding": "https://api.openai.com/v1/embeddings",
                "image": "https://api.openai.com/v1/images/generations"
            ]
            defaultModel = "gpt-4o-mini"
        case "deepseek", "deepseek3.2":
            baseURLs = ["completion": "https://api.deepseek.com/v1/chat/completions"]
            defaultModel = "deepseek-ai/deepseek-v1.5"
        case "baichuan":
            baseURLs = ["completion": "https://api.baichuan-ai.com/v1/chat/completions"]
            defaultModel = "Baichuan2-13B-Chat"
        case "qwen", "qwen-plus":
            baseURLs = ["completion": "https://api.baichuan-ai.com/v1/chat/completions"]
            defaultModel = "Qwen2.5-72B-Instruct"
        default:
            baseURLs = ["completion": "https://api.openai.com/v1/chat/completions"]
            defaultModel = "gpt-4o-mini"
        }
        
        return AIModelProvider(
            id: Int(Date.timeIntervalSinceReferenceDate * 1000),
            name: name,
            baseURLs: baseURLs,
            defaultModel: defaultModel,
            requiresAuth: true,
            authHeader: "Authorization",
            createdAt: now,
            updatedAt: now
        )
    }
    
    private func createStrategy(for provider: AIModelProvider) -> ProviderStrategy {
        return GenericProviderStrategy(provider: provider)
    }
    
    private struct GenericProviderStrategy: ProviderStrategy {
        private let provider: AIModelProvider
        
        init(provider: AIModelProvider) {
            self.provider = provider
        }
        
        func buildChatPayload(messages: [AIMessage]) -> [String: Any] {
            return [
                "model": provider.defaultModel,
                "messages": messages.map { ["role": $0.role, "content": $0.content] },
                "temperature": 0.7
            ]
        }
        
        func parseChatResponse(data: Data) throws -> AIResponse {
            // Parse response based on provider type
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let id = json?["id"] as? String,
                  let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String,
                  let model = json?["model"] as? String else {
                throw AIError.invalidResponse
            }
            
            var usage: AIUsage?
            if let usageData = json?["usage"] as? [String: Any],
               let promptTokens = usageData["prompt_tokens"] as? Int,
               let completionTokens = usageData["completion_tokens"] as? Int,
               let totalTokens = usageData["total_tokens"] as? Int {
                usage = AIUsage(promptTokens: promptTokens, completionTokens: completionTokens, totalTokens: totalTokens)
            }
            
            return AIResponse(
                id: id,
                content: content,
                model: model,
                usage: usage
            )
        }
        
        var chatEndpoint: String {
            // Get the first completion endpoint from baseURLs
            return provider.baseURLs.first { $0.key.contains("completion") }?.value ?? ""
        }
        
        var embeddingEndpoint: String {
            return provider.baseURLs["embedding"] ?? ""
        }
        
        var imageEndpoint: String {
            return provider.baseURLs["image"] ?? ""
        }
    }
    
    private func performRequest(
        endpoint: String,
        body: [String: Any],
        apiKey: String,
        authHeader: String,
        requiresAuth: Bool
    ) async throws -> Data {
        guard let url = URL(string: endpoint) else {
            throw AIError.configurationError("Invalid endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        if requiresAuth {
            if authHeader == "Authorization" {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: authHeader)
            } else {
                request.setValue(apiKey, forHTTPHeaderField: authHeader)
            }
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AIError.networkError
        }
        
        return data
    }
    
    private func mapError(_ data: Data, response: HTTPURLResponse) -> AIError {
        // Implementation for mapping provider-specific errors
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let error = json?["error"] as? [String: Any],
               let message = error["message"] as? String {
                return AIError.providerError(message)
            }
        } catch {
            // Ignore parsing errors
        }
        
        return AIError.networkError
    }
}
