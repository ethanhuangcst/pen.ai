import Foundation

class AIConnection {
    let id: Int
    let userId: Int
    let apiKey: String
    let apiProvider: String
    let createdAt: Date
    let updatedAt: Date?
    
    init(id: Int, userId: Int, apiKey: String, apiProvider: String, createdAt: Date, updatedAt: Date?) {
        self.id = id
        self.userId = userId
        self.apiKey = apiKey
        self.apiProvider = apiProvider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Convenience Methods
    
    /// Creates an AIConnection instance from database row
    static func fromDatabaseRow(_ row: [String: Any]) -> AIConnection? {
        guard let id = row["id"] as? Int,
              let userId = row["user_id"] as? Int,
              let apiKey = row["apiKey"] as? String,
              let apiProvider = row["apiProvider"] as? String else {
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
        
        return AIConnection(id: id, userId: userId, apiKey: apiKey, apiProvider: apiProvider, createdAt: createdAt, updatedAt: updatedAt)
    }
}
