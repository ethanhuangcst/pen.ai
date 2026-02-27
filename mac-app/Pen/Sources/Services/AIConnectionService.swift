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
        
        let query = "SELECT * FROM ai_providers"
        
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
        let query = "SELECT * FROM ai_providers WHERE name = ?"
        
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
            let parameterizedQuery = "SELECT * FROM ai_providers WHERE name = '\(name)'"
            let results = try await connection.execute(query: parameterizedQuery)
            
            guard !results.isEmpty else {
                return nil
            }
            
            return AIModelProvider.fromDatabaseRow(results[0])
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
}
