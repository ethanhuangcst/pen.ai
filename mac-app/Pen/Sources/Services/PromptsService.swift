import Foundation
import MySQLKit

class PromptsService {
    static let shared = PromptsService()
    
    private init() {}
    
    // MARK: - Core Operations
    
    /// Creates a new prompt in the database
    func createPrompt(userId: Int, promptName: String, promptText: String) async throws -> Prompt {
        let newPrompt = Prompt.createNewPrompt(userId: userId, promptName: promptName, promptText: promptText)
        
        let query = """
        INSERT INTO wingman_db.prompts (id, user_id, prompt_name, prompt_text, created_datetime, system_flag)
        VALUES (?, ?, ?, ?, NOW(), ?)
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
        SET prompt_name = ?, prompt_text = ?, updated_datetime = NOW()
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
    
    /// Gets all prompts for a user
    func getPromptsByUserId(userId: Int) async throws -> [Prompt] {
        let query = "SELECT * FROM wingman_db.prompts WHERE user_id = ? ORDER BY created_datetime DESC"
        
        do {
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "PromptsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            let rows = try await connection.execute(query: query, parameters: [MySQLData(int: userId)])
            return rows.compactMap { Prompt.fromDatabaseRow($0) }
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
