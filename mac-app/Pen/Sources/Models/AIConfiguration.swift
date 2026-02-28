import Foundation

class AIConfiguration {
    let id: Int
    let userId: Int
    var apiKey: String
    var apiProvider: String
    let createdAt: Date
    var updatedAt: Date?
    
    init(id: Int, userId: Int, apiKey: String, apiProvider: String, createdAt: Date, updatedAt: Date?) {
        self.id = id
        self.userId = userId
        self.apiKey = apiKey
        self.apiProvider = apiProvider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Convenience Methods
    
    /// Creates an AIConfiguration instance from database row
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
