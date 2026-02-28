import Foundation

class AIConnectionService {
    private let databasePool: DatabaseConnectivityPool
    private var cachedProviders: [AIModelProvider]?
    
    init(databasePool: DatabaseConnectivityPool) {
        self.databasePool = databasePool
    }
    
    // MARK: - AI Model Providers
    
    /// Loads all AI model providers from the database
    /// - Returns: Array of AIModelProvider objects
    /// - Throws: Error if database operation fails
    func loadAllProviders() async throws -> [AIModelProvider] {
        // Return cached providers if available
        if let cached = cachedProviders {
            return cached
        }
        
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw NSError(domain: "AIConnectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Try direct MySQLConnection access for JSON columns
            if let mysqlConnection = connection as? MySQLConnection, let internalConnection = mysqlConnection.getConnection() {
                print("[AIConnectionService] Using direct MySQL connection for JSON columns")
                
                // Execute query directly with JSON column cast to string
                let query = "SELECT id, name, CAST(base_urls AS CHAR) as base_urls, default_model, requires_auth, auth_header, created_at, updated_at FROM ai_providers"
                print("[AIConnectionService] Executing query: \(query)")
                let rows = try await internalConnection.query(query).get()
                
                var providers: [AIModelProvider] = []
                
                for row in rows {
                    // Create a row dictionary manually
                    var rowData: [String: Any] = [:]
                    
                    // Debug: Try to access base_urls directly
                    print("[AIConnectionService] Debug: Trying to access base_urls column")
                    if let baseURLsData = row.column("base_urls") {
                        print("[AIConnectionService] Debug: base_urls column exists")
                        print("[AIConnectionService] Debug: base_urls data type: \(type(of: baseURLsData))")
                        
                        // Try to get as string
                        if let baseURLs = baseURLsData.string {
                            rowData["base_urls"] = baseURLs
                            print("[AIConnectionService] Debug: base_urls as string: \(baseURLs)")
                        } else {
                            print("[AIConnectionService] Debug: base_urls is not a string")
                        }
                    } else {
                        print("[AIConnectionService] Debug: base_urls column not found in row")
                    }
                    
                    // Access other columns
                    if let idData = row.column("id"), let id = idData.string {
                        rowData["id"] = id
                    }
                    if let nameData = row.column("name"), let name = nameData.string {
                        rowData["name"] = name
                    }
                    if let defaultModelData = row.column("default_model"), let defaultModel = defaultModelData.string {
                        rowData["default_model"] = defaultModel
                    }
                    if let requiresAuthData = row.column("requires_auth"), let requiresAuth = requiresAuthData.int {
                        rowData["requires_auth"] = requiresAuth
                    }
                    if let authHeaderData = row.column("auth_header"), let authHeader = authHeaderData.string {
                        rowData["auth_header"] = authHeader
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
                        providers.append(provider)
                    }
                }
                
                // Cache the providers for future use
                cachedProviders = providers
                
                return providers
            } else {
                // Fallback to regular method
                print("[AIConnectionService] Falling back to regular execute method")
                let query = "SELECT * FROM ai_providers"
                let results = try await connection.execute(query: query)
                
                var providers: [AIModelProvider] = []
                
                for row in results {
                    if let provider = AIModelProvider.fromDatabaseRow(row) {
                        try provider.validate()
                        providers.append(provider)
                    }
                }
                
                // Cache the providers for future use
                cachedProviders = providers
                
                return providers
            }
        } catch {
            print("Error loading AI providers: \(error)")
            // Return default providers if database loading fails
            return getDefaultProviders()
        }
    }
    
