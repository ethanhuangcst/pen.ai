import Foundation
import MySQLKit
import NIOCore
import System

// Database configuration
let config = MySQLConfiguration(
    hostname: "101.132.156.250",
    port: 33320,
    username: "wingmandev",
    password: "WingmanDev123!",
    database: "wingman_db"
)

print("Connecting to database...")

Task {
    do {
        // Connect to the database
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let connection = try await MySQLConnection.connect(
            to: SocketAddress(ipAddress: config.hostname, port: config.port),
            username: config.username,
            database: config.database,
            password: config.password,
            on: eventLoopGroup
        )
        defer { 
            try? connection.close()
            try? eventLoopGroup.syncShutdownGracefully()
        }
        
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
            
            // Let's try to create the table now
            print("\nAttempting to create user_preferences table...")
            
            let createTableQuery = """
            CREATE TABLE IF NOT EXISTS user_preferences (
                id VARCHAR(255) NOT NULL PRIMARY KEY,
                user_id INT NOT NULL,
                content_history_count INT NOT NULL DEFAULT 10,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
            """
            
            try await connection.execute(createTableQuery)
            print("✓ Created user_preferences table")
            
            // Add index
            let addIndexQuery = "CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id)"
            try await connection.execute(addIndexQuery)
            print("✓ Added index on user_id")
            
            // Insert default preferences for existing users
            let insertDefaultsQuery = """
            INSERT INTO user_preferences (id, user_id, content_history_count) 
            SELECT CONCAT('preference-', UUID()), id, 10 
            FROM users 
            WHERE NOT EXISTS (
                SELECT 1 FROM user_preferences WHERE user_preferences.user_id = users.id
            )
            """
            
            let insertResult = try await connection.execute(insertDefaultsQuery)
            print("✓ Inserted default preferences for existing users")
            
            // Verify the table was created
            let verifyTables = try await connection.execute(checkTableQuery)
            if let _ = try await verifyTables.first {
                print("✓ user_preferences table now exists")
            } else {
                print("✗ Failed to create user_preferences table")
            }
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Wait for the task to complete
RunLoop.main.run()
