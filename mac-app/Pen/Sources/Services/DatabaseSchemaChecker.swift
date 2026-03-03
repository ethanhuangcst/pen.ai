import Foundation

class DatabaseSchemaChecker {
    static let shared = DatabaseSchemaChecker()
    private init() {}
    
    /// Check the database schema and update the db_structure.md file
    func checkAndUpdateSchema() async {
        print("=== Checking database schema ===")
        
        do {
            // Get all tables in the database
            let tables = try await getTables()
            print("Found tables: \(tables)")
            
            // Get structure for each table
            var schemaContent = "# Database Structure\n\n"
            schemaContent += "## Overview\n"
            schemaContent += "This document describes the database structure for the Pen AI application. The database contains tables for users, AI connections, prompts, chats, chat messages, and AI providers.\n\n"
            schemaContent += "## Tables\n\n"
            
            for table in tables {
                print("\n=== Checking table: \(table) ===")
                let tableStructure = try await getTableStructure(table: table)
                
                schemaContent += "### \(table)\n\n"
                schemaContent += "| Column | Type | Null | Key | Default | Extra |\n"
                schemaContent += "|--------|------|------|-----|---------|-------|\n"
                
                for column in tableStructure {
                    let field = column["Field"] as? String ?? ""
                    let type = column["Type"] as? String ?? ""
                    let nullable = column["Null"] as? String ?? ""
                    let key = column["Key"] as? String ?? ""
                    let defaultValue = column["Default"] as? String ?? ""
                    let extra = column["Extra"] as? String ?? ""
                    
                    schemaContent += "| \(field) | \(type) | \(nullable) | \(key) | \(defaultValue) | \(extra) |\n"
                }
                
                schemaContent += "\n"
            }
            
            // Add relationships section
            schemaContent += "## Relationships\n\n"
            schemaContent += "```\n"
            schemaContent += "┌────────────┐     ┌────────────┐     ┌────────────┐\n"
            schemaContent += "│   users    │────▶│ ai_connections │────▶│ ai_providers │\n"
            schemaContent += "└────────────┘     └────────────┘     └────────────┘\n"
            schemaContent += "      │                   │\n"
            schemaContent += "      │                   │\n"
            schemaContent += "      ▼                   ▼\n"
            schemaContent += "┌────────────┐     ┌────────────┐     ┌───────────────┐\n"
            schemaContent += "│   chats    │────▶│chat_messages│     │content_history│\n"
            schemaContent += "└────────────┘     └────────────┘     └───────────────┘\n"
            schemaContent += "      │                                   ▲\n"
            schemaContent += "      │                                   │\n"
            schemaContent += "      ▼                                   │\n"
            schemaContent += "┌────────────┐                           │\n"
            schemaContent += "│  prompts   │───────────────────────────┘\n"
            schemaContent += "└────────────┘\n"
            schemaContent += "```\n\n"
            
            // Add key points section
            schemaContent += "## Key Points\n\n"
            schemaContent += "1. **User Management**: The `users` table stores all user information, including authentication details and profile data.\n\n"
            schemaContent += "2. **AI Connections**: The `ai_connections` table stores API keys and provider information for each user's AI services.\n\n"
            schemaContent += "3. **Chat System**: The `chats` and `chat_messages` tables handle the chat functionality, allowing users to have multiple conversations with AI providers.\n\n"
            schemaContent += "4. **Prompt Management**: The `prompts` table stores user-created prompts that can be reused in conversations. The `is_default` column indicates whether a prompt is the default prompt for a user.\n\n"
            schemaContent += "5. **AI Provider Configuration**: The `ai_providers` table stores configuration information for different AI service providers.\n\n"
            schemaContent += "6. **Content History**: The `content_history` table stores records of enhanced content, including the original content, enhanced content, prompt used, and AI provider.\n\n"
            schemaContent += "7. **System Configuration**: The `system_config` table stores global system settings, including default prompt information and content history count options (LOW, MEDIUM, HIGH) that can be centrally managed.\n\n"
            schemaContent += "8. **Data Consistency**: Foreign key relationships ensure data integrity between related tables.\n\n"
            schemaContent += "9. **Timestamps**: Most tables include `created_at` and `updated_at` timestamps for tracking when records were created or modified.\n\n"
            schemaContent += "10. **System Flag**: The `system_flag` column in several tables indicates whether records were created by the Wingman app or the Pen app.\n\n"
            
            // Add security considerations section
            schemaContent += "## Security Considerations\n\n"
            schemaContent += "- Passwords are stored as plain text in the `password` column. In a production environment, these should be hashed using a secure hashing algorithm.\n"
            schemaContent += "- API keys in the `ai_connections` table are stored as plain text. These should be encrypted or stored in a secure vault in a production environment.\n"
            schemaContent += "- Email addresses are unique to prevent duplicate user accounts.\n"
            
            // Write the updated schema to the file
            let filePath = "/Users/ethanhuang/code/pen.ai/pen/Docs/tech-design/db_structure.md"
            try schemaContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            print("\n=== Database schema updated in db_structure.md ===")
            
        } catch {
            print("Error checking database schema: \(error)")
        }
    }
    
    /// Get all tables in the database
    private func getTables() async throws -> [String] {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            throw NSError(domain: "DatabaseSchemaChecker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        let query = "SHOW TABLES"
        let results = try await connection.execute(query: query)
        
        var tables: [String] = []
        for row in results {
            // Extract table name from the result
            for (key, value) in row {
                if let tableName = value as? String {
                    tables.append(tableName)
                    break
                }
            }
        }
        
        return tables
    }
    
    /// Get the structure of a specific table
    private func getTableStructure(table: String) async throws -> [[String: Any]] {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            throw NSError(domain: "DatabaseSchemaChecker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        let query = "DESCRIBE \(table)"
        let results = try await connection.execute(query: query)
        
        return results
    }
}