    /// Loads a specific AI model provider by ID
    /// - Parameter id: Provider ID
    /// - Returns: AIModelProvider if found, nil otherwise
    /// - Throws: Error if database operation fails
    func loadProviderById(_ id: Int) async throws -> AIModelProvider? {
        let query = "SELECT * FROM ai_providers WHERE id = ?"
        
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw NSError(domain: "AIConnectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Execute the query with parameter
            // Note: This is a simplified version - in a real implementation, we'd use parameterized queries
            let parameterizedQuery = "SELECT * FROM ai_providers WHERE id = \(id)"
            let results = try await connection.execute(query: parameterizedQuery)
            
            guard !results.isEmpty else {
                return nil
            }
            
            return AIModelProvider.fromDatabaseRow(results[0])
        } catch {
            print("Error loading AI provider by ID: \(error)")
            return nil
        }
    }
    
    /// Loads a specific AI model provider by name
    /// - Parameter name: Provider name
    /// - Returns: AIModelProvider if found, nil otherwise
    /// - Throws: Error if database operation fails
    func loadProviderByName(_ name: String) async throws -> AIModelProvider? {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw NSError(domain: "AIConnectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Try direct MySQLConnection access for JSON columns
            if let mysqlConnection = connection as? MySQLConnection, let internalConnection = mysqlConnection.getConnection() {
                print("[AIConnectionService] Using direct MySQL connection for JSON columns")
                
                // Execute query directly with JSON column cast to string
                let query = "SELECT id, name, CAST(base_urls AS CHAR) as base_urls, default_model, requires_auth, auth_header, created_at, updated_at FROM ai_providers WHERE name = '\(name)'"
                print("[AIConnectionService] Executing query: \(query)")
                let rows = try await internalConnection.query(query).get()
                
                guard !rows.isEmpty else {
                    return nil
                }
                
                for row in rows {
                    // Create a row dictionary manually
                    var rowData: [String: Any] = [:]
                    
                    // Debug: Try to access base_urls directly
                    print("[AIConnectionService] Debug: Trying to access base_urls column")
                    if let baseURLsData = row.column("base_urls") {
                        print("[AIConnectionService] Debug: base_urls column exists")
                        print("[AIConnectionService] Debug: base_urls data type: \(type(of: baseURLsData))")
                        
                        // Try to get as string
                        if let baseURLs = baseURLsData.string {
                            rowData["base_urls"] = baseURLs
                            print("[AIConnectionService] Debug: base_urls as string: \(baseURLs)")
                        } else {
                            print("[AIConnectionService] Debug: base_urls is not a string")
                        }
                    } else {
                        print("[AIConnectionService] Debug: base_urls column not found in row")
                    }
                    
                    // Access other columns
                    if let idData = row.column("id"), let id = idData.string {
                        rowData["id"] = id
                    }
                    if let nameData = row.column("name"), let name = nameData.string {
                        rowData["name"] = name
                        print("[AIConnectionService] Debug: Provider name: \(name)")
                    }
                    if let defaultModelData = row.column("default_model"), let defaultModel = defaultModelData.string {
                        rowData["default_model"] = defaultModel
                        print("[AIConnectionService] Debug: Default model: \(defaultModel)")
                    }
                    if let requiresAuthData = row.column("requires_auth"), let requiresAuth = requiresAuthData.int {
                        rowData["requires_auth"] = requiresAuth
                    }
                    if let authHeaderData = row.column("auth_header"), let authHeader = authHeaderData.string {
                        rowData["auth_header"] = authHeader
                        print("[AIConnectionService] Debug: Auth header: \(authHeader)")
                    } else {
                        print("[AIConnectionService] Debug: Auth header not found, using default")
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
                        return provider
                    }
                }
                
                return nil
            } else {
                // Fallback to regular method
                print("[AIConnectionService] Falling back to regular execute method")
                let parameterizedQuery = "SELECT * FROM ai_providers WHERE name = '\(name)'"
                let results = try await connection.execute(query: parameterizedQuery)
                
                guard !results.isEmpty else {
                    return nil
                }
                
                return AIModelProvider.fromDatabaseRow(results[0])
            }
        } catch {
            print("Error loading AI provider by name: \(error)")
            return nil
        }
    }
    
