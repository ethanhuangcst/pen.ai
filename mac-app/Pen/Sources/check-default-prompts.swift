import Foundation
import MySQLKit

// Database configuration
let config = MySQLConfiguration(
    host: "101.132.156.250",
    port: 33320,
    username: "wingmandev",
    password: "Wing123_Man",
    database: "wingman_db"
)

// Default prompt text
let defaultPromptText = "You are Pen, an AI writing assistant designed to help users improve their writing. Your goal is to analyze the provided text and enhance it while maintaining the original meaning and intent."
let defaultPromptName = "Default Prompt"
let defaultPromptId = "DEFAULT"

func createDefaultPrompt(for userId: Int, using connection: MySQLConnection) async throws {
    print("Creating default prompt for user \(userId)...")
    
    let query = """
    INSERT INTO prompts (id, user_id, prompt_name, prompt_text, system_flag)
    VALUES (?, ?, ?, ?, ?)
    """
    
    let params: [MySQLData] = [
        MySQLData(string: defaultPromptId),
        MySQLData(int: userId),
        MySQLData(string: defaultPromptName),
        MySQLData(string: defaultPromptText),
        MySQLData(string: "PEN")
    ]
    
    _ = try await connection.execute(query: query, parameters: params)
    print("Default prompt created for user \(userId)")
}

func checkUsersForDefaultPrompt() async {
    do {
        let connection = try await MySQLConnection.connect(configuration: config)
        defer { connection.close() }
        
        // Get all users
        let usersQuery = "SELECT id, email FROM users"
        let usersRows = try await connection.execute(query: usersQuery)
        
        var usersWithMissingDefaultPrompt: [Int] = []
        
        // Check each user
        for userRow in usersRows {
            guard let userId = userRow["id"] as? Int, 
                  let email = userRow["email"] as? String else {
                continue
            }
            
            // Check if user has a default prompt
            let promptQuery = "SELECT id, prompt_name FROM prompts WHERE user_id = ? AND (id = ? OR prompt_name = ?)"
            let promptParams: [MySQLData] = [
                MySQLData(int: userId),
                MySQLData(string: defaultPromptId),
                MySQLData(string: defaultPromptName)
            ]
            
            let promptRows = try await connection.execute(query: promptQuery, parameters: promptParams)
            
            if promptRows.isEmpty {
                print("User \(email) (ID: \(userId)) is missing default prompt")
                usersWithMissingDefaultPrompt.append(userId)
            } else {
                print("User \(email) (ID: \(userId)) has default prompt")
            }
        }
        
        // Create default prompts for users who don't have them
        if !usersWithMissingDefaultPrompt.isEmpty {
            print("\nCreating default prompts for \(usersWithMissingDefaultPrompt.count) users...")
            for userId in usersWithMissingDefaultPrompt {
                try await createDefaultPrompt(for: userId, using: connection)
            }
            print("\nDefault prompts created successfully")
        } else {
            print("\nAll users already have default prompts")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the check
Task {
    await checkUsersForDefaultPrompt()
    print("\nCheck completed")
}

// Wait for the task to complete
RunLoop.main.run()
