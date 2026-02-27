import Foundation

class AIModelProvider {
    let id: Int
    let name: String
    let baseURLs: [String]
    let defaultModel: String
    let requiresAuth: Bool
    let authHeader: String
    
    init(id: Int, name: String, baseURLs: [String], defaultModel: String, requiresAuth: Bool, authHeader: String) {
        self.id = id
        self.name = name
        self.baseURLs = baseURLs
        self.defaultModel = defaultModel
        self.requiresAuth = requiresAuth
        self.authHeader = authHeader
    }
    
    // MARK: - Convenience Methods
    
    /// Creates an AIModelProvider instance from database row
    static func fromDatabaseRow(_ row: [String: Any]) -> AIModelProvider? {
        guard let id = row["id"] as? Int,
              let name = row["name"] as? String,
              let baseURLsJSON = row["base_urls"] as? String,
              let defaultModel = row["default_model"] as? String,
              let requiresAuth = row["requires_auth"] as? Int,
              let authHeader = row["auth_header"] as? String else {
            return nil
        }
        
        // Parse base_urls JSON
        var baseURLs: [String] = []
        if let data = baseURLsJSON.data(using: .utf8),
           let urls = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
            baseURLs = urls
        }
        
        return AIModelProvider(
            id: id,
            name: name,
            baseURLs: baseURLs,
            defaultModel: defaultModel,
            requiresAuth: requiresAuth == 1,
            authHeader: authHeader
        )
    }
}