    /// Clears the cached providers
    func clearCache() {
        cachedProviders = nil
    }
    
    // MARK: - Default Providers
    
    /// Returns default AI providers when database loading fails
    /// - Returns: Array of default AIModelProvider objects
    private func getDefaultProviders() -> [AIModelProvider] {
        let now = Date()
        
        // OpenAI
        let openAI = AIModelProvider(
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
        let anthropic = AIModelProvider(
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
        let googleAI = AIModelProvider(
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
        let azureOpenAI = AIModelProvider(
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
    
    // MARK: - AI Connections
    
    /// Creates a new AI connection for a user
    /// - Parameters:
    ///   - userId: User ID
    ///   - apiKey: API key for the provider
    ///   - providerName: AI provider name
    /// - Returns: True if connection was created successfully
    /// - Throws: Error if database operation fails
    func createConnection(userId: Int, apiKey: String, providerName: String) async throws -> Bool {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw NSError(domain: "AIConnectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
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
    
    /// Gets all AI connections for a user
    /// - Parameter userId: User ID
    /// - Returns: Array of AI connections
    /// - Throws: Error if database operation fails
    func getConnections(for userId: Int) async throws -> [[String: Any]] {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw NSError(domain: "AIConnectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Execute the query
            let query = "SELECT * FROM ai_connections WHERE user_id = \(userId)"
            return try await connection.execute(query: query)
        } catch {
            print("Error getting AI connections: \(error)")
            throw error
        }
    }
    
    /// Deletes an AI connection
    /// - Parameter connectionId: Connection ID
    /// - Returns: True if connection was deleted successfully
    /// - Throws: Error if database operation fails
    func deleteConnection(_ connectionId: Int) async throws -> Bool {
        do {
            // Get a connection from the pool
            guard let connection = databasePool.getConnection() else {
                throw NSError(domain: "AIConnectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
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
    
    /// Tests an AI connection by making an actual API call with failover
    /// - Parameters:
    ///   - apiKey: API key for the provider
    ///   - providerName: AI provider name
    /// - Returns: True if connection was successful
    /// - Throws: Error if API call fails
    func testConnection(apiKey: String, providerName: String) async throws -> Bool {
        do {
            // Load the provider
            guard let provider = try await loadProviderByName(providerName) else {
                throw NSError(domain: "AIConnectionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Provider not found"])
            }
            
            // Get all base URLs from the provider
            var baseURLs = Array(provider.baseURLs.values)
            
            // Filter to only test chat completion endpoints
            baseURLs = baseURLs.filter { $0.contains("chat/completions") }
            
            if baseURLs.isEmpty {
                throw NSError(domain: "AIConnectionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No chat completion endpoints found for provider"])
            }
            
            print("Testing connection to \(providerName) with \(baseURLs.count) chat completion endpoints")
            
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
                    print("[AIConnectionService] Debug: Provider requires auth: \(provider.requiresAuth)")
                    print("[AIConnectionService] Debug: Auth header: \(provider.authHeader)")
                    print("[AIConnectionService] Debug: API key length: \(apiKey.count) characters")
                    
                    if provider.requiresAuth {
                        // For providers like OpenAI that use Bearer token
                        if provider.authHeader == "Authorization" {
                            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: provider.authHeader)
                            print("[AIConnectionService] Debug: Using Bearer token authentication")
                        } else {
                            // For providers like Anthropic that use direct API key
                            request.setValue(apiKey, forHTTPHeaderField: provider.authHeader)
                            print("[AIConnectionService] Debug: Using direct API key authentication")
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
                    print("[AIConnectionService] Debug: Raw response data:")
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
                           let content = message["content"] as? String {
                            print("Successfully connected to \(providerName) using URL: \(baseURL)")
                            print("Response: \(content)")
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
            throw NSError(domain: "AIConnectionService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to \(providerName) using all configured URLs. Last error: \(lastError)"])
        } catch {
            print("Error testing AI connection: \(error)")
            throw error
        }
    }
}
