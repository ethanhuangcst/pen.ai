import Foundation
import MySQLKit

class PromptsService {
    
    init() {}
    
    // MARK: - Core Operations
    
    /// Creates a new prompt in the database
    func createPrompt(userId: Int, promptName: String, promptText: String, id: String? = nil) async throws -> Prompt {
        // Create prompt with specified ID or generate a new one
        let newPrompt: Prompt
        if let id = id {
            // Use the provided ID (e.g., for default prompt)
            newPrompt = Prompt(
                id: id,
                userId: userId,
                promptName: promptName,
                promptText: promptText,
                createdDatetime: Date(),
                updatedDatetime: nil,
                systemFlag: "PEN"
            )
        } else if promptName == "Default Prompt" {
            // This is likely the default prompt
            newPrompt = Prompt(
                id: Prompt.DEFAULT_PROMPT_ID,
                userId: userId,
                promptName: promptName,
                promptText: promptText,
                createdDatetime: Date(),
                updatedDatetime: nil,
                systemFlag: "PEN"
            )
        } else {
            // Regular prompt with generated ID
            newPrompt = Prompt.createNewPrompt(userId: userId, promptName: promptName, promptText: promptText)
        }
        
        let query = """
        INSERT INTO wingman_db.prompts (id, user_id, prompt_name, prompt_text, system_flag)
        VALUES (?, ?, ?, ?, ?)
        """
        
        let params: [MySQLData] = [
            MySQLData(string: newPrompt.id),
            MySQLData(int: newPrompt.userId),
            MySQLData(string: newPrompt.promptName),
            MySQLData(string: newPrompt.promptText),
            MySQLData(string: newPrompt.systemFlag)
        ]
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            _ = try await connection.execute(query: query, parameters: params)
            return newPrompt
        } catch {
            print("[PromptsService] Failed to create prompt: \(error)")
            throw error
        }
    }
    
    /// Updates an existing prompt in the database
    func updatePrompt(id: String, promptName: String, promptText: String) async throws -> Prompt? {
        let query = """
        UPDATE wingman_db.prompts
        SET prompt_name = ?, prompt_text = ?
        WHERE id = ?
        """
        
        let params: [MySQLData] = [
            MySQLData(string: promptName),
            MySQLData(string: promptText),
            MySQLData(string: id)
        ]
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            _ = try await connection.execute(query: query, parameters: params)
            return try await getPromptById(id: id)
        } catch {
            print("[PromptsService] Failed to update prompt: \(error)")
            throw error
        }
    }
    
    /// Deletes a prompt from the database
    func deletePrompt(id: String) async throws -> Bool {
        // Prevent deletion of default prompt
        if id == Prompt.DEFAULT_PROMPT_ID {
            throw NSError(domain: "PromptsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Default prompt cannot be deleted"])
        }
        
        let query = "DELETE FROM wingman_db.prompts WHERE id = ?"
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            _ = try await connection.execute(query: query, parameters: [MySQLData(string: id)])
            // For DELETE queries, we can assume success if no error
            return true
        } catch {
            print("[PromptsService] Failed to delete prompt: \(error)")
            throw error
        }
    }
    
    /// Gets a prompt by its ID
    func getPromptById(id: String) async throws -> Prompt? {
        let query = "SELECT * FROM wingman_db.prompts WHERE id = ?"
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            let rows = try await connection.execute(query: query, parameters: [MySQLData(string: id)])
            
            if let row = rows.first, let prompt = Prompt.fromDatabaseRow(row) {
                return prompt
            } else {
                return nil
            }
        } catch {
            print("[PromptsService] Failed to get prompt by id: \(error)")
            throw error
        }
    }
    
    /// Gets all prompts for a user, including the default prompt if it doesn't exist
    func getPromptsByUserId(userId: Int) async throws -> [Prompt] {
        let query = "SELECT * FROM wingman_db.prompts WHERE user_id = ? ORDER BY created_datetime ASC"
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            let rows = try await connection.execute(query: query, parameters: [MySQLData(int: userId)])
            var prompts = rows.compactMap { Prompt.fromDatabaseRow($0) }
            
            // Debug: Print all prompt IDs
            print("[PromptsService] Found \(prompts.count) prompts for user \(userId)")
            for (index, prompt) in prompts.enumerated() {
                print("[PromptsService] Prompt \(index): ID=\(prompt.id), Name=\(prompt.promptName)")
            }
            
            // Check if default prompt exists for this user
            // Check for both "DEFAULT" (string) and "0" (integer conversion) as the default prompt ID
            let hasDefaultPrompt = prompts.contains { $0.id == Prompt.DEFAULT_PROMPT_ID || $0.id == "0" || $0.promptName == "Default Prompt" }
            print("[PromptsService] hasDefaultPrompt: \(hasDefaultPrompt)")
            print("[PromptsService] Prompt.DEFAULT_PROMPT_ID: \(Prompt.DEFAULT_PROMPT_ID)")
            print("[PromptsService] Checking prompts for default: \(prompts.map { $0.promptName }.joined(by: ", "))")
            
            if !hasDefaultPrompt {
                // Create default prompt using the standalone method
                let userDefaultPrompt = try await createDefaultPrompt(userId: userId)
                
                // Add to the list
                prompts.insert(userDefaultPrompt, at: 0)
            }
            
            // Sort prompts: Default Prompt first, then others by creation date
            prompts.sort { (p1, p2) in
                if p1.id == Prompt.DEFAULT_PROMPT_ID { return true }
                if p2.id == Prompt.DEFAULT_PROMPT_ID { return false }
                return p1.createdDatetime < p2.createdDatetime
            }
            
            return prompts
        } catch {
            print("[PromptsService] Failed to get prompts by user id: \(error)")
            throw error
        }
    }
    
    /// Gets the prompt text in markdown format
    func getPromptMarkdownText(id: String) async throws -> String? {
        do {
            if let prompt = try await getPromptById(id: id) {
                return prompt.getMarkdownText()
            } else {
                return nil
            }
        } catch {
            print("[PromptsService] Failed to get prompt markdown text: \(error)")
            throw error
        }
    }
    
    /// Creates a default prompt for a user
    func createDefaultPrompt(userId: Int) async throws -> Prompt {
        // Load default prompt from file or create fallback
        let defaultPrompt = Prompt.loadDefaultPrompt() ?? Prompt.createFallbackDefaultPrompt()
        
        // Create a copy with the user's ID
        let userDefaultPrompt = Prompt(
            id: Prompt.DEFAULT_PROMPT_ID,
            userId: userId,
            promptName: defaultPrompt.promptName,
            promptText: defaultPrompt.promptText,
            createdDatetime: Date(),
            updatedDatetime: nil,
            systemFlag: "PEN"
        )
        
        // Add to database
        _ = try await createPrompt(
            userId: userId,
            promptName: userDefaultPrompt.promptName,
            promptText: userDefaultPrompt.promptText,
            id: userDefaultPrompt.id
        )
        
        return userDefaultPrompt
    }
    
    // MARK: - Helper Methods
    
    /// Checks if a prompt with the given name already exists for the user
    func promptNameExists(userId: Int, promptName: String, excludingId: String? = nil) async throws -> Bool {
        var query = "SELECT COUNT(*) as count FROM wingman_db.prompts WHERE user_id = ? AND prompt_name = ?"
        var params: [MySQLData] = [MySQLData(int: userId), MySQLData(string: promptName)]
        
        if let excludingId = excludingId {
            query += " AND id != ?"
            params.append(MySQLData(string: excludingId))
        }
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            let rows = try await connection.execute(query: query, parameters: params)
            
            if let row = rows.first, let count = row["count"] as? Int {
                return count > 0
            } else {
                return false
            }
        } catch {
            print("[PromptsService] Failed to check if prompt name exists: \(error)")
            throw error
        }
    }
}
