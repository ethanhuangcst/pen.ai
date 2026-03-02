import Foundation
import MySQLKit
import NIO

// Import the database services
@testable import Pen

func createContentHistoryTable() async throws {
    print("Starting to create content_history table...")
    
    // Test database connectivity first
    let pool = DatabaseConnectivityPool.shared
    
    if !pool.isReady {
        print("Database connection pool is not ready. Initializing...")
        // Wait a bit for the pool to initialize
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000) // 2 seconds
    }
    
    // Test connectivity
    let connectivityResult = await pool.testConnectivity()
    if !connectivityResult {
        print("Failed to connect to database. Exiting.")
        return
    }
    
    print("Database connectivity test passed.")
    
    // Get a connection from the pool
    guard let connection = pool.getConnection() else {
        print("Failed to get database connection. Exiting.")
        return
    }
    defer { pool.returnConnection(connection) }
    
    // Create the content_history table
    let createTableQuery = """
    CREATE TABLE IF NOT EXISTS content_history (
        uuid VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36),
        enhance_datetime DATETIME NOT NULL,
        original_content TEXT NOT NULL,
        enhanced_content TEXT NOT NULL,
        prompt_text TEXT NOT NULL,
        ai_provider VARCHAR(255) NOT NULL,
        is_deleted BOOLEAN DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
    """
    
    print("Executing CREATE TABLE query...")
    
    do {
        let result = try await connection.execute(query: createTableQuery)
        print("Table creation query executed successfully.")
        
        // Verify the table was created
        let describeQuery = "DESCRIBE content_history"
        let describeResult = try await connection.execute(query: describeQuery)
        
        print("\nTable structure:")
        for row in describeResult {
            if let field = row["Field"] as? String,
               let type = row["Type"] as? String,
               let nullable = row["Null"] as? String,
               let key = row["Key"] as? String,
               let defaultValue = row["Default"] as? String,
               let extra = row["Extra"] as? String {
                print("\(field): \(type) (Null: \(nullable), Key: \(key), Default: \(defaultValue), Extra: \(extra))")
            }
        }
        
        print("\nContent history table created successfully!")
        
    } catch {
        print("Error creating table: \(error)")
    }
}

// Run the function
Task {
    do {
        try await createContentHistoryTable()
    } catch {
        print("Error: \(error)")
    }
}

// Wait for the task to complete
RunLoop.main.run()
