import Foundation
import MySQLKit

// Database configuration
let config = MySQLConfiguration(
    hostname: "101.132.156.250",
    port: 33320,
    username: "wingmandev",
    password: "WingmanDev123!",
    database: "wingman_db"
)

print("Connecting to database...")

task {
    do {
        // Connect to the database
        let connection = try await MySQLConnection.connect(configuration: config)
        defer { try? connection.close() }
        
        print("Connected to database successfully!")
        
        // Check if user_preferences table exists
        let checkTableQuery = "SHOW TABLES LIKE 'user_preferences'"
        let tables = try await connection.execute(checkTableQuery)
        
        if let _ = try await tables.first {
            print("✓ user_preferences table exists")
            
            // Describe the table structure
            let describeQuery = "DESCRIBE user_preferences"
            let description = try await connection.execute(describeQuery)
            
            print("\nTable structure:")
            print("---------------------------------")
            print("Column Name\tType\tNull\tKey\tDefault\tExtra")
            print("---------------------------------")
            
            for await row in description {
                if let field = row["Field"] as? String,
                   let type = row["Type"] as? String,
                   let nullable = row["Null"] as? String,
                   let key = row["Key"] as? String,
                   let defaultValue = row["Default"] as? String,
                   let extra = row["Extra"] as? String {
                    print("\(field)\t\(type)\t\(nullable)\t\(key)\t\(defaultValue)\t\(extra)")
                }
            }
            print("---------------------------------")
            
            // Check if there are any records
            let countQuery = "SELECT COUNT(*) as count FROM user_preferences"
            let countResult = try await connection.execute(countQuery)
            
            if let row = try await countResult.first, let count = row["count"] as? Int {
                print("\n✓ Found \(count) records in user_preferences table")
            }
            
        } else {
            print("✗ user_preferences table does not exist")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Wait for the task to complete
RunLoop.main.run()
