import Foundation

class Prompt {
    let id: String
    let userId: Int
    let promptName: String
    let promptText: String
    let createdDatetime: Date
    let updatedDatetime: Date?
    let systemFlag: String // WINGMAN: created by Wingman app; PEN: created by PEN app
    
    init(id: String, userId: Int, promptName: String, promptText: String, createdDatetime: Date, updatedDatetime: Date?, systemFlag: String = "PEN") {
        self.id = id
        self.userId = userId
        self.promptName = promptName
        self.promptText = promptText
        self.createdDatetime = createdDatetime
        self.updatedDatetime = updatedDatetime
        self.systemFlag = systemFlag
    }
    
    // MARK: - Convenience Methods
    
    /// Creates a Prompt instance from database row
    static func fromDatabaseRow(_ row: [String: Any]) -> Prompt? {
        // Extract id
        let id: String
        if let idInt = row["id"] as? Int {
            id = String(idInt)
        } else if let idStr = row["id"] as? String {
            id = idStr
        } else {
            print("[Prompt] Missing or invalid id: \(row["id"] ?? "nil")")
            return nil
        }
        
        // Handle userId (from user relation)
        let userId: Int
        if let userIdInt = row["user_id"] as? Int {
            userId = userIdInt
        } else if let userIdString = row["user_id"] as? String, let userIdInt = Int(userIdString) {
            userId = userIdInt
        } else {
            // Default to 0 for null users (default prompts)
            userId = 0
        }
        
        guard let promptName = row["prompt_name"] as? String, 
              let promptText = row["prompt_text"] as? String else {
            print("[Prompt] Failed to extract required fields: prompt_name=\(row["prompt_name"] ?? "nil"), prompt_text=\(row["prompt_text"] ?? "nil")")
            return nil
        }
        
        // Parse created_datetime
        var createdDatetime = Date()
        if let createdAtStr = row["created_datetime"] as? String {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withTime]
            if let parsedDate = dateFormatter.date(from: createdAtStr) {
                createdDatetime = parsedDate
            } else {
                print("[Prompt] Failed to parse created_datetime: \(createdAtStr), using current date")
            }
        } else {
            print("[Prompt] created_datetime not found, using current date")
        }
        
        // Get system flag from database
        let systemFlag = row["system_flag"] as? String ?? "PEN"
        
        return Prompt(id: id, userId: userId, promptName: promptName, promptText: promptText, createdDatetime: createdDatetime, updatedDatetime: nil, systemFlag: systemFlag)
    }
    
    /// Creates a new Prompt instance with default PEN system flag
    static func createNewPrompt(userId: Int, promptName: String, promptText: String) -> Prompt {
        return Prompt(
            id: "prompt-\(Int(Date.timeIntervalSinceReferenceDate * 1000))", // Generate unique ID
            userId: userId,
            promptName: promptName,
            promptText: promptText,
            createdDatetime: Date(),
            updatedDatetime: nil,
            systemFlag: "PEN"
        )
    }
    
    /// Returns the prompt text formatted as markdown
    func getMarkdownText() -> String {
        return promptText
    }
}
