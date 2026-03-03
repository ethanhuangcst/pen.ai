import Foundation
import MySQLKit

class TestContentHistoryLimit {
    static func run() async {
        print("Testing content history limit...")
        
        // Get database connection
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            print("Failed to get database connection")
            return
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            // Get user ID for me@ethanhuang.com
            let userQuery = "SELECT id, name, email, pen_content_history FROM users WHERE email = ?"
            let userParams: [MySQLData] = [MySQLData(string: "me@ethanhuang.com")]
            let userResults = try await connection.execute(query: userQuery, parameters: userParams)
            
            if let userRow = userResults.first {
                let userId = userRow["id"] as? Int ?? 0
                let userName = userRow["name"] as? String ?? ""
                let userEmail = userRow["email"] as? String ?? ""
                let penContentHistory = userRow["pen_content_history"] as? Int ?? 0
                
                print("User: \(userName) (\(userEmail))")
                print("User ID: \(userId)")
                print("pen_content_history: \(penContentHistory)")
                
                // Get content history count
                let historyCountQuery = "SELECT COUNT(*) as count FROM content_history WHERE user_id = ?"
                let historyCountParams: [MySQLData] = [MySQLData(int: userId)]
                let historyCountResults = try await connection.execute(query: historyCountQuery, parameters: historyCountParams)
                
                if let historyCountRow = historyCountResults.first {
                    let count = historyCountRow["count"] as? Int ?? 0
                    print("Content history count: \(count)")
                }
                
                // Get the system config content history limits
                let configQuery = "SELECT content_history_count_low, content_history_count_medium, content_history_count_high FROM system_config LIMIT 1"
                let configResults = try await connection.execute(query: configQuery, parameters: [])
                
                if let configRow = configResults.first {
                    let low = configRow["content_history_count_low"] as? Int ?? 0
                    let medium = configRow["content_history_count_medium"] as? Int ?? 0
                    let high = configRow["content_history_count_high"] as? Int ?? 0
                    
                    print("System config limits:")
                    print("LOW: \(low)")
                    print("MEDIUM: \(medium)")
                    print("HIGH: \(high)")
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
        print("Test completed")
    }
}

// Run the test
Task {
    await TestContentHistoryLimit.run()
}
