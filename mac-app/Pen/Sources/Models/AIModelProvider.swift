import Foundation

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
           let data = baseURLsJSON.data(using: .utf8),
           let urls = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
            baseURLs = urls
        } else {
            // Set default base URLs based on provider name
            baseURLs["completion"] = getDefaultBaseURL(for: name)
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
    
    /// Gets default base URL for a provider
    private static func getDefaultBaseURL(for providerName: String) -> String {
        switch providerName.lowercased() {
        case "deepseek3.2":
            return "https://api.deepseek.com/v1/chat/completions"
        case "gpt-4o-mini":
            return "https://api.openai.com/v1/chat/completions"
        case "qwen-plus":
            return "https://api.baichuan-ai.com/v1/chat/completions"
        default:
            return "https://api.openai.com/v1/chat/completions"
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
