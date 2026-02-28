import Foundation

// Mock database connectivity pool for testing
class MockDatabaseConnectivityPool {
    func getConnection() -> MockConnection? {
        return MockConnection()
    }
    
    func returnConnection(_ connection: Any) {
        // Do nothing
    }
}

// Mock connection for testing
class MockConnection {
    func execute(query: String) async throws -> [[String: Any]] {
        // Return mock data similar to what's in the database
        return [
            [
                "id": 1,
                "name": "gpt-4o-mini",
                "base_urls": "[\"https://openaiss.com/v1\", \"https://openaiss.com\", \"https://api.openai.com/v1\"]",
                "default_model": "gpt-4o-mini",
                "requires_auth": 1,
                "auth_header": "Authorization",
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z"
            ]
        ]
    }
}

// Copy of the AIModelProvider class for testing
class AIModelProvider {
    let id: Int
    let name: String
    let baseURLs: [String: String] // Maps to base_urls JSON object
    let defaultModel: String
    let requiresAuth: Bool
    let authHeader: String
    let createdAt: Date
    let updatedAt: Date?
    
    init(id: Int, name: String, baseURLs: [String: String], defaultModel: String, requiresAuth: Bool, authHeader: String, createdAt: Date, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.baseURLs = baseURLs
        self.defaultModel = defaultModel
        self.requiresAuth = requiresAuth
        self.authHeader = authHeader
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Convenience Methods
    
    /// Creates an AIModelProvider instance from database row
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
                    // For each base URL, construct full endpoints
                    for (index, baseURL) in urlArray.enumerated() {
                        // Remove any trailing slashes
                        let cleanBaseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                        
                        // Construct full endpoints based on provider type
                        switch index {
                        case 0: // completion endpoint
                            baseURLs["completion"] = "\(cleanBaseURL)/chat/completions"
                        case 1: // embedding endpoint
                            baseURLs["embedding"] = "\(cleanBaseURL)/embeddings"
                        case 2: // image endpoint
                            baseURLs["image"] = "\(cleanBaseURL)/images/generations"
                        default:
                            break
                        }
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
    
    // MARK: - Validation
    
    /// Validates the provider data
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.missingName
        }
        
        guard !baseURLs.isEmpty else {
            throw ValidationError.missingBaseURLs
        }
        
        guard !defaultModel.isEmpty else {
            throw ValidationError.missingDefaultModel
        }
    }
}

enum ValidationError: Error {
    case missingName
    case missingBaseURLs
    case missingDefaultModel
}

// Test the AIModelProvider parsing
func testAIModelProvider() async {
    // Test with gpt-4o-mini
    let gpt4oMiniRow: [String: Any] = [
        "id": 1,
        "name": "gpt-4o-mini",
        "base_urls": "[\"https://openaiss.com/v1\", \"https://openaiss.com\", \"https://api.openai.com/v1\"]",
        "default_model": "gpt-4o-mini",
        "requires_auth": 1,
        "auth_header": "Authorization",
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
    ]
    
    // Test with deepseek3.2
    let deepseekRow: [String: Any] = [
        "id": 2,
        "name": "deepseek3.2",
        "base_urls": "[\"https://api.deepseek.com/v1\"]",
        "default_model": "deepseek3.2",
        "requires_auth": 1,
        "auth_header": "Authorization",
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
    ]
    
    // Test with qwen-plus
    let qwenRow: [String: Any] = [
        "id": 3,
        "name": "qwen-plus",
        "base_urls": "[\"https://api.baichuan-ai.com/v1\"]",
        "default_model": "qwen-plus",
        "requires_auth": 1,
        "auth_header": "Authorization",
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
    ]
    
    // Test all providers
    let testRows = [gpt4oMiniRow, deepseekRow, qwenRow]
    
    for row in testRows {
        if let provider = AIModelProvider.fromDatabaseRow(row) {
            print("Provider: \(provider.name)")
            print("Default Model: \(provider.defaultModel)")
            print("Base URLs:")
            for (key, value) in provider.baseURLs {
                print("  \(key): \(value)")
            }
            print("")
        } else {
            print("Failed to create provider from mock data for: \(row["name"] as? String ?? "Unknown")")
        }
    }
    
    print("Test completed successfully!")
}

// Run the test
Task {
    await testAIModelProvider()
}

// Keep the program running until the task completes
RunLoop.main.run()
