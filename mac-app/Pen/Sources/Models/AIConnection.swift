import Foundation

class AIConnection {
    let id: Int
    let userId: Int
    let apiKey: String
    let apiProvider: String
    
    init(id: Int, userId: Int, apiKey: String, apiProvider: String) {
        self.id = id
        self.userId = userId
        self.apiKey = apiKey
        self.apiProvider = apiProvider
    }
    
    // MARK: - Convenience Methods
    
    /// Creates an AIConnection instance from database row
    static func fromDatabaseRow(_ row: [String: Any]) -> AIConnection? {
        guard let id = row["id"] as? Int,
              let userId = row["user_id"] as? Int,
              let apiKey = row["api_key"] as? String,
              let apiProvider = row["api_provider"] as? String else {
            return nil
        }
        
        return AIConnection(id: id, userId: userId, apiKey: apiKey, apiProvider: apiProvider)
    }
}
