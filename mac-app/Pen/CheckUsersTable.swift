import Foundation
import MySQLKit

// Check the structure of the users table
Task {
    print("Checking users table structure...")
    
    // Get database connection
    guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
        print("Failed to get database connection")
        return
    }
    
    defer {
        DatabaseConnectivityPool.shared.returnConnection(connection)
    }
    
    do {
        // Query to describe the users table
        let query = "DESCRIBE users"
        print("Executing query: \(query)")
        let results = try await connection.execute(query: query, parameters: [])
        
        print("\nUsers table structure:")
        print("-" * 60)
        print("Field\t\tType\t\tNull\tKey\tDefault\tExtra")
        print("-" * 60)
        
        for row in results {
            let field = row["Field"] as? String ?? ""
            let type = row["Type"] as? String ?? ""
            let nullable = row["Null"] as? String ?? ""
            let key = row["Key"] as? String ?? ""
            let defaultValue = row["Default"] as? String ?? ""
            let extra = row["Extra"] as? String ?? ""
            
            print("\(field)\t\t\(type)\t\t\(nullable)\t\(key)\t\(defaultValue)\t\(extra)")
        }
        
        print("-" * 60)
        
        // Also check if there are any users
        let countQuery = "SELECT COUNT(*) as count FROM users"
        let countResults = try await connection.execute(query: countQuery, parameters: [])
        
        if let countRow = countResults.first, let count = countRow["count"] as? Int {
            print("\nTotal users in database: \(count)")
        }
        
    } catch {
        print("Error checking users table: \(error)")
    }
}

// Wait for the task to complete
RunLoop.main.run()
