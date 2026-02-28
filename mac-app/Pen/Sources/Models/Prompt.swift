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
        guard let id = row["id"] as? String else {
            print("[Prompt] Missing or invalid id: \(row["id"] ?? "nil")")
            return nil
        }
        
        // Handle userId as string or int
        let userId: Int
        if let userIdInt = row["user_id"] as? Int {
            userId = userIdInt
        } else if let userIdString = row["user_id"] as? String, let userIdInt = Int(userIdString) {
            userId = userIdInt
        } else {
            print("[Prompt] Missing or invalid user_id: \(row["user_id"] ?? "nil")")
            return nil
        }
        
        guard let promptName = row["prompt_name"] as? String, 
              let promptText = row["prompt_text"] as? String else {
            print("[Prompt] Failed to extract required fields")
            return nil
        }
        
        // Parse created_datetime
        var createdDatetime = Date()
        if let createdDatetimeStr = row["created_datetime"] as? String {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withTime]
            if let parsedDate = dateFormatter.date(from: createdDatetimeStr) {
                createdDatetime = parsedDate
            } else {
                print("[Prompt] Failed to parse created_datetime: \(createdDatetimeStr), using current date")
            }
        } else {
            print("[Prompt] created_datetime not found, using current date")
        }
        
        // Parse updated_datetime (optional)
        var updatedDatetime: Date? = nil
        if let updatedDatetimeStr = row["updated_datetime"] as? String {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withTime]
            if let parsedDate = dateFormatter.date(from: updatedDatetimeStr) {
                updatedDatetime = parsedDate
            } else {
                print("[Prompt] Failed to parse updated_datetime: \(updatedDatetimeStr)")
            }
        }
        
        let systemFlag = row["system_flag"] as? String ?? "PEN"
        
        return Prompt(id: id, userId: userId, promptName: promptName, promptText: promptText, createdDatetime: createdDatetime, updatedDatetime: updatedDatetime, systemFlag: systemFlag)
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
