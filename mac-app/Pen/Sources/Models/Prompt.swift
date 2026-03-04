import Foundation

class Prompt {
    // Constants
    static let DEFAULT_PROMPT_ID = "DEFAULT"
    
    let id: String
    let userId: Int
    let promptName: String
    let promptText: String
    let createdDatetime: Date
    let updatedDatetime: Date?
    let systemFlag: String // WINGMAN: created by Wingman app; PEN: created by PEN app
    let isDefault: Bool
    
    init(id: String, userId: Int, promptName: String, promptText: String, createdDatetime: Date, updatedDatetime: Date?, systemFlag: String = "PEN", isDefault: Bool = false) {
        self.id = id
        self.userId = userId
        self.promptName = promptName
        self.promptText = promptText
        self.createdDatetime = createdDatetime
        self.updatedDatetime = updatedDatetime
        self.systemFlag = systemFlag
        self.isDefault = isDefault
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
        
        // Parse created_at (database column name)
        var createdDatetime = Date()
        if let createdAtStr = row["created_at"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            if let parsedDate = dateFormatter.date(from: createdAtStr) {
                createdDatetime = parsedDate
            } else {
                print("[Prompt] Failed to parse created_at: \(createdAtStr), using current date")
            }
        } else {
            print("[Prompt] created_at not found, using current date")
        }
        
        // Get system flag from database
        let systemFlag = row["system_flag"] as? String ?? "PEN"
        
        // Get is_default from database
        var isDefault: Bool
        if let isDefaultInt = row["is_default"] as? Int {
            isDefault = isDefaultInt == 1
        } else if let isDefaultBool = row["is_default"] as? Bool {
            isDefault = isDefaultBool
        } else {
            isDefault = false
        }
        

        
        return Prompt(id: id, userId: userId, promptName: promptName, promptText: promptText, createdDatetime: createdDatetime, updatedDatetime: nil, systemFlag: systemFlag, isDefault: isDefault)
    }
    
    /// Creates a new Prompt instance with default PEN system flag
    static func createNewPrompt(userId: Int, promptName: String, promptText: String, isDefault: Bool = false) -> Prompt {
        return Prompt(
            id: "prompt-\(Int(Date.timeIntervalSinceReferenceDate * 1000))", // Generate unique ID
            userId: userId,
            promptName: promptName,
            promptText: promptText,
            createdDatetime: Date(),
            updatedDatetime: nil,
            systemFlag: "PEN",
            isDefault: isDefault
        )
    }
    
    /// Returns the prompt text formatted as markdown
    func getMarkdownText() -> String {
        return promptText
    }
    
    /// Loads the default prompt from default_prompt.md file
    static func loadDefaultPrompt() -> Prompt? {
        let defaultPromptPath = "\(FileManager.default.currentDirectoryPath)/default_prompt.md"
        
        guard FileManager.default.fileExists(atPath: defaultPromptPath) else {
            print("[Prompt] default_prompt.md not found at \(defaultPromptPath)")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: defaultPromptPath, encoding: .utf8)
            
            // Parse the content to extract prompt name and text
            var promptName = "Default Prompt"
            var promptText = content
            
            // Simple parsing: first line is the name (after #), rest is the content
            let lines = content.components(separatedBy: "\n")
            if let firstLine = lines.first, firstLine.hasPrefix("# ") {
                promptName = firstLine.replacingOccurrences(of: "# ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                promptText = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            return Prompt(
                id: DEFAULT_PROMPT_ID,
                userId: 0, // 0 for system-wide default
                promptName: promptName,
                promptText: promptText,
                createdDatetime: Date(),
                updatedDatetime: nil,
                systemFlag: "PEN",
                isDefault: true
            )
        } catch {
            print("[Prompt] Failed to load default prompt: \(error)")
            return nil
        }
    }
    
    /// Creates a fallback default prompt when default_prompt.md is missing
    static func createFallbackDefaultPrompt() -> Prompt {
        let fallbackPromptText = "You are Pen, an AI writing assistant designed to help users improve their writing. Your goal is to analyze the provided text and enhance it while maintaining the original meaning and intent."
        
        return Prompt(
            id: DEFAULT_PROMPT_ID,
            userId: 0, // 0 for system-wide default
            promptName: "Default Prompt",
            promptText: fallbackPromptText,
            createdDatetime: Date(),
            updatedDatetime: nil,
            systemFlag: "PEN",
            isDefault: true
        )
    }
}
