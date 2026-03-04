import Foundation
import MySQLKit

class PromptsService {
    
    init() {}
    
    // MARK: - Core Operations
    
    /// Creates a new prompt in the database
    func createPrompt(userId: Int, promptName: String, promptText: String, id: String? = nil, isDefault: Bool = false) async throws -> Prompt {
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
                systemFlag: "PEN",
                isDefault: isDefault
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
                systemFlag: "PEN",
                isDefault: true
            )
        } else {
            // Regular prompt with generated ID
            newPrompt = Prompt.createNewPrompt(userId: userId, promptName: promptName, promptText: promptText, isDefault: isDefault)
        }
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            if isDefault {
                // Query the current default prompt for the user
                let currentDefaultQuery = "SELECT id FROM wingman_db.prompts WHERE user_id = ? AND is_default = 1"
                let currentDefaultParams: [MySQLData] = [MySQLData(int: userId)]
                let currentDefaultRows = try await connection.execute(query: currentDefaultQuery, parameters: currentDefaultParams)
                
                // Update the current default prompt to not default if it exists
                if let currentDefaultRow = currentDefaultRows.first, let currentDefaultId = currentDefaultRow["id"] as? String {
                    let unsetDefaultQuery = "UPDATE wingman_db.prompts SET is_default = 0 WHERE id = ?"
                    let unsetParams: [MySQLData] = [MySQLData(string: currentDefaultId)]
                    _ = try await connection.execute(query: unsetDefaultQuery, parameters: unsetParams)
                }
                
                // Insert the new prompt as default
                let insertQuery = """
                INSERT INTO wingman_db.prompts (id, user_id, prompt_name, prompt_text, system_flag, is_default)
                VALUES (?, ?, ?, ?, ?, ?)
                """
                
                let insertParams: [MySQLData] = [
                    MySQLData(string: newPrompt.id),
                    MySQLData(int: newPrompt.userId),
                    MySQLData(string: newPrompt.promptName),
                    MySQLData(string: newPrompt.promptText),
                    MySQLData(string: newPrompt.systemFlag),
                    MySQLData(int: 1)
                ]
                
                _ = try await connection.execute(query: insertQuery, parameters: insertParams)
            } else {
                // Insert without transaction for non-default prompts
                let insertQuery = """
                INSERT INTO wingman_db.prompts (id, user_id, prompt_name, prompt_text, system_flag, is_default)
                VALUES (?, ?, ?, ?, ?, ?)
                """
                
                let isDefaultValue = newPrompt.isDefault ? 1 : 0
                
                let insertParams: [MySQLData] = [
                    MySQLData(string: newPrompt.id),
                    MySQLData(int: newPrompt.userId),
                    MySQLData(string: newPrompt.promptName),
                    MySQLData(string: newPrompt.promptText),
                    MySQLData(string: newPrompt.systemFlag),
                    MySQLData(int: isDefaultValue)
                ]
                
                _ = try await connection.execute(query: insertQuery, parameters: insertParams)
            }
            
            return newPrompt
        } catch {
            print("[PromptsService] Failed to create prompt: \(error)")
            throw error
        }
    }
    
    /// Updates an existing prompt in the database
    func updatePrompt(id: String, promptName: String, promptText: String, isDefault: Bool = false) async throws -> Prompt? {
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            // Get the current prompt to get user ID
            guard let currentPrompt = try await getPromptById(id: id) else {
                throw NSError(domain: "PromptsService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Prompt not found"])
            }
            
            print("[PromptsService] Updating prompt: \(id), isDefault: \(isDefault), userId: \(currentPrompt.userId)")
            
            if isDefault {
                // Query the current default prompt for the user
                let currentDefaultQuery = "SELECT id FROM wingman_db.prompts WHERE user_id = ? AND is_default = 1 AND id != ?"
                let currentDefaultParams: [MySQLData] = [
                    MySQLData(int: currentPrompt.userId),
                    MySQLData(string: id)
                ]
                let currentDefaultRows = try await connection.execute(query: currentDefaultQuery, parameters: currentDefaultParams)
                
                // Update the current default prompt to not default if it exists
                if let currentDefaultRow = currentDefaultRows.first, let currentDefaultId = currentDefaultRow["id"] as? String {
                    let unsetDefaultQuery = "UPDATE wingman_db.prompts SET is_default = 0 WHERE id = ?"
                    let unsetParams: [MySQLData] = [MySQLData(string: currentDefaultId)]
                    _ = try await connection.execute(query: unsetDefaultQuery, parameters: unsetParams)
                }
                
                // Update the current prompt to be default
                let updateQuery = """
                UPDATE wingman_db.prompts
                SET prompt_name = ?, prompt_text = ?, is_default = ?
                WHERE id = ?
                """
                
                let updateParams: [MySQLData] = [
                    MySQLData(string: promptName),
                    MySQLData(string: promptText),
                    MySQLData(int: 1),
                    MySQLData(string: id)
                ]
                
                _ = try await connection.execute(query: updateQuery, parameters: updateParams)
            } else {
                // Update without transaction for non-default prompts
                let updateQuery = """
                UPDATE wingman_db.prompts
                SET prompt_name = ?, prompt_text = ?, is_default = ?
                WHERE id = ?
                """
                
                let updateParams: [MySQLData] = [
                    MySQLData(string: promptName),
                    MySQLData(string: promptText),
                    MySQLData(int: 0),
                    MySQLData(string: id)
                ]
                
                _ = try await connection.execute(query: updateQuery, parameters: updateParams)
            }
            
            let updatedPrompt = try await getPromptById(id: id)
            print("[PromptsService] Updated prompt: \(updatedPrompt?.id), isDefault: \(updatedPrompt?.isDefault)")
            return updatedPrompt
        } catch {
            print("[PromptsService] Failed to update prompt: \(error)")
            throw error
        }
    }
    
    func deletePrompt(id: String) async throws -> Bool {
        if let prompt = try await getPromptById(id: id), prompt.isDefault {
            throw NSError(domain: "PromptsService", code: 2, userInfo: [NSLocalizedDescriptionKey: LocalizationService.shared.localizedString(for: "default_prompt_cannot_be_deleted")])
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
            
            let hasDefaultPrompt = prompts.contains { $0.isDefault }
            
            if !hasDefaultPrompt {
                // Create default prompt using the standalone method
                do {
                    let userDefaultPrompt = try await createDefaultPrompt(userId: userId)
                    
                    // Add to the list
                    prompts.insert(userDefaultPrompt, at: 0)
                } catch {
                    // Handle duplicate entry error gracefully
                    print("[PromptsService] Failed to create default prompt (may already exist): \(error)")
                    // Continue with existing prompts
                }
            }
            
            // Sort prompts: Default Prompt first, then others by creation date descending
            prompts.sort { (p1, p2) in
                if p1.isDefault { return true }
                if p2.isDefault { return false }
                return p1.createdDatetime > p2.createdDatetime
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
        // Get default prompt from SystemConfigService
        let (defaultPromptName, defaultPromptText) = SystemConfigService.shared.getDefaultPrompt()
        
        // Use fallback values if no default prompt is available
        let promptName = defaultPromptName ?? "Default Prompt"
        let promptText = defaultPromptText ?? "You are Pen, an AI writing assistant designed to help users improve their writing. Your goal is to analyze the provided text and enhance it while maintaining the original meaning and intent."
        
        let uniqueDefaultId = "default-\(userId)"
        
        // Create a copy with the user's ID
        let userDefaultPrompt = Prompt(
            id: uniqueDefaultId,
            userId: userId,
            promptName: promptName,
            promptText: promptText,
            createdDatetime: Date(),
            updatedDatetime: nil,
            systemFlag: "PEN",
            isDefault: true
        )
        
        // Add to database
        _ = try await createPrompt(
            userId: userId,
            promptName: userDefaultPrompt.promptName,
            promptText: userDefaultPrompt.promptText,
            id: userDefaultPrompt.id,
            isDefault: userDefaultPrompt.isDefault
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
