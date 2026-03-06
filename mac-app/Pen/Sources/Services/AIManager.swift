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
        case unauthorized(String)
        case forbidden(String)
        case notFound(String)
        case serverError(Int, String)
        case clientError(Int, String)
        case invalidJSONResponse(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidAPIKey:
                return "Invalid API key"
            case .rateLimited:
                return "Rate limited - too many requests"
            case .networkError:
                return "Network error - unable to connect"
            case .invalidResponse:
                return "Invalid response from server"
            case .providerError(let message):
                return "Provider error: \(message)"
            case .configurationError(let message):
                return "Configuration error: \(message)"
            case .unauthorized(let message):
                return "Unauthorized: \(message)"
            case .forbidden(let message):
                return "Forbidden: \(message)"
            case .notFound(let message):
                return "Not found: \(message)"
            case .serverError(let code, let message):
                return "Server error (\(code)): \(message)"
            case .clientError(let code, let message):
                return "Client error (\(code)): \(message)"
            case .invalidJSONResponse(let message):
                return "Invalid JSON response: \(message)"
            }
        }
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
        
        func maskSecret(_ value: String) -> String {
            if value.count <= 8 {
                return String(repeating: "*", count: value.count)
            }
            return "\(value.prefix(4))...\(value.suffix(4))"
        }
        
        // Get all base URLs from the provider, sorted by key for consistent ordering
        let sortedKeys = provider.baseURLs.keys.sorted()
        var baseURLs = sortedKeys.map { provider.baseURLs[$0]! }
        
        // Filter to only test chat completion endpoints
        baseURLs = baseURLs.filter { $0.contains("chat/completions") }
        
        if baseURLs.isEmpty {
            throw AIError.providerError("No chat completion endpoints found")
        }
        
        // Test each base URL in order
        var totalAttempts = 0
        var lastError: AIError?
        
        for baseURL in baseURLs {
            totalAttempts += 1
            print("[AIManager] Testing connection attempt \(totalAttempts) for \(providerName): \(baseURL)")
            
            do {
                guard let url = URL(string: baseURL) else {
                    let error = AIError.configurationError("Invalid URL: \(baseURL)")
                    print("[AIManager] ❌ \(error.localizedDescription)")
                    lastError = error
                    continue
                }
                
                // Create URLRequest
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30.0 // 30 seconds timeout
                
                // Add authorization header
                if provider.requiresAuth {
                    if provider.authHeader == "Authorization" {
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: provider.authHeader)
                    } else {
                        request.setValue(apiKey, forHTTPHeaderField: provider.authHeader)
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
                
                let requestBodyString = String(data: jsonData, encoding: .utf8) ?? "{}"
                var headerSnapshot = request.allHTTPHeaderFields ?? [:]
                if provider.requiresAuth {
                    if provider.authHeader == "Authorization" {
                        headerSnapshot[provider.authHeader] = "Bearer \(maskSecret(apiKey))"
                    } else {
                        headerSnapshot[provider.authHeader] = maskSecret(apiKey)
                    }
                }
                print("[AIManager] ---- Outbound Request ----")
                print("[AIManager] Provider: \(provider.name)")
                print("[AIManager] Model: \(provider.defaultModel)")
                print("[AIManager] URL: \(baseURL)")
                print("[AIManager] Method: \(request.httpMethod ?? "POST")")
                print("[AIManager] Headers: \(headerSnapshot)")
                print("[AIManager] Body: \(requestBodyString)")
                print("[AIManager] --------------------------")
                
                // Make API call
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check response status code
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = AIError.invalidResponse
                    print("[AIManager] ❌ Failed: Invalid response type - \(baseURL)")
                    lastError = error
                    continue
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                    print("[AIManager] ❌ Failed: HTTP \(statusCode) - \(baseURL)")
                    print("[AIManager] Response: \(responseBody.prefix(200))")
                    let mappedError = mapError(data, response: httpResponse)
                    lastError = mappedError
                    continue
                }
                
                // Parse response
                do {
                    // First, check if response looks like valid JSON
                    let responseString = String(data: data, encoding: .utf8) ?? ""
                    
                    // Check if response starts with '{' or '[' (valid JSON)
                    let trimmedResponse = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmedResponse.hasPrefix("{") || trimmedResponse.hasPrefix("[") else {
                        // Response is not JSON - likely HTML or plain text
                        let preview = trimmedResponse.prefix(100)
                        let errorMessage = "Server returned non-JSON response (likely wrong endpoint). Response starts with: \(preview)"
                        print("[AIManager] ❌ Failed: Non-JSON response - \(baseURL)")
                        print("[AIManager] Response preview: \(preview)")
                        lastError = AIError.invalidJSONResponse(errorMessage)
                        continue
                    }
                    
                    let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let choices = responseData?["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        print("[AIManager] ✅ Successfully connected to \(providerName)")
                        print("[AIManager] URL: \(baseURL)")
                        print("[AIManager] Response: \(content)")
                        return true
                    } else if let errorDict = responseData?["error"] as? [String: Any] {
                        // API returned an error object
                        let errorMsg = errorDict["message"] as? String ?? "Unknown error"
                        let errorType = errorDict["type"] as? String ?? "unknown"
                        print("[AIManager] ❌ API Error: \(errorMsg) (type: \(errorType)) - \(baseURL)")
                        lastError = AIError.providerError("\(errorMsg) (type: \(errorType))")
                        continue
                    } else {
                        let errorMessage = "Invalid API response format - missing expected fields"
                        print("[AIManager] ❌ Failed: \(errorMessage) - \(baseURL)")
                        print("[AIManager] Response keys: \(responseData?.keys.sorted().joined(separator: ", ") ?? "none")")
                        lastError = AIError.invalidResponse
                        continue
                    }
                } catch let jsonError as NSError {
                    // JSON parsing failed
                    let responsePreview = String(data: data, encoding: .utf8)?.prefix(200) ?? "Unable to decode"
                    let errorMessage = "JSON parsing failed: \(jsonError.localizedDescription)"
                    print("[AIManager] ❌ Failed: \(errorMessage) - \(baseURL)")
                    print("[AIManager] Response preview: \(responsePreview)")
                    lastError = AIError.invalidJSONResponse(errorMessage)
                    continue
                }
            } catch {
                let errorMessage = "Network error: \(error.localizedDescription)"
                print("[AIManager] ❌ Failed: \(errorMessage) - \(baseURL)")
                lastError = AIError.networkError
                continue
            }
        }
        
        // All URLs failed
        print("[AIManager] ❌ All \(totalAttempts) attempts failed for \(providerName)")
        print("[AIManager] Last error: \(lastError?.localizedDescription ?? "Unknown error")")
        throw lastError ?? AIError.networkError
    }
    
    // Test Call
    public func AITestCall(
        prompt: String,
        model: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int = 1200
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
            var connection = databasePool.getConnection()
            
            // Wait for pool to be ready if no connection available
            var attempts = 0
            let maxAttempts = 5
            while connection == nil && attempts < maxAttempts {
                print("[AIManager] Waiting for database pool to be ready...")
                try await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
                connection = databasePool.getConnection()
                attempts += 1
            }
            
            guard let connection = connection else {
                throw AIError.configurationError("Failed to get database connection after multiple attempts")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Try direct MySQLConnection access for JSON columns
            if let mysqlConnection = connection as? MySQLConnection, let internalConnection = mysqlConnection.getConnection() {
                let query = "SELECT id, name, CAST(base_urls AS CHAR) as base_urls, default_model, requires_auth, auth_header, created_at, updated_at FROM ai_providers"
                let rows = try await internalConnection.query(query).get()
                
                var providers: [PublicAIModelProvider] = []
                
                for row in rows {
                    var rowData: [String: Any] = [:]
                    
                    if let idData = row.column("id"), let id = idData.string {
                        rowData["id"] = id
                    }
                    if let nameData = row.column("name"), let name = nameData.string {
                        rowData["name"] = name
                    }
                    if let baseURLsData = row.column("base_urls"), let baseURLs = baseURLsData.string {
                        rowData["base_urls"] = baseURLs
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
            var connection = databasePool.getConnection()
            
            // Wait for pool to be ready if no connection available
            var attempts = 0
            let maxAttempts = 5
            while connection == nil && attempts < maxAttempts {
                print("[AIManager] Waiting for database pool to be ready...")
                try await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
                connection = databasePool.getConnection()
                attempts += 1
            }
            
            guard let connection = connection else {
                throw AIError.configurationError("Failed to get database connection after multiple attempts")
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
            var connection = databasePool.getConnection()
            
            // Wait for pool to be ready if no connection available
            var attempts = 0
            let maxAttempts = 5
            while connection == nil && attempts < maxAttempts {
                print("[AIManager] Waiting for database pool to be ready...")
                try await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
                connection = databasePool.getConnection()
                attempts += 1
            }
            
            guard let connection = connection else {
                throw AIError.configurationError("Failed to get database connection after multiple attempts")
            }
            
            defer {
                // Return the connection to the pool
                databasePool.returnConnection(connection)
            }
            
            // Try direct MySQLConnection access for JSON columns
            if let mysqlConnection = connection as? MySQLConnection, let internalConnection = mysqlConnection.getConnection() {
                let query = "SELECT id, name, CAST(base_urls AS CHAR) as base_urls, default_model, requires_auth, auth_header, created_at, updated_at FROM ai_providers WHERE name = '\(name)'"
                let rows = try await internalConnection.query(query).get()
                
                guard !rows.isEmpty else {
                    return nil
                }
                
                for row in rows {
                    var rowData: [String: Any] = [:]
                    
                    if let idData = row.column("id"), let id = idData.string {
                        rowData["id"] = id
                    }
                    if let nameData = row.column("name"), let nameVal = nameData.string {
                        rowData["name"] = nameVal
                    }
                    if let baseURLsData = row.column("base_urls"), let baseURLs = baseURLsData.string {
                        rowData["base_urls"] = baseURLs
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
        requiresAuth: Bool,
        providerName: String = "unknown"
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[AIManager] ❌ Invalid response type")
            throw AIError.invalidResponse
        }
        
        let statusCode = httpResponse.statusCode
        
        print("[AIManager] HTTP Status: \(statusCode)")
        
        let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        
        guard (200...299).contains(statusCode) else {
            let responsePrefix = String(responseBody.prefix(200))
            
            // Check if response is non-JSON (likely HTML error page)
            let trimmedResponse = responseBody.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedResponse.hasPrefix("{") && !trimmedResponse.hasPrefix("[") {
                print("[AIManager] ❌ Non-JSON response received (likely wrong endpoint or server error)")
                print("[AIManager] Response preview: \(trimmedResponse.prefix(100))")
                throw AIError.invalidJSONResponse("Server returned non-JSON response. This usually means the endpoint URL is incorrect. Preview: \(trimmedResponse.prefix(100))")
            }
            
            switch statusCode {
            case 401:
                print("[AIManager] ❌ Unauthorized (401) - API key may be invalid or missing")
                throw AIError.unauthorized("Authentication failed. Please check your API key for \(providerName). Response: \(responsePrefix)")
            case 403:
                print("[AIManager] ❌ Forbidden (403) - Access denied")
                throw AIError.forbidden("Access denied. Your API key may not have permission for this operation. Response: \(responsePrefix)")
            case 404:
                print("[AIManager] ❌ Not Found (404) - Endpoint not found")
                throw AIError.notFound("API endpoint not found. Please check the URL configuration. Response: \(responsePrefix)")
            case 429:
                print("[AIManager] ❌ Rate Limited (429) - Too many requests")
                throw AIError.rateLimited
            case 400...499:
                print("[AIManager] ❌ Client Error (\(statusCode))")
                throw AIError.clientError(statusCode, responsePrefix)
            case 500...599:
                print("[AIManager] ❌ Server Error (\(statusCode))")
                throw AIError.serverError(statusCode, responsePrefix)
            default:
                print("[AIManager] ❌ Unknown Error (\(statusCode))")
                throw AIError.networkError
            }
        }
        
        return data
    }
    
    private func mapError(_ data: Data, response: HTTPURLResponse) -> AIError {
        let statusCode = response.statusCode
        let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        
        print("[AIManager] Mapping error for HTTP \(statusCode)")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let error = json?["error"] as? [String: Any],
               let message = error["message"] as? String {
                let errorType = error["type"] as? String ?? "unknown"
                let errorCode = error["code"] as? String ?? "unknown"
                print("[AIManager] Provider error - Type: \(errorType), Code: \(errorCode), Message: \(message)")
                return AIError.providerError("\(message) (type: \(errorType), code: \(errorCode))")
            }
            
            if let message = json?["message"] as? String {
                print("[AIManager] Provider error - Message: \(message)")
                return AIError.providerError(message)
            }
        } catch {
            print("[AIManager] Failed to parse error response as JSON: \(error)")
        }
        
        let responsePrefix = String(responseBody.prefix(200))
        
        switch statusCode {
        case 401:
            return AIError.unauthorized("Authentication failed. Response: \(responsePrefix)")
        case 403:
            return AIError.forbidden("Access denied. Response: \(responsePrefix)")
        case 404:
            return AIError.notFound("Endpoint not found. Response: \(responsePrefix)")
        case 429:
            return AIError.rateLimited
        case 400...499:
            return AIError.clientError(statusCode, responsePrefix)
        case 500...599:
            return AIError.serverError(statusCode, responsePrefix)
        default:
            print("[AIManager] Returning generic error for HTTP \(statusCode)")
            return AIError.clientError(statusCode, responsePrefix)
        }
    }
}
