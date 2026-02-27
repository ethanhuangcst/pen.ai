import Foundation

class Prompt {
    let id: Int
    let userId: Int
    let promptName: String
    let promptText: String
    let createdAt: Date
    let updatedAt: Date
    let systemFlag: String // WINGMAN: created by Wingman app; PEN: created by PEN app
    
    init(id: Int, userId: Int, promptName: String, promptText: String, createdAt: Date, updatedAt: Date, systemFlag: String) {
        self.id = id
        self.userId = userId
        self.promptName = promptName
        self.promptText = promptText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.systemFlag = systemFlag
    }
    
    // MARK: - Convenience Methods
    
    /// Creates a Prompt instance from database row
    static func fromDatabaseRow(_ row: [String: Any]) -> Prompt? {
        guard let id = row["id"] as? Int,
              let userId = row["user_id"] as? Int,
              let promptName = row["prompt_name"] as? String,
              let promptText = row["prompt_text"] as? String,
              let createdAt = row["created_datetime"] as? Date,
              let updatedAt = row["updated_datetime"] as? Date,
              let systemFlag = row["system_flag"] as? String else {
            return nil
        }
        
        return Prompt(id: id, userId: userId, promptName: promptName, promptText: promptText, createdAt: createdAt, updatedAt: updatedAt, systemFlag: systemFlag)
    }
}
